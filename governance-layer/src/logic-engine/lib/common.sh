#!/bin/bash
# lib/common.sh - Shared utilities for Logic Engine
# Figure 26: Adaptive Processing Workflow - Common Functions
# Patent: Unicode Semantic Dictionary and Multi-Logic Processing Architecture

# The engines match multi-byte Unicode operators with bracket expressions
# ([□◇], [∀∃] ...). In a non-UTF-8 locale bash matches those byte by byte,
# so ¬ and ∨ (which share lead bytes with □ and ∀) are misclassified and a
# plain propositional formula is routed to the modal engine. Pin the locale.
if [[ -z "${LC_ALL:-}" || "${LC_ALL}" != *UTF-8* && "${LC_ALL}" != *utf8* ]]; then
    export LC_ALL=C.UTF-8
fi

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

# Extract atomic propositions from a propositional expression.
# An atom is any identifier: a single letter (P, Q) or a policy term such as
# auth, session or role=admin. Operator letters that are followed by "(" in
# the modal/deontic engines never reach this function because those engines
# project their operators away first.
extract_atoms() {
    local expr="$1"
    echo "$expr" | grep -oE '\b[A-Za-z_][A-Za-z0-9_=]*\b' | sort -u | tr '\n' ' '
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
# STRUCTURAL PARSING HELPERS (shared by the modal and deontic evaluators)
# ============================================================================
# These are pure bash (no subshells): the evaluators call them once per
# sub-expression per world per valuation, so a $(...) here dominates runtime.

# Trim leading/trailing whitespace. Sets TRIMMED.
trim_ws() {
    local e="$1"
    e="${e#"${e%%[![:space:]]*}"}"
    e="${e%"${e##*[![:space:]]}"}"
    TRIMMED="$e"
}

# Remove parentheses that enclose the whole expression, repeatedly.
# "(P ∧ Q)" -> "P ∧ Q" but "(P) ∧ (Q)" is left alone. Sets STRIPPED.
strip_outer_parens() {
    local e="$1" i n depth closes_at_end
    trim_ws "$e"; e="$TRIMMED"
    while [[ "$e" == \(* && "$e" == *\) ]]; do
        n=${#e}; depth=0; closes_at_end=1
        for ((i = 0; i < n; i++)); do
            case "${e:i:1}" in
                '(') depth=$((depth + 1)) ;;
                ')') depth=$((depth - 1))
                     if ((depth == 0 && i < n - 1)); then closes_at_end=0; break; fi ;;
            esac
        done
        ((closes_at_end)) || break
        e="${e:1:n-2}"
        trim_ws "$e"; e="$TRIMMED"
    done
    STRIPPED="$e"
}

# Split at the first top-level (paren depth 0) occurrence of a one-character
# operator. Sets SPLIT_LEFT and SPLIT_RIGHT; returns 1 if the operator does
# not occur at depth 0. Splitting at the first occurrence makes → right
# associative; ∧, ∨ and ↔ are associative so the position does not matter.
split_top_level() {
    local e="$1" op="$2" i n=${#1} depth=0 c
    for ((i = 0; i < n; i++)); do
        c="${e:i:1}"
        if [[ "$c" == "(" ]]; then depth=$((depth + 1))
        elif [[ "$c" == ")" ]]; then depth=$((depth - 1))
        elif [[ "$c" == "$op" && $depth -eq 0 ]]; then
            SPLIT_LEFT="${e:0:i}"
            SPLIT_RIGHT="${e:i+1}"
            return 0
        fi
    done
    return 1
}

# Read "world:atom=val" out of a valuation string without grep. Sets ATOM_VAL
# (0 when the pair is absent).
lookup_valuation() {
    local world="$1" atom="$2" valuation="$3"
    if [[ " $valuation " == *" $world:$atom=1 "* ]]; then
        ATOM_VAL=1
    else
        ATOM_VAL=0
    fi
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
