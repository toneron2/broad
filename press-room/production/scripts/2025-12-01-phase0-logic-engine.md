# Video Script: Reasoned Governance - The Logic Engine

## Metadata
- Source: `capture/phase-0-governance/`
- Target Duration: 5:00
- Style: Technical demo with personality
- Created: 2025-12-02

---

## HOOK (0:00-0:30)

**Visual**: Dark terminal, cursor blinking. Text appears: "What if AI governance could prove it's correct?"

**Narration**:
> Here's the problem with AI access control today. You ask an LLM: "Should this user access this resource?" And it... guesses. It takes 500 milliseconds to guess. And next time you ask? It might guess differently.

**Visual**: Split screen - LLM with spinning loader vs Logic Engine with instant checkmark

**Narration**:
> What if instead, your governance layer could mathematically prove its decisions - in under 50 milliseconds? That's what we built.

**Notes**: Fast pace, create urgency. End with confidence.

---

## SECTION 1: The Problem (0:30-1:30)

### Beat 1.1: The Status Quo

**Visual**: Code snippet showing typical LLM access control call

**Narration**:
> Most AI governance today looks like this. Send a prompt to an LLM: "Given this user's role and this resource, should access be granted?" You're literally asking a language model to make security decisions.

### Beat 1.2: Three Problems

**Visual**: Three icons appearing: Clock (latency), Dice (non-determinism), Question mark (auditability)

**Narration**:
> This creates three problems. First, latency - LLM calls take 100 to 2000 milliseconds. Second, non-determinism - the same question can get different answers. Third, auditability - when a regulator asks "why was this allowed?" you can't prove it. You can only show what the LLM said that one time.

### Beat 1.3: Real Stakes

**Visual**: Healthcare compliance document / HIPAA logo

**Narration**:
> In healthcare, this isn't theoretical. PHI access decisions need to be auditable, consistent, and fast. "The AI thought it was okay" doesn't pass a compliance audit.

---

## SECTION 2: The Solution (1:30-3:00)

### Beat 2.1: Introducing the Logic Engine

**Visual**: Terminal - clean dark theme, large font

**Narration**:
> So we built something different. A formal logic engine that evaluates mathematical propositions - not prompts. Let me show you.

### Beat 2.2: Boolean Logic Demo

**Visual**: Terminal command and output
```
./logic "P ∨ ¬P"
TAUTOLOGY
```

**Narration**:
> This is the law of excluded middle. A proposition is either true or not true. The engine doesn't guess - it proves this is a tautology. Always true, mathematically.

### Beat 2.3: Modal Logic Demo

**Visual**: Terminal command and output
```
./logic "□P → P"
T-AXIOM
```

**Narration**:
> Modal logic adds necessity and possibility. This box symbol means "necessarily." If something is necessarily true, it must be true. This is the T-axiom - a foundational rule of modal reasoning.

### Beat 2.4: Deontic Logic Demo

**Visual**: Terminal command and output
```
./logic "O(auth) → P(access)"
VALID
```

**Narration**:
> Now here's where it gets interesting for governance. Deontic logic handles obligations and permissions. O means obligatory. P means permitted. This says: if authentication is obligatory, then access is permitted. Valid.

### Beat 2.5: The Key Innovation

**Visual**: Terminal showing paradigm detection
```
./core/identify.sh "□O(auth) → P(access)"
PRIMARY:deontic
PARADIGMS:boolean modal deontic
```

**Narration**:
> But here's the innovation that makes this fast. How does the engine know which logic to use? Not by asking an LLM. By regex pattern matching on the Unicode operators. This detection takes less than 5 milliseconds. The box means modal. The O and P mean deontic. The operators ARE the type signature.

**Notes**: Slow down here - this is the key differentiator.

---

## SECTION 3: Why It Matters (3:00-4:30)

### Beat 3.1: Cross-Paradigm Composition

**Visual**: Terminal command
```
./logic "□O(auth) → P(access)"
VALID
```

**Narration**:
> We can compose paradigms. This expression says: if authentication is necessarily obligatory - always required, in all contexts - then access is permitted. Modal and deontic logic working together.

### Beat 3.2: Research Foundation

**Visual**: Academic paper citations / research logos

**Narration**:
> This isn't invented from scratch. It's grounded in runtime verification research - MonPoly from ETH Zurich, Lola from CISPA, TeSSLa from Lübeck. We're applying compile-time logic routing to agent governance.

### Beat 3.3: The Agent Model

**Visual**: EVO/NOEVO hierarchy diagram

**Narration**:
> This enables our agent architecture. Some agents are NOEVO - they can't evolve, can't change. They're shields. Security, routing, tool execution - all NOEVO. Other agents are EVO - they can adapt, but only within guardrail constraints defined in formal logic. The shields protect the system from the creative agents.

### Beat 3.4: Performance

**Visual**: Performance metrics graphic

**Narration**:
> And it's fast. Paradigm detection under 5 milliseconds. Full logic evaluation under 50 milliseconds. That's real-time governance. Not "wait for the API" governance.

---

## OUTRO (4:30-5:00)

**Visual**: BROAD logo, terminal in background

**Narration**:
> So that's the Logic Engine. Deterministic. Auditable. Fast. Mathematical proof instead of probabilistic guessing.

**Visual**: "Next: Healthcare Governance Demo" teaser card

**Narration**:
> Next time, we'll show this in action - healthcare workflows with PHI protection using formal deontic constraints. Subscribe so you don't miss it.

**Visual**: End card with subscribe CTA, BROAD branding, copyright

**Narration**:
> Thanks for watching. Links in the description.

---

## Asset Requirements

| Timestamp | Asset Type | Description | Priority |
|-----------|------------|-------------|----------|
| 0:00 | Title Card | "Reasoned Governance" dark theme | Required |
| 0:10 | Split Screen | LLM spinner vs Logic checkmark | Required |
| 0:45 | Code Overlay | LLM access control snippet | Required |
| 1:00 | Icons | Clock, Dice, Question mark | Required |
| 1:20 | Logo | HIPAA/Healthcare compliance | Nice-to-have |
| 1:30-3:00 | Screen Recording | Terminal demo commands | Required |
| 3:15 | Citations | Research paper references | Nice-to-have |
| 3:30 | Diagram | EVO/NOEVO hierarchy | Required |
| 4:00 | Graphic | Performance metrics | Required |
| 4:45 | Teaser Card | "Healthcare Demo" preview | Required |
| 5:00 | End Card | Subscribe CTA + branding | Required |

## B-Roll Suggestions

- 0:20: Abstract neural network / decision tree visualization
- 1:15: Healthcare/hospital environment
- 2:45: Speed lines / fast-motion abstract
- 3:45: Enterprise security imagery

---

## Production Notes

- Terminal font: JetBrains Mono or similar, 16pt minimum
- Terminal theme: Dark (Dracula or similar)
- Pause 1-2 seconds after each command to show output
- Narration pace: ~150 words/minute
- Total word count: ~750 words (~5 minutes)

---

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
