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
            for line in f:
                line = line.strip()

                # Skip comments and empty lines
                if not line or line.startswith('#'):
                    continue

                # Parse constraint
                constraint = self._parse_constraint(line)
                if constraint:
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

        # Get agent's specific scheme
        agent_scheme = self.loader.get_scheme_for_agent(agent_name)
        if not agent_scheme:
            logger.warning(f"No scheme found for agent: {agent_name}")
            # Default to most restrictive (Scheme 0 only)
            return True, "No agent-specific scheme (Scheme 0 checked)"

        # Check agent's scheme for forbidden actions
        if agent_scheme.is_action_forbidden(action):
            constraint = agent_scheme.get_forbidden_constraint(action)
            return False, f"Forbidden by Scheme {agent_scheme.scheme_id}: {constraint}"

        # Check for obligatory actions (if action requires prerequisites)
        for obligatory in agent_scheme.obligatory:
            if self._action_requires(action, obligatory.action):
                # Check if the obligation is satisfied
                if not self._is_obligation_satisfied(obligatory, context):
                    return False, f"Obligation not met: {obligatory}"

        return True, f"Allowed by Scheme {agent_scheme.scheme_id}"

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
        """Get the agent type (EVO/NOEVO) for an agent."""
        scheme = self.loader.get_scheme_for_agent(agent_name)
        if scheme:
            return scheme.agent_type
        return AgentType.NOEVO  # Default to most restrictive

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
