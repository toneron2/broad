# Healthcare workflow library

**Healthcare standards as source documents, n8n as the runtime, an MCP server as the
agent's handle.** The design covers HL7 FHIR R4, BPMN 2.0, CMMN 1.1, DMN 1.3, UDS+ and
GS1; the folder holds artefacts for the first two.

| | |
|---|---|
| **Holds** | two FHIR R4 mappings, one BPMN pathway, one n8n template, an MCP server file, the implementation guide |
| **Runs** | nothing yet: the MCP server imports service modules that are not here, and the n8n template has not been imported into an n8n instance |
| **Design** | [`../WORKFLOW_LIBRARY_DESIGN.md`](../WORKFLOW_LIBRARY_DESIGN.md); designed-versus-delivered in [`../HEALTHCARE_WORKFLOW_LIBRARY_SUMMARY.md`](../HEALTHCARE_WORKFLOW_LIBRARY_SUMMARY.md) |

## Files

```
healthcare-workflow-library/
├── standards/
│   ├── fhir/mappings/patient-mapping.yaml         FHIR Patient ↔ ERPNext Patient, 328 lines
│   ├── fhir/mappings/encounter-mapping.yaml       FHIR Encounter ↔ ERPNext Patient Encounter, 195 lines
│   └── bpmn/clinical-pathways/patient-admission.bpmn   BPMN 2.0, 196 lines
├── n8n-workflows/fhir-integration/patient-sync.json    bidirectional Patient sync, 20 nodes
├── mcp-server/
│   ├── pyproject.toml
│   └── src/main.py                                 eight tool declarations, OpenTelemetry tracing
└── docs/implementation-guide.md                    627 lines
```

## The MCP server's tools, as declared

| Tool | Intended effect |
|---|---|
| `deploy_pathway` | convert a BPMN pathway and deploy it to n8n, optionally with FHIR sync |
| `list_pathways` | the pathways available for an organisation type |
| `sync_fhir` | run a FHIR ↔ ERPNext sync for named resources |
| `import_pathway` | import a BPMN, CMMN or DMN file into the standards layer |
| `configure_uds` | set up UDS+ reporting for an FQHC |
| `validate_mapping` | check a FHIR mapping against the resource definition |
| `query_standards_tool` | query the standards held |
| `get_status` | deployment status of a pathway |

The tools call `services.n8n_service` and `services.erpnext_service`, which were never
written. The file documents the interface; it is not a server that can be started.

## How the mappings are meant to work

A mapping file names the FHIR resource, the ERPNext DocType, and field-by-field
transformations in both directions, including terminology bindings (SNOMED CT, LOINC,
RxNorm). The n8n sync template reads a mapping, polls ERPNext for changes, transforms, and
posts to the FHIR server, with the reverse path on FHIR subscriptions. In the governed
platform the access agent evaluates each transmission first
([`../ESN_BROAD_INTEGRATION.md`](../ESN_BROAD_INTEGRATION.md)).

## Standards

| Standard | Publisher | Used for |
|---|---|---|
| HL7 FHIR R4 | HL7 International | clinical data exchange; the two mappings here |
| BPMN 2.0, CMMN 1.1, DMN 1.3 (BPM+ Health) | Object Management Group | clinical pathways, case management, decision logic; one BPMN pathway here |
| UDS+ FHIR IG | HRSA | health-centre reporting; designed only |
| GS1 Healthcare | GS1 | supply chain and medication administration; designed only |

The specifications are the publishers' and are not redistributed in this repository.
