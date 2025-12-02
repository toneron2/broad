# Production Brief: Reasoned Governance - The Logic Engine

**Production ID**: 2025-12-01-phase0-logic-engine-v1
**Source Material**: `capture/phase-0-governance/`
**Target Duration**: 5 minutes
**Style**: Technical demo with personality
**Status**: In Production

---

## Core Message

**Hook**: "What if your AI governance could prove its decisions are correct - not just guess?"

**Key Differentiator**: Formal logic evaluation (deterministic, <50ms) vs LLM-based access control (probabilistic, 100-2000ms)

**Value Proposition**: Enterprise AI governance that's auditable, provable, and fast enough for real-time decisions.

---

## Target Audience

- ERP professionals evaluating AI governance solutions
- Technical decision-makers (CTOs, architects)
- Investors interested in enterprise AI infrastructure
- Healthcare IT leaders concerned with PHI protection

---

## Structure

### HOOK (0:00-0:30)
- Pose the problem: "AI access control is broken"
- LLM-based governance is slow, non-deterministic, unauditable
- Tease the solution: formal logic in <50ms

### SECTION 1: The Problem (0:30-1:30)
- Show typical AI access control: "Ask the LLM if this is allowed"
- Problems: latency, non-determinism, auditability
- Real-world consequence: healthcare compliance, audit failures

### SECTION 2: The Solution (1:30-3:00)
- Introduce the Logic Engine
- Live demo: Boolean, Modal, Deontic logic
- Show paradigm detection (the key innovation)
- Performance: <5ms detection, <50ms total

### SECTION 3: Why It Matters (3:00-4:30)
- Deontic logic for permissions: O(auth) → P(access)
- Cross-paradigm: □O(auth) - "necessarily obligatory"
- Research grounding: MonPoly, Lola, TeSSLa heritage
- EVO/NOEVO agent model preview

### OUTRO (4:30-5:00)
- Recap: deterministic, auditable, fast
- CTA: Follow for healthcare vertical demo
- BROAD platform teaser

---

## Demo Commands (Screen Recording)

```bash
# Boolean - Mathematical Truth
./logic "P ∨ ¬P"           # TAUTOLOGY

# Modal - Necessity
./logic "□P → P"           # T-AXIOM

# Deontic - Permissions
./logic "O(auth) → P(access)"   # VALID

# Cross-Paradigm
./logic "□O(auth) → P(access)"  # Meta evaluation

# Paradigm Detection (the innovation)
./core/identify.sh "□O(auth) → P(access)"
# → PRIMARY:deontic
# → PARADIGMS:boolean modal deontic
```

---

## Visual Requirements

| Timestamp | Asset Type | Description | Priority |
|-----------|------------|-------------|----------|
| 0:00 | Title Card | "Reasoned Governance" + BROAD logo | Required |
| 0:15 | Diagram | LLM vs Logic Engine comparison | Required |
| 0:45 | Code Overlay | Terminal with logic commands | Required |
| 1:30 | Diagram | Multi-paradigm overview | Required |
| 2:00 | Animation | Regex pattern matching visualization | Nice-to-have |
| 3:00 | Diagram | EVO/NOEVO hierarchy teaser | Required |
| 4:45 | End Card | Subscribe CTA + BROAD branding | Required |

---

## B-Roll Suggestions

- 0:20: Abstract "thinking" visualization (neurons/patterns)
- 1:00: Healthcare compliance imagery
- 2:30: Speed/performance visualization
- 4:00: Enterprise/security imagery

---

## Audio

- Background: Subtle tech ambient (low, non-distracting)
- Narration: Direct, confident, technical but accessible
- Sound effects: Subtle "success" sounds on logic evaluations

---

## Technical Requirements

- Terminal: Dark theme, large font (14pt+), clear prompt
- Screen recording: 1920x1080, 30fps minimum
- Pause after each command for readability

---

## Success Metrics

- Watch time: >70% retention through Section 2
- Engagement: Comments asking about healthcare use case
- Conversion: Clicks to GitHub/docs

---

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
