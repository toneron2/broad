# Governance layer (ESN)

**Emergent Synergy Nexus, the 2025 name for the governance architecture: a device-side
agent, an access agent that gates every action, a multi-logic engine that decides, and a
heartbeat that holds the session.** Designed for people who need computing and face
barriers to it: data stays on the device by default, decisions are explained by rule, and
identity is continuous rather than a password. In 2026 the engine became
[URGE](https://github.com/toneron2/URGE) and the portal became igent.me; the specifications
here are the record of the design.

| | |
|---|---|
| **Specifications** | six, October–November 2025, in [`specs/`](specs/), each with a forward note in [`specs/README.md`](specs/README.md) |
| **Code** | [`src/`](src/): the shell logic engine (about 4,700 lines), `access_agent.py` (442 lines), `heartbeat.py` (522 lines), four guardrail schemes, `test_governance.py` (57 tests pass) |
| **Specification document** | [`patents/`](patents/): the Logic Engine specification, September 2025, copyright-registered; no patent filed |
| **Archive** | [`docs/archive/`](docs/archive/): the seed documents, 2025 planning and outreach drafts, setup logs |

## Components

| Component | Role | Where |
|---|---|---|
| Personal agent | a small model on the device (1–3 B parameters); voice, camera, sensors; simple decisions locally; sends nothing without a verdict | specified |
| Access agent | before any data leaves the device or any resource is used: permitted? privacy preserved? on device or in the cloud? and the reasons | `src/access_agent.py` |
| Logic engine | evaluates a request across several logics at once: boolean, modal, deontic, meta, with temporal, fuzzy and probabilistic in the design | `src/logic-engine/` |
| Guardrails | four schemes as formal constraints, one per agent class; scheme 0 is the floor | `src/guardrails/` |
| Heartbeat | the device-to-cloud session: 1 Hz idle, 50 Hz active, carrying the bio-signature; a lost heartbeat ends the session | `src/heartbeat.py` |
| Bio-authentication | fingerprint, voice and usage pattern, verified throughout the session | specified |

Agents are role-based and either **NOEVO** (fixed after deployment, verifiable) or **EVO**
(adaptive within guardrails, never executing unverified); see
[`specs/evo-noevo-hierarchy.md`](specs/evo-noevo-hierarchy.md).

## Targets stated in the design

| Measure | Target |
|---|---|
| heartbeat latency | under 10 ms |
| access decision | under 5 ms on device; under 50 ms through the shell engine |
| tool call round trip | under 100 ms |
| offline | most tasks |

Hardware in the 2025 design: Orange Pi 5 (RK3588) for development, Pixel on AOSP for
deployment. The 2026 device path is the sensor head and the S23; see
[physicalized-agent](https://github.com/toneron2/physicalized-agent).

## Try the engine

```bash
cd src/logic-engine
./logic "P ∨ ¬P"                    # TAUTOLOGY
./logic "O(auth) → P(access)"       # VALID (deontic)
./logic "□P → P"                    # T-AXIOM (modal)
cd .. && python3 test_governance.py # 57 passed
```

## Files

| | |
|---|---|
| [`CLAUDE.md`](CLAUDE.md), [`WORKFLOW.md`](WORKFLOW.md), [`CONTRIBUTING.md`](CONTRIBUTING.md) | working conventions |
| [`config/`](config/), [`scripts/`](scripts/), [`tests/`](tests/) | placeholders with a README each |
| [`docs/archive/`](docs/archive/) | seeds as first written, the 2025 planning and outreach documents, GPG and backup setup logs |
