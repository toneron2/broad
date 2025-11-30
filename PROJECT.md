# BROAD: Business Resource Observability and Automation Deployment

**With ESN Governance Layer Integrated**

## Project Status: ACTIVE DEVELOPMENT

This is the **PRIMARY repository** for the unified BROAD + ESN platform. All other repositories (ESN, ESN0, etc.) are deprecated.

## What This Is

A **self-governing, self-observing enterprise platform** that demonstrates:
1. **Agentic ERP**: AI agents managing enterprise operations
2. **Formal Governance**: Multi-paradigm Logic Engine for access control
3. **Healthcare Vertical**: Complex use case with FHIR, BPMN, UDS+, GS1
4. **Full Observability**: See how the system functions, not just that it functions

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    USER INTERFACE                            │
│          (Voice / Natural Language / Bio-Auth)               │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│              ESN GOVERNANCE LAYER                            │
│  • QUIC Heartbeat (device registration/session)              │
│  • Access Agent (Triple-Lock: bio + OAuth2 + Logic)          │
│  • Logic Engine (Boolean, Modal, Deontic, Meta)              │
│  [WORKING: governance-layer/src/]                            │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                     BROAD PLATFORM                           │
│  • MCP Servers (9 domains)                                   │
│  • ERPNext + n8n                                             │
│  • Databases, Redis, Observability                           │
│  • GKE Infrastructure                                        │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│              HEALTHCARE WORKFLOW LAYER                       │
│  FHIR R4 │ BPMN Clinical Pathways │ UDS+ │ GS1 │ SNOMED     │
│  [COMPLETE: healthcare-workflow-library/]                    │
└─────────────────────────────────────────────────────────────┘
```

## Repository Structure

```
broad/
├── EXECUTION.md                    # Active execution plan (START HERE)
├── PROJECT.md                      # This file
├── governance-layer/               # ESN Governance (WORKING)
│   ├── src/
│   │   ├── access_agent.py        # Governance gateway
│   │   ├── heartbeat.py           # QUIC session management
│   │   └── logic-engine/          # Multi-paradigm reasoning
│   ├── specs/                     # Technical specifications
│   └── patents/                   # Patent documents
├── healthcare-workflow-library/    # Healthcare vertical (COMPLETE)
│   ├── standards/                 # FHIR, BPMN, UDS+, GS1
│   ├── mcp-server/               # Healthcare MCP tools
│   └── n8n-workflows/            # Workflow templates
└── archive/                       # Deprecated files
```

## Core Components

| Component | Status | Location |
|-----------|--------|----------|
| Logic Engine | WORKING | `governance-layer/src/logic-engine/` |
| Access Agent | WORKING | `governance-layer/src/access_agent.py` |
| Heartbeat Protocol | WORKING | `governance-layer/src/heartbeat.py` |
| Healthcare Library | COMPLETE | `healthcare-workflow-library/` |
| Terraform Modules | PENDING | Next sequence |
| GKE Deployment | PENDING | Next sequence |

## Key Decisions Made

| Decision | Choice |
|----------|--------|
| ESN Integration | NOW (governance from start) |
| Use Case | Demonstration + Healthcare + Generic ERP |
| Hardware Path | Cloud → Orange Pi → Pixel |
| Phase 0 Reasoning | Logic Engine (working) |
| Observability | 100% → Intelligent Sampling |
| Deployment | Configurable (chunked default) |

## Quick Verification

```bash
# Test Logic Engine
cd governance-layer/src/logic-engine
./logic "P ∨ ¬P"                    # → TAUTOLOGY
./logic "O(auth) → P(access)"       # → VALID

# Test Access Agent
cd governance-layer/src
python3 access_agent.py

# Test Heartbeat
python3 heartbeat.py
```

## Next Sequence

See `EXECUTION.md` for detailed sequence. Next up:
1. Create Terraform modules (infrastructure layer)
2. Deploy GKE cluster
3. Deploy databases and observability
4. Deploy ERPNext + n8n with governance hooks

## Technology Stack

### Governance Layer (ESN)
- **Logic Engine**: Multi-paradigm formal reasoning (bash/awk/sed)
- **Paradigms**: Boolean, Modal (Kripke), Deontic (O/P/F), Meta
- **Protocol**: QUIC-based heartbeat
- **Target**: <50ms access decisions

### Platform Layer (BROAD)
- **ERP**: ERPNext (full deployment)
- **Workflows**: n8n orchestration
- **Infrastructure**: GKE + Terraform
- **Database**: Self-hosted MariaDB
- **Cache**: Self-hosted Redis
- **Observability**: OpenTelemetry + Prometheus + Grafana

### Healthcare Layer
- **Clinical Data**: FHIR R4 (HAPI FHIR server)
- **Pathways**: BPMN 2.0 clinical workflows
- **Reporting**: UDS+ federal compliance
- **Supply Chain**: GS1 (24 hospital processes)
- **Terminology**: SNOMED, LOINC, RxNorm

## Contact

- **Organization**: TODOMODO.IO Agency LLC
- **Lead**: Anthony R. Slosar
- **Telegram**: [@toneron2](https://t.me/toneron2)

## Copyright

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
