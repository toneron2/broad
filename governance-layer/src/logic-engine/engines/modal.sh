#!/bin/bash
# engines/modal.sh - Modal Logic Engine
# Figure 17: Expanded Logic System Processing Architecture Flow (Modal Engine)
# Patent: Unicode Semantic Dictionary and Multi-Logic Processing Architecture
#
# Implements Kripke semantics for modal logic systems K, D, T, S4, S5
#
# OPERATORS:
#   □P  - Necessary P (true in all accessible worlds)
#   ◇P  - Possible P (true in at least one accessible world)
#
# SYSTEMS (based on accessibility relation properties):
#   K  - Minimal modal logic (no restrictions)
#   T  - Reflexive (□P → P is valid)
#   S4 - Reflexive + Transitive (□P → □□P)
#   S5 - Equivalence relation (◇P → □◇P)
#
# INPUT: Modal expression with □, ◇, and propositional connectives
# OUTPUT: VALID / INVALID / SATISFIABLE with model info

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# ============================================================================
# KRIPKE MODEL REPRESENTATION
# ============================================================================

# A Kripke model consists of:
# - W: Set of possible worlds (numbered 0, 1, 2, ...)
# - R: Accessibility relation (pairs "w1:w2" meaning w1 can access w2)
# - V: Valuation function (world:prop=val)

# Validity in a modal system means truth at every world of every model on
# every frame with the system's property. Enumerate all accessibility
# relations over n worlds and keep those with the property:
#   K  : any relation            D  : serial (every world sees some world)
#   T  : reflexive               S4 : reflexive + transitive
#   S5 : reflexive + transitive + symmetric (equivalence)
# Checking a single complete relation, as earlier versions did, is checking
# an S5 frame and reports S5 theorems as valid in K.
generate_frames() {
    local n_worlds="$1"
    local system="${2:-K}"
    local pairs=() w1 w2 n_pairs mask rel bit a b c ok

    for ((w1 = 0; w1 < n_worlds; w1++)); do
        for ((w2 = 0; w2 < n_worlds; w2++)); do
            pairs+=("$w1:$w2")
        done
    done
    n_pairs=${#pairs[@]}

    for ((mask = 0; mask < (1 << n_pairs); mask++)); do
        rel=""
        for ((bit = 0; bit < n_pairs; bit++)); do
            if (( (mask >> bit) & 1 )); then rel="$rel ${pairs[bit]}"; fi
        done
        rel="${rel# }"
        ok=1
        case "$system" in
            K) ;;
            D)
                for ((a = 0; a < n_worlds; a++)); do
                    [[ " $rel " == *" $a:"* ]] || { ok=0; break; }
                done ;;
            T|S4|S5)
                for ((a = 0; a < n_worlds; a++)); do
                    [[ " $rel " == *" $a:$a "* ]] || { ok=0; break; }
                done
                if ((ok)) && [[ "$system" != T ]]; then
                    for ((a = 0; a < n_worlds && ok; a++)); do
                        for ((b = 0; b < n_worlds && ok; b++)); do
                            [[ " $rel " == *" $a:$b "* ]] || continue
                            if [[ "$system" == S5 ]] && [[ " $rel " != *" $b:$a "* ]]; then ok=0; break; fi
                            for ((c = 0; c < n_worlds; c++)); do
                                if [[ " $rel " == *" $b:$c "* && " $rel " != *" $a:$c "* ]]; then ok=0; break; fi
                            done
                        done
                    done
                fi ;;
            *)
                echo "ERROR: unknown modal system '$system' (use K, D, T, S4, S5)" >&2
                return 1 ;;
        esac
        ((ok)) && echo "$rel"
    done
}

# Atoms of a modal expression: every identifier once any deontic operator
# letters O( P( F( have been projected away.
modal_atoms() {
    extract_atoms "$(echo "$1" | sed -E 's/\b[OPF]\(/(/g')"
}

# World list "0 1 ... n-1"
world_list() {
    local n="$1" w out=""
    for ((w = 0; w < n; w++)); do out="$out $w"; done
    echo "${out# }"
}

# Generate all valuations for atoms across worlds
generate_valuations() {
    local worlds="$1"
    local atoms="$2"

    local world_arr=($worlds)
    local atom_arr=($atoms)
    local n_worlds=${#world_arr[@]}
    local n_atoms=${#atom_arr[@]}

    if [[ $n_atoms -eq 0 ]]; then
        echo ""
        return
    fi

    # Total combinations: 2^(n_worlds * n_atoms)
    local n_pairs=$((n_worlds * n_atoms))
    local total=$((2 ** n_pairs))

    # Limit to prevent explosion, but say so: a VALID verdict after
    # truncation has only been checked against part of the model space.
    if [[ $total -gt 256 ]]; then
        echo "WARNING: $total valuations truncated to 256; verdict is partial" >&2
        total=256
    fi

    for ((i = 0; i < total; i++)); do
        local valuation=""
        local bit=0
        for w in "${world_arr[@]}"; do
            for a in "${atom_arr[@]}"; do
                local val=$(( (i >> bit) & 1 ))
                valuation="$valuation $w:$a=$val"
                bit=$((bit + 1))
            done
        done
        echo "$valuation"
    done
}

# ============================================================================
# MODAL EXPRESSION EVALUATION
# ============================================================================

# Check if world w1 can access world w2
can_access() {
    local w1="$1"
    local w2="$2"
    local relations="$3"

    [[ " $relations " == *" $w1:$w2 "* ]]
}

# Evaluate a modal expression at a world. Result is left in MODAL_VAL (0/1)
# rather than printed, so the recursion costs no subshells.
#
# Precedence, lowest first: ↔  →  ∨  ∧  then the unary ¬ □ ◇. Binary
# connectives are split at paren depth 0 only, so "(P ∧ Q) → R" is read as
# written rather than as "(P" ∧ "Q) → R".
eval_modal_at_world() {
    local world="$1"
    local expr="$2"
    local worlds="$3"
    local relations="$4"
    local valuation="$5"
    local left right v1 v2 inner w2

    strip_outer_parens "$expr"; expr="$STRIPPED"

    if split_top_level "$expr" "↔"; then
        left="$SPLIT_LEFT"; right="$SPLIT_RIGHT"
        eval_modal_at_world "$world" "$left" "$worlds" "$relations" "$valuation"; v1=$MODAL_VAL
        eval_modal_at_world "$world" "$right" "$worlds" "$relations" "$valuation"; v2=$MODAL_VAL
        [[ "$v1" == "$v2" ]] && MODAL_VAL=1 || MODAL_VAL=0
        return
    fi
    if split_top_level "$expr" "→"; then
        left="$SPLIT_LEFT"; right="$SPLIT_RIGHT"
        eval_modal_at_world "$world" "$left" "$worlds" "$relations" "$valuation"; v1=$MODAL_VAL
        if [[ "$v1" == "0" ]]; then MODAL_VAL=1; return; fi
        eval_modal_at_world "$world" "$right" "$worlds" "$relations" "$valuation"
        return
    fi
    if split_top_level "$expr" "∨"; then
        left="$SPLIT_LEFT"; right="$SPLIT_RIGHT"
        eval_modal_at_world "$world" "$left" "$worlds" "$relations" "$valuation"; v1=$MODAL_VAL
        if [[ "$v1" == "1" ]]; then MODAL_VAL=1; return; fi
        eval_modal_at_world "$world" "$right" "$worlds" "$relations" "$valuation"
        return
    fi
    if split_top_level "$expr" "∧"; then
        left="$SPLIT_LEFT"; right="$SPLIT_RIGHT"
        eval_modal_at_world "$world" "$left" "$worlds" "$relations" "$valuation"; v1=$MODAL_VAL
        if [[ "$v1" == "0" ]]; then MODAL_VAL=0; return; fi
        eval_modal_at_world "$world" "$right" "$worlds" "$relations" "$valuation"
        return
    fi

    # Unary operators
    if [[ "$expr" == □* ]]; then
        inner="${expr#□}"
        for w2 in $worlds; do
            if can_access "$world" "$w2" "$relations"; then
                eval_modal_at_world "$w2" "$inner" "$worlds" "$relations" "$valuation"
                if [[ "$MODAL_VAL" == "0" ]]; then MODAL_VAL=0; return; fi
            fi
        done
        MODAL_VAL=1
        return
    fi
    if [[ "$expr" == ◇* ]]; then
        inner="${expr#◇}"
        for w2 in $worlds; do
            if can_access "$world" "$w2" "$relations"; then
                eval_modal_at_world "$w2" "$inner" "$worlds" "$relations" "$valuation"
                if [[ "$MODAL_VAL" == "1" ]]; then MODAL_VAL=1; return; fi
            fi
        done
        MODAL_VAL=0
        return
    fi
    if [[ "$expr" == ¬* ]]; then
        inner="${expr#¬}"
        eval_modal_at_world "$world" "$inner" "$worlds" "$relations" "$valuation"
        [[ "$MODAL_VAL" == "1" ]] && MODAL_VAL=0 || MODAL_VAL=1
        return
    fi

    # Constants and atoms
    if [[ "$expr" == "⊤" ]]; then MODAL_VAL=1; return; fi
    if [[ "$expr" == "⊥" ]]; then MODAL_VAL=0; return; fi
    if [[ "$expr" =~ ^[A-Za-z_][A-Za-z0-9_=]*$ ]]; then
        lookup_valuation "$world" "$expr" "$valuation"; MODAL_VAL=$ATOM_VAL
        return
    fi

    # Anything else (an unprojected deontic operator, a stray token) is
    # outside the modal fragment: treat as an unknown proposition that is
    # false.
    MODAL_VAL=0
}

# ============================================================================
# VALIDITY CHECKING
# ============================================================================

# Check if formula is valid in given modal system: true at every world of
# every model on every frame (with the system's property) over n worlds.
check_modal_validity() {
    local expr="$1"
    local system="${2:-K}"
    local n_worlds="${3:-2}"  # Default to 2 worlds for tractability

    local atoms=$(modal_atoms "$expr")
    local worlds=$(world_list "$n_worlds")
    local frames
    frames=$(generate_frames "$n_worlds" "$system") || return 2
    local valuations=$(generate_valuations "$worlds" "$atoms")
    [[ -z "$valuations" ]] && valuations=" "

    local relations valuation w
    while IFS= read -r relations; do
        while IFS= read -r valuation; do
            for w in $worlds; do
                eval_modal_at_world "$w" "$expr" "$worlds" "$relations" "$valuation"
                if [[ "$MODAL_VAL" == "0" ]]; then
                    echo "INVALID in $system"
                    echo "counterexample: world=$w frame={${relations}} valuation=${valuation# }"
                    return 1
                fi
            done
        done <<< "$valuations"
    done <<< "$frames"

    echo "VALID in $system (all frames with ${n_worlds} worlds)"
    return 0
}

# Check satisfiability (is there a model where formula is true somewhere?)
check_modal_satisfiability() {
    local expr="$1"
    local system="${2:-K}"
    local n_worlds="${3:-2}"

    local atoms=$(modal_atoms "$expr")
    local worlds=$(world_list "$n_worlds")
    local frames
    frames=$(generate_frames "$n_worlds" "$system") || return 2
    local valuations=$(generate_valuations "$worlds" "$atoms")
    [[ -z "$valuations" ]] && valuations=" "

    local relations valuation w
    while IFS= read -r relations; do
        while IFS= read -r valuation; do
            for w in $worlds; do
                eval_modal_at_world "$w" "$expr" "$worlds" "$relations" "$valuation"
                if [[ "$MODAL_VAL" == "1" ]]; then
                    echo "SATISFIABLE in $system"
                    echo "witness: world=$w frame={${relations}} valuation=${valuation# }"
                    return 0
                fi
            done
        done <<< "$valuations"
    done <<< "$frames"

    echo "UNSATISFIABLE in $system"
    return 1
}

# ============================================================================
# STANDARD MODAL THEOREMS
# ============================================================================

# Recognise the classic axioms by shape and name them. This is an
# annotation only; the verdict for the requested system always comes from
# model checking below (the T axiom is valid in T but not in K, and only the
# frame enumeration knows which system was asked for).
annotate_theorem() {
    local expr="$1"
    local compact="${expr// /}"

    if [[ "$compact" =~ ^□\(.*→.*\)→\(□.*→□.*\)$ ]]; then
        echo "K-AXIOM (distribution): valid in all normal modal logics"
    elif [[ "$compact" =~ ^□[A-Z]→[A-Z]$ ]]; then
        echo "T-AXIOM (reflexivity): valid in T, S4, S5; not in K or D"
    elif [[ "$compact" =~ ^□[A-Z]→□□[A-Z]$ ]]; then
        echo "4-AXIOM (transitivity): valid in S4, S5; not in K, D, T"
    elif [[ "$compact" =~ ^◇[A-Z]→□◇[A-Z]$ ]]; then
        echo "5-AXIOM (euclidean): valid in S5 only"
    elif [[ "$compact" =~ ^□[A-Z]→◇[A-Z]$ ]]; then
        echo "D-AXIOM (seriality): valid in D, T, S4, S5; not in K"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

usage() {
    cat <<EOF
Modal Logic Engine - Figure 17 Implementation (Kripke Semantics)

Usage: $(basename "$0") [OPTIONS] EXPRESSION

OPTIONS:
    -s, --system SYSTEM   Modal system: K, D, T, S4, S5 (default: K)
    -w, --worlds N        Number of worlds per frame (default: 2). Some
                          non-theorems need 3 worlds to refute, e.g. the
                          5 axiom in T or S4.
    -c, --check           Check validity (default)
    -t, --sat             Check satisfiability
    -h, --help            Show this help

OPERATORS:
    □   NECESSARY (box) - true in all accessible worlds
    ◇   POSSIBLE (diamond) - true in some accessible world
    ¬   NOT
    ∧   AND
    ∨   OR
    →   IMPLIES

MODAL SYSTEMS:
    K   Minimal modal logic (no frame conditions)
    D   Serial frames (□P → ◇P valid)
    T   Reflexive frames (□P → P valid)
    S4  Reflexive + transitive (□P → □□P valid)
    S5  Equivalence frames (◇P → □◇P valid)

EXAMPLES:
    $(basename "$0") "□P → P"              # T-axiom (valid in T, S4, S5)
    $(basename "$0") -s S5 "◇P → □◇P"      # 5-axiom (valid in S5)
    $(basename "$0") "□(P → Q) → (□P → □Q)"  # K-axiom (valid in all)
    $(basename "$0") -s D "□P → ◇P"        # D-axiom (needs serial frames; invalid in K)
EOF
}

main() {
    local mode="validity"
    local system="K"
    local n_worlds=2
    local expression=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--system)
                system="$2"
                shift 2
                ;;
            -w|--worlds)
                n_worlds="$2"
                shift 2
                ;;
            -c|--check)
                mode="validity"
                shift
                ;;
            -t|--sat)
                mode="sat"
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
        if [[ ! -t 0 ]]; then
            expression=$(cat)
        else
            usage
            exit 1
        fi
    fi

    # Name the axiom if it is one, then decide by model checking
    annotate_theorem "$expression"

    case "$mode" in
        validity)
            check_modal_validity "$expression" "$system" "$n_worlds"
            ;;
        sat)
            check_modal_satisfiability "$expression" "$system" "$n_worlds"
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
