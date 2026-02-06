#!/bin/bash
set -euo pipefail

# Docker smoke tests for orbit-actions
# Verifies that all required tools and scripts are accessible in the Docker image

IMAGE_NAME="${DOCKER_IMAGE:-orbit-actions:test}"

echo "=== Docker Smoke Tests ==="
echo "Image: $IMAGE_NAME"
echo ""

# Track failures
FAILURES=0

run_test() {
    local name="$1"
    shift
    echo -n "Testing $name... "
    if "$@" > /dev/null 2>&1; then
        echo "OK"
    else
        echo "FAILED"
        FAILURES=$((FAILURES + 1))
    fi
}

# Test 1: Tools are installed (passthrough)
echo "--- Tool Passthrough ---"
run_test "forge" docker run --rm "$IMAGE_NAME" forge --version
run_test "cast" docker run --rm "$IMAGE_NAME" cast --version
run_test "yarn" docker run --rm "$IMAGE_NAME" yarn --version
run_test "node" docker run --rm "$IMAGE_NAME" node --version

# Test 2: Dependencies are installed
echo ""
echo "--- Dependencies ---"
run_test "node_modules exists" docker run --rm "$IMAGE_NAME" test -d node_modules
run_test "forge dependencies" docker run --rm "$IMAGE_NAME" test -d node_modules/@arbitrum

# Test 3: Contracts compile
echo ""
echo "--- Contract Compilation ---"
run_test "contracts built" docker run --rm "$IMAGE_NAME" test -d out

# Test 4: Browsing - list directories
echo ""
echo "--- Directory Browsing ---"

# List top level
echo -n "Testing list top level... "
TOP_OUTPUT=$(docker run --rm "$IMAGE_NAME" 2>&1)
if echo "$TOP_OUTPUT" | grep "contract-upgrades" > /dev/null; then
    echo "OK"
else
    echo "FAILED"
    FAILURES=$((FAILURES + 1))
fi

# List contract-upgrades versions
echo -n "Testing list contract-upgrades... "
VERSIONS_OUTPUT=$(docker run --rm "$IMAGE_NAME" contract-upgrades 2>&1)
if echo "$VERSIONS_OUTPUT" | grep "1.2.1" > /dev/null && echo "$VERSIONS_OUTPUT" | grep "2.1.0" > /dev/null; then
    echo "OK"
else
    echo "FAILED"
    FAILURES=$((FAILURES + 1))
fi

# List version contents (should show virtual commands)
echo -n "Testing list contract-upgrades/1.2.1... "
CONTENTS_OUTPUT=$(docker run --rm "$IMAGE_NAME" contract-upgrades/1.2.1 2>&1)
if echo "$CONTENTS_OUTPUT" | grep "deploy-execute-verify" > /dev/null; then
    echo "OK"
else
    echo "FAILED"
    FAILURES=$((FAILURES + 1))
fi

# Test 5: File viewing
echo ""
echo "--- File Viewing ---"

# View README
echo -n "Testing view README... "
README_OUTPUT=$(docker run --rm "$IMAGE_NAME" contract-upgrades/1.2.1/README.md 2>&1)
if echo "$README_OUTPUT" | grep -i "nitro" > /dev/null; then
    echo "OK"
else
    echo "FAILED"
    FAILURES=$((FAILURES + 1))
fi

# View env template (1.2.1 has env-templates/)
echo -n "Testing view env template... "
ENV_OUTPUT=$(docker run --rm "$IMAGE_NAME" contract-upgrades/1.2.1/env-templates/.env.local-upgrade.example 2>&1)
if echo "$ENV_OUTPUT" | grep "INBOX_ADDRESS" > /dev/null; then
    echo "OK"
else
    echo "FAILED"
    FAILURES=$((FAILURES + 1))
fi

# View .env.sample (2.1.0+ has .env.sample)
echo -n "Testing view .env.sample... "
SAMPLE_OUTPUT=$(docker run --rm "$IMAGE_NAME" contract-upgrades/2.1.0/.env.sample 2>&1)
if echo "$SAMPLE_OUTPUT" | grep "UPGRADE_ACTION_ADDRESS" > /dev/null; then
    echo "OK"
else
    echo "FAILED"
    FAILURES=$((FAILURES + 1))
fi

# Test 6: Help
echo ""
echo "--- Help ---"
run_test "help command" docker run --rm "$IMAGE_NAME" help

# Test 7: Yarn scripts work
echo ""
echo "--- Yarn Scripts ---"
run_test "yarn orbit:contracts:version --help" docker run --rm "$IMAGE_NAME" yarn orbit:contracts:version --help

# Test 8: Unit tests pass
echo ""
echo "--- Unit Tests ---"
echo "Running unit tests inside container..."
if docker run --rm "$IMAGE_NAME" yarn test:unit; then
    echo "Unit tests: OK"
else
    echo "Unit tests: FAILED"
    FAILURES=$((FAILURES + 1))
fi

# Test 9: Dry run tests (requires .env file)
echo ""
echo "--- Dry Run Tests ---"

# Create a temporary .env file for testing arbos
TEMP_ENV=$(mktemp)
cat > "$TEMP_ENV" <<EOF
CHILD_CHAIN_RPC=http://localhost:8545
CHILD_UPGRADE_EXECUTOR_ADDRESS=0x0000000000000000000000000000000000000001
UPGRADE_ACTION_ADDRESS=0x0000000000000000000000000000000000000002
SCHEDULE_TIMESTAMP=1709229600
EOF

echo -n "Testing arbos dry-run calldata... "
DRYRUN_OUTPUT=$(docker run --rm -v "$TEMP_ENV:/app/.env" "$IMAGE_NAME" arbos-upgrades/at-timestamp/deploy-execute-verify 32 --dry-run 2>&1)
if echo "$DRYRUN_OUTPUT" | grep "Calldata:" > /dev/null; then
    echo "OK"
else
    echo "FAILED"
    FAILURES=$((FAILURES + 1))
fi

rm -f "$TEMP_ENV"

# Summary
echo ""
echo "=== Summary ==="
if [ $FAILURES -eq 0 ]; then
    echo "All tests passed!"
    exit 0
else
    echo "$FAILURES test(s) failed"
    exit 1
fi
