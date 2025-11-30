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
import logging
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Optional, Callable
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

    # Thresholds
    DEGRADED_THRESHOLD: int = 3   # Missed heartbeats before degraded
    TERMINATE_THRESHOLD: int = 10  # Missed heartbeats before termination


class HeartbeatManager:
    """
    Manages heartbeat sessions for all connected devices.

    This is the governance entry point - all devices must maintain
    an active heartbeat to access BROAD platform resources.
    """

    def __init__(self, on_session_change: Optional[Callable] = None):
        """
        Initialize the heartbeat manager.

        Args:
            on_session_change: Callback when session state changes
        """
        self.sessions: dict[str, HeartbeatSession] = {}
        self.devices: dict[str, DeviceInfo] = {}
        self.on_session_change = on_session_change

    async def register_device(self, device: DeviceInfo) -> HeartbeatSession:
        """
        Register a new device and create a heartbeat session.

        This is the FIRST step for any device connecting to BROAD.
        """
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

        # Update session state
        session.last_heartbeat = datetime.now(timezone.utc)
        session.sequence_number = payload.sequence_number
        session.current_rate = payload.activity_level
        session.missed_count = 0  # Reset on successful heartbeat

        # Verify authentication if provided
        if payload.auth_token:
            # In production: validate token with IAM
            session.auth_verified = True

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

        return {
            "status": "ok",
            "ack_sequence": payload.sequence_number,
            "server_time": datetime.now(timezone.utc).isoformat(),
            "session_state": session.state.value,
            "auth_verified": session.auth_verified
        }

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

        return {
            "session_valid": session.state == SessionState.ACTIVE,
            "authenticated": session.auth_verified,
            "device_type": device.device_type if device else "unknown",
            "activity_level": session.current_rate.name,
            "missed_heartbeats": session.missed_count
        }

    async def monitor_sessions(self):
        """
        Background task to monitor session health.

        Runs continuously, checking for missed heartbeats.
        """
        while True:
            now = datetime.now(timezone.utc)

            for session in list(self.sessions.values()):
                if session.state in [SessionState.TERMINATED, SessionState.UNREGISTERED]:
                    continue

                if session.last_heartbeat:
                    # Calculate expected heartbeat interval
                    expected_interval = 1.0 / session.current_rate.value
                    elapsed = (now - session.last_heartbeat).total_seconds()

                    if elapsed > expected_interval * 2:  # Missed heartbeat
                        session.missed_count += 1

                        if session.missed_count >= session.TERMINATE_THRESHOLD:
                            session.state = SessionState.TERMINATED
                            logger.warning(
                                f"Session {session.session_id} TERMINATED "
                                f"(missed {session.missed_count} heartbeats)"
                            )
                            if self.on_session_change:
                                await self.on_session_change(session)

                        elif session.missed_count >= session.DEGRADED_THRESHOLD:
                            if session.state != SessionState.DEGRADED:
                                session.state = SessionState.DEGRADED
                                logger.warning(
                                    f"Session {session.session_id} DEGRADED "
                                    f"(missed {session.missed_count} heartbeats)"
                                )
                                if self.on_session_change:
                                    await self.on_session_change(session)

            await asyncio.sleep(0.1)  # Check every 100ms

    def terminate_session(self, session_id: str, reason: str = "manual"):
        """Manually terminate a session."""
        session = self.sessions.get(session_id)
        if session:
            session.state = SessionState.TERMINATED
            logger.info(f"Session {session_id} terminated: {reason}")


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

        # Create manager
        manager = HeartbeatManager()

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
