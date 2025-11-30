# How BROAD Operates in Runtime

**A Story of Every Request, Every Decision, Every Trace**

This narrative explains WHAT the BROAD platform does - moment by moment, decision by decision - for audiences who want to understand the system in action.

---

## The Morning Shift Begins

**7:00 AM - Cardiology Department**

Dr. Sarah Chen arrives at work. She picks up her tablet - a Pixel device running the BROAD mobile interface.

### Step 1: Authentication

The tablet's fingerprint sensor activates. Her bio-signature (fingerprint + behavioral pattern) is captured.

```
┌─────────────────────────────────────────────┐
│  QUIC HEARTBEAT ESTABLISHED                 │
│  Device: pixel_cardio_07                    │
│  User: dr_chen (provider)                   │
│  Bio-auth: verified                         │
│  Session: active (10Hz heartbeat)           │
└─────────────────────────────────────────────┘
```

**What's happening under the hood**:
- Heartbeat protocol establishes continuous session
- Bio-signature carrier embedded in heartbeat packets
- Session valid as long as heartbeat continues
- Adaptive rate: 10Hz at rest, 50Hz during active use

### Step 2: First Request

Dr. Chen opens her patient list: "Show me today's cardiology patients."

```
REQUEST
  User: dr_chen
  Action: list_patients
  Filter: department=cardiology, date=today
  Context: role=provider, shift=07:00-15:00
```

### Step 3: Governance Check

The request flows through the Access Agent:

```
ACCESS AGENT evaluates:
  ┌─────────────────────────────────────────┐
  │  DEONTIC CHECK                          │
  │  Expression: P(list_patients) ←         │
  │              role=provider              │
  │  Result: PERMITTED                      │
  └─────────────────────────────────────────┘

  ┌─────────────────────────────────────────┐
  │  MODAL CHECK                            │
  │  Expression: ◇(access) ←                │
  │              session_valid              │
  │  Result: POSSIBLE                       │
  └─────────────────────────────────────────┘

  ┌─────────────────────────────────────────┐
  │  TEMPORAL CHECK                         │
  │  Expression: □[07:00,15:00](permitted)  │
  │  Result: WITHIN BOUNDS                  │
  └─────────────────────────────────────────┘

  DECISION: ALLOW (latency: 23ms)
```

### Step 4: Execution

The patient list is retrieved from ERPNext Healthcare via the Healthcare MCP Server:

```
MCP CALL: healthcare.list_patients
  Parameters: {department: "cardiology", date: "2025-11-30"}
  Governance: ALLOW (trace_id: 0x7f3a...)
  Result: 12 patients
```

### Step 5: Audit Trail

Every decision is logged with full reasoning:

```json
{
  "timestamp": "2025-11-30T07:00:23Z",
  "trace_id": "0x7f3a...",
  "user": "dr_chen",
  "action": "list_patients",
  "resource": "cardiology_patients",
  "checks": {
    "deontic": {"result": "PERMITTED", "reason": "role=provider"},
    "modal": {"result": "POSSIBLE", "reason": "session=active"},
    "temporal": {"result": "WITHIN_BOUNDS", "reason": "07:00 in [07:00,15:00]"}
  },
  "decision": "ALLOW",
  "latency_ms": 23
}
```

---

## A Sensitive Access

**7:15 AM - Patient Record View**

Dr. Chen selects patient James Wilson to review his cardiac history.

### The Request

```
REQUEST
  User: dr_chen
  Action: view_patient_record
  Resource: patient_wilson_12345
  Data: full_medical_record (PHI)
```

### Enhanced Governance

Because this involves Protected Health Information (PHI), additional checks apply:

```
SCHEME 0 CONSTRAINTS ACTIVE:
  F(transmit_phi_unencrypted)     ✓ Connection is TLS 1.3
  F(access_phi_without_audit)     ✓ Full audit trail
  O(log_all_decisions)            ✓ Reasoning trace recorded

ACCESS AGENT evaluates:
  Deontic: P(view_phi) ← role=provider ∧ care_relationship
           ✓ Dr. Chen is assigned cardiologist

  Modal:   ◇(access) ← session_valid ∧ device_compliant
           ✓ Session active, device encrypted

  Temporal: □[0,8h](session_valid)
           ✓ Within session duration limit

DECISION: ALLOW
```

### What the User Sees

Dr. Chen sees the patient record instantly. She doesn't notice the governance - it's invisible when working correctly.

### What the System Records

```json
{
  "timestamp": "2025-11-30T07:15:02Z",
  "phi_access": true,
  "hipaa_compliant": true,
  "user": "dr_chen",
  "patient": "wilson_12345",
  "justification": "assigned_cardiologist",
  "checks": ["deontic:PERMIT", "modal:POSSIBLE", "temporal:BOUNDED"],
  "decision": "ALLOW"
}
```

---

## A Denied Request

**10:30 AM - IT Department**

Mike from IT Support is troubleshooting a network issue. He tries to access a patient record to "verify connectivity."

### The Request

```
REQUEST
  User: mike_it
  Action: view_patient_record
  Resource: patient_wilson_12345
  Context: role=IT_admin (non-clinical)
```

### Governance Response

```
ACCESS AGENT evaluates:

  Deontic: P(view_phi) ← role ∈ clinical_roles
           ✗ IT_admin ∉ {provider, nurse, clinical_staff}

  EVALUATION STOPPED AT FIRST FAILURE

DECISION: DENY
REASON: "PHI access requires clinical role. IT_admin is not a clinical role."
```

### What Mike Sees

```
┌─────────────────────────────────────────────┐
│  ACCESS DENIED                              │
│                                             │
│  You do not have permission to view         │
│  patient records.                           │
│                                             │
│  Reason: PHI access requires clinical role  │
│                                             │
│  If you believe this is an error, contact   │
│  your supervisor or IT Security.            │
│                                             │
│  Reference: trace_id_0x8b2f...              │
└─────────────────────────────────────────────┘
```

### What the System Records

```json
{
  "timestamp": "2025-11-30T10:30:15Z",
  "phi_access_attempt": true,
  "user": "mike_it",
  "patient": "wilson_12345",
  "checks": {
    "deontic": {"result": "DENIED", "reason": "role=IT_admin not in clinical_roles"}
  },
  "decision": "DENY",
  "security_event": true
}
```

---

## An EVO Agent in Action

**11:00 AM - Workflow Design**

The Workflow Designer (an EVO agent) is asked to create a custom discharge pathway.

### The Request

```
AGENT REQUEST
  Agent: designer_001 [EVO]
  Action: generate_workflow
  Template: discharge_pathway
  Customization: cardiology_specific
```

### EVO-NOEVO Interaction

```
1. Designer [EVO] generates workflow proposal
   ├─ Reads existing templates (permitted by Scheme 2)
   ├─ Composes new pathway structure
   └─ Outputs: discharge_cardio_v1.bpmn

2. Routing [NOEVO] receives proposal
   └─ Forwards to Security for verification

3. Security [NOEVO] checks against Scheme 0 & 2:
   ├─ F(deploy_without_verification)        - Checked
   ├─ O(submit_for_verification)            - Satisfied
   ├─ P(generate_tool) ← within_bounds      - Satisfied
   └─ □(workflow_terminates)                - Verified

4. Decision: APPROVE for staging
   └─ Workflow deployed to test environment

5. Human Review Required:
   └─ Workflow awaits clinical approval before production
```

### The Key Insight

The Designer agent CREATED something new. But:
- Its output was verified by NOEVO agents
- It cannot deploy directly to production
- Human approval is still required for clinical workflows
- Full audit trail of generation process

**This is bounded autonomy** - capability within constraints.

---

## The Observability Layer

### What Appears in Grafana

**Real-Time Dashboard: Governance Decisions**

```
┌─────────────────────────────────────────────────────────────────┐
│  GOVERNANCE DECISIONS (Last 60 minutes)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Decisions:  1,247 total                                        │
│  Allowed:    1,231 (98.7%)    ████████████████████░             │
│  Denied:        16 (1.3%)     ░                                  │
│                                                                  │
│  Avg Latency: 24ms            ████████░░░░░░░░░░░░░ (target 50) │
│  P99 Latency: 47ms            ████████████████████░             │
│                                                                  │
│  PHI Access:    89 requests   (all compliant)                   │
│  EVO Actions:   12 proposals  (8 approved, 4 pending)           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Trace View: Single Request**

```
┌─────────────────────────────────────────────────────────────────┐
│  TRACE: 0x7f3a... (dr_chen → view_patient_record)               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  07:15:02.000  Request received                                 │
│       ├── 2ms   Heartbeat validated                             │
│       ├── 5ms   Paradigm detection (deontic + modal + temporal) │
│       ├── 8ms   Deontic evaluation                              │
│       ├── 4ms   Modal evaluation                                │
│       ├── 3ms   Temporal evaluation                             │
│       ├── 1ms   Decision rendered: ALLOW                        │
│       └── 23ms  Total governance latency                        │
│                                                                  │
│  07:15:02.023  MCP call: healthcare.get_patient                 │
│       └── 45ms  Data retrieved                                  │
│                                                                  │
│  07:15:02.068  Response delivered                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Differentiators

### Traditional ERP Access Control

```
IF user.role == "provider" AND resource.type == "patient":
    RETURN ALLOW
ELSE:
    RETURN DENY
```

**Problems**:
- No reasoning trace
- Static rules
- No context awareness
- Compliance is a checklist

### BROAD Formal Governance

```
P(access) ← (role ∈ clinical) ∧ ◇(session_valid) ∧ □[t₀,t₁](shift)
```

**Benefits**:
- Full reasoning trace
- Multi-paradigm composition
- Context-aware (time, session, relationships)
- Compliance is architectural

---

## Summary

| Question | Answer |
|----------|--------|
| Who accessed what? | Full audit trail with reasoning |
| Why was access allowed/denied? | Formal logic evaluation trace |
| How fast are decisions? | <50ms (typically 20-30ms) |
| Is it HIPAA compliant? | Yes - PHI governed by Scheme 0 |
| Can agents act autonomously? | Yes - within guardrail bounds |
| Can we see what's happening? | Yes - 100% observability |

**The system doesn't just work. It explains itself.**

---

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
