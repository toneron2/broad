# W1 — Sensing the locale, as a governed workflow

**Date:** 2026-09-21 · **Status:** design; procurement in process · **Rung:** W1 of the ladder W0–W3 · **Depends on:** `W0-heartbeat-establishment.md` (a session)

**One sentence.** W1 admits the devices where the person is, records what they read as
FHIR `Observation`s under a verdict each, raises a threshold event by a declared rule, and
routes it to the head's articulation or the drone's navigation, each move a gate Janus
decides with URGE; still the NOEVO identities only, no model anywhere.

The scope: the head's own sensors and any patient-monitoring device
where the person is, at home in the bedroom or on the couch, mounted to a wheelchair (the
wheelchair buddy), or at the desk in a ward room: patient monitors, blood pressure, room
air quality, noise, visual detection, with feedback to articulate the neck or navigate the
silent drone. Nothing in this document runs; the demonstration beside the status line
(`ladder.json` (`identities` repository)) carries seven W1 events and three gates that fold into
G6, G8 and G9 below.

## 1. Inputs, by hash

| Input | What W1 takes from it |
|---|---|
| `W0-heartbeat-establishment.md` (this folder) | the session, `session_active`, the topics, Curator's record, the device's shadow, the three rulings of §4 |
| the igent.me contract (`contract.md`, `igent` repository) v0, `db87034e…` | §2 stream 1 (the igent's data, reliable, old frames dropped by the igent), stream 0 for articulation commands down; §5 `slew` and `hold` for the head; §8 the verdict |
| `status-line.md` (`identities` repository) v0, `89100188…` | §3 the verbs; §5 the W1 row |
| the `identities` repository's README | the W1 row: Curator records observations, Janus verifies each device and each read, Oonia routes a threshold event, Hermes reports; the standards named (FHIR R4 `Device`, `Observation`; the sensor payload envelope) |
| the sensor head's charter (`physicalized-agent` repository) | the software half: device, firmware, comms, the payload envelope; the articulation pathway to igent.me |
| FHIR R4 | `Device` (the register's row, `identifier`, `type`, `status`, `owner`); `Observation` (`status`, `category` vital-signs or environment, `code`, `subject`, `effectiveDateTime`, `device`, `valueQuantity` or `component` for blood pressure); `Consent` (what may be observed and by what) |
| LOINC | blood pressure panel 85354-9 (systolic 8480-6, diastolic 8462-4); heart rate 8867-4; SpO2 59408-5; body temperature 8310-5; respiratory rate 9279-1. Room air and noise have no clinical LOINC and are `Observation`s with a local code system declared once |
| URGE 0.1.1, `1a33e2c6…` | every verdict in §4 was evaluated through it on 2026-09-21 |

## 2. Who does what

| Identity | In W1 |
|---|---|
| ⚖️ Janus | decides G6–G11: admits a device, admits each read, raises or refuses a threshold event, permits or refuses a move; publishes on `security` |
| 📚 Curator | records the `Device` row when admitted, one `Observation` per admitted read with the G7 verdict id, every threshold event and every move with its verdict; subscribes to `security`, `control` |
| 🐌 Oonia | routes: an admitted read to the threshold rules, a raised event to articulation (the head) or navigation (the drone), a refusal to Hermes; publishes on `control` |
| 📖 Hermes | one sentence per outcome the person should hear: a device not on the register, a reading that raised an event, a move made or refused |

Not an identity: the **threshold rules**, declared per person and per code (scheme 1,
fixed rules: `reading_outside_threshold` is true when the value falls outside the declared
band for that code), and the **device register** (the portal's, from W0, extended with a
row per locale device). No EVO identity runs in W1: Athena enters at W2.

## 3. The workflow

```
 device                                   portal
 ──────                                   ──────
 a locale device announces (stream 1) ──▶ D1 Janus verified device <id> ✓ / denied ✗ (G6)
                                          D2 Curator recorded Device <id>
                                          D3 Hermes says (on ✗ only)
 a read arrives (stream 1) ─────────────▶ R1 Janus verified read <code> ✓ / denied ✗ (G7)
                                          R2 Curator recorded Observation <code> <value>
                                          R3 Oonia routed read to threshold rules
                                          T1 Janus verified threshold event ✓ / (no event) (G8)
                                          T2 Oonia routed threshold event to articulation | navigation
 ◀── slew / hold (stream 0) ──────────── M1 Janus verified articulation ✓ / denied ✗ (G9)
 ◀── route (stream 0, the drone) ──────── M1' Janus verified navigation ✓ / denied ✗ (G10)
                                          M2 Curator recorded move <what> <verdict>
                                          M3 Hermes says
```

| Step | Line on stream 0 | Gate | On ✓ | On ✗ |
|---|---|---|---|---|
| D1 | ⚖️ Janus verifying device `<id>` … → verified ✓ / denied ✗ | G6 | D2: the device is admitted for this session | D3: 📖 Hermes: *A sensor in the room is not on the register. Its readings are not being used.* Frames from it are dropped at the receiver (G11) |
| D2 | 📚 Curator recorded Device `<id>` | none | | |
| R1 | ⚖️ Janus verified read `<code>` ✓ / denied ✗ | G7 | R2, R3 | the read is not recorded as an `Observation`; Curator records the refusal from `security`; Hermes speaks only when the refusal is consent |
| R2 | 📚 Curator recorded Observation `<code> <value>` | none | | |
| R3 | 🐌 Oonia routed read to threshold rules | none | | |
| T1 | ⚖️ Janus verified threshold event ✓ | G8 | T2 | no line: a reading within its band raises nothing (the DENY is recorded, not shown) |
| T2 | 🐌 Oonia routed threshold event to articulation \| navigation | none | M1 or M1' | |
| M1 | ⚖️ Janus verified articulation `<command>` ✓ / denied ✗ | G9 | `slew` or `hold` down stream 0 to the head | the head holds; Hermes says why (privacy or hazard) |
| M1' | ⚖️ Janus verified navigation `<route>` ✓ / denied ✗ | G10 | the route to the drone | the drone holds; Hermes says why |
| M2 | 📚 Curator recorded move `<what>` | none | | |
| M3 | 📖 Hermes: *Your blood pressure is high. I have turned to you; please sit still for a second reading.* | none | | |

Every line carries `rung: "W1"` and the `step` above. The head's articulation is the
contract's `slew` and `hold` on stream 0; the drone's navigation is a route object on the
same stream, its shape the Silent Drone's charter to define.

## 4. The gates, as URGE evaluates them

| Gate | Expression | Slots and who measures them |
|---|---|---|
| G6 device admitted | `must device_registered and must device_class_known and must device_calibrated and must session_active` | `device_registered` the register (a row for this device id, bound to this person's locale) · `device_class_known` the register (the class has a FHIR `Device.type` and a code set) · `device_calibrated` the register (calibration date within the class's interval) · `session_active` W0 |
| G7 read admitted | `must device_admitted and must observation_well_formed and must value_in_device_range and must consent_covers_observation` | `device_admitted` G6's verdict for this session · `observation_well_formed` the receiver (the frame maps to an `Observation` with code, value, unit, time) · `value_in_device_range` the class's declared range (a reading outside what the device can measure is a fault, not a finding) · `consent_covers_observation` the `Consent` on record for this code and this device class |
| G8 threshold event | `must threshold_rule_declared and must observation_recorded and must reading_outside_threshold` | `threshold_rule_declared` the rules (a band for this person and code) · `observation_recorded` Curator (R2 done) · `reading_outside_threshold` the rules |
| G9 articulation | `must session_active and must person_present and must command_in_envelope and must_not privacy_mode and must_not hazard_flag` | `person_present` the head's presence sensing · `command_in_envelope` the head's mechanical envelope (ID's: joint limits, rate) · `privacy_mode` the person's switch, on the device · `hazard_flag` the head's own shadow (an obstruction, a fault, a temperature) |
| G10 navigation | `must session_active and must route_known and must_not room_occupied_by_other and must_not hazard_flag` | `route_known` the drone's map · `room_occupied_by_other` the ward's presence rule · `hazard_flag` the drone's shadow |
| G11 standing | `always frames_from_admitted_devices` | the stream-1 receiver: every frame carries an admitted device id; evaluated at every D1 and on every dropped frame |

| Case | Slots changed | URGE notation | Verdict |
|---|---|---|---|
| G6 admitted | all true | `O(device_registered) ∧ O(device_class_known) ∧ O(device_calibrated) ∧ O(session_active)` | PERMIT 100 % |
| G6 refused, not on register | `device_registered=false` | same | DENY 57 % |
| G6 refused, calibration lapsed | `device_calibrated=false` | same | DENY 71 % |
| G7 recorded | all true | `O(device_admitted) ∧ O(observation_well_formed) ∧ O(value_in_device_range) ∧ O(consent_covers_observation)` | PERMIT 100 % |
| G7 refused, out of range | `value_in_device_range=false` | same | DENY 71 % |
| G7 refused, no consent | `consent_covers_observation=false` | same | DENY 71 % |
| G8 raised | all true | `O(threshold_rule_declared) ∧ O(observation_recorded) ∧ O(reading_outside_threshold)` | PERMIT 100 % |
| G8 within band | `reading_outside_threshold=false` | same | DENY 60 % |
| G9 permitted | `privacy_mode=false, hazard_flag=false` | `O(session_active) ∧ O(person_present) ∧ O(command_in_envelope) ∧ F(privacy_mode) ∧ F(hazard_flag)` | PERMIT 100 % |
| G9 refused, privacy | `privacy_mode=true` | same | DENY 78 % |
| G9 refused, hazard | `hazard_flag=true` | same | DENY 78 % |
| G10 permitted | both false | `O(session_active) ∧ O(route_known) ∧ F(room_occupied_by_other) ∧ F(hazard_flag)` | PERMIT 100 % |
| G10 refused, room occupied | `room_occupied_by_other=true` | same | DENY 71 % |
| G11 holds | true | `G(frames_from_admitted_devices)` | PERMIT 100 % |
| G11 broken | false | same | DENY 100 % |

D16 holds throughout: state on `valid`; every measured quantity a boolean slot with its
owner named (the band, the range, the envelope are the owners' thresholds, not URGE's);
prefix operators with `and` only. The DENY confidences run 57–78 % as in W0 and decide
nothing.

## 5. Records and topics

| Step | Curator records | `security` | `control` |
|---|---|---|---|
| D1–D2 | the FHIR `Device` row with the G6 verdict id and trace hash; a refusal with its verdict | the verdict | Oonia's route of the announce |
| R1–R3 | one `Observation` per admitted read: `status: final`, `category`, `code` (LOINC or the local system), `subject`, `effectiveDateTime` from the frame, `device` the admitted id, `valueQuantity` or `component`; the G7 verdict id in `meta` | the verdict | the route to the rules |
| T1–T2 | the threshold event: code, value, band, the G8 verdict id | the verdict | the route to articulation or navigation |
| M1–M3 | the move: command or route, the G9 or G10 verdict id, Hermes's sentence | the verdict | the status lines |

A read refused for consent is recorded as a refusal, never as an `Observation`: the
value does not enter the record. That is what `consent_covers_observation` is for.

## 6. The device's shadow

The head keeps its own G9 slots true without the portal: `person_present`,
`command_in_envelope`, `privacy_mode` and `hazard_flag` are measured on the device, and
the NOEVO shadow refuses a `slew` that would break the envelope or the privacy switch
even if one arrived with a ✓. It never raises a threshold event on its own and never
records an `Observation`: with the link down it buffers stream-1 frames (contract §2)
and the session's W0 rules apply. The drone's shadow is the same for G10.

## 7. Conformance

| | Check | Measured by |
|---|---|---|
| C7 | every admitted device has a D1 ✓ line and a Curator `Device` row before its first R1 | the ledger view |
| C8 | every `Observation` in Curator's record carries a G7 verdict id whose `expr` is G7's and whose `valid` re-evaluates true over the recorded slots | re-running through URGE |
| C9 | no `Observation` exists for a read whose consent slot was false | Curator's record against the refusals |
| C10 | every `slew`, `hold` or route on stream 0 follows an M1 or M1' ✓ line with a G9 or G10 verdict | the ledger view against the stream-0 capture |
| C11 | the stream-1 receiver drops every frame from a device with no D1 ✓ in this session (G11) | a frame from an unadmitted id, injected on the bench; the drop is counted |
| C12 | the seven W1 events of `ladder.json` (`identities` repository) are a subset of §3's lines; its gates `must device_registered and must device_calibrated` and `must reading_above_threshold and must person_present and must_not privacy_mode` fold into G6 and G9 | reading; the demonstration is updated when this document is adopted |
| C13 | no EVO line appears in W1 | `class` is `noevo` on every W1 line |

## 8. Status

A design. The portal that runs it and the devices it admits are procurement in process.
