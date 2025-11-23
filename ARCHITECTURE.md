# BROAD Architecture Philosophy

## Design Principles

### 1. Everything is Observable
Every component exposes real-time metrics, logs, and traces. Every business operation is visible from transaction to infrastructure.

### 2. Everything is Verifiable
Every deployment, configuration, and operation has automated verification. Self-testing and self-validation at every layer.

### 3. Everything is Configurable
Template-driven configuration with stakeholder interview process. 75% functional out-of-box, 100% customizable.

### 4. Everything is Modular
Start small (ma and pa shop), scale via configuration. Each module independently deployable, testable, observable.

### 5. Everything is Exposed via MCP
Agents can deploy, configure, test, observe, and manage the entire system. Infrastructure, application, and business layers all accessible.

## System Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    Agentic Interface                        │
│              (MCP Servers - Agent Access)                   │
├─────────────────────────────────────────────────────────────┤
│                Healthcare Workflow Library                  │  ← NEW
│   (FHIR R4 ↔ ERPNext | BPMN/CMMN/DMN → n8n Workflows)      │
│   (Standardized Clinical Pathways | UDS+ Reporting)        │
├─────────────────────────────────────────────────────────────┤
│                   Business Operations                       │
│         (ERPNext Healthcare + Standard Modules)             │
├─────────────────────────────────────────────────────────────┤
│                 Orchestration Layer                         │
│           (n8n, Workflow Automation)                        │
├─────────────────────────────────────────────────────────────┤
│                  Observability Layer                        │
│    (OpenTelemetry, Prometheus, Grafana, Loki, Tempo)       │
├─────────────────────────────────────────────────────────────┤
│                   Application Layer                         │
│              (ERPNext on Kubernetes)                        │
├─────────────────────────────────────────────────────────────┤
│                  Infrastructure Layer                       │
│         (GKE, Storage, Networking - via Terraform)          │
└─────────────────────────────────────────────────────────────┘
```

## MCP Architecture (DESIGN IN PROGRESS)

### Proposed: Domain-Aligned MCP Servers

Each business domain gets a unified MCP server exposing:
- **Business Operations**: ERPNext DocType CRUD, custom business logic
- **Workflows**: n8n workflow templates for domain
- **Observability**: Domain-specific metrics, dashboards, alerts
- **Testing**: Functional and load tests for domain operations
- **Configuration**: Interview-driven setup for domain

### Domain Structure

```
MCP Servers by Business Domain:
├── Sales & CRM
│   ├── ERPNext: Lead, Opportunity, Quotation, Sales Order, Customer
│   ├── n8n: Lead nurturing, order processing workflows
│   ├── Metrics: Conversion rates, order volume, revenue
│   └── Tests: Order creation, customer management flows
│
├── Purchasing & Procurement
│   ├── ERPNext: Supplier, Purchase Order, Purchase Receipt
│   ├── n8n: PO approval, supplier notification workflows
│   ├── Metrics: Purchase cycle time, supplier performance
│   └── Tests: PO creation, approval workflows
│
├── Inventory & Warehouse
│   ├── ERPNext: Item, Stock Entry, Material Request, Warehouse
│   ├── n8n: Reorder automation, stock alerts
│   ├── Metrics: Stock levels, turnover, movement
│   └── Tests: Stock transactions, warehouse operations
│
├── Manufacturing & Production
│   ├── ERPNext: BOM, Work Order, Production Plan
│   ├── n8n: Production scheduling, material planning
│   ├── Metrics: Production efficiency, capacity utilization
│   └── Tests: Work order processing, BOM validation
│
├── Accounting & Finance
│   ├── ERPNext: Journal Entry, Payment Entry, GL Entry
│   ├── n8n: Invoice processing, payment reconciliation
│   ├── Metrics: Cash flow, AR/AP aging, financial ratios
│   └── Tests: Transaction posting, reconciliation
│
├── Human Resources
│   ├── ERPNext: Employee, Attendance, Payroll Entry
│   ├── n8n: Onboarding, attendance processing
│   ├── Metrics: Headcount, attendance rates, payroll
│   └── Tests: Employee lifecycle, payroll processing
│
└── Infrastructure & Platform
    ├── Terraform: Deploy, configure, scale infrastructure
    ├── n8n: Deployment workflows, backup automation
    ├── Metrics: Resource utilization, costs, availability
    └── Tests: Deployment verification, disaster recovery
```

### Cross-Cutting MCP Servers

```
Platform Services:
├── Observability Server
│   ├── Query metrics across all domains
│   ├── Fetch logs and traces
│   ├── Trigger alerts
│   └── Generate reports
│
├── Testing Orchestration Server
│   ├── Execute test suites
│   ├── Load test scenarios
│   ├── Validation frameworks
│   └── Results aggregation
│
├── Configuration Management Server
│   ├── Interview workflows
│   ├── Template management
│   ├── Deployment orchestration
│   └── Verification checkpoints
│
└── Healthcare Workflow Library Server (NEW)
    ├── Deploy clinical pathways (BPMN → n8n)
    ├── Manage FHIR integration (bidirectional sync)
    ├── Import/export healthcare standards
    ├── Configure UDS+ reporting
    ├── Validate FHIR mappings
    └── Query available pathways and standards
```

## Healthcare Workflow Library

### Purpose

The Healthcare Workflow Library addresses the critical need for standardized, machine-readable healthcare processes by integrating certified healthcare standards with executable n8n workflows.

### Standards Coverage

**HL7 FHIR R4 (Interoperability)**:
- Patient, Encounter, Observation, Procedure, Medication resources
- Bidirectional sync with ERPNext Healthcare
- Terminology services (SNOMED CT, LOINC, RxNorm)
- External system interoperability

**BPM+ Health (Clinical Pathways)**:
- BPMN 2.0: Prescriptive clinical workflows
- CMMN 1.1: Case management for chronic disease
- DMN 1.3: Clinical decision logic (dosing, alerts)
- Shareable pathways across institutions

**UDS+ FHIR IG (Federal Reporting)**:
- HRSA health center reporting requirements
- Table 6A/6B data collection and submission
- Quality measure calculations (eCQMs)
- De-identified patient-level data

**GS1 Healthcare (Supply Chain)**:
- 24 standardized hospital processes
- GTIN/barcode integration
- Medication administration safety
- Recall management workflows

### Architecture

```
Healthcare Workflow Library
├── Standards Layer
│   ├── FHIR Profiles & Mappings (ERPNext ↔ FHIR)
│   ├── BPMN Clinical Pathways (shareable workflows)
│   ├── DMN Decision Tables (clinical logic)
│   └── GS1 Process Maps (operational workflows)
│
├── Conversion Layer
│   ├── BPMN → n8n Converter
│   ├── DMN → n8n Function Nodes
│   └── CMMN → n8n Case Workflows
│
├── Execution Layer
│   ├── n8n Workflow Templates
│   │   ├── FHIR Integration Workflows
│   │   ├── Clinical Pathway Workflows
│   │   ├── Operational Workflows (GS1)
│   │   └── Reporting Workflows (UDS+)
│   └── ERPNext Healthcare Operations
│
└── MCP Exposure Layer
    └── Healthcare Workflows MCP Server
        ├── deploy_clinical_pathway()
        ├── sync_fhir_resources()
        ├── import_bpmn_pathway()
        ├── configure_uds_reporting()
        └── validate_fhir_mapping()
```

### Integration Points

**With ERPNext Healthcare**:
- FHIR mappings for Patient, Encounter, Vital Signs, Lab Tests
- Webhook triggers for real-time workflow execution
- API-based DocType operations

**With n8n**:
- Automated deployment of workflow templates
- BPMN-to-n8n conversion for clinical pathways
- Execution monitoring via n8n API

**With Observability Stack**:
- OpenTelemetry instrumentation for all workflows
- Custom Grafana dashboards for clinical pathways
- Metrics: pathway execution rate, duration, errors, FHIR sync status

**With MCP Layer**:
- New MCP server: `mcp-healthcare-workflows`
- Agent-accessible tools for pathway deployment
- Integration with domain MCP servers

### Use Cases

**Community Health Center**:
```yaml
deployment: community-health-center
enabled_features:
  - uds_plus_reporting: true
  - clinical_pathways: [patient-admission, medication-ordering]
  - fhir_integration: true
reporting_schedule: monthly
```

**Small Clinic**:
```yaml
deployment: basic-clinic
enabled_features:
  - clinical_pathways: [patient-admission, lab-test-processing]
  - fhir_integration: basic
reporting_schedule: none
```

**Hospital**:
```yaml
deployment: hospital
enabled_features:
  - clinical_pathways: all
  - fhir_integration: advanced
  - gs1_supply_chain: true
  - uds_plus_reporting: true (if applicable)
reporting_schedule: monthly
```

### Modular Deployment

The workflow library follows BROAD's modular deployment philosophy:

```hcl
# terraform.tfvars
healthcare_workflows = {
  enabled = true

  # FHIR integration
  fhir_server = "external"  # or "deploy" for HAPI FHIR
  fhir_resources = ["Patient", "Encounter", "Observation"]
  sync_direction = "bidirectional"

  # Clinical pathways
  clinical_pathways = [
    "patient-admission",
    "medication-ordering",
    "lab-test-processing",
    "discharge-planning"
  ]

  # Operational workflows
  gs1_integration = false

  # Reporting
  uds_plus_enabled = false
  quality_measures_enabled = false
}
```

### Verification

**FHIR Integration Verification**:
- FHIR mapping validation tests
- Bidirectional sync verification
- Resource conformance validation

**Clinical Pathway Verification**:
- BPMN conversion correctness
- n8n workflow execution tests
- End-to-end pathway validation

**Compliance Verification**:
- UDS+ submission validation
- Quality measure calculation accuracy
- FHIR IG conformance testing

### Documentation

See `healthcare-workflow-library/` for detailed documentation:
- `README.md` - Overview and quick start
- `WORKFLOW_LIBRARY_DESIGN.md` - Complete design document
- `docs/implementation-guide.md` - Deployment instructions
- `docs/fhir-integration.md` - FHIR setup guide
- `docs/clinical-pathway-guide.md` - BPM+ implementation
- `docs/uds-reporting.md` - UDS+ configuration

## Deployment Model

### Phase 1: Infrastructure Foundation
```bash
terraform apply -target=module.gke
terraform apply -target=module.networking
terraform apply -target=module.storage
# Verification: Can cluster be reached? Storage accessible?
```

### Phase 2: Platform Services
```bash
terraform apply -target=module.observability
terraform apply -target=module.database
terraform apply -target=module.redis
# Verification: Prometheus scraping? Database accepting connections?
```

### Phase 3: Application Layer
```bash
terraform apply -target=module.erpnext
terraform apply -target=module.n8n
# Verification: ERPNext reachable? n8n workflows deployable?
```

### Phase 4: Agentic Layer
```bash
terraform apply -target=module.mcp_servers
# Verification: MCP servers responding? Tools registered?
```

### Phase 5: Healthcare Workflow Library (Optional)
```bash
terraform apply -target=module.healthcare_workflow_library
# Deploy FHIR server (if enabled)
# Deploy workflow library MCP server
# Deploy initial clinical pathways
# Verification: FHIR server accessible? Pathways deployed? MCP tools available?
```

### Phase 6: Business Configuration
```
# Automated interview process per domain
# Template deployment per vertical (including healthcare)
# Functional verification per module
# Configure healthcare workflows based on organization type
```

### Phase 7: Full Integration Test
```
# Multi-domain workflows
# Healthcare pathway execution tests
# FHIR integration validation
# Scale testing
# End-to-end business process validation
```

## Verification Strategy

### Self-Checking at Every Layer

**Infrastructure Verification**:
- Kubernetes cluster healthy
- Nodes ready, pods running
- Network policies enforced
- Storage provisioned and accessible

**Platform Verification**:
- Database connections successful
- Redis queues operational
- Observability stack collecting metrics
- Grafana dashboards rendering

**Application Verification**:
- ERPNext site accessible
- API endpoints responding
- Background workers processing
- n8n workflows executable

**Business Function Verification**:
- Each DocType CRUD operations working
- Workflows triggering correctly
- Data validation enforcing rules
- Reports generating accurately

**Integration Verification**:
- Cross-module operations (Sales Order → Delivery → Invoice)
- n8n triggering ERPNext operations
- MCP servers exposing all functionality
- Observability capturing all transactions

## Modular Scaling Approach

### Configuration-Driven Scale

**Small (Ma & Pa Shop)**:
```yaml
scale: small
users: 5
modules: [sales, purchasing, inventory, accounting]
features:
  - basic_invoicing
  - simple_inventory
  - cash_accounting
resources:
  gke_nodes: 2
  mariadb_size: small
  redis_instances: 1
```

**Medium (Growing Business)**:
```yaml
scale: medium
users: 50
modules: [sales, purchasing, inventory, manufacturing, accounting, hr]
features:
  - advanced_inventory
  - production_planning
  - multi_currency
  - employee_management
resources:
  gke_nodes: 5
  mariadb_size: medium
  redis_instances: 3
```

**Large (Enterprise)**:
```yaml
scale: large
users: 500
modules: all
features: all
resources:
  gke_nodes: 20
  mariadb_size: large
  redis_instances: 3
  high_availability: true
```

## Open Questions for Design

1. **MCP Server Deployment**: Each domain server as separate pod/service, or unified MCP gateway routing to domain handlers?

2. **State Management**: MCP servers stateless (query ERPNext each time) or maintain cached state?

3. **Authentication Flow**: Single OAuth for all MCP servers or per-server auth?

4. **Terraform MCP Exposure**: Direct terraform operations via MCP (risky) or pre-approved operation templates?

5. **Testing MCP Integration**: Tests callable via MCP tools or separate CI/CD pipeline?

6. **Inter-Domain Communication**: MCP servers call each other directly or through n8n orchestration?

7. **Observability Access Pattern**: Real-time query via MCP or pre-computed dashboards?

## Next Design Decisions Needed

- Finalize MCP server architecture (domain-aligned vs layer-aligned)
- Define MCP tool naming conventions and schemas
- Design verification checkpoint framework
- Create terraform module structure
- Define interview template format
