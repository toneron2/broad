# Healthcare Workflow Library Design

## Overview

The Healthcare Workflow Library is a critical integration layer in the BROAD architecture that maps certified healthcare standards (HL7 FHIR, BPM+, BPMN, CMMN, DMN, GS1) to executable n8n workflows, connecting ERPNext business operations with standardized healthcare processes.

## Purpose

1. **Standardization**: Use certified, machine-readable healthcare process standards
2. **Interoperability**: Enable data exchange via HL7 FHIR R4
3. **Automation**: Convert clinical pathways into executable n8n workflows
4. **Modularity**: Deploy workflows based on enabled healthcare domains
5. **Observability**: Full tracking of healthcare process execution
6. **Compliance**: Support regulatory reporting (UDS+, quality measures)

## Architecture Integration

```
┌─────────────────────────────────────────────────────────────┐
│                    Agentic Interface                        │
│              (MCP Servers - Agent Access)                   │
├─────────────────────────────────────────────────────────────┤
│                 Healthcare Workflow Library                 │  ← NEW LAYER
│   (BPMN/CMMN/DMN Definitions → n8n Workflows)              │
│   (FHIR Resources ↔ ERPNext DocTypes)                       │
├─────────────────────────────────────────────────────────────┤
│                   Business Operations                       │
│         (ERPNext Healthcare + n8n Workflows)                │
├─────────────────────────────────────────────────────────────┤
│                 Orchestration Layer                         │
│           (n8n, Workflow Automation)                        │
├─────────────────────────────────────────────────────────────┤
│                  Observability Layer                        │
│    (OpenTelemetry, Prometheus, Grafana, Loki, Tempo)       │
├─────────────────────────────────────────────────────────────┤
│                   Application Layer                         │
│              (ERPNext Healthcare on Kubernetes)             │
├─────────────────────────────────────────────────────────────┤
│                  Infrastructure Layer                       │
│         (GKE, Storage, Networking - via Terraform)          │
└─────────────────────────────────────────────────────────────┘
```

## Healthcare Standards Coverage

### 1. HL7 FHIR R4 (Fast Healthcare Interoperability Resources)

**Purpose**: Modern standard for healthcare data exchange

**Key Resources Mapped**:
- Patient → ERPNext Patient
- Encounter → ERPNext Patient Encounter
- Observation → ERPNext Vital Signs, Lab Test
- Procedure → ERPNext Clinical Procedure
- MedicationRequest → ERPNext Medication Order
- Appointment → ERPNext Patient Appointment
- Condition → ERPNext Diagnosis
- ServiceRequest → ERPNext Lab Test Template

**Implementation**:
- FHIR API endpoint (HAPI FHIR server or custom)
- Bidirectional sync with ERPNext via n8n workflows
- FHIR resource validation
- Terminology services (SNOMED CT, LOINC, RxNorm)

### 2. BPM+ Health (BPMN, CMMN, DMN)

**Purpose**: Standardized clinical pathway modeling

**BPMN (Business Process Model and Notation)**:
- Prescriptive clinical workflows
- Sequential process steps
- Example: Patient admission → triage → assessment → treatment → discharge

**CMMN (Case Management Model and Notation)**:
- Reactive, unstructured activities
- Knowledge-intensive processes
- Example: Chronic disease management, care coordination

**DMN (Decision Model and Notation)**:
- Clinical decision logic in table format
- Rule-based automation
- Example: Medication dosing rules, risk stratification

**Implementation**:
- BPMN XML definitions → n8n workflow conversion
- DMN decision tables → n8n function nodes
- CMMN case models → n8n case management workflows

### 3. UDS+ FHIR Implementation Guide (HRSA Reporting)

**Purpose**: Federal reporting for health centers

**Coverage**:
- Table 6A: Diagnoses and Services Rendered
- Table 6B: Quality of Care Measures
- Demographic data collection
- De-identified patient-level submission

**Implementation**:
- ERPNext data aggregation workflows
- FHIR R4 API submission to HRSA
- Quality measure calculation (eCQMs)
- Automated reporting schedules

### 4. GS1 Healthcare Standards

**Purpose**: Supply chain, inventory, and patient safety

**Key Processes**:
- Clinical: Medication Administration, Charge Capture, Physician Order Entry
- Operational: Purchasing, Inventory Management, Receiving, Recalls
- Financial: Item tracking, billing integration

**Implementation**:
- GTIN (Global Trade Item Number) integration
- Barcode scanning workflows
- GDSN (Global Data Synchronization Network) attribute mapping
- Recall management workflows

## Workflow Library Structure

```
healthcare-workflow-library/
├── README.md
├── standards/
│   ├── fhir/
│   │   ├── profiles/                      # FHIR profiles for customization
│   │   │   ├── Patient.json
│   │   │   ├── Encounter.json
│   │   │   └── ...
│   │   ├── mappings/                      # FHIR ↔ ERPNext mappings
│   │   │   ├── patient-mapping.yaml
│   │   │   ├── encounter-mapping.yaml
│   │   │   └── ...
│   │   └── terminology/                   # Value sets, code systems
│   │       ├── snomed-ct-subset.json
│   │       ├── loinc-lab-codes.json
│   │       └── rxnorm-medications.json
│   ├── bpmn/
│   │   ├── clinical-pathways/            # Shareable clinical pathways
│   │   │   ├── patient-admission.bpmn
│   │   │   ├── medication-ordering.bpmn
│   │   │   ├── lab-test-workflow.bpmn
│   │   │   └── discharge-planning.bpmn
│   │   └── operational/                  # GS1 operational processes
│   │       ├── inventory-receiving.bpmn
│   │       ├── medication-administration.bpmn
│   │       └── recall-management.bpmn
│   ├── cmmn/
│   │   ├── chronic-disease-management.cmmn
│   │   ├── care-coordination.cmmn
│   │   └── patient-case-management.cmmn
│   ├── dmn/
│   │   ├── medication-dosing-rules.dmn
│   │   ├── risk-stratification.dmn
│   │   ├── lab-alert-thresholds.dmn
│   │   └── quality-measure-logic.dmn
│   └── gs1/
│       ├── gtin-attributes.yaml          # GS1 GDSN attributes
│       ├── process-map.yaml              # 24 hospital processes
│       └── barcode-formats.yaml
├── n8n-workflows/
│   ├── fhir-integration/
│   │   ├── patient-sync.json             # Bi-directional Patient sync
│   │   ├── encounter-create.json         # Create FHIR Encounter from ERPNext
│   │   ├── observation-import.json       # Import lab results as FHIR Observations
│   │   └── medication-order-sync.json
│   ├── clinical-workflows/
│   │   ├── patient-admission/
│   │   │   ├── workflow.json             # n8n workflow
│   │   │   ├── metadata.yaml             # BPMN source, description
│   │   │   └── test-data.json            # Test scenarios
│   │   ├── medication-ordering/
│   │   │   ├── workflow.json
│   │   │   ├── decision-logic.js         # DMN implementation
│   │   │   └── metadata.yaml
│   │   ├── lab-test-processing/
│   │   │   ├── workflow.json
│   │   │   └── metadata.yaml
│   │   └── discharge-planning/
│   │       ├── workflow.json
│   │       └── metadata.yaml
│   ├── operational-workflows/
│   │   ├── inventory-receiving/
│   │   │   ├── workflow.json
│   │   │   └── gs1-barcode-scan.js
│   │   ├── medication-administration/
│   │   │   ├── workflow.json
│   │   │   └── five-rights-check.js      # Patient safety checks
│   │   └── recall-management/
│   │       ├── workflow.json
│   │       └── affected-items-query.js
│   ├── reporting-workflows/
│   │   ├── uds-plus/
│   │   │   ├── table-6a-data-collection.json
│   │   │   ├── table-6b-quality-measures.json
│   │   │   ├── fhir-bundle-generation.json
│   │   │   └── hrsa-submission.json
│   │   └── quality-measures/
│   │       ├── ecqm-calculation.json     # Electronic Clinical Quality Measures
│   │       └── measure-reporting.json
│   └── case-management/
│       ├── chronic-disease-mgmt.json     # CMMN-based case management
│       └── care-coordination.json
├── converters/
│   ├── bpmn-to-n8n/
│   │   ├── converter.py                  # BPMN XML → n8n JSON
│   │   ├── task-mappings.yaml            # BPMN task → n8n node mapping
│   │   └── gateway-logic.py              # BPMN gateways → n8n IF/Switch nodes
│   ├── dmn-to-n8n/
│   │   ├── converter.py                  # DMN decision tables → n8n functions
│   │   └── rule-engine.py
│   └── cmmn-to-n8n/
│       ├── converter.py                  # CMMN → n8n case workflows
│       └── case-model.py
├── mcp-server/
│   ├── src/
│   │   ├── __init__.py
│   │   ├── main.py                       # MCP server for workflow library
│   │   ├── tools/
│   │   │   ├── workflow_deployment.py    # Deploy workflows to n8n
│   │   │   ├── bpmn_import.py            # Import BPMN definitions
│   │   │   ├── fhir_mapping.py           # Manage FHIR mappings
│   │   │   └── standards_query.py        # Query available standards
│   │   └── services/
│   │       ├── fhir_service.py           # FHIR API integration
│   │       ├── n8n_service.py            # n8n API client
│   │       └── erpnext_service.py        # ERPNext API client
│   ├── pyproject.toml
│   └── README.md
├── tests/
│   ├── fhir/
│   │   ├── test_patient_mapping.py
│   │   ├── test_encounter_sync.py
│   │   └── test_fhir_validation.py
│   ├── workflows/
│   │   ├── test_patient_admission.py
│   │   ├── test_medication_ordering.py
│   │   └── test_lab_workflow.py
│   └── converters/
│       ├── test_bpmn_conversion.py
│       └── test_dmn_conversion.py
├── docs/
│   ├── implementation-guide.md           # How to use the library
│   ├── fhir-integration.md               # FHIR setup and configuration
│   ├── clinical-pathway-guide.md         # BPM+ implementation guide
│   ├── gs1-integration.md                # GS1 barcode/GTIN setup
│   └── uds-reporting.md                  # UDS+ reporting guide
├── terraform/
│   ├── fhir-server/                      # Optional HAPI FHIR server deployment
│   │   └── main.tf
│   └── terminology-service/              # Optional terminology service
│       └── main.tf
└── examples/
    ├── basic-clinic/                     # Small clinic configuration
    │   ├── enabled-workflows.yaml
    │   └── fhir-mappings.yaml
    ├── community-health-center/          # UDS+ reporting setup
    │   ├── enabled-workflows.yaml
    │   └── uds-config.yaml
    └── hospital/                         # Full acute care setup
        ├── enabled-workflows.yaml
        ├── gs1-config.yaml
        └── clinical-pathways.yaml
```

## Key Components

### 1. Standards Definitions

**FHIR Profiles**: Customized FHIR resource profiles for specific use cases
- Base: FHIR R4 core resources
- Customization: Extensions, constraints for ERPNext integration
- Validation: FHIR resource validation against profiles

**BPMN Clinical Pathways**: Shareable, standard clinical workflows
- Format: BPMN 2.0 XML
- Source: BPM+ Health community, institutional best practices
- Governance: Version control, change management

**DMN Decision Tables**: Clinical decision logic
- Format: DMN 1.3 XML
- Purpose: Medication dosing, alerts, quality measures
- Testing: Decision table test cases

**GS1 Process Maps**: Operational and supply chain workflows
- Source: GS1 Healthcare US business process map
- Coverage: 24 hospital processes (clinical, operational, financial)
- Integration: GTIN, barcode scanning

### 2. n8n Workflow Templates

**Purpose**: Executable implementations of standard processes

**Structure**:
- workflow.json: n8n workflow definition
- metadata.yaml: Links to BPMN source, description, version
- test-data.json: Sample data for testing

**Categories**:
1. **FHIR Integration**: Bidirectional sync workflows
2. **Clinical Workflows**: Patient care processes
3. **Operational Workflows**: GS1-based supply chain
4. **Reporting Workflows**: UDS+, quality measures
5. **Case Management**: CMMN-based chronic disease management

### 3. Converters

**BPMN → n8n Converter**:
```python
# Pseudo-code
def convert_bpmn_to_n8n(bpmn_file):
    bpmn = parse_bpmn_xml(bpmn_file)

    n8n_workflow = {
        "nodes": [],
        "connections": {}
    }

    for task in bpmn.tasks:
        node = map_task_to_n8n_node(task)
        n8n_workflow["nodes"].append(node)

    for gateway in bpmn.gateways:
        conditional = map_gateway_to_n8n_logic(gateway)
        n8n_workflow["nodes"].append(conditional)

    return n8n_workflow
```

**DMN → n8n Converter**:
```python
def convert_dmn_to_n8n_function(dmn_file):
    dmn = parse_dmn_xml(dmn_file)
    decision_table = dmn.decision_tables[0]

    # Generate JavaScript function for n8n Function node
    js_code = generate_decision_logic(decision_table)

    return {
        "type": "n8n-nodes-base.function",
        "parameters": {
            "functionCode": js_code
        }
    }
```

### 4. MCP Server (Workflow Library Control)

**Tools Exposed**:

```python
@mcp.tool()
def deploy_clinical_pathway(pathway_name: str, target_environment: str):
    """Deploy a standard clinical pathway to n8n"""
    # Load BPMN definition
    # Convert to n8n workflow
    # Deploy to n8n instance
    # Verify deployment
    return deployment_result

@mcp.tool()
def sync_fhir_resources(resource_type: str, direction: str):
    """Trigger FHIR resource synchronization (to_erpnext or to_fhir)"""
    # Execute n8n FHIR sync workflow
    return sync_status

@mcp.tool()
def import_bpmn_pathway(bpmn_file_path: str):
    """Import a new BPMN clinical pathway into library"""
    # Validate BPMN
    # Convert to n8n
    # Store in library
    # Register in catalog
    return import_result

@mcp.tool()
def configure_uds_reporting(health_center_id: str):
    """Configure UDS+ reporting workflows for health center"""
    # Set up data collection workflows
    # Configure quality measure calculations
    # Schedule automated submissions
    return config_status

@mcp.tool()
def list_available_pathways(domain: str = None):
    """List available clinical pathways by domain"""
    # Query pathway catalog
    return pathways

@mcp.tool()
def validate_fhir_mapping(erpnext_doctype: str, fhir_resource: str):
    """Validate FHIR mapping for ERPNext DocType"""
    # Test mapping
    # Return validation results
    return validation_report
```

### 5. FHIR ↔ ERPNext Mapping Engine

**Patient Mapping Example**:
```yaml
# fhir/mappings/patient-mapping.yaml
erpnext_doctype: Patient
fhir_resource: Patient

field_mappings:
  # ERPNext field: FHIR path
  patient_name: name[0].text
  first_name: name[0].given[0]
  middle_name: name[0].given[1]
  last_name: name[0].family
  sex: gender
  dob: birthDate
  mobile: telecom[system=phone].value
  email: telecom[system=email].value

  # Address
  address: address[0].line[0]
  city: address[0].city
  state: address[0].state
  pincode: address[0].postalCode

identifier_mappings:
  # ERPNext stores MRN as patient ID
  patient_id: identifier[type=MR].value

extensions:
  # Custom extensions for ERPNext-specific fields
  patient_primary_language:
    url: "http://hl7.org/fhir/StructureDefinition/patient-language"
    path: extension[url=patient-language].valueCodeableConcept.coding[0].code
```

## Integration with Existing Architecture

### MCP Server Integration

**New MCP Server**: `mcp-healthcare-workflows`

**Domain Alignment**:
- Works alongside existing domain MCP servers (Sales, Inventory, etc.)
- Focused on healthcare-specific workflow orchestration
- Cross-cutting: Can be used by multiple domains

**Tools Exposed**:
- Clinical pathway deployment
- FHIR resource synchronization
- Standards import/export
- Workflow validation

### ERPNext Healthcare Module Integration

**ERPNext Healthcare DocTypes**:
- Patient, Patient Encounter, Vital Signs
- Lab Test, Clinical Procedure
- Medication, Prescription, Dosage
- Healthcare Service Unit, Healthcare Practitioner

**Integration Pattern**:
1. Healthcare workflow library provides standardized processes
2. n8n workflows execute processes
3. Workflows interact with ERPNext Healthcare module via API
4. FHIR endpoints expose data to external systems
5. Observability tracks all workflow executions

### n8n Integration

**Workflow Deployment**:
- Workflows stored in library as JSON templates
- MCP server deploys workflows to n8n instance
- n8n API used for CRUD operations
- Workflow versioning and rollback support

**Execution**:
- Triggered by ERPNext webhooks
- Scheduled executions (reporting)
- Manual agent triggers via MCP
- FHIR API requests

### Observability Integration

**Workflow Metrics**:
- Workflow execution count by type
- Execution duration (p50, p95, p99)
- Failure rate by workflow
- FHIR sync success/failure rates

**Custom Dashboards**:
- Healthcare Workflows Overview
- FHIR Integration Status
- Clinical Pathway Performance
- UDS+ Reporting Status

**Traces**:
- OpenTelemetry instrumentation in converters
- n8n workflow execution traces
- FHIR API call tracing
- End-to-end pathway execution

## Deployment Model

### Phase 1: Foundation (Library Setup)
```bash
# Create workflow library directory structure
terraform apply -target=module.healthcare_workflow_library

# Deploy FHIR server (optional)
terraform apply -target=module.fhir_server

# Deploy workflow library MCP server
terraform apply -target=module.mcp.healthcare_workflows
```

### Phase 2: Standards Import
```bash
# Import standard clinical pathways (BPMN)
# Import DMN decision tables
# Configure FHIR mappings
# Load terminology value sets
```

### Phase 3: Workflow Conversion
```bash
# Convert BPMN pathways to n8n workflows
# Deploy workflows to n8n
# Test workflow execution
# Verify observability
```

### Phase 4: FHIR Integration
```bash
# Configure FHIR endpoints
# Test bidirectional sync
# Validate FHIR resources
# Set up terminology services
```

### Phase 5: Reporting Setup
```bash
# Configure UDS+ workflows
# Test quality measure calculations
# Schedule automated reporting
# Verify compliance
```

## Modular Deployment

**Configuration-Driven Activation**:
```hcl
# terraform.tfvars
healthcare_workflows = {
  enabled = true

  fhir_integration = true
  fhir_server = "external"  # or "deploy" for HAPI FHIR

  clinical_pathways = [
    "patient-admission",
    "medication-ordering",
    "lab-test-processing",
    "discharge-planning"
  ]

  operational_workflows = [
    "inventory-receiving",
    "medication-administration"
  ]

  reporting = {
    uds_plus = true
    quality_measures = true
  }

  gs1_integration = true
}
```

## Use Cases

### 1. Community Health Center (UDS+ Reporting Required)
- Deploy UDS+ reporting workflows
- Configure FHIR data collection
- Automate Table 6A/6B submissions
- Quality measure calculations

### 2. Small Clinic (Basic Clinical Pathways)
- Patient admission workflow
- Appointment scheduling
- Lab test ordering and results
- Prescription management

### 3. Hospital (Full GS1 + Clinical Pathways)
- Complete clinical pathway library
- GS1 supply chain integration
- Barcode medication administration
- Recall management
- Multi-department coordination

### 4. Research Institution (FHIR Data Exchange)
- FHIR API endpoints for research data
- De-identification workflows
- Research registry submissions
- Clinical trial integration

## Success Metrics

**Standardization**:
- % of workflows based on certified standards (target: 100%)
- Number of BPMN pathways implemented
- FHIR conformance test pass rate (target: 100%)

**Automation**:
- Clinical pathways automated via n8n (target: 80%)
- Manual process steps eliminated
- Workflow execution success rate (target: 99%)

**Compliance**:
- UDS+ submission timeliness (target: 100% on-time)
- Quality measure reporting accuracy (target: 100%)
- Audit trail completeness (target: 100%)

**Interoperability**:
- FHIR resources successfully exchanged
- External system integrations
- Terminology service coverage

## Next Steps

1. ✅ Design complete - documented in this file
2. ⏭️ Create directory structure
3. ⏭️ Implement FHIR mapping configurations
4. ⏭️ Create initial BPMN pathway definitions
5. ⏭️ Build BPMN → n8n converter
6. ⏭️ Develop first n8n workflow templates
7. ⏭️ Build workflow library MCP server
8. ⏭️ Create Terraform modules
9. ⏭️ Implement testing framework
10. ⏭️ Document integration guide

## References

- HL7 FHIR R4: https://hl7.org/fhir/R4/
- BPM+ Health Community: https://www.omg.org/healthcare/
- BPMN 2.0 Specification: https://www.omg.org/spec/BPMN/2.0/
- DMN 1.3 Specification: https://www.omg.org/spec/DMN/1.3/
- UDS+ FHIR IG: https://www.hrsa.gov/
- GS1 Healthcare: https://www.gs1.org/industries/healthcare
- ERPNext Healthcare: https://docs.erpnext.com/docs/user/manual/en/healthcare
- n8n Documentation: https://docs.n8n.io/
- HAPI FHIR: https://hapifhir.io/
