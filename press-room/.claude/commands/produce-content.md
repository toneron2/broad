---
description: "Execute the full content production pipeline for a press-room source. Orchestrates script writing, asset building, video assembly, QA, and optional publication."
argument-hint: "<source-path> [--preview] [--publish]"
---

# Produce Content Pipeline

Transform a press-room source into publishable video content.

## Usage

```
/produce-content capture/phase-0-governance-foundation
/produce-content narratives/runtime-operation.md --preview
/produce-content demos/scenarios/access-control.md --publish
```

## Arguments

- `<source-path>`: Path to source material (capture directory, narrative file, or demo scenario)
- `--preview`: Stop after assembly, don't run QA or publish
- `--publish`: If QA passes, automatically publish to YouTube

## Pipeline Execution

**CRITICAL**: You are invoking the content-orchestrator agent to manage this pipeline. Do NOT attempt to perform these steps yourself.

### Step 1: Validate Source

First, verify the source exists and is suitable for production:

```
Read the source at {source-path}
Determine source type: capture | narrative | demo
Verify required files are present
```

### Step 2: Invoke Orchestrator

Delegate the full pipeline to content-orchestrator:

```
Use the content-orchestrator agent to produce video content from:

Source: {source-path}
Source Type: {capture|narrative|demo}
Mode: {full|preview} (based on --preview flag)
Auto-publish: {yes|no} (based on --publish flag)

The orchestrator should:
1. Analyze source and create production brief
2. Delegate to script-writer for narration script
3. Delegate to asset-builder for visual assets
4. Delegate to video-assembler for rendering
5. Delegate to qa-inspector for validation
6. If approved and --publish: delegate to youtube-publisher

Report back with final status and any issues.
```

### Step 3: Report Results

After orchestrator completes, summarize:

```markdown
## Production Complete

**Source**: {source-path}
**Status**: {SUCCESS | PARTIAL | FAILED}

### Outputs
- Script: production/scripts/{file}
- Assets: production/assets/{folder}/
- Video: production/renders/{file}
- QA Report: production/qa/{file}
- Published: {YouTube URL if published}

### Issues
{any problems encountered}

### Next Steps
{recommendations}
```

## Source Type Handling

### Captures (directories)
- Read SNAPSHOT.md for state summary
- Read DECISIONS.md for context
- Read DEMO.md for demonstration opportunities
- Check assets/ for existing screenshots/diagrams

### Narratives (markdown files)
- Single source file
- Extract structure from headers
- Identify code blocks and diagrams

### Demos (scripts or scenarios)
- For .sh files: extract commands and comments
- For .md scenarios: follow scenario structure
- May need screen recording guidance

## Output Locations

All outputs go to the `production/` directory:

```
production/
├── scripts/          # Video narration scripts
├── assets/           # Generated graphics, titles
├── renders/          # Final video files (gitignored)
├── qa/               # QA reports and screenshots
└── published/        # Publication metadata
```

## Error Handling

If any stage fails:
1. Orchestrator will report the failure
2. Partial outputs are preserved
3. User can re-run with fixes
4. Use `/qa-check` to re-validate after manual fixes

## Examples

### Produce Phase 0 Demo
```
/produce-content capture/phase-0-governance-foundation
```
Produces a video from the Phase 0 capture, including governance foundation demo.

### Preview Only (no QA or publish)
```
/produce-content narratives/build-evolution.md --preview
```
Generates script, assets, and renders but skips validation and publishing.

### Full Pipeline with Auto-Publish
```
/produce-content demos/scenarios/guardrails-demo.md --publish
```
Runs full pipeline and publishes to YouTube if QA passes.
