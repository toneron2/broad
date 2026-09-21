# Governance and BROAD: how they meet

**The governance layer (ESN in the 2025 documents; URGE at the portal in the 2026
architecture) stands between every requester and every BROAD operation.** Nothing reads or
writes clinical data, runs a workflow or calls an MCP tool without a verdict, and every
verdict carries its reasoning.

## What the governance layer supplies

| Component | Function in BROAD |
|---|---|
| Access agent | evaluates every FHIR read and write, every workflow trigger, every MCP call; enforces de-identification and minimum-necessary access before transmission |
| Logic engine | the evaluation itself, across several formal logics at once; the same engine serves clinical decision support and compliance rules |
| Continuous bio-authentication | provider identity verified throughout a session (fingerprint, voice, behaviour), not once at login |
| Reasoning traces | every decision logged with its derivation: the audit record HIPAA asks for |
| Heartbeat | the session between an edge device and the platform; carries authentication state; a lost heartbeat ends the session |

## How a request is evaluated

```
 request ── access agent ── logic engine ─┬─ temporal    within the allowed window?
                                          ├─ deontic     obligated, permitted, prohibited?
                                          ├─ modal       necessary or possible in this context?
                                          └─ fuzzy / probabilistic   degree of risk, confidence
                                    verdict: ALLOW or DENY, with the trace
                                    ALLOW ─▶ the BROAD workflow runs
                                    DENY  ─▶ logged; requester and compliance officer notified
```

Examples of the rules, in the logics that state them:

| Logic | Rule |
|---|---|
| Temporal | lab results accessible for 90 days after the test; medication orders reviewed within 4 hours |
| Deontic | providers are obligated to review critical lab alerts within 1 hour; nurses are permitted assigned patients' records and prohibited others' |
| Modal | a valid prescription is necessary before administration; an interaction warning may be overridden with attestation |
| Fuzzy | patient risk "moderately high" (0.7); a lab value "slightly elevated" (0.4) |
| Probabilistic | 75 % likelihood of readmission within 30 days |

## Integration points

| Point | Without governance | With governance |
|---|---|---|
| FHIR sync (n8n) | an ERPNext update is sent to the FHIR server unconditionally | the access agent checks that the server is authorised, whether de-identification is required, whether transmission is necessary; the workflow runs with transformations and a trace |
| UDS+ reporting | a monthly job collects and submits | temporal (the reporting window), deontic (obligated as an FQHC), modal (HRSA endpoint reachable); tables 6A/6B collected, Safe Harbor de-identification, FHIR bundle submitted, every step logged |
| Medication administration (GS1) | barcode lookup | the five rights checked as rules: patient, drug, dose (fuzzy: "slightly high" flags), route, time (temporal); drug-interaction and allergy risk as probabilities; ALLOW with a warning where warranted |
| MCP tool call | the tool executes | who is calling, what they deploy, whether they are permitted, whether the time is appropriate; then the tool executes with a trace |

## Privacy before transmission

```python
# ungoverned: PHI leaves as soon as it is fetched
send_to_fhir_server(get_patient(patient_id))

# governed: the agent decides what may leave, in what form
verdict = access_agent.evaluate(action="send_fhir", resource=patient, destination=server)
if verdict.allow:
    send_to_fhir_server(verdict.transform(patient))   # de-identified where required
audit.log(verdict.trace)
```

## Deployment shape

```
 edge device (Orange Pi 5, then Pixel)         local agent (1–3 B parameter model) · access agent · sensors
        │  WebTransport / QUIC, heartbeat under 10 ms
 platform (GKE in 2025; Cloud Run in 2026)     ERPNext · n8n · workflow library · MCP servers · observability
```

The edge half decides without the network where it can and syncs when connected. The 2026
architecture keeps this shape and names the pieces: the device is an igent, the platform
endpoint is igent.me, and the engine at the portal is URGE.

## One scenario

A federally qualified health centre with ten providers and a thousand patients. BROAD
supplies patient records, encounters and billing in ERPNext, the admission, medication and
lab pathways, FHIR exchange and UDS+ reporting. The governance layer adds governed FHIR
exchange, bio-authentication in place of passwords, minimum-necessary access enforced by
rule, reconciliation and documentation obligations stated formally, and a trace for every
decision.
