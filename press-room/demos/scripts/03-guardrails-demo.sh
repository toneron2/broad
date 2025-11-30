#!/bin/bash
# =============================================================================
# DEMO: Guardrails Schemes - Formal Agent Constraints
# Duration: 3-4 minutes
# Purpose: Show the formal constraint system for EVO/NOEVO agents
# =============================================================================
# COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Get paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARDRAILS="${SCRIPT_DIR}/../../../governance-layer/src/guardrails"
SPECS="${SCRIPT_DIR}/../../../governance-layer/specs"

echo ""
echo -e "${BOLD}${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${RED}║         GUARDRAILS SCHEMES - FORMAL CONSTRAINTS              ║${NC}"
echo -e "${BOLD}${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if guardrails exist
if [[ ! -d "${GUARDRAILS}" ]]; then
    echo -e "${RED}ERROR: Guardrails not found at ${GUARDRAILS}${NC}"
    exit 1
fi

# -----------------------------------------------------------------------------
# Overview
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${YELLOW}  THE EVO/NOEVO MODEL${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "  ${BOLD}NOEVO${NC} (Non-Evolutionary)"
echo -e "    • Fixed behavior after deployment"
echo -e "    • Acts as ${GREEN}SHIELD${NC} for EVO agents"
echo -e "    • Formally verifiable, deterministic"
echo -e "    • Examples: Security, Routing, Tool agents"
echo ""
echo -e "  ${BOLD}EVO${NC} (Evolutionary)"
echo -e "    • Can adapt within guardrail constraints"
echo -e "    • Outputs verified by NOEVO before execution"
echo -e "    • Examples: Designer, Composer agents"
echo ""

echo -e "  ${CYAN}Agent Hierarchy:${NC}"
echo ""
echo -e "  A. Security Agent       ${RED}[NOEVO]${NC} - Scheme 0 (BLOCKED)"
echo -e "  ├── A.1 User Agent      [CONTROLLED] - Bio-auth required"
echo -e "  │   └── A.1.1 Routing   ${RED}[NOEVO]${NC} - Scheme 1"
echo -e "  │       ├── Chat        ${RED}[NOEVO]${NC}"
echo -e "  │       ├── Tool        ${RED}[NOEVO]${NC}"
echo -e "  │       ├── Orchestrator${RED}[NOEVO]${NC}"
echo -e "  │       ├── Designer    ${GREEN}[EVO]${NC} - Scheme 2"
echo -e "  │       └── Composer    ${GREEN}[EVO]${NC} - Scheme 3"
echo -e "  ├── Monitor Agent       ${GREEN}[EVO]${NC}"
echo -e "  └── Ops Agent           ${GREEN}[EVO]${NC}"
echo ""

sleep 2

# -----------------------------------------------------------------------------
# Scheme 0: Security Agent
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${YELLOW}  SCHEME 0: Security Agent - BLOCKED${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${RED}NOTHING bypasses these constraints.${NC}"
echo ""

echo -e "${CYAN}Fundamental Safety:${NC}"
grep -E "^F\(harm|^F\(deceive|^F\(leak" "${GUARDRAILS}/scheme-0.logic" 2>/dev/null | head -5 | while read line; do
    echo -e "  ${line}"
done
echo ""

echo -e "${CYAN}Authentication Integrity:${NC}"
grep -E "^F\(bypass|^F\(forge" "${GUARDRAILS}/scheme-0.logic" 2>/dev/null | head -3 | while read line; do
    echo -e "  ${line}"
done
echo ""

echo -e "${CYAN}Temporal Constraints:${NC}"
grep -E "^□\(" "${GUARDRAILS}/scheme-0.logic" 2>/dev/null | head -3 | while read line; do
    echo -e "  ${line}"
done
echo ""

sleep 2

# -----------------------------------------------------------------------------
# Scheme 1: Operational
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${YELLOW}  SCHEME 1: Routing/Tool Agents - Fixed Rules${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${CYAN}These agents follow fixed, verified rules.${NC}"
echo ""

echo -e "${CYAN}Routing Constraints:${NC}"
grep -E "^O\(route|^P\(route|^F\(route" "${GUARDRAILS}/scheme-1.logic" 2>/dev/null | head -4 | while read line; do
    echo -e "  ${line}"
done
echo ""

echo -e "${CYAN}Execution Constraints:${NC}"
grep -E "^O\(verify|^F\(execute" "${GUARDRAILS}/scheme-1.logic" 2>/dev/null | head -3 | while read line; do
    echo -e "  ${line}"
done
echo ""

sleep 2

# -----------------------------------------------------------------------------
# Scheme 2: Designer
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${YELLOW}  SCHEME 2: Designer Agent - Bounded Generation${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${GREEN}Can CREATE within constraints. Outputs verified by NOEVO.${NC}"
echo ""

echo -e "${CYAN}Generation Bounds:${NC}"
grep -E "^P\(generate|^O\(submit|^F\(deploy" "${GUARDRAILS}/scheme-2.logic" 2>/dev/null | head -4 | while read line; do
    echo -e "  ${line}"
done
echo ""

echo -e "${CYAN}Learning Bounds:${NC}"
grep -E "^P\(learn|learning_rate" "${GUARDRAILS}/scheme-2.logic" 2>/dev/null | head -2 | while read line; do
    echo -e "  ${line}"
done
echo ""

sleep 2

# -----------------------------------------------------------------------------
# Scheme 3: Composer
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${YELLOW}  SCHEME 3: Composer Agent - Bounded Composition${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${GREEN}Can COMBINE within constraints. Outputs verified by NOEVO.${NC}"
echo ""

echo -e "${CYAN}Composition Bounds:${NC}"
grep -E "^P\(compose|^O\(verify|^F\(compose" "${GUARDRAILS}/scheme-3.logic" 2>/dev/null | head -4 | while read line; do
    echo -e "  ${line}"
done
echo ""

echo -e "${CYAN}Workflow Bounds:${NC}"
grep -E "workflow_length|workflow_terminates|recursive" "${GUARDRAILS}/scheme-3.logic" 2>/dev/null | head -3 | while read line; do
    echo -e "  ${line}"
done
echo ""

# -----------------------------------------------------------------------------
# The Key Insight
# -----------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${YELLOW}  THE KEY INSIGHT: Shields Protect Learners${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "  When an ${GREEN}EVO agent${NC} (Designer) proposes an action:"
echo ""
echo -e "    1. Designer generates: ${CYAN}create_new_workflow()${NC}"
echo -e "    2. Routing [NOEVO] receives the proposal"
echo -e "    3. Security [NOEVO] checks against Scheme 0"
echo -e "    4. If valid → execute"
echo -e "    5. If invalid → ${RED}BLOCK + log reasoning${NC}"
echo ""
echo -e "  ${BOLD}NOEVO agents are the guardrails.${NC}"
echo -e "  ${BOLD}EVO agents are the capability.${NC}"
echo -e "  ${BOLD}Together = safe autonomy.${NC}"
echo ""

# -----------------------------------------------------------------------------
# Research Basis
# -----------------------------------------------------------------------------
echo -e "${CYAN}Research Basis:${NC}"
echo ""
echo -e "  • ${BOLD}Shielding${NC} (Alshiekh et al. 2018)"
echo -e "    NOEVO = synthesized safety monitors"
echo ""
echo -e "  • ${BOLD}Constrained Policy Optimization${NC} (Achiam et al. 2017)"
echo -e "    EVO = policies trained with formal constraints"
echo ""
echo -e "  • ${BOLD}Options Framework${NC} (Sutton 1999)"
echo -e "    NOEVO = primitive options, EVO = option generators"
echo ""

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${GREEN}  DEMO COMPLETE${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}Key Takeaways:${NC}"
echo -e "  1. Four schemes: Blocked → Fixed → Bounded Gen → Bounded Compose"
echo -e "  2. NOEVO agents = shields (verified, immutable)"
echo -e "  3. EVO agents = learners (bounded by guardrails)"
echo -e "  4. All constraints are ${BOLD}formal logic${NC}, not rule lists"
echo ""
