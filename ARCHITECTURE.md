# BROAD architecture

**Five principles, seven layers, one rule: every layer is reachable by an agent through MCP
and every deployment verifies itself.** Written November 2025 for a GKE target; the 2026
target is Cloud Run behind igent.me, and nothing below has been deployed.

## Principles

| | Principle | Meaning |
|---|---|---|
| 1 | Observable | every component emits metrics, logs and traces; a business operation is visible from transaction to infrastructure |
| 2 | Verifiable | every deployment, configuration and operation has an automated check |
| 3 | Configurable | template-driven, filled in by a stakeholder interview; most of it functional as shipped, all of it adjustable |
| 4 | Modular | starts at a single-site scale and grows by configuration; each module deploys, tests and observes independently |
| 5 | Exposed through MCP | agents can deploy, configure, test, observe and manage every layer |

## Layers

```
 Agentic interface         MCP servers: one per business domain, plus platform servers
 Healthcare workflows      FHIR R4 ↔ ERPNext · BPMN / CMMN / DMN → n8n · UDS+ reporting
 Business operations       ERPNext Healthcare and the standard modules
 Orchestration             n8n
 Observability             OpenTelemetry · Prometheus · Grafana · Loki · Tempo
 Application               ERPNext on Kubernetes
 Infrastructure            GKE, storage, networking, through Terraform
```

## MCP servers (design)

One server per business domain, stateless, querying ERPNext on each request, over
Streamable HTTP with OAuth 2.1 and dynamic client registration. Each exposes the domain's
ERPNext DocTypes, its n8n workflow templates, its metrics and dashboards, its tests and its
interview-driven configuration.

| Domain server | ERPNext DocTypes | n8n workflows | Metrics |
|---|---|---|---|
| Sales and CRM | Lead, Opportunity, Quotation, Sales Order, Customer | lead nurturing, order processing | conversion, order volume, revenue |
| Purchasing | Supplier, Purchase Order, Purchase Receipt | PO approval, supplier notification | cycle time, supplier performance |
| Inventory | Item, Stock Entry, Material Request, Warehouse | reorder, stock alerts | stock levels, turnover |
| Manufacturing | BOM, Work Order, Production Plan | scheduling, material planning | efficiency, capacity |
| Accounting | Journal Entry, Payment Entry, GL Entry | invoicing, reconciliation | cash flow, AR/AP ageing |
| Human resources | Employee, Attendance, Payroll Entry | onboarding, attendance | headcount, attendance, payroll |
| Infrastructure | Terraform: deploy, configure, scale | deployment, backup | utilisation, cost, availability |

Cross-cutting servers: observability (query metrics, logs, traces; alerts; reports), test
orchestration (suites, load scenarios, results), configuration (interviews, templates,
deployment, verification checkpoints), and the healthcare workflow server (deploy a
pathway, sync FHIR, import a standard, configure UDS+, validate a mapping).

## Healthcare workflow library

Standards as the source, n8n as the runtime, an MCP server as the agent's handle.

| Standard | Role |
|---|---|
| HL7 FHIR R4 | Patient, Encounter, Observation, Procedure, Medication; bidirectional sync with ERPNext; SNOMED CT, LOINC, RxNorm terminology |
| BPM+ Health: BPMN 2.0, CMMN 1.1, DMN 1.3 | prescriptive pathways, case management for chronic disease, decision logic such as dosing and alerts |
| UDS+ FHIR IG | HRSA health-centre reporting: tables 6A/6B, eCQMs, de-identified patient-level data |
| GS1 Healthcare | 24 hospital supply-chain processes, GTIN barcodes, medication administration, recalls |

The library is layered: standards → converters (BPMN, DMN and CMMN to n8n) → n8n templates
→ MCP exposure. Organisation profiles (community health centre, small clinic, hospital)
enable the pathways and reporting each needs. The design is
[`WORKFLOW_LIBRARY_DESIGN.md`](WORKFLOW_LIBRARY_DESIGN.md); what exists is listed in
[`healthcare-workflow-library/README.md`](healthcare-workflow-library/README.md).

## Deployment model

Each phase is one Terraform target set with its own verification.

| Phase | Targets | Verified by |
|---|---|---|
| 1 Infrastructure | gke, networking, storage | cluster reachable, storage provisioned |
| 2 Platform services | observability, database, redis | Prometheus scraping, database accepting connections |
| 3 Application | erpnext, n8n | ERPNext reachable, workflows deployable |
| 4 Agentic layer | mcp_servers | servers responding, tools registered |
| 5 Healthcare library (optional) | healthcare_workflow_library | FHIR server up, pathways deployed, MCP tools present |
| 6 Business configuration | interview per domain, templates per vertical | functional check per module |
| 7 Integration test | multi-domain workflows, pathway execution, FHIR validation, scale | end-to-end business processes |

Verification runs at every layer: Kubernetes health, database and queue connectivity,
collector metrics, ERPNext and n8n API checks, MCP tool registration, and business
transactions through the full stack.
