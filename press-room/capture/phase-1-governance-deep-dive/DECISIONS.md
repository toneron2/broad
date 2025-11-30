# Phase 1: Governance Deep-Dive - Key Decisions

**Document Purpose**: Record WHY decisions were made during the governance deep-dive.

---

## Decision 1: Guardrails as Formal Logic Files

**Date**: November 30, 2025

### Context

Need to enforce constraints from the guardrails schemes (0-3). Options:
1. Hardcode constraints in Python
2. Parse .logic files at runtime
3. Use a rules engine (Drools, etc.)

### Decision

**Parse .logic files at runtime using regex patterns**

### Rationale

| Approach | Pros | Cons |
|----------|------|------|
| Hardcoded | Fast | Can't update without code change |
| **Parse .logic** | **Auditable, single source of truth** | **Slightly more complex** |
| Rules engine | Powerful | Heavy dependency |

The .logic files are already written in formal logic notation. Parsing them means:
- Single source of truth for guardrails
- Changes to .logic files automatically reflected
- Formal logic is auditable and verifiable

### Implementation

`guardrails_loader.py` uses patterns:
```python
# F(action), O(action), P(action)
deontic_pattern = r'^([FOPfop])\(([^)]+)\)(?:\s*←\s*(.+))?$'
# □[bounds](expression)
temporal_pattern = r'^□(?:\[([^\]]+)\])?\((.+)\)$'
```

---

## Decision 2: Gateway Pattern for Unified Governance

**Date**: November 30, 2025

### Context

Multiple governance components exist:
- Guardrails Enforcer
- Access Agent (Logic Engine)
- Heartbeat Manager

How should they be coordinated?

### Decision

**Single GovernanceGateway class orchestrating all components**

### Rationale

```
                    GovernanceGateway
                          │
        ┌─────────────────┼─────────────────┐
        ↓                 ↓                 ↓
   Guardrails        Access Agent       Heartbeat
   Enforcer         (Logic Engine)       Manager
```

Benefits:
- Single entry point for all governance
- Consistent audit logging
- Clear sequencing (session → guardrails → logic)
- Easy to test in isolation

### Implementation

```python
class GovernanceGateway:
    async def check_access(self, session_id, agent_name, resource, action, context):
        # 1. Session check
        # 2. Guardrails check
        # 3. Logic Engine check
        # 4. Return comprehensive decision
```

---

## Decision 3: EVO/NOEVO Communication Enforcement

**Date**: November 30, 2025

### Context

The EVO/NOEVO model specifies:
- EVO→EVO: Must route through NOEVO
- NOEVO→NOEVO: Direct trusted

Should this be enforced in code?

### Decision

**Yes - enforce at gateway level**

### Rationale

This is a fundamental safety property. If EVO agents could communicate directly, they could potentially evolve together in unexpected ways.

By forcing EVO→EVO through NOEVO:
- NOEVO acts as a verification checkpoint
- All EVO outputs are checked before reaching another EVO
- Audit trail is maintained

### Implementation

```python
def check_evo_noevo_permission(self, requesting_agent, target_agent, action):
    req_type = self.enforcer.get_agent_type(requesting_agent)
    tgt_type = self.enforcer.get_agent_type(target_agent)

    # EVO → EVO: BLOCKED
    if req_type == AgentType.EVO and tgt_type == AgentType.EVO:
        return False, "EVO→EVO: Must route through NOEVO mediator"
```

---

## Decision 4: Decorator-Based MCP Tool Protection

**Date**: November 30, 2025

### Context

MCP tools need governance. How should protection be applied?

Options:
1. Manual check in every tool
2. Middleware/interceptor
3. Decorator pattern

### Decision

**Decorator pattern (`@governed_mcp_tool`)**

### Rationale

Decorators are:
- Pythonic and familiar
- Self-documenting (visible at function definition)
- Easy to test
- Non-invasive to tool logic

### Implementation

```python
@governed_mcp_tool("healthcare", "read_patient")
async def read_patient(patient_id: str):
    # Only executes if access is granted
    ...
```

The decorator:
1. Extracts context from kwargs
2. Calls GovernanceGateway.check_access()
3. Raises PermissionError if denied
4. Proceeds with tool execution if allowed

---

## Decision 5: Comprehensive Test Suite

**Date**: November 30, 2025

### Context

Governance is critical. How do we ensure it works?

### Decision

**57 automated tests covering all aspects**

### Categories

| Category | Tests | Purpose |
|----------|-------|---------|
| Guardrails | 44 | All forbidden actions blocked |
| Classification | 8 | EVO/NOEVO detection |
| Logic Engine | 5 | Policy generation |
| EVO/NOEVO | 4 | Communication rules |
| Complete Flow | 4 | End-to-end governance |

### Rationale

Governance must be provable. The test suite:
- Can run in CI/CD
- Catches regressions
- Documents expected behavior
- Provides demo material

---

## Decisions NOT Made (Deferred)

| Topic | Why Deferred | When to Decide |
|-------|--------------|----------------|
| Compiled Logic Engine | Requires optimization work | Phase 3+ |
| Dynamic guardrails reload | Low priority, restart is acceptable | Phase 4+ |
| Distributed governance | Single-node sufficient for MVP | Phase 5+ |

---

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
