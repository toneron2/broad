# BROAD Project - Claude Code Context

## Project Overview
**BROAD**: Business Resource Observability and Automation Deployment

Full-stack ERPNext deployment on GCP with complete observability, MCP exposure, n8n orchestration, and automated testing. First-of-its-kind agentic ERP platform demonstration.

## Current Status
**Phase**: Architecture & Design Complete, Awaiting Decisions

**Completed**:
- ✅ Technology stack research (ERPNext, n8n, MCP, GCP, observability)
- ✅ Architecture design (domain-aligned MCP servers, hybrid observability)
- ✅ 21 architectural decisions made with rationale
- ✅ Cost optimization strategy (free tier maximization)

**Next**: User to answer 6 critical decisions in DECISIONS.md, then begin terraform module development

## Key Documents

### Primary References (Read These First)
1. **PROJECT.md** - Project objectives, tech stack, research findings
2. **ARCHITECTURE.md** - System design, layers, MCP structure, deployment model
3. **DECISIONS.md** - Architectural decisions with ✅ recommendations and ❓ questions

### Working Principles
- Everything observable, verifiable, configurable, modular, exposed via MCP
- Domain-aligned MCP servers (Sales, Purchasing, Inventory, etc.)
- Self-hosted data layer on GKE (MariaDB, Redis as StatefulSets)
- Hybrid observability (OpenTelemetry + Prometheus + Grafana + Cloud Monitoring)
- Progressive deployment with verification checkpoints
- Cost-optimized for GCP free tier

## How to Re-Engage

### First Message in New Session
```
Working on BROAD project. Read PROJECT.md, ARCHITECTURE.md, and DECISIONS.md for context.

Current task: [describe what you're working on]
```

### Context Files to Reference
- **PROJECT.md**: Overall objectives and tech stack
- **ARCHITECTURE.md**: Design philosophy and structure
- **DECISIONS.md**: Decisions made and questions pending

## Pending Critical Decisions (User Input Needed)

See DECISIONS.md for full details. User needs to decide:

1. **Terraform Safety Model**: How should agents interact with terraform?
2. **Observability Granularity**: 100% tracing or intelligent sampling?
3. **Test Data Strategy**: Synthetic, template-based, or hybrid?
4. **Deployment Mode**: Single-pass, phased, or configurable?
5. **Interview Format**: Automated forms or agent-conducted?
6. **Scale Testing**: User count only or business complexity simulation?

## Tech Stack Summary

### Core Stack
- **ERP**: ERPNext (via Frappe Helm chart)
- **Workflow**: n8n (built-in ERPNext node)
- **Infrastructure**: Terraform + GKE
- **Database**: MariaDB 10.6+ (StatefulSet on GKE)
- **Cache**: Redis (StatefulSet on GKE)
- **Observability**: OpenTelemetry → Prometheus/Loki/Tempo → Grafana
- **Testing**: k6 (load), pytest+Selenium (functional)
- **MCP**: frappe/mcp library, HTTP/SSE transport, OAuth2 auth

### MCP Server Architecture
- Domain-aligned servers: Sales, Purchasing, Inventory, Manufacturing, Accounting, HR
- Cross-cutting servers: Infrastructure, Observability, Testing
- Stateless design, independent deployment

## Directory Structure

```
/storage/emulated/0/Documents/projects/broad/
├── .claude/
│   └── README.md                 # This file
├── PROJECT.md                    # Project overview
├── ARCHITECTURE.md               # System architecture
├── DECISIONS.md                  # Architectural decisions
├── terraform/                    # (To be created)
│   ├── modules/
│   │   ├── infrastructure/
│   │   ├── platform/
│   │   ├── application/
│   │   └── mcp/
│   └── environments/
├── mcp-servers/                  # (To be created)
│   ├── mcp-sales/
│   ├── mcp-purchasing/
│   └── ...
├── monitoring/                   # (To be created)
│   ├── grafana-dashboards/
│   ├── prometheus/
│   └── opentelemetry/
└── testing/                      # (To be created)
    ├── load/
    └── functional/
```

## Next Implementation Steps (After Decisions Made)

1. **Terraform Module Structure**
   - Create hierarchical module structure
   - Infrastructure layer (GKE, networking, storage)
   - Platform layer (databases, observability)
   - Application layer (ERPNext, n8n)
   - MCP layer (domain servers)

2. **First MCP Server (Sales)**
   - Prototype domain-aligned architecture
   - Validate patterns before replicating
   - Tools: CRUD on Sales DocTypes, workflows, metrics

3. **Observability Foundation**
   - OpenTelemetry Collector configuration
   - Prometheus setup with custom metrics
   - Grafana dashboard templates

4. **Deployment Automation**
   - Phased deployment script
   - Verification checkpoints
   - Health monitoring

## User Preferences & Constraints

- **Budget**: No funding for managed GCP services, maximize free tier
- **Communication Style**: Business-focused, conversational, no emotional language
- **Focus**: Functional demonstration over code education
- **Scope**: Full depth and breadth of ERP, n8n, terraform, MCP
- **Goal**: Single-pass deployment, 75% functional out-of-box
- **Modularity**: Start small (ma & pa), scale via configuration
- **Time**: No artificial deadlines, focus on proper timing during deployment

## Research Artifacts Available

All research completed and documented:
- ERPNext on GCP deployments (no existing terraform modules found)
- n8n integration patterns (2 templates exist, need comprehensive library)
- MCP best practices (official Anthropic documentation synthesized)
- Observability stacks (industry standards documented)
- Testing frameworks (k6, pytest, Selenium evaluated)

## Commands & Workflows

### Development Workflow
- Terminal: Planning, research, documentation, quick edits
- VS Code: Code development, terraform modules, MCP servers
- Claude Code: Both interfaces supported, choose by task complexity

### When to Use Each Interface
- **Terminal**: Quick questions, documentation review, planning sessions
- **VS Code**: Code editing, debugging, file navigation, multi-file edits
- **Both**: Can switch between them, project context persists

## Important Notes

- This is first-of-its-kind integration (no existing reference implementations)
- Design decisions based on synthesized best practices across domains
- Self-managing, self-observing, self-verifying system
- Agent-to-agent communication via MCP (not peer-to-peer)
- Host-based orchestration (Claude coordinates between MCP servers)
- Everything exposed for demonstration to ERP professionals

## Contact Points for Clarification

If working with this project and unclear on:
- **Architecture decisions**: Check DECISIONS.md
- **Tech stack choices**: Check PROJECT.md
- **Design philosophy**: Check ARCHITECTURE.md
- **MCP patterns**: See DECISIONS.md Section 1
- **Cost strategy**: See DECISIONS.md Section 10

---

**Last Updated**: 2025-11-21
**Status**: Research complete, architecture designed, awaiting user decisions
