# Demo Runbook: VS Code Setup & Execution

## Opening VS Code for the Demo

### Step 1: Launch the Workspace

```bash
cd /home/szt0j2/Desktop/broad/press-room
code demo.code-workspace
```

This opens VS Code with three folders pre-configured:
- **Logic Engine** - The core engine code
- **Guardrails** - Formal constraint files
- **Press Room** - This production context

---

## VS Code Basics (30-Second Crash Course)

| Action | Shortcut |
|--------|----------|
| Open terminal | Ctrl + ` (backtick) |
| Split terminal | Click the split icon in terminal |
| Toggle sidebar | Ctrl + B |
| Open file | Ctrl + P, then type filename |
| Zoom in/out | Ctrl + +/- |

---

## Demo Layout Setup

### Step 2: Arrange the Windows

1. **Open the guardrails file**:
   - In left sidebar, expand "Guardrails"
   - Click `scheme-0.logic`
   - This shows the Security Agent constraints

2. **Open terminal** (Ctrl + `):
   - You'll see a terminal panel at bottom

3. **Split the terminal**:
   - Click the split icon (two rectangles) in terminal header
   - Now you have two terminals side by side

4. **Resize for balance**:
   - Drag the divider between editor and terminals
   - Aim for ~60% editor, ~40% terminals

Your layout should look like:
```
┌────────────────────────────────────────────────────┐
│ [Guardrails] [Logic Engine] [Press Room]  (tabs)   │
├──────────────┬─────────────────────────────────────┤
│ EXPLORER     │  scheme-0.logic                     │
│              │  ───────────────────────────────    │
│ ▼ Guardrails │  # Guardrails Scheme 0              │
│   scheme-0   │  # Security Agent [NOEVO]           │
│   scheme-1   │                                     │
│   scheme-2   │  F(harm_user)                       │
│   scheme-3   │  F(bypass_authentication)           │
│              │  □(security_decision ≤ 50ms)        │
│              ├─────────────────────────────────────│
│              │ TERMINAL 1      │ TERMINAL 2        │
│              │                 │                   │
└──────────────┴─────────────────┴───────────────────┘
```

---

## Demo Execution

### Terminal 1: Navigate to Logic Engine

```bash
cd /home/szt0j2/Desktop/broad/governance-layer/src/logic-engine
```

### Terminal 2: Same location (for paradigm detection)

```bash
cd /home/szt0j2/Desktop/broad/governance-layer/src/logic-engine
```

---

## Demo Script (What to Type & Say)

### Part 1: Boolean Logic (Terminal 1)

**Type:**
```bash
./logic "P ∨ ¬P"
```

**Say:** "This is the law of excluded middle. A proposition is either true or not true. The engine proves this is a tautology - always true, mathematically."

**Type:**
```bash
./logic "P ∧ ¬P"
```

**Say:** "And this is a contradiction. Something can't be both true and false. The engine knows the difference."

---

### Part 2: Modal Logic (Terminal 1)

**Type:**
```bash
./logic "□P → P"
```

**Say:** "Modal logic. The box means 'necessarily.' If something is necessarily true, it must be true. This is the T-axiom."

---

### Part 3: Deontic Logic (Terminal 1)

**Type:**
```bash
./logic "O(auth) → P(access)"
```

**Say:** "Now deontic logic - obligations and permissions. O means obligatory, P means permitted. If authentication is obligatory, access is permitted."

---

### Part 4: The Innovation (Terminal 2)

**Say:** "But here's the key question - how does the engine know which logic paradigm to use?"

**Type (in Terminal 2):**
```bash
./core/identify.sh "□O(auth) → P(access)"
```

**Say:** "Not by asking an LLM. By regex pattern matching on the Unicode operators. This takes less than 5 milliseconds. The operators ARE the type signature."

---

### Part 5: Show the Guardrails (Click scheme-0.logic in editor)

**Say:** "And these logic expressions define our guardrails. F means forbidden - harm user is forbidden. Bypass authentication is forbidden. And this box expression says security decisions must always complete in under 50 milliseconds."

---

## Recording Tips

1. **Before recording**: Run each command once to ensure it works
2. **Font size**: Ctrl + + to zoom if needed
3. **Pause**: Wait 1-2 seconds after each command for output
4. **Clean terminals**: Type `clear` before starting
5. **Hide distractions**: Close other apps, notifications off

---

## Quick Test Run

Before the real recording, do a dry run:

```bash
# Terminal 1
cd /home/szt0j2/Desktop/broad/governance-layer/src/logic-engine
./logic "P ∨ ¬P"
./logic "□P → P"
./logic "O(auth) → P(access)"

# Terminal 2
./core/identify.sh "□O(auth) → P(access)"
```

All should complete without errors.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `./logic: not found` | Check path, ensure in logic-engine dir |
| Permission denied | Run `chmod +x logic` and `chmod +x core/identify.sh` |
| Terminal too small | Drag dividers or use Ctrl + + |
| Sidebar in the way | Ctrl + B to hide |

---

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
