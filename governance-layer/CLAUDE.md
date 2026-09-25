# Instructions for Claude Code AI Assistant

This document provides guidance to Claude Code when working in the ESN Governance Layer within the BROAD platform.

---

## Project status: specification and partial implementation (dormant since February 2026; the engine continues as URGE)

The governance layer is **operational** with working code and formal specifications:

**Working Implementation**:
- **Logic Engine**: Multi-paradigm formal reasoning (`src/logic-engine/`)
- **Access Agent**: Governance gateway (`src/access_agent.py`)
- **Heartbeat Protocol**: Session management (`src/heartbeat.py`)
- **Guardrails Schemes**: Formal agent constraints (`src/guardrails/`)

**Key Innovation**: Regex-based paradigm detection enables compile-time logic routing - orders of magnitude faster than LLM-based reasoning.

---

## Repository Structure

```
governance-layer/
├── src/                           # Working implementation
│   ├── access_agent.py           # Governance gateway (Triple-Lock)
│   ├── heartbeat.py              # QUIC heartbeat protocol
│   ├── logic-engine/             # Multi-paradigm Logic Engine
│   │   ├── logic                 # Main entry point
│   │   ├── engines/              # Boolean, Modal, Deontic, Meta
│   │   ├── core/                 # Pipeline (tokenize, identify, route, output)
│   │   │   └── identify.sh       # CRITICAL: Regex paradigm detection
│   │   ├── dict/                 # Unicode Semantic Dictionary
│   │   ├── tests/                # Test suite (130+ cases)
│   │   └── demos/                # ESN access control demo
│   └── guardrails/               # Formal agent constraints
│       ├── scheme-0.logic        # Security Agent (BLOCKED)
│       ├── scheme-1.logic        # NOEVO operational agents
│       ├── scheme-2.logic        # EVO Designer (bounded generation)
│       └── scheme-3.logic        # EVO Composer (bounded composition)
├── specs/                        # Technical specifications
│   ├── core-architecture.md      # Bare-bones infrastructure
│   ├── agent-roles.md            # Agent hierarchy (Tier 1-4)
│   ├── evo-noevo-hierarchy.md    # EVO/NOEVO classification
│   ├── logic-engine.md           # Logic Engine specification
│   ├── protocols.md              # Communication protocols
│   └── hardware.md               # Hardware requirements
├── docs/archive/
│   └── 2025-planning/research/
│       └── L5A-AGENTIC-RESEARCH-FRAMEWORK.md  # Research mappings
├── patents/                      # The Logic Engine specification (copyright-registered; patent pending)
└── tests/                        # Integration tests
```

---

## Quick Verification

```bash
# Test Logic Engine
cd src/logic-engine
./logic "P ∨ ¬P"                    # → TAUTOLOGY
./logic "O(auth) → P(access)"       # → VALID (Deontic)
./logic "□P → P"                    # → T-AXIOM (Modal)

# Test paradigm detection (CRITICAL INNOVATION)
./core/identify.sh "□O(auth) → P(access)"
# → PRIMARY:deontic
# → PARADIGMS:boolean modal deontic

# Run test suite
./tests/run-tests.sh smoke
```

---

## EVO/NOEVO Agent Hierarchy

**CRITICAL CONCEPT**: Agents are classified by evolution capability.

### NOEVO (Non-Evolutionary)
- Fixed behavior after deployment
- Acts as "shield" for EVO agents
- Formally verifiable, deterministic
- **Examples**: Security Agent, Routing Agent, Tool Agent, Orchestrator Agent

### EVO (Evolutionary)
- Can adapt within guardrail constraints
- Outputs verified by NOEVO before execution
- Rollback capability to previous states
- **Examples**: Designer Agent, Composer Agent, Monitor Agent

### Hierarchy Structure
```
A. Security Agent       [NOEVO] - Guardrails Scheme 0
├── A.1 User Agent      [CONTROLLED] - Bio-auth required
│   └── A.1.1 Routing   [NOEVO] - Scheme 1
│       ├── A.1.n.1 Chat       [NOEVO] - Context only
│       ├── A.1.n.2 Tool       [NOEVO] - Pre-made tools
│       ├── A.1.n.3 Orchestrator [NOEVO] - Verified workflows
│       ├── A.1.n.4 Designer   [EVO] - Scheme 2 (generate)
│       └── A.1.n.5 Composer   [EVO] - Scheme 3 (compose)
├── Monitor Agent       [EVO] - Observation only
└── Ops Agent          [EVO] - Operations only
```

**Full spec**: `specs/evo-noevo-hierarchy.md`

---

## Guardrails Schemes

| Scheme | Level | Agents | Purpose |
|--------|-------|--------|---------|
| 0 | BLOCKED | Security Agent | Ultimate safety - nothing bypasses |
| 1 | Fixed | Routing, Tool, Orchestrator | Operational bounds |
| 2 | Bounded Generation | Designer | Can generate within constraints |
| 3 | Bounded Composition | Composer | Can combine within constraints |

**Key constraints in Scheme 0**:
```
F(harm_user)
F(bypass_authentication)
F(disable_logging)
F(modify_noevo_agent)
□(security_decision → (deontic_check ∧ modal_check ∧ temporal_check))
```

---

## Research Mappings

The architecture maps to current research:

| ESN Component | Research Domain | Key Papers |
|---------------|-----------------|------------|
| Regex paradigm detection | Runtime Verification | MonPoly, Lola, TeSSLa |
| NOEVO agents | Shielding (Safe RL) | Alshiekh et al. 2018 |
| EVO agents | Constrained RL | CPO (Achiam et al. 2017) |
| Agent hierarchy | Hierarchical RL | Options Framework (Sutton 1999) |
| Deontic constraints | Formal Synthesis | Shield Synthesis (Bloem 2015) |
| Edge governance | Neuromorphic | Loihi 2, Akida |

**Full mapping**: `docs/archive/2025-planning/research/L5A-AGENTIC-RESEARCH-FRAMEWORK.md`

---

## Agent Communication Patterns

### NOEVO ↔ NOEVO
- Direct, synchronous, trusted
- Example: `tool_agent.execute(verified_command)`

### EVO → NOEVO
- Request-verify-execute pattern
- EVO proposes, NOEVO verifies, then executes
```python
request = designer_agent.propose_tool()
if security_agent.verify(request):
    result = tool_agent.execute(request)
```

### NOEVO → EVO
- Bounded delegation with constraints
```python
result = designer_agent.generate(task, Constraints(
    time_limit=timedelta(seconds=30),
    output_schema=ApprovedSchema
))
```

### EVO ↔ EVO
- **Must go through Routing Agent (NOEVO)**
- No direct EVO-to-EVO communication

---

## Sub-Agent Spawning Rules

1. **NOEVO can only spawn verified NOEVO** from approved pool
2. **EVO cannot spawn directly** - must request through Security Agent
3. **Spawned agents inherit** parent's guardrails (minimum) plus additional constraints

---

## Integration with BROAD Platform

### MCP Server Mapping
| Domain Server | Agent Type | Guardrails |
|---------------|------------|------------|
| Infrastructure | Tool Agent [NOEVO] | Scheme 1 |
| Sales/Purchasing/Inventory | Tool Agent [NOEVO] | Scheme 1 |
| Healthcare Workflows | Orchestrator [NOEVO] | Scheme 1 |
| Workflow Designer | Designer [EVO] | Scheme 2 |

### Access Control Flow
```
Request → Heartbeat → Access Agent → Logic Engine → ALLOW/DENY
                                          ↓
                            Multi-paradigm evaluation:
                            - Deontic: Is it PERMITTED?
                            - Modal: Is it POSSIBLE?
                            - Temporal: Is it within time bounds?
```

---

## Development Workflow

### Adding New Agents
1. Determine classification: NOEVO or EVO
2. Select appropriate guardrails scheme
3. Implement agent following communication patterns
4. Register with Security Agent
5. Add to routing table
6. Test against guardrails constraints

### Extending Guardrails
1. Edit appropriate `src/guardrails/scheme-N.logic`
2. Use deontic operators: O() P() F()
3. Add temporal bounds with □[t1,t2]
4. Test with Logic Engine: `./logic "new_constraint"`

### Adding Logic Paradigms
1. Create `src/logic-engine/engines/newparadigm.sh`
2. Add detection pattern to `core/identify.sh`
3. Add routing case to `core/route.sh`
4. Add tests to `tests/generate-tests.sh`

---

## Performance Targets

| Metric | Target | Achieved | Research Basis |
|--------|--------|----------|----------------|
| Access decision | <50ms | ✓ | Runtime Verification |
| Logic Engine | <50ms | ✓ | Specification claim |
| Paradigm detection | <5ms | ✓ | Regex compilation |
| Heartbeat rate | 1-50 Hz | ✓ | QUIC protocol |
| Memory footprint | <5MB | ✓ | Edge deployment |

---

## Expansion Opportunities

**Immediate** (current codebase):
- Add Metric Temporal Logic to operators.tsv
- Formalize guardrails as Options (RL)
- Add shield synthesis hook

**Medium-term** (PoC):
- Compile regex governance to Qualcomm NPU (<5ms on-device)
- Implement streaming runtime monitor (TeSSLa-style)
- Prototype constrained EVO agent with JAX/Flax

**Long-term** (production):
- Neuromorphic governance coprocessor (Loihi 2 / Akida)
- Federated EVO agent evolution
- Formal verification of cross-system translations

---

## Key Files for Agent Development

| File | Purpose |
|------|---------|
| `specs/evo-noevo-hierarchy.md` | Agent classification and rules |
| `src/guardrails/scheme-*.logic` | Formal constraints |
| `src/access_agent.py` | Governance gateway implementation |
| `src/logic-engine/core/identify.sh` | Paradigm detection (key innovation) |
| `src/logic-engine/engines/deontic.sh` | Deontic logic evaluation |
| `docs/archive/2025-planning/research/L5A-AGENTIC-RESEARCH-FRAMEWORK.md` | Research context |

---

## Copyright

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED

---

**Last Updated**: 2025-11-30
**Status**: Active Development
**Research Integration**: L5A Framework
