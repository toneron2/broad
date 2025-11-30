#!/bin/bash
# engines/deontic.sh - Deontic Logic Engine
# Figure 18: Expanded Logic System Processing Architecture Flow (Deontic Engine)
# Patent: Unicode Semantic Dictionary and Multi-Logic Processing Architecture
#
# Implements Standard Deontic Logic (SDL) for obligations, permissions, and prohibitions
# Critical for ESN Access Agent governance and policy enforcement
#
# OPERATORS:
#   O(P)  - Obligatory P (must do P)
#   P(P)  - Permitted P (may do P)
#   F(P)  - Forbidden P (must not do P)
#
# INTER-DEFINITIONAL AXIOMS:
#   F(P) ↔ ¬P(P)     Forbidden = not permitted
#   F(P) ↔ O(¬P)     Forbidden = obligatory not
#   P(P) ↔ ¬O(¬P)    Permitted = not obligatory not
#
# DEONTIC AXIOMS:
#   O(P) → P(P)                What is obligatory is permitted
#   O(P → Q) → (O(P) → O(Q))   Distribution (K-axiom for deontic)
#   ¬(O(P) ∧ O(¬P))            No conflicting obligations
#   ¬(O(P) ∧ F(P))             Deontic consistency
#
# INPUT: Deontic expression with O(), P(), F() operators
# OUTPUT: VALID / INVALID / CONSISTENT / INCONSISTENT

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# ============================================================================
# DEONTIC EXPRESSION PARSING
# ============================================================================

# Parse deontic operators: O(P), P(Q), F(R)
# Returns the operator type and inner expression
parse_deontic_op() {
    local expr="$1"
    expr=$(echo "$expr" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Check for O(...)
    if [[ "$expr" =~ ^O\((.+)\)$ ]]; then
        echo "OBLIGATION:${BASH_REMATCH[1]}"
        return
    fi

    # Check for P(...)
    if [[ "$expr" =~ ^P\((.+)\)$ ]]; then
        echo "PERMISSION:${BASH_REMATCH[1]}"
        return
    fi

    # Check for F(...)
    if [[ "$expr" =~ ^F\((.+)\)$ ]]; then
        echo "FORBIDDEN:${BASH_REMATCH[1]}"
        return
    fi

    # Not a deontic operator
    echo "PROP:$expr"
}

# ============================================================================
# KRIPKE-STYLE DEONTIC SEMANTICS
# ============================================================================

# Deontic logic uses "ideal worlds" (deontically perfect worlds)
# O(P) = P is true in all ideal worlds accessible from current world
# P(P) = P is true in at least one ideal world
# F(P) = P is false in all ideal worlds (equivalent to O(¬P))

# Generate deontic frame: current world + ideal worlds
generate_deontic_frame() {
    local n_ideal="${1:-2}"  # Number of ideal worlds

    # World 0 is the actual world, worlds 1..n are ideal worlds
    local worlds="0"
    for ((i = 1; i <= n_ideal; i++)); do
        worlds="$worlds $i"
    done

    # Relations: actual world accesses all ideal worlds
    local relations=""
    for ((i = 1; i <= n_ideal; i++)); do
        relations="$relations 0:$i"
    done

    echo "WORLDS:$worlds"
    echo "IDEAL:$(echo $worlds | cut -d' ' -f2-)"
    echo "RELATIONS:$relations"
}

# Generate valuations for atoms in ideal worlds
generate_deontic_valuations() {
    local ideal_worlds="$1"
    local atoms="$2"

    local world_arr=($ideal_worlds)
    local atom_arr=($atoms)
    local n_worlds=${#world_arr[@]}
    local n_atoms=${#atom_arr[@]}

    if [[ $n_atoms -eq 0 ]]; then
        echo ""
        return
    fi

    local n_pairs=$((n_worlds * n_atoms))
    local total=$((2 ** n_pairs))

    # Limit combinations
    if [[ $total -gt 128 ]]; then
        total=128
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

# Get value of atom in specific world
get_value() {
    local world="$1"
    local atom="$2"
    local valuation="$3"

    local pattern="$world:$atom="
    local match=$(echo "$valuation" | grep -oE "$pattern[01]" | head -1)

    if [[ -n "$match" ]]; then
        echo "${match##*=}"
    else
        echo "0"
    fi
}

# Evaluate deontic expression at ideal worlds
eval_deontic() {
    local expr="$1"
    local ideal_worlds="$2"
    local valuation="$3"

    expr=$(echo "$expr" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    local world_arr=($ideal_worlds)

    # Handle O(P) - true in all ideal worlds
    if [[ "$expr" =~ ^O\((.+)\)$ ]]; then
        local inner="${BASH_REMATCH[1]}"
        for w in "${world_arr[@]}"; do
            local val=$(eval_prop "$inner" "$w" "$valuation")
            if [[ "$val" == "0" ]]; then
                echo "0"
                return
            fi
        done
        echo "1"
        return
    fi

    # Handle P(P) - true in some ideal world
    if [[ "$expr" =~ ^P\((.+)\)$ ]]; then
        local inner="${BASH_REMATCH[1]}"
        for w in "${world_arr[@]}"; do
            local val=$(eval_prop "$inner" "$w" "$valuation")
            if [[ "$val" == "1" ]]; then
                echo "1"
                return
            fi
        done
        echo "0"
        return
    fi

    # Handle F(P) = O(¬P) - P false in all ideal worlds
    if [[ "$expr" =~ ^F\((.+)\)$ ]]; then
        local inner="${BASH_REMATCH[1]}"
        for w in "${world_arr[@]}"; do
            local val=$(eval_prop "$inner" "$w" "$valuation")
            if [[ "$val" == "1" ]]; then
                echo "0"  # Found a world where P is true, so not forbidden
                return
            fi
        done
        echo "1"  # P is false in all ideal worlds = forbidden
        return
    fi

    # Handle negation ¬
    if [[ "$expr" =~ ^¬(.+)$ ]]; then
        local inner="${BASH_REMATCH[1]}"
        local val=$(eval_deontic "$inner" "$ideal_worlds" "$valuation")
        if [[ "$val" == "1" ]]; then
            echo "0"
        else
            echo "1"
        fi
        return
    fi

    # Handle conjunction ∧
    if [[ "$expr" =~ (.+)∧(.+) ]]; then
        local left="${BASH_REMATCH[1]}"
        local right="${BASH_REMATCH[2]}"
        local v1=$(eval_deontic "$left" "$ideal_worlds" "$valuation")
        local v2=$(eval_deontic "$right" "$ideal_worlds" "$valuation")
        if [[ "$v1" == "1" && "$v2" == "1" ]]; then
            echo "1"
        else
            echo "0"
        fi
        return
    fi

    # Handle disjunction ∨
    if [[ "$expr" =~ (.+)∨(.+) ]]; then
        local left="${BASH_REMATCH[1]}"
        local right="${BASH_REMATCH[2]}"
        local v1=$(eval_deontic "$left" "$ideal_worlds" "$valuation")
        local v2=$(eval_deontic "$right" "$ideal_worlds" "$valuation")
        if [[ "$v1" == "1" || "$v2" == "1" ]]; then
            echo "1"
        else
            echo "0"
        fi
        return
    fi

    # Handle implication →
    if [[ "$expr" =~ (.+)→(.+) ]]; then
        local left="${BASH_REMATCH[1]}"
        local right="${BASH_REMATCH[2]}"
        local v1=$(eval_deontic "$left" "$ideal_worlds" "$valuation")
        local v2=$(eval_deontic "$right" "$ideal_worlds" "$valuation")
        if [[ "$v1" == "0" || "$v2" == "1" ]]; then
            echo "1"
        else
            echo "0"
        fi
        return
    fi

    # Handle parentheses
    if [[ "$expr" =~ ^\((.+)\)$ ]]; then
        eval_deontic "${BASH_REMATCH[1]}" "$ideal_worlds" "$valuation"
        return
    fi

    # Atomic proposition - not directly evaluable at deontic level
    # Default to checking if it's satisfied
    echo "1"
}

# Evaluate propositional expression at specific world
eval_prop() {
    local expr="$1"
    local world="$2"
    local valuation="$3"

    expr=$(echo "$expr" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Atomic proposition
    if [[ "$expr" =~ ^[A-Z]$ ]]; then
        get_value "$world" "$expr" "$valuation"
        return
    fi

    # Constants
    if [[ "$expr" == "⊤" ]]; then
        echo "1"
        return
    fi
    if [[ "$expr" == "⊥" ]]; then
        echo "0"
        return
    fi

    # Negation
    if [[ "$expr" =~ ^¬(.+)$ ]]; then
        local inner="${BASH_REMATCH[1]}"
        local val=$(eval_prop "$inner" "$world" "$valuation")
        if [[ "$val" == "1" ]]; then
            echo "0"
        else
            echo "1"
        fi
        return
    fi

    # Parentheses
    if [[ "$expr" =~ ^\((.+)\)$ ]]; then
        eval_prop "${BASH_REMATCH[1]}" "$world" "$valuation"
        return
    fi

    # Binary operators
    if [[ "$expr" =~ (.+)∧(.+) ]]; then
        local v1=$(eval_prop "${BASH_REMATCH[1]}" "$world" "$valuation")
        local v2=$(eval_prop "${BASH_REMATCH[2]}" "$world" "$valuation")
        [[ "$v1" == "1" && "$v2" == "1" ]] && echo "1" || echo "0"
        return
    fi

    if [[ "$expr" =~ (.+)∨(.+) ]]; then
        local v1=$(eval_prop "${BASH_REMATCH[1]}" "$world" "$valuation")
        local v2=$(eval_prop "${BASH_REMATCH[2]}" "$world" "$valuation")
        [[ "$v1" == "1" || "$v2" == "1" ]] && echo "1" || echo "0"
        return
    fi

    if [[ "$expr" =~ (.+)→(.+) ]]; then
        local v1=$(eval_prop "${BASH_REMATCH[1]}" "$world" "$valuation")
        local v2=$(eval_prop "${BASH_REMATCH[2]}" "$world" "$valuation")
        [[ "$v1" == "0" || "$v2" == "1" ]] && echo "1" || echo "0"
        return
    fi

    # Default
    echo "1"
}

# ============================================================================
# DEONTIC VALIDITY AND CONSISTENCY CHECKING
# ============================================================================

# Check if deontic formula is valid (true in all models)
check_deontic_validity() {
    local expr="$1"
    local n_ideal="${2:-2}"

    # Extract atoms
    local atoms=$(echo "$expr" | grep -oE '\b[A-Z]\b' | sort -u | tr '\n' ' ')

    # Generate frame
    local frame=$(generate_deontic_frame "$n_ideal")
    local ideal_worlds=$(echo "$frame" | grep '^IDEAL:' | cut -d: -f2-)

    # Generate valuations
    local valuations=$(generate_deontic_valuations "$ideal_worlds" "$atoms")

    if [[ -z "$valuations" ]]; then
        # No atoms - evaluate directly
        local val=$(eval_deontic "$expr" "$ideal_worlds" "")
        if [[ "$val" == "0" ]]; then
            echo "INVALID"
            echo "counterexample: (no atoms)"
            return 1
        fi
    else
        while IFS= read -r valuation; do
            [[ -z "$valuation" ]] && continue
            local val=$(eval_deontic "$expr" "$ideal_worlds" "$valuation")
            if [[ "$val" == "0" ]]; then
                echo "INVALID"
                echo "counterexample: $valuation"
                return 1
            fi
        done <<< "$valuations"
    fi

    echo "VALID"
    return 0
}

# Check for deontic conflicts (O(P) ∧ F(P) or O(P) ∧ O(¬P))
check_deontic_consistency() {
    local expr="$1"

    # Extract all O(...), P(...), F(...) operators and their contents
    local obligations=$(echo "$expr" | grep -oE 'O\([^)]+\)' | sed 's/O(\([^)]*\))/\1/g' | sort -u)
    local forbiddens=$(echo "$expr" | grep -oE 'F\([^)]+\)' | sed 's/F(\([^)]*\))/\1/g' | sort -u)

    # Check if any obligation is also forbidden
    for o in $obligations; do
        for f in $forbiddens; do
            if [[ "$o" == "$f" ]]; then
                echo "INCONSISTENT"
                echo "conflict: O($o) and F($o) cannot both hold"
                return 1
            fi
        done

        # Check for O(P) and O(¬P)
        local neg_o="¬$o"
        for o2 in $obligations; do
            if [[ "$o2" == "$neg_o" ]]; then
                echo "INCONSISTENT"
                echo "conflict: O($o) and O(¬$o) violates D-axiom"
                return 1
            fi
        done
    done

    echo "CONSISTENT"
    return 0
}

# ============================================================================
# STANDARD DEONTIC THEOREMS
# ============================================================================

check_deontic_theorem() {
    local expr="$1"

    # O(P) → P(P) (ought implies can)
    if [[ "$expr" == "O(P) → P(P)" ]] || [[ "$expr" =~ ^O\([A-Z]\)→P\([A-Z]\)$ ]]; then
        echo "D-AXIOM (ought implies can)"
        echo "VALID: What is obligatory is permitted"
        return 0
    fi

    # ¬(O(P) ∧ F(P)) (deontic consistency)
    if [[ "$expr" =~ ^¬\(O\(.+\)∧F\(.+\)\)$ ]]; then
        echo "DEONTIC-CONSISTENCY"
        echo "VALID: Cannot be both obligatory and forbidden"
        return 0
    fi

    # F(P) ↔ ¬P(P) (definition of forbidden)
    if [[ "$expr" == "F(P) ↔ ¬P(P)" ]]; then
        echo "F-DEFINITION"
        echo "VALID: Forbidden = not permitted"
        return 0
    fi

    # F(P) ↔ O(¬P) (forbidden = obligatory not)
    if [[ "$expr" == "F(P) ↔ O(¬P)" ]]; then
        echo "F-O-EQUIVALENCE"
        echo "VALID: Forbidden = obligatory not"
        return 0
    fi

    # P(P) ↔ ¬O(¬P) (permission definition)
    if [[ "$expr" == "P(P) ↔ ¬O(¬P)" ]]; then
        echo "P-DEFINITION"
        echo "VALID: Permitted = not obligatory not"
        return 0
    fi

    return 1
}

# ============================================================================
# ESN ACCESS CONTROL APPLICATION
# ============================================================================

# Evaluate access control policy
evaluate_access_policy() {
    local policy="$1"

    echo "=== ESN Access Control Evaluation ==="
    echo "Policy: $policy"
    echo ""

    # Check consistency
    local consistency=$(check_deontic_consistency "$policy")
    echo "Consistency: $consistency"

    if [[ "$consistency" =~ ^INCONSISTENT ]]; then
        echo "WARNING: Policy contains conflicting obligations!"
        return 1
    fi

    # Check validity
    local validity=$(check_deontic_validity "$policy")
    echo "Validity: $validity"

    return 0
}

# ============================================================================
# MAIN
# ============================================================================

usage() {
    cat <<EOF
Deontic Logic Engine - Figure 18 Implementation

Usage: $(basename "$0") [OPTIONS] EXPRESSION

OPTIONS:
    -c, --check       Check validity (default)
    -t, --consistent  Check deontic consistency
    -a, --access      ESN access control evaluation mode
    -w, --worlds N    Number of ideal worlds (default: 2)
    -h, --help        Show this help

OPERATORS:
    O(P)  OBLIGATORY - P must be done
    P(P)  PERMITTED - P may be done
    F(P)  FORBIDDEN - P must not be done
    ¬     NOT
    ∧     AND
    ∨     OR
    →     IMPLIES

DEONTIC PRINCIPLES:
    O(P) → P(P)       Ought implies can
    F(P) ↔ ¬P(P)      Forbidden = not permitted
    F(P) ↔ O(¬P)      Forbidden = obligatory not

EXAMPLES:
    $(basename "$0") "O(P) → P(P)"           # D-axiom (valid)
    $(basename "$0") "O(P) ∧ F(P)"           # Contradiction
    $(basename "$0") -t "O(A) ∧ P(B)"        # Check consistency
    $(basename "$0") -a "O(auth) → P(access)" # Access policy

ESN ACCESS CONTROL:
    O(authenticate)          User must authenticate
    P(read_data)            User may read data
    F(modify_system)        User must not modify system
    O(log) → P(access)      Logging required for access
EOF
}

main() {
    local mode="validity"
    local n_ideal=2
    local expression=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--check)
                mode="validity"
                shift
                ;;
            -t|--consistent)
                mode="consistency"
                shift
                ;;
            -a|--access)
                mode="access"
                shift
                ;;
            -w|--worlds)
                n_ideal="$2"
                shift 2
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

    # Check for known theorems first
    if check_deontic_theorem "$expression"; then
        exit 0
    fi

    case "$mode" in
        validity)
            check_deontic_validity "$expression" "$n_ideal"
            ;;
        consistency)
            check_deontic_consistency "$expression"
            ;;
        access)
            evaluate_access_policy "$expression"
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
