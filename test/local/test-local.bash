#!/bin/bash
set -euo pipefail

# Local (non-Docker) smoke tests for orbit-actions CLI
# Tests the CLI via yarn cli

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Local Smoke Tests ==="
echo ""

PASSED=0
FAILED=0

check() {
    local name="$1"
    shift
    printf "Testing %s... " "$name"
    if "$@" >/dev/null 2>&1; then
        echo "OK"
        PASSED=$((PASSED + 1))
    else
        echo "FAILED"
        FAILED=$((FAILED + 1))
    fi
}

check_output() {
    local name="$1"
    local expected="$2"
    shift 2
    printf "Testing %s... " "$name"
    # Disable pipefail for this check - it interferes with if/pipe/grep
    if (set +o pipefail; "$@" 2>&1 | grep -q "$expected"); then
        echo "OK"
        PASSED=$((PASSED + 1))
    else
        echo "FAILED (expected: $expected)"
        FAILED=$((FAILED + 1))
    fi
}

cli() {
    yarn --silent --cwd "$REPO_ROOT" cli -- "$@"
}

echo "--- Prerequisites ---"
check "forge installed" command -v forge
check "cast installed" command -v cast
check "yarn installed" command -v yarn

echo ""
echo "--- Directory Browsing ---"
check "list top level" cli
check_output "list contract-upgrades" "1.2.1" cli contract-upgrades
check_output "list contract-upgrades/1.2.1" "deploy" cli contract-upgrades/1.2.1
check_output "list arbos-upgrades" "at-timestamp" cli arbos-upgrades

echo ""
echo "--- File Viewing ---"
check_output "view README" "Nitro contracts" cli contract-upgrades/1.2.1/README.md

echo ""
echo "--- Help ---"
check_output "help command" "Usage:" cli help

echo ""
echo "=== Summary ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [[ $FAILED -gt 0 ]]; then
    echo "Some tests failed!"
    exit 1
else
    echo "All tests passed!"
fi
