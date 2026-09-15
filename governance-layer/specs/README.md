# The ESN specifications, and what came after them

The six documents in this directory are the Emergent Synergy Nexus design as written in
October and November 2025. **They are kept byte-for-byte as first published here** (five
arrived with the repository on 2025-11-22; `evo-noevo-hierarchy.md` followed on 2025-11-30),
because a specification that keeps being edited in place stops being a record of anything.

The design did not stop in November 2025. The 2026 architecture that grew out of it uses
one name for each thing where these documents use two, and moves some pieces. Rather than
rewriting the specs, each carries one forward note below. Where a spec and a note disagree,
the note is current; where the note is silent, the spec stands.

The names, once:

| 2026 | In these specs |
|---|---|
| igent — any device running the edge agent stack | "local device", "edge", "Pixel 10", "AOSP device" |
| igent.me — the portal, the one cloud-side thing every igent talks to | "Cloud Agent", "cloud", "GCP" |
| URGE — the governance engine ([github.com/toneron2/URGE](https://github.com/toneron2/URGE)) | "Logic Engine", "Reasoning Layer" |
| Security Agent | "Access Agent" |
| User Agent | "Personal LLM", "Personal Agent" |
| BROAD — the first service behind igent.me | "BROAD platform" |

## Forward notes

### `core-architecture.md` — Bare-Bones Infrastructure Specification, 2025-10-22

Stands as the outside-in method and the five layers. Three things moved. The device is no
longer one phone model: the spec's Pixel 10 build is one of three igent classes (a phone, a
desktop portlet, a sensor head) and the list of devices is a register, not a document. The
Reasoning Layer is URGE. The Cloud Agent is the portal, igent.me; the spec's own hosting
choice, Cloud Run, is the one the 2026 architecture keeps (the BROAD documents above this
directory said GKE; Cloud Run is right until a service needs what only Kubernetes gives).
Appendix A, the heartbeat message and its IDLE → ACTIVE → BURST transitions, is the input
to the igent.me contract and has not been superseded.

### `logic-engine.md` — Reasoning Layer Integration, 2025-10-23

Stands. Its central claim, that the reasoning layer is architectural and the same interface
carries a growing implementation, is what happened: the shell engine at
`../src/logic-engine/` is the Phase 1 proof this document asked for, and URGE is the
implementation behind the same interface, in Rust, with seven paradigms and cross-paradigm
validation. "Logic Engine" here means URGE from 2026 on.

### `agent-roles.md` — Agent Roles Architecture, 2025-10-23

The four tiers are renamed and one is split. Tier 1, the Personal LLM, is the User Agent
and still runs on the device. Tier 2, the Access Agent, is the Security Agent. Tier 4, the
Cloud Agent, is two things in 2026: the portal itself (igent.me) and the Routing Agent that
`evo-noevo-hierarchy.md` already names as A.1.1. The three-layer protocol stack in this
document (WebTransport; A2A + MCP + heartbeat; bio-auth + IAM/PAM + logic) stands
unchanged. The discovery protocol and Process DNA are design, not built. The Unicode
Semantic Dictionary is the notation URGE emits.

### `protocols.md` — WebTransport Protocol Enhancement Analysis, 2025-10-31

Stands as the reason for the transport choice. WebTransport over HTTP/3 (QUIC, TLS 1.3) is
the one design transport between an igent and igent.me: streams for MCP and A2A, datagrams
for the heartbeat. WebRTC is reached for only as media until RTP over QUIC is usable on the
device; gRPC over HTTP/2 is out, as a second stack for no capability the first lacks. The
six-month implementation plan in §6 was not executed.

### `evo-noevo-hierarchy.md` — EVO/NOEVO Agent Hierarchy, 2025-11-30

Stands, and is the hierarchy the 2026 architecture uses: A Security, A.1 User, A.1.1
Routing, A.1.n.1–5, Monitor and Ops, with schemes 0–3 as written in `../src/guardrails/`.
The one addition is that the schemes are evaluated by URGE rather than by the shell engine.
The NOEVO / EVO separation is architectural, not a permission: a NOEVO agent's capability
set is closed at build time, so there is nothing to escalate to.

### `hardware.md` — RK3588 single-board computers, 2025

Not adopted. No Orange Pi 5 Plus or Radxa ROCK 5B was built against. The first non-phone
igent is the sensor head, [physicalized-agent](https://github.com/toneron2/physicalized-agent),
on an ESP32. Kept because it records what was considered and why the phone class stayed
AOSP.

---

COPYRIGHT 2025–2026 TODOMODO.IO AGENCY LLC — ALL RIGHTS RESERVED
