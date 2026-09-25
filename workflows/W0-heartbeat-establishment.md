# W0 — Heartbeat establishment, as a governed workflow

**Date:** 2026-09-21 · **Status:** design; procurement in process · **Rung:** W0 of the ladder W0–W3

**One sentence.** W0 turns a registered device into a session: the NOEVO identities only,
every decision a governance expression Janus evaluates with URGE, every step a status
line, and the heartbeat keeping the session alive or taking it down by the same three
expressions for the rest of its life.

Nothing in this document runs. What runs today is the demonstration beside the status
line (`ladder.json` (`identities` repository), six W0 events, two Janus gates evaluated in the
browser) and the contract's fixtures (`bin/check.mjs` in the `igent` repository). The
portal that runs W0 is procurement in process.

## 1. Inputs, by hash

| Input | Version | sha256 | What W0 takes from it |
|---|---|---|---|
| the igent.me contract (`contract.md`, `igent` repository) | v0, 2026-09-21 | `db87034e79a633c51198e68422b4400925b3f58a77d8f2ebaf8022987aa5c45c` | §2 the connection and its streams; §3 `authenticate0` / `authorize0`, the refusal shape, the codes 4010 4030 4090 4260; §4 the heartbeat datagram, ACTIVE / DEGRADED / TERMINATED; §7 the topics; §8 the verdict object |
| `status-line.md` (`identities` repository) | v0, 2026-09-21 | `891001881456692d1511f54d287751a616d7fd0b03c43730f4bce0c0c7b31308` | §1 the event, §3 the verbs, §4 the line and marks, §5 the W0 row |
| `governance-layer/specs/evo-noevo-hierarchy.md` (this repository), `src/guardrails/scheme-0.logic`, `scheme-1.logic` | public, 2025 | as published | the NOEVO rule; scheme 0 (`F(bypass_authentication)`, `F(spoof_bio_signature)`, `F(disable_logging)`); scheme 1 (`O(log_routing_decision)`, `O(verify_before_execute)`, `F(execute_unverified_workflow)`) |
| the `identities` repository's README | 2026-09-21 | tree | the W0 row: Oonia orchestrating sign-on, Janus verifying the secure connection and the bio-signature, Curator opening the session record, Hermes saying so |
| URGE | 0.1.1 as WebAssembly, `1a33e2c60f33eb1a…` (the copy in the `identities` repository's `urge/`, byte-identical) | | every verdict in §4 was evaluated through it on 2026-09-21 |

A change to an input's hash is a reason to reread this document, not to trust it.

## 2. Who does what

Four identities, all NOEVO, so no model runs anywhere in W0. Each is the face of a
role BROAD already defines.

| Identity | Role | In W0 |
|---|---|---|
| 🐌 Oonia | Routing / Orchestrator Agent, scheme 1 | opens the sign-on, orders the steps, routes the session to the register and the heartbeat receiver; publishes on `control` |
| ⚖️ Janus | Security / Access Agent, scheme 0 | decides every gate in §4 by evaluating its expression with URGE; publishes every verdict and every state change on `security` |
| 📚 Curator | the records role | opens the session record, stores every trace URGE produced under its hash, records every state change; subscribes to `security` and `control` |
| 📖 Hermes | User's Personal Agent | says one sentence per outcome on the device, in the person's language; nothing else |

The heartbeat receiver is portal code, not an identity: it counts datagrams and publishes
one message per state change on `heartbeat` (contract §7). Janus subscribes to it.

## 3. The workflow

```
 device                                         portal
 ──────                                         ──────
 QUIC + TLS 1.3 ──────────────────────────────▶ S1  Janus verifying secure connection …
                                                    Janus verified ✓ / denied ✗ (4260)
 authenticate0 {igent, role, hardware, bio} ──▶ S2  Oonia orchestrating sign-on …
                                                    Janus verified ✓ / denied ✗ (4010 · 4030 · 4090)
 authorize0 {session} ────────────────────────▶ S3  Janus verified ✓: the capability set, closed
                                                S4  Curator recorded session <id>
                                                S5  Hermes: "You are connected."
 heartbeat datagram, a Hz ───────────────────▶ H   ACTIVE ⇄ DEGRADED → TERMINATED  (§4, H1–H3)
```

| Step | Line on stream 0 | Gate | On ✓ | On ✗ |
|---|---|---|---|---|
| S1 | ⚖️ Janus verifying secure connection … → verified ✓ | G1 | S2 | refusal 4260 with the verdict; no session; Curator records the refusal from `security` |
| S2 | 🐌 Oonia orchestrating sign-on … · ⚖️ Janus verified sign-on ✓ | G2 | S3; `authenticate0` result with `session`, `rate`, `missed`, the verdict | refusal 4010 (not registered) or 4030 (bio, hardware) with the verdict; 4090 if a session exists for this igent |
| S3 | ⚖️ Janus verified capabilities ✓ | G3 | the closed capability set for the igent's class and role | 4030; the session stands, the call is refused |
| S4 | 📚 Curator recorded session `<id>` | none (a done line, no mark) | the record holds: igent, role, hardware, `bio.kind`, the G1–G3 verdict ids and trace hashes, `t` | |
| S5 | 📖 Hermes: *You are connected. The head is on and verified.* | none | | |
| H1 | none per datagram; on return from DEGRADED: ⚖️ Janus verified heartbeat ✓ | G4 | ACTIVE | |
| H2 | ⚖️ Janus denied use and execute ✗ · 📚 Curator recorded state DEGRADED · 📖 Hermes: *Connection weak; holding.* | G4 | | DEGRADED: session kept, new `use` and `execute` refused 4030 |
| H3 | ⚖️ Janus denied session ✗ · 📚 Curator recorded state TERMINATED · 📖 Hermes: *Disconnected. Reconnecting.* | G5 | | TERMINATED: streams reset; the next `authenticate0` starts at S1 |

Every line carries the fields of status-line §1 with `rung: "W0"` and `step` as named in the
first column; every Janus line carries the verdict object of contract §8. The `seq` of the
Janus line is what Curator's record and Hermes's sentence refer to.

## 4. The gates, as URGE evaluates them

Each gate is one governance expression over named slots. The slot is measured by the
component in the third column; Janus evaluates, it never measures. The verdicts were
produced through URGE 0.1.1 on 2026-09-21 with the slot values shown; the notation is
URGE's own.

| Gate | Expression | Slots and who measures them |
|---|---|---|
| G1 connect | `must tls_established and must contract_supported` | `tls_established` the transport (QUIC handshake complete, TLS 1.3) · `contract_supported` the portal (the `contract` version in `authenticate0` is one it serves) |
| G2 sign-on | `must device_registered and must hardware_matches_register and must bio_signature_fresh` | `device_registered` the register (contract §1) · `hardware_matches_register` the register (the `hardware` field equals the recorded one) · `bio_signature_fresh` the verifier for `bio.kind` (signature verifies and `t` is within the window) |
| G3 capabilities | `must session_active and must_not capability_outside_class` | `session_active` the session table · `capability_outside_class` the capability table for the igent's class and role (contract §5) |
| G4 heartbeat state | `must heartbeat_in_window and must bio_signature_fresh and must bio_signature_strong` | `heartbeat_in_window` the receiver (a datagram within `2 / a` s of the last; false after 3 missed) · `bio_signature_fresh` the verifier per datagram · `bio_signature_strong` the verifier's own score above its threshold |
| G5 termination | `must_not heartbeat_lost and must_not bio_signature_failed_thrice` | `heartbeat_lost` the receiver (10 missed in a row) · `bio_signature_failed_thrice` the verifier (3 consecutive failures) |

| Case | Slots | URGE notation | Verdict |
|---|---|---|---|
| G1 verified | `tls_established=true, contract_supported=true` | `O(tls_established) ∧ O(contract_supported)` | PERMIT 100 % |
| G1 refused 4260 | `contract_supported=false` | same | DENY 67 % |
| G2 verified | all three true | `O(device_registered) ∧ O(hardware_matches_register) ∧ O(bio_signature_fresh)` | PERMIT 100 % |
| G2 refused 4010 | `device_registered=false, hardware_matches_register=false` | same | DENY 80 % |
| G2 refused 4030 | `bio_signature_fresh=false` | same | DENY 60 % |
| G3 verified | `session_active=true, capability_outside_class=false` | `O(session_active) ∧ F(capability_outside_class)` | PERMIT 100 % |
| G3 refused 4030 | `capability_outside_class=true` | same | DENY 67 % |
| G4 ACTIVE | all three true | `O(heartbeat_in_window) ∧ O(bio_signature_fresh) ∧ O(bio_signature_strong)` | PERMIT 100 % |
| G4 DEGRADED, 3 missed | `heartbeat_in_window=false` | same | DENY 60 % |
| G4 DEGRADED, weak bio | `bio_signature_strong=false` | same | DENY 60 % |
| G5 TERMINATED | `heartbeat_lost=true` | `F(heartbeat_lost) ∧ F(bio_signature_failed_thrice)` | DENY 67 % |
| G5 standing | both false | same | PERMIT 100 % |

Three things the measurement decided:

1. **State is keyed on `valid`, never on `confidence`.** A clean refusal of a conjunction
   of obligations comes back at 60–80 % (the engines that ran disagree on the refusal).
   `confidence` is reported on every line (contract §8) and decides nothing in W0.
2. **The bio-signature's strength is its own slot.** Contract v0 §4 says the DEGRADED rule
   applies when the verdict's confidence falls below the scheme's threshold; that
   sentence conflates URGE's engine agreement with the verifier's score. `bio_signature_strong`
   carries the verifier's threshold as a boolean, and the correction is made in
   contract v1.
3. **A gate combines a prefix operator with `and` only.** URGE 0.1 reads `or`, `implies`,
   `iff` and `xor` as `and` when a prefix operator is present (`always a implies b`
   evaluates as `G(a) ∧ b`). The session's standing rule is therefore written
   as G5's two obligations, not as an implication.

`must_not` prints as `F(…)`, the same letter URGE prints for `eventually`;
the expression beside the notation is what a reader re-runs.

## 5. Topics and records

| Step | `security` | `control` | `heartbeat` | Curator's record |
|---|---|---|---|---|
| S1–S3 | every verdict, every refusal | Oonia's route of the sign-on | | the session record opens at S4 with the G1–G3 verdict ids and trace hashes |
| S4–S5 | | the status lines | | the record itself; Hermes's sentence |
| H1–H3 | every state change with its verdict | | one message per state change, never per datagram | state, `t`, verdict id, trace hash; TERMINATED closes the record |

The trace is stored once, by Curator, and referred to by `sha256:` everywhere else
(status-line §2); scheme 0's `F(disable_logging)` is what makes S4 and every H-row
record unconditional.

## 6. What the device does alone

When the link is down the device keeps itself safe without the portal: the NOEVO shadow
of the Security Agent. W0 says only what the shadow must not do: it does not
mint a session, it does not answer `authorize0`, and it does not show a ✓ it did not
receive on stream 0. What it may do alone (hold the head, keep sensing, buffer stream-1
frames) is the device's interface document, held by the physical half of the sensor head.

## 7. Conformance

A portal or a device claims W0 when all of these hold, each measurable from the outside:

| | Check | Measured by |
|---|---|---|
| C1 | every step in §3 emits its status line with `rung: "W0"` and the named `step` | the ledger view of stream 0 |
| C2 | every Janus line carries a verdict whose `expr` is one of G1–G5 and whose `valid` matches URGE's evaluation of that `expr` over the slots Curator recorded | re-running the `expr` through URGE (the reader's right, status-line §2) |
| C3 | every trace hash on a line resolves in Curator's record | Curator's ledger |
| C4 | no EVO line appears in W0 | the ledger view: `class` is `noevo` on every W0 line |
| C5 | the refusal codes of §3 and the state rules of §4 are the contract's | `bin/check.mjs` (`igent` repository) on the fixtures |
| C6 | the six W0 lines of `ladder.json` (`identities` repository) are a subset of §3's lines and its two gates are G1 and G2's ancestors | reading; the ladder's `handshake` gate (`must tls_established and must device_registered`) folds into G1 + G2 and the demonstration is updated when this document is adopted |

## 8. Status

A design. The portal that runs it and the devices it admits are procurement in process.
