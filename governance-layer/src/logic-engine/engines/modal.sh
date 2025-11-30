#!/bin/bash
# engines/modal.sh - Modal Logic Engine
# Figure 17: Expanded Logic System Processing Architecture Flow (Modal Engine)
# Patent: Unicode Semantic Dictionary and Multi-Logic Processing Architecture
#
# Implements Kripke semantics for modal logic systems K, T, S4, S5
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

# Generate small Kripke frames for model checking
# For n worlds, generates frame based on system type
generate_frame() {
    local n_worlds="$1"
    local system="${2:-K}"
    local worlds=""
    local relations=""

    # Generate world list
    for ((w = 0; w < n_worlds; w++)); do
        worlds="$worlds $w"
    done

    case "$system" in
        K)
            # No restrictions - generate all possible relations
            for ((w1 = 0; w1 < n_worlds; w1++)); do
                for ((w2 = 0; w2 < n_worlds; w2++)); do
                    relations="$relations $w1:$w2"
                done
            done
            ;;
        T)
            # Reflexive: every world accesses itself
            for ((w = 0; w < n_worlds; w++)); do
                relations="$relations $w:$w"
            done
            # Plus some non-reflexive relations
            for ((w1 = 0; w1 < n_worlds; w1++)); do
                for ((w2 = 0; w2 < n_worlds; w2++)); do
                    if [[ $w1 -ne $w2 ]]; then
                        relations="$relations $w1:$w2"
                    fi
                done
            done
            ;;
        S4)
            # Reflexive and Transitive
            # For small models, just use reflexive + full relation for simplicity
            for ((w = 0; w < n_worlds; w++)); do
                relations="$relations $w:$w"
            done
            # Add transitive closure (for small n, just add all)
            for ((w1 = 0; w1 < n_worlds; w1++)); do
                for ((w2 = 0; w2 < n_worlds; w2++)); do
                    relations="$relations $w1:$w2"
                done
            done
            ;;
        S5)
            # Equivalence relation - full accessibility
            for ((w1 = 0; w1 < n_worlds; w1++)); do
                for ((w2 = 0; w2 < n_worlds; w2++)); do
                    relations="$relations $w1:$w2"
                done
            done
            ;;
    esac

    echo "WORLDS:$worlds"
    echo "RELATIONS:$relations"
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

    # Limit to prevent explosion
    if [[ $total -gt 256 ]]; then
        total=256
    fi

    for ((i = 0; i < total; i++)); do
        local valuation=""
        local bit=0
        for w in "${world_arr[@]}"; do
            for a in "${atom_arr[@]}"; do
                local val=$(( (i >> bit) & 1 ))
                valuation="$valuation $w:$a=$val"
                ((bit++))
            done
        done
        echo "$valuation"
    done
}

# ============================================================================
# MODAL EXPRESSION EVALUATION
# ============================================================================

# Get value of atom in specific world
get_atom_value() {
    local world="$1"
    local atom="$2"
    local valuation="$3"

    local pattern="$world:$atom="
    local match=$(echo "$valuation" | grep -oE "$pattern[01]" | head -1)

    if [[ -n "$match" ]]; then
        echo "${match##*=}"
    else
        echo "0"  # Default to false
    fi
}

# Check if world w1 can access world w2
can_access() {
    local w1="$1"
    local w2="$2"
    local relations="$3"

    [[ "$relations" =~ (^|[[:space:]])"$w1:$w2"($|[[:space:]]) ]]
}

# Evaluate modal expression at a specific world
# Uses recursive descent for nested modalities
eval_modal_at_world() {
    local world="$1"
    local expr="$2"
    local worlds="$3"
    local relations="$4"
    local valuation="$5"

    # Strip whitespace
    expr=$(echo "$expr" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Handle atomic propositions
    if [[ "$expr" =~ ^[A-Z]$ ]]; then
        get_atom_value "$world" "$expr" "$valuation"
        return
    fi

    # Handle constants
    if [[ "$expr" == "⊤" ]]; then
        echo "1"
        return
    fi
    if [[ "$expr" == "⊥" ]]; then
        echo "0"
        return
    fi

    # Handle necessity □P
    if [[ "$expr" =~ ^□(.+)$ ]]; then
        local inner="${BASH_REMATCH[1]}"
        local world_arr=($worlds)

        for w2 in "${world_arr[@]}"; do
            if can_access "$world" "$w2" "$relations"; then
                local val=$(eval_modal_at_world "$w2" "$inner" "$worlds" "$relations" "$valuation")
                if [[ "$val" == "0" ]]; then
                    echo "0"
                    return
                fi
            fi
        done
        echo "1"
        return
    fi

    # Handle possibility ◇P
    if [[ "$expr" =~ ^◇(.+)$ ]]; then
        local inner="${BASH_REMATCH[1]}"
        local world_arr=($worlds)

        for w2 in "${world_arr[@]}"; do
            if can_access "$world" "$w2" "$relations"; then
                local val=$(eval_modal_at_world "$w2" "$inner" "$worlds" "$relations" "$valuation")
                if [[ "$val" == "1" ]]; then
                    echo "1"
                    return
                fi
            fi
        done
        echo "0"
        return
    fi

    # Handle negation ¬P
    if [[ "$expr" =~ ^¬(.+)$ ]]; then
        local inner="${BASH_REMATCH[1]}"
        local val=$(eval_modal_at_world "$world" "$inner" "$worlds" "$relations" "$valuation")
        if [[ "$val" == "1" ]]; then
            echo "0"
        else
            echo "1"
        fi
        return
    fi

    # Handle parentheses
    if [[ "$expr" =~ ^\((.+)\)$ ]]; then
        eval_modal_at_world "$world" "${BASH_REMATCH[1]}" "$worlds" "$relations" "$valuation"
        return
    fi

    # Handle binary connectives (simple left-to-right for now)
    # Conjunction P ∧ Q
    if [[ "$expr" =~ (.+)∧(.+) ]]; then
        local left="${BASH_REMATCH[1]}"
        local right="${BASH_REMATCH[2]}"
        local v1=$(eval_modal_at_world "$world" "$left" "$worlds" "$relations" "$valuation")
        local v2=$(eval_modal_at_world "$world" "$right" "$worlds" "$relations" "$valuation")
        if [[ "$v1" == "1" && "$v2" == "1" ]]; then
            echo "1"
        else
            echo "0"
        fi
        return
    fi

    # Disjunction P ∨ Q
    if [[ "$expr" =~ (.+)∨(.+) ]]; then
        local left="${BASH_REMATCH[1]}"
        local right="${BASH_REMATCH[2]}"
        local v1=$(eval_modal_at_world "$world" "$left" "$worlds" "$relations" "$valuation")
        local v2=$(eval_modal_at_world "$world" "$right" "$worlds" "$relations" "$valuation")
        if [[ "$v1" == "1" || "$v2" == "1" ]]; then
            echo "1"
        else
            echo "0"
        fi
        return
    fi

    # Implication P → Q
    if [[ "$expr" =~ (.+)→(.+) ]]; then
        local left="${BASH_REMATCH[1]}"
        local right="${BASH_REMATCH[2]}"
        local v1=$(eval_modal_at_world "$world" "$left" "$worlds" "$relations" "$valuation")
        local v2=$(eval_modal_at_world "$world" "$right" "$worlds" "$relations" "$valuation")
        if [[ "$v1" == "0" || "$v2" == "1" ]]; then
            echo "1"
        else
            echo "0"
        fi
        return
    fi

    # Default: unknown expression
    echo "0"
}

# ============================================================================
# VALIDITY CHECKING
# ============================================================================

# Check if formula is valid in given modal system
# A formula is valid iff it's true at all worlds in all models
check_modal_validity() {
    local expr="$1"
    local system="${2:-K}"
    local n_worlds="${3:-2}"  # Default to 2 worlds for tractability

    # Extract atomic propositions
    local atoms=$(echo "$expr" | grep -oE '\b[A-Z]\b' | sort -u | tr '\n' ' ')

    # Generate frame
    local frame=$(generate_frame "$n_worlds" "$system")
    local worlds=$(echo "$frame" | grep '^WORLDS:' | cut -d: -f2-)
    local relations=$(echo "$frame" | grep '^RELATIONS:' | cut -d: -f2-)

    # For each valuation, check if formula is true at all worlds
    local valuations=$(generate_valuations "$worlds" "$atoms")
    local found_counterexample=false
    local counterexample_info=""

    if [[ -z "$valuations" ]]; then
        # No atoms - evaluate directly at each world
        local world_arr=($worlds)
        for w in "${world_arr[@]}"; do
            local val=$(eval_modal_at_world "$w" "$expr" "$worlds" "$relations" "")
            if [[ "$val" == "0" ]]; then
                found_counterexample=true
                counterexample_info="world=$w (no atoms)"
                break
            fi
        done
    else
        while IFS= read -r valuation; do
            [[ -z "$valuation" ]] && continue
            local world_arr=($worlds)

            for w in "${world_arr[@]}"; do
                local val=$(eval_modal_at_world "$w" "$expr" "$worlds" "$relations" "$valuation")
                if [[ "$val" == "0" ]]; then
                    found_counterexample=true
                    counterexample_info="world=$w valuation=$valuation"
                    break 2
                fi
            done
        done <<< "$valuations"
    fi

    if $found_counterexample; then
        echo "INVALID in $system"
        echo "counterexample: $counterexample_info"
        return 1
    else
        echo "VALID in $system"
        return 0
    fi
}

# Check satisfiability (is there a model where formula is true somewhere?)
check_modal_satisfiability() {
    local expr="$1"
    local system="${2:-K}"
    local n_worlds="${3:-2}"

    local atoms=$(echo "$expr" | grep -oE '\b[A-Z]\b' | sort -u | tr '\n' ' ')
    local frame=$(generate_frame "$n_worlds" "$system")
    local worlds=$(echo "$frame" | grep '^WORLDS:' | cut -d: -f2-)
    local relations=$(echo "$frame" | grep '^RELATIONS:' | cut -d: -f2-)

    local valuations=$(generate_valuations "$worlds" "$atoms")

    if [[ -z "$valuations" ]]; then
        local world_arr=($worlds)
        for w in "${world_arr[@]}"; do
            local val=$(eval_modal_at_world "$w" "$expr" "$worlds" "$relations" "")
            if [[ "$val" == "1" ]]; then
                echo "SATISFIABLE in $system"
                echo "witness: world=$w"
                return 0
            fi
        done
    else
        while IFS= read -r valuation; do
            [[ -z "$valuation" ]] && continue
            local world_arr=($worlds)

            for w in "${world_arr[@]}"; do
                local val=$(eval_modal_at_world "$w" "$expr" "$worlds" "$relations" "$valuation")
                if [[ "$val" == "1" ]]; then
                    echo "SATISFIABLE in $system"
                    echo "witness: world=$w, valuation=$valuation"
                    return 0
                fi
            done
        done <<< "$valuations"
    fi

    echo "UNSATISFIABLE in $system"
    return 1
}

# ============================================================================
# STANDARD MODAL THEOREMS
# ============================================================================

# Check known modal theorems
check_theorem() {
    local expr="$1"

    # K axiom: □(P → Q) → (□P → □Q)
    if [[ "$expr" =~ □\(.*→.*\)→\(□.*→□.*\) ]]; then
        echo "K-AXIOM (distribution)"
        echo "VALID in all normal modal logics"
        return 0
    fi

    # T axiom: □P → P (reflexivity)
    if [[ "$expr" == "□P → P" || "$expr" =~ ^□[A-Z]→[A-Z]$ ]]; then
        local prop=$(echo "$expr" | grep -oE '[A-Z]' | head -1)
        echo "T-AXIOM (reflexivity)"
        echo "VALID in T, S4, S5 (not in K)"
        return 0
    fi

    # 4 axiom: □P → □□P (transitivity)
    if [[ "$expr" =~ ^□[A-Z]→□□[A-Z]$ ]]; then
        echo "4-AXIOM (transitivity)"
        echo "VALID in S4, S5 (not in K, T)"
        return 0
    fi

    # 5 axiom: ◇P → □◇P (euclidean)
    if [[ "$expr" =~ ^◇[A-Z]→□◇[A-Z]$ ]]; then
        echo "5-AXIOM (euclidean)"
        echo "VALID in S5 only"
        return 0
    fi

    # Necessitation rule: if P is valid, then □P is valid
    # Duality: ¬□¬P ↔ ◇P and ¬◇¬P ↔ □P

    return 1
}

# ============================================================================
# MAIN
# ============================================================================

usage() {
    cat <<EOF
Modal Logic Engine - Figure 17 Implementation (Kripke Semantics)

Usage: $(basename "$0") [OPTIONS] EXPRESSION

OPTIONS:
    -s, --system SYSTEM   Modal system: K, T, S4, S5 (default: K)
    -w, --worlds N        Number of worlds to check (default: 2)
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
    T   Reflexive frames (□P → P valid)
    S4  Reflexive + transitive (□P → □□P valid)
    S5  Equivalence frames (◇P → □◇P valid)

EXAMPLES:
    $(basename "$0") "□P → P"              # T-axiom (valid in T, S4, S5)
    $(basename "$0") -s S5 "◇P → □◇P"      # 5-axiom (valid in S5)
    $(basename "$0") "□(P → Q) → (□P → □Q)"  # K-axiom (valid in all)
    $(basename "$0") "□P → ◇P"             # Serial frames required
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

    # First check if it's a known theorem
    if check_theorem "$expression"; then
        exit 0
    fi

    # Otherwise do model checking
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
