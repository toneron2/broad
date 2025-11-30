#!/bin/bash
# core/identify.sh - Logic System Identifier
# Figure 26 Phase 1: Enhanced Input Analysis - System Identification
# Patent: Unicode Semantic Dictionary and Multi-Logic Processing Architecture
#
# Identifies primary and secondary logic systems from input or token stream.
# Output: SYSTEM:name lines followed by the original input/tokens

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# ============================================================================
# PARADIGM DETECTION PATTERNS
# ============================================================================

# Detect paradigms from raw expression
detect_from_expression() {
    local expr="$1"
    local paradigms="boolean"  # Always base

    # Modal: □ ◇
    if [[ "$expr" =~ [□◇] ]]; then
        paradigms="$paradigms modal"
    fi

    # Deontic: O( P( F( patterns
    if echo "$expr" | grep -qE '[OPF]\('; then
        paradigms="$paradigms deontic"
    fi

    # Epistemic: K_ B_ patterns
    if echo "$expr" | grep -qE '[KB]_'; then
        paradigms="$paradigms epistemic"
    fi

    # Temporal: ○ or temporal keywords
    if [[ "$expr" =~ ○ ]] || echo "$expr" | grep -qE '\bU\b|\bR\b|\bG\b|\bF\b'; then
        paradigms="$paradigms temporal"
    fi

    # Fuzzy: decimal numbers in [0,1]
    if echo "$expr" | grep -qE '0\.[0-9]+|1\.0'; then
        paradigms="$paradigms fuzzy"
    fi

    # First-order: ∀ ∃
    if [[ "$expr" =~ [∀∃] ]]; then
        paradigms="$paradigms fol"
    fi

    # Paraconsistent: ~ (tilde for weak negation)
    if echo "$expr" | grep -qF '~'; then
        paradigms="$paradigms paraconsistent"
    fi

    # Linear logic: ⊸ (avoiding ! and ? as they're common)
    if [[ "$expr" =~ ⊸ ]]; then
        paradigms="$paradigms linear"
    fi

    # Set theory: ∈ ⊆ ∪ ∩
    if [[ "$expr" =~ [∈⊆∪∩] ]]; then
        paradigms="$paradigms set"
    fi

    # Type theory: : ⊢ Π Σ
    if [[ "$expr" =~ [⊢ΠΣ] ]] || echo "$expr" | grep -qE '[a-z]+\s*:'; then
        paradigms="$paradigms type"
    fi

    echo "$paradigms"
}

# Detect paradigms from token stream
detect_from_tokens() {
    local tokens="$1"
    local paradigms="boolean"

    # Check token types
    if echo "$tokens" | grep -qE '^(NECESSARY|POSSIBLE):'; then
        paradigms="$paradigms modal"
    fi

    if echo "$tokens" | grep -qE '^(OBLIGATION|PERMISSION|FORBIDDEN):'; then
        paradigms="$paradigms deontic"
    fi

    if echo "$tokens" | grep -qE '^(KNOWLEDGE|BELIEF):'; then
        paradigms="$paradigms epistemic"
    fi

    if echo "$tokens" | grep -qE '^(NEXT|GLOBALLY|UNTIL|RELEASE):'; then
        paradigms="$paradigms temporal"
    fi

    if echo "$tokens" | grep -qE '^FLOAT:'; then
        paradigms="$paradigms fuzzy"
    fi

    if echo "$tokens" | grep -qE '^(FORALL|EXISTS):'; then
        paradigms="$paradigms fol"
    fi

    echo "$paradigms"
}

# Determine primary paradigm (most specific)
get_primary() {
    local paradigms="$1"

    # Priority order (most specific first)
    for p in epistemic deontic modal temporal fuzzy paraconsistent linear set type fol boolean; do
        if [[ "$paradigms" =~ $p ]]; then
            echo "$p"
            return
        fi
    done

    echo "boolean"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    local input=""
    local is_tokens=false

    # Read input - prefer arguments over stdin
    if [[ $# -gt 0 ]]; then
        # Argument mode
        input="$*"
    elif [[ ! -t 0 ]]; then
        # Pipe mode
        input=$(cat)
    else
        echo "ERROR: No input provided" >&2
        exit 1
    fi

    # Check if input is token stream
    if echo "$input" | head -1 | grep -qE '^[A-Z_]+:'; then
        is_tokens=true
    fi

    # Detect paradigms
    local paradigms
    if $is_tokens; then
        paradigms=$(detect_from_tokens "$input")
    else
        paradigms=$(detect_from_expression "$input")
    fi

    local primary=$(get_primary "$paradigms")

    # Output system identification
    echo "PRIMARY:$primary"
    echo "PARADIGMS:$paradigms"
    echo "---"

    # Pass through the input
    echo "$input"
}

main "$@"
