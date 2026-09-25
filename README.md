# BROAD

**Business Resource Observability and Automation Deployment.** A healthcare agentic ERP
design in which every agent action passes a formal logic check before it executes, and the
reasoning behind each decision is recorded rather than inferred.

| | |
|---|---|
| **Status** | Specification and partial implementation. |
| **Written** | October 2025 – February 2026 |
| **Runs today** | The shell logic engine, the access agent and its 57 tests, the heartbeat session manager (Python, no transport) |
| **Does not run** | MCP servers, Terraform deployment, the workflow library's n8n template, the portal |
| **Successor** | [URGE](https://github.com/toneron2/URGE): the production form of the logic engine, Rust, on crates.io |
| **Licence** | Copyright 2025–2026 TODOMODO.IO AGENCY LLC. Published to be read; no licence granted. See [`LICENSE`](LICENSE) |

## Where it sits

BROAD is one piece of a larger design, and the documents here were written before the rest
of that design had names. The 2026 names, and what the 2025 documents call the same thing:

| 2026 name | What it is | Called here |
|---|---|---|
| **igent** | any device running the edge agent stack: a phone, a desktop portlet, the sensor head | "local device", "edge", "Physicalized Agent" |
| **igent.me** | the portal, the one cloud-side endpoint every igent talks to | "cloud agent", "BROAD platform" |
| **URGE** | the governance engine | "Logic Engine" |
| **Security Agent** | the gatekeeper at the portal edge; can block any action | "Access Agent" |
| **BROAD** | the first service behind the portal: ERPNext, n8n as workflow runtime, FHIR R4 | "the BROAD platform" |

```
 igent(n) ──▶ WebTransport / HTTP/3 ──▶ igent.me ──▶ service(n)
 [edge]       [one contract]           [portal]     [BROAD first]
                                          │
                          Security Agent  │  URGE gates every call
                                          │  ALLOW / DENY + reasoning trace
                                          ▼
                              BROAD: ERPNext · n8n · FHIR R4 · MCP
```

Nothing reaches the service without a verdict, and a denied call returns the reasoning
rather than a status code.

## How the check works

The request is classified into the logic paradigms it involves by pattern matching, not by a
language model, then evaluated in each and returned as a verdict with its derivation.

```console
$ ./logic "P ∨ ¬P"                    # TAUTOLOGY
$ ./logic "O(auth) → P(access)"       # VALID          (deontic)
$ ./logic "□P → P"                    # T-AXIOM        (modal, reflexivity)
$ ./core/identify.sh "□O(auth) → P(access)"
PRIMARY:deontic
PARADIGMS:boolean modal deontic
```

These run today against `governance-layer/src/logic-engine/`: four engines, about 4,700
lines of shell, awk and sed. It is a proof of correctness, not of speed; the sub-50 ms
target belongs to URGE.

**Agents are classified by whether they may change.** A **NOEVO** agent is fixed after
deployment and formally verifiable. An **EVO** agent may adapt within guardrails but cannot
execute until a NOEVO agent has verified its output, cannot talk to another EVO agent
directly, and cannot spawn agents. Four guardrail schemes state this as formal constraints,
with Scheme 0 as the floor nothing bypasses:

```
F(harm_user)   F(bypass_authentication)   F(disable_logging)   F(modify_noevo_agent)
□(security_decision → (deontic_check ∧ modal_check ∧ temporal_check))
```

## What is implemented

| Component | State |
|---|---|
| Logic Engine (shell) | Working. Dormant since February 2026; superseded by URGE |
| Security Agent (`governance-layer/src/access_agent.py`) | Working; `test_governance.py` passes 57 of 57 |
| Heartbeat session manager (`governance-layer/src/heartbeat.py`) | Working in Python; no QUIC transport under it |
| Guardrail schemes 0–3 | Defined |
| EVO / NOEVO hierarchy | Specified |
| W0 heartbeat establishment ([`workflows/`](workflows/)) | Designed as a governed workflow: five gates, each evaluated through URGE. Procurement in process |
| W1 sensing the locale ([`workflows/`](workflows/)) | Designed as a governed workflow: six gates, FHIR R4 `Device` and `Observation`. Procurement in process |
| Healthcare workflow library | Started: one BPMN clinical pathway (patient admission), two FHIR R4 mappings (Patient, Encounter), one n8n sync template, an MCP server skeleton. The design names CMMN, DMN and GS1 as well; those are not yet in the repository |
| MCP servers | Designed, not built |
| Deployment | Terraform for GKE, not deployed; the 2026 target is Cloud Run |
| The portal (igent.me) | Not in this repository |

One execution sequence was ever run. Nothing here is deployed.

## The edge

An igent holds a local shadow of the Security Agent and makes safety decisions without the
network, then streams logical telemetry over WebTransport on HTTP/3, with the governance
heartbeat on the highest-priority stream so a dropped video frame cannot delay a decision.
The first device built to that contract is
[physicalized-agent](https://github.com/toneron2/physicalized-agent).

| Layer | igent | igent.me and BROAD |
|---|---|---|
| Transport | WebTransport / QUIC: heartbeat, bio-auth | — |
| Agent | MCP + A2A | MCP |
| Workflow | Process DNA | BPMN 2.0 |
| Data | FHIR R4, governed locally | FHIR R4 |
| Reasoning | URGE | URGE at the portal; n8n runs BROAD's workflows |
| Observability | reasoning traces, bio-auth logs | OpenTelemetry, Prometheus, Grafana |

## Reading order

| | |
|---|---|
| [`PROJECT.md`](PROJECT.md) | What BROAD is, one page (2025 wording: "platform" means service #1) |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Five design principles and the system layers (2025; GKE where the target is now Cloud Run) |
| [`ESN_BROAD_INTEGRATION.md`](ESN_BROAD_INTEGRATION.md) | How governance and BROAD meet; the protocol stack above |
| [`governance-layer/specs/`](governance-layer/specs/) | The ESN specifications, October–November 2025, with a forward note per spec in their [README](governance-layer/specs/README.md) |
| [`governance-layer/patents/`](governance-layer/patents/) | The Logic Engine specification (September 2025, copyright-registered). The architecture is the subject of United States provisional patent application 64/161,805, filed 2026-09-24: patent pending |
| [`DECISIONS.md`](DECISIONS.md) | Each architectural decision with its reasoning |
| [`EXECUTION.md`](EXECUTION.md) | The build sequence |
| [`HEALTHCARE_WORKFLOW_LIBRARY_SUMMARY.md`](HEALTHCARE_WORKFLOW_LIBRARY_SUMMARY.md) | What the workflow library was designed to hold |

The 2025 documents are kept as written. Where the 2026 architecture supersedes them, the
difference is recorded beside them, not edited into them.

## Contact

Tony Slosar · TODOMODO.IO AGENCY LLC · anthonyslosar@gmail.com · [t.me/toneron2](https://t.me/toneron2) · [slosars.me](https://slosars.me)
