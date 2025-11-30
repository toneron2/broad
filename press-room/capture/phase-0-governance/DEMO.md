# Phase 0: Governance Foundation - Demo Guide

**Demo Duration**: 10-15 minutes (full) / 5 minutes (quick)
**Prerequisites**: Terminal access to BROAD repository
**Audience**: ERP professionals, investors, technical partners

---

## Quick Demo (5 minutes)

### Script: `demos/scripts/01-logic-engine-demo.sh`

**Talking Points**:

1. **"This is formal logic evaluation, not LLM guessing"**
   - Show `P ∨ ¬P` → TAUTOLOGY
   - Explain: This is mathematically proven, not probabilistic

2. **"We support multiple reasoning paradigms"**
   - Boolean: True/False
   - Modal: Necessary/Possible (□◇)
   - Deontic: Obligatory/Permitted/Forbidden (O/P/F)

3. **"Paradigm detection in <5ms via regex"**
   - Show `identify.sh` output
   - Explain: We don't ask an LLM "what type is this?" - we pattern match

4. **"Access control is formal, not rule-based"**
   - Show: `O(auth) → P(access)` → VALID
   - Explain: "If authentication is obligatory, then access is permitted"

---

## Full Demo (15 minutes)

### Part 1: Logic Engine Core (5 min)

Run: `demos/scripts/01-logic-engine-demo.sh`

**Key demonstrations**:
```bash
# Boolean logic - mathematical truth
./logic "P ∨ ¬P"           # TAUTOLOGY (law of excluded middle)
./logic "P ∧ ¬P"           # CONTRADICTION

# Modal logic - necessity and possibility
./logic "□P → P"           # T-AXIOM (what's necessary is true)
./logic "□P → □□P"         # S4-AXIOM

# Deontic logic - obligations and permissions
./logic "O(auth) → P(access)"    # If obligated to auth, permitted to access
./logic "F(harm) → ¬P(harm)"     # If forbidden, then not permitted
```

### Part 2: The Key Innovation (3 min)

Run: `demos/scripts/02-paradigm-detection-demo.sh`

**Talking point**: "This is what makes <50ms governance possible"

```bash
# Show paradigm detection
./core/identify.sh "□O(auth) → P(access)"
# Output:
# PRIMARY:deontic
# PARADIGMS:boolean modal deontic

# Explain the magic
cat core/identify.sh | grep -A2 "Modal\|Deontic"
# Shows regex patterns that route to correct engine
```

### Part 3: Guardrails in Action (4 min)

Run: `demos/scripts/03-guardrails-demo.sh`

**Show the formal constraints**:
```bash
# Security Agent constraints (Scheme 0)
head -50 src/guardrails/scheme-0.logic

# Point out key constraints:
# F(harm_user)              - FORBIDDEN: harm user
# F(bypass_authentication)  - FORBIDDEN: bypass auth
# □(security_decision ≤ 50ms) - ALWAYS: decide in 50ms
```

**Explain EVO/NOEVO**:
```bash
# Show the hierarchy
cat specs/evo-noevo-hierarchy.md | head -80

# Key point: NOEVO agents are SHIELDS
# They protect EVO agents from making mistakes
```

### Part 4: Access Control Flow (3 min)

Run: `demos/scripts/04-access-control-demo.sh`

**Show the decision flow**:
```
Request: "View patient 12345"
    ↓
Heartbeat: Session valid? ✓
    ↓
Access Agent: Evaluate policy
    ↓
Logic Engine:
  - Deontic: P(view_patient) given role=provider? ✓
  - Modal: ◇(access) given shift_hours? ✓
  - Temporal: □[0,8h](session_valid)? ✓
    ↓
Decision: ALLOW (reasoning trace logged)
```

---

## Demo Scenarios

### Scenario A: Successful Access

**Setup**: Provider requesting patient record during shift
```
User: provider_001 (authenticated)
Action: view_patient_record
Resource: patient_12345
Context: time=09:00, department=cardiology
```

**Expected**: ALLOW with reasoning trace

### Scenario B: Denied Access

**Setup**: Unauthorized role requesting PHI
```
User: admin_001 (authenticated)
Action: view_patient_record
Resource: patient_12345
Context: role=IT_admin (not clinical)
```

**Expected**: DENY with explanation
- `¬P(view_phi) ← role ∉ clinical_roles`

### Scenario C: EVO Agent Bounded

**Setup**: Designer agent proposes new workflow
```
Agent: designer_001 [EVO]
Action: generate_workflow
Constraints: scheme-2 bounds
```

**Expected**: Workflow generated, submitted for verification
- Output goes to NOEVO agent for approval before deployment

---

## Q&A Preparation

### "How is this different from RBAC?"

**Answer**: "Traditional RBAC is static rules. We use formal logic:
- Deontic logic expresses obligations and permissions
- Modal logic handles possibility in context
- Temporal logic enforces time bounds
- Cross-paradigm composition for complex decisions

The Logic Engine doesn't just check 'role = X'. It evaluates formal propositions."

### "Why not use an LLM for access control?"

**Answer**: "Three reasons:
1. **Latency**: LLM = 100-2000ms, Logic Engine = <50ms
2. **Determinism**: Same input always gives same output
3. **Auditability**: We can prove WHY a decision was made

We use formal logic where determinism matters, LLMs where flexibility matters."

### "What happens if the Logic Engine is wrong?"

**Answer**: "The guardrails are formally specified. If `F(harm_user)` is in Scheme 0, NO agent can bypass it. The Logic Engine evaluates what's permitted - it doesn't decide what SHOULD be permitted. That's defined in the guardrails."

---

## Recording Notes

If recording a demo:

1. **Terminal setup**: Large font, dark background, clear prompt
2. **Pacing**: Pause after each command to show output
3. **Commentary**: Narrate what you're showing and why it matters
4. **Highlight**: Use mouse to point at key output lines

---

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
