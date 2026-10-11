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
    multi-paradigm formal reasoning (Boolean, Modal, Deontic). Policies live
    in policies/access.policy (see access_policies.py); a request's context
    becomes facts, and engines/meta.sh -a decides the facts against the
    policy for the resource and action.

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

import re
import subprocess
import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional
from datetime import datetime, timezone

from access_policies import PolicyStore, get_policy_store

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("access_agent")

# Logic Engine path (symlinked from ESN)
LOGIC_ENGINE_DIR = Path(__file__).parent / "logic-engine"
LOGIC_ENGINE = LOGIC_ENGINE_DIR / "logic"
META_ENGINE = LOGIC_ENGINE_DIR / "engines" / "meta.sh"
DEONTIC_ENGINE = LOGIC_ENGINE_DIR / "engines" / "deontic.sh"

# Every value interpolated into a policy expression must be a bare
# identifier. The expression is evaluated by a shell engine, and bash
# arithmetic performs command substitution before it evaluates, so anything
# outside this alphabet is rejected before it is built into an expression.
IDENTIFIER = re.compile(r"^[A-Za-z][A-Za-z0-9_]*$")

# A request fact: an identifier, optionally "=value" (role=nurse).
FACT = re.compile(r"^[A-Za-z][A-Za-z0-9_]*(=[A-Za-z0-9_]+)?$")

# The verdict line of engines/meta.sh -a
RE_DECISION = re.compile(r"^DECISION:\s*(ALLOW|DENY|CONFLICT)\b\s*(.*)$", re.MULTILINE)
RE_POLICY_PARADIGMS = re.compile(r"^Policy Paradigms:\s*(.*)$", re.MULTILINE)

# Whole-word verdicts. "VALID" in result would also match "INVALID".
RE_VALID = re.compile(r"(?<![A-Z])VALID(?![A-Z])")
RE_CONFLICT = re.compile(r"\b(INCONSISTENT|CONFLICT)\b")
RE_ERROR = re.compile(r"^(ERROR|TIMEOUT)\b", re.MULTILINE)
RE_PARADIGMS = re.compile(r"^PARADIGMS_EVALUATED:\s*(.*)$", re.MULTILINE)


def is_identifier(value: Optional[str]) -> bool:
    """True if value is safe to interpolate into a policy expression."""
    return value is not None and bool(IDENTIFIER.match(value))


@dataclass
class AccessDecision:
    """Result of an access control decision."""
    allowed: bool
    reasoning_trace: str
    paradigms_used: list[str] = field(default_factory=list)
    confidence: float = 1.0
    timestamp: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    policy_expression: str = ""
    request_facts: str = ""

    def to_dict(self) -> dict:
        return {
            "allowed": self.allowed,
            "reasoning_trace": self.reasoning_trace,
            "paradigms_used": self.paradigms_used,
            "confidence": self.confidence,
            "timestamp": self.timestamp,
            "policy_expression": self.policy_expression,
            "request_facts": self.request_facts
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

    def __init__(self, strict_mode: bool = True, policy_store: Optional[PolicyStore] = None):
        """
        Initialize the Access Agent.

        Args:
            strict_mode: If True, deny access on any engine failure
            policy_store: Source of resource.action → policy (default:
                policies/access.policy)
        """
        self.strict_mode = strict_mode
        self.policies = policy_store or get_policy_store()
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

    def _run_meta_access(self, policy: str, facts: str) -> str:
        """Decide request facts against a policy (engines/meta.sh -a)."""
        result = subprocess.run(
            [str(META_ENGINE), "-a", policy, facts],
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

    @staticmethod
    def _build_request_facts(context: ResourceContext, extra_facts: list[str]) -> list[str]:
        """
        What is true of this request, in the request syntax of meta.sh -a.

        The facts come from the request; the policy comes from the store.
        Keeping those two sources apart is the point: a policy derived from
        the request's own flags could never contradict the request.
        """
        facts = []
        if context.authenticated:
            facts.append("auth")
        if context.user_role:
            facts.append(f"role={context.user_role}")
        if context.consent_given:
            facts.append("consent")
        if context.session_valid:
            facts.append("session")
        for fact in extra_facts:
            if fact not in facts:
                facts.append(fact)
        return facts

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
            context: Additional context: role, authenticated, consent,
                session_valid, and facts (a list of further identifiers the
                policy may refer to, e.g. ["verified"])

        Returns:
            AccessDecision with allowed/denied and reasoning trace

        Decision:
            1. resource, action, role and facts must be bare identifiers.
            2. The policy for resource.action comes from the policy store;
               none means DENY.
            3. engines/meta.sh -a decides the request's facts against the
               policy: ALLOW, DENY (with the unmet precondition) or
               CONFLICT (the policy is inconsistent).
            4. Authentication is required for every ALLOW, whatever the
               policy says (defence in depth).
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
        extra_facts = [str(f) for f in (ctx.get("facts") or [])]

        # Reject anything that is not a bare identifier before it reaches
        # the shell engines (see IDENTIFIER).
        bad = [
            name for name, value in (
                ("resource", resource), ("action", action), ("role", res_ctx.user_role)
            )
            if value is not None and not is_identifier(value)
        ]
        if any(not FACT.match(f) for f in extra_facts):
            bad.append("facts")
        if bad:
            decision = AccessDecision(
                allowed=False,
                reasoning_trace=f"REJECTED: invalid identifier in {', '.join(bad)}",
                paradigms_used=[],
                confidence=0.0,
                policy_expression="",
            )
            self._access_log.append(decision)
            logger.warning(
                f"Access rejected: resource={resource!r} action={action!r} "
                f"invalid identifier in {bad}"
            )
            return decision

        facts = self._build_request_facts(res_ctx, extra_facts)
        facts_expr = " ∧ ".join(facts)

        # The policy comes from the store, never from the request
        policy = self.policies.lookup(resource, action)
        if policy is None:
            decision = AccessDecision(
                allowed=False,
                reasoning_trace=f"DENY: no policy for {resource}.{action} (deny by default)",
                paradigms_used=[],
                confidence=1.0,
                policy_expression=f"F({action}_{resource})",
                request_facts=facts_expr,
            )
            self._access_log.append(decision)
            logger.info(f"Access decision: resource={resource} action={action} allowed=False (no policy)")
            return decision

        try:
            result = self._run_meta_access(policy.expression, facts_expr)

            paradigms_match = RE_POLICY_PARADIGMS.search(result)
            paradigms = paradigms_match.group(1).split() if paradigms_match else []
            verdicts = RE_DECISION.findall(result)
            verdict, reason = verdicts[-1] if verdicts else ("DENY", "(engine returned no decision)")

            trace_lines = [f"{verdict}: {reason.strip() or 'policy ' + policy.key} [{policy.source}]"]
            allowed = verdict == "ALLOW"
            if allowed and not res_ctx.authenticated:
                # The store should never grant an unauthenticated request;
                # if a policy does, authentication still wins.
                allowed = False
                trace_lines.insert(0, "DENY: authentication required")

            decision = AccessDecision(
                allowed=allowed,
                reasoning_trace="\n".join(trace_lines) + "\n" + result,
                paradigms_used=paradigms,
                confidence=1.0 if verdicts else 0.0,
                policy_expression=policy.expression,
                request_facts=facts_expr,
            )

        except subprocess.TimeoutExpired:
            decision = AccessDecision(
                allowed=not self.strict_mode,
                reasoning_trace="TIMEOUT: Logic Engine did not respond in time",
                paradigms_used=[],
                confidence=0.0,
                policy_expression=policy.expression,
                request_facts=facts_expr,
            )

        except Exception as e:
            decision = AccessDecision(
                allowed=not self.strict_mode,
                reasoning_trace=f"ERROR: {str(e)}",
                paradigms_used=[],
                confidence=0.0,
                policy_expression=policy.expression,
                request_facts=facts_expr,
            )

        # Log decision for audit
        self._access_log.append(decision)
        logger.info(
            f"Access decision: resource={resource} action={action} "
            f"facts=[{facts_expr}] allowed={decision.allowed} paradigms={decision.paradigms_used}"
        )

        return decision

    def check_bio_auth_policy(self, bio_auth_verified: bool) -> AccessDecision:
        """
        Evaluate bio-authentication policy.

        ESN Policy: O(bio_auth) → P(identity_verified)

        The verified flag is the fact; the deontic engine checks the policy
        statement is consistent and supplies the trace.
        """
        if bio_auth_verified:
            policy = "O(bio_auth) → P(identity_verified)"
        else:
            policy = "¬O(bio_auth) → F(access)"

        consistency = self._run_deontic_engine(policy, check_consistency=True)
        consistent = not RE_CONFLICT.search(consistency)

        return AccessDecision(
            allowed=bio_auth_verified and consistent,
            reasoning_trace=consistency,
            paradigms_used=["deontic"],
            confidence=1.0 if consistent else 0.0,
            policy_expression=policy
        )

    # Actions each role may perform. "*" means any action.
    ROLE_PERMISSIONS = {
        "admin": {"*"},
        "operator": {"control", "view"},
        "viewer": {"view"},
    }

    def check_role_permission(self, role: str, action: str) -> AccessDecision:
        """
        Evaluate role-based access control.

        ESN Role Policies:
            - O(role=admin) → P(delete_data)
            - O(role=operator) → P(control_device)
            - O(role=viewer) → P(view_data) ∧ F(delete_data)

        The permission table decides; the deontic engine checks that the
        policy statement built for the role is consistent (no action both
        permitted and forbidden) and supplies the trace.
        """
        if not is_identifier(role) or not is_identifier(action):
            return AccessDecision(
                allowed=False,
                reasoning_trace="REJECTED: invalid identifier in role or action",
                paradigms_used=["deontic"],
                confidence=0.0,
            )

        permitted = self.ROLE_PERMISSIONS.get(role)
        if permitted is None:
            policy = f"F({action})"
            role_allows = False
        else:
            role_allows = "*" in permitted or action in permitted
            verdict = "P" if role_allows else "F"
            policy = f"O(role={role}) → {verdict}({action})"

        consistency = self._run_deontic_engine(policy, check_consistency=True)
        consistent = not RE_CONFLICT.search(consistency)

        return AccessDecision(
            allowed=role_allows and consistent,
            reasoning_trace=consistency,
            paradigms_used=["deontic"],
            confidence=1.0 if consistent else 0.0,
            policy_expression=policy
        )

    def get_audit_log(self) -> list[dict]:
        """Return audit log of all access decisions."""
        return [d.to_dict() for d in self._access_log]

    def clear_audit_log(self) -> None:
        """Clear the audit log."""
        self._access_log = []


# Shared agent for the decorator. Constructing an AccessAgent runs a health
# check against the engine (about 90 ms), so one per call is wasteful.
_default_agent: Optional[AccessAgent] = None


def get_access_agent() -> AccessAgent:
    """Return the process-wide AccessAgent, creating it on first use."""
    global _default_agent
    if _default_agent is None:
        _default_agent = AccessAgent()
    return _default_agent


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
            decision = get_access_agent().check_access(resource, action, context)

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
    print(f"  Facts: {decision.request_facts}")
    print(f"  Policy: {decision.policy_expression}")

    # Test 1b: Authenticated nurse, but no live session
    print("\n[Test 1b] Authenticated nurse without a heartbeat session:")
    decision = agent.check_access(
        resource="patient_records",
        action="read",
        context={"role": "nurse", "authenticated": True}
    )
    print(f"  Allowed: {decision.allowed}")
    print(f"  Reason: {decision.reasoning_trace.splitlines()[0]}")

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
