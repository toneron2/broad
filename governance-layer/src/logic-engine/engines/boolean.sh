#!/bin/bash
# engines/boolean.sh - Boolean Logic Engine
# Figure 16: Expanded Logic System Processing Architecture Flow (Boolean Engine)
# Patent: Unicode Semantic Dictionary and Multi-Logic Processing Architecture
#
# INPUT: Argument(Premise, Premise, ..., Conclusion)
# PROCESS:
#   1. Parse statements into atomic propositions (P, Q, R, ...)
#   2. Apply truth table evaluation
#   3. Check validity: all interpretations where (P1 ∧ P2 ∧ ... ∧ Pn) → C
#   4. Return: VALID / INVALID + counterexample

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# ============================================================================
# EXPRESSION TOKENIZATION AND PARSING
# ============================================================================

# Convert expression to evaluable bash arithmetic
# Handles: ¬ ∧ ∨ → ↔ ⊤ ⊥
# Using sed for reliable Unicode handling
expr_to_bash() {
    local expr="$1"

    # Use sed for all Unicode replacements (more reliable than bash parameter expansion)
    echo "$expr" | sed \
        -e 's/(/ ( /g' \
        -e 's/)/ ) /g' \
        -e 's/⊤/1/g' \
        -e 's/⊥/0/g' \
        -e 's/∧/ \&\& /g' \
        -e 's/∨/ || /g' \
        -e 's/¬/!/g' \
        | tr -s ' '
}

# Evaluate a boolean expression with given variable assignments
# Args: expression, then VAR=val pairs
eval_bool_expr() {
    local expr="$1"
    shift

    # Set variable values
    local vars=""
    for assignment in "$@"; do
        local var="${assignment%%=*}"
        local val="${assignment#*=}"
        vars="$vars local $var=$val;"
    done

    # Convert expression to bash
    local bash_expr=$(expr_to_bash "$expr")

    # Handle implication manually: A → B becomes (!A || B)
    bash_expr=$(echo "$bash_expr" | sed -E 's/([^|&!() ]+)[[:space:]]*→[[:space:]]*([^|&!() ]+)/( !\1 || \2 )/g')

    # Handle biconditional: A ↔ B becomes ((A && B) || (!A && !B))
    bash_expr=$(echo "$bash_expr" | sed -E 's/([^|&!() ]+)[[:space:]]*↔[[:space:]]*([^|&!() ]+)/(( \1 \&\& \2 ) || ( !\1 \&\& !\2 ))/g')

    # Evaluate
    eval "$vars"
    eval "echo \$(( $bash_expr ))" 2>/dev/null || echo "ERROR"
}

# ============================================================================
# TRUTH TABLE GENERATION
# ============================================================================

# Generate all truth assignments for n variables
# Returns lines of "P=0 Q=1 R=0" etc.
generate_assignments() {
    local vars="$1"  # Space-separated variable names
    local var_array=($vars)
    local n=${#var_array[@]}
    local total=$((2 ** n))

    for ((i = 0; i < total; i++)); do
        local assignment=""
        for ((v = 0; v < n; v++)); do
            local bit=$(( (i >> (n - 1 - v)) & 1 ))
            assignment="$assignment${var_array[$v]}=$bit "
        done
        echo "$assignment"
    done
}

# ============================================================================
# VALIDITY CHECKING (Figure 16 Step 3-4)
# ============================================================================

# Check if argument is valid
# An argument is valid iff: for all interpretations, if premises are all true, conclusion is true
# Equivalently: there is no counterexample where all premises true and conclusion false
check_validity() {
    local premises="$1"  # Premises joined by ∧
    local conclusion="$2"

    # Extract all atomic propositions
    local all_expr="$premises $conclusion"
    local atoms=$(echo "$all_expr" | grep -oE '\b[A-Z]\b' | sort -u | tr '\n' ' ')

    if [[ -z "$atoms" ]]; then
        # No variables - evaluate directly
        local p_val=$(eval_bool_expr "$premises")
        local c_val=$(eval_bool_expr "$conclusion")
        if [[ "$p_val" == "1" && "$c_val" == "0" ]]; then
            echo "INVALID"
            echo "counterexample: (no variables)"
            return 1
        else
            echo "VALID"
            return 0
        fi
    fi

    # Generate all truth assignments
    local assignments=$(generate_assignments "$atoms")
    local counterexamples=""

    while IFS= read -r assignment; do
        # Evaluate premises
        local p_val=$(eval_bool_expr "$premises" $assignment)

        # If premises are true, check conclusion
        if [[ "$p_val" == "1" ]]; then
            local c_val=$(eval_bool_expr "$conclusion" $assignment)
            if [[ "$c_val" == "0" ]]; then
                # Found counterexample!
                counterexamples="$counterexamples$assignment\n"
            fi
        fi
    done <<< "$assignments"

    if [[ -n "$counterexamples" ]]; then
        echo "INVALID"
        echo "counterexamples:"
        echo -e "$counterexamples" | head -5  # Show first 5
        return 1
    else
        echo "VALID"
        return 0
    fi
}

# ============================================================================
# TRUTH TABLE DISPLAY
# ============================================================================

# Generate and display full truth table for an expression
truth_table() {
    local expr="$1"
    local atoms=$(echo "$expr" | grep -oE '\b[A-Z]\b' | sort -u | tr '\n' ' ')
    local var_array=($atoms)

    # Header
    local header=""
    for v in "${var_array[@]}"; do
        header="$header$v\t"
    done
    header="$header| $expr"
    echo -e "$header"
    echo "---"

    # Rows
    local assignments=$(generate_assignments "$atoms")
    while IFS= read -r assignment; do
        local row=""
        for v in "${var_array[@]}"; do
            local val=$(echo "$assignment" | grep -oP "$v=\K[01]")
            row="$row$val\t"
        done
        local result=$(eval_bool_expr "$expr" $assignment)
        row="$row| $result"
        echo -e "$row"
    done <<< "$assignments"
}

# ============================================================================
# TAUTOLOGY AND CONTRADICTION CHECKING
# ============================================================================

# Check if expression is a tautology (true for all interpretations)
is_tautology() {
    local expr="$1"
    local atoms=$(echo "$expr" | grep -oE '\b[A-Z]\b' | sort -u | tr '\n' ' ')

    if [[ -z "$atoms" ]]; then
        local val=$(eval_bool_expr "$expr")
        [[ "$val" == "1" ]] && return 0 || return 1
    fi

    local assignments=$(generate_assignments "$atoms")
    while IFS= read -r assignment; do
        local val=$(eval_bool_expr "$expr" $assignment)
        if [[ "$val" != "1" ]]; then
            return 1
        fi
    done <<< "$assignments"
    return 0
}

# Check if expression is a contradiction (false for all interpretations)
is_contradiction() {
    local expr="$1"
    local atoms=$(echo "$expr" | grep -oE '\b[A-Z]\b' | sort -u | tr '\n' ' ')

    if [[ -z "$atoms" ]]; then
        local val=$(eval_bool_expr "$expr")
        [[ "$val" == "0" ]] && return 0 || return 1
    fi

    local assignments=$(generate_assignments "$atoms")
    while IFS= read -r assignment; do
        local val=$(eval_bool_expr "$expr" $assignment)
        if [[ "$val" != "0" ]]; then
            return 1
        fi
    done <<< "$assignments"
    return 0
}

# Check if expression is satisfiable (true for at least one interpretation)
is_satisfiable() {
    local expr="$1"
    local atoms=$(echo "$expr" | grep -oE '\b[A-Z]\b' | sort -u | tr '\n' ' ')

    if [[ -z "$atoms" ]]; then
        local val=$(eval_bool_expr "$expr")
        [[ "$val" == "1" ]] && return 0 || return 1
    fi

    local assignments=$(generate_assignments "$atoms")
    while IFS= read -r assignment; do
        local val=$(eval_bool_expr "$expr" $assignment)
        if [[ "$val" == "1" ]]; then
            return 0
        fi
    done <<< "$assignments"
    return 1
}

# ============================================================================
# MAIN PROCESSING (Figure 16)
# ============================================================================

process_argument() {
    local input="$1"

    # Parse input format: "premise1, premise2, ..., premiseN ⊢ conclusion"
    # Or: "premise1 ∧ premise2 ∧ ... ∧ premiseN → conclusion"

    local premises=""
    local conclusion=""

    if [[ "$input" =~ ⊢ ]]; then
        # Turnstile notation
        premises="${input%%⊢*}"
        conclusion="${input#*⊢}"
    elif [[ "$input" =~ →[^→]*$ ]]; then
        # Implication notation (last →)
        premises="${input%→*}"
        conclusion="${input##*→}"
    else
        # Single expression - check if tautology
        if is_tautology "$input"; then
            echo "TAUTOLOGY"
            return 0
        elif is_contradiction "$input"; then
            echo "CONTRADICTION"
            return 1
        elif is_satisfiable "$input"; then
            echo "SATISFIABLE (not tautology)"
            return 0
        else
            echo "UNSATISFIABLE"
            return 1
        fi
    fi

    # Normalize premises (join with ∧ if comma-separated)
    premises=$(echo "$premises" | sed 's/,/ ∧ /g' | tr -s ' ')
    conclusion=$(echo "$conclusion" | tr -s ' ')

    # Check validity
    check_validity "$premises" "$conclusion"
}

# ============================================================================
# COMMAND LINE INTERFACE
# ============================================================================

usage() {
    cat <<EOF
Boolean Logic Engine - Figure 16 Implementation

Usage: $(basename "$0") [OPTIONS] EXPRESSION

OPTIONS:
    -v, --validity    Check argument validity (default)
    -t, --table       Show truth table
    -a, --analyze     Full analysis (tautology/contradiction/satisfiable)
    -h, --help        Show this help

EXPRESSION FORMATS:
    "P ∧ Q → R"           Single expression
    "P, Q ⊢ P ∧ Q"        Turnstile notation (premises ⊢ conclusion)
    "P → Q, Q → R ⊢ P → R" Multiple premises

OPERATORS:
    ¬  NOT (negation)
    ∧  AND (conjunction)
    ∨  OR (disjunction)
    →  IMPLIES (implication)
    ↔  IFF (biconditional)
    ⊤  TRUE
    ⊥  FALSE

EXAMPLES:
    $(basename "$0") "P ∨ ¬P"                    # Tautology check
    $(basename "$0") "P, P → Q ⊢ Q"              # Modus ponens (VALID)
    $(basename "$0") -t "P → Q"                  # Truth table
    $(basename "$0") "P ∧ Q ⊢ P"                 # Simplification (VALID)
EOF
}

main() {
    local mode="validity"
    local expression=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--validity)
                mode="validity"
                shift
                ;;
            -t|--table)
                mode="table"
                shift
                ;;
            -a|--analyze)
                mode="analyze"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                expression="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$expression" ]]; then
        # Read from stdin
        expression=$(cat)
    fi

    if [[ -z "$expression" ]]; then
        usage
        exit 1
    fi

    case "$mode" in
        validity)
            process_argument "$expression"
            ;;
        table)
            truth_table "$expression"
            ;;
        analyze)
            echo "Expression: $expression"
            echo "---"
            if is_tautology "$expression"; then
                echo "Type: TAUTOLOGY (always true)"
            elif is_contradiction "$expression"; then
                echo "Type: CONTRADICTION (always false)"
            elif is_satisfiable "$expression"; then
                echo "Type: CONTINGENT (sometimes true, sometimes false)"
                echo ""
                echo "Truth table:"
                truth_table "$expression"
            fi
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
