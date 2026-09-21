# Architectural decisions

**Forty decisions, November 2025: twenty-six taken from documented practice, fourteen that
needed a business judgement and got one on 2025-11-29.** Each is one line here; the
reasoning behind the first group is the cited practice, and the second group's is in
[`EXECUTION.md`](EXECUTION.md). Nothing below has been deployed; the decisions describe the
design.

## Taken from practice

| Area | Decision | Because |
|---|---|---|
| MCP servers | one server per business domain (sales, purchasing, inventory, manufacturing, HR, accounting, infrastructure) | the MCP guidance favours focused servers; domains deploy, test and scale independently; each maps to one stakeholder interview |
| | stateless; every request queries ERPNext | no session state to lose or replicate; horizontal scaling is free |
| | Streamable HTTP transport in production, not stdio | network-addressable, load-balanced, observable |
| | OAuth 2.1 with dynamic client registration | the MCP authorisation specification; agents register themselves |
| Terraform | state in a GCS backend with native locking | one state, concurrent runs cannot corrupt it |
| n8n | workflow orchestration and MCP exposure in one component | one runtime for human-designed and agent-composed workflows |
| | on the same GKE cluster as ERPNext, shared database access | latency and one operational surface |
| Observability | OpenTelemetry + Prometheus + Grafana, with Cloud Monitoring | open instrumentation, self-hosted dashboards, managed alerting where it is free |
| | a Grafana dashboard per domain plus platform dashboards | the domain owner's view and the operator's view differ |
| | every custom component instrumented with the OpenTelemetry SDK | traces cross service boundaries only if every hop emits them |
| Testing | k6 with k6-operator for load | runs inside the cluster, scriptable, reproducible |
| | pytest with Selenium for functional tests | ERPNext is a web application; workflows are end-to-end |
| | a dedicated MCP server for test orchestration | agents run and read tests the same way they run anything else |
| Deployment | hierarchical Terraform modules with conditional domain activation | a site enables the domains it uses |
| | phased targets with verification between phases | a failure is found at its layer |
| | verification checkpoints built into every component | principle 2 |
| | a live health dashboard of verification status | the checks are visible, not only logged |
| Configuration | stakeholder interviews run as n8n workflows that emit configuration | the interview is itself a workflow and is auditable |
| Scale | scale profiles as Terraform variables | switching profiles is a demonstration, not a rebuild |
| Cost | architected to the GCP free tier | the demonstration must run at near-zero cost |
| | MariaDB and Redis as StatefulSets, not managed services | cost; and the platform owns its data layer |
| Healthcare | certified standards as the foundation: HL7 FHIR R4, BPMN 2.0, BPM+ Health | shareable pathways and interoperable data instead of bespoke schemas |
| | pathways enabled per organisation type | a clinic and a hospital do not run the same set |
| | healthcare workflows deployed in phases, core pathways first | admission, medication and lab before case management and reporting |

## Decided by Tony, 2025-11-29

| Question | Decision |
|---|---|
| Terraform safety model | tiered: read operations automatic, destructive ones need approval |
| Observability granularity | 100 % tracing first, sampled as the system matures |
| Test data | hybrid: synthetic plus templates |
| Single command or phased deployment | configurable; chunked by default |
| Interview format | hybrid, with synchronous sessions for customisation |
| Scale testing | by user count and workflow complexity |
| Organisation type | community health centre (FQHC) |
| FHIR server | HAPI FHIR, self-hosted |
| UDS+ reporting | yes |
| GS1 supply chain | the full 24 hospital processes |
| Clinical pathways | standard pathways plus custom ones |
| PHI handling | full data set and a limited data set |
| Terminology services | full service (SNOMED CT, LOINC, RxNorm) |
| Timeline | none; the plan is a sequence, not a schedule |

Three further decisions were taken the same day about the governance layer and are in
[`EXECUTION.md`](EXECUTION.md): governance integrates from the first deployment, the
existing logic engine is the phase-0 reasoner without a separate validation phase, and the
hardware path is cloud simulation, then Orange Pi 5, then Pixel.
