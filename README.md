# BROAD

**Business Resource Observability and Automation Deployment.** An enterprise platform where
every agent action passes a formal logic check before it executes, and the reasoning behind
every decision is recorded rather than inferred.

Healthcare is the proving vertical, because it is the one where "who accessed this record,
under what authority, and show me the reasoning" is a question with a legal answer.

---

## The problem

An AI agent can act. It usually cannot prove why the action was permitted.

Most access control answers that with a probability or a model output. Neither is auditable
and neither is reproducible, which makes both unusable anywhere a regulator can ask for the
decision path. BROAD replaces the guess with a formal evaluation: the request is classified
into the logic paradigms it actually involves, evaluated in each, and returned as a verdict
with its own derivation attached.

## How it works

```
              Voice · natural language · bio-auth
                              │
   ┌──────────────────────────▼──────────────────────────┐
   │  ESN GOVERNANCE LAYER                               │
   │  QUIC heartbeat -- device registration and session  │
   │  Access Agent   -- triple lock: bio + OAuth2 + logic│
   │  Logic Engine   -- boolean, modal, deontic, meta    │
   └──────────────────────────┬──────────────────────────┘
                              │  ALLOW / DENY + reasoning trace
   ┌──────────────────────────▼──────────────────────────┐
   │  BROAD PLATFORM                                     │
   │  MCP servers · ERPNext · n8n · observability · GKE  │
   └──────────────────────────┬──────────────────────────┘
                              │
   ┌──────────────────────────▼──────────────────────────┐
   │  HEALTHCARE WORKFLOW LAYER                          │
   │  FHIR R4 · BPMN clinical pathways · CMMN · DMN · GS1│
   └─────────────────────────────────────────────────────┘
```

Nothing reaches the platform without passing the governance layer. Every MCP tool call is an
access decision, and a denied call returns the reasoning rather than a status code.

### Paradigm detection is the mechanism

The Logic Engine does not ask a language model what kind of question it has been handed. It
matches the expression against regular expressions and routes to the engines that apply,
which is a compile-time decision rather than an inference:

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
cannot spawn agents; both go through a NOEVO router.

Four guardrail schemes express this as formal constraints rather than as policy prose, with
Scheme 0 as the floor nothing bypasses:

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

The governance layer was always meant to reach past the cloud. Edge devices hold a local
Access Agent and make safety decisions without the network, then stream logical telemetry
back over **WebTransport on HTTP/3** — QUIC, bidirectional, with the governance heartbeat
prioritised above everything else so a dropped video frame cannot delay a decision.

| Layer | Edge | Platform |
|---|---|---|
| Transport | WebTransport / QUIC — heartbeat, bio-auth | n/a |
| Agent | MCP + A2A | MCP |
| Workflow | Process DNA | BPMN 2.0 |
| Data | FHIR R4, governed by the Access Agent | FHIR R4 |
| Reasoning | Logic Engine | n8n |
| Observability | Reasoning traces, bio-auth logs | OpenTelemetry, Prometheus, Grafana |

The first device built to this contract is
[**physicalized-agent**](https://github.com/toneron2/physicalized-agent) — a low-cost
healthcare sensor head that computes vectors rather than guesses, governs locally, and treats
the person in front of it as the party it answers to.

## Relationship to URGE

The Logic Engine here is the original proof that multi-paradigm governance works: four
engines, roughly 4,000 lines of shell, and it still executes. It is a proof of *correctness*,
not of speed — the sub-50ms design target belongs to a compiled implementation, not to a
pipeline that pays shell startup on every call.

That implementation is [**URGE**](https://github.com/toneron2/URGE), in Rust, with seven
paradigms and cross-paradigm validation. It has a
[live browser demo](https://toneron2.github.io/URGE/demo/). **Read the reasoning here; the
engine continues there.**

## Status

Honest, because the alternative is worse:

| Component | State |
|---|---|
| Logic Engine (shell) | Working, verified above. Dormant since February 2026 |
| Access Agent | Working |
| QUIC heartbeat | Working |
| Guardrail schemes 0–3 | Defined |
| EVO / NOEVO hierarchy | Specified |
| Healthcare Workflow Library | Complete |
| MCP servers | Designed, not built |
| Terraform / GKE deployment | Designed, not deployed |
| Production reasoning engine | Moved to [URGE](https://github.com/toneron2/URGE) |

This is a specification and a working governance core, not a deployed product. One execution
sequence was ever run.

## Reading order

| | |
|---|---|
| [`PROJECT.md`](PROJECT.md) | What the platform is, in one page |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | The five design principles and the system layers |
| [`ESN_BROAD_INTEGRATION.md`](ESN_BROAD_INTEGRATION.md) | How governance and platform meet, and the protocol stack above |
| [`DECISIONS.md`](DECISIONS.md) | Every architectural decision with its reasoning |
| [`EXECUTION.md`](EXECUTION.md) | The build sequence |
| [`HEALTHCARE_WORKFLOW_LIBRARY_SUMMARY.md`](HEALTHCARE_WORKFLOW_LIBRARY_SUMMARY.md) | What the healthcare vertical delivered |

## License

Copyright 2025–2026 TODOMODO.IO AGENCY LLC. All rights reserved. This repository is published
to be read, not to be reused; no licence is granted. [URGE](https://github.com/toneron2/URGE)
is Apache-2.0 and
[physicalized-agent](https://github.com/toneron2/physicalized-agent) is MIT.
