# Instructions for Claude Code AI Assistant

This document provides guidance to Claude Code (claude.ai/code) when working in this repository.

---

## Project Overview

**Emergent Synergy Nexus (ESN)** is a role-based agentic AI system for vulnerable populations and NGO applications. Key features:
- Bio-authenticated continuous trust
- Multi-paradigm formal reasoning (Logic Engine)
- Privacy-by-design governance
- Designed for people with limited literacy or poor internet access

**Current Status**: Specification phase - no implementation code yet, only architectural documentation.

---

## Repository Structure

```
esn/
├── .claude/                   # Claude Code configuration (commands, agents)
├── docs/                      # User-facing documentation (simplified)
├── specs/                     # Technical specifications (detailed)
│   ├── core-architecture.md   # Main system specification
│   ├── agent-roles.md         # Agent hierarchy and protocols
│   ├── logic-engine.md        # Multi-paradigm reasoning system
│   ├── protocols.md           # WebTransport/QUIC/MCP/A2A
│   └── hardware.md            # Orange Pi 5 execution plan
├── patents/                   # Patent applications
│   └── logic-engine-patent.pdf # Figure 26: Adaptive Processing Workflow
├── src/                       # Source code (Phase 1+)
│   ├── edge/                  # Edge device code (AOSP)
│   ├── cloud/                 # Cloud services (GCP)
│   └── shared/                # Shared libraries/protocols
├── tests/                     # Test suites (Phase 1+)
├── scripts/                   # Build and deployment automation
├── config/                    # Configuration files
└── README.md                  # Main project introduction
```

---

## Core Architectural Principles

### 1. Outside-In Design
Define constraints first (hardware, protocol, security), then discover capabilities within those boundaries. This ensures the system is governable, predictable, and trustworthy.

### 2. Privacy-by-Design
The Access Agent enforces privacy BEFORE any data transmission. All data movement must be:
- Explicitly authorized
- Logged with reasoning traces
- Subject to privacy transformations
- Auditable

### 3. Role-Based Agents (Not Swarms)
ESN uses hierarchical agent roles with formal governance:
- **Personal LLM**: User's digital proxy (no direct resource access)
- **Access Agent**: Security gatekeeper with Logic Engine
- **Specialized Agents**: Camera, Sensor, Tool agents with limited scope
- **Cloud Agents**: Orchestration, registry, workflow execution

### 4. Multi-Paradigm Logic Engine
The Logic Engine uses 15+ logic systems simultaneously:
- Temporal: Time-based rules
- Deontic: Obligations and permissions
- Modal: Necessity and possibility
- Fuzzy: Degrees of truth
- Probabilistic: Uncertainty reasoning
- And 10+ more (see `patents/logic-engine-patent.pdf` Figure 26)

### 5. Continuous Bio-Authentication
Unlike login-once systems, ESN continuously verifies user identity via:
- Fingerprint patterns
- Voice characteristics
- Behavioral patterns
- Embedded in 1-50 Hz heartbeat protocol

---

## Key Technical Specifications

### Performance Requirements
- Heartbeat latency: < 10ms p50
- Access control decisions: < 5ms (Phase 0), < 20ms (Phase 1)
- Resource allocation: < 10ms (Phase 0), < 50ms (Phase 1)
- Tool call round-trip: < 100ms (edge → cloud → edge)

### Protocol Layer
- **WebTransport over QUIC**: Single transport protocol
- **Heartbeat Protocol**: Bio-authenticated, 1-50 Hz adaptive
- **MCP (Model Context Protocol)**: Tool/sensor access
- **A2A (Agent-to-Agent)**: Inter-agent communication

### Hardware Platform
- **Development**: Orange Pi 5 (Rockchip RK3588) - see `specs/hardware.md`
- **Target Deployment**: Google Pixel devices with AOSP/GrapheneOS
- **Local AI**: 1-3B parameter LLMs (quantized)
- **Cloud**: Google Cloud Platform

---

## Development Phases

### Phase 0: Foundation Validation (CURRENT)
- Complete specifications
- Validate research novelty
- Establish NGO partnerships
- Acquire hardware for prototyping
- Build heartbeat proof-of-concept

**Success Criteria**: Defined in `specs/core-architecture.md`

### Phase 1: Logic Engine Integration
- Replace rule-based reasoning with multi-paradigm Logic Engine
- Implement Unicode Semantic Dictionary
- Deploy 3-5 core paradigms (temporal, deontic, modal, fuzzy, probabilistic)
- Achieve < 20ms simple decisions, < 50ms complex decisions
- Create comprehensive test suite

**Migration Checklist**: Defined in `specs/logic-engine.md`

### Phase 2: Community Scale
- Open-source release
- Community-contributed dialects and workflows
- GrapheneOS security hardening
- Multi-device coordination
- NGO pilot deployments

---

## Documentation Standards

### Writing Style
All documentation should be:
1. **Clear**: College freshman reading level for docs/, graduate level for specs/
2. **Structured**: Use headings, lists, and tables
3. **Scholarly**: Use proper citations and references
4. **Audience-First**: Know who will read each document

### Document Types
- `README.md`: Introductory overview for all audiences
- `docs/*.md`: User-facing guides (simplified language)
- `specs/*.md`: Technical specifications (detailed, precise)
- `patents/*.pdf`: Patent applications (formal legal language)

---

## Working with Claude Code

### Modus Operandi
This project follows Claude Code best practices as defined in the root `modus_operandi.md`:
- Use **Agents** for complex multi-step tasks
- Use **Skills** for specialized capabilities (PDF processing, etc.)
- Use **Slash Commands** for frequent workflows
- Leverage **MCP** for external data sources

### Custom Agents (`.claude/agents/`)
Project-specific agents will be defined for:
- Logic Engine specification validation
- Protocol conformance checking
- Documentation consistency
- Hardware compatibility verification

### Custom Commands (`.claude/commands/`)
Project-specific commands will be defined for:
- `/cleanup`: Repository maintenance
- `/spec-check`: Validate specification completeness
- `/doc-simplify`: Convert technical content to freshman level

---

## Key Concepts and Terminology

- **Personal LLM**: User's on-device digital proxy (no direct resource access)
- **Access Agent**: Security LLM gating all resource access via Logic Engine
- **Reasoning Layer**: Governance layer enforcing access control, privacy, resource allocation
- **Logic Engine**: Multi-paradigm formal reasoning system (15+ logic types)
- **Bio-Signature**: Encrypted fingerprint + voice + behavioral patterns
- **Device Twin**: Cloud-maintained real-time state model of edge device
- **Process DNA**: Composable, evolvable workflow fragments
- **MCP**: Model Context Protocol (tool/sensor access standard)
- **A2A**: Agent-to-Agent communication protocol
- **Triple-Lock**: Bio-auth + IAM/PAM + Logic Engine (all required for access)
- **Heartbeat**: Continuous low-overhead connection with bio-signature
- **Unicode Semantic Dictionary**: 300+ symbols mapped across 15+ logic systems

---

## Reference Alignment

### Knowledge Base
The project aligns with research from:
- NVIDIA Jetson AI community (edge AI, agentic systems)
- CrewAI framework (multi-agent orchestration)
- Academic work in neuro-symbolic AI
- IETF QUIC Working Group (protocol standards)
- Trusted scholarly research (prioritize peer-reviewed sources)

See `docs/research/knowledge.pdf` for detailed bibliography.

### Figure 26: Adaptive Processing Workflow
The Logic Engine implementation is based on Figure 26 from the patent application (`patents/logic-engine-patent.pdf`). This diagram shows:
1. Enhanced Input Analysis (tokenize, identify systems, parse operators)
2. Multi-System Logic Engine Selection (15+ engines)
3. Cross-System Validation (translate, check contradictions)
4. Response Generation (AST, validity, notation, confidence)

---

## Important Constraints

### Reasoning Layer is Architectural (Not Optional)
- All resource access MUST flow through Access Agent
- Reasoning decisions MUST be logged with logic traces
- Privacy enforcement MUST happen before data transmission
- Interface defined in Phase 0, implementation evolves in Phase 1

### No Code Exists Yet
This repository contains specifications only. Implementation begins in Phase 1.

### Copyright and Licensing
All materials currently under:
**COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED**

Open-source licensing will be determined in Phase 2.

---

## Contact

- **Telegram**: [@toneron2](https://t.me/toneron2)
- **Email**: Available via Telegram
- **Organization**: TODOMODO.IO Agency LLC
- **Lead**: Anthony R. Slosar

---

## Development Workflow (Git + GitHub)

This repository follows a standard Git workflow for version control:

### 1. Clone Repository (First Time Only)
```bash
git clone https://github.com/toneron2/esn.git
cd esn
```

### 2. Daily Work Cycle

#### Start of Day
```bash
# Get latest changes from GitHub
git pull
```

#### During Work
Make your changes to files as needed.

#### End of Session - Commit Changes
```bash
# See what changed
git status

# Stage all changes
git add .

# Commit with descriptive message (will be GPG signed automatically)
git commit -m "Your descriptive message here"

# Push to GitHub (backup)
git push
```

### 3. Commit Message Guidelines

Use conventional commit format:
- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `refactor:` Code restructuring
- `chore:` Maintenance tasks
- `test:` Adding tests

Example:
```bash
git commit -m "feat: Add bio-authentication heartbeat protocol"
git commit -m "docs: Update Logic Engine specification"
git commit -m "chore: Update dependencies"
```

### 4. GPG Signing (Automatic)

All commits are automatically GPG signed with your key:
- **Key ID**: `3BB23D1FFB598E99`
- **Name**: Anthony Richard Slosar
- **Email**: anthonyslosar@gmail.com

If passphrase prompt doesn't appear, check Kleopatra settings.

### 5. Troubleshooting

**If push is rejected:**
```bash
git pull --rebase
git push
```

**If you need to undo last commit (before push):**
```bash
git reset --soft HEAD~1
```

**If you accidentally committed sensitive data:**
```bash
git reset --hard HEAD~1  # Removes last commit entirely
```

---

**Last Updated**: 2025-11-05
**Version**: 1.0.0 (Repository Refactor)
**Status**: Specification Phase
