# Instructions for Claude Code AI Assistant

This document provides guidance to Claude Code when working in the ESN Governance Layer.

---

## Project Status: ACTIVE DEVELOPMENT

The governance layer is **operational** with working code:
- **Logic Engine**: Multi-paradigm formal reasoning (`src/logic-engine/`)
- **Access Agent**: Governance gateway (`src/access_agent.py`)
- **Heartbeat Protocol**: Session management (`src/heartbeat.py`)

---

## Repository Structure

```
governance-layer/
├── src/                           # Working implementation
│   ├── access_agent.py           # Governance gateway (Triple-Lock)
│   ├── heartbeat.py              # QUIC heartbeat protocol
│   └── logic-engine/             # Multi-paradigm Logic Engine
│       ├── logic                 # Main entry point
│       ├── engines/              # Boolean, Modal, Deontic, Meta
│       ├── core/                 # Pipeline components
│       ├── dict/                 # Unicode Semantic Dictionary
│       ├── tests/                # Test suite
│       └── demos/                # ESN access control demo
├── specs/                        # Technical specifications
│   ├── core-architecture.md
│   ├── agent-roles.md
│   ├── logic-engine.md
│   ├── protocols.md
│   └── hardware.md
├── patents/                      # Patent documents
│   ├── logic-engine-patent.pdf
│   └── Unicode Semantic Dictionary...pdf
├── docs/                         # Documentation
└── tests/                        # Integration tests
```

---

## Quick Verification

```bash
# Test Logic Engine
cd src/logic-engine
./logic "P ∨ ¬P"                    # → TAUTOLOGY
./logic "O(auth) → P(access)"       # → VALID

# Test Access Agent
cd src
python3 access_agent.py

# Test Heartbeat Protocol
python3 heartbeat.py
```

---

## Core Architectural Principles

### 1. All Access Through Governance
Every resource access flows through the Access Agent:
```
Request → Heartbeat → Access Agent → Logic Engine → ALLOW/DENY
```

### 2. Triple-Lock Security
All access decisions require:
1. **Bio-authentication** (user identity) - future: heartbeat carrier
2. **OAuth2/IAM** (service identity)
3. **Logic Engine** (formal reasoning)

### 3. Multi-Paradigm Logic Engine
The Logic Engine combines 4+ paradigms:
- **Boolean**: Propositional logic, truth tables
- **Modal**: Kripke semantics (□ necessity, ◇ possibility)
- **Deontic**: Obligations (O), Permissions (P), Forbidden (F)
- **Meta**: Cross-paradigm composition (Figure 26)

### 4. Auditable Decisions
All access decisions are logged with:
- Policy expression (formal logic)
- Paradigms used
- Reasoning trace
- Timestamp
- Confidence level

---

## Key Components

### Access Agent (`src/access_agent.py`)
- Builds formal policy expressions from context
- Calls Logic Engine for evaluation
- Returns ALLOW/DENY with reasoning trace
- Logs all decisions for audit

### Heartbeat Protocol (`src/heartbeat.py`)
- Device registration and session management
- Adaptive rate: 1-50 Hz based on activity
- Carries authentication state
- Monitors session health

### Logic Engine (`src/logic-engine/`)
- ~4,300 lines of bash/awk/sed
- <50ms decision latency
- POSIX-only dependencies
- Patent Figure 26 implementation

---

## Integration with BROAD

This governance layer integrates with the BROAD platform:
1. MCP tools call `AccessAgent.check_access()` before execution
2. Heartbeat establishes and maintains device sessions
3. Logic Engine evaluates access policies
4. All decisions logged for observability

---

## Development Workflow

### Adding New Logic Paradigms
1. Create `src/logic-engine/engines/newparadigm.sh`
2. Add detection pattern to `src/logic-engine/core/identify.sh`
3. Add routing case to `src/logic-engine/core/route.sh`
4. Add tests to `src/logic-engine/tests/generate-tests.sh`

### Extending Access Policies
1. Add policy template in `AccessAgent._build_policy_expression()`
2. Add role-based check in `AccessAgent.check_role_permission()`
3. Test with `python3 access_agent.py`

---

## Performance Targets

| Metric | Target | Achieved |
|--------|--------|----------|
| Access decision | <50ms | ✓ |
| Logic Engine | <50ms | ✓ |
| Heartbeat rate | 1-50 Hz | ✓ |
| Memory footprint | <5MB | ✓ |

---

## Copyright

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED

---

**Last Updated**: 2025-11-30
**Status**: Active Development
