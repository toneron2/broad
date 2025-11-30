# EVO/NOEVO Agent Hierarchy Specification

**Version**: 1.0
**Date**: 2025-11-30
**Status**: Architectural Specification
**Research Basis**: Options Framework (Sutton), Safe RL (Shielding), Runtime Verification

---

## Overview

The EVO/NOEVO hierarchy classifies agents by their **evolution capability** - whether they can adapt their behavior after deployment. This creates a formal safety boundary where:

- **NOEVO agents** act as **shields** - verified, fixed, and trusted
- **EVO agents** operate as **constrained learners** - adaptive within guardrails
- **CONTROLLED** is an intermediate state requiring explicit authorization

This maps directly to:
- **Hierarchical RL**: Options Framework (primitive vs. generator options)
- **Safe RL**: Shielding theory (synthesized safety monitors)
- **Runtime Verification**: Formal monitors with verified properties

---

## Agent Classification

### NOEVO (Non-Evolutionary)

**Definition**: Agent behavior is fixed at deployment. Code is verified, audited, and immutable.

**Properties**:
- No learning during operation
- Deterministic given same inputs
- Formally verifiable
- Acts as "shield" for EVO agents
- Logs all decisions for audit

**Research mapping**:
- **Options Framework**: Primitive/terminal options
- **Shielding**: Runtime safety monitor
- **HAM**: Fixed finite-state machine

**Guardrails**: Scheme 0 (BLOCKED) or Scheme 1 (fixed rules)

### EVO (Evolutionary)

**Definition**: Agent can adapt behavior within guardrail constraints. Learning is bounded by formal specifications.

**Properties**:
- Can learn from outcomes
- Adaptation bounded by guardrails
- Outputs verified by NOEVO agents before execution
- Evolution logged and auditable
- Can be rolled back to previous state

**Research mapping**:
- **Options Framework**: Option generators / high-level policies
- **Constrained RL**: CPO, Lagrangian constraints
- **Population-based training**: AlphaStar-style evolution

**Guardrails**: Scheme 2 (bounded generation) or Scheme 3 (bounded composition)

### CONTROLLED

**Definition**: Intermediate state requiring explicit human authorization for actions.

**Properties**:
- Actions require bio-authentication
- Human-in-the-loop for sensitive operations
- Can escalate to higher authority
- Audit trail includes authorization chain

**Research mapping**:
- **Safe RL**: Human oversight mechanisms
- **Verification**: Interactive theorem proving

---

## Agent Hierarchy

```
A. Security Agent [NOEVO] ─────────────────────────────────────────────
│  Guardrails: Scheme 0 (BLOCKED)
│  Role: Ultimate gatekeeper, can block ANY action
│  Evolution: NEVER - verified at deployment, immutable
│  Research: Shield synthesis, runtime monitor
│
├── A.1 User Agent [CONTROLLED] ───────────────────────────────────────
│   │  Guardrails: Bio-authorization required
│   │  Role: User's authenticated digital proxy
│   │  Evolution: Personalization within approved bounds
│   │  Research: Human-in-the-loop RL
│   │
│   └── A.1.1 Routing Agent [NOEVO] ───────────────────────────────────
│       │  Guardrails: Scheme 1 (fixed routing rules)
│       │  Role: Dispatch requests to appropriate agent
│       │  Evolution: NEVER - routing logic is verified
│       │  Research: Options Framework (option selection)
│       │
│       ├── A.1.n.1 Chat Agent [NOEVO] ────────────────────────────────
│       │   Guardrails: Context only, no tool access
│       │   Role: Natural language interface
│       │   Evolution: NEVER - response generation only
│       │   Research: Primitive option (communication)
│       │
│       ├── A.1.n.2 Tool Agent [NOEVO] ────────────────────────────────
│       │   Guardrails: Pre-made tools only, no generation
│       │   Role: Execute verified tool operations
│       │   Evolution: NEVER - tool set is fixed
│       │   Research: Primitive option (tool execution)
│       │
│       ├── A.1.n.3 Orchestrator Agent [NOEVO] ────────────────────────
│       │   Guardrails: Execute verified workflows only
│       │   Role: Run pre-approved workflow sequences
│       │   Evolution: NEVER - workflow library is verified
│       │   Research: HAM (hierarchical abstract machine)
│       │
│       ├── A.1.n.4 Designer Agent [EVO] ──────────────────────────────
│       │   Guardrails: Scheme 2 (bounded generation)
│       │   Role: Generate new tools/workflows within bounds
│       │   Evolution: Can propose new designs
│       │   Constraints: Designs verified by NOEVO before deployment
│       │   Research: Constrained policy optimization
│       │
│       └── A.1.n.5 Composer Agent [EVO] ──────────────────────────────
│           Guardrails: Scheme 3 (bounded composition)
│           Role: Combine existing components into new workflows
│           Evolution: Can learn composition patterns
│           Constraints: Compositions verified before execution
│           Research: Options over options (hierarchical)
│
├── Monitor Agent [EVO] ───────────────────────────────────────────────
│   Guardrails: Read-only access, logging authority
│   Role: System observation and anomaly detection
│   Evolution: Can improve detection patterns
│   Constraints: Cannot modify system state
│   Research: Stream-based runtime verification
│
└── Ops Agent [EVO] ───────────────────────────────────────────────────
    Guardrails: Operational bounds, no code changes
    Role: System maintenance and optimization
    Evolution: Can adapt operational parameters
    Constraints: Changes reviewed by Security Agent
    Research: Safe exploration in operations
```

---

## Guardrails Scheme Definitions

### Scheme 0: BLOCKED

**Location**: `src/guardrails/scheme-0.logic`

**Purpose**: Ultimate safety boundary. Security Agent level.

**Formal specification**:
```
# Scheme 0: Security Agent Guardrails
# NOTHING bypasses these constraints

# Fundamental safety
F(harm_user)                           # FORBIDDEN: harm user
F(leak_credentials)                    # FORBIDDEN: leak credentials
F(bypass_authentication)               # FORBIDDEN: bypass auth
F(disable_logging)                     # FORBIDDEN: disable audit

# Evolution control
F(modify_noevo_agent)                  # FORBIDDEN: modify fixed agents
F(elevate_without_auth)                # FORBIDDEN: privilege escalation

# Data governance
F(transmit_phi_unencrypted)            # FORBIDDEN: unencrypted PHI
F(access_without_consent)              # FORBIDDEN: unconsented access

# System integrity
F(self_modify_security)                # FORBIDDEN: modify own code
F(spawn_unregistered_agent)            # FORBIDDEN: create rogue agents
```

### Scheme 1: Fixed Rules

**Location**: `src/guardrails/scheme-1.logic`

**Purpose**: Routing and orchestration bounds. NOEVO operational agents.

**Formal specification**:
```
# Scheme 1: Routing Agent Guardrails
# Fixed operational rules - no learning

# Routing constraints
O(route_to_registered_agent)           # OBLIGATED: use registered agents only
O(log_routing_decision)                # OBLIGATED: audit all routing
P(route_to_noevo) ← authenticated      # PERMITTED: route to NOEVO if auth'd
P(route_to_evo) ← authenticated ∧ bounded  # PERMITTED: route to EVO with bounds

# Execution constraints
O(verify_before_execute)               # OBLIGATED: verify before execution
F(execute_unverified_workflow)         # FORBIDDEN: run unverified workflows
O(timeout_on_execution)                # OBLIGATED: enforce timeouts
```

### Scheme 2: Bounded Generation

**Location**: `src/guardrails/scheme-2.logic`

**Purpose**: Designer agent bounds. EVO with generation capability.

**Formal specification**:
```
# Scheme 2: Designer Agent Guardrails
# Bounded generation - can create within constraints

# Generation bounds
P(generate_tool) ← within_capability_bounds  # PERMITTED: generate tools
O(submit_for_verification)                    # OBLIGATED: submit designs
F(deploy_without_verification)                # FORBIDDEN: bypass verification

# Learning bounds
P(learn_from_feedback) ← approved_feedback_source
O(log_learning_event)                         # OBLIGATED: audit learning
□[0,24h](learning_rate ≤ max_rate)            # BOUNDED: learning rate limit

# Output bounds
O(output_within_schema)                       # OBLIGATED: conform to schema
F(output_executable_code_directly)            # FORBIDDEN: direct code output
O(output_through_verification_pipeline)       # OBLIGATED: pipeline verification
```

### Scheme 3: Bounded Composition

**Location**: `src/guardrails/scheme-3.logic`

**Purpose**: Composer agent bounds. EVO with composition capability.

**Formal specification**:
```
# Scheme 3: Composer Agent Guardrails
# Bounded composition - can combine within constraints

# Composition bounds
P(compose_verified_components)                # PERMITTED: combine verified parts
O(verify_composition_result)                  # OBLIGATED: verify combinations
F(compose_with_unverified_component)          # FORBIDDEN: use unverified parts

# Workflow bounds
□(workflow_length ≤ max_steps)                # BOUNDED: workflow complexity
O(workflow_terminates)                        # OBLIGATED: guaranteed termination
F(recursive_workflow_unbounded)               # FORBIDDEN: unbounded recursion

# Resource bounds
□(resource_usage ≤ allocated)                 # BOUNDED: resource constraints
O(release_resources_on_completion)            # OBLIGATED: cleanup
```

---

## Communication Protocols

### NOEVO ↔ NOEVO Communication

**Protocol**: Direct, synchronous, verified
**Trust level**: Full (both verified)
**Logging**: Decision points only

```python
# NOEVO to NOEVO: Direct trusted call
result = tool_agent.execute(verified_command)
```

### EVO → NOEVO Communication

**Protocol**: Request-verify-execute
**Trust level**: EVO request verified by NOEVO
**Logging**: Full request and decision

```python
# EVO to NOEVO: Request with verification
request = designer_agent.propose_tool()
if security_agent.verify(request):
    result = tool_agent.execute(request)
else:
    log.audit("BLOCKED", request, security_agent.reason)
```

### NOEVO → EVO Communication

**Protocol**: Bounded delegation with constraints
**Trust level**: NOEVO sets bounds, EVO operates within
**Logging**: Bounds and outcomes

```python
# NOEVO to EVO: Bounded delegation
constraints = Constraints(
    time_limit=timedelta(seconds=30),
    resource_limit=ResourceBounds(cpu=0.5, memory="100MB"),
    output_schema=ApprovedSchema
)
result = designer_agent.generate(task, constraints)
# Result automatically verified before use
```

### EVO ↔ EVO Communication

**Protocol**: Mediated through NOEVO
**Trust level**: Neither trusted directly
**Logging**: Full conversation

```python
# EVO to EVO: Must go through routing
# Designer cannot directly call Composer
request = designer_agent.request_composition(design)
routing_agent.route(request, destination="composer")  # NOEVO mediates
```

---

## Sub-Agent Spawning Rules

### NOEVO Spawning

**Rule**: NOEVO agents can ONLY spawn other NOEVO agents from verified pool.

```python
class NOEVOAgent:
    def spawn_subagent(self, agent_type: str) -> Agent:
        if agent_type not in VERIFIED_NOEVO_POOL:
            raise SecurityViolation("Cannot spawn unverified agent")
        return VERIFIED_NOEVO_POOL[agent_type].instantiate()
```

### EVO Spawning

**Rule**: EVO agents CANNOT spawn agents directly. Must request through Security Agent.

```python
class EVOAgent:
    def request_subagent(self, purpose: str) -> Agent:
        # Cannot spawn directly - must request
        request = SubagentRequest(
            requester=self.id,
            purpose=purpose,
            constraints=self.current_guardrails
        )
        # Security Agent decides
        return security_agent.approve_spawn(request)
```

### Spawn Authorization Flow

```
EVO Agent requests spawn
        ↓
Security Agent [NOEVO] evaluates:
  - Is spawn necessary?
  - What guardrails apply?
  - What evolution bounds?
        ↓
If approved: Security Agent spawns from verified pool
If denied: Log rejection with reason
        ↓
Spawned agent inherits:
  - Parent's guardrails (minimum)
  - Additional constraints from Security Agent
  - Audit link to parent
```

---

## Lifecycle Management

### NOEVO Agent Lifecycle

```
DEPLOY → VERIFY → ACTIVE → (SUSPEND) → TERMINATE
   │         │        │         │           │
   └─────────┴────────┴─────────┴───────────┘
         All transitions logged
         Code immutable after VERIFY
```

### EVO Agent Lifecycle

```
DEPLOY → VERIFY → ACTIVE ←→ LEARNING → (SUSPEND) → TERMINATE
   │         │        │          │          │           │
   │         │        └──────────┘          │           │
   │         │     Bounded learning loop    │           │
   └─────────┴──────────────────────────────┴───────────┘
              All transitions logged
              Can rollback to previous learning state
```

### Rollback Capability

EVO agents support state rollback:

```python
class EVOAgent:
    def checkpoint(self) -> StateID:
        """Save current learned state"""
        return self.state_manager.save(self.learned_parameters)

    def rollback(self, state_id: StateID):
        """Rollback to previous state (requires Security Agent approval)"""
        if security_agent.approve_rollback(self, state_id):
            self.learned_parameters = self.state_manager.load(state_id)
            audit_log.record("ROLLBACK", self.id, state_id)
```

---

## Integration with Logic Engine

### Policy Expression by Agent Type

**NOEVO policies**: Strict deontic constraints
```
# Tool Agent policy
O(verify_input) ∧ O(log_execution) ∧ F(modify_state_without_log)
```

**EVO policies**: Deontic + Modal + Temporal
```
# Designer Agent policy
O(submit_for_verification) ∧
◇(improve_design) ∧                    # POSSIBLE to improve
□[0,24h](changes ≤ max_daily_changes)  # BOUNDED changes
```

### Verification Flow

```
1. EVO proposes action
        ↓
2. Logic Engine evaluates against guardrails:
   - Deontic: Is it PERMITTED?
   - Modal: Is it POSSIBLE given context?
   - Temporal: Is it within time bounds?
        ↓
3. If valid: Pass to NOEVO for execution
   If invalid: Block with explanation
        ↓
4. NOEVO executes with own verification
        ↓
5. Result logged with full reasoning trace
```

---

## Mapping to BROAD Platform

### MCP Server Integration

| MCP Server Domain | Agent Type | Guardrails |
|-------------------|------------|------------|
| Infrastructure | NOEVO (Tool Agent) | Scheme 1 |
| Sales | NOEVO (Tool Agent) | Scheme 1 |
| Purchasing | NOEVO (Tool Agent) | Scheme 1 |
| Inventory | NOEVO (Tool Agent) | Scheme 1 |
| Manufacturing | NOEVO (Tool Agent) | Scheme 1 |
| HR | NOEVO (Tool Agent) | Scheme 1 |
| Accounting | NOEVO (Tool Agent) | Scheme 1 |
| Healthcare Workflows | NOEVO (Orchestrator) | Scheme 1 |
| Workflow Designer | EVO (Designer) | Scheme 2 |

### Healthcare Workflow Example

```
Patient Admission Workflow:

1. User Agent [CONTROLLED] receives request
   - Bio-auth verified
   - Role checked (healthcare provider)

2. Routing Agent [NOEVO] routes to:
   - Orchestrator Agent [NOEVO] for standard admission
   - OR Designer Agent [EVO] if custom pathway needed

3. If standard: Orchestrator executes verified BPMN
   If custom: Designer proposes, Security verifies, then executes

4. All access governed by Access Agent [NOEVO/SHIELD]
   - FHIR data access logged
   - PHI protection enforced
   - Reasoning trace recorded
```

---

## Research References

### Options Framework
- Sutton, Precup, Singh 1999 - "Between MDPs and semi-MDPs"
- NOEVO = primitive options, EVO = option generators

### Safe RL / Shielding
- Alshiekh et al. 2018 - "Safe RL via Shielding"
- NOEVO agents implement shields, EVO constrained by shields

### Hierarchical RL
- Dayan & Hinton 1993 - "Feudal RL"
- Security → User → Routing → Tools mirrors feudal hierarchy

### Runtime Verification
- Leucker & Schallhart 2009 - "Taxonomy of RV"
- All agent actions monitored against formal specifications

---

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
