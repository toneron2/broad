# en-to-formal.sed - Natural Language to Formal Logic Translation
# Patent: Unicode Semantic Dictionary and Multi-Logic Processing Architecture
#
# Converts natural language expressions to Unicode formal notation.
# Used by the NLP layer of the Logic Engine (Figure 26).
#
# Reading level: Designed for college-level English comprehension
#
# Usage: echo "if P then Q" | sed -f en-to-formal.sed
# Result: P → Q

# ============================================================================
# PROPOSITIONAL CONNECTIVES
# ============================================================================

# Implication patterns
s/\bif \([A-Za-z_][A-Za-z0-9_]*\) then \([A-Za-z_][A-Za-z0-9_]*\)/\1 → \2/gi
s/\bif \([A-Za-z_][A-Za-z0-9_]*\), then \([A-Za-z_][A-Za-z0-9_]*\)/\1 → \2/gi
s/\bwhen \([A-Za-z_][A-Za-z0-9_]*\) then \([A-Za-z_][A-Za-z0-9_]*\)/\1 → \2/gi
s/\([A-Za-z_][A-Za-z0-9_]*\) implies \([A-Za-z_][A-Za-z0-9_]*\)/\1 → \2/gi
s/\([A-Za-z_][A-Za-z0-9_]*\) entails \([A-Za-z_][A-Za-z0-9_]*\)/\1 → \2/gi

# Conjunction patterns
s/\([A-Za-z_][A-Za-z0-9_]*\) and \([A-Za-z_][A-Za-z0-9_]*\)/\1 ∧ \2/gi
s/\bboth \([A-Za-z_][A-Za-z0-9_]*\) and \([A-Za-z_][A-Za-z0-9_]*\)/\1 ∧ \2/gi

# Disjunction patterns
s/\([A-Za-z_][A-Za-z0-9_]*\) or \([A-Za-z_][A-Za-z0-9_]*\)/\1 ∨ \2/gi
s/\beither \([A-Za-z_][A-Za-z0-9_]*\) or \([A-Za-z_][A-Za-z0-9_]*\)/\1 ∨ \2/gi

# Negation patterns
s/\bnot \([A-Za-z_][A-Za-z0-9_]*\)/¬\1/gi
s/\bit is not the case that \([A-Za-z_][A-Za-z0-9_]*\)/¬\1/gi
s/\bit is false that \([A-Za-z_][A-Za-z0-9_]*\)/¬\1/gi

# Biconditional patterns
s/\([A-Za-z_][A-Za-z0-9_]*\) if and only if \([A-Za-z_][A-Za-z0-9_]*\)/\1 ↔ \2/gi
s/\([A-Za-z_][A-Za-z0-9_]*\) iff \([A-Za-z_][A-Za-z0-9_]*\)/\1 ↔ \2/gi
s/\([A-Za-z_][A-Za-z0-9_]*\) is equivalent to \([A-Za-z_][A-Za-z0-9_]*\)/\1 ↔ \2/gi

# Constants
s/\btrue\b/⊤/gi
s/\bfalse\b/⊥/gi
s/\bcontradiction\b/⊥/gi
s/\btautology\b/⊤/gi

# ============================================================================
# MODAL OPERATORS
# ============================================================================

# Necessity patterns
s/\bit is necessary that \([A-Za-z_][A-Za-z0-9_]*\)/□\1/gi
s/\bnecessarily \([A-Za-z_][A-Za-z0-9_]*\)/□\1/gi
s/\bmust be \([A-Za-z_][A-Za-z0-9_]*\)/□\1/gi
s/\bit must be that \([A-Za-z_][A-Za-z0-9_]*\)/□\1/gi
s/\b\([A-Za-z_][A-Za-z0-9_]*\) is necessary/□\1/gi

# Possibility patterns
s/\bit is possible that \([A-Za-z_][A-Za-z0-9_]*\)/◇\1/gi
s/\bpossibly \([A-Za-z_][A-Za-z0-9_]*\)/◇\1/gi
s/\bmight be \([A-Za-z_][A-Za-z0-9_]*\)/◇\1/gi
s/\bcould be \([A-Za-z_][A-Za-z0-9_]*\)/◇\1/gi
s/\b\([A-Za-z_][A-Za-z0-9_]*\) is possible/◇\1/gi

# ============================================================================
# DEONTIC OPERATORS
# ============================================================================

# Obligation patterns
s/\bit is obligatory that \([A-Za-z_][A-Za-z0-9_]*\)/O(\1)/gi
s/\b\([A-Za-z_][A-Za-z0-9_]*\) is obligatory/O(\1)/gi
s/\b\([A-Za-z_][A-Za-z0-9_]*\) must be done/O(\1)/gi
s/\b\([A-Za-z_][A-Za-z0-9_]*\) is required/O(\1)/gi
s/\bmust \([A-Za-z_][A-Za-z0-9_]*\)/O(\1)/gi
s/\bshall \([A-Za-z_][A-Za-z0-9_]*\)/O(\1)/gi
s/\bought to \([A-Za-z_][A-Za-z0-9_]*\)/O(\1)/gi

# Permission patterns
s/\bit is permitted that \([A-Za-z_][A-Za-z0-9_]*\)/P(\1)/gi
s/\b\([A-Za-z_][A-Za-z0-9_]*\) is permitted/P(\1)/gi
s/\b\([A-Za-z_][A-Za-z0-9_]*\) is allowed/P(\1)/gi
s/\bmay \([A-Za-z_][A-Za-z0-9_]*\)/P(\1)/gi
s/\bcan \([A-Za-z_][A-Za-z0-9_]*\)/P(\1)/gi
s/\ballowed to \([A-Za-z_][A-Za-z0-9_]*\)/P(\1)/gi

# Prohibition patterns
s/\bit is forbidden that \([A-Za-z_][A-Za-z0-9_]*\)/F(\1)/gi
s/\b\([A-Za-z_][A-Za-z0-9_]*\) is forbidden/F(\1)/gi
s/\b\([A-Za-z_][A-Za-z0-9_]*\) is prohibited/F(\1)/gi
s/\bmust not \([A-Za-z_][A-Za-z0-9_]*\)/F(\1)/gi
s/\bshall not \([A-Za-z_][A-Za-z0-9_]*\)/F(\1)/gi
s/\bprohibited from \([A-Za-z_][A-Za-z0-9_]*\)/F(\1)/gi

# ============================================================================
# EPISTEMIC OPERATORS
# ============================================================================

# Knowledge patterns
s/\b\([A-Za-z_][A-Za-z0-9_]*\) knows that \([A-Za-z_][A-Za-z0-9_]*\)/K_\1(\2)/gi
s/\b\([A-Za-z_][A-Za-z0-9_]*\) knows \([A-Za-z_][A-Za-z0-9_]*\)/K_\1(\2)/gi
s/\bit is known that \([A-Za-z_][A-Za-z0-9_]*\)/K(\1)/gi

# Belief patterns
s/\b\([A-Za-z_][A-Za-z0-9_]*\) believes that \([A-Za-z_][A-Za-z0-9_]*\)/B_\1(\2)/gi
s/\b\([A-Za-z_][A-Za-z0-9_]*\) believes \([A-Za-z_][A-Za-z0-9_]*\)/B_\1(\2)/gi
s/\bit is believed that \([A-Za-z_][A-Za-z0-9_]*\)/B(\1)/gi

# ============================================================================
# TEMPORAL OPERATORS (LTL)
# ============================================================================

# Globally (always)
s/\balways \([A-Za-z_][A-Za-z0-9_]*\)/G(\1)/gi
s/\bit is always the case that \([A-Za-z_][A-Za-z0-9_]*\)/G(\1)/gi
s/\bforever \([A-Za-z_][A-Za-z0-9_]*\)/G(\1)/gi

# Finally (eventually)
s/\beventually \([A-Za-z_][A-Za-z0-9_]*\)/F(\1)/gi
s/\bit will be the case that \([A-Za-z_][A-Za-z0-9_]*\)/F(\1)/gi
s/\bsometime \([A-Za-z_][A-Za-z0-9_]*\)/F(\1)/gi

# Next
s/\bnext \([A-Za-z_][A-Za-z0-9_]*\)/○\1/gi
s/\bin the next state \([A-Za-z_][A-Za-z0-9_]*\)/○\1/gi

# Until
s/\b\([A-Za-z_][A-Za-z0-9_]*\) until \([A-Za-z_][A-Za-z0-9_]*\)/\1 U \2/gi

# ============================================================================
# QUANTIFIERS
# ============================================================================

s/\bfor all \([A-Za-z_][A-Za-z0-9_]*\)/∀\1/gi
s/\bfor every \([A-Za-z_][A-Za-z0-9_]*\)/∀\1/gi
s/\ball \([A-Za-z_][A-Za-z0-9_]*\) are/∀\1/gi
s/\bthere exists \([A-Za-z_][A-Za-z0-9_]*\)/∃\1/gi
s/\bsome \([A-Za-z_][A-Za-z0-9_]*\) is/∃\1/gi
s/\bthere is a \([A-Za-z_][A-Za-z0-9_]*\)/∃\1/gi

# ============================================================================
# INFERENCE MARKERS
# ============================================================================

s/\btherefore /⊢ /gi
s/\bhence /⊢ /gi
s/\bthus /⊢ /gi
s/\bconclusion: /⊢ /gi
s/\bwe conclude /⊢ /gi
