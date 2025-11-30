#!/bin/bash
# =============================================================================
# DEMO: Logic Engine Multi-Paradigm Evaluation
# Duration: 3-5 minutes
# Purpose: Show formal logic evaluation across Boolean, Modal, and Deontic
# =============================================================================
# COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Get the logic engine path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGIC_ENGINE="${SCRIPT_DIR}/../../../governance-layer/src/logic-engine"

echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║          ESN LOGIC ENGINE - MULTI-PARADIGM DEMO              ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if logic engine exists
if [[ ! -x "${LOGIC_ENGINE}/logic" ]]; then
    echo -e "${RED}ERROR: Logic Engine not found at ${LOGIC_ENGINE}/logic${NC}"
    exit 1
fi

cd "${LOGIC_ENGINE}"

# -----------------------------------------------------------------------------
# SECTION 1: Boolean Logic
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${YELLOW}  SECTION 1: Boolean Logic - Mathematical Truth${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${CYAN}Testing: P ∨ ¬P (Law of Excluded Middle)${NC}"
echo -e "${CYAN}A proposition is either true or not true - always.${NC}"
echo ""
echo -n "  Result: "
./logic "P ∨ ¬P"
echo ""

sleep 1

echo -e "${CYAN}Testing: P ∧ ¬P (Contradiction)${NC}"
echo -e "${CYAN}A proposition cannot be both true and false.${NC}"
echo ""
echo -n "  Result: "
./logic "P ∧ ¬P"
echo ""

sleep 1

echo -e "${CYAN}Testing: (P → Q) ↔ (¬P ∨ Q) (Material Implication)${NC}"
echo -e "${CYAN}Implication equivalence - foundational logic identity.${NC}"
echo ""
echo -n "  Result: "
./logic "(P → Q) ↔ (¬P ∨ Q)"
echo ""

# -----------------------------------------------------------------------------
# SECTION 2: Modal Logic
# -----------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${YELLOW}  SECTION 2: Modal Logic - Necessity & Possibility${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${CYAN}Testing: □P → P (T-Axiom)${NC}"
echo -e "${CYAN}What is NECESSARY (□) must be TRUE.${NC}"
echo ""
echo -n "  Result: "
./logic "□P → P"
echo ""

sleep 1

echo -e "${CYAN}Testing: □P → □□P (S4-Axiom)${NC}"
echo -e "${CYAN}If necessary, then necessarily necessary.${NC}"
echo ""
echo -n "  Result: "
./logic "□P → □□P"
echo ""

sleep 1

echo -e "${CYAN}Testing: □(P → Q) → (□P → □Q) (K-Axiom)${NC}"
echo -e "${CYAN}Necessity distributes over implication.${NC}"
echo ""
echo -n "  Result: "
./logic "□(P → Q) → (□P → □Q)"
echo ""

# -----------------------------------------------------------------------------
# SECTION 3: Deontic Logic
# -----------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${YELLOW}  SECTION 3: Deontic Logic - Obligations & Permissions${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${CYAN}Testing: O(auth) → P(access)${NC}"
echo -e "${CYAN}If authentication is OBLIGATORY, then access is PERMITTED.${NC}"
echo ""
echo -n "  Result: "
./logic "O(auth) → P(access)"
echo ""

sleep 1

echo -e "${CYAN}Testing: F(action) → ¬P(action)${NC}"
echo -e "${CYAN}If an action is FORBIDDEN, it is NOT PERMITTED.${NC}"
echo ""
echo -n "  Result: "
./logic "F(action) → ¬P(action)"
echo ""

sleep 1

echo -e "${CYAN}Testing: O(action) → ¬F(action)${NC}"
echo -e "${CYAN}If an action is OBLIGATORY, it cannot be FORBIDDEN.${NC}"
echo ""
echo -n "  Result: "
./logic "O(action) → ¬F(action)"
echo ""

# -----------------------------------------------------------------------------
# SECTION 4: Cross-Paradigm (Meta)
# -----------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${YELLOW}  SECTION 4: Cross-Paradigm - Combined Reasoning${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${CYAN}Testing: □O(auth) → P(access)${NC}"
echo -e "${CYAN}If auth is NECESSARILY OBLIGATORY, access is PERMITTED.${NC}"
echo -e "${CYAN}(Modal □ + Deontic O/P)${NC}"
echo ""
echo -n "  Result: "
./logic "□O(auth) → P(access)"
echo ""

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${GREEN}  DEMO COMPLETE${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}Key Takeaways:${NC}"
echo -e "  1. Logic Engine evaluates ${BOLD}formal logic${NC}, not pattern matching"
echo -e "  2. Multiple paradigms: Boolean, Modal (□◇), Deontic (O/P/F)"
echo -e "  3. Cross-paradigm composition for complex governance"
echo -e "  4. All evaluations < 50ms"
echo ""
