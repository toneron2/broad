#!/bin/bash
# core/route.sh - Engine Router/Dispatcher
# Figure 26 Phase 2: Multi-System Logic Engine Selection
# Patent: Unicode Semantic Dictionary and Multi-Logic Processing Architecture
#
# Routes input to the appropriate logic engine based on detected paradigm.
# Implements the SWITCH logic_system from Figure 26.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE_DIR="${SCRIPT_DIR}/../engines"

# ============================================================================
# ENGINE DISPATCH (Figure 26 Phase 2)
# ============================================================================

# Route to appropriate engine
route_to_engine() {
    local primary="$1"
    local paradigms="$2"
    local expression="$3"

    # Figure 26 SWITCH logic_system:
    case "$primary" in
        boolean)
            "${ENGINE_DIR}/boolean.sh" "$expression"
            ;;
        modal)
            if [[ -x "${ENGINE_DIR}/modal.sh" ]]; then
                "${ENGINE_DIR}/modal.sh" "$expression"
            else
                # Fallback to boolean with modal translation
                echo "NOTE: Modal engine not available, using boolean approximation" >&2
                "${ENGINE_DIR}/boolean.sh" "$expression"
            fi
            ;;
        deontic)
            if [[ -x "${ENGINE_DIR}/deontic.sh" ]]; then
                "${ENGINE_DIR}/deontic.sh" "$expression"
            else
                echo "NOTE: Deontic engine not available" >&2
                "${ENGINE_DIR}/boolean.sh" "$expression"
            fi
            ;;
        epistemic)
            if [[ -x "${ENGINE_DIR}/epistemic.sh" ]]; then
                "${ENGINE_DIR}/epistemic.sh" "$expression"
            else
                echo "NOTE: Epistemic engine not available" >&2
                "${ENGINE_DIR}/boolean.sh" "$expression"
            fi
            ;;
        fuzzy)
            if [[ -x "${ENGINE_DIR}/fuzzy.sh" ]]; then
                "${ENGINE_DIR}/fuzzy.sh" "$expression"
            else
                echo "NOTE: Fuzzy engine not available" >&2
                "${ENGINE_DIR}/boolean.sh" "$expression"
            fi
            ;;
        temporal)
            if [[ -x "${ENGINE_DIR}/temporal.sh" ]]; then
                "${ENGINE_DIR}/temporal.sh" "$expression"
            else
                echo "NOTE: Temporal engine not available" >&2
                "${ENGINE_DIR}/boolean.sh" "$expression"
            fi
            ;;
        paraconsistent)
            if [[ -x "${ENGINE_DIR}/paraconsistent.sh" ]]; then
                "${ENGINE_DIR}/paraconsistent.sh" "$expression"
            else
                echo "NOTE: Paraconsistent engine not available" >&2
                "${ENGINE_DIR}/boolean.sh" "$expression"
            fi
            ;;
        meta|composite)
            # Meta-engine for multi-paradigm composition
            if [[ -x "${ENGINE_DIR}/meta.sh" ]]; then
                "${ENGINE_DIR}/meta.sh" "$expression" "$paradigms"
            else
                echo "NOTE: Meta-engine not available" >&2
                "${ENGINE_DIR}/boolean.sh" "$expression"
            fi
            ;;
        *)
            # DEFAULT: UniversalTranslationEngine.process(argument)
            if [[ -x "${ENGINE_DIR}/meta.sh" ]]; then
                "${ENGINE_DIR}/meta.sh" "$expression" "$paradigms"
            else
                "${ENGINE_DIR}/boolean.sh" "$expression"
            fi
            ;;
    esac
}

# Check if multiple paradigms require meta-engine
needs_meta_engine() {
    local paradigms="$1"
    local count=$(echo "$paradigms" | wc -w)
    [[ $count -gt 1 ]]
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    local input=""

    # Read input (may include system identification header)
    if [[ -t 0 ]]; then
        input="$*"
    else
        input=$(cat)
    fi

    # Parse system identification if present
    local primary="boolean"
    local paradigms="boolean"
    local expression="$input"

    if echo "$input" | head -1 | grep -qE '^PRIMARY:'; then
        primary=$(echo "$input" | grep '^PRIMARY:' | cut -d: -f2)
        paradigms=$(echo "$input" | grep '^PARADIGMS:' | cut -d: -f2-)

        # Extract expression (everything after ---)
        expression=$(echo "$input" | sed -n '/^---$/,${/^---$/d;p}')
    fi

    # If no expression extracted, use original input
    if [[ -z "$expression" ]]; then
        expression="$input"
    fi

    # Check if multiple paradigms warrant meta-engine
    if needs_meta_engine "$paradigms"; then
        primary="meta"
    fi

    # Route to appropriate engine
    route_to_engine "$primary" "$paradigms" "$expression"
}

main "$@"
