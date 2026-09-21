# Execution sequence

**Six sequences, no timelines. Sequence 1 ran; nothing after it has.** Written 2025-11-29,
when the logic engine proof of concept existed and the question of when governance enters
was settled: from the start.

| | |
|---|---|
| **Decisions by** | Anthony R. Slosar |
| **Ran** | Sequence 1: the logic engine linked into `governance-layer/src/`, the access agent calling it, the heartbeat session manager |
| **Did not run** | Sequences 2–6 |
| **2026 note** | the platform target moved from GKE to Cloud Run behind igent.me; the edge path is now the sensor head and the S23 (see [physicalized-agent](https://github.com/toneron2/physicalized-agent)) |

## Sequences

| # | Sequence | Actions | Complete when |
|---|---|---|---|
| 1 | Governance foundation | link the logic engine into BROAD; a governance wrapper for MCP access; heartbeat integration points; an access agent that calls the engine | an access decision flows request → engine → ALLOW/DENY with a trace. **Done: `access_agent.py`, `heartbeat.py`, 57 tests** |
| 2 | Platform infrastructure | Terraform modules; GKE on the free tier; MariaDB and Redis; observability at 100 % tracing; OAuth2 between services | cluster up, databases reachable, traces in Grafana |
| 3 | Application | ERPNext and n8n on the cluster; the sales and infrastructure MCP servers first; every MCP call through the access agent | ERPNext reachable, workflows executable, tools callable only through governance |
| 4 | Healthcare vertical | HAPI FHIR; BPMN pathways; UDS+ reporting; GS1 supply chain; terminology server | FHIR endpoints up, pathways executable, standards compliance demonstrable |
| 5 | Observability and demonstration | sampling tuned down from 100 %; dashboards of agent decision flows; views of access decisions, workflow composition, inter-agent traces | any decision path can be observed and shown to an ERP professional |
| 6 | Hardware path (parallel) | A: cloud simulation, heartbeat simulated, bio-auth mocked. B: the engine on an Orange Pi 5, a real heartbeat, edge-to-cloud tests. C: Pixel on AOSP/GrapheneOS, full bio-authentication | each phase's transport and authentication measured on the device |

## Decided parameters

| Platform | Healthcare | Governance |
|---|---|---|
| Terraform safety: tiered (read automatic, destroy on approval) | organisation: community health centre | validation phase: skipped; the engine proof suffices |
| observability: 100 % → sampled | FHIR server: HAPI, self-hosted | phase-0 reasoning: the existing engine |
| test data: synthetic + templates | UDS+: yes (FQHC) | integration timing: from the first deployment |
| deployment: configurable, chunked default | GS1: the 24 hospital processes | hardware: cloud → Orange Pi → Pixel |
| interviews: hybrid, synchronous for customisation | pathways: standard + custom | |
| scale tests: user count × workflow complexity | PHI: full and limited data set; terminology: full | |

## User groups

| Group | Interface |
|---|---|
| patients | voice, mobile |
| healthcare workers | simplified web, voice |
| providers | clinical dashboards |
| IT operations | admin console, observability |
| ERP professionals observing | the demonstration views of sequence 5 |

## Technical notes

- The logic engine provides boolean, modal (Kripke), deontic (O/P/F) and meta engines and an
  access-control demonstration; the access agent wraps it as `check_access(resource,
  context) → ALLOW/DENY`.
- The heartbeat is the entry point for governance: a device registers through it, it
  carries authentication state, the access agent watches its health, and a session ends
  when it fails.
- The engine's `operators.tsv` (the Unicode semantic dictionary) is the formal notation;
  agent-composed workflows (Process DNA) were to use it at runtime.

Copyright 2025–2026 TODOMODO.IO AGENCY LLC. All rights reserved.
