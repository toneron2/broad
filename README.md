# BROAD

**Business Resource Observability and Automation Deployment.** A healthcare agentic ERP
where every agent action passes a formal logic check before it executes, and the reasoning
behind every decision is recorded rather than inferred.

Healthcare is the proving vertical, because it is the one where "who accessed this record,
under what authority, and show me the reasoning" is a question with a legal answer.

**Status: Specification and partial implementation.** What runs and what does not is in the
table below.

---

## Where it sits

BROAD is one piece of a larger design, and this repository was written before the rest of
that design had names. The names used from 2026 on:

| Here | What it is | Called in the 2025 documents in this repository |
|---|---|---|
| **igent** | any device running the edge agent stack: a phone, a desktop portlet, the sensor head | "local device", "edge", "Physicalized Agent" |
| **igent.me** | the portal, the one cloud-side thing every igent talks to | "cloud agent", "BROAD platform" |
| **URGE** | the governance engine; the production form of the Logic Engine | "Logic Engine" |
| **Security Agent** | the gatekeeper at the portal edge; can block any action | "Access Agent" |
| **BROAD** | **the first service behind igent.me**: ERPNext, n8n as its workflow runtime, FHIR R4, the healthcare workflow library | "the BROAD platform" |

```
 igent(n) ──▶ WebTransport / HTTP3 / QUIC / TLS 1.3 ──▶ igent.me ──▶ service(n)
 [edge]       [transport, one contract]                 [portal]     [BROAD first]
                                                            │
                                            Security Agent  │  URGE gates every call
                                                            │  ALLOW / DENY + reasoning trace
                                                            ▼
                                        ┌──────────────────────────────────────┐
                                        │  BROAD (service #1)                  │
                                        │  ERPNext · n8n · FHIR R4 · MCP       │
                                        │  BPMN pathways · CMMN · DMN · GS1    │
                                        └──────────────────────────────────────┘
```

So BROAD is not the platform. The platform is the portal and its governance; BROAD is what
the portal routes a governed healthcare request to. Nothing reaches it without a verdict,
and a denied call returns the reasoning rather than a status code.

The documents here (`PROJECT.md`, `ARCHITECTURE.md`, `EXECUTION.md`, the ESN specs) are
the 2025 design and are kept as written. Where the 2026 architecture supersedes them, the
difference is recorded beside them rather than edited into them:
[`governance-layer/specs/README.md`](governance-layer/specs/README.md) carries one forward
note per spec.

## The problem

An AI agent can act. It usually cannot prove why the action was permitted.

Most access control answers that with a probability or a model output. Neither is auditable
and neither is reproducible, which makes both unusable anywhere a regulator can ask for the
decision path. The design here replaces the guess with a formal evaluation: the request is
classified into the logic paradigms it actually involves, evaluated in each, and returned
as a verdict with its own derivation attached.

### Paradigm detection is the mechanism

The Logic Engine here does not ask a language model what kind of question it has been
handed. It matches the expression against regular expressions and routes to the engines
that apply, which is a compile-time decision rather than an inference:

```console
$ ./logic "P ∨ ¬P"                    # TAUTOLOGY
$ ./logic "O(auth) → P(access)"       # VALID          (deontic)
$ ./logic "□P → P"                    # T-AXIOM        (modal, reflexivity)

$ ./core/identify.sh "□O(auth) → P(access)"
PRIMARY:deontic
PARADIGMS:boolean modal deontic
```

Those four commands run today against `governance-layer/src/logic-engine/`.

### Agents are classified by whether they may change

Every agent is **NOEVO** — fixed after deployment, formally verifiable, acting as a shield —
or **EVO**, able to adapt within guardrail constraints but never able to execute without a
NOEVO agent verifying the output first. EVO agents cannot talk to each other directly and
cannot spawn agents; both go through a NOEVO router. A NOEVO agent's capability set is
closed at build time, so there is nothing to escalate to.

Four guardrail schemes express this as formal constraints rather than as policy prose, one
per agent class, with Scheme 0 as the Security Agent's floor that nothing bypasses:

```
F(harm_user)
F(bypass_authentication)
F(disable_logging)
F(modify_noevo_agent)
□(security_decision → (deontic_check ∧ modal_check ∧ temporal_check))
```

### The healthcare vertical is real standards, not a demo

`healthcare-workflow-library/` carries FHIR R4 profiles and terminology, BPMN clinical
pathways, CMMN case models, DMN decision tables and GS1 supply chain definitions, with
converters that turn the modelled pathways into executable n8n workflows and an MCP server so
agents can drive them under governance.

## Where the edge fits

The governance layer was always meant to reach past the cloud. An igent holds a local shadow
of the Security Agent and makes safety decisions without the network, then streams logical
telemetry back over **WebTransport on HTTP/3** — QUIC, bidirectional, with the governance
heartbeat prioritised above everything else so a dropped video frame cannot delay a decision.

| Layer | igent | igent.me and BROAD |
|---|---|---|
| Transport | WebTransport / QUIC — heartbeat, bio-auth | n/a |
| Agent | MCP + A2A | MCP |
| Workflow | Process DNA | BPMN 2.0 |
| Data | FHIR R4, governed locally | FHIR R4 |
| Reasoning | URGE | URGE at the portal; n8n runs BROAD's workflows |
| Observability | Reasoning traces, bio-auth logs | OpenTelemetry, Prometheus, Grafana |

The first device built to this contract is
[**physicalized-agent**](https://github.com/toneron2/physicalized-agent) — a low-cost
healthcare sensor head that computes vectors rather than guesses, governs locally, and treats
the person in front of it as the party it answers to.

## Relationship to URGE

The Logic Engine here is the original proof that multi-paradigm governance works: four
engines, roughly 4,700 lines of shell, awk and sed, and it still executes. It is a proof of
*correctness*, not of speed — the sub-50ms design target belongs to a compiled
implementation, not to a pipeline that pays shell startup on every call.

That implementation is [**URGE**](https://github.com/toneron2/URGE), in Rust, with seven
paradigms, cross-paradigm validation and an obligation lifecycle, published on
[crates.io](https://crates.io/crates/urge) with a
[live browser demo](https://toneron2.github.io/URGE/demo/). In the architecture above, every
place the 2025 documents say "Logic Engine" means URGE. **Read the reasoning here; the
engine continues there.**

## Status

Specification and partial implementation. Honest, because the alternative is worse:

| Component | State |
|---|---|
| Logic Engine (shell) | Working, verified above. Dormant since February 2026; superseded by URGE |
| Security Agent (`src/access_agent.py`, called Access Agent there) | Working: calls the shell engine per request; `src/test_governance.py` passes 57 of 57 |
| Heartbeat session manager (`src/heartbeat.py`) | Working in Python; no QUIC transport under it yet |
| Guardrail schemes 0–3 | Defined |
| EVO / NOEVO hierarchy | Specified |
| Healthcare Workflow Library | Complete |
| MCP servers | Designed, not built |
| Terraform deployment | Designed for GKE, not deployed; the 2026 target is Cloud Run |
| The portal (igent.me) | Not in this repository |
| Production reasoning engine | Moved to [URGE](https://github.com/toneron2/URGE) |

One execution sequence was ever run. Nothing here is deployed.

## Reading order

| | |
|---|---|
| [`PROJECT.md`](PROJECT.md) | What BROAD is, in one page (2025 wording: "platform" means service #1 above) |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | The five design principles and the system layers (2025; GKE where the target is now Cloud Run) |
| [`ESN_BROAD_INTEGRATION.md`](ESN_BROAD_INTEGRATION.md) | How governance and BROAD meet, and the protocol stack above |
| [`governance-layer/specs/`](governance-layer/specs/) | The ESN specifications, October–November 2025, unchanged since, with a forward note per spec in their [README](governance-layer/specs/README.md) |
| [`DECISIONS.md`](DECISIONS.md) | Every architectural decision with its reasoning |
| [`EXECUTION.md`](EXECUTION.md) | The build sequence |
| [`HEALTHCARE_WORKFLOW_LIBRARY_SUMMARY.md`](HEALTHCARE_WORKFLOW_LIBRARY_SUMMARY.md) | What the healthcare vertical delivered |
| [`press-room/`](press-room/) | The December 2025 capture and demo scripts; the press room itself moved out of this repository |

## License

Copyright 2025–2026 TODOMODO.IO AGENCY LLC. All rights reserved. This repository is published
to be read, not to be reused; no licence is granted — see [`LICENSE`](LICENSE).
[URGE](https://github.com/toneron2/URGE) is Apache-2.0 and
[physicalized-agent](https://github.com/toneron2/physicalized-agent) is MIT.
