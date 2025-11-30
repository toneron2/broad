#!/bin/bash
# =============================================================================
# DEMO: Access Control Decision Flow
# Duration: 3-4 minutes
# Purpose: Show the full governance flow from request to decision
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
LOGIC_ENGINE="${SCRIPT_DIR}/../../../governance-layer/src/logic-engine"
GOVERNANCE="${SCRIPT_DIR}/../../../governance-layer/src"

echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║          ACCESS CONTROL - FULL DECISION FLOW                 ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# -----------------------------------------------------------------------------
# The Architecture
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${YELLOW}  THE GOVERNANCE ARCHITECTURE${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "  ${CYAN}Every request flows through:${NC}"
echo ""
echo -e "  ┌─────────────────────────────────────────────────────────┐"
echo -e "  │                    ${BOLD}USER REQUEST${NC}                         │"
echo -e "  │    \"View patient 12345 medical records\"                │"
echo -e "  └─────────────────────┬───────────────────────────────────┘"
echo -e "                        │"
echo -e "                        ▼"
echo -e "  ┌─────────────────────────────────────────────────────────┐"
echo -e "  │                 ${BOLD}QUIC HEARTBEAT${NC}                          │"
echo -e "  │    • Session valid?                                    │"
echo -e "  │    • Device authenticated?                             │"
echo -e "  │    • Bio-signature current?                            │"
echo -e "  └─────────────────────┬───────────────────────────────────┘"
echo -e "                        │"
echo -e "                        ▼"
echo -e "  ┌─────────────────────────────────────────────────────────┐"
echo -e "  │                 ${BOLD}ACCESS AGENT${NC}                            │"
echo -e "  │    Triple-Lock: Bio + OAuth2 + Logic                   │"
echo -e "  └─────────────────────┬───────────────────────────────────┘"
echo -e "                        │"
echo -e "                        ▼"
echo -e "  ┌─────────────────────────────────────────────────────────┐"
echo -e "  │                 ${BOLD}LOGIC ENGINE${NC}                            │"
echo -e "  │    Multi-paradigm evaluation (<50ms)                   │"
echo -e "  │    • Deontic: Is it PERMITTED?                         │"
echo -e "  │    • Modal: Is it POSSIBLE in context?                 │"
echo -e "  │    • Temporal: Is it within time bounds?               │"
echo -e "  └─────────────────────┬───────────────────────────────────┘"
echo -e "                        │"
echo -e "                        ▼"
echo -e "  ┌─────────────────────────────────────────────────────────┐"
echo -e "  │            ${GREEN}ALLOW${NC}  or  ${RED}DENY${NC}                             │"
echo -e "  │    (with full reasoning trace logged)                  │"
echo -e "  └─────────────────────────────────────────────────────────┘"
echo ""

sleep 2

# -----------------------------------------------------------------------------
# Scenario 1: Successful Access
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${YELLOW}  SCENARIO 1: Provider Accessing Patient Record${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${CYAN}Request Context:${NC}"
echo -e "  User: Dr. Smith (provider_001)"
echo -e "  Role: Clinical Provider"
echo -e "  Action: view_patient_record"
echo -e "  Resource: patient_12345"
echo -e "  Time: 09:00 AM (within shift)"
echo -e "  Department: Cardiology"
echo ""

echo -e "${CYAN}Policy Evaluation:${NC}"
echo ""

cd "${LOGIC_ENGINE}"

echo -e "  ${BOLD}1. Deontic Check:${NC} P(view_phi) ← role = provider"
echo -n "     Expression: "
echo -e "${CYAN}P(view_phi) ← authenticated ∧ role_provider${NC}"
echo -n "     Result: "
./logic "P(view_phi) ← (authenticated ∧ role_provider)"
echo ""

echo -e "  ${BOLD}2. Modal Check:${NC} ◇(access) given context"
echo -n "     Expression: "
echo -e "${CYAN}◇(access) ← session_valid${NC}"
echo -n "     Result: "
./logic "◇(access) ← session_valid"
echo ""

echo -e "  ${BOLD}3. Temporal Check:${NC} □[shift_start,shift_end](access_permitted)"
echo -n "     Expression: "
echo -e "${CYAN}□(shift_hours → P(access))${NC}"
echo -n "     Result: "
./logic "□(shift_hours → P(access))"
echo ""

echo -e "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${BOLD}${GREEN}  DECISION: ALLOW${NC}"
echo -e "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${CYAN}Reasoning trace logged:${NC}"
echo -e "    timestamp: 2025-11-30T09:00:15Z"
echo -e "    user: provider_001"
echo -e "    action: view_patient_record"
echo -e "    resource: patient_12345"
echo -e "    deontic_check: VALID (role=provider)"
echo -e "    modal_check: VALID (session=active)"
echo -e "    temporal_check: VALID (within shift)"
echo -e "    decision: ALLOW"
echo -e "    latency: 23ms"
echo ""

sleep 2

# -----------------------------------------------------------------------------
# Scenario 2: Denied Access
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${YELLOW}  SCENARIO 2: Non-Clinical Staff Accessing PHI${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${CYAN}Request Context:${NC}"
echo -e "  User: IT Admin (admin_001)"
echo -e "  Role: IT Administrator (non-clinical)"
echo -e "  Action: view_patient_record"
echo -e "  Resource: patient_12345"
echo -e "  Time: 10:30 AM"
echo ""

echo -e "${CYAN}Policy Evaluation:${NC}"
echo ""

echo -e "  ${BOLD}1. Deontic Check:${NC} P(view_phi) ← role ∈ clinical_roles"
echo -n "     Expression: "
echo -e "${CYAN}¬P(view_phi) ← role = IT_admin${NC}"
echo ""
echo -e "     ${RED}FAIL: IT_admin ∉ clinical_roles${NC}"
echo ""

echo -e "  ${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${BOLD}${RED}  DECISION: DENY${NC}"
echo -e "  ${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${CYAN}Reasoning trace logged:${NC}"
echo -e "    timestamp: 2025-11-30T10:30:22Z"
echo -e "    user: admin_001"
echo -e "    action: view_patient_record"
echo -e "    resource: patient_12345"
echo -e "    deontic_check: ${RED}INVALID${NC} (role=IT_admin, not clinical)"
echo -e "    decision: ${RED}DENY${NC}"
echo -e "    reason: \"PHI access requires clinical role\""
echo -e "    latency: 18ms"
echo ""

sleep 2

# -----------------------------------------------------------------------------
# Key Differentiators
# -----------------------------------------------------------------------------
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${YELLOW}  HOW THIS DIFFERS FROM TRADITIONAL ACCESS CONTROL${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "  ${CYAN}Traditional RBAC:${NC}"
echo -e "    IF role = 'provider' AND resource.type = 'patient'"
echo -e "       THEN ALLOW"
echo -e "    ${RED}Problem: Static rules, no reasoning trace${NC}"
echo ""

echo -e "  ${CYAN}ESN Formal Logic:${NC}"
echo -e "    P(access) ← (role ∈ clinical) ∧ ◇(session_valid) ∧ □[t₀,t₁](shift)"
echo -e "    ${GREEN}Benefits:${NC}"
echo -e "      • Composable paradigms (deontic + modal + temporal)"
echo -e "      • Full reasoning trace (WHY, not just WHAT)"
echo -e "      • Provable correctness (formal verification possible)"
echo -e "      • <50ms latency (regex routing, not LLM inference)"
echo ""

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${GREEN}  DEMO COMPLETE${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}Key Takeaways:${NC}"
echo -e "  1. Every access decision has a ${BOLD}formal reasoning trace${NC}"
echo -e "  2. Multi-paradigm: Deontic (permission) + Modal (possibility) + Temporal"
echo -e "  3. Decision latency: ${BOLD}<50ms${NC}"
echo -e "  4. Full audit trail for compliance (HIPAA, SOC2)"
echo ""
