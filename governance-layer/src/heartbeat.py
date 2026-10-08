#!/usr/bin/env python3
"""
QUIC Heartbeat Protocol - ESN Governance Entry Point

This module defines the heartbeat protocol that establishes and maintains
device registration and authentication state with the BROAD platform.

Architecture Role:
    The heartbeat is the FIRST governance interaction. All other governance
    decisions depend on a valid heartbeat session.

    Device → QUIC Heartbeat → Access Agent → Logic Engine → Resources

Heartbeat Characteristics:
    - Adaptive rate: 1 Hz (idle) to 50 Hz (active tasks)
    - Carries: device ID, session token, authentication state
    - Future: bio-signature for continuous authentication
    - Timeout: session terminated on missed heartbeats

Integration Points:
    1. Device Registration: New devices register via initial heartbeat
    2. Session Management: Heartbeat maintains session validity
    3. Authentication State: Heartbeat carries auth tokens/bio-signature
    4. Health Monitoring: Access Agent monitors heartbeat health
    5. Resource Allocation: Active devices get priority

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
"""

import asyncio
import inspect
import logging
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Awaitable, Callable, Optional, Union
from uuid import uuid4

# Note: In production, this would use aioquic for actual QUIC transport
# For now, we define the interface and simulate the protocol

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("heartbeat")


class HeartbeatRate(Enum):
    """Adaptive heartbeat rates based on activity level."""
    IDLE = 1        # 1 Hz - device idle
    LIGHT = 5       # 5 Hz - light activity
    ACTIVE = 10     # 10 Hz - active user interaction
    INTENSIVE = 25  # 25 Hz - intensive task underway
    REALTIME = 50   # 50 Hz - real-time operations


class SessionState(Enum):
    """Heartbeat session states."""
    UNREGISTERED = "unregistered"
    REGISTERING = "registering"
    ACTIVE = "active"
    DEGRADED = "degraded"  # Missed heartbeats, but not terminated
    TERMINATED = "terminated"


@dataclass
class DeviceInfo:
    """Device identification and capabilities."""
    device_id: str
    device_type: str  # "pixel", "orange_pi", "simulation"
    hardware_id: Optional[str] = None  # Unique hardware identifier
    capabilities: list[str] = field(default_factory=list)
    sensors_available: list[str] = field(default_factory=list)


@dataclass
class HeartbeatPayload:
    """Data carried in each heartbeat."""
    device_id: str
    session_id: str
    sequence_number: int
    timestamp: str
    auth_token: Optional[str] = None
    bio_signature: Optional[bytes] = None  # Future: fingerprint + voice + behavioral
    activity_level: HeartbeatRate = HeartbeatRate.IDLE
    health_metrics: dict = field(default_factory=dict)

    def to_dict(self) -> dict:
        return {
            "device_id": self.device_id,
            "session_id": self.session_id,
            "sequence_number": self.sequence_number,
            "timestamp": self.timestamp,
            "auth_token": self.auth_token,
            "bio_signature": self.bio_signature.hex() if self.bio_signature else None,
            "activity_level": self.activity_level.name,
            "health_metrics": self.health_metrics
        }


@dataclass
class HeartbeatSession:
    """Active heartbeat session state."""
    session_id: str
    device_id: str
    state: SessionState = SessionState.UNREGISTERED
    last_heartbeat: Optional[datetime] = None
    missed_count: int = 0
    sequence_number: int = 0
    current_rate: HeartbeatRate = HeartbeatRate.IDLE
    auth_verified: bool = False
    created_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    terminated_at: Optional[datetime] = None

    # Thresholds
    DEGRADED_THRESHOLD: int = 3   # Missed heartbeats before degraded
    TERMINATE_THRESHOLD: int = 10  # Missed heartbeats before termination


# A token validator receives (token, device_id) and returns whether the
# token authenticates that device. It may be a plain function or a coroutine.
TokenValidator = Callable[[str, str], Union[bool, Awaitable[bool]]]


def accept_any_token(token: str, device_id: str) -> bool:
    """
    Validator for simulations and tests ONLY: every non-empty token verifies.

    It is deliberately not the default. A HeartbeatManager with no validator
    never marks a session authenticated, so a deployment that forgets to
    wire IAM fails closed rather than open.
    """
    return bool(token)


class HeartbeatManager:
    """
    Manages heartbeat sessions for all connected devices.

    This is the governance entry point - all devices must maintain
    an active heartbeat to access BROAD platform resources.
    """

    # How long a TERMINATED session is kept so a late heartbeat gets the
    # specific "session_terminated" answer instead of "unknown_session".
    TERMINATED_RETENTION_SECONDS: float = 300.0

    def __init__(
        self,
        on_session_change: Optional[Callable] = None,
        token_validator: Optional[TokenValidator] = None,
        terminated_retention_seconds: Optional[float] = None,
    ):
        """
        Initialize the heartbeat manager.

        Args:
            on_session_change: Callback when session state changes
            token_validator: Validates auth tokens carried by heartbeats.
                None (the default) means no token is ever accepted and no
                session becomes authenticated through the heartbeat; pass
                accept_any_token for simulations.
            terminated_retention_seconds: how long terminated sessions stay
                in the table before the monitor purges them.
        """
        self.sessions: dict[str, HeartbeatSession] = {}
        self.devices: dict[str, DeviceInfo] = {}
        self.on_session_change = on_session_change
        self.token_validator = token_validator
        if terminated_retention_seconds is not None:
            self.TERMINATED_RETENTION_SECONDS = terminated_retention_seconds
        self._monitor_task: Optional[asyncio.Task] = None
        if token_validator is None:
            logger.warning(
                "HeartbeatManager has no token validator: heartbeats cannot "
                "authenticate sessions until one is configured"
            )

    def _terminate(self, session: HeartbeatSession, reason: str) -> None:
        session.state = SessionState.TERMINATED
        session.terminated_at = datetime.now(timezone.utc)
        logger.info(f"Session {session.session_id} terminated: {reason}")

    async def _validate_token(self, token: str, device_id: str) -> bool:
        if self.token_validator is None:
            return False
        try:
            result = self.token_validator(token, device_id)
            if inspect.isawaitable(result):
                result = await result
            return bool(result)
        except Exception as e:  # a failing validator must fail closed
            logger.error(f"Token validator raised for device {device_id}: {e}")
            return False

    async def register_device(self, device: DeviceInfo) -> HeartbeatSession:
        """
        Register a new device and create a heartbeat session.

        This is the FIRST step for any device connecting to BROAD.
        """
        # One live session per device: a re-registration supersedes any
        # earlier session for the same device instead of leaving it active.
        for existing in self.sessions.values():
            if existing.device_id == device.device_id and existing.state != SessionState.TERMINATED:
                self._terminate(existing, f"device {device.device_id} re-registered")
                if self.on_session_change:
                    await self.on_session_change(existing)

        session_id = str(uuid4())
        session = HeartbeatSession(
            session_id=session_id,
            device_id=device.device_id,
            state=SessionState.REGISTERING
        )

        self.devices[device.device_id] = device
        self.sessions[session_id] = session

        logger.info(
            f"Device registered: {device.device_id} "
            f"type={device.device_type} session={session_id}"
        )

        # Transition to active after successful registration
        session.state = SessionState.ACTIVE
        session.last_heartbeat = datetime.now(timezone.utc)

        if self.on_session_change:
            await self.on_session_change(session)

        return session

    async def process_heartbeat(self, payload: HeartbeatPayload) -> dict:
        """
        Process an incoming heartbeat from a device.

        Returns:
            Response dict with acknowledgment and any commands
        """
        session = self.sessions.get(payload.session_id)

        if not session:
            return {
                "status": "error",
                "error": "unknown_session",
                "message": "Session not found - device must re-register"
            }

        if session.state == SessionState.TERMINATED:
            return {
                "status": "error",
                "error": "session_terminated",
                "message": "Session was terminated - device must re-register"
            }

        if payload.device_id != session.device_id:
            return {
                "status": "error",
                "error": "device_mismatch",
                "message": "Heartbeat device does not match the session's device"
            }

        # Sequence numbers must advance: a repeated or older number is a
        # replay or a duplicate and is not accepted as liveness.
        if payload.sequence_number <= session.sequence_number:
            return {
                "status": "error",
                "error": "stale_sequence",
                "message": (
                    f"Sequence {payload.sequence_number} is not after "
                    f"{session.sequence_number}"
                ),
                "expected_after": session.sequence_number
            }

        # Update session state
        session.last_heartbeat = datetime.now(timezone.utc)
        session.sequence_number = payload.sequence_number
        session.current_rate = payload.activity_level
        session.missed_count = 0  # Reset on successful heartbeat

        # Authentication. A token is checked by the configured validator; a
        # rejected token revokes any earlier verification (the heartbeat is
        # the continuous-authentication carrier). No token leaves the
        # session's authentication state as it was.
        auth_result = None
        if payload.auth_token:
            if await self._validate_token(payload.auth_token, session.device_id):
                session.auth_verified = True
                auth_result = "verified"
            else:
                session.auth_verified = False
                auth_result = "rejected" if self.token_validator else "no_validator"
                logger.warning(
                    f"Session {session.session_id}: auth token {auth_result} "
                    f"for device {session.device_id}"
                )

        # Handle bio-signature (future)
        if payload.bio_signature:
            # In production: verify bio-signature for continuous auth
            pass

        # Transition from degraded back to active
        if session.state == SessionState.DEGRADED:
            session.state = SessionState.ACTIVE
            logger.info(f"Session {session.session_id} recovered from degraded state")
            if self.on_session_change:
                await self.on_session_change(session)

        response = {
            "status": "ok",
            "ack_sequence": payload.sequence_number,
            "server_time": datetime.now(timezone.utc).isoformat(),
            "session_state": session.state.value,
            "auth_verified": session.auth_verified
        }
        if auth_result:
            response["auth"] = auth_result
        return response

    async def check_session_health(self, session_id: str) -> bool:
        """
        Check if a session is healthy (for Access Agent use).

        This is called by the Access Agent before granting access.
        """
        session = self.sessions.get(session_id)
        if not session:
            return False

        return session.state == SessionState.ACTIVE and session.auth_verified

    async def get_session_context(self, session_id: str) -> Optional[dict]:
        """
        Get context for Access Agent decision making.

        Returns authentication and session state for governance decisions.
        """
        session = self.sessions.get(session_id)
        if not session:
            return None

        device = self.devices.get(session.device_id)
        now = datetime.now(timezone.utc)
        idle = (now - session.last_heartbeat).total_seconds() if session.last_heartbeat else None
        age = (now - datetime.fromisoformat(session.created_at)).total_seconds()

        return {
            "session_valid": session.state == SessionState.ACTIVE,
            "authenticated": session.auth_verified,
            "device_type": device.device_type if device else "unknown",
            "activity_level": session.current_rate.name,
            "missed_heartbeats": session.missed_count,
            # Used by the gateway for the Scheme 0 session bounds
            # □(idle_session_timeout ≤ 30m) and □(maximum_session_duration ≤ 24h)
            "idle_seconds": idle,
            "session_age_seconds": age,
        }

    async def check_sessions_once(self, now: Optional[datetime] = None) -> list[HeartbeatSession]:
        """
        One monitoring pass. Returns the sessions whose state changed.

        A heartbeat is "missed" once per expected interval that has passed
        without one, so missed_count is derived from elapsed time rather
        than incremented on every pass: at 1 Hz the third miss is at 4 s and
        the tenth at 11 s, whatever the polling period of the monitor.
        """
        now = now or datetime.now(timezone.utc)
        changed = []

        for session in list(self.sessions.values()):
            if session.state in (SessionState.TERMINATED, SessionState.UNREGISTERED):
                continue
            if not session.last_heartbeat:
                continue

            expected_interval = 1.0 / session.current_rate.value
            elapsed = (now - session.last_heartbeat).total_seconds()
            missed = max(0, int(elapsed // expected_interval) - 1)
            if missed == session.missed_count:
                continue
            session.missed_count = missed

            if missed >= session.TERMINATE_THRESHOLD:
                self._terminate(session, f"missed {missed} heartbeats")
                changed.append(session)
            elif missed >= session.DEGRADED_THRESHOLD and session.state != SessionState.DEGRADED:
                session.state = SessionState.DEGRADED
                logger.warning(
                    f"Session {session.session_id} DEGRADED "
                    f"(missed {missed} heartbeats)"
                )
                changed.append(session)

        if self.on_session_change:
            for session in changed:
                await self.on_session_change(session)

        self.purge_terminated(now)
        return changed

    def purge_terminated(self, now: Optional[datetime] = None) -> int:
        """
        Drop sessions that have been TERMINATED for longer than the
        retention window, so the table does not grow without bound.
        Returns the number removed.
        """
        now = now or datetime.now(timezone.utc)
        expired = [
            sid for sid, s in self.sessions.items()
            if s.state == SessionState.TERMINATED
            and s.terminated_at is not None
            and (now - s.terminated_at).total_seconds() > self.TERMINATED_RETENTION_SECONDS
        ]
        for sid in expired:
            del self.sessions[sid]
        if expired:
            logger.info(f"Purged {len(expired)} terminated session(s)")
        return len(expired)

    async def monitor_sessions(self, poll_interval: float = 0.1):
        """
        Background task to monitor session health.

        Runs continuously, checking for missed heartbeats.
        """
        while True:
            await self.check_sessions_once()
            await asyncio.sleep(poll_interval)

    def start_monitor(self, poll_interval: float = 0.1) -> asyncio.Task:
        """Start monitor_sessions as a background task (idempotent)."""
        if self._monitor_task is None or self._monitor_task.done():
            self._monitor_task = asyncio.create_task(
                self.monitor_sessions(poll_interval)
            )
        return self._monitor_task

    def stop_monitor(self) -> None:
        """Cancel the background monitor if it is running."""
        if self._monitor_task and not self._monitor_task.done():
            self._monitor_task.cancel()
        self._monitor_task = None

    def terminate_session(self, session_id: str, reason: str = "manual"):
        """Manually terminate a session."""
        session = self.sessions.get(session_id)
        if session:
            self._terminate(session, reason)


class HeartbeatClient:
    """
    Client-side heartbeat sender (runs on edge device).

    In production, this would use aioquic to send QUIC datagrams.
    """

    def __init__(
        self,
        device: DeviceInfo,
        server_callback: Callable,  # In production: QUIC connection
    ):
        self.device = device
        self.server_callback = server_callback
        self.session_id: Optional[str] = None
        self.sequence_number: int = 0
        self.current_rate: HeartbeatRate = HeartbeatRate.IDLE
        self.running: bool = False

    async def register(self) -> str:
        """Register device and get session ID."""
        # In production: send registration over QUIC
        # For now: direct callback
        response = await self.server_callback("register", self.device)
        self.session_id = response.session_id
        return self.session_id

    async def send_heartbeat(
        self,
        auth_token: Optional[str] = None,
        bio_signature: Optional[bytes] = None,
        health_metrics: Optional[dict] = None
    ) -> dict:
        """Send a single heartbeat."""
        if not self.session_id:
            raise RuntimeError("Device not registered")

        self.sequence_number += 1

        payload = HeartbeatPayload(
            device_id=self.device.device_id,
            session_id=self.session_id,
            sequence_number=self.sequence_number,
            timestamp=datetime.now(timezone.utc).isoformat(),
            auth_token=auth_token,
            bio_signature=bio_signature,
            activity_level=self.current_rate,
            health_metrics=health_metrics or {}
        )

        # In production: send over QUIC
        response = await self.server_callback("heartbeat", payload)
        return response

    async def run(self, auth_token: Optional[str] = None):
        """Run the heartbeat loop."""
        self.running = True

        while self.running:
            try:
                await self.send_heartbeat(auth_token=auth_token)
            except Exception as e:
                logger.error(f"Heartbeat failed: {e}")

            # Adaptive rate
            interval = 1.0 / self.current_rate.value
            await asyncio.sleep(interval)

    def set_rate(self, rate: HeartbeatRate):
        """Update the heartbeat rate based on activity."""
        self.current_rate = rate
        logger.debug(f"Heartbeat rate changed to {rate.name}")

    def stop(self):
        """Stop the heartbeat loop."""
        self.running = False


# Integration with Access Agent
class GovernedHeartbeatManager(HeartbeatManager):
    """
    Heartbeat manager integrated with Access Agent.

    Provides session context for governance decisions.
    """

    def __init__(self, access_agent=None):
        """
        Initialize with optional Access Agent.

        Args:
            access_agent: AccessAgent instance for governance decisions
        """
        super().__init__(on_session_change=self._on_session_change)
        self.access_agent = access_agent

    async def _on_session_change(self, session: HeartbeatSession):
        """Handle session state changes."""
        if session.state == SessionState.TERMINATED:
            logger.info(
                f"Session {session.session_id} terminated - "
                "access will be denied for this session"
            )

    async def check_access(
        self,
        session_id: str,
        resource: str,
        action: str
    ) -> dict:
        """
        Check access using session context + Access Agent.

        This combines heartbeat session state with Logic Engine reasoning.
        """
        context = await self.get_session_context(session_id)

        if not context:
            return {
                "allowed": False,
                "reason": "No valid session"
            }

        if not context["session_valid"]:
            return {
                "allowed": False,
                "reason": f"Session state: {context.get('session_state', 'invalid')}"
            }

        if self.access_agent:
            decision = self.access_agent.check_access(
                resource=resource,
                action=action,
                context=context
            )
            return decision.to_dict()

        # Fallback if no Access Agent
        return {
            "allowed": context["authenticated"],
            "reason": "Basic auth check (no Logic Engine)"
        }


if __name__ == "__main__":
    # Demo: Simulate heartbeat flow

    async def demo():
        print("=" * 60)
        print("QUIC Heartbeat Protocol - Demo")
        print("=" * 60)

        # Create manager. The demo accepts any token; production wires IAM.
        manager = HeartbeatManager(token_validator=accept_any_token)

        # Register a device
        device = DeviceInfo(
            device_id="pixel-001",
            device_type="simulation",
            capabilities=["bio_auth", "camera", "sensors"],
            sensors_available=["fingerprint", "microphone"]
        )

        print("\n[1] Registering device...")
        session = await manager.register_device(device)
        print(f"    Session ID: {session.session_id}")
        print(f"    State: {session.state.value}")

        # Create client
        async def mock_callback(action, data):
            if action == "register":
                return session
            elif action == "heartbeat":
                return await manager.process_heartbeat(data)

        client = HeartbeatClient(device, mock_callback)
        client.session_id = session.session_id

        # Send heartbeats
        print("\n[2] Sending heartbeats...")
        for i in range(3):
            response = await client.send_heartbeat(auth_token="test-token")
            print(f"    Heartbeat {i+1}: {response['status']}")

        # Check session health
        print("\n[3] Checking session health...")
        healthy = await manager.check_session_health(session.session_id)
        print(f"    Healthy: {healthy}")

        # Get context for Access Agent
        print("\n[4] Getting session context for governance...")
        context = await manager.get_session_context(session.session_id)
        print(f"    Context: {context}")

        # Integrate with Access Agent
        print("\n[5] Integration with Access Agent...")
        try:
            from access_agent import AccessAgent
            agent = AccessAgent()

            governed_manager = GovernedHeartbeatManager(access_agent=agent)
            governed_manager.token_validator = accept_any_token
            await governed_manager.register_device(device)

            # Simulate heartbeat
            client2 = HeartbeatClient(device, lambda a, d: governed_manager.process_heartbeat(d) if a == "heartbeat" else None)
            client2.session_id = list(governed_manager.sessions.keys())[0]
            await client2.send_heartbeat(auth_token="test-token")

            # Check access through governed manager
            access_result = await governed_manager.check_access(
                session_id=client2.session_id,
                resource="patient_records",
                action="read"
            )
            print(f"    Access result: {access_result}")

        except Exception as e:
            print(f"    (Access Agent integration demo skipped: {e})")

        print("\n" + "=" * 60)

    asyncio.run(demo())
