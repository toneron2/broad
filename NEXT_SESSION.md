# How to Continue BROAD Project

## Immediate Next Steps

### 1. Review & Decide (You)
Read **DECISIONS.md** and answer the 6 critical questions:

1. **Terraform Safety Model** (Section 2)
   - Choose: Templates, approval workflow, tiered access, or sandbox-only?

2. **Observability Granularity** (Section 4)
   - Choose: 100% tracing or intelligent sampling?

3. **Test Data Strategy** (Section 5)
   - Choose: Synthetic, template-based, anonymized, or hybrid?

4. **Deployment Mode Default** (Section 6)
   - Choose: Single-pass, phased, or configurable?

5. **Interview Format** (Section 8)
   - Choose: Automated forms, agent-conducted, or hybrid?
   - Choose: Synchronous or asynchronous?

6. **Scale Testing Realism** (Section 9)
   - Choose: User count only or company type simulation?

**Format your answers as**:
```
1. Terraform Safety: [Your choice + brief rationale]
2. Observability: [Your choice + brief rationale]
3. Test Data: [Your choice + brief rationale]
4. Deployment Mode: [Your choice + brief rationale]
5. Interview Format: [Your choice + brief rationale]
6. Scale Testing: [Your choice + brief rationale]
```

### 2. Re-Engage Claude (Next Session)

**In Terminal**:
```bash
cd /storage/emulated/0/Documents/projects/broad
# Start new Claude Code session
```

**First message**:
```
Working on BROAD project (ERPNext + n8n + MCP on GCP).

Context: Read .claude/README.md, PROJECT.md, ARCHITECTURE.md

I've made decisions on the 6 critical questions:
[Paste your answers from step 1]

Ready to begin terraform module implementation.
```

**In VS Code** (when you have it set up):
```
1. Open folder: /storage/emulated/0/Documents/projects/broad
2. Claude Code will auto-detect project
3. Reference documents appear in context
4. Same first message as terminal approach
```

### 3. Implementation Begins (Claude)

Once decisions received, Claude will:
1. Create terraform module structure
2. Implement infrastructure modules (GKE, networking, storage)
3. Build first MCP server prototype (Sales domain)
4. Set up observability foundation
5. Create deployment scripts with verification

---

## When to Use Terminal vs VS Code

### Use Terminal For:
- ✅ Planning sessions (like this one)
- ✅ Documentation review
- ✅ Architecture discussions
- ✅ Quick questions
- ✅ Research tasks
- ✅ Running deployment commands
- ✅ Monitoring and observability

### Use VS Code For:
- ✅ Writing terraform modules (multi-file editing)
- ✅ Developing MCP servers (Python packages)
- ✅ Creating test suites (pytest files)
- ✅ Grafana dashboard JSON editing
- ✅ Complex refactoring
- ✅ Git integration
- ✅ Debugging

### Either Works For:
- Reviewing code
- Making small edits
- Reading documentation
- Asking questions about architecture

---

## VS Code Setup (When Ready)

### Install Claude Code Extension
```bash
# If you have VS Code installed
code --install-extension anthropic.claude-code
```

### Open Project
```bash
cd /storage/emulated/0/Documents/projects/broad
code .
```

### First Time in VS Code
Claude Code will:
1. Detect project structure
2. Read .claude/README.md for context
3. Index codebase
4. Be ready to code

**Note**: On Android/Termux, VS Code may not be available. Terminal workflow is fully supported.

---

## Best Practices for Long-Running Projects

### 1. Context Persistence
- Key docs: PROJECT.md, ARCHITECTURE.md, DECISIONS.md
- Always reference these when re-engaging
- Update them as project evolves

### 2. Session Continuity
**Every new session, provide**:
- Project name: "BROAD project"
- Current phase: "terraform implementation" or "MCP server development"
- Reference docs: "Read .claude/README.md for context"
- Specific task: "Implementing infrastructure terraform module"

### 3. Chunking Work
For compute efficiency:
- One terraform module at a time
- One MCP server domain at a time
- Test and verify before moving to next
- Matches your modular design philosophy

### 4. Documentation Updates
As you build:
- Update PROJECT.md status section
- Document new decisions in DECISIONS.md
- Keep ARCHITECTURE.md current if design evolves

### 5. Git Workflow (Recommended)
```bash
cd /storage/emulated/0/Documents/projects/broad
git init
git add .
git commit -m "Initial architecture and design"

# After each major milestone
git add .
git commit -m "Implemented infrastructure terraform module"
```

Benefits:
- Version control for complex project
- Easy rollback if needed
- Track evolution
- Can push to GitHub for backup

---

## Project Phases (Roadmap)

### Phase 1: Foundation (Next)
- Terraform module structure
- Infrastructure layer (GKE, networking)
- Platform layer (databases, observability)
- First deployment to GCP sandbox
- **Deliverable**: GKE cluster running with monitoring

### Phase 2: Application Layer
- ERPNext Helm deployment via Terraform
- n8n deployment
- Database initialization
- Basic workflows
- **Deliverable**: ERPNext accessible, n8n operational

### Phase 3: MCP Layer
- First domain server (Sales) prototype
- Validate architecture
- Replicate to other domains
- OAuth2 authentication
- **Deliverable**: MCP servers exposing ERP functions

### Phase 4: Observability
- OpenTelemetry instrumentation
- Grafana dashboards per domain
- Alerting rules
- Health monitoring
- **Deliverable**: Full visibility into operations

### Phase 5: Testing Infrastructure
- k6 load testing scenarios
- pytest functional tests
- Testing MCP server
- Automated verification
- **Deliverable**: Self-testing system

### Phase 6: Interview & Configuration
- n8n interview workflows
- Industry templates
- Configuration automation
- **Deliverable**: 75% out-of-box functionality

### Phase 7: Scale Demonstration
- Multiple scale profiles
- Load testing at scale
- Performance optimization
- **Deliverable**: Working demo for ERP professionals

---

## Quick Reference Commands

### Check Project Status
```bash
cd /storage/emulated/0/Documents/projects/broad
ls -la
cat PROJECT.md | head -30
```

### Review Architecture
```bash
cat ARCHITECTURE.md | grep "^##"  # Section headers
```

### Check Pending Decisions
```bash
cat DECISIONS.md | grep "❓"
```

### See Research Findings
```bash
ls -R  # All project files
```

---

## If You Get Stuck

### Can't Remember Where We Left Off
Read: `.claude/README.md` (this is the context file)

### Forgot Technical Decisions
Read: `DECISIONS.md` (all decisions with rationale)

### Need Architecture Clarity
Read: `ARCHITECTURE.md` (design philosophy)

### Want Overall Picture
Read: `PROJECT.md` (objectives and stack)

### Ready to Code
Answer the 6 questions in DECISIONS.md, then re-engage Claude with answers.

---

## Current Blocker

**Waiting on**: Your answers to 6 critical decisions in DECISIONS.md

**Why blocked**: These decisions affect terraform module structure, so can't proceed with implementation until resolved.

**How long to review**: ~15-30 minutes to read DECISIONS.md and make choices

**What happens next**: Claude builds terraform modules based on your decisions

---

## Contact & Re-Engagement

### Terminal (Termux)
Just start Claude Code in project directory:
```bash
cd /storage/emulated/0/Documents/projects/broad
claude  # or however you launch Claude Code
```

First message: Reference context docs and provide decisions

### VS Code (If Available)
Open project folder, Claude Code extension auto-loads context

### Any Time
Can re-engage at any point. Project documentation is self-contained. Claude will read context docs and continue from where you left off.

---

**Status**: Waiting for your 6 decisions
**Next**: Terraform implementation begins
**Timeline**: No rush, answer when ready
**Complexity**: This is the easy part - just choose from options provided
