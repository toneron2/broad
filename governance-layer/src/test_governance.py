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

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
"""

import asyncio
import sys
import argparse
from dataclasses import dataclass
from typing import Optional
from datetime import datetime

# Import governance components
from guardrails_loader import GuardrailsEnforcer, AgentType, get_enforcer
from access_agent import AccessAgent
from governed_access import GovernanceGateway, governed_mcp_tool


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
            self.gateway = GovernanceGateway()

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
            ],
            "classification": [
                self.test_noevo_agent_classification,
                self.test_evo_agent_classification,
            ],
            "logic_engine": [
                self.test_logic_engine_available,
                self.test_policy_expression_generation,
            ],
            "evo_noevo": [
                self.test_evo_noevo_communication,
            ],
            "complete_flow": [
                self.test_complete_governance_flow,
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
