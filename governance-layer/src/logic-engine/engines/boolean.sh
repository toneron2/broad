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
# EXPRESSION VALIDATION, TOKENIZATION AND PARSING
# ============================================================================

# The evaluator hands the compiled expression to bash arithmetic through
# eval. Arithmetic expansion performs command substitution first, so any
# character that is not part of the formula language must be rejected before
# it gets near eval: `P ∨ `touch /tmp/x`` would otherwise run the command.
# Allowed: identifiers (letters, digits, _ and = for role=admin style atoms),
# whitespace, parentheses, the comma and turnstile used for argument
# notation, and the propositional operators.
validate_expression() {
    local expr="$1"
    local leftover
    leftover=$(printf '%s' "$expr" | sed 's/[A-Za-z0-9_=, ()¬∧∨→↔⊤⊥⊢]//g')
    if [[ -n "$leftover" ]]; then
        echo "ERROR: unsupported character(s) in expression: $leftover" >&2
        return 1
    fi
    return 0
}

# Compile a propositional formula into a bash arithmetic expression.
#
# Operators are first mapped to single ASCII markers (mawk is byte oriented),
# then a recursive-descent parser builds the arithmetic text with explicit
# parentheses so precedence is always  ¬  >  ∧  >  ∨  >  →  >  ↔  with →
# right associative. Every identifier becomes the shell variable v_<ident>
# (= replaced by _), which is 0 unless the caller assigned it, so the output
# only ever contains identifiers, digits, parentheses and ! & | =.
#
# Prints the arithmetic expression, or "ERROR: ..." on a parse failure.
expr_to_bash() {
    local expr="$1"
    printf '%s' "$expr" | sed \
        -e 's/¬/!/g' -e 's/∧/\&/g' -e 's/∨/|/g' -e 's/→/>/g' -e 's/↔/~/g' \
        -e 's/⊤/ 1 /g' -e 's/⊥/ 0 /g' \
    | awk '
    function next_token() {
        while (pos <= n && substr(src, pos, 1) ~ /[ \t\r\n]/) pos++
        if (pos > n) { tok = "EOF"; return }
        c = substr(src, pos, 1)
        if (c ~ /[A-Za-z_]/) {
            start = pos
            while (pos <= n && substr(src, pos, 1) ~ /[A-Za-z0-9_=]/) pos++
            tok = "ID"; tokval = substr(src, start, pos - start); return
        }
        if (c ~ /[0-9]/) {
            start = pos
            while (pos <= n && substr(src, pos, 1) ~ /[0-9]/) pos++
            tok = "NUM"; tokval = substr(src, start, pos - start); return
        }
        pos++; tok = c
    }
    function fail(msg) { print "ERROR: " msg; failed = 1; exit 1 }
    function parse_iff(  l, r) {
        l = parse_imp()
        while (tok == "~") { next_token(); r = parse_imp(); l = "((" l ")==(" r "))" }
        return l
    }
    function parse_imp(  l, r) {
        l = parse_or()
        if (tok == ">") { next_token(); r = parse_imp(); return "((!(" l "))||(" r "))" }
        return l
    }
    function parse_or(  l, r) {
        l = parse_and()
        while (tok == "|") { next_token(); r = parse_and(); l = "((" l ")||(" r "))" }
        return l
    }
    function parse_and(  l, r) {
        l = parse_not()
        while (tok == "&") { next_token(); r = parse_not(); l = "((" l ")&&(" r "))" }
        return l
    }
    function parse_not(  e) {
        if (tok == "!") { next_token(); e = parse_not(); return "(!(" e "))" }
        return parse_atom()
    }
    function parse_atom(  e, name) {
        if (tok == "(") {
            next_token(); e = parse_iff()
            if (tok != ")") fail("expected ) at position " pos)
            next_token(); return "(" e ")"
        }
        if (tok == "ID") { name = tokval; gsub(/=/, "_", name); next_token(); return "(v_" name ")" }
        if (tok == "NUM") { e = (tokval == "0") ? "0" : "1"; next_token(); return e }
        if (tok == "EOF") fail("unexpected end of expression")
        fail("unexpected token \"" tok "\" at position " pos)
    }
    {
        src = $0; n = length(src); pos = 1; failed = 0
        next_token()
        if (tok == "EOF") fail("empty expression")
        out = parse_iff()
        if (tok != "EOF") fail("unexpected token \"" tok "\" at position " pos)
        print out
    }'
}

declare -A COMPILED_CACHE=()

# Evaluate a boolean expression with given variable assignments
# Args: expression, then VAR=val pairs. Prints 1, 0 or ERROR.
eval_bool_expr() {
    local expr="$1"
    shift

    # Compile once per distinct expression: a truth table evaluates the same
    # formula 2^n times and the sed+awk compile is the only process spawn.
    local bash_expr
    if [[ -n "${COMPILED_CACHE[$expr]+x}" ]]; then
        bash_expr="${COMPILED_CACHE[$expr]}"
    else
        bash_expr=$(expr_to_bash "$expr")
        COMPILED_CACHE[$expr]="$bash_expr"
    fi
    if [[ "$bash_expr" == ERROR* || -z "$bash_expr" ]]; then
        echo "ERROR"
        return 1
    fi

    # Bind atoms. Names were validated by validate_expression and the atom
    # extractor only yields identifiers, so the assignment text is inert.
    # Bind at the LAST "=": the atom itself may contain one (role=admin=1).
    local assignment var val
    for assignment in "$@"; do
        var="${assignment%=*}"
        val="${assignment##*=}"
        local "v_${var//=/_}=$val"
    done

    # Identifiers that are not atoms (lowercase policy terms) are unset and
    # read as 0; allow that lookup under set -u.
    local result
    set +u
    result=$(( bash_expr )) 2>/dev/null || { set -u; echo "ERROR"; return 1; }
    set -u
    echo "$result"
}

# Confirm an expression parses before any truth-table work, so a syntax
# error is reported as such rather than surfacing as UNSATISFIABLE.
check_parses() {
    local expr="$1"
    local compiled
    compiled=$(expr_to_bash "$expr")
    if [[ "$compiled" == ERROR* || -z "$compiled" ]]; then
        echo "${compiled:-ERROR: cannot parse expression}"
        return 1
    fi
    return 0
}

# Split "premises → conclusion" at the FIRST top-level implication (→ is right
# associative, so that is the main connective). Sets SPLIT_LEFT/SPLIT_RIGHT.
split_main_implication() {
    split_top_level "$1" "→"
}

# Read "VAR=val" out of an assignment line. Sets ATOM_VAL.
lookup_assignment() {
    local var="$1" assignment="$2"
    if [[ " $assignment " == *" $var=1 "* ]]; then ATOM_VAL=1; else ATOM_VAL=0; fi
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
    local atoms=$(extract_atoms "$all_expr")

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
    local atoms=$(extract_atoms "$expr")
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
            local val
            lookup_assignment "$v" "$assignment"; val="$ATOM_VAL"
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
    local atoms=$(extract_atoms "$expr")

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
    local atoms=$(extract_atoms "$expr")

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
    local atoms=$(extract_atoms "$expr")

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
    # Or a single formula, which may itself be an implication.

    if [[ "$input" == *⊢* ]]; then
        local premises="${input%%⊢*}"
        local conclusion="${input#*⊢}"
        # Each comma-separated premise is a formula in its own right, so
        # parenthesise before joining: "P, P → Q" is (P) ∧ (P → Q), not
        # (P ∧ P) → Q.
        local joined="" part
        IFS=',' read -ra parts <<< "$premises"
        for part in "${parts[@]}"; do
            trim_ws "$part"; part="$TRIMMED"
            [[ -z "$part" ]] && continue
            joined="${joined:+$joined ∧ }($part)"
        done
        premises="${joined:-⊤}"
        conclusion=$(echo "$conclusion" | tr -s ' ')
        check_parses "$premises" || return 2
        check_parses "$conclusion" || return 2
        check_validity "$premises" "$conclusion"
        return
    fi

    check_parses "$input" || return 2

    if is_tautology "$input"; then
        echo "TAUTOLOGY"
        return 0
    elif is_contradiction "$input"; then
        echo "CONTRADICTION"
        return 1
    fi

    # Contingent. If the main connective is an implication, report it as an
    # invalid argument with the assignments that break it.
    if split_main_implication "$input"; then
        check_validity "$SPLIT_LEFT" "$SPLIT_RIGHT"
        return
    fi

    echo "SATISFIABLE (not tautology)"
    return 0
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

    validate_expression "$expression" || exit 2

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
