# Source Code - ESN Governance Layer

This directory contains the implementation code for the ESN governance layer integrated into BROAD.

## Structure

```
src/
├── access_agent.py      # Access Agent - governance gateway
├── heartbeat.py         # QUIC Heartbeat Protocol
├── logic-engine/        # Multi-paradigm Logic Engine (linked from ESN)
│   ├── logic            # Main entry point
│   ├── engines/         # Boolean, Modal, Deontic, Meta engines
│   ├── core/            # Pipeline components
│   ├── dict/            # Unicode Semantic Dictionary
│   └── demos/           # ESN access control demo
├── edge/                # Edge device code (future)
├── cloud/               # Cloud orchestration (future)
└── shared/              # Shared libraries (future)
```

## Status: ACTIVE DEVELOPMENT

The governance layer is now operational with:

1. **Logic Engine** - Working multi-paradigm formal reasoning (~4,300 lines)
2. **Access Agent** - Governance gateway calling Logic Engine for decisions
3. **Heartbeat Protocol** - Session management and authentication state

## Quick Test

```bash
# Test Logic Engine
./logic-engine/logic "P ∨ ¬P"                    # → TAUTOLOGY
./logic-engine/logic "O(auth) → P(access)"       # → VALID

# Test Access Agent
python3 access_agent.py

# Test Heartbeat Protocol
python3 heartbeat.py
```

## Integration Flow

```
Device → Heartbeat → Access Agent → Logic Engine → Access Decision
                          ↓
                     MCP Tools / Resources
```

All resource access flows through this governance chain.

## Key Components

### Access Agent (`access_agent.py`)
- Triple-lock security: Bio-auth + OAuth2 + Logic Engine
- Builds formal policy expressions from context
- Logs all decisions for audit

### Heartbeat Protocol (`heartbeat.py`)
- Device registration and session management
- Adaptive rate: 1-50 Hz based on activity
- Carries authentication state
- Future: bio-signature for continuous auth

### Logic Engine (`logic-engine/`)
- Boolean logic (truth tables)
- Modal logic (Kripke semantics - □◇)
- Deontic logic (Obligations/Permissions/Forbidden)
- Meta-engine for cross-paradigm composition

## COPYRIGHT

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
