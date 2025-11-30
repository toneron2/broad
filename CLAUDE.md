# Instructions for Claude Code AI Assistant

This document provides guidance to Claude Code when working in the BROAD platform with ESN governance.

---

## Project Overview

**BROAD** (Business Resource Observability and Automation Deployment) is a unified enterprise platform with:
- **ESN Governance Layer**: Formal logic-based access control with bio-authentication
- **Healthcare Workflow Library**: FHIR R4, BPMN, UDS+, GS1 standards integration
- **MCP Servers**: 9 domain-specific agent interfaces
- **Infrastructure**: GKE, ERPNext, n8n on GCP

**Key Innovation**: Regex-based paradigm detection enables compile-time logic routing for governance decisions in <50ms.

---

## Repository Structure

```
broad/
├── CLAUDE.md                         # This file - project context
├── PROJECT.md                        # Project overview
├── ARCHITECTURE.md                   # Architecture documentation
├── EXECUTION.md                      # Execution plan (no timelines)
├── DECISIONS.md                      # Architectural decisions
├── ESN_BROAD_INTEGRATION.md          # Integration strategy
│
├── governance-layer/                 # ESN Governance (WORKING)
│   ├── CLAUDE.md                    # Governance-specific context
│   ├── src/
│   │   ├── access_agent.py          # Governance gateway
│   │   ├── heartbeat.py             # QUIC session management
│   │   ├── logic-engine/            # Multi-paradigm Logic Engine
│   │   │   └── CLAUDE.md            # Logic Engine context
│   │   └── guardrails/              # Formal agent constraints
│   │       ├── scheme-0.logic       # Security Agent [NOEVO]
│   │       ├── scheme-1.logic       # Tool/Routing [NOEVO]
│   │       ├── scheme-2.logic       # Designer [EVO]
│   │       └── scheme-3.logic       # Composer [EVO]
│   ├── specs/
│   │   ├── evo-noevo-hierarchy.md   # Agent classification
│   │   ├── core-architecture.md
│   │   └── agent-roles.md
│   └── docs/research/
│       └── L5A-AGENTIC-RESEARCH-FRAMEWORK.md
│
└── healthcare-workflow-library/      # Healthcare Vertical (COMPLETE)
    ├── standards/                    # FHIR, BPMN, CMMN, DMN, GS1
    ├── converters/                   # BPMN → n8n converters
    ├── n8n-workflows/                # Executable workflow templates
    └── mcp-server/                   # Healthcare MCP server
```

---

## Current Status

| Component | Status | Location |
|-----------|--------|----------|
| Logic Engine | Working | `governance-layer/src/logic-engine/` |
| Access Agent | Working | `governance-layer/src/access_agent.py` |
| Heartbeat Protocol | Working | `governance-layer/src/heartbeat.py` |
| Guardrails Schemes | Defined | `governance-layer/src/guardrails/` |
| EVO/NOEVO Hierarchy | Specified | `governance-layer/specs/evo-noevo-hierarchy.md` |
| Healthcare Workflows | Complete | `healthcare-workflow-library/` |
| MCP Servers | Planned | Design in `DECISIONS.md` |
| Terraform | Planned | Next sequence |

---

## EVO/NOEVO Agent Model

**Critical Concept**: Agents classified by evolution capability.

```
A. Security Agent       [NOEVO] - Guardrails Scheme 0 (BLOCKED)
├── A.1 User Agent      [CONTROLLED] - Bio-auth required
│   └── A.1.1 Routing   [NOEVO] - Scheme 1 (fixed routing)
│       ├── A.1.n.1 Chat       [NOEVO] - Context only
│       ├── A.1.n.2 Tool       [NOEVO] - Pre-made tools
│       ├── A.1.n.3 Orchestrator [NOEVO] - Verified workflows
│       ├── A.1.n.4 Designer   [EVO] - Scheme 2 (bounded generation)
│       └── A.1.n.5 Composer   [EVO] - Scheme 3 (bounded composition)
├── Monitor Agent       [EVO] - Observation only
└── Ops Agent          [EVO] - Operations only
```

**NOEVO**: Fixed, verified, acts as shield
**EVO**: Can adapt within guardrail constraints

---

## Research Foundation

Architecture maps to cutting-edge research:

| Component | Research Domain | Key Work |
|-----------|-----------------|----------|
| Regex paradigm detection | Runtime Verification | MonPoly, Lola, TeSSLa |
| NOEVO agents | Shielding (Safe RL) | Alshiekh et al. 2018 |
| EVO agents | Constrained RL | CPO (Achiam et al. 2017) |
| Agent hierarchy | Hierarchical RL | Options Framework (Sutton 1999) |
| Deontic constraints | Formal Synthesis | Bloem et al. 2015 |

**Full mapping**: `governance-layer/docs/research/L5A-AGENTIC-RESEARCH-FRAMEWORK.md`

---

## Quick Verification

```bash
# Test Logic Engine
cd governance-layer/src/logic-engine
./logic "P ∨ ¬P"                    # → TAUTOLOGY
./logic "O(auth) → P(access)"       # → VALID (Deontic)
./logic "□P → P"                    # → T-AXIOM (Modal)

# Test paradigm detection
./core/identify.sh "□O(auth)"
# → PRIMARY:deontic
# → PARADIGMS:boolean modal deontic
```

---

## Development Priorities

### Next Steps (From EXECUTION.md)

**Sequence 2: Platform Infrastructure**
- Create terraform modules
- Deploy GKE cluster
- Deploy MariaDB, Redis, observability stack

**Sequence 3: Application Deployment**
- Deploy ERPNext on GKE
- Deploy n8n
- Implement MCP servers (Sales, Infrastructure first)

### Agent Development

When implementing agents:
1. Determine classification: NOEVO or EVO
2. Select appropriate guardrails scheme (0-3)
3. Follow communication patterns in `governance-layer/CLAUDE.md`
4. Register with Security Agent
5. Test against guardrails constraints

---

## Key Files by Task

| Task | Primary Files |
|------|---------------|
| Agent design | `governance-layer/specs/evo-noevo-hierarchy.md` |
| Guardrails | `governance-layer/src/guardrails/*.logic` |
| Access control | `governance-layer/src/access_agent.py` |
| Logic evaluation | `governance-layer/src/logic-engine/` |
| Healthcare workflows | `healthcare-workflow-library/` |
| Architecture decisions | `DECISIONS.md` |
| Research context | `governance-layer/docs/research/L5A-*.md` |

---

## Integration Points

### All Access Through Governance
```
Request → Heartbeat → Access Agent → Logic Engine → ALLOW/DENY
                                          ↓
                            Multi-paradigm evaluation:
                            - Deontic: Is it PERMITTED?
                            - Modal: Is it POSSIBLE?
                            - Temporal: Is it within time bounds?
```

### MCP Server → ESN Integration
```python
# Every MCP tool call requires access check
def mcp_tool_handler(request):
    decision = access_agent.check_access(
        resource=request.tool,
        context=request.context,
        user=request.user
    )
    if decision.status == "ALLOW":
        return execute_tool(request)
    else:
        return deny_with_reasoning(decision)
```

---

## Performance Targets

| Metric | Target | Research Basis |
|--------|--------|----------------|
| Access decision | <50ms | Runtime Verification |
| Paradigm detection | <5ms | Regex compilation |
| Heartbeat rate | 1-50 Hz | QUIC protocol |
| Edge governance | <1ms | Neuromorphic (future) |

---

## Copyright

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED

---

**Last Updated**: 2025-11-30
**Branch**: governance-layer
**Status**: Active Development
