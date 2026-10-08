#!/usr/bin/env python3
"""
Governance Layer Test Suite

Comprehensive tests for the ESN Governance Layer proving:
    1. Guardrails enforcement works
    2. EVO/NOEVO classification is correct
    3. Logic Engine integration functions
    4. MCP tool protection works
    5. Forbidden actions are ALWAYS blocked

Run:
    python3 test_governance.py
    python3 test_governance.py --verbose
    python3 test_governance.py --category guardrails

Categories: guardrails, classification, logic_engine, evo_noevo,
            complete_flow, heartbeat

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
"""

import asyncio
import os
import sys
import argparse
import tempfile
from dataclasses import dataclass
from typing import Optional
from datetime import datetime, timedelta, timezone

# Import governance components
from guardrails_loader import GuardrailsEnforcer, AgentType, get_enforcer, evaluate_condition
from access_agent import AccessAgent
from governed_access import GovernanceGateway, governed_mcp_tool
from heartbeat import HeartbeatManager, HeartbeatPayload, DeviceInfo, SessionState, accept_any_token


@dataclass
class TestResult:
    """Result of a single test."""
    name: str
    category: str
    passed: bool
    expected: str
    actual: str
    duration_ms: float = 0.0
    notes: str = ""


class GovernanceTestSuite:
    """
    Comprehensive test suite for the governance layer.
    """

    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.results: list[TestResult] = []
        self.enforcer = get_enforcer()
        self.gateway = None  # Lazy init

    def _init_gateway(self):
        """Initialize gateway (expensive, only when needed)."""
        if self.gateway is None:
            self.gateway = GovernanceGateway(
                heartbeat_manager=HeartbeatManager(token_validator=accept_any_token)
            )

    def log(self, msg: str):
        """Log if verbose mode."""
        if self.verbose:
            print(f"  {msg}")

    # =========================================================================
    # Category 1: Guardrails Enforcement
    # =========================================================================

    def test_scheme0_forbidden_actions(self) -> list[TestResult]:
        """Test that Scheme 0 forbidden actions are always blocked."""
        results = []

        # Critical forbidden actions from Scheme 0
        forbidden_actions = [
            "harm_user",
            "bypass_authentication",
            "leak_credentials",
            "disable_logging",
            "modify_noevo_agent",
            "spawn_unregistered_agent",
            "transmit_phi_unencrypted",
            "self_modify_security",
        ]

        agents = ["tool_agent", "designer_agent", "security_agent", "any_agent"]

        for action in forbidden_actions:
            for agent in agents:
                allowed, reason = self.enforcer.check_action(action, agent)

                result = TestResult(
                    name=f"Block F({action}) for {agent}",
                    category="guardrails",
                    passed=not allowed,  # Should NOT be allowed
                    expected="DENIED",
                    actual="DENIED" if not allowed else "ALLOWED",
                    notes=reason
                )
                results.append(result)
                self.log(f"{'✓' if result.passed else '✗'} {result.name}")

        return results

    def test_noevo_agent_classification(self) -> list[TestResult]:
        """Test that NOEVO agents are correctly classified."""
        results = []

        noevo_agents = [
            "security_agent",
            "routing_agent",
            "tool_agent",
            "orchestrator_agent",
        ]

        for agent in noevo_agents:
            agent_type = self.enforcer.get_agent_type(agent)
            passed = agent_type == AgentType.NOEVO

            result = TestResult(
                name=f"{agent} is NOEVO",
                category="classification",
                passed=passed,
                expected="NOEVO",
                actual=agent_type.value.upper()
            )
            results.append(result)
            self.log(f"{'✓' if result.passed else '✗'} {result.name}")

        return results

    def test_evo_agent_classification(self) -> list[TestResult]:
        """Test that EVO agents are correctly classified."""
        results = []

        evo_agents = [
            "designer_agent",
            "composer_agent",
            "monitor_agent",
            "ops_agent",
        ]

        for agent in evo_agents:
            agent_type = self.enforcer.get_agent_type(agent)
            passed = agent_type == AgentType.EVO

            result = TestResult(
                name=f"{agent} is EVO",
                category="classification",
                passed=passed,
                expected="EVO",
                actual=agent_type.value.upper()
            )
            results.append(result)
            self.log(f"{'✓' if result.passed else '✗'} {result.name}")

        return results

    def test_scheme_specific_constraints(self) -> list[TestResult]:
        """Test scheme-specific constraints are enforced."""
        results = []

        test_cases = [
            # Scheme 1: NOEVO operational agents
            {
                "agent": "tool_agent",
                "action": "execute_unverified_workflow",
                "expected_denied": True,
                "reason": "Scheme 1 forbids unverified execution"
            },
            {
                "agent": "routing_agent",
                "action": "route_to_unregistered_agent",
                "expected_denied": True,
                "reason": "Scheme 1 forbids unregistered routing"
            },
            # Scheme 2: Designer EVO
            {
                "agent": "designer_agent",
                "action": "deploy_without_verification",
                "expected_denied": True,
                "reason": "Scheme 2 forbids unverified deployment"
            },
            # Scheme 3: Composer EVO
            {
                "agent": "composer_agent",
                "action": "compose_with_unverified_component",
                "expected_denied": True,
                "reason": "Scheme 3 forbids unverified composition"
            },
        ]

        for tc in test_cases:
            allowed, reason = self.enforcer.check_action(tc["action"], tc["agent"])
            passed = (not allowed) == tc["expected_denied"]

            result = TestResult(
                name=f"{tc['agent']}: {tc['action']}",
                category="guardrails",
                passed=passed,
                expected="DENIED" if tc["expected_denied"] else "ALLOWED",
                actual="DENIED" if not allowed else "ALLOWED",
                notes=tc["reason"]
            )
            results.append(result)
            self.log(f"{'✓' if result.passed else '✗'} {result.name}")

        return results

    def test_unknown_agent_denied(self) -> list[TestResult]:
        """An agent registered in no scheme has no permissions and no trust."""
        results = []

        allowed, reason = self.enforcer.check_action("execute_unverified_workflow", "rogue_agent")
        results.append(TestResult(
            name="Unregistered agent is denied",
            category="guardrails",
            passed=not allowed,
            expected="DENIED",
            actual="DENIED" if not allowed else "ALLOWED",
            notes=reason
        ))

        agent_type = self.enforcer.get_agent_type("rogue_agent")
        results.append(TestResult(
            name="Unregistered agent is UNKNOWN, not NOEVO",
            category="guardrails",
            passed=agent_type == AgentType.UNKNOWN,
            expected="UNKNOWN",
            actual=agent_type.value.upper()
        ))

        for r in results:
            self.log(f"{'✓' if r.passed else '✗'} {r.name}")
        return results

    def test_scheme_parse_coverage(self) -> list[TestResult]:
        """Every constraint line in every .logic file is parsed and enforced."""
        results = []
        loader = self.enforcer.loader

        for scheme_id, scheme in sorted(loader.schemes.items()):
            path = loader.guardrails_dir / f"scheme-{scheme_id}.logic"
            with open(path) as f:
                lines = [l.split('#', 1)[0].strip() for l in f]
            lines = [l for l in lines if l]
            parsed = (len(scheme.forbidden) + len(scheme.obligatory)
                      + len(scheme.permitted) + len(scheme.temporal))
            results.append(TestResult(
                name=f"Scheme {scheme_id}: all {len(lines)} constraint lines parsed",
                category="guardrails",
                passed=parsed == len(lines),
                expected=str(len(lines)),
                actual=str(parsed)
            ))

        scheme2 = loader.get_scheme(2)
        conditional = [c for c in scheme2.obligatory if c.condition == "P(generate)"]
        results.append(TestResult(
            name="Conditional obligation P(generate) → O(submit_for_verification) parsed",
            category="guardrails",
            passed=bool(conditional) and conditional[0].action == "submit_for_verification",
            expected="O(submit_for_verification) ← P(generate)",
            actual=str(conditional[0]) if conditional else "missing"
        ))

        scheme1 = loader.get_scheme(1)
        commented = [c for c in scheme1.temporal if c.action.startswith("tool_response")]
        results.append(TestResult(
            name="Constraint with trailing comment parsed",
            category="guardrails",
            passed=bool(commented),
            expected="□(tool_response ≤ 5s)",
            actual=commented[0].raw_expression if commented else "missing"
        ))

        for r in results:
            self.log(f"{'✓' if r.passed else '✗'} {r.name}")
        return results

    def test_conditional_permissions(self) -> list[TestResult]:
        """A "P(x) ← cond" permission is enforced when x is exercised."""
        results = []

        cases = [
            # Scheme 1: P(execute_verified_tool) ← authorized(user) ∧ registered(tool)
            ("tool_agent", "execute_verified_tool", {}, False, "no facts"),
            ("tool_agent", "execute_verified_tool", {"authorized": True}, False, "only authorized"),
            ("tool_agent", "execute_verified_tool",
             {"authorized": True, "facts": ["registered(tool)"]}, True, "authorized and registered"),
            # Scheme 1: P(route_to_evo_agent) ← authenticated(user) ∧ bounded(request)
            ("routing_agent", "route_to_evo_agent", {"authenticated": True}, False, "unbounded request"),
            ("routing_agent", "route_to_evo_agent",
             {"authenticated": True, "facts": ["bounded"]}, True, "bounded request"),
            # Scheme 1: P(call_mcp_tool) ← registered(tool) ∧ authorized(user) ∧ access_granted
            ("tool_agent", "call_mcp_tool",
             {"authorized": True, "access_granted": True}, False, "tool not registered"),
            ("tool_agent", "call_mcp_tool",
             {"authorized": True, "access_granted": True, "facts": ["registered(tool)"]}, True,
             "all three conditions"),
            # Scheme 2: P(propose_optimization) ← existing_component ∧ within_bounds
            ("designer_agent", "propose_optimization", {"within_bounds": True}, False, "no existing component"),
            ("designer_agent", "propose_optimization",
             {"within_bounds": True, "existing_component": True}, True, "existing component in bounds"),
        ]

        for agent, action, context, expected, label in cases:
            allowed, reason = self.enforcer.check_action(action, agent, context)
            passed = allowed == expected
            results.append(TestResult(
                name=f"{agent}: {action} ({label})",
                category="guardrails",
                passed=passed,
                expected="ALLOWED" if expected else "DENIED",
                actual="ALLOWED" if allowed else "DENIED",
                notes=reason
            ))
            self.log(f"{'✓' if passed else '✗'} {results[-1].name}")

        # ∨ and ∧ precedence in a condition
        cond = "learning_failure ∨ design_failure"
        evals = [
            (evaluate_condition(cond, {"design_failure": True}), True),
            (evaluate_condition(cond, {}), False),
            (evaluate_condition("a ∧ b ∨ c", {"c": True}), True),
            (evaluate_condition("a ∧ b ∨ c", {"a": True}), False),
            (evaluate_condition("a ∧ ???", {"a": True}), None),
        ]
        passed = all(got == want for got, want in evals)
        results.append(TestResult(
            name="Condition evaluation (∧ binds tighter than ∨, malformed → None)",
            category="guardrails",
            passed=passed,
            expected=str([w for _, w in evals]),
            actual=str([g for g, _ in evals])
        ))
        self.log(f"{'✓' if passed else '✗'} {results[-1].name}")

        return results

    def test_conditional_obligations(self) -> list[TestResult]:
        """An "O(y) ← cond" obligation binds when its condition holds."""
        results = []

        # Scheme 1: O(verify_evo_request) ← request_from_evo
        base = {"authorized": True, "facts": ["registered(tool)"]}
        cases = [
            ("tool_agent", "execute_verified_tool", {**base}, True, "not from EVO"),
            ("tool_agent", "execute_verified_tool", {**base, "request_from_evo": True}, False,
             "from EVO, not verified"),
            ("tool_agent", "execute_verified_tool",
             {**base, "request_from_evo": True, "performed_actions": ["verify_evo_request"]}, True,
             "from EVO, verified"),
            # Scheme 3: P(compose) → O(verify_composition_result)
            ("composer_agent", "compose_verified_components",
             {"facts": ["all_components_verified"]}, False, "composition not verified"),
            ("composer_agent", "compose_verified_components",
             {"facts": ["all_components_verified"], "performed_actions": ["verify_composition_result"]},
             True, "composition verified"),
        ]

        for agent, action, context, expected, label in cases:
            allowed, reason = self.enforcer.check_action(action, agent, context)
            passed = allowed == expected
            results.append(TestResult(
                name=f"{agent}: {action} ({label})",
                category="guardrails",
                passed=passed,
                expected="ALLOWED" if expected else "DENIED",
                actual="ALLOWED" if allowed else "DENIED",
                notes=reason
            ))
            self.log(f"{'✓' if passed else '✗'} {results[-1].name}")

        return results

    def test_temporal_bounds(self) -> list[TestResult]:
        """□(metric op limit) bounds are checked against measured values."""
        results = []

        cases = [
            ("tool_agent", {"idle_session_timeout": 29 * 60}, True, "idle 29 min"),
            ("tool_agent", {"idle_session_timeout": 31 * 60}, False, "idle 31 min"),
            ("tool_agent", {"maximum_session_duration": 23 * 3600}, True, "session 23 h"),
            ("tool_agent", {"maximum_session_duration": 25 * 3600}, False, "session 25 h"),
            ("routing_agent", {"route_retry": 3}, True, "3 retries"),
            ("routing_agent", {"route_retry": 4}, False, "4 retries"),
            ("tool_agent", {"tool_response": 6}, False, "tool response 6 s (bound carried a comment)"),
            ("designer_agent", {"memory_usage": 600 * 1024 ** 2}, False, "designer memory 600 MB"),
            ("designer_agent", {"cpu_usage": 40}, True, "designer cpu 40 %"),
            ("composer_agent", {"workflow_steps": 51}, False, "51 workflow steps"),
            ("tool_agent", {"unbounded_metric": 10 ** 9}, True, "metric with no bound"),
            ("security_agent", {"security_decision": 0.04}, True, "decision in 40 ms"),
            ("security_agent", {"security_decision": 0.6}, False, "decision in 600 ms"),
        ]

        for agent, metrics, expected, label in cases:
            ok, violations = self.enforcer.check_temporal_bounds(agent, metrics)
            passed = ok == expected
            results.append(TestResult(
                name=f"Temporal bound: {label}",
                category="guardrails",
                passed=passed,
                expected="HOLDS" if expected else "VIOLATED",
                actual="HOLDS" if ok else "VIOLATED",
                notes="; ".join(violations)
            ))
            self.log(f"{'✓' if passed else '✗'} {results[-1].name}")

        # Every □ constraint is either checkable or explicitly listed as not
        enforceable = sum(len(sch.temporal_bounds()[0]) for sch in self.enforcer.loader.schemes.values())
        unenforceable = self.enforcer.unenforceable_temporal()
        total_temporal = sum(len(sch.temporal) for sch in self.enforcer.loader.schemes.values())
        listed = sum(len(v) for v in unenforceable.values())
        passed = enforceable + listed == total_temporal and enforceable >= 30
        results.append(TestResult(
            name=f"Temporal constraints accounted for ({enforceable} checkable, {listed} symbolic)",
            category="guardrails",
            passed=passed,
            expected=str(total_temporal),
            actual=str(enforceable + listed),
            notes=str(unenforceable)
        ))
        self.log(f"{'✓' if passed else '✗'} {results[-1].name}")

        return results

    # =========================================================================
    # Category 2: Logic Engine Integration
    # =========================================================================

    def test_logic_engine_available(self) -> list[TestResult]:
        """Test that Logic Engine is available and responding."""
        results = []

        try:
            agent = AccessAgent()

            # Test tautology
            decision = agent.check_access(
                resource="test",
                action="test",
                context={"authenticated": True, "role": "admin"}
            )

            result = TestResult(
                name="Logic Engine responds to queries",
                category="logic_engine",
                passed=True,
                expected="Response",
                actual=f"Response (paradigms: {decision.paradigms_used})"
            )
        except Exception as e:
            result = TestResult(
                name="Logic Engine responds to queries",
                category="logic_engine",
                passed=False,
                expected="Response",
                actual=f"Error: {str(e)}"
            )

        results.append(result)
        self.log(f"{'✓' if result.passed else '✗'} {result.name}")

        return results

    def test_policy_expression_generation(self) -> list[TestResult]:
        """Test that policy expressions are generated correctly."""
        results = []

        agent = AccessAgent()

        test_cases = [
            {
                "context": {"authenticated": True},
                "expected_contains": "O(auth)"
            },
            {
                "context": {"role": "provider"},
                "expected_contains": "O(role=provider)"
            },
            {
                "context": {"session_valid": True},
                "expected_contains": "□session"
            },
            {
                "context": {},  # No context = forbidden
                "expected_contains": "F("
            },
        ]

        for tc in test_cases:
            decision = agent.check_access(
                resource="test",
                action="test",
                context=tc["context"]
            )

            passed = tc["expected_contains"] in decision.policy_expression

            result = TestResult(
                name=f"Policy contains {tc['expected_contains']}",
                category="logic_engine",
                passed=passed,
                expected=tc["expected_contains"],
                actual=decision.policy_expression[:50] + "..."
            )
            results.append(result)
            self.log(f"{'✓' if result.passed else '✗'} {result.name}")

        return results

    def test_authentication_required(self) -> list[TestResult]:
        """No context flag other than authentication can grant access."""
        results = []
        agent = AccessAgent()

        test_cases = [
            ({"role": "provider"}, False, "role alone"),
            ({"consent": True}, False, "consent alone"),
            ({"session_valid": True}, False, "valid session alone"),
            ({"role": "provider", "consent": True, "session_valid": True}, False,
             "everything except authentication"),
            ({"authenticated": True}, True, "authentication alone"),
            ({"authenticated": True, "role": "provider", "session_valid": True}, True,
             "authentication with role and session"),
        ]

        for context, expected_allowed, label in test_cases:
            decision = agent.check_access(
                resource="patient_records",
                action="read",
                context=context
            )
            passed = decision.allowed == expected_allowed
            results.append(TestResult(
                name=f"Access with {label}",
                category="logic_engine",
                passed=passed,
                expected="ALLOWED" if expected_allowed else "DENIED",
                actual="ALLOWED" if decision.allowed else "DENIED",
                notes=decision.reasoning_trace.splitlines()[0] if decision.reasoning_trace else ""
            ))
            self.log(f"{'✓' if passed else '✗'} {results[-1].name}")

        return results

    def test_identifier_validation(self) -> list[TestResult]:
        """Values that are not bare identifiers never reach the shell engines."""
        results = []
        agent = AccessAgent()

        marker = os.path.join(tempfile.gettempdir(), f"broad-injection-{os.getpid()}")
        try:
            os.remove(marker)
        except FileNotFoundError:
            pass

        test_cases = [
            ("patient_records", "read", {"authenticated": True, "role": f"nurse`touch {marker}`"},
             "backticks in role"),
            ("patient_records", "read", {"authenticated": True, "role": "nurse$(id)"},
             "command substitution in role"),
            ("patient records", "read", {"authenticated": True}, "space in resource"),
            ("patient_records", "read; rm -rf /", {"authenticated": True}, "shell metacharacters in action"),
            ("patient_records", "read", {"authenticated": True, "role": "nurse ∧ ⊤"},
             "logic operators in role"),
        ]

        for resource, action, context, label in test_cases:
            decision = agent.check_access(resource=resource, action=action, context=context)
            passed = (not decision.allowed
                      and decision.reasoning_trace.startswith("REJECTED")
                      and decision.paradigms_used == [])
            results.append(TestResult(
                name=f"Rejected before evaluation: {label}",
                category="logic_engine",
                passed=passed,
                expected="REJECTED, engine not invoked",
                actual=decision.reasoning_trace.splitlines()[0]
            ))
            self.log(f"{'✓' if passed else '✗'} {results[-1].name}")

        executed = os.path.exists(marker)
        if executed:
            os.remove(marker)
        results.append(TestResult(
            name="Injected command did not execute",
            category="logic_engine",
            passed=not executed,
            expected="no side effect",
            actual="marker file created" if executed else "no side effect"
        ))
        self.log(f"{'✓' if not executed else '✗'} {results[-1].name}")

        return results

    def test_role_permissions(self) -> list[TestResult]:
        """Role-based permission checks decide by the role table."""
        results = []
        agent = AccessAgent()

        test_cases = [
            ("admin", "delete", True),
            ("admin", "view", True),
            ("operator", "control", True),
            ("operator", "delete", False),
            ("viewer", "view", True),
            ("viewer", "delete", False),
            ("viewer", "control", False),
            ("nurse", "read", False),  # unknown role
        ]

        for role, action, expected_allowed in test_cases:
            decision = agent.check_role_permission(role, action)
            passed = decision.allowed == expected_allowed
            results.append(TestResult(
                name=f"Role {role} / {action}",
                category="logic_engine",
                passed=passed,
                expected="ALLOWED" if expected_allowed else "DENIED",
                actual="ALLOWED" if decision.allowed else "DENIED",
                notes=decision.policy_expression
            ))
            self.log(f"{'✓' if passed else '✗'} {results[-1].name}")

        decision = agent.check_bio_auth_policy(True)
        results.append(TestResult(
            name="Bio-auth verified is allowed",
            category="logic_engine",
            passed=decision.allowed,
            expected="ALLOWED",
            actual="ALLOWED" if decision.allowed else "DENIED"
        ))
        decision = agent.check_bio_auth_policy(False)
        results.append(TestResult(
            name="Bio-auth unverified is denied",
            category="logic_engine",
            passed=not decision.allowed,
            expected="DENIED",
            actual="ALLOWED" if decision.allowed else "DENIED"
        ))
        for r in results[-2:]:
            self.log(f"{'✓' if r.passed else '✗'} {r.name}")

        return results

    # =========================================================================
    # Category 3: EVO/NOEVO Communication Rules
    # =========================================================================

    async def test_evo_noevo_communication(self) -> list[TestResult]:
        """Test EVO/NOEVO agent communication rules."""
        results = []
        self._init_gateway()

        test_cases = [
            # NOEVO → NOEVO: Direct trusted
            {
                "from": "tool_agent",
                "to": "orchestrator_agent",
                "expected_allowed": True,
                "reason": "NOEVO→NOEVO is direct"
            },
            # EVO → NOEVO: Allowed (will be verified)
            {
                "from": "designer_agent",
                "to": "tool_agent",
                "expected_allowed": True,
                "reason": "EVO→NOEVO requires verification"
            },
            # NOEVO → EVO: Allowed (bounded delegation)
            {
                "from": "routing_agent",
                "to": "designer_agent",
                "expected_allowed": True,
                "reason": "NOEVO→EVO is bounded delegation"
            },
            # EVO → EVO: BLOCKED (must go through NOEVO)
            {
                "from": "designer_agent",
                "to": "composer_agent",
                "expected_allowed": False,
                "reason": "EVO→EVO must route through NOEVO"
            },
        ]

        for tc in test_cases:
            allowed, reason = self.gateway.check_evo_noevo_permission(
                tc["from"], tc["to"], "communicate"
            )
            passed = allowed == tc["expected_allowed"]

            result = TestResult(
                name=f"{tc['from']} → {tc['to']}",
                category="evo_noevo",
                passed=passed,
                expected="ALLOWED" if tc["expected_allowed"] else "BLOCKED",
                actual="ALLOWED" if allowed else "BLOCKED",
                notes=tc["reason"]
            )
            results.append(result)
            self.log(f"{'✓' if result.passed else '✗'} {result.name}")

        return results

    # =========================================================================
    # Category 4: Complete Governance Flow
    # =========================================================================

    async def test_complete_governance_flow(self) -> list[TestResult]:
        """Test the complete governance flow."""
        results = []
        self._init_gateway()

        test_cases = [
            {
                "name": "Authenticated provider access",
                "agent": "tool_agent",
                "resource": "patient_records",
                "action": "read",
                "context": {"authenticated": True, "role": "provider", "session_valid": True},
                "expected_allowed": True
            },
            {
                "name": "Unauthenticated access attempt",
                "agent": "tool_agent",
                "resource": "patient_records",
                "action": "read",
                "context": {},
                "expected_allowed": False
            },
            {
                "name": "Forbidden action (bypass auth)",
                "agent": "tool_agent",
                "resource": "auth",
                "action": "bypass_authentication",
                "context": {"authenticated": True, "role": "admin"},
                "expected_allowed": False
            },
            {
                "name": "EVO agent with proper constraints",
                "agent": "designer_agent",
                "resource": "workflow",
                "action": "generate",
                "context": {
                    "authenticated": True,
                    "role": "designer",
                    "performed_actions": ["submit_for_verification"]
                },
                "expected_allowed": True
            },
        ]

        for tc in test_cases:
            decision = await self.gateway.check_access(
                session_id=None,
                agent_name=tc["agent"],
                resource=tc["resource"],
                action=tc["action"],
                context=tc["context"]
            )

            passed = decision.allowed == tc["expected_allowed"]

            result = TestResult(
                name=tc["name"],
                category="complete_flow",
                passed=passed,
                expected="ALLOWED" if tc["expected_allowed"] else "DENIED",
                actual="ALLOWED" if decision.allowed else "DENIED",
                duration_ms=decision.latency_ms,
                notes="; ".join(decision.reasoning_trace[-2:])
            )
            results.append(result)
            self.log(f"{'✓' if result.passed else '✗'} {result.name} ({decision.latency_ms:.1f}ms)")

        return results

    async def test_governed_tool_decorator(self) -> list[TestResult]:
        """The MCP tool decorator blocks the call unless governance allows it."""
        results = []
        self._init_gateway()

        calls = []

        @governed_mcp_tool("healthcare", "read_patient")
        async def read_patient(patient_id: str):
            calls.append(patient_id)
            return {"patient_id": patient_id}

        try:
            await read_patient("p-1", context={})
            denied = False
        except PermissionError:
            denied = True
        results.append(TestResult(
            name="Decorated tool denied without authentication",
            category="complete_flow",
            passed=denied and calls == [],
            expected="PermissionError, tool body not run",
            actual="PermissionError" if denied else f"returned (calls={calls})"
        ))

        try:
            result = await read_patient("p-2", context={"authenticated": True, "role": "provider"})
            ran = result == {"patient_id": "p-2"} and calls == ["p-2"]
        except PermissionError as e:
            ran = False
        results.append(TestResult(
            name="Decorated tool runs when authenticated",
            category="complete_flow",
            passed=ran,
            expected="tool body run once",
            actual=f"calls={calls}"
        ))

        for r in results:
            self.log(f"{'✓' if r.passed else '✗'} {r.name}")
        return results

    async def test_session_temporal_bounds(self) -> list[TestResult]:
        """The gateway denies a session past the Scheme 0 idle/duration bounds."""
        results = []
        self._init_gateway()
        manager = self.gateway.heartbeat_manager
        now = datetime.now(timezone.utc)
        ctx = {"role": "provider"}

        async def fresh_session():
            session = await manager.register_device(DeviceInfo("tb-dev", "simulation"))
            await manager.process_heartbeat(
                HeartbeatPayload("tb-dev", session.session_id, 1, now.isoformat(), auth_token="tok")
            )
            return session

        session = await fresh_session()
        decision = await self.gateway.check_access(session.session_id, "tool_agent", "patient_records", "read", ctx)
        results.append(TestResult(
            name="Fresh authenticated session is allowed",
            category="complete_flow",
            passed=decision.allowed,
            expected="ALLOWED",
            actual="ALLOWED" if decision.allowed else "DENIED",
            notes="; ".join(decision.reasoning_trace[:3])
        ))

        session = await fresh_session()
        session.last_heartbeat = now - timedelta(minutes=31)
        decision = await self.gateway.check_access(session.session_id, "tool_agent", "patient_records", "read", ctx)
        passed = (not decision.allowed
                  and any("idle_session_timeout" in v for v in decision.temporal_violations))
        results.append(TestResult(
            name="Session idle 31 minutes is denied by □(idle_session_timeout ≤ 30m)",
            category="complete_flow",
            passed=passed,
            expected="DENIED, idle bound named",
            actual=("DENIED" if not decision.allowed else "ALLOWED") + f" {decision.temporal_violations}"
        ))

        session = await fresh_session()
        session.created_at = (now - timedelta(hours=25)).isoformat()
        decision = await self.gateway.check_access(session.session_id, "tool_agent", "patient_records", "read", ctx)
        passed = (not decision.allowed
                  and any("maximum_session_duration" in v for v in decision.temporal_violations))
        results.append(TestResult(
            name="Session 25 hours old is denied by □(maximum_session_duration ≤ 24h)",
            category="complete_flow",
            passed=passed,
            expected="DENIED, duration bound named",
            actual=("DENIED" if not decision.allowed else "ALLOWED") + f" {decision.temporal_violations}"
        ))

        # Caller-supplied metrics are checked too
        decision = await self.gateway.check_access(
            None, "routing_agent", "router", "route_to_registered_agent",
            {"authenticated": True, "metrics": {"route_retry": 5}}
        )
        passed = not decision.allowed and any("route_retry" in v for v in decision.temporal_violations)
        results.append(TestResult(
            name="Caller metric route_retry=5 is denied by □(route_retry ≤ 3)",
            category="complete_flow",
            passed=passed,
            expected="DENIED, retry bound named",
            actual=("DENIED" if not decision.allowed else "ALLOWED") + f" {decision.temporal_violations}"
        ))

        # The decision latency bound is reported, never enforced
        decision = await self.gateway.check_access(None, "tool_agent", "patient_records", "read",
                                                   {"authenticated": True})
        over = decision.latency_ms > 50
        reported = any("security_decision" in v for v in decision.temporal_violations)
        passed = decision.allowed and (reported == over)
        results.append(TestResult(
            name="□(security_decision ≤ 50ms) is reported, not enforced",
            category="complete_flow",
            passed=passed,
            expected=f"ALLOWED, reported={over}",
            actual=f"{'ALLOWED' if decision.allowed else 'DENIED'}, reported={reported} ({decision.latency_ms:.0f}ms)"
        ))

        for r in results:
            self.log(f"{'✓' if r.passed else '✗'} {r.name}")
        return results

    # =========================================================================
    # Category 5: Heartbeat Sessions
    # =========================================================================

    async def test_heartbeat_missed_count(self) -> list[TestResult]:
        """Missed heartbeats are counted per expected interval, not per poll."""
        results = []
        manager = HeartbeatManager()
        session = await manager.register_device(DeviceInfo("hb-1", "simulation"))
        now = datetime.now(timezone.utc)

        # At IDLE (1 Hz): third miss at 4 s -> DEGRADED, tenth at 11 s -> TERMINATED
        expectations = [
            (1.5, 0, SessionState.ACTIVE),
            (3.9, 2, SessionState.ACTIVE),
            (4.0, 3, SessionState.DEGRADED),
            (10.9, 9, SessionState.DEGRADED),
            (11.0, 10, SessionState.TERMINATED),
        ]
        for idle_seconds, expected_missed, expected_state in expectations:
            session.last_heartbeat = now - timedelta(seconds=idle_seconds)
            await manager.check_sessions_once(now)
            passed = (session.missed_count == expected_missed
                      and session.state == expected_state)
            results.append(TestResult(
                name=f"Idle {idle_seconds}s at 1 Hz",
                category="heartbeat",
                passed=passed,
                expected=f"missed={expected_missed} {expected_state.value}",
                actual=f"missed={session.missed_count} {session.state.value}"
            ))
            self.log(f"{'✓' if passed else '✗'} {results[-1].name}")

        # Repeated polls within one interval do not inflate the count
        session2 = await manager.register_device(DeviceInfo("hb-2", "simulation"))
        session2.last_heartbeat = now - timedelta(seconds=2.5)
        for _ in range(20):
            await manager.check_sessions_once(now)
        passed = session2.missed_count == 1 and session2.state == SessionState.ACTIVE
        results.append(TestResult(
            name="Twenty polls inside one interval count one miss",
            category="heartbeat",
            passed=passed,
            expected="missed=1 active",
            actual=f"missed={session2.missed_count} {session2.state.value}"
        ))
        self.log(f"{'✓' if passed else '✗'} {results[-1].name}")

        # A heartbeat recovers a degraded session
        session3 = await manager.register_device(DeviceInfo("hb-3", "simulation"))
        session3.last_heartbeat = now - timedelta(seconds=5)
        await manager.check_sessions_once(now)
        response = await manager.process_heartbeat(
            HeartbeatPayload("hb-3", session3.session_id, 1, now.isoformat())
        )
        passed = (response["status"] == "ok" and session3.state == SessionState.ACTIVE
                  and session3.missed_count == 0)
        results.append(TestResult(
            name="Heartbeat recovers a degraded session",
            category="heartbeat",
            passed=passed,
            expected="ok, active, missed=0",
            actual=f"{response['status']}, {session3.state.value}, missed={session3.missed_count}"
        ))
        self.log(f"{'✓' if passed else '✗'} {results[-1].name}")

        return results

    async def test_heartbeat_authentication(self) -> list[TestResult]:
        """Tokens are checked by the configured validator; none means never."""
        results = []
        ts = datetime.now(timezone.utc).isoformat()

        # No validator: a token never authenticates
        manager = HeartbeatManager()
        session = await manager.register_device(DeviceInfo("auth-1", "simulation"))
        response = await manager.process_heartbeat(HeartbeatPayload("auth-1", session.session_id, 1, ts, auth_token="tok"))
        passed = (response["status"] == "ok" and not session.auth_verified
                  and response.get("auth") == "no_validator"
                  and not await manager.check_session_health(session.session_id))
        results.append(TestResult(
            name="Without a validator a token never authenticates",
            category="heartbeat",
            passed=passed,
            expected="auth_verified=False, auth=no_validator",
            actual=f"auth_verified={session.auth_verified}, auth={response.get('auth')}"
        ))

        # A validator decides, per device; a rejected token revokes
        def only_device_two(token, device_id):
            return token == "secret" and device_id == "auth-2"

        manager = HeartbeatManager(token_validator=only_device_two)
        s2 = await manager.register_device(DeviceInfo("auth-2", "simulation"))
        s3 = await manager.register_device(DeviceInfo("auth-3", "simulation"))
        r_ok = await manager.process_heartbeat(HeartbeatPayload("auth-2", s2.session_id, 1, ts, auth_token="secret"))
        r_wrong_dev = await manager.process_heartbeat(HeartbeatPayload("auth-3", s3.session_id, 1, ts, auth_token="secret"))
        r_none = await manager.process_heartbeat(HeartbeatPayload("auth-2", s2.session_id, 2, ts))
        still_verified = s2.auth_verified
        r_bad = await manager.process_heartbeat(HeartbeatPayload("auth-2", s2.session_id, 3, ts, auth_token="wrong"))
        passed = (r_ok.get("auth") == "verified" and r_wrong_dev.get("auth") == "rejected"
                  and not s3.auth_verified and "auth" not in r_none and still_verified
                  and r_bad.get("auth") == "rejected" and not s2.auth_verified)
        results.append(TestResult(
            name="Validator verifies per device, no token keeps state, bad token revokes",
            category="heartbeat",
            passed=passed,
            expected="verified / rejected / kept / revoked",
            actual=f"{r_ok.get('auth')} / {r_wrong_dev.get('auth')} / kept={still_verified} / {r_bad.get('auth')} verified={s2.auth_verified}"
        ))

        # An async validator and a raising validator
        async def async_validator(token, device_id):
            return token == "async-ok"

        def broken_validator(token, device_id):
            raise RuntimeError("IAM unreachable")

        manager = HeartbeatManager(token_validator=async_validator)
        s4 = await manager.register_device(DeviceInfo("auth-4", "simulation"))
        r_async = await manager.process_heartbeat(HeartbeatPayload("auth-4", s4.session_id, 1, ts, auth_token="async-ok"))
        manager = HeartbeatManager(token_validator=broken_validator)
        s5 = await manager.register_device(DeviceInfo("auth-5", "simulation"))
        r_broken = await manager.process_heartbeat(HeartbeatPayload("auth-5", s5.session_id, 1, ts, auth_token="tok"))
        passed = (r_async.get("auth") == "verified" and s4.auth_verified
                  and r_broken.get("auth") == "rejected" and not s5.auth_verified)
        results.append(TestResult(
            name="Async validator works; a raising validator fails closed",
            category="heartbeat",
            passed=passed,
            expected="verified / rejected",
            actual=f"{r_async.get('auth')} / {r_broken.get('auth')}"
        ))

        for r in results:
            self.log(f"{'✓' if r.passed else '✗'} {r.name}")
        return results

    async def test_heartbeat_lifecycle(self) -> list[TestResult]:
        """Terminated sessions are purged and the gateway starts the monitor."""
        results = []
        now = datetime.now(timezone.utc)

        manager = HeartbeatManager(terminated_retention_seconds=60)
        kept = await manager.register_device(DeviceInfo("lc-1", "simulation"))
        old = await manager.register_device(DeviceInfo("lc-2", "simulation"))
        recent = await manager.register_device(DeviceInfo("lc-3", "simulation"))
        manager.terminate_session(old.session_id, "test")
        manager.terminate_session(recent.session_id, "test")
        old.terminated_at = now - timedelta(seconds=61)
        recent.terminated_at = now - timedelta(seconds=10)
        removed = manager.purge_terminated(now)
        passed = (removed == 1 and old.session_id not in manager.sessions
                  and recent.session_id in manager.sessions and kept.session_id in manager.sessions)
        results.append(TestResult(
            name="Purge removes sessions terminated longer than the retention window",
            category="heartbeat",
            passed=passed,
            expected="1 removed, recent and live kept",
            actual=f"{removed} removed, sessions={len(manager.sessions)}"
        ))

        # A late heartbeat to a purged session gets unknown_session, to a
        # recently terminated one gets session_terminated
        ts = now.isoformat()
        r_purged = await manager.process_heartbeat(HeartbeatPayload("lc-2", old.session_id, 1, ts))
        r_recent = await manager.process_heartbeat(HeartbeatPayload("lc-3", recent.session_id, 1, ts))
        passed = r_purged.get("error") == "unknown_session" and r_recent.get("error") == "session_terminated"
        results.append(TestResult(
            name="Late heartbeats distinguish purged from recently terminated",
            category="heartbeat",
            passed=passed,
            expected="unknown_session / session_terminated",
            actual=f"{r_purged.get('error')} / {r_recent.get('error')}"
        ))

        # Monitor pass terminates and later purges without manual calls
        manager = HeartbeatManager(terminated_retention_seconds=0)
        session = await manager.register_device(DeviceInfo("lc-4", "simulation"))
        session.last_heartbeat = now - timedelta(seconds=20)
        await manager.check_sessions_once(now)
        terminated = session.state == SessionState.TERMINATED
        await manager.check_sessions_once(now + timedelta(seconds=1))
        passed = terminated and session.session_id not in manager.sessions
        results.append(TestResult(
            name="Monitor terminates an idle session and purges it after retention",
            category="heartbeat",
            passed=passed,
            expected="terminated then purged",
            actual=f"terminated={terminated}, present={session.session_id in manager.sessions}"
        ))

        # The gateway starts the monitor on its first session-bound check
        gateway = GovernanceGateway(
            enforcer=self.enforcer,
            access_agent=AccessAgent(),
            heartbeat_manager=HeartbeatManager(token_validator=accept_any_token)
        )
        before = gateway.heartbeat_manager._monitor_task
        session = await gateway.heartbeat_manager.register_device(DeviceInfo("lc-5", "simulation"))
        await gateway.check_access(session.session_id, "tool_agent", "patient_records", "read", {})
        task = gateway.heartbeat_manager._monitor_task
        running = task is not None and not task.done()
        gateway.close()
        await asyncio.sleep(0)
        stopped = gateway.heartbeat_manager._monitor_task is None and (task.cancelled() or task.done())
        passed = before is None and running and stopped
        results.append(TestResult(
            name="Gateway starts the heartbeat monitor on first use and close() stops it",
            category="heartbeat",
            passed=passed,
            expected="not running / running / stopped",
            actual=f"before={before} running={running} stopped={stopped}"
        ))

        for r in results:
            self.log(f"{'✓' if r.passed else '✗'} {r.name}")
        return results

    async def test_heartbeat_session_integrity(self) -> list[TestResult]:
        """Re-registration, replayed sequence numbers and device mismatch."""
        results = []
        manager = HeartbeatManager()
        device = DeviceInfo("hb-dup", "simulation")

        first = await manager.register_device(device)
        second = await manager.register_device(device)
        live = [s for s in manager.sessions.values()
                if s.device_id == "hb-dup" and s.state != SessionState.TERMINATED]
        passed = first.state == SessionState.TERMINATED and live == [second]
        results.append(TestResult(
            name="Re-registration terminates the earlier session",
            category="heartbeat",
            passed=passed,
            expected="one live session, old terminated",
            actual=f"{len(live)} live, old={first.state.value}"
        ))

        ts = datetime.now(timezone.utc).isoformat()
        ok = await manager.process_heartbeat(HeartbeatPayload("hb-dup", second.session_id, 5, ts))
        replay = await manager.process_heartbeat(HeartbeatPayload("hb-dup", second.session_id, 5, ts))
        older = await manager.process_heartbeat(HeartbeatPayload("hb-dup", second.session_id, 3, ts))
        passed = (ok["status"] == "ok" and replay.get("error") == "stale_sequence"
                  and older.get("error") == "stale_sequence" and second.sequence_number == 5)
        results.append(TestResult(
            name="Replayed or older sequence numbers are rejected",
            category="heartbeat",
            passed=passed,
            expected="ok, stale_sequence, stale_sequence",
            actual=f"{ok['status']}, {replay.get('error')}, {older.get('error')}"
        ))

        mismatch = await manager.process_heartbeat(HeartbeatPayload("other", second.session_id, 6, ts))
        passed = mismatch.get("error") == "device_mismatch"
        results.append(TestResult(
            name="Heartbeat from another device is rejected",
            category="heartbeat",
            passed=passed,
            expected="device_mismatch",
            actual=str(mismatch.get("error"))
        ))

        for r in results:
            self.log(f"{'✓' if r.passed else '✗'} {r.name}")
        return results

    # =========================================================================
    # Test Runner
    # =========================================================================

    async def run_all(self, category: Optional[str] = None) -> dict:
        """Run all tests or a specific category."""
        all_results = []

        categories = {
            "guardrails": [
                self.test_scheme0_forbidden_actions,
                self.test_scheme_specific_constraints,
                self.test_unknown_agent_denied,
                self.test_scheme_parse_coverage,
                self.test_conditional_permissions,
                self.test_conditional_obligations,
                self.test_temporal_bounds,
            ],
            "classification": [
                self.test_noevo_agent_classification,
                self.test_evo_agent_classification,
            ],
            "logic_engine": [
                self.test_logic_engine_available,
                self.test_policy_expression_generation,
                self.test_authentication_required,
                self.test_identifier_validation,
                self.test_role_permissions,
            ],
            "evo_noevo": [
                self.test_evo_noevo_communication,
            ],
            "complete_flow": [
                self.test_complete_governance_flow,
                self.test_governed_tool_decorator,
                self.test_session_temporal_bounds,
            ],
            "heartbeat": [
                self.test_heartbeat_missed_count,
                self.test_heartbeat_session_integrity,
                self.test_heartbeat_authentication,
                self.test_heartbeat_lifecycle,
            ],
        }

        # Filter by category if specified
        if category:
            if category not in categories:
                print(f"Unknown category: {category}")
                print(f"Available: {list(categories.keys())}")
                return {}
            categories = {category: categories[category]}

        for cat_name, test_funcs in categories.items():
            print(f"\n{'='*60}")
            print(f"  Category: {cat_name.upper()}")
            print(f"{'='*60}")

            for func in test_funcs:
                if asyncio.iscoroutinefunction(func):
                    results = await func()
                else:
                    results = func()
                all_results.extend(results)

        # Summary
        passed = sum(1 for r in all_results if r.passed)
        failed = sum(1 for r in all_results if not r.passed)

        print(f"\n{'='*60}")
        print(f"  SUMMARY")
        print(f"{'='*60}")
        print(f"  Total: {len(all_results)}")
        print(f"  Passed: {passed} ✓")
        print(f"  Failed: {failed} ✗")
        print(f"  Pass Rate: {100*passed/len(all_results):.1f}%")

        if failed > 0:
            print(f"\n  FAILED TESTS:")
            for r in all_results:
                if not r.passed:
                    print(f"    ✗ {r.name}")
                    print(f"      Expected: {r.expected}, Got: {r.actual}")

        return {
            "total": len(all_results),
            "passed": passed,
            "failed": failed,
            "results": [
                {
                    "name": r.name,
                    "category": r.category,
                    "passed": r.passed,
                    "expected": r.expected,
                    "actual": r.actual,
                }
                for r in all_results
            ]
        }


async def main():
    parser = argparse.ArgumentParser(description="Run governance tests")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument("--category", "-c", help="Run specific category")
    args = parser.parse_args()

    print("=" * 60)
    print("  ESN GOVERNANCE LAYER - TEST SUITE")
    print("  " + datetime.now().isoformat())
    print("=" * 60)

    suite = GovernanceTestSuite(verbose=args.verbose)
    summary = await suite.run_all(category=args.category)

    # Exit with error code if any tests failed
    if summary.get("failed", 0) > 0:
        sys.exit(1)
    else:
        print("\n  ALL TESTS PASSED ✓")
        sys.exit(0)


if __name__ == "__main__":
    asyncio.run(main())
