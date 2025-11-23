# Healthcare Workflow Library - Implementation Guide

## Overview

This guide provides step-by-step instructions for implementing the Healthcare Workflow Library within the BROAD platform. It covers deployment, configuration, integration, and testing.

## Prerequisites

### Infrastructure Requirements

- Running BROAD platform with:
  - ERPNext Healthcare deployed on GKE
  - n8n workflow engine operational
  - Observability stack (Prometheus, Grafana, Loki, Tempo)
  - MCP infrastructure layer deployed

### Software Requirements

- Python 3.10+
- Node.js 18+ (for n8n)
- kubectl (GKE access)
- Terraform (for infrastructure deployment)
- BPMN modeler (Camunda Modeler or bpmn.io) - optional

### Access Requirements

- ERPNext API credentials
- n8n API key
- GKE cluster access
- (Optional) FHIR server access

## Installation

### 1. Deploy the Workflow Library

#### Option A: Using Terraform (Recommended)

```bash
cd broad/terraform
terraform apply -target=module.healthcare_workflow_library
```

This deploys:
- Workflow library directory structure in shared volume
- MCP server for workflow library
- FHIR server (if enabled)
- n8n workflow templates

#### Option B: Manual Deployment

```bash
# Clone or copy the workflow library to your infrastructure
cd broad
git clone <repo> healthcare-workflow-library

# Or if part of the BROAD repo
cd healthcare-workflow-library

# Install Python dependencies
cd mcp-server
poetry install

# Or using pip
pip install -r requirements.txt
```

### 2. Configure Environment Variables

Create a `.env` file in `healthcare-workflow-library/mcp-server/`:

```bash
# ERPNext Configuration
ERPNEXT_URL=https://your-erpnext.example.com
ERPNEXT_API_KEY=your_api_key
ERPNEXT_API_SECRET=your_api_secret

# n8n Configuration
N8N_URL=https://your-n8n.example.com
N8N_API_KEY=your_n8n_api_key

# FHIR Server Configuration (optional)
FHIR_SERVER_URL=https://your-fhir.example.com
FHIR_SERVER_AUTH=Bearer your_token

# MCP Server Configuration
MCP_HOST=0.0.0.0
MCP_PORT=8080
MCP_LOG_LEVEL=INFO

# Observability Configuration
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
OTEL_SERVICE_NAME=healthcare-workflow-library-mcp

# OAuth2 Configuration (production)
OAUTH_SERVER_URL=https://oauth.example.com
OAUTH_CLIENT_ID=workflow-library-mcp
OAUTH_CLIENT_SECRET=your_secret
```

### 3. Deploy MCP Server

#### Using Kubernetes (Production)

```bash
cd terraform/healthcare-workflow-library
terraform apply -target=module.mcp_server

# Verify deployment
kubectl get pods -n broad | grep healthcare-workflow-library
kubectl logs -f deployment/mcp-healthcare-workflows -n broad
```

#### Using Docker Compose (Development)

```bash
cd healthcare-workflow-library/mcp-server
docker-compose up -d

# View logs
docker-compose logs -f
```

#### Running Locally (Development)

```bash
cd healthcare-workflow-library/mcp-server
poetry run python -m src.main

# Or
python -m src.main
```

### 4. Verify Installation

```bash
# Check MCP server health
curl http://localhost:8080/health

# List available tools
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{"method": "tools/list"}'

# Should return list of tools:
# - deploy_clinical_pathway
# - sync_fhir_resources
# - import_bpmn_pathway
# - configure_uds_reporting
# - validate_fhir_mapping
# - etc.
```

## Configuration

### 1. Configure FHIR Integration

#### Deploy FHIR Server (Optional)

If you don't have an existing FHIR server:

```bash
cd terraform/healthcare-workflow-library/fhir-server
terraform apply

# This deploys HAPI FHIR server on GKE
```

#### Configure FHIR Mappings

Edit FHIR mappings for your organization:

```bash
cd healthcare-workflow-library/standards/fhir/mappings

# Copy and customize patient mapping
cp patient-mapping.yaml patient-mapping-custom.yaml
vim patient-mapping-custom.yaml

# Update field mappings based on your ERPNext customizations
```

#### Test FHIR Mapping

```python
# Using MCP tool
{
  "tool": "validate_fhir_mapping",
  "arguments": {
    "erpnext_doctype": "Patient",
    "fhir_resource": "Patient",
    "test_record_id": "PAT-00001"
  }
}
```

### 2. Deploy Clinical Pathways

#### Deploy Standard Pathways

```python
# Using MCP tool (via Claude or custom client)
{
  "tool": "deploy_clinical_pathway",
  "arguments": {
    "pathway_name": "patient-admission",
    "target_environment": "production",
    "enable_fhir_sync": true
  }
}

# Deploy all standard pathways
pathways = ["patient-admission", "medication-ordering", "lab-test-processing", "discharge-planning"]
for pathway in pathways:
    deploy_clinical_pathway(pathway_name=pathway)
```

#### Verify Deployment

```bash
# Check n8n for deployed workflows
curl -X GET http://n8n:5678/api/v1/workflows \
  -H "X-N8N-API-KEY: $N8N_API_KEY"

# Or use MCP tool
{
  "tool": "get_pathway_status",
  "arguments": {
    "pathway_name": "patient-admission"
  }
}
```

### 3. Configure UDS+ Reporting (For Health Centers)

```python
# Configure UDS+ reporting
{
  "tool": "configure_uds_reporting",
  "arguments": {
    "health_center_id": "H12345678",
    "enable_table_6a": true,
    "enable_table_6b": true,
    "submission_schedule": "monthly"
  }
}
```

### 4. Set Up GS1 Integration (For Supply Chain)

```yaml
# healthcare-workflow-library/config/gs1-config.yaml
gs1_integration:
  enabled: true
  gtin_lookup_enabled: true
  barcode_scanning: true

  processes:
    - inventory-receiving
    - medication-administration
    - recall-management

  gdsn_connection:
    enabled: false  # Enable if connecting to GDSN
    data_pool: "example-data-pool"
```

## Integration with Existing BROAD Architecture

### 1. MCP Server Registration

Add the workflow library MCP server to your MCP server configuration:

```yaml
# broad/terraform/modules/mcp/main.tf
module "mcp_healthcare_workflows" {
  source = "./domain-healthcare-workflows"

  server_name = "mcp-healthcare-workflows"
  server_port = 8080
  environment = var.environment

  erpnext_url = var.erpnext_url
  n8n_url = var.n8n_url
  fhir_server_url = var.fhir_server_url
}
```

### 2. Claude Desktop Configuration

Add to Claude Desktop config to expose workflow library tools:

```json
{
  "mcpServers": {
    "healthcare-workflows": {
      "command": "python",
      "args": ["-m", "healthcare-workflow-library-mcp"],
      "env": {
        "ERPNEXT_URL": "https://erpnext.example.com",
        "N8N_URL": "https://n8n.example.com"
      }
    }
  }
}
```

### 3. n8n Integration

Workflow library workflows will appear in n8n with tags:
- `healthcare`
- `workflow-library`
- `fhir`
- `clinical-pathway`

Filter in n8n:
```
Tags: #healthcare #workflow-library
```

### 4. Observability Integration

#### Grafana Dashboard

Import the Healthcare Workflows dashboard:

```bash
cd healthcare-workflow-library/terraform/grafana
kubectl apply -f healthcare-workflows-dashboard.yaml

# Or manually import
# Navigate to Grafana → Dashboards → Import
# Upload: docs/grafana/healthcare-workflows-dashboard.json
```

Dashboard includes:
- Workflow execution count by pathway
- Execution duration (p50, p95, p99)
- Error rate by workflow
- FHIR sync statistics
- UDS+ reporting status

#### Prometheus Metrics

The MCP server exposes metrics at `/metrics`:

```
# HELP clinical_pathway_executions_total Total clinical pathway executions
# TYPE clinical_pathway_executions_total counter
clinical_pathway_executions_total{pathway="patient-admission",status="success"} 1543

# HELP fhir_sync_records_total Total FHIR records synchronized
# TYPE fhir_sync_records_total counter
fhir_sync_records_total{resource="Patient",direction="to_fhir"} 892

# HELP workflow_execution_duration_seconds Workflow execution duration
# TYPE workflow_execution_duration_seconds histogram
workflow_execution_duration_seconds_bucket{pathway="medication-ordering",le="1"} 45
```

## Usage Examples

### Example 1: Deploy Patient Admission Workflow

```python
# Step 1: List available pathways
pathways = list_available_pathways(domain="clinical")
print(pathways)

# Step 2: Deploy patient admission pathway
result = deploy_clinical_pathway(
    pathway_name="patient-admission",
    target_environment="production",
    enable_fhir_sync=True
)
print(f"Deployed workflow ID: {result['workflow_id']}")

# Step 3: Verify deployment
status = get_pathway_status(pathway_name="patient-admission")
print(f"Status: {status['deployment_status']}")
print(f"Executions: {status['execution_count']}")

# Step 4: Test the workflow
# In ERPNext, create a new Patient record
# Workflow will automatically trigger via webhook
```

### Example 2: Set Up FHIR Bidirectional Sync

```python
# Step 1: Validate FHIR mapping
validation = validate_fhir_mapping(
    erpnext_doctype="Patient",
    fhir_resource="Patient",
    test_record_id="PAT-00001"
)

if validation['valid']:
    print("Mapping is valid!")

    # Step 2: Configure FHIR sync
    sync_config = configure_fhir_sync(
        resource_type="Patient",
        direction="bidirectional",
        auto_sync=True
    )

    # Step 3: Trigger initial sync
    sync_result = sync_fhir_resources(
        resource_type="Patient",
        direction="bidirectional"
    )

    print(f"Synced {sync_result['records_synced']} patients")
```

### Example 3: Import Custom BPMN Pathway

```python
# Step 1: Create BPMN using Camunda Modeler
# Save to: /path/to/custom-pathway.bpmn

# Step 2: Import into library
import_result = import_bpmn_pathway(
    bpmn_file_path="/path/to/custom-pathway.bpmn",
    pathway_name="custom-discharge-workflow",
    description="Custom discharge workflow for orthopedic patients",
    auto_deploy=True
)

print(f"Imported pathway: {import_result['pathway_id']}")
print(f"n8n workflow ID: {import_result['n8n_workflow_id']}")

# Step 3: Monitor execution
status = get_pathway_status(pathway_name="custom-discharge-workflow")
```

### Example 4: Configure UDS+ Reporting for Health Center

```python
# Configure UDS+ reporting
uds_config = configure_uds_reporting(
    health_center_id="H80CS12345",
    enable_table_6a=True,
    enable_table_6b=True,
    submission_schedule="monthly"
)

# Workflows created:
# - UDS Table 6A Data Collection (daily aggregation)
# - UDS Table 6B Quality Measures (monthly calculation)
# - HRSA Submission (monthly, scheduled on 15th)

print(f"UDS+ configured. Workflows:")
for workflow_name, workflow_id in uds_config['workflows'].items():
    print(f"  {workflow_name}: {workflow_id}")
```

## Testing

### Unit Tests

```bash
cd healthcare-workflow-library/mcp-server
pytest tests/ -v

# Test specific components
pytest tests/fhir/ -v         # FHIR mapping tests
pytest tests/workflows/ -v    # Workflow tests
pytest tests/converters/ -v   # BPMN converter tests
```

### Integration Tests

```bash
# Requires running ERPNext, n8n, and FHIR server
pytest tests/integration/ -v --integration

# Test specific pathway
pytest tests/integration/test_patient_admission.py -v
```

### End-to-End Testing

```bash
# Full pathway execution test
cd healthcare-workflow-library/tests/e2e
./run-e2e-tests.sh

# This will:
# 1. Create test patient in ERPNext
# 2. Trigger patient admission workflow
# 3. Verify encounter creation
# 4. Verify FHIR sync
# 5. Verify metrics collection
# 6. Clean up test data
```

## Troubleshooting

### MCP Server Won't Start

```bash
# Check logs
kubectl logs deployment/mcp-healthcare-workflows -n broad

# Common issues:
# - Missing environment variables
# - Cannot connect to ERPNext/n8n
# - Port already in use

# Verify connectivity
curl http://erpnext:8000/api/method/ping
curl http://n8n:5678/health
```

### FHIR Sync Failures

```bash
# Check FHIR server logs
kubectl logs deployment/hapi-fhir -n broad

# Validate mapping
{
  "tool": "validate_fhir_mapping",
  "arguments": {
    "erpnext_doctype": "Patient",
    "fhir_resource": "Patient"
  }
}

# Check n8n workflow execution
# Navigate to n8n → Executions
# Filter by workflow: "FHIR Patient Sync"
```

### Workflow Not Triggering

```bash
# Check ERPNext webhooks
# ERPNext → Setup → Webhook
# Verify webhook is active and URL is correct

# Test webhook manually
curl -X POST http://n8n:5678/webhook/fhir-patient-sync \
  -H "Content-Type: application/json" \
  -d '{"patient_id": "PAT-00001", "trigger_source": "erpnext"}'

# Check n8n webhook logs
kubectl logs deployment/n8n -n broad | grep webhook
```

## Maintenance

### Updating Pathways

```python
# Update an existing pathway
import_bpmn_pathway(
    bpmn_file_path="/path/to/updated-pathway.bpmn",
    pathway_name="patient-admission",  # Same name to update
    description="Updated admission workflow with new triage logic",
    auto_deploy=True
)
```

### Monitoring Performance

```bash
# Access Grafana dashboard
https://grafana.example.com/d/healthcare-workflows

# Key metrics to monitor:
# - Workflow execution rate
# - Error rate
# - Execution duration
# - FHIR sync lag
```

### Backup and Recovery

```bash
# Backup BPMN definitions
tar -czf bpmn-backup-$(date +%Y%m%d).tar.gz \
  healthcare-workflow-library/standards/bpmn/

# Backup FHIR mappings
tar -czf fhir-mappings-backup-$(date +%Y%m%d).tar.gz \
  healthcare-workflow-library/standards/fhir/mappings/

# Backup n8n workflows (via n8n API)
curl -X GET http://n8n:5678/api/v1/workflows \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  > n8n-workflows-backup-$(date +%Y%m%d).json
```

## Security Considerations

### API Key Management

- Store API keys in Kubernetes Secrets
- Use separate API keys for development/staging/production
- Rotate keys regularly

### FHIR Data Security

- Ensure FHIR server has proper authentication
- Use HTTPS for all FHIR API calls
- Implement audit logging for all FHIR access

### PHI Handling

- De-identify data before syncing to external systems
- Implement proper access controls
- Maintain audit trails for PHI access

## Next Steps

1. Review the [FHIR Integration Guide](fhir-integration.md)
2. Explore [Clinical Pathway Development](clinical-pathway-guide.md)
3. Set up [UDS+ Reporting](uds-reporting.md) (if applicable)
4. Configure [GS1 Integration](gs1-integration.md) (for supply chain)

## Support

- Issues: [GitHub Issues]
- Documentation: `healthcare-workflow-library/docs/`
- Community: [Link to forum/chat]
