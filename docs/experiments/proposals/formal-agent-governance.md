---
summary: "Proposal: formal logic-based governance for agent and skill runtime behavior"
read_when:
  - Designing agent trust boundaries and runtime constraints
  - Exploring formal safety guarantees for skill execution
  - Considering structured governance beyond manual review
title: "Formal Agent Governance"
---

# Formal Agent Governance (Proposal)

This document proposes a **formal logic-based governance layer** for OpenClaw's
agent and skill runtime. It is an exploration, not a shipping spec. For current
agent behavior, see:

- [Agent Guidelines](/reference/agent-guidelines)
- [Skills Architecture](/concepts/skills)
- [Gateway Security](/gateway/security)

## Motivation

OpenClaw's agent ecosystem is growing fast. Skills execute arbitrary code,
agents make decisions across 30+ channels, and the Gateway orchestrates it all.
Today, safety relies on:

1. **Manual review** (PR workflow, maintainer judgment)
2. **Static policy** (Agent Submission Control Policy, install gating)
3. **Runtime trust** (once installed, a skill runs with full agent permissions)

This works at current scale but leaves gaps:

- **No runtime constraints**: A skill that passes review can still misbehave at
  runtime (network calls it shouldn't make, data access beyond its scope).
- **No formal safety guarantees**: Trust is binary (installed or not). There's no
  spectrum of "this skill can do X but not Y at runtime."
- **No auditable reasoning**: When the Gateway makes a routing decision, there's
  no formal trace explaining *why* that path was chosen.
- **Skill composition risk**: As skills compose (one skill calling another),
  trust boundaries blur without formal constraints.

## Prior art

### OpenClaw's existing governance

OpenClaw already has strong governance instincts:

- **Agent Submission Control Policy**: Quota limits, de-duplication, anti-spam,
  mandatory signoff. This is deontic logic expressed in natural language
  ("MUST", "MUST NOT", "MAY").
- **Install gating**: Skills require explicit user consent. This is a permission
  check, but only at install time.
- **Gateway as control plane**: All sessions, channels, tools, and events flow
  through the Gateway. This is architecturally identical to a governance
  checkpoint.

### ESN governance model (BROAD platform)

The ESN (Emergent Synergy Nexus) governance layer, developed for the BROAD
enterprise platform, provides a formal logic framework for agent governance:

- **Multi-paradigm logic engine**: Evaluates constraints using deontic
  (obligation/permission/forbidden), modal (possibility/necessity), and temporal
  (time-bounded) logic. Paradigm detection via regex runs in <5ms.
- **EVO/NOEVO classification**: Agents classified by evolution capability.
  NOEVO agents are fixed and verified (shields). EVO agents adapt within
  formal bounds (bounded learning).
- **Guardrails schemes**: Four tiers of constraint (Scheme 0-3), from absolute
  prohibitions to bounded creative freedom.
- **Access Agent pattern**: Every resource access flows through a single
  governance checkpoint with triple verification.

Research basis: Runtime Verification (MonPoly, Lola), Safe RL shielding
(Alshiekh et al. 2018), Constrained Policy Optimization (Achiam et al. 2017),
Options Framework (Sutton 1999).

## Proposed direction

### 1. Skill capability manifests

Every skill declares what it needs and what it must never do:

```yaml
# skill.yaml (extended)
name: "notion-sync"
version: "1.0.0"

capabilities:
  network:
    - domain: "api.notion.so"
      methods: ["GET", "POST", "PATCH"]
    - domain: "*.notion.so"
      methods: ["GET"]
  filesystem:
    read: ["workspace/**"]
    write: ["workspace/.notion-cache/**"]
  memory:
    read: true
    write: false

constraints:
  max_network_calls_per_invocation: 50
  max_execution_time_ms: 30000
  data_classification: "user-content"
  prohibited:
    - "credential_access"
    - "skill_installation"
    - "gateway_config_mutation"
```

**Why**: Makes trust boundaries explicit and machine-readable. The Gateway can
enforce these at runtime, not just at review time.

### 2. Deontic constraints for the Gateway

Express existing policies as formal logic the Gateway can evaluate:

```
# Current natural language policy → formal constraint
"Skills MUST NOT access credentials"
  → F(credential_access) for all skills

"Skills MAY read memory if user consents"
  → P(memory_read) ← user_consent ∧ skill_manifest_declares(memory_read)

"Gateway MUST log all tool executions"
  → O(audit_log) for all tool_execution events

"Skills MUST NOT call other skills without declaration"
  → F(skill_invoke(X)) ← ¬manifest_declares(skill_invoke(X))
```

**Notation**: O = obligated, P = permitted, F = forbidden. These map directly
to OpenClaw's existing "MUST/MUST NOT/MAY" language in the Agent Submission
Control Policy.

**Why**: Converts review-time policies into runtime-enforceable constraints.
A skill that tries to access credentials gets blocked immediately, with an
auditable reason.

### 3. Skill trust tiers (inspired by EVO/NOEVO)

Instead of binary installed/not-installed:

| Tier | Name | Can adapt? | Constraints | Example |
|------|------|------------|-------------|---------|
| 0 | **Core** | No | Built-in, verified, immutable | Gateway routing, auth |
| 1 | **Verified** | No | Manifest-locked, audited | Bundled skills (healthcheck, send) |
| 2 | **Managed** | Limited | Manifest-enforced, sandboxed | ClawHub published skills |
| 3 | **Workspace** | Yes | User-defined bounds, logged | User-created local skills |

**Mapping to ESN**: Tier 0-1 = NOEVO (shields), Tier 2-3 = EVO (bounded).
Core and Verified skills form a trusted base that constrains what Managed and
Workspace skills can do.

**Why**: A workspace skill the user wrote yesterday shouldn't have the same
implicit trust as the Gateway's auth system. Tiered trust makes this explicit.

### 4. Lightweight runtime governance hook

Add a governance checkpoint to the existing tool execution pipeline:

```typescript
// Conceptual — not a shipping API
interface GovernanceCheck {
  skill: string;
  action: string;
  resource: string;
  context: SessionContext;
}

interface GovernanceDecision {
  allowed: boolean;
  reason: string;          // human-readable
  constraint_trace: string[]; // which rules applied
  tier: SkillTier;
}

// In the Gateway's tool execution path:
async function executeToolCall(call: ToolCall, session: Session) {
  const decision = await governanceCheck({
    skill: call.skill,
    action: call.action,
    resource: call.resource,
    context: session.context,
  });

  if (!decision.allowed) {
    logger.warn("governance:denied", { decision });
    return denyWithReason(decision);
  }

  // Proceed with existing execution
  return executeTool(call);
}
```

**Key design constraint**: This must be fast. The ESN logic engine achieves
<50ms decisions through regex-based paradigm detection. For OpenClaw, the
initial implementation should target <10ms overhead by using pre-compiled
manifest lookups rather than runtime logic evaluation.

### 5. Audit trail for agent decisions

Every governance decision gets logged:

```json
{
  "timestamp": "2026-02-15T14:30:15.234Z",
  "session_id": "sess_abc123",
  "skill": "notion-sync",
  "action": "network_call",
  "resource": "api.notion.so/v1/pages",
  "decision": "allowed",
  "tier": 2,
  "constraints_checked": [
    "manifest.network includes api.notion.so: PASS",
    "method POST in allowed methods: PASS",
    "network_call_count 12 < limit 50: PASS"
  ],
  "latency_ms": 2.1
}
```

**Why**: When something goes wrong, operators can trace exactly what happened
and why. This is the foundation for trust in an AI assistant that runs on your
own devices.

## What this does NOT propose

- **No blockchain or DAO**: OpenClaw is BDFL-governed. This proposal strengthens
  that model with formal tools, it doesn't replace it.
- **No breaking changes**: Existing skills continue to work. Manifests are
  opt-in initially; unmanifested skills run at Tier 3 with default constraints.
- **No heavyweight runtime**: No separate logic engine process. Governance
  checks compile to fast lookups within the existing Gateway.
- **No LLM-in-the-loop governance**: Decisions are deterministic formal logic,
  not LLM judgment calls. This is critical for predictability and speed.

## Open questions

- Should capability manifests be required for ClawHub publication?
- How granular should network constraints be (domain-level vs endpoint-level)?
- Should governance decisions be surfaceable to the user in the Control UI?
- What's the migration path for existing skills without manifests?
- How should composed skill chains inherit or narrow constraints?
- Is `<10ms` overhead acceptable, or does this need to be `<1ms`?

## Implementation sketch

**Phase 0** (minimal, behind flag):
- Add optional `capabilities` and `constraints` fields to `skill.yaml` schema
- Gateway logs constraint violations but does not block (observation mode)
- Expose governance log in Control UI for operator visibility

**Phase 1** (enforcement):
- Gateway enforces manifest constraints at runtime
- ClawHub requires manifests for new skill submissions
- Skill composition inherits narrowest constraint set

**Phase 2** (formal logic):
- Replace lookup-based checks with lightweight deontic evaluator
- Support temporal constraints (rate limits, time-of-day restrictions)
- Enable operator-defined custom governance rules

## References

- [Agent Submission Control Policy](/.agents/AGENT_SUBMISSION_CONTROL_POLICY.md)
- [ESN Governance Layer](https://github.com/toneron2/broad/tree/main/governance-layer) — BROAD platform formal governance
- Alshiekh et al. "Safe Reinforcement Learning via Shielding" (2018) — NOEVO/shield foundation
- Achiam et al. "Constrained Policy Optimization" (2017) — EVO/bounded agent foundation
- Sutton et al. "Between MDPs and Semi-MDPs: Options Framework" (1999) — Agent hierarchy
- Bloem et al. "Shield Synthesis" (2015) — Formal safety guarantees
