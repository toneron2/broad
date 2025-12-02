# Press Room - Quick Start HOWTO

## Current Production: Logic Engine Demo Video

**Status**: Script complete, ready for recording
**Target**: 5-minute YouTube video on formal governance

---

## Files You Need

| File | What It Is |
|------|------------|
| `demo.code-workspace` | VS Code workspace - open this |
| `production/DEMO-RUNBOOK.md` | Step-by-step recording guide |
| `production/scripts/2025-12-01-phase0-logic-engine.md` | Full video script with narration |
| `production/2025-12-01-phase0-logic-engine-brief.md` | Production brief (context) |

---

## To Resume Production

### Step 1: Open VS Code

```bash
cd /home/szt0j2/Desktop/broad/press-room
code demo.code-workspace
```

### Step 2: Set Up Layout

1. Open terminal: `Ctrl + `` (backtick)
2. Split terminal: click split icon
3. Open `Guardrails/scheme-0.logic` in editor

### Step 3: Test Commands Work

Terminal 1:
```bash
cd /home/szt0j2/Desktop/broad/governance-layer/src/logic-engine
./logic "P ∨ ¬P"
```
Should output: `TAUTOLOGY`

Terminal 2:
```bash
cd /home/szt0j2/Desktop/broad/governance-layer/src/logic-engine
./core/identify.sh "□O(auth)"
```
Should output paradigm info.

### Step 4: Record

Follow `DEMO-RUNBOOK.md` for the full script.

---

## YouTube API

Key location: `/home/szt0j2/Desktop/broad/press-room/yt_api_key`

---

## Directory Structure

```
press-room/
├── demo.code-workspace      ← OPEN THIS IN VS CODE
├── production/
│   ├── HOWTO.md             ← YOU ARE HERE
│   ├── DEMO-RUNBOOK.md      ← Recording guide
│   ├── scripts/
│   │   └── 2025-12-01-phase0-logic-engine.md  ← Full script
│   └── 2025-12-01-phase0-logic-engine-brief.md
├── .claude/
│   ├── agents/              ← 6 production agents defined
│   └── commands/
│       └── produce-content.md
└── capture/
    └── phase-0-governance/  ← Source material
```

---

## If Something Breaks

```bash
# Check logic engine works
cd /home/szt0j2/Desktop/broad/governance-layer/src/logic-engine
./logic "P ∨ ¬P"

# Check permissions
chmod +x logic core/identify.sh
```

---

## Next Steps After Recording

1. Screen recording saved to `production/renders/`
2. Run QA check
3. Publish to YouTube using API key

---

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
