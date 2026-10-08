#!/usr/bin/env python3
"""
Guardrails Loader - Parse and Enforce Formal Constraints

This module loads guardrails schemes (0-3) from .logic files and provides
constraint checking capabilities for the Access Agent.

Guardrails Schemes:
    - Scheme 0: Security Agent [NOEVO] - BLOCKED (nothing bypasses)
    - Scheme 1: Routing/Tool [NOEVO] - Fixed operational rules
    - Scheme 2: Designer [EVO] - Bounded generation
    - Scheme 3: Composer [EVO] - Bounded composition

Constraint Types:
    - F(x): Forbidden - action x is NEVER allowed
    - O(x): Obligatory - action x MUST be performed
    - P(x): Permitted - action x is allowed (given conditions)
    - □(x): Necessary - x must always hold (temporal)

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
"""

import re
import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional
from enum import Enum

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("guardrails")

# Path to guardrails schemes
GUARDRAILS_DIR = Path(__file__).parent / "guardrails"


class ConstraintType(Enum):
    """Types of deontic constraints."""
    FORBIDDEN = "F"      # F(x) - NEVER allowed
    OBLIGATORY = "O"     # O(x) - MUST be done
    PERMITTED = "P"      # P(x) - Allowed (conditional)
    NECESSARY = "□"      # □(x) - Must always hold


class AgentType(Enum):
    """Agent classification for EVO/NOEVO model."""
    NOEVO = "noevo"          # Fixed, verified, immutable
    EVO = "evo"              # Adaptive within bounds
    CONTROLLED = "controlled" # Human authorization required
    UNKNOWN = "unknown"      # Not registered in any scheme: trusted for nothing


# ---------------------------------------------------------------------------
# Condition evaluation
#
# A permitted or obligatory constraint may carry a condition after "←":
#     P(route_to_evo_agent) ← authenticated(user) ∧ bounded(request)
# Conditions are conjunctions/disjunctions of atoms. An atom "name(arg)" or
# "name" holds when the request context has a truthy value under "name", or
# lists the atom (with or without its argument) in context["facts"].
# ---------------------------------------------------------------------------

_COND_ATOM = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)(?:\(([^)]*)\))?$')
_DEONTIC_ATOM = re.compile(r'^[FOPfop]\(([^)]+)\)$')


def atom_holds(atom: str, context: dict) -> Optional[bool]:
    """True/False for a condition atom, None if the atom is not well formed."""
    atom = atom.strip()
    match = _COND_ATOM.match(atom)
    if not match:
        return None
    name = match.group(1)
    facts = context.get("facts") or ()
    if atom in facts or name in facts:
        return True
    value = context.get(name)
    if isinstance(value, bool):
        return value
    if value is None:
        return False
    return bool(value)


def evaluate_condition(condition: str, context: dict) -> Optional[bool]:
    """
    Evaluate a "←" condition against a request context.

    Supports atoms joined by ∧ (all must hold) and ∨ (any must hold), with
    ∧ binding tighter than ∨. Returns None if any atom is not well formed,
    so a condition the enforcer cannot read is never silently satisfied.
    """
    condition = condition.strip()
    if condition.startswith("(") and condition.endswith(")"):
        condition = condition[1:-1].strip()
    disjuncts = [d for d in re.split(r'\s*∨\s*', condition) if d]
    if not disjuncts:
        return None
    any_true = False
    for disjunct in disjuncts:
        values = [atom_holds(a, context) for a in re.split(r'\s*∧\s*', disjunct) if a]
        if not values or any(v is None for v in values):
            return None
        if all(values):
            any_true = True
    return any_true


# ---------------------------------------------------------------------------
# Temporal bounds
#
#     □(idle_session_timeout ≤ 30m)      □[0,1h](design_proposals ≤ 5)
#
# A bound compares a named metric with a limit. Limits are durations
# (ms, s, m, h, d → seconds), sizes (KB, MB, GB → bytes), percentages,
# money ($) or plain numbers. A symbolic limit (tool.timeout, allocated)
# cannot be enforced by the loader and is reported as such.
# ---------------------------------------------------------------------------

_BOUND = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)\s*(≤|<|≥|>|=|≠|<=|>=|==)\s*(.+)$')
_UNITS = {
    "ms": 0.001, "s": 1.0, "m": 60.0, "h": 3600.0, "d": 86400.0,
    "kb": 1024.0, "mb": 1024.0 ** 2, "gb": 1024.0 ** 3,
    "%": 1.0,
}
_LIMIT = re.compile(r'^\$?\s*([0-9]+(?:\.[0-9]+)?)\s*([A-Za-z%]*)$')
_COMPARE = {
    "≤": lambda a, b: a <= b, "<=": lambda a, b: a <= b,
    "<": lambda a, b: a < b,
    "≥": lambda a, b: a >= b, ">=": lambda a, b: a >= b,
    ">": lambda a, b: a > b,
    "=": lambda a, b: a == b, "==": lambda a, b: a == b,
    "≠": lambda a, b: a != b,
}


def parse_limit(text: str) -> Optional[float]:
    """Numeric value of a bound's limit in base units, or None if symbolic."""
    match = _LIMIT.match(text.strip())
    if not match:
        return None
    number, unit = float(match.group(1)), match.group(2).lower()
    if not unit:
        return number
    if unit in _UNITS:
        return number * _UNITS[unit]
    return None


@dataclass
class TemporalBound:
    """A machine-checkable □(metric op limit) constraint."""
    metric: str
    operator: str
    limit: float
    limit_text: str
    window: Optional[str]
    constraint: "Constraint"

    def holds(self, value: float) -> bool:
        return _COMPARE[self.operator](value, self.limit)

    def __str__(self) -> str:
        window = f"[{self.window}]" if self.window else ""
        return f"□{window}({self.metric} {self.operator} {self.limit_text})"


@dataclass
class Constraint:
    """A single formal constraint from a guardrails scheme."""
    constraint_type: ConstraintType
    action: str
    condition: Optional[str] = None
    temporal_bound: Optional[str] = None  # e.g., "[0,50ms]"
    raw_expression: str = ""

    def __str__(self) -> str:
        if self.condition:
            return f"{self.constraint_type.value}({self.action}) ← {self.condition}"
        return f"{self.constraint_type.value}({self.action})"


@dataclass
class GuardrailsScheme:
    """A complete guardrails scheme with all constraints."""
    scheme_id: int
    name: str
    agent_type: AgentType
    description: str
    forbidden: list[Constraint] = field(default_factory=list)
    obligatory: list[Constraint] = field(default_factory=list)
    permitted: list[Constraint] = field(default_factory=list)
    temporal: list[Constraint] = field(default_factory=list)

    def get_all_forbidden_actions(self) -> set[str]:
        """Return all forbidden action names."""
        return {c.action for c in self.forbidden}

    def get_all_obligatory_actions(self) -> set[str]:
        """Return all obligatory action names."""
        return {c.action for c in self.obligatory}

    def is_action_forbidden(self, action: str) -> bool:
        """Check if an action is forbidden by this scheme."""
        return action in self.get_all_forbidden_actions()

    def get_forbidden_constraint(self, action: str) -> Optional[Constraint]:
        """Get the constraint that forbids an action."""
        for c in self.forbidden:
            if c.action == action:
                return c
        return None

    def temporal_bounds(self) -> tuple[list[TemporalBound], list[Constraint]]:
        """
        Split the temporal constraints into machine-checkable bounds and
        the rest (symbolic limits such as "tool.timeout", and implications
        such as "security_violation → O(escalate_to_human)").
        """
        bounds, other = [], []
        for c in self.temporal:
            match = _BOUND.match(c.action)
            limit = parse_limit(match.group(3)) if match else None
            if match and limit is not None:
                bounds.append(TemporalBound(
                    metric=match.group(1), operator=match.group(2), limit=limit,
                    limit_text=match.group(3).strip(), window=c.temporal_bound,
                    constraint=c
                ))
            else:
                other.append(c)
        return bounds, other


class GuardrailsLoader:
    """
    Loads and manages guardrails schemes.

    Usage:
        loader = GuardrailsLoader()
        scheme0 = loader.get_scheme(0)

        # Check if action is forbidden
        if scheme0.is_action_forbidden("bypass_authentication"):
            raise SecurityViolation("Forbidden by Scheme 0")
    """

    def __init__(self, guardrails_dir: Optional[Path] = None):
        """
        Initialize the loader.

        Args:
            guardrails_dir: Directory containing .logic files
        """
        self.guardrails_dir = guardrails_dir or GUARDRAILS_DIR
        self.schemes: dict[int, GuardrailsScheme] = {}
        self._load_all_schemes()

    def _load_all_schemes(self):
        """Load all guardrails schemes from disk."""
        for scheme_id in range(4):  # Schemes 0-3
            scheme = self._load_scheme(scheme_id)
            if scheme:
                self.schemes[scheme_id] = scheme
                logger.info(
                    f"Loaded Scheme {scheme_id}: {scheme.name} "
                    f"({len(scheme.forbidden)} forbidden, "
                    f"{len(scheme.obligatory)} obligatory, "
                    f"{len(scheme.permitted)} permitted)"
                )

    def _load_scheme(self, scheme_id: int) -> Optional[GuardrailsScheme]:
        """Load a single scheme from its .logic file."""
        file_path = self.guardrails_dir / f"scheme-{scheme_id}.logic"

        if not file_path.exists():
            logger.warning(f"Scheme file not found: {file_path}")
            return None

        # Scheme metadata
        scheme_names = {
            0: ("Security Agent - BLOCKED", AgentType.NOEVO),
            1: ("Routing/Tool - Fixed Rules", AgentType.NOEVO),
            2: ("Designer - Bounded Generation", AgentType.EVO),
            3: ("Composer - Bounded Composition", AgentType.EVO),
        }

        name, agent_type = scheme_names.get(scheme_id, (f"Scheme {scheme_id}", AgentType.NOEVO))

        scheme = GuardrailsScheme(
            scheme_id=scheme_id,
            name=name,
            agent_type=agent_type,
            description=f"Guardrails for {name}"
        )

        # Parse the file
        with open(file_path, 'r') as f:
            for lineno, raw in enumerate(f, 1):
                # Drop trailing comments ("□(x ≤ 5s)  # Default timeout")
                line = raw.split('#', 1)[0].strip()

                # Skip comments and empty lines
                if not line:
                    continue

                # Parse constraint
                constraint = self._parse_constraint(line)
                if constraint is None:
                    logger.warning(
                        f"{file_path.name}:{lineno}: unparsed constraint, "
                        f"not enforced: {line}"
                    )
                elif constraint:
                    if constraint.constraint_type == ConstraintType.FORBIDDEN:
                        scheme.forbidden.append(constraint)
                    elif constraint.constraint_type == ConstraintType.OBLIGATORY:
                        scheme.obligatory.append(constraint)
                    elif constraint.constraint_type == ConstraintType.PERMITTED:
                        scheme.permitted.append(constraint)
                    elif constraint.constraint_type == ConstraintType.NECESSARY:
                        scheme.temporal.append(constraint)

        return scheme

    def _parse_constraint(self, line: str) -> Optional[Constraint]:
        """Parse a single constraint line."""
        # Pattern for F(action), O(action), P(action)
        deontic_pattern = r'^([FOPfop])\(([^)]+)\)(?:\s*←\s*(.+))?$'
        # Pattern for □(expression) or □[bounds](expression)
        temporal_pattern = r'^□(?:\[([^\]]+)\])?\((.+)\)$'
        # Pattern for a conditional obligation: P(x) → O(y), F(x) → O(y)
        conditional_pattern = r'^([FOPfop]\([^)]+\))\s*→\s*[Oo]\(([^)]+)\)$'

        # Try conditional obligation first (it also contains "O(...)")
        match = re.match(conditional_pattern, line)
        if match:
            return Constraint(
                constraint_type=ConstraintType.OBLIGATORY,
                action=match.group(2).strip(),
                condition=match.group(1).strip(),
                raw_expression=line
            )

        # Try deontic pattern
        match = re.match(deontic_pattern, line)
        if match:
            constraint_char = match.group(1).upper()
            action = match.group(2).strip()
            condition = match.group(3).strip() if match.group(3) else None

            constraint_type = {
                'F': ConstraintType.FORBIDDEN,
                'O': ConstraintType.OBLIGATORY,
                'P': ConstraintType.PERMITTED,
            }.get(constraint_char)

            if constraint_type:
                return Constraint(
                    constraint_type=constraint_type,
                    action=action,
                    condition=condition,
                    raw_expression=line
                )

        # Try temporal pattern
        match = re.match(temporal_pattern, line)
        if match:
            temporal_bound = match.group(1)
            expression = match.group(2).strip()

            return Constraint(
                constraint_type=ConstraintType.NECESSARY,
                action=expression,
                temporal_bound=temporal_bound,
                raw_expression=line
            )

        return None

    def get_scheme(self, scheme_id: int) -> Optional[GuardrailsScheme]:
        """Get a scheme by ID."""
        return self.schemes.get(scheme_id)

    def get_scheme_for_agent(self, agent_name: str) -> Optional[GuardrailsScheme]:
        """
        Get the appropriate scheme for an agent.

        Agent → Scheme mapping:
            security_agent → 0
            routing_agent, tool_agent, orchestrator_agent → 1
            designer_agent → 2
            composer_agent → 3
        """
        agent_schemes = {
            "security_agent": 0,
            "security": 0,
            "routing_agent": 1,
            "routing": 1,
            "tool_agent": 1,
            "tool": 1,
            "orchestrator_agent": 1,
            "orchestrator": 1,
            "designer_agent": 2,
            "designer": 2,
            "composer_agent": 3,
            "composer": 3,
            "monitor_agent": 2,  # EVO but read-only
            "monitor": 2,
            "ops_agent": 2,  # EVO but bounded
            "ops": 2,
        }

        scheme_id = agent_schemes.get(agent_name.lower())
        if scheme_id is not None:
            return self.get_scheme(scheme_id)
        return None


class GuardrailsEnforcer:
    """
    Enforces guardrails constraints on actions.

    This is used by the Access Agent to check if actions are allowed
    before execution.
    """

    def __init__(self, loader: Optional[GuardrailsLoader] = None):
        """
        Initialize the enforcer.

        Args:
            loader: GuardrailsLoader instance (creates one if not provided)
        """
        self.loader = loader or GuardrailsLoader()
        self._scheme0 = self.loader.get_scheme(0)  # Security scheme always checked

    def check_action(
        self,
        action: str,
        agent_name: str,
        context: Optional[dict] = None
    ) -> tuple[bool, str]:
        """
        Check if an action is allowed for an agent.

        Args:
            action: The action being attempted
            agent_name: The agent attempting the action
            context: Additional context for condition evaluation

        Returns:
            Tuple of (allowed, reason)
        """
        context = context or {}

        # ALWAYS check Scheme 0 first (Security Agent constraints)
        if self._scheme0:
            if self._scheme0.is_action_forbidden(action):
                constraint = self._scheme0.get_forbidden_constraint(action)
                return False, f"BLOCKED by Scheme 0: {constraint}"

        # Get agent's specific scheme. An agent that is not registered in
        # any scheme has no permissions at all: deny rather than fall back
        # to "only Scheme 0 applies", which was the least restrictive case.
        agent_scheme = self.loader.get_scheme_for_agent(agent_name)
        if not agent_scheme:
            logger.warning(f"No scheme found for agent: {agent_name}")
            return False, f"DENIED: no guardrails scheme registered for agent '{agent_name}'"

        # Check agent's scheme for forbidden actions
        if agent_scheme.is_action_forbidden(action):
            constraint = agent_scheme.get_forbidden_constraint(action)
            return False, f"Forbidden by Scheme {agent_scheme.scheme_id}: {constraint}"

        # A conditional permission "P(x) ← cond" is enforced when x is the
        # action being exercised: cond must hold in the request context. A
        # condition the enforcer cannot read is treated as not met.
        # (Permissions are not an allowlist: an action with no P() entry is
        # governed by the forbidden and obligatory constraints alone.)
        for permitted in agent_scheme.permitted:
            if permitted.condition and permitted.action == action:
                holds = evaluate_condition(permitted.condition, context)
                if holds is None:
                    return False, f"Condition not evaluable for {permitted}"
                if not holds:
                    return False, f"Condition not met for {permitted}"

        # Obligations. Three ways an obligation can apply to this action:
        #   O(y) ← P(x)      when the action is x (or x_...)
        #   O(y) ← cond      when cond holds in the request context
        #   O(y)             when the built-in prerequisite table says so
        for obligatory in agent_scheme.obligatory:
            if self._obligation_applies(obligatory, action, context):
                if not self._is_obligation_satisfied(obligatory, context):
                    return False, f"Obligation not met: {obligatory}"

        return True, f"Allowed by Scheme {agent_scheme.scheme_id}"

    def _obligation_applies(self, obligation: Constraint, action: str, context: dict) -> bool:
        """Does this obligation bind the current action?"""
        if obligation.condition:
            match = _DEONTIC_ATOM.match(obligation.condition.strip())
            if match:
                trigger = match.group(1).strip()
                return action == trigger or action.startswith(trigger + "_")
            return evaluate_condition(obligation.condition, context) is True
        return self._action_requires(action, obligation.action)

    def check_temporal_bounds(
        self,
        agent_name: str,
        metrics: dict
    ) -> tuple[bool, list[str]]:
        """
        Check measured values against the □(metric op limit) bounds of
        Scheme 0 and the agent's scheme.

        Args:
            agent_name: the agent whose scheme applies (Scheme 0 always does)
            metrics: metric name → measured value in base units (seconds,
                     bytes, percent, count). Metrics with no bound are ignored;
                     bounds with no metric are not checked.

        Returns:
            (all_hold, violations) where each violation names the bound and
            the measured value.
        """
        schemes = [s for s in (self._scheme0, self.loader.get_scheme_for_agent(agent_name)) if s]
        violations = []
        seen = set()
        for scheme in schemes:
            if scheme.scheme_id in seen:
                continue
            seen.add(scheme.scheme_id)
            bounds, _ = scheme.temporal_bounds()
            for bound in bounds:
                if bound.metric not in metrics:
                    continue
                try:
                    value = float(metrics[bound.metric])
                except (TypeError, ValueError):
                    violations.append(f"Scheme {scheme.scheme_id}: {bound} has non-numeric value {metrics[bound.metric]!r}")
                    continue
                if not bound.holds(value):
                    violations.append(f"Scheme {scheme.scheme_id}: {bound} violated, measured {value:g}")
        return not violations, violations

    def unenforceable_temporal(self) -> dict[int, list[str]]:
        """Temporal constraints per scheme that the enforcer cannot check."""
        return {
            sid: [c.raw_expression for c in scheme.temporal_bounds()[1]]
            for sid, scheme in sorted(self.loader.schemes.items())
        }

    def _action_requires(self, action: str, prerequisite: str) -> bool:
        """Check if an action has a prerequisite."""
        # Common prerequisites
        prerequisites = {
            "access": ["verify_before_execute", "log_all_decisions"],
            "read": ["check_authorization_before_access"],
            "write": ["check_authorization_before_access", "log_all_decisions"],
            "delete": ["check_authorization_before_access", "log_all_decisions"],
            "generate": ["submit_for_verification"],
            "deploy": ["verify_before_execute"],
            "compose": ["verify_composition_result"],
        }

        required = prerequisites.get(action.split('_')[0], [])
        return prerequisite in required

    def _is_obligation_satisfied(self, obligation: Constraint, context: dict) -> bool:
        """Check if an obligation is satisfied by the context."""
        # Check if the obligatory action has been performed
        performed_actions = context.get("performed_actions", [])
        return obligation.action in performed_actions

    def get_agent_type(self, agent_name: str) -> AgentType:
        """
        Get the agent type (EVO/NOEVO) for an agent.

        An unregistered agent is UNKNOWN. It must not default to NOEVO:
        NOEVO is the trusted class (NOEVO → NOEVO calls are direct), so that
        default handed the most trust to the least known caller.
        """
        scheme = self.loader.get_scheme_for_agent(agent_name)
        if scheme:
            return scheme.agent_type
        return AgentType.UNKNOWN

    def is_evo_agent(self, agent_name: str) -> bool:
        """Check if an agent is EVO (can evolve)."""
        return self.get_agent_type(agent_name) == AgentType.EVO

    def is_noevo_agent(self, agent_name: str) -> bool:
        """Check if an agent is NOEVO (fixed)."""
        return self.get_agent_type(agent_name) == AgentType.NOEVO

    def get_all_forbidden(self) -> set[str]:
        """Get all actions forbidden by Scheme 0."""
        if self._scheme0:
            return self._scheme0.get_all_forbidden_actions()
        return set()


# Convenience singleton
_default_enforcer: Optional[GuardrailsEnforcer] = None


def get_enforcer() -> GuardrailsEnforcer:
    """Get the default guardrails enforcer."""
    global _default_enforcer
    if _default_enforcer is None:
        _default_enforcer = GuardrailsEnforcer()
    return _default_enforcer


if __name__ == "__main__":
    # Demo
    print("=" * 60)
    print("Guardrails Loader - Demo")
    print("=" * 60)

    loader = GuardrailsLoader()
    enforcer = GuardrailsEnforcer(loader)

    # Show loaded schemes
    print("\n[1] Loaded Schemes:")
    for scheme_id, scheme in loader.schemes.items():
        print(f"    Scheme {scheme_id}: {scheme.name}")
        print(f"      Agent Type: {scheme.agent_type.value}")
        print(f"      Forbidden: {len(scheme.forbidden)}")
        print(f"      Obligatory: {len(scheme.obligatory)}")
        print(f"      Permitted: {len(scheme.permitted)}")
        print(f"      Temporal: {len(scheme.temporal)}")

    # Test enforcement
    print("\n[2] Testing Enforcement:")

    test_cases = [
        ("harm_user", "tool_agent"),
        ("bypass_authentication", "security_agent"),
        ("read_data", "tool_agent"),
        ("generate_workflow", "designer_agent"),
        ("execute_unverified_workflow", "orchestrator_agent"),
        ("leak_credentials", "any_agent"),
    ]

    for action, agent in test_cases:
        allowed, reason = enforcer.check_action(action, agent)
        status = "✓ ALLOWED" if allowed else "✗ DENIED"
        print(f"    {action} by {agent}: {status}")
        print(f"      Reason: {reason}")

    # Show agent types
    print("\n[3] Agent Classifications:")
    agents = ["security_agent", "routing_agent", "tool_agent", "designer_agent", "composer_agent"]
    for agent in agents:
        agent_type = enforcer.get_agent_type(agent)
        print(f"    {agent}: {agent_type.value.upper()}")

    # Show all forbidden actions
    print("\n[4] All Forbidden Actions (Scheme 0):")
    for action in sorted(enforcer.get_all_forbidden()):
        print(f"    F({action})")

    print("\n" + "=" * 60)
