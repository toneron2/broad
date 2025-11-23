# BROAD Project: Architectural Decisions

## How to Use This Document

- **✅ RECOMMENDED**: Decisions I can make based on synthesized best practices across domains
- **❓ YOUR DECISION NEEDED**: Questions where best practices don't exist, conflict, or require business judgment

Review recommendations, make decisions on open questions, and we proceed with implementation.

---

## 1. MCP SERVER ARCHITECTURE

### ✅ RECOMMENDED: Domain-Aligned Multiple Servers

**Decision**: Implement **separate MCP servers per business domain** (Sales, Purchasing, Inventory, Manufacturing, HR, Accounting, Infrastructure).

**Rationale from Best Practices**:
1. **MCP Official Guidance**: "Servers should operate independently with focused, specialized responsibilities" - explicitly recommends multiple specialized servers over monolithic
2. **Team Ownership Pattern**: Each domain can be developed, tested, deployed independently
3. **Security Isolation**: Clear boundaries prevent cross-domain access issues
4. **Scaling Flexibility**: Can scale domains independently based on load
5. **Stakeholder Interview Mapping**: Each vertical business area stakeholder maps to specific MCP server
6. **Modular Demonstration**: Can demonstrate Sales domain independently before Manufacturing is ready

**Domain Server Structure**:
```
mcp-sales/              - Sales & CRM operations
mcp-purchasing/         - Procurement operations
mcp-inventory/          - Stock & warehouse operations
mcp-manufacturing/      - Production operations
mcp-accounting/         - Financial operations
mcp-hr/                 - Human resources operations
mcp-infrastructure/     - Terraform, n8n, observability platform operations
mcp-observability/      - Query metrics, logs, traces (cross-cutting)
mcp-testing/            - Execute tests, verify operations (cross-cutting)
```

**Implementation Pattern**:
- Each server = separate Python package using `frappe/mcp` library
- Each server = separate Kubernetes deployment
- Each server = independent versioning and deployment
- Host (Claude Desktop or custom client) connects to all servers
- Host orchestrates cross-domain workflows

---

### ✅ RECOMMENDED: Stateless Server Design

**Decision**: Implement MCP servers as **stateless services** that query ERPNext on each request.

**Rationale from Best Practices**:
1. **MCP Guidance**: Streamable HTTP designed for stateless implementations to enable horizontal scaling
2. **Kubernetes Pattern**: Stateless pods scale horizontally via replicas
3. **ERPNext as Source of Truth**: ERPNext already maintains state, servers are thin API layer
4. **High Availability**: Any server instance can handle any request
5. **Simplified Deployment**: No state migration, no session affinity required

**Session ID Usage**:
- Use session IDs for request resumability (MCP standard)
- NOT for storing application state
- Bind session to user ID for security
- Cryptographically secure random generation

**Performance Optimization**:
- Can add read-through cache layer (Redis) if needed
- Cache ERPNext API responses with TTL
- Invalidate on webhook notifications from ERPNext
- But server logic remains stateless

---

### ✅ RECOMMENDED: HTTP/SSE Transport for Production

**Decision**: Deploy MCP servers using **Streamable HTTP transport** (not stdio).

**Rationale from Best Practices**:
1. **MCP Official Standard**: Streamable HTTP is current production standard (HTTP+SSE deprecated)
2. **Remote Access Required**: Demonstration needs remote access, stdio is local-only
3. **Horizontal Scaling**: HTTP works with load balancers, stdio doesn't
4. **Standard Infrastructure**: Works with ingress controllers, API gateways
5. **Multi-Client Support**: Multiple agents/users can connect simultaneously

**Transport Configuration**:
- Single `/mcp` endpoint per server
- POST for client requests
- GET with optional SSE for server messages
- `Mcp-Session-Id` header for resumability
- HTTPS with OAuth2 authentication

**Development Mode**:
- Can use stdio locally for testing individual servers
- Production deployment always HTTP/SSE

---

### ✅ RECOMMENDED: OAuth2 with Dynamic Client Registration

**Decision**: Implement **OAuth 2.1 with Dynamic Client Registration** for MCP authentication.

**Rationale from Best Practices**:
1. **MCP Security Standard**: OAuth 2.1 is official authentication mechanism
2. **Dynamic Registration (RFC 7591)**: Eliminates manual credential setup, reduces friction
3. **Multi-Server Support**: Each server validates tokens independently
4. **Production Security**: Industry standard, well-understood, auditable
5. **Token Separation**: MCP servers MUST NOT accept tokens not issued for them (security requirement)

**Implementation Pattern**:
- Deploy OAuth server (recommend Keycloak or cloud-managed)
- Each MCP server registers with OAuth server
- Metadata discovery via `/.well-known/oauth-authorization-server`
- PKCE flow for client security
- Token verification on every request

**Alternative for Initial Demo** (❓ YOUR DECISION):
- Could use API keys initially for simpler demo
- Migrate to OAuth2 for production
- Trade-off: Speed to demo vs production security from start

---

## 2. TERRAFORM EXPOSURE VIA MCP

### ❓ YOUR DECISION NEEDED: Terraform Operation Safety Model

**The Challenge**: Exposing terraform operations via MCP is powerful but risky. Agents could potentially destroy infrastructure.

**Option A: Pre-Approved Operation Templates**
- MCP tools expose only safe, pre-defined operations
- Examples: `scale_up_gke`, `enable_module`, `backup_state`
- Each template has validation rules
- No arbitrary terraform commands
- **PRO**: Very safe, predictable
- **CON**: Less flexible, need to anticipate all operations

**Option B: Approval Workflow Pattern**
- MCP tools can propose any terraform operation
- Requires human approval before execution
- Show terraform plan output
- User confirms/rejects
- **PRO**: Flexible, full terraform power
- **CON**: More complex, requires approval UI

**Option C: Sandbox Environment Only**
- MCP terraform tools work only in sandbox
- Production infrastructure changes are manual/CI-CD only
- **PRO**: Very safe for demonstration
- **CON**: Not full self-managing system

**Option D: Tiered Access Model**
- Read-only operations: No approval needed (`terraform show`, `terraform state list`)
- Non-destructive changes: Automated approval (`scale`, `add resources`)
- Destructive operations: Always require approval (`destroy`, `delete`)
- **PRO**: Balanced safety and automation
- **CON**: Complex to categorize all operations

**My Recommendation**: Start with **Option A** (templates) for initial deployment, evolve to **Option D** (tiered) once proven.

**QUESTION**: Which safety model aligns with your "single pass deployment" vision while maintaining safety?

---

### ✅ RECOMMENDED: Terraform State Management

**Decision**: Use **GCS backend for terraform state** with state locking via native GCS locking.

**Rationale from Best Practices**:
1. **Terraform Best Practice**: Remote state required for team/automation collaboration
2. **GCP Native**: GCS provides automatic locking (no separate DynamoDB needed like AWS)
3. **Versioning**: GCS versioning provides state history
4. **Encryption**: At-rest encryption for sensitive state data
5. **Access Control**: IAM-based access to state files

**State Structure**:
```
broad-terraform-state/
├── infrastructure/terraform.tfstate      # GKE, networking, storage
├── platform/terraform.tfstate            # Databases, redis, observability
├── application/terraform.tfstate         # ERPNext, n8n deployments
└── mcp/terraform.tfstate                 # MCP server deployments
```

**Workspace Strategy**:
- Workspaces for different scales: `small`, `medium`, `large`
- Or separate state files per environment
- MCP tools can switch workspaces for scale demonstrations

---

## 3. N8N INTEGRATION ARCHITECTURE

### ✅ RECOMMENDED: n8n as Workflow Orchestration + MCP Exposure

**Decision**: n8n serves **two roles**:
1. **Workflow automation** (traditional n8n use)
2. **Exposed via MCP** for agents to create/manage workflows

**Rationale from Best Practices**:
1. **Domain Separation**: n8n has built-in ERPNext node - perfect for workflow automation
2. **Agentic Control**: Agents should be able to create workflows, not just trigger them
3. **Self-Configuration**: System can wire itself together via n8n workflow creation
4. **Demonstration Value**: Show how agents create automation, not just execute it

**n8n MCP Server Tools**:
```python
@mcp.tool()
def create_workflow(name: str, definition: dict):
    """Create new n8n workflow from definition"""

@mcp.tool()
def execute_workflow(workflow_id: str, data: dict):
    """Execute existing workflow with data"""

@mcp.tool()
def list_workflows(tag: str = None):
    """List available workflows, optionally filtered by tag"""

@mcp.tool()
def get_workflow_executions(workflow_id: str):
    """Get execution history and results"""
```

**Workflow Templates by Domain**:
- Sales: Lead nurturing, order processing, customer notifications
- Purchasing: PO approval chains, supplier notifications
- Inventory: Stock alerts, reorder automation
- Each domain MCP server includes relevant n8n templates
- Infrastructure MCP server can deploy workflow templates

---

### ✅ RECOMMENDED: n8n Deployment Pattern

**Decision**: Deploy n8n on **same GKE cluster** as ERPNext with shared database access.

**Rationale from Best Practices**:
1. **Network Locality**: Fast internal communication with ERPNext
2. **Resource Efficiency**: Shared cluster resources
3. **Unified Observability**: Same Prometheus/Grafana stack
4. **Database Access**: Can query ERPNext database for complex operations
5. **Webhook Receiver**: Internal service for ERPNext webhooks

**n8n Configuration**:
- Persistent storage for workflow definitions (GCS or Persistent Volume)
- PostgreSQL database for execution history (Cloud SQL or in-cluster)
- Environment-based configuration (secrets in Kubernetes Secrets)
- API access enabled for MCP server integration
- Webhook URL accessible from ERPNext

---

## 4. OBSERVABILITY ARCHITECTURE

### ✅ RECOMMENDED: Hybrid Observability Stack

**Decision**: **OpenTelemetry + Prometheus + Grafana + Cloud Monitoring** hybrid approach.

**Rationale from Best Practices**:
1. **Rich Dashboards**: Grafana provides "contextually meaningful visualizations" you require
2. **Vendor Neutrality**: OpenTelemetry prevents GCP lock-in
3. **Cost Optimization**: Self-hosted Prometheus cheaper than Cloud Monitoring for high-cardinality metrics
4. **GCP Integration**: Cloud Monitoring for infrastructure metrics (GKE, Cloud SQL)
5. **Unified View**: Grafana can query both Prometheus and Cloud Monitoring

**Architecture**:
```
ERPNext + n8n + MCP Servers (OTel instrumentation)
    ↓
OpenTelemetry Collector
    ↓
    ├─→ Prometheus (application metrics, custom business metrics)
    ├─→ Cloud Monitoring (infrastructure metrics, GCP services)
    ├─→ Loki (application logs, cheap storage)
    ├─→ Cloud Logging (infrastructure logs, audit logs)
    ├─→ Tempo (distributed traces)
    └─→ Cloud Trace (infrastructure traces)
         ↓
    Grafana (unified visualization)
```

**Free Tier Maximization**:
- Prometheus self-hosted (no cost except compute)
- Loki self-hosted (cheap object storage)
- Tempo self-hosted (cheap object storage)
- Cloud Monitoring free tier: 150MB/month metrics
- Cloud Logging free tier: 50GB/month logs
- Send only essential data to GCP services

---

### ✅ RECOMMENDED: Domain-Specific Dashboards

**Decision**: Create **Grafana dashboard per business domain** plus platform dashboards.

**Rationale from Best Practices**:
1. **Contextual Relevance**: Sales stakeholder sees sales metrics, not kubernetes pods
2. **Business + Technical Correlation**: Show order processing time AND database query time
3. **Demonstration Value**: Each vertical demo shows its own observability
4. **Progressive Disclosure**: Executive → Operations → Developer dashboard hierarchy

**Dashboard Structure**:
```
Grafana Dashboards:
├── Executive Overview (all domains, high-level KPIs)
├── Platform Operations (GKE, databases, infrastructure)
├── Sales Domain (orders, customers, conversion rates, API latency)
├── Purchasing Domain (POs, suppliers, approval times)
├── Inventory Domain (stock levels, movements, warehouse performance)
├── Manufacturing Domain (production, efficiency, capacity)
├── Accounting Domain (transactions, reconciliation, cash flow)
├── HR Domain (headcount, attendance, payroll)
└── Testing & Quality (test execution, coverage, performance)
```

**Common Dashboard Pattern** (each domain):
```
[Business KPIs]           [Technical Performance]
- Transactions/hour       - API response time (p50/p95/p99)
- Error rate             - Error rate by endpoint
- Active operations      - Database query performance
- Pending approvals      - Queue depths

[Real-Time Activity]      [Resource Utilization]
- Recent transactions    - CPU/Memory
- Active users          - Network I/O
- Workflow executions   - Cache hit rates
```

---

### ✅ RECOMMENDED: OpenTelemetry Instrumentation

**Decision**: Instrument **all custom code** with OpenTelemetry SDK.

**Rationale from Best Practices**:
1. **89% Industry Adoption**: Industry standard, proven pattern
2. **Vendor Neutral**: Can switch backends without code changes
3. **Automatic Instrumentation**: Libraries auto-instrument common frameworks
4. **Correlation**: Links metrics, logs, traces automatically
5. **Future-Proof**: Industry moving to OTel as standard

**Instrumentation Points**:
- ERPNext: Custom Frappe apps and hooks
- n8n: Custom nodes and workflow steps
- MCP Servers: All tool invocations
- Infrastructure: Kubernetes metrics via OTel Collector

**Python Instrumentation** (for Frappe/MCP):
```python
from opentelemetry import trace, metrics
from opentelemetry.exporter.otlp.proto.grpc import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider

tracer = trace.get_tracer(__name__)

@mcp.tool()
@tracer.start_as_current_span("create_sales_order")
def create_sales_order(customer: str, items: list):
    span = trace.get_current_span()
    span.set_attribute("customer", customer)
    span.set_attribute("item_count", len(items))
    # Business logic
```

---

### ❓ YOUR DECISION NEEDED: Observability Granularity

**The Question**: How detailed should real-time observability be?

**Option A: Every Transaction**
- Trace every API call, database query, workflow execution
- Complete visibility, perfect for demonstration
- **PRO**: Total transparency, catch everything
- **CON**: High cardinality, expensive storage, potential performance impact

**Option B: Sampled Tracing**
- Sample 10% of transactions, all errors
- Aggregate metrics for everything
- **PRO**: Lower cost, still representative
- **CON**: Might miss specific transactions

**Option C: Intelligent Sampling**
- 100% tracing for slow/error transactions
- Sample normal transactions
- Always trace "interesting" operations (new customer, large order)
- **PRO**: Catch problems, reduce noise
- **CON**: More complex configuration

**My Recommendation**: Start **Option A** (complete tracing) for demonstration, have **Option C** configuration ready for cost management.

**QUESTION**: For demonstrating "full operational observability", is 100% tracing essential or is intelligent sampling acceptable?

---

## 5. TESTING ARCHITECTURE

### ✅ RECOMMENDED: k6 for Load Testing

**Decision**: Use **k6 with k6-operator on GKE** for load and performance testing.

**Rationale from Best Practices**:
1. **Kubernetes Native**: k6-operator manages distributed test execution
2. **Cloud Native**: Modern, designed for microservices and APIs
3. **JavaScript Familiar**: Test scripts in JavaScript, accessible
4. **Metrics Integration**: Exports to Prometheus automatically
5. **Scale Testing**: Can simulate thousands of concurrent users
6. **Active Development**: k6 Operator 1.0 released September 2025

**k6 Test Structure**:
```
tests/load/
├── scenarios/
│   ├── small-business.js      # 10 users, basic workflows
│   ├── medium-business.js     # 100 users, standard operations
│   └── large-enterprise.js    # 1000 users, complex workflows
├── workflows/
│   ├── sales-order-flow.js
│   ├── purchase-cycle.js
│   └── inventory-movement.js
└── lib/
    └── erpnext-helpers.js     # Reusable ERPNext API functions
```

**Deployment**:
- k6-operator deployed on GKE
- TestRun CRDs define test scenarios
- Tests triggered via MCP testing server
- Results stored in Prometheus, visualized in Grafana

---

### ✅ RECOMMENDED: pytest for Functional Testing

**Decision**: Use **pytest + Selenium** for functional/workflow testing.

**Rationale from Best Practices**:
1. **Python Ecosystem**: Matches Frappe/ERPNext stack
2. **Selenium Standard**: Industry standard for web application testing
3. **Frappe Integration**: Can use Frappe test framework patterns
4. **Fixture-Based**: Clean setup/teardown for test isolation
5. **Extensive Plugins**: pytest-xdist for parallel execution, pytest-bdd for behavior testing

**Test Structure**:
```
tests/functional/
├── test_sales_workflows.py
├── test_purchasing_workflows.py
├── test_inventory_workflows.py
├── test_manufacturing_workflows.py
├── test_accounting_workflows.py
├── test_hr_workflows.py
├── fixtures/
│   ├── test_data.py
│   └── browser.py
└── conftest.py
```

**Test Pattern**:
```python
@pytest.mark.sales
def test_sales_order_creation_workflow(erpnext_session, test_customer):
    """Verify complete sales order workflow from quote to invoice"""
    # Create quotation
    # Convert to sales order
    # Create delivery note
    # Generate invoice
    # Verify accounting entries
    # Assert all steps successful
```

---

### ✅ RECOMMENDED: MCP Testing Server

**Decision**: Create **dedicated MCP server for test orchestration**.

**Rationale from Best Practices**:
1. **Agentic Testing**: Agents can trigger tests, verify results
2. **Self-Validation**: System can test itself
3. **Continuous Verification**: After each deployment, run validation
4. **Progressive Testing**: Start with smoke tests, expand to full suite

**Testing MCP Tools**:
```python
@mcp.tool()
def run_smoke_tests(domain: str = None):
    """Execute smoke tests for domain or all"""

@mcp.tool()
def run_functional_tests(domain: str, workflow: str = None):
    """Execute functional tests for specific workflows"""

@mcp.tool()
def run_load_test(scenario: str, duration: str):
    """Execute k6 load test scenario"""

@mcp.tool()
def get_test_results(test_run_id: str):
    """Retrieve test execution results"""

@mcp.tool()
def verify_deployment(component: str):
    """Verify component is deployed and functional"""
```

---

### ❓ YOUR DECISION NEEDED: Test Data Strategy

**The Question**: Where does test data come from?

**Option A: Synthetic Generation**
- Programmatically generate customers, items, orders
- Faker library for realistic data
- **PRO**: Repeatable, clean, no privacy concerns
- **CON**: May not reflect real-world complexity

**Option B: Template-Based**
- Pre-defined test datasets per industry vertical
- Manufacturing company template, retail template, etc.
- **PRO**: Realistic scenarios, stakeholder-relevant
- **CON**: Need to create/maintain templates

**Option C: Anonymized Production Data**
- If real ERPNext data available, anonymize and use
- **PRO**: Most realistic
- **CON**: Privacy concerns, may not exist yet

**Option D: Hybrid**
- Synthetic for automated tests
- Template-based for demonstrations
- **PRO**: Best of both worlds
- **CON**: Maintain both systems

**My Recommendation**: **Option D** - synthetic for testing, template-based for stakeholder demos.

**QUESTION**: Do you have industry vertical preferences for demonstration templates (manufacturing, retail, services, etc.)?

---

## 6. DEPLOYMENT MODULARITY

### ✅ RECOMMENDED: Terraform Module Structure

**Decision**: **Hierarchical terraform modules** with conditional domain activation.

**Rationale from Best Practices**:
1. **Terraform Best Practice**: Composition of smaller modules
2. **Progressive Deployment**: Can deploy infrastructure → platform → domains incrementally
3. **Scale Configuration**: Same modules, different variables
4. **Reusability**: Modules can be used independently

**Module Structure**:
```
terraform/
├── modules/
│   ├── infrastructure/
│   │   ├── gke/              # Kubernetes cluster
│   │   ├── networking/       # VPC, subnets, firewall
│   │   └── storage/          # Persistent volumes, GCS buckets
│   ├── platform/
│   │   ├── database/         # MariaDB (StatefulSet or Cloud SQL)
│   │   ├── redis/            # Redis StatefulSets
│   │   ├── observability/    # Prometheus, Grafana, Loki, Tempo
│   │   └── oauth/            # OAuth server (Keycloak)
│   ├── application/
│   │   ├── erpnext/          # ERPNext Helm deployment
│   │   └── n8n/              # n8n deployment
│   └── mcp/
│       ├── mcp-server-base/  # Shared MCP server infrastructure
│       ├── domain-sales/     # Sales MCP server
│       ├── domain-purchasing/# Purchasing MCP server
│       ├── domain-inventory/ # Inventory MCP server
│       └── ...               # Other domain servers
├── environments/
│   ├── sandbox/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars  # Sandbox config
│   ├── small/
│   │   └── terraform.tfvars  # Small business config
│   ├── medium/
│   │   └── terraform.tfvars  # Medium business config
│   └── large/
│       └── terraform.tfvars  # Large enterprise config
└── main.tf                   # Root module
```

**Configuration-Driven Domain Activation**:
```hcl
# terraform.tfvars
enabled_domains = {
  sales        = true
  purchasing   = true
  inventory    = true
  manufacturing = false  # Not deployed yet
  accounting   = true
  hr           = false   # Not deployed yet
}

scale_profile = "small"  # small, medium, large

gke_node_count = 2
mariadb_storage_size = "20Gi"
```

---

### ✅ RECOMMENDED: Phased Deployment Targets

**Decision**: Define **terraform targets** for incremental deployment with verification.

**Rationale from Best Practices**:
1. **Terraform Target Feature**: `-target` flag for selective apply
2. **Dependency Management**: Terraform handles dependencies automatically
3. **Verification Checkpoints**: Test each layer before next
4. **Rollback Capability**: Can destroy specific components

**Deployment Phases**:
```bash
# Phase 1: Infrastructure
terraform apply -target=module.infrastructure
# Verify: kubectl cluster-info, kubectl get nodes

# Phase 2: Platform Services
terraform apply -target=module.platform
# Verify: Database reachable, Prometheus scraping

# Phase 3: Core Application
terraform apply -target=module.application.erpnext
terraform apply -target=module.application.n8n
# Verify: ERPNext site accessible, n8n API responding

# Phase 4: Observability
terraform apply -target=module.platform.observability
# Verify: Grafana dashboards loading, metrics flowing

# Phase 5: MCP Servers (by domain)
terraform apply -target=module.mcp.domain-sales
# Verify: MCP server health check, tools registered
terraform apply -target=module.mcp.domain-purchasing
# Verify: MCP server health check, tools registered

# Phase 6: Full Deployment (everything together)
terraform apply
# Verify: Full integration test suite
```

---

### ❓ YOUR DECISION NEEDED: Single-Command vs Phased Default

**The Question**: What's the default deployment experience?

**Option A: Single Command by Default**
- `terraform apply` deploys everything
- Phased deployment available but manual
- **PRO**: "Single pass full deployment" goal achieved
- **CON**: If one component fails, everything rolls back

**Option B: Phased by Default**
- Script orchestrates phased deployment with verification
- `./deploy.sh` runs all phases with checkpoints
- **PRO**: Validation at each layer, easier debugging
- **CON**: Longer deployment, more complex

**Option C: Configuration Choice**
```hcl
deployment_mode = "single_pass"  # or "phased" or "manual"
```
- **PRO**: Flexible for different use cases
- **CON**: More complex implementation

**My Recommendation**: **Option C** with default "phased" for safety, "single_pass" available for demonstration.

**QUESTION**: For initial sandbox deployment, which mode do you want as default?

---

## 7. VERIFICATION & SELF-CHECKING

### ✅ RECOMMENDED: Automated Verification Framework

**Decision**: Build **verification checkpoints** into every deployment component.

**Rationale from Best Practices**:
1. **Your Requirement**: "Always make sure what we deliver meets our requirements"
2. **Terraform Provisioners**: Can run verification scripts
3. **Kubernetes Readiness Probes**: Built-in health checking
4. **Testing MCP Server**: Agents can verify deployments

**Verification Layers**:

**1. Infrastructure Verification** (Terraform provisioners):
```hcl
resource "null_resource" "verify_gke" {
  provisioner "local-exec" {
    command = "python3 scripts/verify_gke.py"
  }
  depends_on = [module.gke]
}
```

**2. Application Readiness** (Kubernetes):
```yaml
readinessProbe:
  httpGet:
    path: /api/method/ping
    port: 8000
  initialDelaySeconds: 30
  periodSeconds: 10
```

**3. Functional Verification** (pytest):
```python
@pytest.mark.verification
def test_erpnext_api_accessible():
    response = requests.get(f"{ERPNEXT_URL}/api/method/ping")
    assert response.status_code == 200
```

**4. Integration Verification** (MCP tools):
```python
@mcp.tool()
def verify_full_stack():
    """Comprehensive verification of all components"""
    results = {
        "infrastructure": verify_infrastructure(),
        "database": verify_database_connectivity(),
        "erpnext": verify_erpnext_operational(),
        "n8n": verify_n8n_workflows(),
        "observability": verify_metrics_flowing(),
        "mcp_servers": verify_all_mcp_servers()
    }
    return results
```

---

### ✅ RECOMMENDED: Health Check Dashboard

**Decision**: Create **real-time health dashboard** showing verification status.

**Rationale from Best Practices**:
1. **Continuous Verification**: Not just at deployment, always
2. **Visual Status**: Quickly see what's working
3. **Demonstration Value**: Show self-awareness of system

**Grafana Health Dashboard**:
```
[System Health Overview]
┌─────────────────────────────────────────────────┐
│ Infrastructure:  ✅ Healthy (2/2 nodes ready)  │
│ Database:        ✅ Healthy (connections: 5/100)│
│ ERPNext:         ✅ Healthy (response: 45ms)    │
│ n8n:             ✅ Healthy (workflows: 12)     │
│ Observability:   ✅ Healthy (metrics flowing)   │
│ MCP Servers:     ⚠️  Partial (6/9 online)      │
│   - Sales:       ✅ Online                      │
│   - Purchasing:  ✅ Online                      │
│   - Inventory:   ✅ Online                      │
│   - Manufacturing: ❌ Offline                   │
│   - Accounting:  ✅ Online                      │
│   - HR:          ❌ Offline                     │
│   - Infrastructure: ✅ Online                   │
│   - Observability: ✅ Online                    │
│   - Testing:     ❌ Offline                     │
└─────────────────────────────────────────────────┘
```

---

## 8. INTERVIEW-DRIVEN CONFIGURATION

### ✅ RECOMMENDED: n8n Interview Workflows

**Decision**: Use **n8n workflows** to conduct stakeholder interviews and generate configuration.

**Rationale from Best Practices**:
1. **Visual Workflow Builder**: Stakeholders can see interview flow
2. **Form Support**: n8n has form nodes for data collection
3. **Conditional Logic**: Branch based on answers
4. **Template Generation**: Output configuration files
5. **Demonstration Value**: Show automation of configuration process

**Interview Workflow Pattern**:
```
[Interview Workflow: Sales Configuration]
1. Welcome Form Node
   - Company name
   - Industry vertical
   - Company size

2. Sales Process Questions
   - Lead sources (web, referral, cold call)
   - Quotation approval needed? (yes/no)
   - Standard payment terms
   - Product vs service sales

3. Conditional Branching
   - If product sales → inventory questions
   - If service sales → project questions

4. Generate Configuration
   - Create ERPNext company
   - Set up default price lists
   - Configure sales settings
   - Create customer groups
   - Set up territories

5. Deploy via MCP
   - Call sales MCP server to apply config
   - Verify configuration
   - Return success/errors

6. Confirmation & Next Steps
   - Show what was configured
   - Offer next interview (purchasing, inventory)
```

---

### ❓ YOUR DECISION NEEDED: Interview Format

**The Question**: How are stakeholder interviews conducted?

**Option A: Automated n8n Forms**
- Stakeholder fills web forms
- n8n processes answers
- Configuration deployed automatically
- **PRO**: Fully automated, scalable
- **CON**: Less interactive, may miss nuances

**Option B: Agent-Conducted Interviews**
- Claude (via MCP) asks questions conversationally
- Records answers
- Generates configuration
- **PRO**: Natural, can clarify, adapt questions
- **CON**: Requires agent availability

**Option C: Hybrid Template Selection**
- Stakeholder selects industry template
- Agent asks clarifying questions
- Fine-tunes configuration
- **PRO**: Fast baseline, customization available
- **CON**: Templates must exist first

**My Recommendation**: **Option C** - start with templates (manufacturing, retail, services), agent customizes.

**QUESTION**: Should interviews be synchronous (real-time with agent) or asynchronous (form-based)?

---

## 9. SCALE DEMONSTRATION

### ✅ RECOMMENDED: Configuration-Based Scale Profiles

**Decision**: Define **scale profiles** as terraform variables, demonstrate switching between them.

**Rationale from Best Practices**:
1. **Your Requirement**: "Start ma and pa, scale through automation"
2. **Terraform Workspaces**: Can manage multiple configurations
3. **Demonstration Value**: Show same system at different scales

**Scale Profile Definitions**:
```hcl
# small.tfvars (Ma & Pa Shop)
scale_profile = "small"
gke_node_count = 2
gke_node_type = "e2-small"
mariadb_storage = "20Gi"
redis_memory = "256Mi"
max_users = 5
enabled_modules = ["sales", "purchasing", "inventory", "accounting"]
```

```hcl
# medium.tfvars (Growing Business)
scale_profile = "medium"
gke_node_count = 5
gke_node_type = "e2-standard-4"
mariadb_storage = "100Gi"
redis_memory = "2Gi"
max_users = 50
enabled_modules = ["sales", "purchasing", "inventory", "manufacturing", "accounting", "hr"]
```

```hcl
# large.tfvars (Enterprise)
scale_profile = "large"
gke_node_count = 20
gke_node_type = "e2-standard-8"
mariadb_storage = "1Ti"
mariadb_replicas = 3  # HA setup
redis_memory = "8Gi"
redis_replicas = 3
max_users = 500
enabled_modules = "all"
high_availability = true
```

**Demonstration Flow**:
1. Deploy small profile
2. Run load tests simulating 5 users
3. Show metrics and performance
4. Scale to medium (terraform apply with new variables)
5. Run load tests with 50 users
6. Show auto-scaling, performance changes
7. Scale to large
8. Demonstrate enterprise features (HA, geographic distribution)

---

### ❓ YOUR DECISION NEEDED: Scale Testing Realism

**The Question**: Should scale testing simulate different company TYPES or just different user COUNTS?

**Option A: User Count Only**
- Same workflows, different concurrency
- 5 users vs 50 users doing same operations
- **PRO**: Simple, easy to measure
- **CON**: Doesn't reflect different business complexity

**Option B: Company Type Simulation**
- Small: Simple workflows (invoice, basic inventory)
- Medium: Added complexity (manufacturing, multi-warehouse)
- Large: Full complexity (multi-company, multi-currency, complex approval chains)
- **PRO**: Realistic, shows functionality scaling too
- **CON**: More complex to set up

**My Recommendation**: **Option B** - scale includes both user count AND workflow complexity.

**QUESTION**: Should we prepare distinct test scenarios per scale, or scale a single scenario?

---

## 10. COST OPTIMIZATION (Free Tier Maximization)

### ✅ RECOMMENDED: GCP Free Tier Strategy

**Decision**: Architect to **maximize GCP free tier** usage.

**Rationale**: You mentioned no budget for high-end services.

**Free Tier Components** (as of 2025):
```
GKE:
- 1 zonal cluster free
- $0.10/hour per cluster (eliminate with Autopilot)
- Use GKE Autopilot: No cluster management fee

Compute Engine:
- e2-micro: 1 instance free per month (US regions)
- 30GB standard persistent disk free
- Use for small profile

Cloud SQL:
- NOT included in free tier
- Alternative: Self-hosted MariaDB on GKE (free except compute)

Memorystore (Redis):
- NOT included in free tier
- Alternative: Self-hosted Redis on GKE (free except compute)

Cloud Monitoring:
- 150MB metrics ingestion/month free
- Send only essential metrics to stay under

Cloud Logging:
- 50GB logs/month free
- Use log exclusions for noisy logs

Cloud Storage:
- 5GB standard storage free
- Use for backups, terraform state

Networking:
- 1GB North America egress/month free
- Use internal networking where possible
```

**Cost-Optimized Architecture**:
```
Small Profile (targeting ~$10-20/month):
├── GKE Autopilot (no cluster fee)
├── 2x e2-small nodes (~$15/month)
├── Self-hosted MariaDB on GKE (StatefulSet)
├── Self-hosted Redis on GKE (StatefulSet)
├── Self-hosted Prometheus/Grafana/Loki
└── Cloud Storage for backups (~$0.50/month)

Medium Profile (~$50-100/month):
├── GKE Autopilot
├── 5x e2-standard-4 nodes
├── Still self-hosted databases
└── More Cloud Storage

Large Profile (demo only, not sustained):
├── Scale up for demonstration
├── Scale back down after demo
└── Use preemptible nodes (60-90% cheaper)
```

---

### ✅ RECOMMENDED: Self-Hosted Data Layer

**Decision**: Deploy **MariaDB and Redis as Kubernetes StatefulSets**, not managed services.

**Rationale from Best Practices**:
1. **Cost**: Cloud SQL starts at ~$50/month, self-hosted is compute-only
2. **ERPNext Compatibility**: Frappe Helm chart designed for both patterns
3. **Learning Value**: Demonstrates Kubernetes StatefulSet patterns
4. **Production Patterns**: Many companies run databases on Kubernetes now

**StatefulSet Pattern**:
- Persistent volumes for data
- Headless service for stable network identity
- Init containers for setup
- Backup jobs to Cloud Storage
- Can migrate to Cloud SQL later if needed

**Backup Strategy**:
```yaml
# CronJob for database backups
apiVersion: batch/v1
kind: CronJob
metadata:
  name: mariadb-backup
spec:
  schedule: "0 2 * * *"  # 2 AM daily
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: mariadb:10.6
            command:
            - /bin/sh
            - -c
            - mysqldump --all-databases | gzip | gsutil cp - gs://broad-backups/mariadb-$(date +%Y%m%d).sql.gz
```

---

## 11. HEALTHCARE WORKFLOW LIBRARY

### ✅ RECOMMENDED: Standards-Based Approach

**Decision**: Use certified healthcare standards (HL7 FHIR R4, BPMN 2.0, BPM+ Health) as foundation.

**Rationale from Best Practices**:
1. **HL7 FHIR**: Industry standard (89% adoption in healthcare IT)
2. **BPM+ Health**: OMG/HL7 certified methodology for shareable pathways
3. **Interoperability**: Enables data exchange with external systems
4. **Regulatory Compliance**: Aligns with ONC and CMS requirements
5. **Community Support**: Large ecosystem of tools and implementations

**Standards Coverage**:
- HL7 FHIR R4: Patient, Encounter, Observation, Procedure, Medication
- BPMN 2.0: Clinical pathways (prescriptive workflows)
- CMMN 1.1: Case management (chronic disease, care coordination)
- DMN 1.3: Clinical decision logic
- UDS+ FHIR IG: HRSA health center reporting
- GS1 Healthcare: Supply chain and operational processes

---

### ✅ RECOMMENDED: Modular Pathway Deployment

**Decision**: Enable/disable clinical pathways based on organization type configuration.

**Rationale from Best Practices**:
1. **Modularity Principle**: Aligns with BROAD "everything is modular" philosophy
2. **Progressive Deployment**: Start with essential pathways, add incrementally
3. **Organization-Specific**: Different needs for clinic vs hospital
4. **Cost Optimization**: Only deploy what's needed
5. **Complexity Management**: Easier to maintain and troubleshoot

**Configuration-Driven**:
```hcl
clinical_pathways = [
  "patient-admission",      # Essential for all
  "medication-ordering",    # Essential for all
  "lab-test-processing",    # Optional for small clinics
  "discharge-planning",     # Optional for outpatient-only
]
```

---

### ❓ YOUR DECISION NEEDED: Organization Type and Use Case

**The Challenge**: Healthcare workflows vary significantly by organization type. Need to know your target to prioritize implementation.

**Option A: Small Clinic**
- 1-5 providers, outpatient only
- Basic clinical pathways (admission, medication, lab)
- FHIR integration (basic)
- No federal reporting
- **PRO**: Simple, fast deployment, minimal cost
- **CON**: Limited functionality, no advanced features

**Option B: Community Health Center**
- 10-50 providers, FQHC designation
- Complete clinical pathways
- UDS+ reporting (REQUIRED by HRSA)
- Quality measure calculations
- FHIR integration (advanced)
- **PRO**: Meets federal requirements, comprehensive
- **CON**: More complex, ongoing reporting obligations

**Option C: Hospital (Acute Care)**
- 50+ providers, inpatient/outpatient
- Complete clinical pathway library
- GS1 supply chain integration
- Multi-department workflows
- Advanced FHIR interoperability
- **PRO**: Full functionality, enterprise-grade
- **CON**: Most complex, highest cost, longest deployment

**Option D: Multi-Organization Platform**
- Support all organization types
- Template-based configuration
- Enable features per organization
- **PRO**: Maximum flexibility, scalable business model
- **CON**: Most complex to build and maintain

**My Recommendation**: Start with **Option B** (Community Health Center) - it's comprehensive but focused, and UDS+ reporting provides clear requirements.

**QUESTION**: What is your target organization type? Is this for:
- [ ] Your own organization (specify type)
- [ ] A specific client (specify type)
- [ ] A SaaS platform (multi-organization)
- [ ] A demonstration/proof-of-concept

---

### ❓ YOUR DECISION NEEDED: FHIR Server Strategy

**The Challenge**: FHIR integration requires a FHIR server. Multiple deployment options exist.

**Option A: Deploy HAPI FHIR Server**
- Open-source FHIR server (most popular)
- Deploy on same GKE cluster
- Full control over configuration
- **PRO**: Complete control, free (except compute), proven solution
- **CON**: Additional infrastructure to manage, requires expertise
- **Cost**: ~$20-50/month (compute + storage)

**Option B: Use External FHIR Server**
- Commercial FHIR service (e.g., Azure FHIR, AWS HealthLake, Google Cloud Healthcare API)
- Managed service, no infrastructure
- **PRO**: Fully managed, enterprise support, compliance built-in
- **CON**: Ongoing cost, vendor lock-in, data egress fees
- **Cost**: $500-2000/month depending on volume

**Option C: Connect to Existing FHIR Server**
- Hospital/health system already has FHIR server
- Just configure connection
- **PRO**: No new infrastructure, leverages existing investment
- **CON**: Requires access/permissions, may have limitations

**Option D: Skip FHIR Integration Initially**
- Deploy clinical pathways without FHIR
- Add FHIR later when needed
- **PRO**: Simpler initial deployment, lower cost
- **CON**: No external interoperability, limits use cases

**My Recommendation**: **Option A** (HAPI FHIR) for full control and cost optimization, with fallback to **Option D** (skip initially) if budget is very tight.

**QUESTION**: What is your FHIR server strategy?
- [ ] Deploy HAPI FHIR on GKE
- [ ] Use managed FHIR service (specify: Azure/AWS/GCP)
- [ ] Connect to existing FHIR server (provide details)
- [ ] Skip FHIR integration for now

---

### ❓ YOUR DECISION NEEDED: UDS+ Reporting Requirements

**The Challenge**: UDS+ reporting is mandatory for HRSA-funded health centers but not applicable to other organizations.

**Context**:
- HRSA requires Federally Qualified Health Centers (FQHCs) to submit UDS+ data
- Transition from legacy UDS to FHIR-based UDS+ underway (2024-2026)
- Significant compliance burden if required
- Zero value if not applicable

**Option A: Enable UDS+ Reporting**
- Full UDS+ FHIR IG implementation
- Table 6A (diagnoses and services) workflows
- Table 6B (quality measures) calculations
- Automated monthly submissions
- **PRO**: Regulatory compliance, automated reporting
- **CON**: Complex implementation, ongoing maintenance
- **Applicable**: Only if you're an FQHC/health center

**Option B: Skip UDS+ Reporting**
- No UDS+ specific workflows
- Framework remains available for future
- **PRO**: Simpler deployment, lower cost
- **CON**: Not compliant if you're an FQHC
- **Applicable**: Non-FQHC organizations

**My Recommendation**: **Option B** (skip) unless you explicitly need it for HRSA compliance.

**QUESTION**: Do you need UDS+ reporting?
- [ ] Yes - we are an FQHC/health center with HRSA reporting requirements
- [ ] No - we are not federally funded
- [ ] Unsure - provide Health Center ID or funding source

---

### ❓ YOUR DECISION NEEDED: GS1 Supply Chain Integration

**The Challenge**: GS1 integration requires barcode scanners and process changes. Benefit varies by organization size.

**Context**:
- GS1 Healthcare standards cover 24 hospital processes
- Improves patient safety (medication administration)
- Enables recall management
- Requires hardware (barcode scanners)
- Requires workflow training

**Option A: Full GS1 Integration**
- All 24 hospital processes
- GTIN/barcode tracking
- Medication administration (5 rights checking)
- Inventory receiving workflows
- Recall management
- **PRO**: Maximum patient safety, full traceability
- **CON**: Requires hardware, significant training, process changes
- **Best For**: Hospitals, large clinics

**Option B: Selective GS1 Integration**
- Only critical processes (medication administration, recalls)
- Limited scope, easier deployment
- **PRO**: Key safety benefits, lower complexity
- **CON**: Missing some operational efficiencies
- **Best For**: Medium-sized clinics

**Option C: Skip GS1 Integration**
- No barcode/GTIN integration
- Manual processes remain
- **PRO**: Simpler deployment, no hardware required
- **CON**: Missed patient safety improvements
- **Best For**: Small clinics, outpatient-only

**My Recommendation**: **Option C** (skip) for initial deployment, add later if needed.

**QUESTION**: Do you want GS1 supply chain integration?
- [ ] Yes - full integration (hospital/large clinic)
- [ ] Yes - selective (medication admin + recalls only)
- [ ] No - skip for now
- [ ] Unsure - describe your supply chain processes

---

### ❓ YOUR DECISION NEEDED: Clinical Pathway Customization

**The Challenge**: Standard pathways may not match your organization's specific protocols.

**Option A: Use Standard Pathways Only**
- BPM+ Health community pathways
- No customization
- Deploy as-is
- **PRO**: Fast deployment, proven pathways, shareable
- **CON**: May not match your exact processes
- **When**: You want to adopt best practices, willing to change processes

**Option B: Customize Standard Pathways**
- Start with standards
- Modify to match your protocols
- Maintain customized versions
- **PRO**: Matches your processes exactly
- **CON**: More complex, harder to update, not shareable
- **When**: You have established protocols you can't change

**Option C: Import Your Own BPMN Pathways**
- You create BPMN definitions
- Import via MCP tools
- Full control
- **PRO**: Complete flexibility, matches organization
- **CON**: Requires BPMN expertise, time investment
- **When**: You have clinical informatics team, specific requirements

**Option D: Hybrid Approach**
- Use standards for common pathways
- Customize or create for unique needs
- **PRO**: Best of both worlds
- **CON**: More to manage
- **When**: Mix of standard and specialized care

**My Recommendation**: **Option A** (standards only) initially, evolve to **Option D** (hybrid) based on feedback.

**QUESTION**: How will you approach clinical pathways?
- [ ] Use standard pathways only
- [ ] Customize standard pathways (describe customizations needed)
- [ ] Import our own BPMN pathways (we have clinical informatics expertise)
- [ ] Hybrid approach

---

### ❓ YOUR DECISION NEEDED: PHI Handling and De-Identification

**The Challenge**: FHIR sync and external integrations involve Protected Health Information (PHI). Need clear data handling policy.

**Option A: Full PHI in FHIR (With Proper Security)**
- FHIR resources contain identifiable patient data
- Enables complete clinical interoperability
- Requires HIPAA compliance, encryption, access controls
- **PRO**: Full functionality, complete data exchange
- **CON**: Higher security requirements, compliance burden
- **When**: Internal FHIR server, proper security infrastructure

**Option B: De-Identified Data Only**
- Strip PHI before FHIR sync
- Safe Harbor or Expert Determination method
- Research/quality improvement focus
- **PRO**: Lower compliance burden, safer
- **CON**: Limited interoperability, can't use for patient care
- **When**: Research use case, external FHIR servers

**Option C: Limited Data Set**
- Remove direct identifiers, keep dates/geography
- Meets HIPAA limited data set requirements
- Data use agreement required
- **PRO**: Balance of utility and privacy
- **CON**: Still requires compliance measures
- **When**: Quality improvement, limited external sharing

**Option D: No PHI in FHIR**
- Only aggregate data, no patient-level
- Reporting/analytics only
- **PRO**: Minimal compliance risk
- **CON**: Very limited functionality
- **When**: Public reporting only

**My Recommendation**: **Option A** (full PHI with security) for internal use, **Option C** (limited data set) for external sharing.

**QUESTION**: How will you handle PHI in FHIR integration?
- [ ] Full PHI with proper security (internal use)
- [ ] De-identified data only (research/QI)
- [ ] Limited data set (with data use agreements)
- [ ] No PHI (aggregate data only)
- [ ] Describe your specific compliance requirements

---

### ✅ RECOMMENDED: Incremental Deployment Strategy

**Decision**: Deploy healthcare workflows in phases, starting with core pathways.

**Rationale from Best Practices**:
1. **Risk Management**: Validate each component before adding complexity
2. **Learning Curve**: Staff needs time to adapt to new workflows
3. **Technical Validation**: Ensure FHIR sync works before adding pathways
4. **Cost Control**: Spread implementation costs over time

**Recommended Phases**:
```
Phase 1: FHIR Foundation (Week 1-2)
- Deploy FHIR server (if applicable)
- Configure Patient and Encounter mappings
- Test bidirectional sync
- Verify data quality

Phase 2: Core Clinical Pathways (Week 3-4)
- Deploy patient admission workflow
- Deploy medication ordering workflow
- Train staff on new processes
- Monitor execution, fix issues

Phase 3: Additional Pathways (Week 5-6)
- Add lab test processing
- Add discharge planning
- Add organization-specific pathways

Phase 4: Reporting and Advanced Features (Week 7-8)
- Enable UDS+ reporting (if applicable)
- Add GS1 integration (if applicable)
- Quality measure calculations
- Optimization and tuning
```

---

### ❓ YOUR DECISION NEEDED: Initial Deployment Timeline

**The Challenge**: Balance between speed to value and thoroughness.

**Option A: Aggressive (4 weeks)**
- Deploy all core components at once
- Parallel workstreams
- Minimal testing between phases
- **PRO**: Fast time to value
- **CON**: Higher risk, less validation
- **When**: Urgent need, experienced team

**Option B: Moderate (8 weeks)**
- Follow recommended phases above
- Sequential deployment with validation
- Adequate testing between phases
- **PRO**: Balanced risk/speed
- **CON**: Longer to full functionality
- **When**: Normal business case, recommended approach

**Option C: Conservative (12+ weeks)**
- Extended testing at each phase
- Pilot programs before rollout
- Comprehensive training
- **PRO**: Lowest risk, highest quality
- **CON**: Slow time to value
- **When**: Risk-averse organization, complex environment

**My Recommendation**: **Option B** (8 weeks) for good balance of speed and safety.

**QUESTION**: What is your preferred deployment timeline?
- [ ] Aggressive (4 weeks) - we need this quickly
- [ ] Moderate (8 weeks) - recommended approach
- [ ] Conservative (12+ weeks) - minimize risk
- [ ] Describe your specific timeline constraints

---

### ❓ YOUR DECISION NEEDED: Terminology Services

**The Challenge**: FHIR uses standard terminologies (SNOMED CT, LOINC, RxNorm). These require licensing and/or deployment.

**Option A: Deploy Terminology Service**
- Self-hosted terminology server (e.g., Ontoserver, HAPI FHIR)
- Contains SNOMED CT, LOINC, RxNorm
- **PRO**: Complete control, full functionality
- **CON**: Licensing costs (SNOMED ~$500-2000/year), infrastructure
- **Cost**: $500-3000/year (licensing + compute)

**Option B: Use External Terminology Service**
- NIH Value Set Authority Center (VSAC)
- Cloud-based terminology services
- **PRO**: Managed, no infrastructure
- **CON**: API limits, potential costs, external dependency

**Option C: Embedded Terminology (Limited)**
- Small subset of codes embedded in application
- Only codes you actually use
- **PRO**: Simple, no licensing for small sets
- **CON**: Limited coverage, manual maintenance
- **When**: Small clinic with limited code usage

**Option D: Skip Terminology Services Initially**
- Use free-text or simple codes
- Add proper terminology later
- **PRO**: Simplest initial deployment
- **CON**: Not fully FHIR compliant, limits interoperability

**My Recommendation**: **Option C** (embedded limited) for small deployments, **Option A** (full service) for hospitals.

**QUESTION**: How will you handle clinical terminologies?
- [ ] Deploy full terminology service (SNOMED + LOINC + RxNorm)
- [ ] Use external terminology service
- [ ] Embedded limited terminology (small code sets)
- [ ] Skip for now (we'll add later)

---

## SUMMARY: DECISIONS NEEDED FROM YOU

### Critical Path Decisions (need these to proceed):

**BROAD Platform Core** (Sections 1-10):

1. **Terraform Safety Model** (Section 2): How should agents interact with terraform? Templates, approval workflow, tiered access, or sandbox-only?

2. **Observability Granularity** (Section 4): 100% tracing or intelligent sampling for cost/performance?

3. **Test Data Strategy** (Section 5): Synthetic, template-based, anonymized, or hybrid?

4. **Deployment Mode Default** (Section 6): Single-pass, phased, or configurable?

5. **Interview Format** (Section 8): Automated forms, agent-conducted, or hybrid template selection? Synchronous or asynchronous?

6. **Scale Testing Realism** (Section 9): User count only, or company type simulation with different workflows?

**Healthcare Workflow Library** (Section 11 - NEW):

7. **Organization Type** (Section 11): Small clinic, community health center, hospital, or multi-organization platform?

8. **FHIR Server Strategy** (Section 11): Deploy HAPI FHIR, use managed service, connect to existing, or skip initially?

9. **UDS+ Reporting** (Section 11): Enable (FQHC/health center) or skip (non-FQHC)?

10. **GS1 Supply Chain** (Section 11): Full integration, selective (medication admin only), or skip?

11. **Clinical Pathway Customization** (Section 11): Use standards only, customize, import your own, or hybrid?

12. **PHI Handling** (Section 11): Full PHI with security, de-identified only, limited data set, or no PHI?

13. **Deployment Timeline** (Section 11): Aggressive (4 weeks), moderate (8 weeks), or conservative (12+ weeks)?

14. **Terminology Services** (Section 11): Deploy full service, use external, embedded limited, or skip?

### Nice-to-Have Clarifications:

15. **OAuth Timing**: Full OAuth2 from start or API keys for initial demo?

16. **Industry Vertical Preferences**: Which industries for demonstration templates (manufacturing, retail, services, healthcare, etc.)?

---

## RECOMMENDED DECISIONS SUMMARY

Everything else is answered with rationale:

**BROAD Platform Core**:
- ✅ Multiple domain-aligned MCP servers
- ✅ Stateless server design
- ✅ HTTP/SSE transport for production
- ✅ OAuth2 with dynamic registration
- ✅ GCS terraform state with locking
- ✅ n8n dual role (automation + MCP exposure)
- ✅ n8n on same GKE cluster
- ✅ Hybrid observability (OTel + Prometheus + Grafana + Cloud Monitoring)
- ✅ Domain-specific Grafana dashboards
- ✅ OpenTelemetry instrumentation
- ✅ k6 for load testing
- ✅ pytest for functional testing
- ✅ Dedicated testing MCP server
- ✅ Hierarchical terraform modules
- ✅ Phased deployment targets
- ✅ Automated verification framework
- ✅ Health check dashboard
- ✅ n8n interview workflows
- ✅ Configuration-based scale profiles
- ✅ Free tier maximization strategy
- ✅ Self-hosted databases on GKE

**Healthcare Workflow Library** (NEW):
- ✅ Standards-based approach (HL7 FHIR R4, BPMN 2.0, BPM+ Health)
- ✅ Modular pathway deployment (enable/disable by configuration)
- ✅ Incremental deployment strategy (phased approach)
- ✅ Healthcare Workflows MCP Server (new cross-cutting server)
- ✅ FHIR mapping framework (Patient, Encounter, extensible)
- ✅ BPMN → n8n conversion pipeline
- ✅ n8n workflow templates (FHIR sync, clinical pathways)
- ✅ Integration with existing BROAD architecture

---

**Next Step**:

1. **Review Healthcare Workflow Library deliverables** (see HEALTHCARE_WORKFLOW_LIBRARY_SUMMARY.md)
2. **Answer the 14 critical decisions** (6 BROAD core + 8 healthcare-specific)
3. **Begin terraform module implementation** for chosen configuration

**Note**: Healthcare workflow library can be deployed independently after core BROAD infrastructure, or as part of initial deployment.
