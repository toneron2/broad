# BROAD Press Room

**Documentation & Demonstration Hub**

The Press Room captures, organizes, and transforms project artifacts into presentation-ready materials. It serves two goals:

1. **Goal 1: Runtime Operation** - Demonstrate WHAT the system does
2. **Goal 2: Build Evolution** - Document HOW the system is built, managed, and grows

---

## Directory Structure

```
press-room/
├── capture/                 # Phase-by-phase snapshots
│   └── phase-N-name/        # Each deployment phase
│       ├── SNAPSHOT.md      # State at completion
│       ├── DECISIONS.md     # Key decisions made
│       ├── DEMO.md          # Demo script for this phase
│       └── assets/          # Screenshots, diagrams
│
├── narratives/              # Story-form documentation
│   ├── runtime-operation.md # Goal 1: WHAT it does
│   ├── build-evolution.md   # Goal 2: HOW it grows
│   └── healthcare-journey.md # Use case walkthrough
│
├── demos/                   # Executable demonstrations
│   ├── scripts/             # Demo automation scripts
│   ├── scenarios/           # Pre-built demo scenarios
│   └── recordings/          # Screen recordings (gitignored)
│
├── presentations/           # Generated presentation materials
│   ├── templates/           # Slide templates
│   ├── generated/           # Auto-generated decks (gitignored)
│   └── assets/              # Logos, diagrams, visuals
│
└── reports/                 # Generated reports
    ├── templates/           # Report templates
    └── generated/           # Auto-generated reports (gitignored)
```

---

## Phase Capture Protocol

### Before Starting Phase N

```bash
mkdir -p press-room/capture/phase-N-name/assets
```

### During Phase N

1. Log key decisions to `DECISIONS.md`
2. Capture screenshots/diagrams in `assets/`
3. Draft demo opportunities in `DEMO.md`

### At Phase Completion

Create `SNAPSHOT.md` with:
- Date completed
- What was deployed
- Verification evidence
- Key decisions (link)
- Demo readiness
- Lessons learned
- Next phase dependencies

---

## Running Demos

All demo scripts are in `demos/scripts/`:

```bash
# Quick smoke test of all demos
cd press-room/demos/scripts
./00-all-demos.sh

# Individual demos
./01-logic-engine-demo.sh      # Core Logic Engine
./02-paradigm-detection-demo.sh # Regex innovation
./03-guardrails-demo.sh         # Formal constraints
./04-access-control-demo.sh     # Full governance flow
```

---

## Completed Phases

| Phase | Name | Status | Demo Ready |
|-------|------|--------|------------|
| 0 | Governance Foundation | ✅ Complete | ✅ Yes |
| 1 | Governance Deep-Dive | ✅ Complete | ✅ Yes |
| 2 | Local Docker Environment | Pending | - |
| 3 | Cloud Infrastructure | Pending | - |
| 4 | Healthcare Vertical | Pending | - |
| 5 | Full Observability | Pending | - |

---

## Generating Materials

### From Narratives to Slides

```bash
# Future: Generate slides from narrative markdown
./scripts/generate-slides.sh narratives/runtime-operation.md
```

### From Captures to Reports

```bash
# Future: Generate phase report
./scripts/generate-report.sh capture/phase-0-governance/
```

---

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
