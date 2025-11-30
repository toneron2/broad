#!/bin/bash
# =============================================================================
# DEMO: All Demos - Complete Governance Demonstration
# Duration: 15-20 minutes
# Purpose: Run all Phase 0 demos in sequence
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║     BROAD/ESN GOVERNANCE - COMPLETE DEMONSTRATION           ║${NC}"
echo -e "${BOLD}${BLUE}║                                                              ║${NC}"
echo -e "${BOLD}${BLUE}║     Phase 0: Governance Foundation                          ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "This demonstration covers:"
echo -e "  1. Logic Engine - Multi-paradigm formal evaluation"
echo -e "  2. Paradigm Detection - Regex innovation (<5ms routing)"
echo -e "  3. Guardrails Schemes - Formal agent constraints"
echo -e "  4. Access Control Flow - Full governance decision"
echo ""
echo -e "Total duration: ~15-20 minutes"
echo ""

# Check for --quick flag
if [[ "$1" == "--quick" ]]; then
    echo -e "${YELLOW}Running in QUICK mode (demos 1 and 4 only)${NC}"
    echo ""
    QUICK_MODE=true
else
    QUICK_MODE=false
fi

read -p "Press Enter to begin (or Ctrl+C to cancel)..."
echo ""

# -----------------------------------------------------------------------------
# Demo 1: Logic Engine
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${YELLOW}  DEMO 1 of 4: Logic Engine${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

"${SCRIPT_DIR}/01-logic-engine-demo.sh"

read -p "Press Enter to continue to next demo..."
echo ""

# -----------------------------------------------------------------------------
# Demo 2: Paradigm Detection
# -----------------------------------------------------------------------------
if [[ "$QUICK_MODE" == false ]]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${YELLOW}  DEMO 2 of 4: Paradigm Detection${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    "${SCRIPT_DIR}/02-paradigm-detection-demo.sh"

    read -p "Press Enter to continue to next demo..."
    echo ""
fi

# -----------------------------------------------------------------------------
# Demo 3: Guardrails
# -----------------------------------------------------------------------------
if [[ "$QUICK_MODE" == false ]]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${YELLOW}  DEMO 3 of 4: Guardrails Schemes${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    "${SCRIPT_DIR}/03-guardrails-demo.sh"

    read -p "Press Enter to continue to next demo..."
    echo ""
fi

# -----------------------------------------------------------------------------
# Demo 4: Access Control
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${YELLOW}  DEMO 4 of 4: Access Control Flow${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

"${SCRIPT_DIR}/04-access-control-demo.sh"

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              DEMONSTRATION COMPLETE                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}What We Demonstrated:${NC}"
echo ""
echo -e "  ${GREEN}✓${NC} Logic Engine: Multi-paradigm formal reasoning"
echo -e "  ${GREEN}✓${NC} Paradigm Detection: <5ms regex-based routing"
echo -e "  ${GREEN}✓${NC} Guardrails: Formal constraints (EVO/NOEVO)"
echo -e "  ${GREEN}✓${NC} Access Control: Full governance flow <50ms"
echo ""
echo -e "${BOLD}Key Differentiators:${NC}"
echo ""
echo -e "  • Formal logic, not rule matching"
echo -e "  • Deterministic, not probabilistic"
echo -e "  • Full reasoning traces for compliance"
echo -e "  • Research-grounded architecture (L5A)"
echo ""
echo -e "${CYAN}For more information:${NC}"
echo -e "  • Architecture: governance-layer/specs/"
echo -e "  • Research: governance-layer/docs/research/L5A-*.md"
echo -e "  • Guardrails: governance-layer/src/guardrails/"
echo ""
echo -e "${BOLD}COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED${NC}"
echo ""
