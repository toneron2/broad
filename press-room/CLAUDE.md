# BROAD Press Room - Claude Code Context

## Purpose

This is the content production layer for the BROAD project. It transforms project artifacts (captures, narratives, demos) into publishable video content for YouTube.

## Dual Mission

1. **Document the Work** - Capture governance innovation as it happens
2. **Produce the Content** - Turn documentation into professional videos

---

## Directory Structure

```
press-room/
├── .claude/
│   ├── agents/              # Subagent definitions
│   │   ├── content-orchestrator.md
│   │   ├── script-writer.md
│   │   ├── asset-builder.md
│   │   ├── video-assembler.md
│   │   ├── qa-inspector.md
│   │   └── youtube-publisher.md
│   └── commands/
│       └── produce-content.md
│
├── capture/                 # Phase-by-phase snapshots (SOURCE MATERIAL)
│   └── phase-N-name/
│       ├── SNAPSHOT.md
│       ├── DECISIONS.md
│       ├── DEMO.md
│       └── assets/
│
├── narratives/              # Story-form documentation (SOURCE MATERIAL)
│   ├── runtime-operation.md
│   └── build-evolution.md
│
├── demos/                   # Executable demonstrations (SOURCE MATERIAL)
│   ├── scripts/
│   ├── scenarios/
│   └── recordings/
│
├── presentations/           # Generated slides (INTERMEDIATE)
│   ├── templates/
│   ├── generated/
│   └── assets/
│
├── reports/                 # Generated reports (INTERMEDIATE)
│   ├── templates/
│   └── generated/
│
└── production/              # Video production layer (OUTPUT)
    ├── scripts/             # Video narration scripts
    ├── assets/              # Graphics, titles, B-roll
    ├── renders/             # FFmpeg output (gitignored)
    ├── qa/                  # QA reports and screenshots
    └── published/           # Final artifacts + metadata
```

---

## Content Production Workflow

### Pipeline Stages

1. **Source Selection** - Choose capture/narrative/demo to produce
2. **Script Generation** - Transform source into video narrative
3. **Asset Building** - Generate graphics, titles, B-roll elements
4. **Assembly** - FFmpeg composition of assets into video
5. **QA Review** - Playwright-based visual inspection
6. **Publication** - YouTube upload with metadata

### Agent Responsibilities

| Agent | Role | Does NOT Do |
|-------|------|-------------|
| content-orchestrator | Holds production plan, delegates tasks | Any actual work |
| script-writer | Transforms sources into video scripts | Asset creation |
| asset-builder | Generates graphics, titles, transitions | Video assembly |
| video-assembler | FFmpeg/rendering operations | Script or asset work |
| qa-inspector | Playwright visual validation | Corrections |
| youtube-publisher | Upload, metadata, scheduling | Content creation |

---

## Commands

- `/produce-content <source>` - Full pipeline for a source
- `/preview-video <source>` - Generate without publishing
- `/qa-check <render>` - Run Playwright inspection
- `/publish <render>` - Upload to YouTube

---

## Source Material References

When working with existing press-room content:
- Captures: `capture/phase-N-name/SNAPSHOT.md`
- Narratives: `narratives/*.md`
- Demo scripts: `demos/scripts/*.sh`
- Demo scenarios: `demos/scenarios/*.md`

### Current Source Material

| Source | Location | Status |
|--------|----------|--------|
| Phase 0: Governance Foundation | `capture/phase-0-governance/` | Ready |
| Phase 1: Governance Deep-Dive | `capture/phase-1-governance-deep-dive/` | Ready |
| Runtime Operation Narrative | `narratives/runtime-operation.md` | Ready |
| Build Evolution Narrative | `narratives/build-evolution.md` | Ready |

---

## Output Naming Convention

Video artifacts follow: `{date}-{phase}-{topic}-{version}`

Example: `2025-12-01-phase0-logic-engine-v1`

---

## Quality Gates

Before publishing, videos must pass:
1. Duration check (target length ±10%)
2. Audio levels normalized
3. Visual consistency (Playwright screenshot comparison)
4. Metadata complete (title, description, tags, thumbnail)

---

## Integration Points

### n8n Workflows

The press-room can trigger n8n workflows for:
- Multi-platform publishing
- Scheduled releases
- Analytics collection

### GCP/YouTube

Uses existing project GCP credentials for:
- YouTube Data API (upload, metadata)
- Cloud Storage (asset backup)

---

## Key Conventions

- The orchestrator NEVER does work - it only coordinates
- Each agent operates in its own context window
- Source material lives in existing directories - don't duplicate
- Renders are gitignored - only metadata and scripts are versioned

---

## Current Production Status

**Active Production**: Logic Engine Demo Video (Phase 0)

| Stage | Status | File |
|-------|--------|------|
| Source | Ready | `capture/phase-0-governance/` |
| Brief | Complete | `production/2025-12-01-phase0-logic-engine-brief.md` |
| Script | Complete | `production/scripts/2025-12-01-phase0-logic-engine.md` |
| Recording | Pending | Use `demo.code-workspace` |
| Assets | Pending | - |
| Assembly | Pending | - |
| QA | Pending | - |
| Publish | Pending | YouTube API key in `yt_api_key` |

### Quick Resume

```bash
# Open VS Code with demo workspace
cd /home/szt0j2/Desktop/broad/press-room
code demo.code-workspace

# See full instructions
cat production/HOWTO.md
```

### Key Files for Demo

- `demo.code-workspace` - VS Code workspace (open this)
- `production/HOWTO.md` - Quick start guide
- `production/DEMO-RUNBOOK.md` - Step-by-step recording script

---

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
