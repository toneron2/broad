# BROAD in one page

**Business Resource Observability and Automation Deployment: an agentic ERP in which every
agent action passes a formal governance check, with healthcare as the demonstration
vertical.** In the 2026 architecture BROAD is the first service behind the portal igent.me;
the governance layer here is the 2025 form of what became [URGE](https://github.com/toneron2/URGE).
The [README](README.md) carries the name mapping.

| | |
|---|---|
| **Status** | Specification and partial implementation. |
| **Organisation** | TODOMODO.IO AGENCY LLC · Anthony R. Slosar |
| **Written** | November 2025 – February 2026 |
| **Runs** | shell logic engine · access agent (57 tests) · heartbeat session manager (Python) |
| **Designed, not built** | MCP servers · Terraform for GKE · the workflow library beyond its four artefacts |

## Layers

```
 User interface        voice · natural language · bio-authentication
 ──────────────────────────────────────────────────────────────────────
 Governance layer      heartbeat session · access agent · logic engine    [runs: governance-layer/src/]
 ──────────────────────────────────────────────────────────────────────
 Platform              ERPNext · n8n · MCP servers by domain · MariaDB, Redis · OpenTelemetry stack · GKE
 ──────────────────────────────────────────────────────────────────────
 Healthcare workflows  FHIR R4 mappings · BPMN pathways · (designed: CMMN, DMN, UDS+, GS1)
```

## Components

| Component | State | Where |
|---|---|---|
| Logic engine: boolean, modal (Kripke), deontic (O/P/F), meta | working | `governance-layer/src/logic-engine/` |
| Access agent: the governance gateway | working | `governance-layer/src/access_agent.py` |
| Heartbeat: session and authentication state | working in Python, no QUIC | `governance-layer/src/heartbeat.py` |
| Healthcare workflow library | one BPMN pathway, two FHIR mappings, one n8n template, an MCP server file that does not run | `healthcare-workflow-library/` |
| Terraform modules, GKE deployment | not started | — |

```bash
cd governance-layer/src/logic-engine && ./logic "P ∨ ¬P"        # TAUTOLOGY
./logic "O(auth) → P(access)"                                    # VALID
cd .. && python3 test_governance.py                              # 57 passed
```

## Decisions that shape it

| Question | Decision |
|---|---|
| When does governance enter | from the first deployment, not as a later layer |
| Reasoning in phase 0 | the shell logic engine as it is; no separate validation phase |
| Hardware path | cloud simulation → Orange Pi 5 → Pixel (AOSP) |
| Use case | a community health centre: FHIR R4, UDS+ reporting, clinical pathways |
| Observability | 100 % tracing first, sampled later |
| Deployment | configurable; chunked by default |

The full register is [`DECISIONS.md`](DECISIONS.md); the sequence is [`EXECUTION.md`](EXECUTION.md).

## Stack

| Layer | Choice |
|---|---|
| Governance | logic engine in bash/awk/sed; target under 50 ms per decision; heartbeat over QUIC |
| ERP | ERPNext, full deployment |
| Workflows | n8n |
| Infrastructure | GKE via Terraform; MariaDB and Redis self-hosted |
| Observability | OpenTelemetry, Prometheus, Grafana |
| Clinical data | FHIR R4 (HAPI); BPMN 2.0 pathways; SNOMED, LOINC, RxNorm |

## Contact

Tony Slosar · TODOMODO.IO AGENCY LLC · anthonyslosar@gmail.com · [t.me/toneron2](https://t.me/toneron2) · [slosars.me](https://slosars.me)

Copyright 2025–2026 TODOMODO.IO AGENCY LLC. All rights reserved.
