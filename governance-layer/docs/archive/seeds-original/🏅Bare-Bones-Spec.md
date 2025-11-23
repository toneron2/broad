# ESN Bare-Bones Infrastructure Specification
**Version:** 0.1  
**Date:** October 22, 2025  
**Status:** Foundation Document

---

## Purpose

This document defines the **absolute minimum infrastructure** required for the Emergent Synergy Nexus (ESN) to function. Everything described here must exist before higher-level features (discovery, orchestration, workflows) can be built.

**Core Question:** What is the minimum needed for a local device and cloud agent to be meaningfully aware of each other and capable of coordinated action?

**Philosophy:** Build from the outside-in. Define the boundaries (hardware, protocol, cloud) precisely so the undefined center (orchestration, discovery) has known constraints to work within.

---

## System Overview

ESN is a distributed nervous system where:
- **Local devices** have sensors, local compute, and context awareness
- **Cloud agents** have knowledge, compute resources, and orchestration capability
- **Continuous connection** maintains bidirectional awareness via ultra-low overhead heartbeat
- **Connection scaling** from minimal heartbeat to full bandwidth based on need

### Architectural Layers

```
┌─────────────────────────────────────────────────┐
│  USER INTERACTION (text, audio, video, sensors) │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│  LOCAL DEVICE (AOSP + Local LLM + Sensors)      │
│  - Sensor access (camera, mic, GPS, etc)        │
│  - Local LLM inference                           │
│  - MCP tool interface                            │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│  REASONING LAYER (Logic Engine Foundation)      │
│  - Access control (can I use this resource?)    │
│  - Resource allocation (local vs cloud?)        │
│  - Privacy enforcement (can data leave device?) │
│  - Tool selection (which tool for this goal?)   │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│  PROTOCOL LAYER (WebTransport/QUIC)             │
│  - Heartbeat: ~200 bytes, adaptive frequency    │
│  - Active streams: full MCP/A2A protocol         │
│  - State transitions: IDLE → ACTIVE → BURST     │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│  CLOUD AGENT (GCP + Device Twin + Tools)        │
│  - Device state model (real-time twin)          │
│  - Tool registry (APIs, services, resources)    │
│  - LLM inference (Anthropic, others)            │
│  - Workflow coordination                         │
│  - Reasoning layer (cloud-side decisions)       │
└─────────────────────────────────────────────────┘
```

---

## Core Components (What MUST Exist)

### 1. Local Device Stack

#### 1.1 Hardware Platform (Phase 1)
- **Device:** Google Pixel 10 (Tensor G5 chipset)
- **Rationale:** 
  - Native AOSP support
  - On-device ML acceleration
  - Known sensor suite
  - Developer-friendly bootloader

#### 1.2 Operating System
- **Base:** AOSP (Android Open Source Project)
- **Build Environment:** Android Studio on Ubuntu
- **Customizations:**
  - Minimal system services (no Google Play Services)
  - Direct HAL access for sensors
  - Custom init.rc for early boot agent launch
  - No traditional Android UI (custom interface layer)

#### 1.3 Local Agent Runtime
**Components:**
- **Local LLM:** Small language model (1-3B parameters)
  - Quantized for on-device inference
  - Tuned for sensor interpretation and user context
  - Gemini Nano initially, but architecture-agnostic
- **MCP Client:** Model Context Protocol implementation
  - Exposes local tools (sensors, device APIs)
  - Communicates with cloud MCP server
- **Sensor Manager:** 
  - Enumerates available sensors at boot
  - Provides unified API for sensor access
  - Handles permissions and privacy controls

**Responsibilities:**
- Maintain heartbeat connection to cloud
- Execute local inference when appropriate
- Handle offline degradation gracefully
- Manage sensor access and data flow
- Provide user interaction interface

#### 1.4 Sensor Framework
**Must Support:**
- Camera (still + video)
- Microphone (audio input)
- GPS/Location
- Accelerometer/Gyroscope
- Ambient light
- Connectivity state (WiFi, cellular, quality metrics)
- Battery state
- (Optional: Health sensors if available)

**API Surface:**
```
SensorCapabilities {
  device_id: UUID
  available_sensors: [SensorType]
  sensor_specs: { type: SensorType, capabilities: {} }
}

SensorAccess {
  request_access(sensor: SensorType, duration: Time)
  stream_data(sensor: SensorType, callback: fn)
  capture_once(sensor: SensorType) -> Data
}
```

---

#### 1.5 Reasoning Layer (Logic Engine Foundation)

**Purpose:** All access control, resource allocation, privacy enforcement, and orchestration decisions flow through a unified reasoning layer. This is the architectural manifestation of the Logic Engine patent and the governance foundation for the entire system.

**Critical Architectural Decision:** The Reasoning Layer is NOT an optional feature - it is the trust foundation that makes ESN suitable for vulnerable populations and mission-critical applications.

**Implementation Strategy:**
- **Phase 0 (Bare-Bones):** Simple rule-based reasoning that proves the interface
- **Phase 1 (Logic Engine):** Full multi-paradigm reasoning with Unicode Semantic Dictionary
- **Interface:** Identical across both phases - implementation complexity grows, architecture stays stable

##### Reasoning Layer Responsibilities

**1. Access Control**
- Determines whether a resource (sensor, tool, API) can be accessed
- Considers: permissions, context, time, user state, device state
- Returns: GRANTED, DENIED (with reason), or REQUIRE_CONFIRMATION

**2. Resource Allocation**
- Decides where computation should execute (local vs cloud vs hybrid)
- Considers: latency requirements, battery state, network quality, compute availability, cost
- Returns: Execution plan with reasoning trace

**3. Privacy Enforcement**
- Determines whether data can leave the device or move to specific destinations
- Considers: data classification, user consent, regulatory requirements, destination trust
- Returns: Privacy decision with enforced transformations (anonymization, encryption, etc.)

**4. Tool Selection**
- Chooses appropriate tools for a given goal
- Considers: available tools, context, constraints, past success/failure
- Returns: Ranked tool list with reasoning

##### Phase 0: Rule-Based Reasoning (Bare-Bones Implementation)

**Goal:** Prove the reasoning interface works with simple, deterministic logic.

**Implementation:**
```python
class ReasoningLayerPhase0:
    """
    Simple rule-based reasoning for Phase 0.
    
    All decisions are deterministic, traceable, and auditable.
    Interface is designed to support Phase 1 Logic Engine with no changes.
    """
    
    def check_access(self, 
                     resource: Resource, 
                     context: Context) -> AccessDecision:
        """
        Determine if access to resource is permitted.
        
        Phase 0: Simple if/then rules
        Phase 1: Temporal + Deontic + Modal logic
        
        Example rules:
        - Camera disabled if battery < 20%
        - GPS requires user permission
        - Microphone disabled 10 PM - 6 AM unless emergency
        - Sensors require user consent on first use
        """
        
        # Battery-based restrictions
        if resource.power_intensive and context.battery_percent < 20:
            return AccessDecision(
                status=AccessStatus.DENIED,
                reason="Battery too low for power-intensive resource",
                logic_trace=["battery_check: 15% < 20%"]
            )
        
        # Permission checks
        if not context.permissions.has(resource.permission_type):
            return AccessDecision(
                status=AccessStatus.DENIED,
                reason="Missing required permission",
                logic_trace=["permission_check: not granted"]
            )
        
        # Time-based restrictions (simple temporal logic)
        if resource.time_restricted:
            current_hour = context.time.hour
            if current_hour >= 22 or current_hour < 6:
                if not context.emergency_mode:
                    return AccessDecision(
                        status=AccessStatus.REQUIRE_CONFIRMATION,
                        reason="Resource typically restricted at night",
                        logic_trace=["time_check: 23:00 in restricted range"]
                    )
        
        # Privacy mode
        if context.privacy_mode_active and resource.data_sensitive:
            return AccessDecision(
                status=AccessStatus.DENIED,
                reason="Privacy mode active",
                logic_trace=["privacy_mode: active", "resource: sensitive"]
            )
        
        return AccessDecision(
            status=AccessStatus.GRANTED,
            logic_trace=["all_checks: passed"]
        )
    
    def allocate_compute(self, 
                         task: Task, 
                         context: Context) -> ComputeAllocation:
        """
        Decide where task should execute.
        
        Phase 0: Simple heuristics
        Phase 1: Fuzzy + Probabilistic reasoning
        
        Decision factors:
        - Task latency requirement
        - Network quality
        - Battery state
        - Local model capability
        - Cloud API cost
        """
        
        # High latency tolerance -> prefer cloud (better models)
        if task.latency_tolerance_ms > 1000:
            if context.network_quality >= NetworkQuality.GOOD:
                return ComputeAllocation(
                    location=ComputeLocation.CLOUD,
                    reason="High latency tolerance + good network",
                    logic_trace=["latency: 2000ms > 1000ms", "network: GOOD"]
                )
        
        # Low battery -> minimize local compute
        if context.battery_percent < 30:
            if task.compute_intensive:
                return ComputeAllocation(
                    location=ComputeLocation.CLOUD,
                    reason="Battery conservation mode",
                    logic_trace=["battery: 25% < 30%", "task: compute_intensive"]
                )
        
        # Poor network -> must use local if possible
        if context.network_quality <= NetworkQuality.POOR:
            if task.can_run_locally:
                return ComputeAllocation(
                    location=ComputeLocation.LOCAL,
                    reason="Network too poor for cloud",
                    logic_trace=["network: POOR", "local_capable: true"]
                )
            else:
                return ComputeAllocation(
                    location=ComputeLocation.DEFERRED,
                    reason="Cannot run locally, network insufficient",
                    logic_trace=["network: POOR", "local_capable: false"]
                )
        
        # Default: local for speed, cloud for quality
        if task.latency_critical:
            return ComputeAllocation(
                location=ComputeLocation.LOCAL,
                reason="Latency critical",
                logic_trace=["latency_critical: true"]
            )
        else:
            return ComputeAllocation(
                location=ComputeLocation.CLOUD,
                reason="Quality over speed",
                logic_trace=["default: cloud"]
            )
    
    def enforce_privacy(self, 
                        data: Data, 
                        destination: Destination) -> PrivacyDecision:
        """
        Determine if data can be sent to destination.
        
        Phase 0: Simple classification rules
        Phase 1: Deontic + Modal logic with consent models
        
        Data classifications:
        - PUBLIC: Can go anywhere
        - PERSONAL: Requires user consent
        - SENSITIVE: Strong encryption + trusted destinations only
        - PHI/PII: Regulatory compliance required
        """
        
        # PUBLIC data -> always allowed
        if data.classification == DataClass.PUBLIC:
            return PrivacyDecision(
                allowed=True,
                transformations=[],
                logic_trace=["classification: PUBLIC"]
            )
        
        # Check user consent
        if data.classification == DataClass.PERSONAL:
            if not context.user_consent.allows(data.type, destination):
                return PrivacyDecision(
                    allowed=False,
                    reason="User has not consented to this data sharing",
                    logic_trace=["consent_check: not granted"]
                )
        
        # SENSITIVE data -> encryption required
        if data.classification == DataClass.SENSITIVE:
            if not destination.trusted:
                return PrivacyDecision(
                    allowed=False,
                    reason="Destination not trusted for sensitive data",
                    logic_trace=["destination: untrusted"]
                )
            
            return PrivacyDecision(
                allowed=True,
                transformations=[Transform.ENCRYPT_AES256],
                logic_trace=["sensitive: encrypt", "destination: trusted"]
            )
        
        # PHI/PII -> strict compliance
        if data.classification in [DataClass.PHI, DataClass.PII]:
            if not destination.compliance_verified:
                return PrivacyDecision(
                    allowed=False,
                    reason="Destination lacks required compliance certifications",
                    logic_trace=["compliance: not_verified"]
                )
            
            return PrivacyDecision(
                allowed=True,
                transformations=[
                    Transform.ENCRYPT_AES256,
                    Transform.AUDIT_LOG,
                    Transform.REQUIRE_2FA
                ],
                logic_trace=["PHI: strict_mode", "compliance: verified"]
            )
        
        # Default deny
        return PrivacyDecision(
            allowed=False,
            reason="Unknown classification, default deny",
            logic_trace=["default: deny"]
        )
    
    def select_tool(self, 
                    goal: Goal, 
                    available_tools: List[Tool]) -> ToolSelection:
        """
        Choose appropriate tool for goal.
        
        Phase 0: Keyword matching + simple ranking
        Phase 1: Abductive + Causal reasoning
        
        Ranking factors:
        - Tool capability match
        - Context appropriateness
        - Past success rate
        - Cost/latency constraints
        """
        
        scored_tools = []
        
        for tool in available_tools:
            score = 0
            reasoning = []
            
            # Capability matching
            if goal.required_capability in tool.capabilities:
                score += 10
                reasoning.append(f"has_capability: {goal.required_capability}")
            
            # Context matching
            if tool.works_offline and context.network_quality == NetworkQuality.POOR:
                score += 5
                reasoning.append("works_offline: bonus for poor network")
            
            # Cost constraints
            if goal.max_cost and tool.cost_per_call <= goal.max_cost:
                score += 3
                reasoning.append(f"cost_ok: {tool.cost_per_call} <= {goal.max_cost}")
            elif goal.max_cost and tool.cost_per_call > goal.max_cost:
                score -= 10
                reasoning.append(f"cost_high: {tool.cost_per_call} > {goal.max_cost}")
            
            # Latency constraints
            if goal.max_latency_ms and tool.avg_latency_ms <= goal.max_latency_ms:
                score += 2
                reasoning.append(f"latency_ok: {tool.avg_latency_ms}ms")
            
            # Historical success
            if tool.success_rate > 0.9:
                score += 4
                reasoning.append(f"reliable: {tool.success_rate}")
            
            scored_tools.append((score, tool, reasoning))
        
        # Sort by score
        scored_tools.sort(reverse=True, key=lambda x: x[0])
        
        if not scored_tools:
            return ToolSelection(
                selected=None,
                reason="No tools available for goal",
                logic_trace=["no_tools_available"]
            )
        
        best_score, best_tool, reasoning = scored_tools[0]
        
        if best_score < 5:  # Threshold for "good enough"
            return ToolSelection(
                selected=None,
                reason="No tool meets minimum criteria",
                alternatives=[t for _, t, _ in scored_tools[:3]],
                logic_trace=["best_score: too_low", f"score: {best_score}"]
            )
        
        return ToolSelection(
            selected=best_tool,
            alternatives=[t for _, t, _ in scored_tools[1:4]],
            logic_trace=reasoning,
            confidence=min(best_score / 20.0, 1.0)  # Normalize to 0-1
        )
```

##### Phase 1: Logic Engine (Future Implementation)

**Goal:** Replace rule-based reasoning with full multi-paradigm Logic Engine using Unicode Semantic Dictionary.

**Key Differences from Phase 0:**
- **Temporal Logic:** Rich time-based reasoning ("ALWAYS," "EVENTUALLY," "UNTIL")
- **Deontic Logic:** Obligations, permissions, prohibitions
- **Modal Logic:** Possibility, necessity, counterfactuals
- **Fuzzy Logic:** Degrees of truth ("battery is somewhat low")
- **Probabilistic Logic:** Uncertainty quantification
- **Abductive Logic:** Best explanation for observations
- **Causal Logic:** Cause-effect reasoning
- **18+ paradigms** working in concert via Unicode Semantic Dictionary

**Example Phase 1 Access Control:**
```python
# Temporal logic: "Camera allowed between 6 AM - 10 PM"
temporal_constraint = LogicEngine.evaluate(
    paradigm=Paradigm.TEMPORAL,
    expression="ALWAYS((hour >= 6 AND hour < 22) -> camera.permitted)"
)

# Deontic logic: "System is obligated to respect user privacy settings"
deontic_constraint = LogicEngine.evaluate(
    paradigm=Paradigm.DEONTIC,
    expression="OBLIGATED(respect_privacy) AND in_private_space -> PROHIBITED(camera)"
)

# Fuzzy logic: "Battery is 'sufficient' for camera use"
fuzzy_battery = LogicEngine.evaluate(
    paradigm=Paradigm.FUZZY,
    expression="battery_level IS sufficient_for_camera",
    context={"battery_percent": 35}
)

# Modal logic: "It is possible to use camera, but not necessary"
modal_analysis = LogicEngine.evaluate(
    paradigm=Paradigm.MODAL,
    expression="POSSIBLE(camera_use) AND NOT NECESSARY(camera_use)"
)

# Synthesize across paradigms
decision = LogicEngine.synthesize(
    constraints=[temporal_constraint, deontic_constraint, fuzzy_battery, modal_analysis],
    weights=get_paradigm_weights_for_context(context)
)
```

**Migration Path:** Because the interface is identical, Phase 0 → Phase 1 migration requires:
1. Implement Unicode Semantic Dictionary
2. Add logic paradigm evaluators
3. Implement synthesis engine
4. Swap `ReasoningLayerPhase0` for `ReasoningLayerPhase1`
5. **No changes to agent, protocol, or tool layers**

##### Integration with Device & Cloud

**On Device:**
```python
# Before calling any tool, check with reasoning layer
sensor_data = device.sensors.camera.capture()  # This would fail!

# Correct flow:
access_decision = reasoning_layer.check_access(
    resource=Resource.CAMERA,
    context=device.get_context()
)

if access_decision.status == AccessStatus.GRANTED:
    sensor_data = device.sensors.camera.capture()
    
    # Before sending to cloud, check privacy
    privacy_decision = reasoning_layer.enforce_privacy(
        data=sensor_data,
        destination=Destination.CLOUD_AGENT
    )
    
    if privacy_decision.allowed:
        # Apply required transformations
        for transform in privacy_decision.transformations:
            sensor_data = transform.apply(sensor_data)
        
        device.send_to_cloud(sensor_data)
```

**On Cloud:**
```python
# When coordinating workflow, use reasoning layer
task = Task(
    type=TaskType.VISION_PROCESSING,
    latency_requirement_ms=500,
    compute_intensive=True
)

allocation = reasoning_layer.allocate_compute(
    task=task,
    context=cloud.get_device_context(device_id)
)

if allocation.location == ComputeLocation.CLOUD:
    result = vertex_ai.process_image(image)
elif allocation.location == ComputeLocation.LOCAL:
    cloud.send_task_to_device(device_id, task)
```

##### Governance & Auditability

**All reasoning decisions are logged:**
```python
@dataclass
class ReasoningLog:
    timestamp: datetime
    decision_type: str  # "access_control", "resource_allocation", etc.
    input_context: dict
    decision: Decision
    logic_trace: List[str]  # Step-by-step reasoning
    paradigms_used: List[Paradigm]  # Phase 1 only
    
# Example log entry
{
    "timestamp": "2025-10-23T10:15:30Z",
    "decision_type": "access_control",
    "resource": "camera",
    "decision": "GRANTED",
    "logic_trace": [
        "battery_check: 45% >= 20% threshold",
        "permission_check: GRANTED",
        "time_check: 10:15 in allowed range (06:00-22:00)",
        "privacy_mode: inactive",
        "all_checks: passed"
    ],
    "latency_ms": 2.3
}
```

**Why this matters:**
- **Transparency:** Users can see why decisions were made
- **Debugging:** Developers can trace unexpected behavior
- **Compliance:** Auditors can verify governance rules were followed
- **Learning:** System can improve reasoning from outcomes

##### Performance Requirements

**Phase 0 (Rule-Based):**
- Access control decision: <5ms
- Resource allocation: <10ms
- Privacy enforcement: <3ms
- Tool selection: <20ms

**Phase 1 (Logic Engine):**
- Simple decision (1-2 paradigms): <20ms
- Complex decision (5+ paradigms): <50ms
- Emergency override: <5ms (bypass complex reasoning)

##### Testing Strategy

**Unit Tests:**
```python
def test_access_control_battery_low():
    reasoning = ReasoningLayerPhase0()
    decision = reasoning.check_access(
        resource=Resource(type="camera", power_intensive=True),
        context=Context(battery_percent=15)
    )
    assert decision.status == AccessStatus.DENIED
    assert "battery" in decision.reason.lower()

def test_privacy_enforcement_sensitive_data():
    reasoning = ReasoningLayerPhase0()
    decision = reasoning.enforce_privacy(
        data=Data(classification=DataClass.SENSITIVE),
        destination=Destination(trusted=False)
    )
    assert decision.allowed == False
```

**Integration Tests:**
```python
def test_end_to_end_camera_capture_with_reasoning():
    # Simulate full flow with reasoning layer
    device = SimulatedDevice(battery=50, permissions=["camera"])
    
    # Attempt camera access
    access = device.reasoning.check_access(Resource.CAMERA, device.context())
    assert access.status == AccessStatus.GRANTED
    
    # Capture image
    image = device.camera.capture()
    
    # Check privacy before sending
    privacy = device.reasoning.enforce_privacy(image, Destination.CLOUD)
    assert privacy.allowed == True
    
    # Send to cloud
    device.send_to_cloud(image)
```

---

### 2. Protocol Layer

#### 2.1 Transport: WebTransport over QUIC
**Rationale:**
- Low latency (<10ms target)
- Multiplexing (multiple streams, single connection)
- Built-in reliability and congestion control
- NAT/firewall friendly
- Modern HTTP/3 ecosystem

**Implementation:**
- **Client:** Chromium WebTransport API (embedded or via system)
- **Server:** GCP Cloud Run or similar with WebTransport support

#### 2.2 Heartbeat Protocol

**Purpose:** Maintain continuous bidirectional awareness with minimal overhead.

**Payload Format (≤256 bytes):**
```protobuf
message Heartbeat {
  string device_id = 1;           // UUID (16 bytes)
  uint64 timestamp_ms = 2;        // Unix timestamp (8 bytes)
  uint32 sequence_number = 3;     // Monotonic counter (4 bytes)
  
  // Device state
  SensorBitmask available_sensors = 4;  // Bitfield (8 bytes)
  ConnectionQuality network_quality = 5; // Enum (1 byte)
  BatteryState battery = 6;              // % + charging (2 bytes)
  ComputeHeadroom compute_free = 7;      // % CPU/GPU/Memory (3 bytes)
  
  // Context (privacy-preserving)
  bytes context_hash = 8;         // SHA256 of user state (32 bytes)
  
  // Flags
  bool user_active = 9;           // Is user currently interacting? (1 bit)
  bool workflow_pending = 10;     // Background task running? (1 bit)
  
  // Optional: compressed telemetry (remaining budget)
}
```

**Frequency:**
- **IDLE:** 1 Hz (device inactive, no user interaction)
- **ACTIVE:** 10 Hz (user interacting, rapid state changes)
- **BURST:** 50 Hz (high-bandwidth activity like AR, video)

**Behavior:**
- **Missing heartbeat:** Cloud marks device as potentially disconnected
- **Reconnection:** Device sends full capability manifest
- **Offline mode:** Device queues heartbeats, sends on reconnect

#### 2.3 Connection States

```
STATE: IDLE
- Heartbeat only (1 Hz)
- No active streams
- Cloud maintains device twin state
- Transition: User interaction OR cloud-initiated workflow

STATE: ACTIVE  
- Heartbeat increases (10 Hz)
- MCP streams open for tool calls
- Full conversational interaction
- Transition: User idle timeout → IDLE, OR high-bandwidth need → BURST

STATE: BURST
- Heartbeat max (50 Hz)
- Multiple parallel streams (video, audio, data)
- Hybrid edge/cloud processing
- Transition: Task completion → ACTIVE or IDLE

STATE: WORKFLOW
- Background task running
- Periodic status via heartbeat
- Can transition to ACTIVE if user attention needed
- Transition: Task complete → IDLE
```

#### 2.4 MCP (Model Context Protocol)

**Purpose:** Standardized interface for tool access and context sharing.

**On Device (MCP Client):**
- Exposes local capabilities as MCP tools
- Example tools:
  - `camera_capture()`
  - `get_location()`
  - `sensor_stream(type, duration)`
  - `local_inference(prompt)`

**In Cloud (MCP Server):**
- Exposes cloud resources as MCP tools
- Example tools:
  - `vertex_ai_inference(model, prompt)`
  - `anthropic_claude(prompt, model)`
  - `eleven_labs_tts(text, voice)`
  - `blender_process(file, operations)`
  - `search_web(query)`

**Protocol:** JSON-RPC over WebTransport streams

---

### 3. Cloud Agent Infrastructure

#### 3.1 Hosting Platform
- **Primary:** Google Cloud Platform (GCP)
- **Services:**
  - **Compute:** Cloud Run (stateless agent instances)
  - **State:** Firestore or Cloud Memorystore (device twin state)
  - **Storage:** Cloud Storage (artifacts, models, data)
  - **ML:** Vertex AI (if using Google models)

#### 3.2 Cloud Agent Architecture

**Device Twin:**
- Real-time state model for each connected device
- Updated via heartbeat
- Queryable by orchestration engine

```python
class DeviceTwin:
    device_id: str
    last_heartbeat: datetime
    capabilities: SensorCapabilities
    current_state: DeviceState
    user_context_hash: bytes
    connection_quality: ConnectionQuality
    active_workflows: List[WorkflowID]
```

**Tool Registry:**
- Catalog of available cloud services
- Dynamic registration (services can come online/offline)
- Cost tracking (API usage, compute costs)

```python
class ToolRegistry:
    tools: Dict[str, ToolSpec]
    
    def discover_tools(self, context: TaskContext) -> List[Tool]:
        """Return tools relevant for given task context"""
        
    def call_tool(self, tool_id: str, params: dict) -> Result:
        """Execute tool call, handle auth, retry, errors"""
```

**Agent Runtime:**
- **LLM Backend:** Anthropic Claude (primary), fallback to others
- **Prompt Management:** System prompts for agent behavior
- **Context Window:** Device state + tool registry + user history
- **Reasoning:** Decides which tools to use, where to execute

#### 3.3 Minimal API Surface

```
Cloud Agent Endpoints:

WebSocket /connect
- Establish WebTransport connection
- Authenticate device
- Send initial capability manifest

POST /heartbeat
- Receive device heartbeat
- Update device twin
- Return any pending cloud-to-device messages

POST /mcp/tool_call
- Device requests cloud tool execution
- Cloud agent processes, returns result

GET /mcp/tool_list
- Device queries available cloud tools
- Filtered by device permissions

POST /workflow/start
- Initiate long-running workflow
- Return workflow ID for tracking

GET /workflow/status
- Query workflow state
- Can be polled from device
```

---

## Development Environment

### Local Development Setup

**Host Machine:**
- **OS:** Ubuntu 22.04 LTS or later
- **IDE:** Android Studio (latest stable)
- **Tools:**
  - AOSP build tools
  - Android SDK/NDK
  - Python 3.11+ (for LLM tuning, cloud development)
  - Docker (for local cloud agent testing)

**AOSP Build:**
```bash
# Minimal AOSP build for Pixel 10
repo init -u https://android.googlesource.com/platform/manifest -b main
repo sync -j8

# Custom build config
source build/envsetup.sh
lunch aosp_pixel10-userdebug

# Build minimal system
m -j8
```

**LLM Tuning Environment:**
- **Framework:** PyTorch or JAX
- **Hardware:** CUDA-capable GPU for fine-tuning
- **Models:** Gemini Nano or Llama-3 1B/3B quantized
- **Tools:** Hugging Face Transformers, PEFT for LoRA

### Cloud Development Setup

**Local Testing:**
- Docker containers simulating Cloud Run
- Local Firestore emulator for state
- Mock tool registry

**GCP Project Setup:**
```
Project: esn-dev-001
Region: us-central1 (or user-specific)

Services Enabled:
- Cloud Run
- Firestore
- Cloud Storage
- Vertex AI (optional)
- Secret Manager (API keys)

Service Account:
- esn-device-agent (for device auth)
- esn-cloud-agent (for cloud services)
```

---

## Minimal Viable Architecture (MVA)

### What Must Work for Phase 0 Success

**Milestone:** A device and cloud agent can maintain awareness and execute a simple coordinated action.

**Test Case:** "Device captures image, sends to cloud, cloud processes with vision API, returns result to device."

**Requirements:**
1. ✅ Device boots AOSP with custom agent
2. ✅ Device connects to cloud via WebTransport
3. ✅ Heartbeat flows bidirectionally every 1 second
4. ✅ Cloud maintains device twin (shows device as "online")
5. ✅ **Reasoning layer validates camera access** (battery check, permission check, time check)
6. ✅ Device can call local MCP tool (camera_capture) **after reasoning layer approval**
7. ✅ **Reasoning layer validates privacy** before sending image to cloud
8. ✅ Device sends captured image to cloud via stream
9. ✅ Cloud can call external tool (Vertex AI Vision or similar)
10. ✅ Cloud sends result back to device
11. ✅ Device displays result to user
12. ✅ Connection survives network interruption (reconnects gracefully)
13. ✅ **All reasoning decisions are logged with logic traces**

---

## Technology Stack Summary

### Device Side
| Component | Technology | Rationale |
|-----------|------------|-----------|
| Hardware | Google Pixel 10 (Tensor G5) | AOSP support, ML acceleration |
| OS | AOSP (custom build) | Full control, no bloat |
| Local LLM | Gemini Nano / Llama-3 1B | On-device inference capability |
| **Reasoning Layer** | **Custom (Python/Kotlin)** | **Logic Engine foundation, governance** |
| Protocol Client | Chromium WebTransport | Modern, low-latency |
| MCP Implementation | Custom (Python or Kotlin) | Lightweight, embeddable |
| UI Framework | Jetpack Compose / Custom | TBD based on LCARS design |

### Cloud Side
| Component | Technology | Rationale |
|-----------|------------|-----------|
| Hosting | GCP Cloud Run | Serverless, scales to zero |
| State Store | Firestore | Real-time, low-latency |
| LLM API | Anthropic Claude | Best reasoning capability |
| TTS | ElevenLabs | High quality, cost-effective |
| Vision | Vertex AI or external | Image understanding |
| Protocol Server | Python + WebTransport lib | Flexible, debuggable |

### Protocol & Standards
- **Transport:** WebTransport over QUIC
- **Tool Protocol:** MCP (Model Context Protocol)
- **Agent Protocol:** A2A (Agent-to-Agent, future)
- **Message Format:** Protocol Buffers (efficient, typed)
- **Auth:** OAuth 2.0 device flow + mTLS

---

## Non-Goals (For Bare-Bones Phase)

**Not required for Phase 0:**
- ❌ Multi-user support
- ❌ Advanced discovery mechanisms
- ❌ Long-running workflow engine
- ❌ P2P device communication
- ❌ Offline LLM inference (can degrade gracefully)
- ❌ Production-grade security hardening
- ❌ Cross-platform support (iOS, desktop)
- ❌ Advanced UI/UX (LCARS aesthetic)
- ❌ Healthcare sensor integration
- ❌ Kitchen/fridge management
- ❌ 3D printing workflows
- ❌ **Full Logic Engine with 18+ paradigms** (Phase 0 uses simplified rule-based reasoning)
- ❌ **Unicode Semantic Dictionary** (Phase 1 implementation)
- ❌ **Multi-paradigm synthesis** (Phase 1 implementation)

**Important:** While the full Logic Engine is deferred to Phase 1, the **reasoning layer interface** is architectural and must be present in Phase 0. This ensures governance is built-in from the start, and the system can evolve from simple rules to complex multi-paradigm reasoning without architectural changes.

**These will be built on top of the bare-bones foundation.**

---

## Success Criteria

**Bare-Bones Infrastructure is complete when:**

1. A physical device runs custom AOSP build
2. Device successfully connects to cloud agent
3. Heartbeat maintains connection with <10ms latency p50
4. Device can enumerate and access all sensors
5. Cloud can query device state in real-time
6. MCP tool calls work bidirectionally (device → cloud, cloud → device)
7. A simple multi-step workflow completes:
   - User triggers action on device
   - Device calls local tool (sensor)
   - Device sends data to cloud
   - Cloud processes with external API
   - Cloud returns result to device
   - User sees result
8. System recovers from network interruption automatically
9. Performance metrics:
   - Heartbeat: <10ms latency
   - Tool call: <100ms round-trip (local → cloud → local)
   - Image capture → cloud processing → result: <2 seconds
   - **Reasoning decisions: <5ms for access control, <10ms for resource allocation**
10. **Reasoning Layer operational:**
    - All tool/sensor access routes through reasoning layer
    - Access control decisions are logged and auditable
    - Resource allocation demonstrably affects behavior (local vs cloud execution)
    - Privacy enforcement prevents unauthorized data transmission
    - Logic traces are generated for every decision
11. Code is documented and reproducible by other developers

---

## Next Steps After Bare-Bones

Once the foundation exists, build inward:

**Phase 1: Discovery**
- Dynamic tool discovery
- Capability negotiation
- Resource-aware task allocation

**Phase 2: Orchestration**
- Workflow definition language
- Multi-step task coordination
- Error handling and retry logic

**Phase 3: Use Cases**
- 3D printing workflow
- Healthcare monitoring
- Kitchen management
- NGO-specific applications

**Phase 4: Scale**
- Multi-device coordination
- Community resource sharing
- P2P capabilities

---

## Appendix A: Heartbeat Protocol Details

### Message Format (Protobuf)

```protobuf
syntax = "proto3";

message Heartbeat {
  // Identity
  string device_id = 1;
  uint64 timestamp_ms = 2;
  uint32 sequence = 3;
  
  // Device state
  DeviceCapabilities capabilities = 4;
  DeviceHealth health = 5;
  UserContext context = 6;
}

message DeviceCapabilities {
  repeated SensorType sensors = 1;
  repeated string mcp_tools = 2;
  ComputeResources resources = 3;
}

message DeviceHealth {
  uint32 battery_percent = 1;
  bool battery_charging = 2;
  ConnectionQuality network = 3;
  uint32 cpu_usage_percent = 4;
  uint32 memory_free_mb = 5;
}

message UserContext {
  bytes context_hash = 1;  // Privacy-preserving state signature
  bool user_active = 2;
  uint64 last_interaction_ms = 3;
}

enum SensorType {
  CAMERA = 0;
  MICROPHONE = 1;
  GPS = 2;
  ACCELEROMETER = 3;
  // ... etc
}

enum ConnectionQuality {
  EXCELLENT = 0;  // <20ms latency, >50 Mbps
  GOOD = 1;       // <50ms latency, >10 Mbps
  FAIR = 2;       // <100ms latency, >1 Mbps
  POOR = 3;       // >100ms latency or <1 Mbps
}
```

### State Transitions

```
Device Boot → CONNECTING
    ↓
CONNECTING → IDLE (heartbeat established)
    ↓
IDLE → ACTIVE (user interaction OR cloud-initiated workflow)
    ↓
ACTIVE → BURST (high-bandwidth requirement)
    ↓
BURST → ACTIVE (task completes)
    ↓
ACTIVE → IDLE (inactivity timeout)
    ↓
IDLE → DISCONNECTED (network lost)
    ↓
DISCONNECTED → CONNECTING (network returns)
```

---

## Appendix B: MCP Tool Examples

### Device-Side Tools

```json
{
  "tool": "camera_capture",
  "description": "Capture a still image from device camera",
  "parameters": {
    "camera": "front|back",
    "resolution": "low|medium|high",
    "format": "jpg|png"
  },
  "returns": {
    "image_data": "base64",
    "metadata": {
      "timestamp": "ISO8601",
      "location": "optional GPS"
    }
  }
}
```

### Cloud-Side Tools

```json
{
  "tool": "anthropic_claude",
  "description": "Call Claude API for reasoning/generation",
  "parameters": {
    "model": "claude-sonnet-4.5",
    "prompt": "string",
    "max_tokens": "integer"
  },
  "returns": {
    "response": "string",
    "usage": {
      "input_tokens": "integer",
      "output_tokens": "integer",
      "cost_usd": "float"
    }
  }
}
```

---

## Appendix C: Initial Build Instructions

### AOSP Build for Pixel 10

```bash
# 1. Setup build environment
sudo apt-get install git-core gnupg flex bison build-essential \
  zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 \
  libncurses5 lib32ncurses5-dev x11proto-core-dev libx11-dev \
  lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig

# 2. Install repo tool
mkdir ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH=~/bin:$PATH

# 3. Initialize AOSP source
mkdir ~/aosp
cd ~/aosp
repo init -u https://android.googlesource.com/platform/manifest -b main
repo sync -j8

# 4. Build
source build/envsetup.sh
lunch aosp_pixel10-userdebug
m -j$(nproc)

# 5. Flash to device
adb reboot bootloader
fastboot flashall -w
```

### Cloud Agent Setup (GCP)

```bash
# 1. Create GCP project
gcloud projects create esn-dev-001
gcloud config set project esn-dev-001

# 2. Enable services
gcloud services enable run.googleapis.com
gcloud services enable firestore.googleapis.com
gcloud services enable storage.googleapis.com

# 3. Deploy agent (example)
gcloud run deploy esn-cloud-agent \
  --image gcr.io/esn-dev-001/cloud-agent:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated

# 4. Setup Firestore
gcloud firestore databases create --region=us-central1
```

---

## Appendix D: Reasoning Layer Examples

### Example 1: Camera Access with Low Battery

**Scenario:** User attempts to take photo, battery at 18%

**Reasoning Flow:**
```python
context = Context(
    battery_percent=18,
    user_permissions={"camera": True},
    time=datetime(2025, 10, 23, 14, 30),
    privacy_mode=False
)

decision = reasoning.check_access(
    resource=Resource(type="camera", power_intensive=True),
    context=context
)

# Result:
# decision.status = AccessStatus.DENIED
# decision.reason = "Battery too low for power-intensive resource"
# decision.logic_trace = ["battery_check: 18% < 20% threshold"]
```

**User Experience:** "Camera unavailable - battery too low. Please charge device or use low-power mode."

---

### Example 2: Inference Location Decision

**Scenario:** Vision processing task, good network, medium battery

**Reasoning Flow:**
```python
task = Task(
    type=TaskType.VISION_PROCESSING,
    latency_tolerance_ms=2000,
    compute_intensive=True,
    can_run_locally=True
)

context = Context(
    battery_percent=55,
    network_quality=NetworkQuality.GOOD,
    local_model_available=True
)

allocation = reasoning.allocate_compute(task, context)

# Result:
# allocation.location = ComputeLocation.CLOUD
# allocation.reason = "High latency tolerance + good network"
# allocation.logic_trace = [
#     "latency: 2000ms > 1000ms threshold",
#     "network: GOOD",
#     "prefer_cloud: better model quality"
# ]
```

**System Behavior:** Task sent to cloud Vertex AI for processing

---

### Example 3: Privacy Enforcement for Health Data

**Scenario:** Heart rate sensor data being sent to analytics service

**Reasoning Flow:**
```python
data = Data(
    type=DataType.HEART_RATE,
    classification=DataClass.PHI,  # Protected Health Information
    value=72
)

destination = Destination(
    name="analytics-service",
    trusted=True,
    compliance_verified=True  # HIPAA compliant
)

privacy = reasoning.enforce_privacy(data, destination)

# Result:
# privacy.allowed = True
# privacy.transformations = [
#     Transform.ENCRYPT_AES256,
#     Transform.AUDIT_LOG,
#     Transform.REQUIRE_2FA
# ]
# privacy.logic_trace = [
#     "classification: PHI",
#     "destination: trusted",
#     "compliance: HIPAA verified",
#     "enforce: strict_mode"
# ]
```

**System Behavior:** Data encrypted, logged, requires 2FA before transmission

---

### Example 4: Tool Selection for Image Task

**Scenario:** User wants to "identify this plant"

**Available Tools:**
- Vertex AI Vision (cloud, $0.001/image, 200ms avg, 95% accuracy)
- Local Plant Classifier (device, free, 50ms avg, 78% accuracy)
- PlantNet API (cloud, free, 500ms avg, 88% accuracy)

**Reasoning Flow:**
```python
goal = Goal(
    type=GoalType.IMAGE_CLASSIFICATION,
    domain="plants",
    required_capability="image_classification",
    max_latency_ms=1000,
    max_cost=0.01
)

selection = reasoning.select_tool(goal, available_tools)

# Scoring:
# Vertex AI: score=19 (capability+10, cost_ok+3, latency_ok+2, reliable+4)
# Local Classifier: score=17 (capability+10, works_offline+5, latency_ok+2)
# PlantNet: score=18 (capability+10, cost_ok+3, latency_ok+2, reliable+3)

# Result:
# selection.selected = "Vertex AI Vision"
# selection.alternatives = ["PlantNet API", "Local Plant Classifier"]
# selection.confidence = 0.95
# selection.logic_trace = [
#     "has_capability: image_classification",
#     "cost_ok: $0.001 <= $0.01",
#     "latency_ok: 200ms <= 1000ms",
#     "reliable: 0.95 success_rate"
# ]
```

**System Behavior:** Image sent to Vertex AI Vision for best accuracy

---

### Example 5: Emergency Override

**Scenario:** Emergency call initiated, camera needed despite low battery

**Reasoning Flow:**
```python
context = Context(
    battery_percent=8,
    emergency_mode=True,  # User pressed emergency button
    user_permissions={"camera": True}
)

decision = reasoning.check_access(
    resource=Resource(type="camera", power_intensive=True),
    context=context
)

# Result:
# decision.status = AccessStatus.GRANTED
# decision.reason = "Emergency mode active, safety override"
# decision.logic_trace = [
#     "battery_check: 8% < 20% threshold",
#     "emergency_mode: active",
#     "override: safety_priority",
#     "granted: emergency_override"
# ]
```

**System Behavior:** Camera access granted, emergency services notified

---

### Example 6: Multi-Factor Decision (Phase 1 Preview)

**Scenario:** User in private space, wants to record voice note, 11 PM

**Phase 1 Logic Engine Flow:**
```python
# Temporal Logic
temporal = LogicEngine.evaluate(
    paradigm=Paradigm.TEMPORAL,
    expression="NOT (DURING working_hours) -> microphone.requires_justification"
)
# Result: True (11 PM is outside working hours)

# Deontic Logic
deontic = LogicEngine.evaluate(
    paradigm=Paradigm.DEONTIC,
    expression="in_private_space AND OBLIGATED(respect_privacy) -> microphone.permitted_with_consent"
)
# Result: True (private space + consent given = permitted)

# Modal Logic
modal = LogicEngine.evaluate(
    paradigm=Paradigm.MODAL,
    expression="POSSIBLE(voice_note) AND NECESSARY(user_initiated)"
)
# Result: True (action is possible and was user-initiated)

# Fuzzy Logic
fuzzy_appropriateness = LogicEngine.evaluate(
    paradigm=Paradigm.FUZZY,
    expression="time_appropriateness IS medium",
    context={"hour": 23, "location": "home"}
)
# Result: 0.6 (moderately appropriate)

# Synthesize
decision = LogicEngine.synthesize(
    constraints=[temporal, deontic, modal, fuzzy_appropriateness],
    weights={
        Paradigm.DEONTIC: 0.4,  # Privacy rules weighted heavily
        Paradigm.MODAL: 0.3,
        Paradigm.TEMPORAL: 0.2,
        Paradigm.FUZZY: 0.1
    }
)

# Result:
# decision.status = AccessStatus.GRANTED
# decision.confidence = 0.85
# decision.paradigms_used = [TEMPORAL, DEONTIC, MODAL, FUZZY]
# decision.logic_trace = [
#     "temporal: outside_working_hours (11 PM)",
#     "deontic: private_space + user_consent = permitted",
#     "modal: user_initiated + possible",
#     "fuzzy: appropriateness = 0.6 (medium)",
#     "synthesis: weighted_score = 0.85",
#     "decision: GRANTED"
# ]
```

**User Experience:** "Recording voice note. Privacy mode active - data stays on device."

---

### Example 7: Governance Audit Log

**Sample Audit Entry:**
```json
{
  "event_id": "evt_2025-10-23_14-30-15_abc123",
  "timestamp": "2025-10-23T14:30:15.234Z",
  "device_id": "device_pixel10_001",
  "decision_type": "access_control",
  "resource": "camera",
  "context": {
    "battery_percent": 45,
    "network_quality": "GOOD",
    "user_permissions": ["camera", "location"],
    "privacy_mode": false,
    "time": "2025-10-23T14:30:15Z"
  },
  "decision": {
    "status": "GRANTED",
    "confidence": 1.0,
    "logic_trace": [
      "battery_check: 45% >= 20% (PASS)",
      "permission_check: camera permission granted (PASS)",
      "time_check: 14:30 in allowed range 06:00-22:00 (PASS)",
      "privacy_mode: inactive (PASS)",
      "all_checks: passed"
    ],
    "latency_ms": 2.1
  },
  "outcome": {
    "resource_accessed": true,
    "data_captured": "image_001.jpg",
    "privacy_decision": {
      "allowed_destinations": ["cloud_agent"],
      "transformations_applied": [],
      "reasoning": "public classification, no restrictions"
    }
  },
  "phase": 0,  // Phase 0 = rule-based, Phase 1 = Logic Engine
  "paradigms_used": ["rule_based"]  // Phase 1 will list multiple paradigms
}
```

**Audit Use Cases:**
- User reviews: "Why couldn't I use the camera last night?"
- Developer debugging: "Why is this task always running on cloud?"
- Compliance: "Prove that PHI was never sent unencrypted"
- System learning: "Which decisions led to user satisfaction?"

---

**End of Appendix D**

---

## Appendix E: Phase 0 → Phase 1 Migration Checklist

### Prerequisites
- [ ] Phase 0 bare-bones fully operational
- [ ] All success criteria met
- [ ] Reasoning layer interface proven in production
- [ ] Governance audit logs demonstrating correct behavior
- [ ] Performance benchmarks established

### Unicode Semantic Dictionary Implementation
- [ ] Design dictionary schema (concepts, relations, paradigms)
- [ ] Implement core vocabulary (access, permission, privacy, resources)
- [ ] Add domain-specific vocabularies (sensors, tools, health, etc.)
- [ ] Create paradigm mapping (concept → logic paradigms)
- [ ] Validate dictionary completeness for target use cases

### Logic Paradigm Evaluators
- [ ] **Temporal Logic** (ALWAYS, EVENTUALLY, UNTIL, SINCE)
- [ ] **Deontic Logic** (OBLIGATED, PERMITTED, FORBIDDEN)
- [ ] **Modal Logic** (POSSIBLE, NECESSARY, CONTINGENT)
- [ ] **Fuzzy Logic** (membership functions, degrees of truth)
- [ ] **Probabilistic Logic** (Bayesian reasoning, uncertainty)
- [ ] **Abductive Logic** (best explanation)
- [ ] **Causal Logic** (cause-effect chains)
- [ ] Additional paradigms per patent specification

### Synthesis Engine
- [ ] Implement paradigm weighting mechanism
- [ ] Create conflict resolution strategies
- [ ] Build confidence scoring
- [ ] Add explanation generation (why this decision?)
- [ ] Implement caching for repeated decisions

### Integration Testing
- [ ] All Phase 0 test cases pass with Phase 1 implementation
- [ ] Complex multi-paradigm decisions work correctly
- [ ] Performance meets targets (<50ms for complex decisions)
- [ ] Audit logs include paradigm information
- [ ] User explanations are comprehensible

### Validation Against Patent Claims
- [ ] <35ms validation time (per patent claim)
- [ ] 18+ logic paradigms operational
- [ ] Unicode dictionary correctly maps concepts
- [ ] Multi-paradigm synthesis produces correct results
- [ ] System demonstrates advantages over single-logic approaches

### Production Rollout
- [ ] A/B testing (Phase 0 vs Phase 1)
- [ ] Gradual rollout (10% → 50% → 100%)
- [ ] Monitor decision quality metrics
- [ ] User satisfaction surveys
- [ ] Performance impact assessment

### Success Metrics
- [ ] Decision accuracy improved over Phase 0
- [ ] User trust/satisfaction increased
- [ ] Edge cases handled better (complex scenarios)
- [ ] Governance compliance improved
- [ ] System can explain its reasoning to users

---

## Document History

- **v0.1** (2025-10-23): Initial bare-bones specification
  - Defined core components (device, protocol, cloud)
  - Established protocol layer (WebTransport, heartbeat, MCP)
  - Added Reasoning Layer as architectural foundation
  - Outlined development environment (AOSP, GCP)
  - Set success criteria with governance requirements
  - Included Phase 0 → Phase 1 migration path for Logic Engine

---

**End of Bare-Bones Specification**

This document defines the foundation. Everything else builds on top of this.
