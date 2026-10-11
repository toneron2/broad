#!/bin/bash
# engines/meta.sh - Meta-Engine for Agentic Logic Composition
# Figure 24-26: Cross-System Translation and Adaptive Processing
# Patent: Unicode Semantic Dictionary and Multi-Logic Processing Architecture
#
# The Meta-Engine is the key innovation: it enables on-the-fly composition of
# multiple logic paradigms for complex agentic reasoning tasks.
#
# CAPABILITIES:
#   1. Multi-paradigm expression decomposition
#   2. Cross-system translation (Figure 25 matrix)
#   3. Parallel evaluation across paradigms
#   4. Inter-paradigm conflict detection
#   5. Confidence aggregation
#   6. Dynamic engine composition
#
# USE CASES:
#   - ESN Access Agent: deontic + temporal + modal constraints
#   - Policy reasoning: obligation within necessity contexts
#   - Agentic decisions: combining epistemic + deontic + fuzzy confidence
#
# INPUT: Multi-paradigm expression
# OUTPUT: Unified evaluation with cross-system validation

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

ENGINE_DIR="${SCRIPT_DIR}"

# ============================================================================
# CROSS-SYSTEM TRANSLATION MATRIX (Figure 25)
# ============================================================================

# Translation rules between paradigms
# Format: SOURCE_PARADIGM:TARGET_PARADIGM:PATTERN:TRANSLATION

declare -A TRANSLATION_MATRIX

# Modal ↔ Deontic translations
TRANSLATION_MATRIX["modal:deontic:□"]="O"      # Necessity → Obligation (in normative context)
TRANSLATION_MATRIX["deontic:modal:O"]="□"      # Obligation → Necessity (idealized)
TRANSLATION_MATRIX["modal:deontic:◇"]="P"      # Possibility → Permission
TRANSLATION_MATRIX["deontic:modal:P"]="◇"      # Permission → Possibility

# Modal ↔ Temporal translations (LTL)
TRANSLATION_MATRIX["modal:temporal:□"]="G"     # Necessity → Globally (always)
TRANSLATION_MATRIX["modal:temporal:◇"]="F"     # Possibility → Finally (eventually)

# Boolean ↔ Fuzzy boundary
# (fuzzy threshold: ≥0.5 → true, <0.5 → false)

# Epistemic ↔ Modal translations
TRANSLATION_MATRIX["epistemic:modal:K"]="□"    # Knowledge → Necessity (in epistemic context)
TRANSLATION_MATRIX["epistemic:modal:B"]="◇"    # Belief → Possibility (weaker)

# ============================================================================
# PARADIGM DECOMPOSITION
# ============================================================================

# Project a multi-paradigm expression onto its propositional skeleton for
# the boolean engine: drop □ ◇ and replace the deontic operators by their
# operand, keeping parentheses balanced. "□O(P) → P(Q)" becomes "(P) → (Q)".
boolean_projection() {
    echo "$1" | sed -E 's/[□◇]//g; s/\b[OPF]\(/(/g'
}

# Projection for the modal engine: keep □ ◇, read each deontic claim as its
# propositional content. "□O(P) → P(Q)" becomes "□(P) → (Q)".
modal_projection() {
    echo "$1" | sed -E 's/\b[OPF]\(/(/g'
}

# Projection for the deontic engine: read □X / ◇X as X (the Figure 25
# idealisation, □ ↔ O). "□O(P) → O(P)" becomes "O(P) → O(P)".
deontic_projection() {
    echo "$1" | sed -E 's/[□◇]//g'
}

# Identify which paradigms are present in an expression
detect_paradigms() {
    local expr="$1"
    local paradigms=""

    # Always include boolean as base
    paradigms="boolean"

    # Check for modal operators
    if [[ "$expr" =~ [□◇] ]]; then
        paradigms="$paradigms modal"
    fi

    # Check for deontic operators
    if echo "$expr" | grep -qE '[OPF]\('; then
        paradigms="$paradigms deontic"
    fi

    # Check for epistemic operators
    if echo "$expr" | grep -qE '[KB]_'; then
        paradigms="$paradigms epistemic"
    fi

    # Check for temporal operators
    if [[ "$expr" =~ ○ ]] || echo "$expr" | grep -qE '\bG\b|\bF\b|\bU\b'; then
        paradigms="$paradigms temporal"
    fi

    # Check for fuzzy values
    if echo "$expr" | grep -qE '0\.[0-9]+|1\.0'; then
        paradigms="$paradigms fuzzy"
    fi

    # Check for quantifiers
    if [[ "$expr" =~ [∀∃] ]]; then
        paradigms="$paradigms fol"
    fi

    echo "$paradigms"
}

# Decompose expression into paradigm-specific sub-expressions
decompose_expression() {
    local expr="$1"
    local paradigms="$2"

    # For now, evaluate the expression as a whole but track which
    # engines were invoked. More sophisticated decomposition can
    # split nested expressions.

    echo "ORIGINAL:$expr"

    for p in $paradigms; do
        case "$p" in
            boolean)
                # Base propositional structure
                local bool_expr=$(boolean_projection "$expr")
                echo "BOOLEAN:$bool_expr"
                ;;
            modal)
                # Extract modal sub-expressions
                local modal_subs=$(echo "$expr" | grep -oE '[□◇][A-Z(][^∧∨→]*')
                for sub in $modal_subs; do
                    echo "MODAL:$sub"
                done
                ;;
            deontic)
                # Extract deontic sub-expressions
                local deontic_subs=$(echo "$expr" | grep -oE '[OPF]\([^)]+\)')
                for sub in $deontic_subs; do
                    echo "DEONTIC:$sub"
                done
                ;;
        esac
    done
}

# ============================================================================
# CROSS-SYSTEM VALIDATION
# ============================================================================

# Check for inter-paradigm conflicts
check_cross_system_conflicts() {
    local expr="$1"
    local paradigms="$2"
    local conflicts=""

    # Deontic + Modal conflict: □¬P ∧ O(P) is inconsistent
    # (Necessarily not P, but P is obligatory)
    if [[ "$paradigms" =~ modal ]] && [[ "$paradigms" =~ deontic ]]; then
        # Check for □¬X and O(X)
        local necessary_nots=$(echo "$expr" | grep -oE '□¬[A-Z]' | sed 's/□¬//')
        local obligations=$(echo "$expr" | grep -oE 'O\([^)]+\)' | sed 's/O(//;s/)//')

        for neg in $necessary_nots; do
            for obl in $obligations; do
                if [[ "$neg" == "$obl" ]]; then
                    conflicts="$conflicts CONFLICT: □¬$neg inconsistent with O($obl)"
                fi
            done
        done
    fi

    # Modal + Deontic: ◇P and F(P) is problematic
    # (P is possible but forbidden)
    if [[ "$paradigms" =~ modal ]] && [[ "$paradigms" =~ deontic ]]; then
        local possibles=$(echo "$expr" | grep -oE '◇[A-Z]' | sed 's/◇//')
        local forbiddens=$(echo "$expr" | grep -oE 'F\([^)]+\)' | sed 's/F(//;s/)//')

        for poss in $possibles; do
            for forb in $forbiddens; do
                if [[ "$poss" == "$forb" ]]; then
                    # This is a warning, not necessarily inconsistent
                    conflicts="$conflicts WARNING: ◇$poss with F($forb) - possible but forbidden"
                fi
            done
        done
    fi

    if [[ -n "$conflicts" ]]; then
        echo "$conflicts"
        return 1
    fi

    echo "NO_CONFLICTS"
    return 0
}

# ============================================================================
# PARALLEL ENGINE EVALUATION
# ============================================================================

# Evaluate expression across multiple paradigms
evaluate_multiparadigm() {
    local expr="$1"
    local paradigms="$2"

    local results=""
    local primary_result=""
    local confidence="1.0"

    for p in $paradigms; do
        case "$p" in
            boolean)
                if [[ -x "${ENGINE_DIR}/boolean.sh" ]]; then
                    local bool_result=$("${ENGINE_DIR}/boolean.sh" "$(boolean_projection "$expr")" 2>&1) || true
                    results="$results\nBOOLEAN: $bool_result"
                    if [[ -z "$primary_result" ]]; then
                        primary_result="$bool_result"
                    fi
                fi
                ;;
            modal)
                if [[ -x "${ENGINE_DIR}/modal.sh" ]]; then
                    local modal_result=$("${ENGINE_DIR}/modal.sh" "$(modal_projection "$expr")" 2>&1) || true
                    results="$results\nMODAL: $modal_result"
                    primary_result="$modal_result"
                fi
                ;;
            deontic)
                if [[ -x "${ENGINE_DIR}/deontic.sh" ]]; then
                    local deontic_result=$("${ENGINE_DIR}/deontic.sh" "$(deontic_projection "$expr")" 2>&1) || true
                    results="$results\nDEONTIC: $deontic_result"
                    primary_result="$deontic_result"
                fi
                ;;
            fuzzy)
                # Fuzzy engine would provide confidence values
                # For now, estimate from expression
                local fuzzy_vals=$(echo "$expr" | grep -oE '0\.[0-9]+|1\.0')
                if [[ -n "$fuzzy_vals" ]]; then
                    # Use minimum fuzzy value as confidence
                    confidence=$(echo "$fuzzy_vals" | sort -n | head -1)
                fi
                results="$results\nFUZZY: confidence=$confidence"
                ;;
        esac
    done

    echo "PRIMARY_RESULT: $primary_result"
    echo "CONFIDENCE: $confidence"
    echo "PARADIGMS_EVALUATED: $paradigms"
    echo -e "DETAILED_RESULTS:$results"
}

# ============================================================================
# AGENTIC COMPOSITION
# ============================================================================

# Compose a new reasoning task from multiple paradigms
# This is the key Figure 26 capability for on-the-fly logic composition
compose_reasoning() {
    local task="$1"
    local context="${2:-}"

    echo "=== AGENTIC COMPOSITION ==="
    echo "Task: $task"
    echo "Context: $context"
    echo ""

    # Step 1: Detect required paradigms
    local paradigms=$(detect_paradigms "$task")
    echo "Detected Paradigms: $paradigms"

    # Step 2: Decompose into sub-tasks
    echo ""
    echo "--- Decomposition ---"
    decompose_expression "$task" "$paradigms"

    # Step 3: Check for cross-system conflicts
    echo ""
    echo "--- Cross-System Validation ---"
    local conflict_check=$(check_cross_system_conflicts "$task" "$paradigms")
    echo "$conflict_check"

    # Step 4: Evaluate across paradigms
    echo ""
    echo "--- Multi-Paradigm Evaluation ---"
    evaluate_multiparadigm "$task" "$paradigms"
}

# ============================================================================
# ESN ACCESS CONTROL COMPOSITION
# ============================================================================

# Specialized composition for ESN access control scenarios.
#
#   esn_access_decision POLICY REQUEST
#
# POLICY is a formal policy such as "(O(auth) ∧ O(role=nurse)) → P(read)".
# REQUEST is what is true of this request: facts joined by ∧, each optionally
# negated with ¬ ("auth ∧ role=nurse ∧ ¬verify"). A fact not listed is false.
#
# Decision procedure:
#   1. CONFLICT  if the policy is deontically inconsistent (O(x) ∧ F(x)) or
#                has a cross-paradigm conflict (□¬x ∧ O(x)).
#   2. DENY      if the request asserts a fact the policy forbids (F(x)).
#   3. The policy's antecedent (everything before the main →, or ⊤ if there
#      is none) is evaluated under the request's facts: each O(x), □x, G(x)
#      is read as "x holds", the result is a propositional formula with ⊤/⊥
#      substituted, decided by the boolean engine.
#      DENY      if the antecedent is false (a precondition is not met) or
#                cannot be evaluated.
#   4. ALLOW     if the consequent grants a permission P(x);
#      DENY      otherwise (deny by default: no permission was granted).
# The verdict is the last line, "DECISION: ALLOW|DENY|CONFLICT (reason)".

# Read ∧-separated facts into ESN_FACTS (true) and ESN_NEGATED (asserted false).
parse_request() {
    local request="$1" part
    ESN_FACTS=(); ESN_NEGATED=()
    [[ -z "${request// /}" ]] && return 0
    while IFS= read -r part; do
        trim_ws "$part"; part="$TRIMMED"
        [[ -z "$part" ]] && continue
        if [[ "$part" == ¬* ]]; then
            trim_ws "${part#¬}"; ESN_NEGATED+=("$TRIMMED")
        else
            ESN_FACTS+=("$part")
        fi
    done < <(echo "$request" | sed 's/∧/\n/g')
}

fact_holds() {
    local f
    for f in "${ESN_FACTS[@]}"; do [[ "$f" == "$1" ]] && return 0; done
    return 1
}

# Does one projected conjunct of an antecedent hold under the request's facts?
# A bare atom, or a disjunction of bare atoms (every line in access.policy), is
# decided here without starting a process; anything else is substituted and
# handed to the boolean engine, as the whole antecedent is.
conj_holds() {
    local c rest alt atom
    strip_outer_parens "$1"; c="$STRIPPED"
    if [[ "$c" != *"∧"* && "$c" != *"¬"* && "$c" != *"→"* && "$c" != *"↔"* ]]; then
        rest="$c"
        while :; do
            if split_top_level "$rest" "∨"; then alt="$SPLIT_LEFT"; rest="$SPLIT_RIGHT"
            else alt="$rest"; rest=""; fi
            strip_outer_parens "$alt"; alt="$STRIPPED"
            [[ "$alt" == *"("* || "$alt" == *"∨"* ]] && break   # nested: the boolean engine decides
            fact_holds "$alt" && return 0
            [[ -z "$rest" ]] && return 1
        done
    fi
    local part="$c"
    for atom in $(extract_atoms "$c"); do
        if fact_holds "$atom"; then part=$(echo "$part" | sed -E "s/\b${atom}\b/⊤/g")
        else part=$(echo "$part" | sed -E "s/\b${atom}\b/⊥/g"); fi
    done
    [[ "$("${ENGINE_DIR}/boolean.sh" "$part" 2>&1 | head -1)" != CONTRADICTION ]]
}

esn_access_decision() {
    local policy="$1"
    local request="${2:-}"

    echo "=== ESN ACCESS CONTROL DECISION ==="
    echo "Policy:  $policy"
    echo "Request: ${request:-(no facts)}"
    echo ""

    local paradigms=$(detect_paradigms "$policy")
    echo "Policy Paradigms: $paradigms"

    # Step 1: the policy itself must be coherent
    echo ""
    echo "--- Policy Consistency ---"
    if [[ "$paradigms" =~ deontic ]]; then
        local deontic_check=$("${ENGINE_DIR}/deontic.sh" -t "$(deontic_projection "$policy")" 2>&1) || true
        echo "$deontic_check"
        if [[ "$deontic_check" =~ INCONSISTENT ]]; then
            echo ""
            echo "DECISION: CONFLICT (policy is deontically inconsistent)"
            return 2
        fi
    fi
    local cross_check=$(check_cross_system_conflicts "$policy" "$paradigms") || true
    echo "$cross_check"
    # Whole-word: the no-conflict answer is the single token NO_CONFLICTS
    if [[ "$cross_check" =~ (^|[[:space:]])CONFLICT: ]]; then
        echo ""
        echo "DECISION: CONFLICT (cross-paradigm conflict in policy)"
        return 2
    fi

    # Step 2: nothing requested may be forbidden
    parse_request "$request"
    echo ""
    echo "--- Request Facts ---"
    echo "true:  ${ESN_FACTS[*]:-(none)}"
    echo "false: ${ESN_NEGATED[*]:-(none)}"

    local forbidden f
    while IFS= read -r forbidden; do
        [[ -z "$forbidden" ]] && continue
        if fact_holds "$forbidden"; then
            echo ""
            echo "DECISION: DENY (request asserts forbidden act F($forbidden))"
            return 1
        fi
    done < <(echo "$policy" | grep -oE '\bF\([^)]+\)' | sed -E 's/^F\((.*)\)$/\1/')

    # Step 3: the antecedent must hold under the request's facts
    local antecedent consequent
    if split_top_level "$policy" "→"; then
        antecedent="$SPLIT_LEFT"; consequent="$SPLIT_RIGHT"
    else
        antecedent="⊤"; consequent="$policy"
    fi

    # Read O(x) / □x / G(x) in the antecedent as "x holds", then substitute
    # the request's truth values and let the boolean engine decide.
    local projected=$(echo "$antecedent" | sed -E 's/[□◇]//g; s/\b[OPFG]\(/(/g')
    local atoms=$(extract_atoms "$projected")
    local substituted="$projected" atom
    for atom in $atoms; do
        if fact_holds "$atom"; then
            substituted=$(echo "$substituted" | sed -E "s/\b${atom}\b/⊤/g")
        else
            substituted=$(echo "$substituted" | sed -E "s/\b${atom}\b/⊥/g")
        fi
    done
    local verdict=$("${ENGINE_DIR}/boolean.sh" "$substituted" 2>&1 | head -1) || true

    echo ""
    echo "--- Antecedent Evaluation ---"
    echo "antecedent:  $antecedent"
    echo "under facts: $substituted"
    echo "boolean:     $verdict"

    case "$verdict" in
        TAUTOLOGY) ;;
        CONTRADICTION)
            # Name the top-level conjuncts that fail, not every false atom: under
            # auth ∧ (role=nurse ∨ role=provider) ∧ session, a nurse without a
            # session is missing "session", not the roles she does not hold.
            local unmet="" rest conj
            strip_outer_parens "$projected"; rest="$STRIPPED"
            while :; do
                if split_top_level "$rest" "∧"; then conj="$SPLIT_LEFT"; rest="$SPLIT_RIGHT"
                else conj="$rest"; rest=""; fi
                strip_outer_parens "$conj"; conj="$STRIPPED"
                conj_holds "$conj" || unmet="${unmet:+$unmet,} $(echo "$conj" | sed -E 's/\(([^() ]+)\)/\1/g')"
                [[ -z "$rest" ]] && break
            done
            echo ""
            echo "DECISION: DENY (precondition not met:${unmet:- antecedent false})"
            return 1 ;;
        *)
            echo ""
            echo "DECISION: DENY (antecedent could not be evaluated: $verdict)"
            return 1 ;;
    esac

    # Step 4: what does the policy grant?
    local granted=$(echo "$consequent" | grep -oE '\bP\([^)]+\)' | sed -E 's/^P\((.*)\)$/\1/' | tr '\n' ' ')
    granted="${granted% }"
    echo ""
    echo "--- Consequent ---"
    echo "consequent: $consequent"
    if [[ -n "${granted// /}" ]]; then
        echo "permits:    $granted"
        echo ""
        echo "DECISION: ALLOW (permission granted: $granted)"
        return 0
    fi
    echo "permits:    (nothing)"
    echo ""
    echo "DECISION: DENY (policy grants no permission for this request)"
    return 1
}

# ============================================================================
# MAIN
# ============================================================================

usage() {
    cat <<EOF
Meta-Engine - Figure 24-26 Agentic Logic Composition

Usage: $(basename "$0") [OPTIONS] EXPRESSION [PARADIGMS]
       $(basename "$0") -a POLICY [REQUEST]

OPTIONS:
    -c, --compose     Compose reasoning task (default)
    -v, --validate    Cross-system validation only
    -a, --access      ESN access control: decide REQUEST against POLICY.
                      REQUEST is ∧-separated facts, ¬ negates, unlisted is false.
                      Last line is DECISION: ALLOW | DENY | CONFLICT (reason)
    -d, --decompose   Decompose expression by paradigm
    -h, --help        Show this help

MULTI-PARADIGM EXAMPLES:
    $(basename "$0") "□O(P) → O(P)"                    # Modal-Deontic
    $(basename "$0") "K_a(O(P)) → B_a(P)"              # Epistemic-Deontic
    $(basename "$0") "□(0.8) → P(action)"              # Modal-Fuzzy-Deontic
    $(basename "$0") -a "O(auth) → P(access)" "auth"            # DECISION: ALLOW
    $(basename "$0") -a "O(auth) → P(access)" "¬auth"           # DECISION: DENY
    $(basename "$0") -a "O(role=admin) → P(delete)" "role=user" # DECISION: DENY
    $(basename "$0") -a "O(x) ∧ F(x)" "x"                       # DECISION: CONFLICT

FIGURE 26 WORKFLOW:
    1. Enhanced Input Analysis  → detect paradigms
    2. Engine Selection         → route to engines
    3. Cross-System Validation  → check conflicts
    4. Response Generation      → unified result

ESN ACCESS CONTROL:
    Combines deontic (O/P/F), modal (□/◇), and temporal (○/G/F/U) logic
    for comprehensive governance policy evaluation.

CROSS-SYSTEM TRANSLATIONS (Figure 25):
    □ ↔ O  (necessity ↔ obligation)
    ◇ ↔ P  (possibility ↔ permission)
    □ ↔ G  (necessity ↔ globally)
    ◇ ↔ F  (possibility ↔ finally)
EOF
}

main() {
    local mode="compose"
    local expression=""
    local paradigms=""     # second positional: paradigms, or the REQUEST in -a mode

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--compose)
                mode="compose"
                shift
                ;;
            -v|--validate)
                mode="validate"
                shift
                ;;
            -a|--access)
                mode="access"
                shift
                ;;
            -d|--decompose)
                mode="decompose"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                if [[ -z "$expression" ]]; then
                    expression="$1"
                else
                    paradigms="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$expression" ]]; then
        if [[ ! -t 0 ]]; then
            expression=$(cat)
        else
            usage
            exit 1
        fi
    fi

    # Auto-detect paradigms if not provided (in -a mode the second
    # positional is the request, left as given, possibly empty)
    if [[ -z "$paradigms" && "$mode" != "access" ]]; then
        paradigms=$(detect_paradigms "$expression")
    fi

    case "$mode" in
        compose)
            compose_reasoning "$expression" "$paradigms"
            ;;
        validate)
            check_cross_system_conflicts "$expression" "$paradigms"
            ;;
        decompose)
            decompose_expression "$expression" "$paradigms"
            ;;
        access)
            esn_access_decision "$expression" "$paradigms"
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
