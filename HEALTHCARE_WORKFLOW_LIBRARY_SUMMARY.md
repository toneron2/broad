# Healthcare workflow library: designed and delivered

**The library was designed to hold seven standards across four layers. It holds four
artefacts for two of them.** This page keeps the two columns apart. The design is
[`WORKFLOW_LIBRARY_DESIGN.md`](WORKFLOW_LIBRARY_DESIGN.md); the folder is
[`healthcare-workflow-library/`](healthcare-workflow-library/).

An earlier revision of this page (November 2025) was a generated session summary that
listed 47 directories and eleven implementation files as delivered. Measured against the
repository, that was not so, and the page was replaced on 2026-09-20.

## Designed

| Layer | Contents |
|---|---|
| Standards | FHIR R4 profiles and ERPNext mappings; BPMN clinical pathways; CMMN case models; DMN decision tables; GS1 process maps; UDS+ reporting definitions |
| Conversion | BPMN → n8n, DMN → n8n function nodes, CMMN → n8n case workflows |
| Execution | n8n templates: FHIR integration, clinical, operational (GS1), reporting (UDS+), case management; ERPNext Healthcare operations |
| MCP exposure | a server with tools to deploy a pathway, sync FHIR resources, import a standard, configure UDS+, validate a mapping, query the standards |

Organisation profiles enable subsets: a community health centre gets UDS+ reporting,
admission and medication pathways and FHIR sync; a small clinic gets admission and lab
pathways; a hospital gets every pathway, advanced FHIR and GS1.

## Delivered

| Artefact | File | Size |
|---|---|---|
| FHIR R4 Patient ↔ ERPNext Patient mapping | `standards/fhir/mappings/patient-mapping.yaml` | 328 lines |
| FHIR R4 Encounter ↔ ERPNext Patient Encounter mapping | `standards/fhir/mappings/encounter-mapping.yaml` | 195 lines |
| BPMN 2.0 clinical pathway: patient admission | `standards/bpmn/clinical-pathways/patient-admission.bpmn` | 196 lines |
| n8n template: bidirectional patient sync | `n8n-workflows/fhir-integration/patient-sync.json` | 335 lines, 20 nodes |
| MCP server | `mcp-server/src/main.py` | 393 lines; declares eight tools over service modules that are not in the repository, so it does not run |
| Implementation guide | `docs/implementation-guide.md` | 627 lines |

Not present: CMMN, DMN, GS1 and UDS+ material of any kind, the converters, the terminology
service, tests, Terraform. The standards themselves are published by HL7, the OMG and GS1
and are not redistributed here.

## What follows

The seven-standard claim stays a design until each standard has an artefact behind it.
The next step, if the library is taken up again, is the converter for the one BPMN pathway
that exists, so that the n8n template is generated rather than hand-written.
