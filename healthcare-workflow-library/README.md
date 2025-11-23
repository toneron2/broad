# Healthcare Workflow Library

## Overview

The Healthcare Workflow Library is a comprehensive collection of standardized, machine-readable healthcare processes that integrate certified healthcare standards (HL7 FHIR R4, BPM+, BPMN, CMMN, DMN, GS1) with executable n8n workflows for the BROAD platform.

## Purpose

- **Standardization**: Use certified healthcare process standards (BPM+ Health, HL7 FHIR)
- **Interoperability**: Enable seamless data exchange via HL7 FHIR R4 API
- **Automation**: Convert clinical pathways into executable workflows
- **Compliance**: Support regulatory reporting (UDS+, quality measures)
- **Modularity**: Deploy workflows based on organizational needs
- **Observability**: Full visibility into healthcare process execution

## Quick Start

### Installation

```bash
cd healthcare-workflow-library

# Install Python dependencies for converters and MCP server
pip install -r requirements.txt

# Or using poetry
poetry install
```

### Deploy a Clinical Pathway

```bash
# Using the MCP server (via Claude or custom client)
# Deploy patient admission workflow
mcp-tool deploy_clinical_pathway --pathway=patient-admission --environment=production

# Or manually deploy to n8n
python converters/bpmn-to-n8n/converter.py \
  --input standards/bpmn/clinical-pathways/patient-admission.bpmn \
  --output n8n-workflows/clinical-workflows/patient-admission/workflow.json

# Import to n8n via API
curl -X POST http://n8n:5678/api/v1/workflows \
  -H "Content-Type: application/json" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -d @n8n-workflows/clinical-workflows/patient-admission/workflow.json
```

### Configure FHIR Integration

```bash
# Configure FHIR endpoints in ERPNext
# Set up Patient mapping
cp standards/fhir/mappings/patient-mapping.yaml config/active/

# Deploy FHIR sync workflows to n8n
python scripts/deploy-fhir-workflows.py --resources Patient,Encounter,Observation
```

## Structure

```
healthcare-workflow-library/
├── standards/              # Standard definitions (BPMN, FHIR, DMN, GS1)
├── n8n-workflows/          # Executable n8n workflow templates
├── converters/             # BPMN/DMN/CMMN → n8n converters
├── mcp-server/             # MCP server for workflow library control
├── tests/                  # Test suites
├── docs/                   # Documentation
├── terraform/              # Infrastructure as Code
└── examples/               # Example configurations by organization type
```

## Standards Covered

### HL7 FHIR R4
- Patient, Encounter, Observation, Procedure resources
- Bidirectional sync with ERPNext Healthcare
- Terminology services (SNOMED CT, LOINC, RxNorm)

### BPM+ Health (BPMN, CMMN, DMN)
- **BPMN**: Clinical pathways (admission, medication ordering, discharge)
- **CMMN**: Case management (chronic disease, care coordination)
- **DMN**: Decision logic (dosing rules, risk stratification)

### UDS+ FHIR IG
- HRSA health center reporting
- Table 6A/6B data collection
- Quality measure calculations

### GS1 Healthcare
- Supply chain processes (24 hospital workflows)
- GTIN/barcode integration
- Medication administration safety
- Recall management

## Key Components

### 1. FHIR Mappings
Pre-configured mappings between FHIR resources and ERPNext DocTypes:
- `standards/fhir/mappings/patient-mapping.yaml`
- `standards/fhir/mappings/encounter-mapping.yaml`
- `standards/fhir/mappings/observation-mapping.yaml`

### 2. Clinical Pathways (BPMN)
Shareable, standardized clinical workflows:
- Patient admission process
- Medication ordering with safety checks
- Lab test workflow
- Discharge planning

### 3. Decision Logic (DMN)
Clinical decision tables:
- Medication dosing rules
- Lab alert thresholds
- Risk stratification
- Quality measure logic

### 4. n8n Workflows
Ready-to-deploy workflow templates:
- FHIR integration (bidirectional sync)
- Clinical workflows (care processes)
- Operational workflows (GS1-based)
- Reporting workflows (UDS+, quality measures)

### 5. MCP Server
Agent-accessible workflow library control:
```python
# Available MCP tools:
deploy_clinical_pathway()      # Deploy BPMN pathway to n8n
sync_fhir_resources()          # Trigger FHIR sync
import_bpmn_pathway()          # Import new pathway
configure_uds_reporting()      # Set up UDS+ reporting
list_available_pathways()      # Query pathway catalog
validate_fhir_mapping()        # Test FHIR mappings
```

## Use Cases

### Community Health Center
```bash
# Enable UDS+ reporting
python scripts/configure-organization.py \
  --type community-health-center \
  --enable-uds-reporting \
  --enable-quality-measures

# Deploys:
# - UDS+ data collection workflows
# - Quality measure calculations
# - Automated HRSA submissions
```

### Small Clinic
```bash
# Basic clinical workflows
python scripts/configure-organization.py \
  --type basic-clinic \
  --pathways patient-admission,medication-ordering,lab-test-processing

# Deploys:
# - Core clinical pathways
# - FHIR Patient/Encounter sync
# - Appointment workflows
```

### Hospital
```bash
# Full clinical + operational workflows
python scripts/configure-organization.py \
  --type hospital \
  --enable-all-pathways \
  --enable-gs1-integration

# Deploys:
# - All clinical pathways
# - GS1 supply chain workflows
# - Barcode medication administration
# - Recall management
# - UDS+ reporting (if applicable)
```

## Development

### Adding a New Clinical Pathway

1. Create BPMN definition:
```bash
# Use a BPMN modeler (Camunda Modeler, bpmn.io)
# Save to: standards/bpmn/clinical-pathways/my-pathway.bpmn
```

2. Convert to n8n workflow:
```bash
python converters/bpmn-to-n8n/converter.py \
  --input standards/bpmn/clinical-pathways/my-pathway.bpmn \
  --output n8n-workflows/clinical-workflows/my-pathway/workflow.json
```

3. Add metadata:
```yaml
# n8n-workflows/clinical-workflows/my-pathway/metadata.yaml
name: My Clinical Pathway
version: 1.0.0
bpmn_source: standards/bpmn/clinical-pathways/my-pathway.bpmn
description: Description of what this pathway does
domains:
  - clinical-care
tags:
  - patient-care
  - standardized
```

4. Test:
```bash
pytest tests/workflows/test_my_pathway.py
```

5. Deploy:
```bash
mcp-tool deploy_clinical_pathway --pathway=my-pathway
```

### Adding a FHIR Mapping

1. Create mapping definition:
```yaml
# standards/fhir/mappings/my-resource-mapping.yaml
erpnext_doctype: MyDocType
fhir_resource: MyResource

field_mappings:
  my_field: myFhirPath
  another_field: another.fhir.path
```

2. Test mapping:
```bash
pytest tests/fhir/test_my_resource_mapping.py
```

3. Deploy mapping:
```bash
python scripts/deploy-fhir-mapping.py --mapping my-resource-mapping
```

## Testing

### Run All Tests
```bash
pytest tests/
```

### Test Specific Components
```bash
# FHIR mapping tests
pytest tests/fhir/

# Workflow tests
pytest tests/workflows/

# Converter tests
pytest tests/converters/
```

### Integration Tests
```bash
# Requires running ERPNext, n8n, and FHIR server
pytest tests/integration/ --integration
```

## Documentation

- [Implementation Guide](docs/implementation-guide.md) - Detailed setup instructions
- [FHIR Integration Guide](docs/fhir-integration.md) - FHIR configuration and troubleshooting
- [Clinical Pathway Guide](docs/clinical-pathway-guide.md) - BPM+ implementation
- [GS1 Integration Guide](docs/gs1-integration.md) - Supply chain workflows
- [UDS+ Reporting Guide](docs/uds-reporting.md) - HRSA reporting setup

## Architecture Integration

The workflow library integrates with the BROAD platform as follows:

```
MCP Servers (Agent Interface)
     ↓
Healthcare Workflow Library MCP Server
     ↓
n8n (Workflow Execution)
     ↓
ERPNext Healthcare (Data Storage) ↔ FHIR Server (Interoperability)
     ↓
Observability Stack (Metrics, Logs, Traces)
```

### MCP Integration
- New MCP server: `mcp-healthcare-workflows`
- Exposes workflow deployment and management tools
- Integrates with existing domain MCP servers

### n8n Integration
- Workflows deployed to n8n via API
- Triggered by ERPNext webhooks or schedules
- Execution monitored via observability stack

### ERPNext Integration
- Uses ERPNext Healthcare module DocTypes
- API-based operations (CRUD)
- Webhook triggers for real-time workflows

### FHIR Integration
- Optional HAPI FHIR server deployment
- Bidirectional sync workflows
- External system interoperability

### Observability Integration
- OpenTelemetry instrumentation
- Custom Grafana dashboards
- Workflow execution metrics

## Configuration

### Environment Variables
```bash
# ERPNext
ERPNEXT_URL=https://erpnext.example.com
ERPNEXT_API_KEY=your-api-key
ERPNEXT_API_SECRET=your-api-secret

# n8n
N8N_URL=https://n8n.example.com
N8N_API_KEY=your-n8n-api-key

# FHIR Server (optional)
FHIR_SERVER_URL=https://fhir.example.com
FHIR_SERVER_AUTH=Bearer your-token

# Observability
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
```

### Configuration Files
```yaml
# config/workflow-library.yaml
enabled_standards:
  - fhir_r4
  - bpmn_2.0
  - dmn_1.3
  - gs1

fhir_integration:
  enabled: true
  server_type: external  # or 'hapi' for deployed server
  sync_resources:
    - Patient
    - Encounter
    - Observation

clinical_pathways:
  enabled:
    - patient-admission
    - medication-ordering
    - lab-test-processing
    - discharge-planning

operational_workflows:
  enabled:
    - inventory-receiving
    - medication-administration

reporting:
  uds_plus: true
  quality_measures: true
```

## Roadmap

### Phase 1: Foundation (Current)
- [x] Design and architecture
- [x] Directory structure
- [ ] FHIR mapping configurations
- [ ] Core BPMN pathway definitions
- [ ] BPMN → n8n converter

### Phase 2: Core Workflows
- [ ] Patient admission workflow
- [ ] Medication ordering workflow
- [ ] Lab test workflow
- [ ] FHIR bidirectional sync

### Phase 3: MCP Server
- [ ] MCP server implementation
- [ ] Tool registration
- [ ] Integration with n8n API
- [ ] Integration with ERPNext API

### Phase 4: Reporting
- [ ] UDS+ data collection workflows
- [ ] Quality measure calculations
- [ ] Automated HRSA submissions

### Phase 5: Advanced Features
- [ ] CMMN case management
- [ ] GS1 supply chain integration
- [ ] Advanced decision logic (DMN)
- [ ] Multi-organization support

## Contributing

Guidelines for contributing new pathways, mappings, or workflows:

1. Follow BPM+ Health standards for clinical pathways
2. Use HL7 FHIR R4 profiles for interoperability
3. Include test cases for all workflows
4. Document mappings and decision logic
5. Version control all standard definitions

## License

[License information to be added]

## Support

- Documentation: `docs/`
- Issues: [GitHub Issues]
- Community: [Link to community forum/chat]

## References

- [HL7 FHIR R4 Specification](https://hl7.org/fhir/R4/)
- [BPM+ Health Community](https://www.omg.org/healthcare/)
- [BPMN 2.0 Specification](https://www.omg.org/spec/BPMN/2.0/)
- [DMN 1.3 Specification](https://www.omg.org/spec/DMN/1.3/)
- [UDS+ FHIR IG](https://www.hrsa.gov/)
- [GS1 Healthcare Standards](https://www.gs1.org/industries/healthcare)
- [ERPNext Healthcare Documentation](https://docs.erpnext.com/docs/user/manual/en/healthcare)
- [n8n Documentation](https://docs.n8n.io/)
