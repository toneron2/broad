#!/bin/bash
# tests/run-tests.sh - Test Harness
# Patent: Unicode Semantic Dictionary and Multi-Logic Processing Architecture
#
# Runs the exhaustive test suite and reports results.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE_DIR="${SCRIPT_DIR}/../engines"
ROOT_DIR="${SCRIPT_DIR}/.."
TEST_DIR="${SCRIPT_DIR}/generated"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0
SKIP=0

# ============================================================================
# TEST RUNNER FUNCTIONS
# ============================================================================

run_test() {
    local engine="$1"
    local expr="$2"
    local expected="$3"
    local extra_args="${4:-}"

    # Skip CHECK tests (these are for manual verification)
    if [[ "$expected" == "CHECK" ]]; then
        ((SKIP++))
        return 0
    fi

    local result
    case "$engine" in
        boolean)
            result=$("${ROOT_DIR}/logic" "$expr" 2>&1) || true
            ;;
        modal)
            local system="${extra_args:-K}"
            result=$("${ENGINE_DIR}/modal.sh" -s "$system" "$expr" 2>&1) || true
            ;;
        deontic)
            result=$("${ENGINE_DIR}/deontic.sh" "$expr" 2>&1) || true
            ;;
        meta)
            result=$("${ENGINE_DIR}/meta.sh" "$expr" 2>&1) || true
            ;;
        nlp)
            result=$("${ROOT_DIR}/nlp" "$expr" 2>&1) || true
            ;;
        esn)
            result=$("${ENGINE_DIR}/meta.sh" -a "$expr" 2>&1) || true
            ;;
    esac

    # Check if result matches expected pattern
    if [[ "$result" =~ $expected ]]; then
        echo -e "${GREEN}PASS${NC}: $expr -> $expected"
        ((PASS++))
        return 0
    else
        echo -e "${RED}FAIL${NC}: $expr"
        echo "  Expected: $expected"
        echo "  Got: $(echo "$result" | head -1)"
        ((FAIL++))
        return 1
    fi
}

# ============================================================================
# TEST SUITE RUNNERS
# ============================================================================

run_boolean_tests() {
    local test_file="${TEST_DIR}/boolean-tests.txt"
    if [[ ! -f "$test_file" ]]; then
        echo "Boolean tests not found. Run generate-tests.sh first."
        return 1
    fi

    echo ""
    echo "=== Running Boolean Logic Tests ==="
    echo ""

    while IFS='|' read -r expr expected; do
        [[ -z "$expr" ]] && continue
        [[ "$expr" =~ ^# ]] && { echo "$expr"; continue; }

        run_test "boolean" "$expr" "$expected" || true
    done < "$test_file"
}

run_modal_tests() {
    local test_file="${TEST_DIR}/modal-tests.txt"
    if [[ ! -f "$test_file" ]]; then
        echo "Modal tests not found. Run generate-tests.sh first."
        return 1
    fi

    echo ""
    echo "=== Running Modal Logic Tests ==="
    echo ""

    while IFS='|' read -r expr system expected; do
        [[ -z "$expr" ]] && continue
        [[ "$expr" =~ ^# ]] && { echo "$expr"; continue; }

        run_test "modal" "$expr" "$expected" "$system" || true
    done < "$test_file"
}

run_deontic_tests() {
    local test_file="${TEST_DIR}/deontic-tests.txt"
    if [[ ! -f "$test_file" ]]; then
        echo "Deontic tests not found. Run generate-tests.sh first."
        return 1
    fi

    echo ""
    echo "=== Running Deontic Logic Tests ==="
    echo ""

    while IFS='|' read -r expr expected; do
        [[ -z "$expr" ]] && continue
        [[ "$expr" =~ ^# ]] && { echo "$expr"; continue; }

        # For consistency tests, use -t flag
        if [[ "$expected" == "INCONSISTENT" ]]; then
            local result=$("${ENGINE_DIR}/deontic.sh" -t "$expr" 2>&1) || true
            if [[ "$result" =~ INCONSISTENT ]]; then
                echo -e "${GREEN}PASS${NC}: $expr -> $expected"
                ((PASS++))
            else
                echo -e "${RED}FAIL${NC}: $expr -> expected INCONSISTENT, got: $(echo "$result" | head -1)"
                ((FAIL++))
            fi
        else
            run_test "deontic" "$expr" "$expected" || true
        fi
    done < "$test_file"
}

run_meta_tests() {
    local test_file="${TEST_DIR}/meta-tests.txt"
    if [[ ! -f "$test_file" ]]; then
        echo "Meta tests not found. Run generate-tests.sh first."
        return 1
    fi

    echo ""
    echo "=== Running Meta-Engine Tests ==="
    echo ""

    while IFS='|' read -r expr paradigms expected; do
        [[ -z "$expr" ]] && continue
        [[ "$expr" =~ ^# ]] && { echo "$expr"; continue; }

        run_test "meta" "$expr" "$expected" || true
    done < "$test_file"
}

run_nlp_tests() {
    local test_file="${TEST_DIR}/nlp-tests.txt"
    if [[ ! -f "$test_file" ]]; then
        echo "NLP tests not found. Run generate-tests.sh first."
        return 1
    fi

    echo ""
    echo "=== Running NLP Translation Tests ==="
    echo ""

    while IFS='|' read -r nl_expr expected_formal; do
        [[ -z "$nl_expr" ]] && continue
        [[ "$nl_expr" =~ ^# ]] && { echo "$nl_expr"; continue; }

        local result=$("${ROOT_DIR}/nlp" "$nl_expr" 2>&1) || true
        # Normalize whitespace for comparison
        result=$(echo "$result" | tr -s ' ' | sed 's/^ *//;s/ *$//')
        expected_formal=$(echo "$expected_formal" | tr -s ' ' | sed 's/^ *//;s/ *$//')

        if [[ "$result" == "$expected_formal" ]]; then
            echo -e "${GREEN}PASS${NC}: '$nl_expr' -> '$expected_formal'"
            ((PASS++))
        else
            echo -e "${RED}FAIL${NC}: '$nl_expr'"
            echo "  Expected: '$expected_formal'"
            echo "  Got: '$result'"
            ((FAIL++))
        fi
    done < "$test_file"
}

# ============================================================================
# QUICK SMOKE TESTS
# ============================================================================

run_smoke_tests() {
    echo ""
    echo "=== Running Smoke Tests ==="
    echo ""

    # Boolean basics
    echo "--- Boolean ---"
    run_test "boolean" "P ∨ ¬P" "TAUTOLOGY" || true
    run_test "boolean" "P ∧ ¬P" "CONTRADICTION" || true
    run_test "boolean" "P, P → Q ⊢ Q" "VALID" || true

    # Modal basics
    echo "--- Modal ---"
    run_test "modal" "□P → P" "VALID" "T" || true
    run_test "modal" "□P → ◇P" "VALID" "K" || true

    # Deontic basics
    echo "--- Deontic ---"
    run_test "deontic" "O(P) → P(P)" "VALID" || true

    # NLP basics
    echo "--- NLP ---"
    local nlp_result=$("${ROOT_DIR}/nlp" "if P then Q" 2>&1)
    if [[ "$nlp_result" == "P → Q" ]]; then
        echo -e "${GREEN}PASS${NC}: NLP 'if P then Q' -> 'P → Q'"
        ((PASS++))
    else
        echo -e "${RED}FAIL${NC}: NLP 'if P then Q' -> expected 'P → Q', got '$nlp_result'"
        ((FAIL++))
    fi
}

# ============================================================================
# MAIN
# ============================================================================

usage() {
    cat <<EOF
Test Harness - Logic Engine Test Suite

Usage: $(basename "$0") [OPTIONS] [TEST_SUITE]

TEST_SUITES:
    all         Run all tests (default)
    smoke       Quick smoke tests
    boolean     Boolean logic tests
    modal       Modal logic tests
    deontic     Deontic logic tests
    meta        Meta-engine tests
    nlp         NLP translation tests

OPTIONS:
    -g, --generate    Generate tests before running
    -v, --verbose     Verbose output
    -h, --help        Show this help

EXAMPLES:
    $(basename "$0")                 # Run all tests
    $(basename "$0") smoke           # Quick smoke tests
    $(basename "$0") -g boolean      # Generate and run boolean tests
EOF
}

main() {
    local suite="all"
    local generate=false
    local verbose=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -g|--generate)
                generate=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                suite="$1"
                shift
                ;;
        esac
    done

    # Generate tests if requested
    if $generate; then
        echo "Generating tests..."
        "${SCRIPT_DIR}/generate-tests.sh"
    fi

    echo "=============================================="
    echo "  LOGIC ENGINE TEST SUITE"
    echo "  $(date)"
    echo "=============================================="

    case "$suite" in
        all)
            run_smoke_tests
            if [[ -d "$TEST_DIR" ]]; then
                run_boolean_tests
                run_modal_tests
                run_deontic_tests
                run_meta_tests
                run_nlp_tests
            fi
            ;;
        smoke)
            run_smoke_tests
            ;;
        boolean)
            run_boolean_tests
            ;;
        modal)
            run_modal_tests
            ;;
        deontic)
            run_deontic_tests
            ;;
        meta)
            run_meta_tests
            ;;
        nlp)
            run_nlp_tests
            ;;
        *)
            echo "Unknown test suite: $suite"
            usage
            exit 1
            ;;
    esac

    # Summary
    echo ""
    echo "=============================================="
    echo "  TEST SUMMARY"
    echo "=============================================="
    echo -e "  ${GREEN}PASSED${NC}: $PASS"
    echo -e "  ${RED}FAILED${NC}: $FAIL"
    echo -e "  ${YELLOW}SKIPPED${NC}: $SKIP"
    echo "  TOTAL: $((PASS + FAIL + SKIP))"
    echo ""

    if [[ $FAIL -gt 0 ]]; then
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    else
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    fi
}

main "$@"
