# Instructions for Claude Code AI Assistant

## Logic Engine - Figure 26 Implementation

**Specification**: Unicode Semantic Dictionary and Multi-Logic Processing Architecture (September 2025; patent pending)
**Status**: Working Proof-of-Concept
**Created**: 2025-11-29

---

## What This Is

This directory contains a **working implementation** of the specification's Figure 26 (Adaptive Processing Workflow) built entirely with Unix primitives (bash, awk, sed, regex). It proves the specified architecture can run on minimal hardware with extreme compactness.

**Key Achievement**: Multi-paradigm formal logic reasoning in ~4,300 lines of shell scripts.

---

## Architecture (Figure 26)

```
INPUT → TOKENIZE → IDENTIFY → ROUTE → ENGINE → OUTPUT
           │           │         │        │
        awk/sed    identify.sh  route.sh  *.sh engines
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
                 BOOLEAN       MODAL        DEONTIC
                    │             │             │
                    └─────────────┼─────────────┘
                                  ▼
                            META-ENGINE
                    (agentic composition)
```

---

## Directory Structure

```
logic-engine/
├── logic                 # MAIN ENTRY POINT - use this
├── nlp                   # Natural language interface
├── core/                 # Pipeline components
│   ├── tokenize.awk      # Tokenizer (Figs 1-15 operators)
│   ├── identify.sh       # Paradigm detector
│   ├── route.sh          # Engine router
│   └── output.sh         # Response formatter
├── engines/              # Logic engines
│   ├── boolean.sh        # Propositional (Fig 16)
│   ├── modal.sh          # Kripke semantics (Fig 17)
│   ├── deontic.sh        # O/P/F obligations (Fig 18)
│   └── meta.sh           # Cross-paradigm (Fig 24-26)
├── dict/                 # Dictionaries
│   ├── operators.tsv     # Unicode Semantic Dictionary
│   └── nlp/              # NL translation rules
├── lib/
│   └── common.sh         # Shared utilities
├── tests/                # Test suite
│   ├── generate-tests.sh # Creates 130+ test cases
│   └── run-tests.sh      # Test harness
├── demos/
│   └── esn-access-control.sh  # ESN use case demo
└── README.md             # Full documentation
```

---

## Quick Commands

```bash
# Boolean logic
./logic "P ∨ ¬P"                    # → TAUTOLOGY
./logic "P, P → Q ⊢ Q"              # → VALID

# Modal logic (auto-detected)
./logic "□P → P"                    # → T-AXIOM, VALID in T/S4/S5

# Deontic logic (auto-detected)
./logic "O(P) → P(P)"               # → D-AXIOM, VALID

# Natural language input
./logic --nlp "if P then Q"         # Converts and evaluates

# Verbose mode (shows paradigm detection)
./logic -v "□O(auth) → P(access)"

# Run tests
./tests/run-tests.sh smoke

# ESN demo
./demos/esn-access-control.sh --batch
```

---

## Key Unicode Operators

| Symbol | Meaning | Paradigm |
|--------|---------|----------|
| ¬ | NOT | all |
| ∧ | AND | all |
| ∨ | OR | all |
| → | IMPLIES | all |
| □ | NECESSARY | modal |
| ◇ | POSSIBLE | modal |
| O() | OBLIGATORY | deontic |
| P() | PERMITTED | deontic |
| F() | FORBIDDEN | deontic |
| ⊢ | THEREFORE | all |

---

## How It Works

1. **Input Analysis**: `identify.sh` detects which logic paradigms are in the expression
2. **Engine Routing**: `route.sh` sends to appropriate engine(s)
3. **Evaluation**: Engine evaluates using truth tables (boolean), Kripke frames (modal), or ideal worlds (deontic)
4. **Meta-Composition**: For mixed expressions, `meta.sh` coordinates across paradigms
5. **Output**: Structured result with validity, counterexamples, confidence

---

## ESN Integration Points

This engine powers the ESN Access Agent:

- **Bio-auth policy**: `O(authenticate) → P(access)`
- **Role-based access**: `O(role=admin) → P(delete_data)`
- **Temporal constraints**: `G(O(heartbeat)) → P(session)`
- **Privacy governance**: `O(consent) → P(data_access)`
- **Conflict detection**: Automatic cross-paradigm validation

---

## For Development

**To add a new engine:**
1. Create `engines/newparadigm.sh`
2. Add detection pattern to `core/identify.sh`
3. Add routing case to `core/route.sh`
4. Add tests to `tests/generate-tests.sh`

**To add NLP patterns:**
1. Edit `dict/nlp/en-to-formal.sed` (English → Formal)
2. Edit `dict/nlp/formal-to-en.sed` (Formal → English)

---

## Performance Targets

| Metric | Target | Achieved |
|--------|--------|----------|
| Decision latency | <50ms | ✓ |
| Memory footprint | <5MB | ✓ |
| Disk size | <100KB code | ~100KB |
| Dependencies | POSIX only | ✓ |

---

## Important Notes

- This is a **proof-of-concept** demonstrating the specification's feasibility
- Complex biconditional expressions need parser improvements
- Edge cases in Unicode handling are known
- The meta-engine is the key innovation (agentic composition)

---

## Copyright

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED

---

**Last Updated**: 2025-11-29
**Implementation**: Claude Code + Tony collaboration
