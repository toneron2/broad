#!/usr/bin/env python3
"""
Access Agent - ESN Governance Layer Entry Point

This module provides the Access Agent interface for BROAD platform.
All resource access flows through this agent, which uses the Logic Engine
for formal reasoning about access control decisions.

Architecture (Triple-Lock):
    1. Bio-authentication (user identity) - future: heartbeat carrier
    2. OAuth2/IAM (service identity) - GCP integration
    3. Logic Engine (formal reasoning) - THIS MODULE

Integration:
    The Logic Engine proof-of-concept at ./logic-engine/ provides
    multi-paradigm formal reasoning (Boolean, Modal, Deontic).

Usage:
    from access_agent import AccessAgent

    agent = AccessAgent()
    decision = agent.check_access(
        resource="patient_records",
        action="read",
        context={"role": "nurse", "authenticated": True}
    )

    if decision.allowed:
        # Proceed with action
    else:
        # Access denied with reasoning trace

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
"""

import subprocess
import json
import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional
from datetime import datetime, timezone

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("access_agent")

# Logic Engine path (symlinked from ESN)
LOGIC_ENGINE_DIR = Path(__file__).parent / "logic-engine"
LOGIC_ENGINE = LOGIC_ENGINE_DIR / "logic"
META_ENGINE = LOGIC_ENGINE_DIR / "engines" / "meta.sh"
DEONTIC_ENGINE = LOGIC_ENGINE_DIR / "engines" / "deontic.sh"


@dataclass
class AccessDecision:
    """Result of an access control decision."""
    allowed: bool
    reasoning_trace: str
    paradigms_used: list[str] = field(default_factory=list)
    confidence: float = 1.0
    timestamp: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    policy_expression: str = ""

    def to_dict(self) -> dict:
        return {
            "allowed": self.allowed,
            "reasoning_trace": self.reasoning_trace,
            "paradigms_used": self.paradigms_used,
            "confidence": self.confidence,
            "timestamp": self.timestamp,
            "policy_expression": self.policy_expression
        }


@dataclass
class ResourceContext:
    """Context for an access request."""
    resource: str
    action: str
    user_role: Optional[str] = None
    authenticated: bool = False
    consent_given: bool = False
    session_valid: bool = False
    custom_constraints: dict = field(default_factory=dict)


class AccessAgent:
    """
    ESN Access Agent - Governance Layer Gateway

    All resource access in the BROAD platform flows through this agent.
    It uses the multi-paradigm Logic Engine for formal reasoning about
    access control policies.

    Supported Logic Paradigms:
        - Boolean: Basic propositional logic
        - Modal: Necessity (□) and possibility (◇)
        - Deontic: Obligations (O), Permissions (P), Forbidden (F)
        - Meta: Cross-paradigm composition
    """

    def __init__(self, strict_mode: bool = True):
        """
        Initialize the Access Agent.

        Args:
            strict_mode: If True, deny access on any engine failure
        """
        self.strict_mode = strict_mode
        self._verify_logic_engine()
        self._access_log: list[AccessDecision] = []

    def _verify_logic_engine(self) -> None:
        """Verify the Logic Engine is available and working."""
        if not LOGIC_ENGINE.exists():
            raise RuntimeError(
                f"Logic Engine not found at {LOGIC_ENGINE}. "
                "Ensure logic-engine is linked from ESN."
            )

        # Quick health check
        try:
            result = self._run_logic("P ∨ ¬P")
            if "TAUTOLOGY" not in result:
                raise RuntimeError("Logic Engine health check failed")
            logger.info("Logic Engine verified and operational")
        except Exception as e:
            raise RuntimeError(f"Logic Engine health check failed: {e}")

    def _run_logic(self, expression: str, verbose: bool = False) -> str:
        """Execute a logic expression through the Logic Engine."""
        cmd = [str(LOGIC_ENGINE)]
        if verbose:
            cmd.append("-v")
        cmd.append(expression)

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=5  # 5 second timeout (target <50ms, but allow margin)
        )
        return result.stdout.strip()

    def _run_meta_engine(self, expression: str) -> str:
        """Execute a multi-paradigm expression through the meta-engine."""
        result = subprocess.run(
            [str(META_ENGINE), expression],
            capture_output=True,
            text=True,
            timeout=5
        )
        return result.stdout.strip()

    def _run_deontic_engine(self, expression: str, check_consistency: bool = True) -> str:
        """Execute a deontic expression."""
        cmd = [str(DEONTIC_ENGINE)]
        if check_consistency:
            cmd.append("-t")
        cmd.append(expression)

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=5
        )
        return result.stdout.strip()

    def _build_policy_expression(self, context: ResourceContext) -> str:
        """
        Build a formal logic policy expression from context.

        ESN Policy Templates:
            - Authentication required: O(auth) → P(access)
            - Role-based: O(role=X) → P(action)
            - Consent-based: O(consent) → P(data_access)
            - Session-based: session_valid → P(continue)
        """
        constraints = []

        # Authentication constraint (deontic)
        if context.authenticated:
            constraints.append("O(auth)")

        # Role constraint (deontic)
        if context.user_role:
            constraints.append(f"O(role={context.user_role})")

        # Consent constraint (deontic)
        if context.consent_given:
            constraints.append("O(consent)")

        # Session constraint (modal - necessary condition)
        if context.session_valid:
            constraints.append("□session")

        # Build policy: all constraints must be met for permission
        if constraints:
            antecedent = " ∧ ".join(constraints)
            return f"({antecedent}) → P({context.action}_{context.resource})"
        else:
            # No constraints met - access forbidden
            return f"F({context.action}_{context.resource})"

    def check_access(
        self,
        resource: str,
        action: str,
        context: Optional[dict] = None
    ) -> AccessDecision:
        """
        Check if an access request should be allowed.

        This is the main entry point for governance decisions.
        All MCP tool calls should flow through this method.

        Args:
            resource: The resource being accessed (e.g., "patient_records")
            action: The action being taken (e.g., "read", "write", "delete")
            context: Additional context (role, authentication state, etc.)

        Returns:
            AccessDecision with allowed/denied and reasoning trace
        """
        ctx = context or {}

        # Build resource context
        res_ctx = ResourceContext(
            resource=resource,
            action=action,
            user_role=ctx.get("role"),
            authenticated=ctx.get("authenticated", False),
            consent_given=ctx.get("consent", False),
            session_valid=ctx.get("session_valid", False),
            custom_constraints=ctx.get("constraints", {})
        )

        # Build formal policy expression
        policy_expr = self._build_policy_expression(res_ctx)

        # Evaluate through Logic Engine
        try:
            # Use meta-engine for cross-paradigm evaluation
            result = self._run_meta_engine(policy_expr)

            # Parse result
            paradigms = []
            if "BOOLEAN" in result:
                paradigms.append("boolean")
            if "MODAL" in result:
                paradigms.append("modal")
            if "DEONTIC" in result:
                paradigms.append("deontic")

            # Determine if access allowed
            allowed = (
                "VALID" in result or
                "ALLOW" in result or
                ("P(" in policy_expr and "F(" not in policy_expr and res_ctx.authenticated)
            )

            # Handle forbidden explicitly
            if "F(" in policy_expr and not any([
                res_ctx.authenticated,
                res_ctx.user_role,
                res_ctx.consent_given
            ]):
                allowed = False

            decision = AccessDecision(
                allowed=allowed,
                reasoning_trace=result,
                paradigms_used=paradigms,
                confidence=1.0 if "VALID" in result else 0.8,
                policy_expression=policy_expr
            )

        except subprocess.TimeoutExpired:
            decision = AccessDecision(
                allowed=not self.strict_mode,
                reasoning_trace="TIMEOUT: Logic Engine did not respond in time",
                paradigms_used=[],
                confidence=0.0,
                policy_expression=policy_expr
            )

        except Exception as e:
            decision = AccessDecision(
                allowed=not self.strict_mode,
                reasoning_trace=f"ERROR: {str(e)}",
                paradigms_used=[],
                confidence=0.0,
                policy_expression=policy_expr
            )

        # Log decision for audit
        self._access_log.append(decision)
        logger.info(
            f"Access decision: resource={resource} action={action} "
            f"allowed={decision.allowed} paradigms={decision.paradigms_used}"
        )

        return decision

    def check_bio_auth_policy(self, bio_auth_verified: bool) -> AccessDecision:
        """
        Evaluate bio-authentication policy.

        ESN Policy: O(bio_auth) → P(identity_verified)
        """
        if bio_auth_verified:
            policy = "O(bio_auth) → P(identity_verified)"
        else:
            policy = "¬O(bio_auth) → F(access)"

        result = self._run_logic(policy)

        return AccessDecision(
            allowed=bio_auth_verified and "VALID" in result,
            reasoning_trace=result,
            paradigms_used=["deontic"],
            policy_expression=policy
        )

    def check_role_permission(self, role: str, action: str) -> AccessDecision:
        """
        Evaluate role-based access control.

        ESN Role Policies:
            - O(role=admin) → P(delete_data)
            - O(role=operator) → P(control_device)
            - O(role=viewer) → P(view_data) ∧ F(delete_data)
        """
        role_policies = {
            "admin": f"O(role=admin) → P({action})",
            "operator": f"O(role=operator) → P(control) ∧ P(view)",
            "viewer": f"O(role=viewer) → P(view) ∧ F(delete) ∧ F(control)",
        }

        policy = role_policies.get(role, f"F({action})")
        result = self._run_deontic_engine(policy)

        # Check if action is permitted for role
        allowed = "VALID" in result and f"P({action})" in policy
        if role == "viewer" and action in ["delete", "control"]:
            allowed = False

        return AccessDecision(
            allowed=allowed,
            reasoning_trace=result,
            paradigms_used=["deontic"],
            policy_expression=policy
        )

    def get_audit_log(self) -> list[dict]:
        """Return audit log of all access decisions."""
        return [d.to_dict() for d in self._access_log]

    def clear_audit_log(self) -> None:
        """Clear the audit log."""
        self._access_log = []


# MCP Tool Integration Decorator
def governed_access(resource: str, action: str):
    """
    Decorator for MCP tools that require governance.

    Usage:
        @governed_access("patient_records", "read")
        def read_patient_records(patient_id: str):
            # This only executes if access is granted
            ...
    """
    def decorator(func):
        def wrapper(*args, context: dict = None, **kwargs):
            agent = AccessAgent()
            decision = agent.check_access(resource, action, context)

            if not decision.allowed:
                raise PermissionError(
                    f"Access denied: {resource}/{action}\n"
                    f"Reasoning: {decision.reasoning_trace}"
                )

            # Access granted - proceed
            return func(*args, **kwargs)
        return wrapper
    return decorator


if __name__ == "__main__":
    # Demo usage
    print("=" * 60)
    print("ESN Access Agent - Demo")
    print("=" * 60)

    agent = AccessAgent()

    # Test 1: Authenticated user accessing records
    print("\n[Test 1] Authenticated nurse reading patient records:")
    decision = agent.check_access(
        resource="patient_records",
        action="read",
        context={
            "role": "nurse",
            "authenticated": True,
            "session_valid": True
        }
    )
    print(f"  Allowed: {decision.allowed}")
    print(f"  Paradigms: {decision.paradigms_used}")
    print(f"  Policy: {decision.policy_expression}")

    # Test 2: Unauthenticated access attempt
    print("\n[Test 2] Unauthenticated access attempt:")
    decision = agent.check_access(
        resource="patient_records",
        action="read",
        context={}
    )
    print(f"  Allowed: {decision.allowed}")
    print(f"  Policy: {decision.policy_expression}")

    # Test 3: Bio-auth policy
    print("\n[Test 3] Bio-authentication policy check:")
    decision = agent.check_bio_auth_policy(bio_auth_verified=True)
    print(f"  Allowed: {decision.allowed}")
    print(f"  Policy: {decision.policy_expression}")

    # Test 4: Role-based access
    print("\n[Test 4] Role-based access (viewer trying delete):")
    decision = agent.check_role_permission(role="viewer", action="delete")
    print(f"  Allowed: {decision.allowed}")
    print(f"  Policy: {decision.policy_expression}")

    print("\n" + "=" * 60)
    print("Audit Log:")
    for entry in agent.get_audit_log():
        print(f"  {entry['timestamp']}: allowed={entry['allowed']}")
