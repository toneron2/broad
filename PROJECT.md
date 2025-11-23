# BROAD: Business Resource Observability and Automation Deployment

## Objective
Deploy fully functional, observable ERPNext system on GCP with complete visibility and automation for demonstration to ERP professionals.

## Core Components
- **ERPNext**: Full ERP deployment (all modules)
- **Terraform**: IaC for GCP provisioning
- **n8n**: Workflow orchestration and integration layer
- **MCP Servers**: Expose all ERP functionality via protocol
- **Observability**: Complete operational metrics and testing visibility
- **Testing**: Automated load testing, functional validation, multi-scale simulation

## Approach
1. Leverage existing community templates and deployments
2. Configure comprehensive Terraform deployment for GCP
3. Integrate full n8n workflow coverage for ERPNext operations
4. Expose all functionality through MCP/agent protocols
5. Implement full observability stack
6. Configure automated testing from common to obscure operations
7. Enable scale simulation and demonstration

## Status
Initial setup - research phase

## Technology Stack (Research Complete)

### Core ERP Platform
- **ERPNext**: Full deployment via official Frappe Helm chart
- **Deployment**: GKE (Google Kubernetes Engine) + Terraform IaC
- **Database**: Cloud SQL for MySQL (MariaDB 10.6+)
- **Cache/Queue**: Memorystore for Redis (3 instances: cache, queue, socketio)
- **Storage**: Persistent Disk + Cloud Storage (backups)

### Workflow Orchestration
- **n8n**: Built-in ERPNext node (CRUD on all DocTypes)
- **Integration**: Webhook-based triggers + API polling
- **Coverage**: 2 AI templates exist, need comprehensive workflow library
- **Deployment**: On GKE alongside ERPNext

### MCP Exposure Layer
- **Framework**: frappe/mcp (official Python library for Frappe)
- **Pattern**: Decorator-based tool registration (@mcp.tool())
- **Transport**: HTTP with Streamable SSE for production
- **Examples**: rakeshgangwar/erpnext-mcp-server, ManotLuijiu/erpnext_mcp_server
- **Scope**: Expose all DocTypes + custom business operations

### Observability Stack
- **Instrumentation**: OpenTelemetry SDK
- **Metrics**: Managed Service for Prometheus + Cloud Monitoring
- **Logging**: Cloud Logging + optional Loki
- **Tracing**: Cloud Trace + optional Tempo
- **Visualization**: Grafana (primary) + Cloud Console
- **Profiling**: Cloud Profiler

### Testing Infrastructure
- **Load Testing**: k6 with k6 Operator on GKE
- **Functional Testing**: pytest + Selenium
- **API Testing**: pytest + requests
- **Test Orchestration**: n8n workflows for automated test execution

### Infrastructure Deployment
- **IaC**: Terraform (no existing ERPNext+GCP module, need to build)
- **Container Orchestration**: Kubernetes via GKE
- **Application Deployment**: Helm chart (frappe/helm - official)
- **CI/CD**: Cloud Build potential

## Key Research Findings

### What Exists
- Official Frappe Helm chart (production-ready)
- Built-in n8n ERPNext node
- Multiple MCP server implementations (Python/TypeScript)
- OpenTelemetry + Prometheus + Grafana stack (mature)
- k6 load testing framework (Kubernetes-native)

### What Needs Building
- Terraform module for GCP infrastructure (GKE + Cloud SQL + Memorystore)
- Comprehensive n8n workflow library (only 2 templates exist)
- Complete MCP server exposing all ERP functionality
- Custom Grafana dashboards for ERP observability
- Multi-scale testing scenarios and automation
- GCS backup integration

## Stack Decisions Needed

### Infrastructure Choices
1. **Pure GKE vs Hybrid**: All on GKE or mix with Compute Engine?
2. **Database**: Fully managed Cloud SQL vs self-managed MariaDB on GKE?
3. **Redis**: Memorystore for Redis vs self-managed?
4. **Storage**: GCS integration approach for ERPNext files/backups?

### Observability Trade-offs
1. **Hybrid vs Pure GCP**: OpenTelemetry + Grafana + Prometheus OR pure Cloud Operations Suite?
2. **Cost vs Features**: Managed Prometheus vs self-hosted?
3. **Log Strategy**: Cloud Logging only OR Cloud Logging + Loki for cost optimization?

### MCP Architecture
1. **Granularity**: One MCP server for all ERPNext OR module-specific servers (Sales, Inventory, Manufacturing)?
2. **Transport**: Stdio (local) vs HTTP/SSE (remote) for demonstration?
3. **Security**: OAuth2 implementation from start OR API key for initial demo?

### Testing Scope
1. **Scale Targets**: What user counts per enterprise size tier?
2. **Test Data**: Synthetic generation OR anonymized production data?
3. **Automation Level**: Fully automated test suite OR manual validation checkpoints?

## Next Steps
- Finalize technology stack choices
- Define deployment architecture
- Begin Terraform module development
