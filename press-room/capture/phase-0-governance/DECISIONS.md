# Phase 0: Governance Foundation - Key Decisions

**Document Purpose**: Record WHY decisions were made, not just WHAT was decided.

---

## Decision 1: Regex-Based Paradigm Detection

**Date**: November 2025
**Decision Maker**: Architecture Team

### Context
The Logic Engine needs to route expressions to the appropriate evaluation engine (Boolean, Modal, Deontic, etc.). Two approaches were considered:

1. **LLM-based**: Ask an LLM "what type of logic is this?"
2. **Regex-based**: Pattern match on Unicode operators

### Decision
**Regex-based paradigm detection**

### Rationale
| Factor | LLM Approach | Regex Approach |
|--------|--------------|----------------|
| Latency | 100-2000ms | <5ms |
| Determinism | Non-deterministic | Deterministic |
| Cost | API costs | Zero marginal cost |
| Auditability | Opaque | Transparent |
| Edge deployment | Requires connectivity | Works offline |

### Implementation
`governance-layer/src/logic-engine/core/identify.sh` uses regex patterns:
```bash
[□◇] → Modal
[OPF]\( → Deontic
[∀∃] → First-order
```

### Research Basis
- Runtime Verification (MonPoly, Lola, TeSSLa)
- Compile-time logic routing is a form of lightweight runtime monitoring

---

## Decision 2: EVO/NOEVO Agent Classification

**Date**: November 2025
**Decision Maker**: Architecture Team

### Context
AI agents in the platform need different levels of autonomy:
- Some should be fixed and verified (safety-critical)
- Some should adapt and learn (value-adding)

### Decision
**Binary classification: EVO (can evolve) vs NOEVO (cannot evolve)**

### Rationale
| Classification | Properties | Examples |
|---------------|------------|----------|
| NOEVO | Fixed, verified, deterministic, acts as "shield" | Security Agent, Routing Agent, Tool Agent |
| EVO | Adaptive within guardrails, outputs verified by NOEVO | Designer Agent, Composer Agent |

This maps directly to:
- **Options Framework** (Sutton): NOEVO = primitive options, EVO = option generators
- **Safe RL Shielding** (Alshiekh): NOEVO = shields, EVO = shielded policies

### Implementation
- `governance-layer/specs/evo-noevo-hierarchy.md` - Full specification
- `governance-layer/src/guardrails/scheme-*.logic` - Formal constraints

### Key Insight
NOEVO agents don't just "not learn" - they actively **shield** EVO agents, ensuring all EVO outputs are verified before execution.

---

## Decision 3: Deontic Logic as Primary Governance Language

**Date**: November 2025
**Decision Maker**: Architecture Team

### Context
Multiple formal logics could express access control:
- Boolean: True/False
- Modal: Necessary/Possible
- Deontic: Obligatory/Permitted/Forbidden
- Temporal: Always/Eventually

### Decision
**Deontic logic (O/P/F) as the primary language, with modal and temporal extensions**

### Rationale
Deontic logic directly expresses what we need:
```
O(auth) → P(access)    # If auth obligatory, then access permitted
F(harm_user)           # Harm is forbidden
P(read) ∧ F(write)     # Read permitted, write forbidden
```

This is more natural than:
```
auth = TRUE ∧ role = "provider" ∧ time > 0800 ∧ time < 1700  # Boolean mess
```

### Implementation
- `governance-layer/src/logic-engine/engines/deontic.sh` - Deontic evaluation
- `governance-layer/src/guardrails/scheme-*.logic` - All use deontic operators

### Research Basis
- Formal Synthesis (Bloem et al. 2015)
- Shield Synthesis from deontic specifications

---

## Decision 4: Four Guardrails Schemes

**Date**: November 2025
**Decision Maker**: Architecture Team

### Context
Different agent types need different constraint levels:
- Security agents need absolute constraints
- Operational agents need fixed rules
- Creative agents need bounded freedom

### Decision
**Four schemes: 0 (BLOCKED), 1 (Fixed), 2 (Bounded Generation), 3 (Bounded Composition)**

### Rationale
| Scheme | Level | Purpose | Agents |
|--------|-------|---------|--------|
| 0 | BLOCKED | Ultimate safety | Security Agent |
| 1 | Fixed | Operational bounds | Routing, Tool, Orchestrator |
| 2 | Bounded Generation | Can create within limits | Designer |
| 3 | Bounded Composition | Can combine within limits | Composer |

### Implementation
- `governance-layer/src/guardrails/scheme-0.logic` through `scheme-3.logic`

### Key Constraint Examples
```
# Scheme 0 - Absolute
F(harm_user)
F(bypass_authentication)
□(security_decision ≤ 50ms)

# Scheme 2 - Bounded Generation
P(generate_tool) ← within_capability_bounds
O(submit_for_verification)
F(deploy_without_verification)
```

---

## Decision 5: Research-Grounded Architecture (L5A)

**Date**: November 2025
**Decision Maker**: Tony Slosar

### Context
The architecture was developed organically. Question: Does it align with current research?

### Decision
**Map architecture to cutting-edge research domains and document the mapping**

### Research Mapping
| ESN Component | Research Domain | Key Papers |
|---------------|-----------------|------------|
| Regex detection | Runtime Verification | MonPoly, Lola, TeSSLa |
| NOEVO agents | Shielding (Safe RL) | Alshiekh et al. 2018 |
| EVO agents | Constrained RL | CPO (Achiam et al. 2017) |
| Agent hierarchy | Hierarchical RL | Options Framework (Sutton 1999) |
| Deontic constraints | Formal Synthesis | Bloem et al. 2015 |

### Implementation
`governance-layer/docs/research/L5A-AGENTIC-RESEARCH-FRAMEWORK.md`

### Value
- Academic credibility for presentations
- Clear expansion roadmap (neuromorphic, federated learning)
- Validates architectural intuitions

---

## Decision 6: Integrate ESN Governance NOW (Not Later)

**Date**: November 2025
**Decision Maker**: Tony Slosar

### Context
Two approaches to governance:
1. Build ERP first, add governance later
2. Governance from day one

### Decision
**Governance from day one** - Every MCP call goes through Access Agent

### Rationale
| Factor | Later Integration | Day-One Integration |
|--------|-------------------|---------------------|
| Retrofit cost | High (every endpoint) | None (baked in) |
| Security posture | Gaps during development | Consistent |
| Demo value | "We'll add security" | "Security is foundational" |
| Architecture clarity | Bolted on | Integrated |

### Implementation
All MCP tool calls route through:
```
Request → Heartbeat → Access Agent → Logic Engine → ALLOW/DENY
```

### Key Quote
"The Logic Engine proof exists. ESN integrates NOW."

---

## Decisions NOT Made (Deferred)

| Topic | Why Deferred | When to Decide |
|-------|--------------|----------------|
| Neuromorphic deployment | Hardware not ready | Phase 5+ |
| Federated EVO learning | Need base system first | Phase 4+ |
| NPU compilation | Pixel deployment later | Phase 5+ |

---

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
