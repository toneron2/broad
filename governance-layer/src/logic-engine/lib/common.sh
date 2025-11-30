#!/bin/bash
# lib/common.sh - Shared utilities for Logic Engine
# Figure 26: Adaptive Processing Workflow - Common Functions
# Patent: Unicode Semantic Dictionary and Multi-Logic Processing Architecture

# Engine directory
ENGINE_DIR="$(dirname "${BASH_SOURCE[0]}")/../engines"
DICT_DIR="$(dirname "${BASH_SOURCE[0]}")/../dict"

# ============================================================================
# UNICODE OPERATOR PATTERNS (from Figs 1-15)
# ============================================================================

# Core logical operators (Fig 1)
readonly OP_NOT='¬'
readonly OP_AND='∧'
readonly OP_OR='∨'
readonly OP_IMPLIES='→'
readonly OP_IFF='↔'
readonly OP_TRUE='⊤'
readonly OP_FALSE='⊥'

# Modal operators (Fig 3)
readonly OP_NECESSARY='□'
readonly OP_POSSIBLE='◇'

# Temporal operators (Fig 3)
readonly OP_NEXT='○'
readonly OP_UNTIL='U'
readonly OP_RELEASE='R'
readonly OP_GLOBALLY='G'
readonly OP_FINALLY='F'

# Deontic operators (Fig 4)
readonly OP_OBLIGATORY='O'
readonly OP_PERMITTED='P'
readonly OP_FORBIDDEN='F'

# Epistemic operators (Fig 5)
readonly OP_KNOWS='K'
readonly OP_BELIEVES='B'
readonly OP_COMMON='C'
readonly OP_EVERYONE='E'

# Fuzzy operators (Fig 6)
readonly OP_TNORM='⊙'
readonly OP_TCONORM='⊕'

# ============================================================================
# PARADIGM DETECTION
# ============================================================================

# Detect which logic paradigms are present in an expression
detect_paradigms() {
    local expr="$1"
    local paradigms=""

    # Boolean is always the base
    paradigms="boolean"

    # Modal: □ ◇
    if [[ "$expr" =~ [$OP_NECESSARY$OP_POSSIBLE] ]]; then
        paradigms="$paradigms modal"
    fi

    # Deontic: O( P( F(
    if [[ "$expr" =~ O\( ]] || [[ "$expr" =~ P\( ]] || [[ "$expr" =~ F\( ]]; then
        paradigms="$paradigms deontic"
    fi

    # Epistemic: K_ B_
    if [[ "$expr" =~ K_ ]] || [[ "$expr" =~ B_ ]]; then
        paradigms="$paradigms epistemic"
    fi

    # Temporal: ○ G F U R (with specific patterns)
    if [[ "$expr" =~ [$OP_NEXT] ]] || [[ "$expr" =~ [[:space:]]U[[:space:]] ]]; then
        paradigms="$paradigms temporal"
    fi

    # Fuzzy: numeric truth values [0,1]
    if [[ "$expr" =~ [0-9]\.[0-9] ]]; then
        paradigms="$paradigms fuzzy"
    fi

    echo "$paradigms"
}

# ============================================================================
# EXPRESSION PARSING UTILITIES
# ============================================================================

# Extract atomic propositions from expression
extract_atoms() {
    local expr="$1"
    # Match single uppercase letters not followed by ( or _
    echo "$expr" | grep -oE '\b[A-Z]\b' | sort -u | tr '\n' ' '
}

# Count variables in expression
count_vars() {
    local expr="$1"
    extract_atoms "$expr" | wc -w
}

# Normalize whitespace
normalize() {
    echo "$1" | tr -s '[:space:]' ' ' | sed 's/^ *//;s/ *$//'
}

# ============================================================================
# BOOLEAN EVALUATION PRIMITIVES
# ============================================================================

# Evaluate boolean NOT
bool_not() {
    [[ "$1" -eq 0 ]] && echo 1 || echo 0
}

# Evaluate boolean AND
bool_and() {
    [[ "$1" -eq 1 && "$2" -eq 1 ]] && echo 1 || echo 0
}

# Evaluate boolean OR
bool_or() {
    [[ "$1" -eq 1 || "$2" -eq 1 ]] && echo 1 || echo 0
}

# Evaluate boolean IMPLIES (P → Q ≡ ¬P ∨ Q)
bool_implies() {
    local p="$1" q="$2"
    [[ "$p" -eq 0 || "$q" -eq 1 ]] && echo 1 || echo 0
}

# Evaluate boolean IFF (P ↔ Q ≡ (P → Q) ∧ (Q → P))
bool_iff() {
    local p="$1" q="$2"
    [[ "$p" -eq "$q" ]] && echo 1 || echo 0
}

# ============================================================================
# FUZZY LOGIC PRIMITIVES (Fig 6)
# ============================================================================

# T-norm (minimum)
fuzzy_tnorm() {
    awk -v p="$1" -v q="$2" 'BEGIN { print (p < q) ? p : q }'
}

# T-conorm (maximum)
fuzzy_tconorm() {
    awk -v p="$1" -v q="$2" 'BEGIN { print (p > q) ? p : q }'
}

# Fuzzy negation
fuzzy_not() {
    awk -v p="$1" 'BEGIN { print 1 - p }'
}

# Fuzzy implication (Kleene-Dienes)
fuzzy_implies() {
    local p="$1" q="$2"
    fuzzy_tconorm "$(fuzzy_not "$p")" "$q"
}

# ============================================================================
# OUTPUT FORMATTING (Fig 26 Phase 4)
# ============================================================================

# Format result as JSON-like output (per Fig 26)
format_result() {
    local validity="$1"
    local notation="$2"
    local confidence="${3:-1.0}"
    local paradigms="${4:-boolean}"

    cat <<EOF
{
  "validity": "$validity",
  "notation": "$notation",
  "confidence": $confidence,
  "paradigms": "$paradigms"
}
EOF
}

# ============================================================================
# ERROR HANDLING
# ============================================================================

# Log error to stderr
log_error() {
    echo "ERROR: $*" >&2
}

# Log warning to stderr
log_warn() {
    echo "WARNING: $*" >&2
}

# Log info to stderr (for debugging)
log_info() {
    [[ -n "$DEBUG" ]] && echo "INFO: $*" >&2
}

# ============================================================================
# DICTIONARY LOADING
# ============================================================================

# Load operators from TSV dictionary
load_operators() {
    local dict_file="${DICT_DIR}/operators.tsv"
    if [[ -f "$dict_file" ]]; then
        # Returns associative array setup commands
        while IFS=$'\t' read -r symbol unicode systems function rule; do
            [[ "$symbol" =~ ^# ]] && continue  # Skip comments
            echo "OP_${function}='${symbol}'"
        done < "$dict_file"
    fi
}

# ============================================================================
# VALIDATION HELPERS
# ============================================================================

# Check for contradictions
has_contradiction() {
    local expr="$1"
    # P ∧ ¬P pattern
    local atoms=$(extract_atoms "$expr")
    for atom in $atoms; do
        if [[ "$expr" =~ $atom ]] && [[ "$expr" =~ $OP_NOT$atom ]]; then
            # Check if both appear in conjunction
            if [[ "$expr" =~ $atom.*$OP_AND.*$OP_NOT$atom ]] || \
               [[ "$expr" =~ $OP_NOT$atom.*$OP_AND.*$atom ]]; then
                return 0  # Contradiction found
            fi
        fi
    done
    return 1  # No contradiction
}

# Check deontic consistency (¬(OP ∧ FP))
check_deontic_consistency() {
    local expr="$1"
    # Extract O(...) and F(...) contents
    local obligations=$(echo "$expr" | grep -oP 'O\(\K[^)]+' | sort -u)
    local forbiddens=$(echo "$expr" | grep -oP 'F\(\K[^)]+' | sort -u)

    for o in $obligations; do
        for f in $forbiddens; do
            if [[ "$o" == "$f" ]]; then
                return 1  # Inconsistent: something is both obligatory and forbidden
            fi
        done
    done
    return 0  # Consistent
}
