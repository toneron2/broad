# formal-to-en.sed - Formal Logic to Natural Language Translation
# Patent: Unicode Semantic Dictionary and Multi-Logic Processing Architecture
#
# Converts Unicode formal notation to natural language for human comprehension.
# Used by the NLP output layer of the Logic Engine (Figure 26).
#
# Reading level: College-level English output
#
# Usage: echo "P → Q" | sed -f formal-to-en.sed
# Result: if P then Q

# ============================================================================
# PROPOSITIONAL CONNECTIVES
# ============================================================================

# Implication
s/\([A-Za-z_][A-Za-z0-9_]*\) → \([A-Za-z_][A-Za-z0-9_]*\)/if \1 then \2/g
s/→/ implies /g

# Conjunction
s/\([A-Za-z_][A-Za-z0-9_]*\) ∧ \([A-Za-z_][A-Za-z0-9_]*\)/\1 and \2/g
s/∧/ and /g

# Disjunction
s/\([A-Za-z_][A-Za-z0-9_]*\) ∨ \([A-Za-z_][A-Za-z0-9_]*\)/\1 or \2/g
s/∨/ or /g

# Negation
s/¬\([A-Za-z_][A-Za-z0-9_]*\)/not \1/g
s/¬/not /g

# Biconditional
s/\([A-Za-z_][A-Za-z0-9_]*\) ↔ \([A-Za-z_][A-Za-z0-9_]*\)/\1 if and only if \2/g
s/↔/ if and only if /g

# Constants
s/⊤/TRUE/g
s/⊥/FALSE/g

# ============================================================================
# MODAL OPERATORS
# ============================================================================

# Necessity
s/□\([A-Za-z_][A-Za-z0-9_]*\)/necessarily \1/g
s/□/necessarily /g

# Possibility
s/◇\([A-Za-z_][A-Za-z0-9_]*\)/possibly \1/g
s/◇/possibly /g

# ============================================================================
# DEONTIC OPERATORS
# ============================================================================

# Obligation
s/O(\([^)]*\))/it is obligatory that \1/g

# Permission
s/P(\([^)]*\))/it is permitted that \1/g

# Prohibition
s/F(\([^)]*\))/it is forbidden that \1/g

# ============================================================================
# EPISTEMIC OPERATORS
# ============================================================================

# Knowledge
s/K_\([A-Za-z_][A-Za-z0-9_]*\)(\([^)]*\))/\1 knows that \2/g
s/K(\([^)]*\))/it is known that \1/g

# Belief
s/B_\([A-Za-z_][A-Za-z0-9_]*\)(\([^)]*\))/\1 believes that \2/g
s/B(\([^)]*\))/it is believed that \1/g

# ============================================================================
# TEMPORAL OPERATORS
# ============================================================================

# Globally
s/G(\([^)]*\))/always \1/g
s/G\([A-Za-z_][A-Za-z0-9_]*\)/always \1/g

# Finally
s/F(\([^)]*\))/eventually \1/g

# Next
s/○\([A-Za-z_][A-Za-z0-9_]*\)/next \1/g
s/○/next /g

# Until
s/\([A-Za-z_][A-Za-z0-9_]*\) U \([A-Za-z_][A-Za-z0-9_]*\)/\1 until \2/g

# ============================================================================
# QUANTIFIERS
# ============================================================================

s/∀\([A-Za-z_][A-Za-z0-9_]*\)/for all \1/g
s/∀/for all /g

s/∃\([A-Za-z_][A-Za-z0-9_]*\)/there exists \1/g
s/∃/there exists /g

# ============================================================================
# INFERENCE MARKERS
# ============================================================================

s/⊢/ therefore /g
