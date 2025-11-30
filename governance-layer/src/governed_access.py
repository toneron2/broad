#!/usr/bin/env python3
"""
Governed Access - Complete Governance Layer Integration

This module provides the fully integrated governance layer combining:
    1. Guardrails Enforcer (formal constraints from .logic files)
    2. Access Agent (Logic Engine for multi-paradigm reasoning)
    3. Heartbeat Manager (session management)
    4. EVO/NOEVO classification enforcement

Architecture:
    Request → Heartbeat Check → Guardrails Check → Logic Engine → Decision

Usage:
    from governed_access import GovernanceGateway, governed_mcp_tool

    # Initialize gateway
    gateway = GovernanceGateway()

    # Check access
    decision = await gateway.check_access(
        session_id="...",
        agent_name="tool_agent",
        resource="patient_records",
        action="read",
        context={"role": "provider", "authenticated": True}
    )

    # Or use decorator
    @governed_mcp_tool("healthcare", "read_patient")
    async def read_patient(patient_id: str):
        ...

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
"""

import asyncio
import logging
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Optional, Callable, Any
from functools import wraps

from guardrails_loader import GuardrailsEnforcer, AgentType, get_enforcer
from access_agent import AccessAgent, AccessDecision
from heartbeat import HeartbeatManager, HeartbeatSession, SessionState, DeviceInfo

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("governance")


@dataclass
class GovernanceDecision:
    """Complete governance decision with all checks."""
    allowed: bool
    guardrails_passed: bool
    logic_engine_passed: bool
    session_valid: bool
    agent_type: AgentType
    reasoning_trace: list[str] = field(default_factory=list)
    policy_expression: str = ""
    latency_ms: float = 0.0
    timestamp: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())

    def to_dict(self) -> dict:
        return {
            "allowed": self.allowed,
            "guardrails_passed": self.guardrails_passed,
            "logic_engine_passed": self.logic_engine_passed,
            "session_valid": self.session_valid,
            "agent_type": self.agent_type.value,
            "reasoning_trace": self.reasoning_trace,
            "policy_expression": self.policy_expression,
            "latency_ms": self.latency_ms,
            "timestamp": self.timestamp
        }


class GovernanceGateway:
    """
    Central governance gateway integrating all components.

    This is the single point of entry for all access control decisions
    in the BROAD platform.
    """

    def __init__(
        self,
        enforcer: Optional[GuardrailsEnforcer] = None,
        access_agent: Optional[AccessAgent] = None,
        heartbeat_manager: Optional[HeartbeatManager] = None
    ):
        """
        Initialize the governance gateway.

        Args:
            enforcer: Guardrails enforcer (creates default if not provided)
            access_agent: Logic Engine access agent
            heartbeat_manager: Session manager
        """
        self.enforcer = enforcer or get_enforcer()
        self.access_agent = access_agent or AccessAgent()
        self.heartbeat_manager = heartbeat_manager or HeartbeatManager()
        self._audit_log: list[GovernanceDecision] = []

        logger.info("GovernanceGateway initialized")
        logger.info(f"  Guardrails: {len(self.enforcer.loader.schemes)} schemes loaded")
        logger.info(f"  Forbidden actions (Scheme 0): {len(self.enforcer.get_all_forbidden())}")

    async def check_access(
        self,
        session_id: Optional[str],
        agent_name: str,
        resource: str,
        action: str,
        context: Optional[dict] = None
    ) -> GovernanceDecision:
        """
        Complete access control check.

        Sequence:
            1. Check session validity (heartbeat)
            2. Check guardrails (formal constraints)
            3. Check Logic Engine (multi-paradigm reasoning)
            4. Return comprehensive decision

        Args:
            session_id: Heartbeat session ID (None for service-to-service)
            agent_name: Name of the agent making the request
            resource: Resource being accessed
            action: Action being performed
            context: Additional context

        Returns:
            GovernanceDecision with full reasoning trace
        """
        start_time = time.time()
        context = context or {}
        reasoning_trace = []

        # Initialize decision
        decision = GovernanceDecision(
            allowed=False,
            guardrails_passed=False,
            logic_engine_passed=False,
            session_valid=False,
            agent_type=self.enforcer.get_agent_type(agent_name)
        )

        # Step 1: Session Check (if session_id provided)
        if session_id:
            session_context = await self.heartbeat_manager.get_session_context(session_id)
            if session_context:
                decision.session_valid = session_context.get("session_valid", False)
                context.update(session_context)
                reasoning_trace.append(f"Session check: {'VALID' if decision.session_valid else 'INVALID'}")
            else:
                reasoning_trace.append("Session check: NO SESSION FOUND")
        else:
            # Service-to-service call (no heartbeat required)
            decision.session_valid = True
            reasoning_trace.append("Session check: SKIPPED (service call)")

        if not decision.session_valid and session_id:
            decision.latency_ms = (time.time() - start_time) * 1000
            decision.reasoning_trace = reasoning_trace
            self._log_decision(decision)
            return decision

        # Step 2: Guardrails Check
        guardrails_allowed, guardrails_reason = self.enforcer.check_action(
            action=action,
            agent_name=agent_name,
            context=context
        )
        decision.guardrails_passed = guardrails_allowed
        reasoning_trace.append(f"Guardrails check: {guardrails_reason}")

        if not guardrails_allowed:
            decision.latency_ms = (time.time() - start_time) * 1000
            decision.reasoning_trace = reasoning_trace
            self._log_decision(decision)
            return decision

        # Step 3: Logic Engine Check
        logic_decision = self.access_agent.check_access(
            resource=resource,
            action=action,
            context=context
        )
        decision.logic_engine_passed = logic_decision.allowed
        decision.policy_expression = logic_decision.policy_expression
        reasoning_trace.append(f"Logic Engine: {'ALLOW' if logic_decision.allowed else 'DENY'}")
        reasoning_trace.append(f"  Policy: {logic_decision.policy_expression}")
        reasoning_trace.append(f"  Paradigms: {logic_decision.paradigms_used}")

        # Step 4: Final Decision
        decision.allowed = (
            decision.session_valid and
            decision.guardrails_passed and
            decision.logic_engine_passed
        )
        reasoning_trace.append(f"Final decision: {'ALLOW' if decision.allowed else 'DENY'}")

        decision.latency_ms = (time.time() - start_time) * 1000
        decision.reasoning_trace = reasoning_trace

        self._log_decision(decision)

        logger.info(
            f"Access decision: agent={agent_name} resource={resource} action={action} "
            f"allowed={decision.allowed} latency={decision.latency_ms:.2f}ms"
        )

        return decision

    def _log_decision(self, decision: GovernanceDecision):
        """Log decision for audit."""
        self._audit_log.append(decision)

        # Keep last 10000 decisions
        if len(self._audit_log) > 10000:
            self._audit_log = self._audit_log[-10000:]

    def get_audit_log(self, limit: int = 100) -> list[dict]:
        """Get recent audit log entries."""
        return [d.to_dict() for d in self._audit_log[-limit:]]

    def check_evo_noevo_permission(
        self,
        requesting_agent: str,
        target_agent: str,
        action: str
    ) -> tuple[bool, str]:
        """
        Check if an agent can interact with another based on EVO/NOEVO rules.

        Rules:
            - NOEVO → NOEVO: Direct, trusted
            - EVO → NOEVO: Request-verify-execute
            - NOEVO → EVO: Bounded delegation
            - EVO → EVO: Must go through NOEVO mediator

        Args:
            requesting_agent: Agent making the request
            target_agent: Agent being called
            action: Action being requested

        Returns:
            Tuple of (allowed, reason)
        """
        req_type = self.enforcer.get_agent_type(requesting_agent)
        tgt_type = self.enforcer.get_agent_type(target_agent)

        # NOEVO → NOEVO: Direct trusted call
        if req_type == AgentType.NOEVO and tgt_type == AgentType.NOEVO:
            return True, "NOEVO→NOEVO: Direct trusted call"

        # EVO → NOEVO: Allowed with verification
        if req_type == AgentType.EVO and tgt_type == AgentType.NOEVO:
            return True, "EVO→NOEVO: Request will be verified"

        # NOEVO → EVO: Bounded delegation
        if req_type == AgentType.NOEVO and tgt_type == AgentType.EVO:
            return True, "NOEVO→EVO: Bounded delegation"

        # EVO → EVO: Must go through routing (NOEVO)
        if req_type == AgentType.EVO and tgt_type == AgentType.EVO:
            return False, "EVO→EVO: Must route through NOEVO mediator"

        return False, "Unknown agent type combination"


# Global gateway singleton
_gateway: Optional[GovernanceGateway] = None


def get_gateway() -> GovernanceGateway:
    """Get the global governance gateway."""
    global _gateway
    if _gateway is None:
        _gateway = GovernanceGateway()
    return _gateway


def governed_mcp_tool(
    domain: str,
    tool_name: str,
    agent_name: str = "tool_agent"
):
    """
    Decorator for MCP tools that require governance.

    Usage:
        @governed_mcp_tool("healthcare", "read_patient")
        async def read_patient(patient_id: str, context: dict = None):
            # Only executes if access is granted
            ...

    Args:
        domain: MCP domain (e.g., "healthcare", "sales")
        tool_name: Tool name (e.g., "read_patient")
        agent_name: Agent type executing the tool
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(*args, **kwargs) -> Any:
            # Extract context from kwargs
            context = kwargs.pop("context", {})
            session_id = kwargs.pop("session_id", None)

            # Build resource name
            resource = f"{domain}.{tool_name}"
            action = "execute"

            # Check governance
            gateway = get_gateway()
            decision = await gateway.check_access(
                session_id=session_id,
                agent_name=agent_name,
                resource=resource,
                action=action,
                context=context
            )

            if not decision.allowed:
                raise PermissionError(
                    f"Access denied: {resource}/{action}\n"
                    f"Reasoning:\n" + "\n".join(decision.reasoning_trace)
                )

            # Access granted - execute tool
            return await func(*args, **kwargs)

        return wrapper
    return decorator


def governed_sync_tool(
    domain: str,
    tool_name: str,
    agent_name: str = "tool_agent"
):
    """
    Decorator for synchronous tools that require governance.

    Same as governed_mcp_tool but for sync functions.
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            context = kwargs.pop("context", {})

            resource = f"{domain}.{tool_name}"
            action = "execute"

            # Use sync check
            gateway = get_gateway()
            enforcer = gateway.enforcer

            # Quick guardrails check (sync)
            allowed, reason = enforcer.check_action(
                action=action,
                agent_name=agent_name,
                context=context
            )

            if not allowed:
                raise PermissionError(f"Access denied: {resource} - {reason}")

            # Check via access agent (sync)
            decision = gateway.access_agent.check_access(
                resource=resource,
                action=action,
                context=context
            )

            if not decision.allowed:
                raise PermissionError(
                    f"Access denied: {resource}\n"
                    f"Reasoning: {decision.reasoning_trace}"
                )

            return func(*args, **kwargs)

        return wrapper
    return decorator


if __name__ == "__main__":
    # Demo
    async def demo():
        print("=" * 60)
        print("Governance Gateway - Complete Demo")
        print("=" * 60)

        gateway = GovernanceGateway()

        # Register a device
        device = DeviceInfo(
            device_id="demo-device",
            device_type="simulation"
        )
        session = await gateway.heartbeat_manager.register_device(device)
        session_id = session.session_id

        # Simulate auth
        session.auth_verified = True

        # Test cases
        test_cases = [
            {
                "name": "Authenticated provider reading patient records",
                "agent": "tool_agent",
                "resource": "patient_records",
                "action": "read",
                "context": {"role": "provider", "authenticated": True, "session_valid": True}
            },
            {
                "name": "Unauthenticated access attempt",
                "agent": "tool_agent",
                "resource": "patient_records",
                "action": "read",
                "context": {}
            },
            {
                "name": "Attempt to bypass authentication (forbidden)",
                "agent": "tool_agent",
                "resource": "auth_system",
                "action": "bypass_authentication",
                "context": {"role": "admin", "authenticated": True}
            },
            {
                "name": "Designer agent generating workflow",
                "agent": "designer_agent",
                "resource": "workflow",
                "action": "generate",
                "context": {
                    "role": "designer",
                    "authenticated": True,
                    "performed_actions": ["submit_for_verification"]
                }
            },
            {
                "name": "Attempt to harm user (always forbidden)",
                "agent": "any_agent",
                "resource": "user",
                "action": "harm_user",
                "context": {}
            },
        ]

        print("\n[1] Running Governance Test Cases:\n")

        for i, test in enumerate(test_cases, 1):
            print(f"  Test {i}: {test['name']}")
            print(f"    Agent: {test['agent']}")
            print(f"    Resource: {test['resource']}")
            print(f"    Action: {test['action']}")

            decision = await gateway.check_access(
                session_id=None,  # Skip session for demo
                agent_name=test["agent"],
                resource=test["resource"],
                action=test["action"],
                context=test["context"]
            )

            status = "✓ ALLOWED" if decision.allowed else "✗ DENIED"
            print(f"    Result: {status}")
            print(f"    Latency: {decision.latency_ms:.2f}ms")
            for trace in decision.reasoning_trace:
                print(f"      → {trace}")
            print()

        # Test EVO/NOEVO rules
        print("[2] EVO/NOEVO Agent Communication Rules:\n")

        comm_tests = [
            ("tool_agent", "orchestrator_agent", "execute"),
            ("designer_agent", "tool_agent", "request"),
            ("tool_agent", "designer_agent", "delegate"),
            ("designer_agent", "composer_agent", "collaborate"),
        ]

        for req, tgt, action in comm_tests:
            allowed, reason = gateway.check_evo_noevo_permission(req, tgt, action)
            status = "✓" if allowed else "✗"
            req_type = gateway.enforcer.get_agent_type(req).value.upper()
            tgt_type = gateway.enforcer.get_agent_type(tgt).value.upper()
            print(f"  {status} {req} [{req_type}] → {tgt} [{tgt_type}]: {reason}")

        # Show audit log
        print("\n[3] Audit Log (last 5 entries):")
        for entry in gateway.get_audit_log(5):
            print(f"    {entry['timestamp']}: allowed={entry['allowed']}, latency={entry['latency_ms']:.2f}ms")

        print("\n" + "=" * 60)

    asyncio.run(demo())
