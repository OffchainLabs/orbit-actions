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

# Test 1: Tools are installed
echo "--- Tool Availability ---"
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

# Test 4: Scripts are accessible
echo ""
echo "--- Script Accessibility ---"

DEPLOY_SCRIPTS=(
    "scripts/foundry/contract-upgrades/1.2.1/DeployNitroContracts1Point2Point1UpgradeAction.s.sol"
    "scripts/foundry/contract-upgrades/2.1.0/DeployNitroContracts2Point1Point0UpgradeAction.s.sol"
    "scripts/foundry/contract-upgrades/2.1.2/DeployNitroContracts2Point1Point2UpgradeAction.s.sol"
    "scripts/foundry/contract-upgrades/2.1.3/DeployNitroContracts2Point1Point3UpgradeAction.s.sol"
    "scripts/foundry/arbos-upgrades/at-timestamp/DeployUpgradeArbOSVersionAtTimestampAction.s.sol"
)

for script in "${DEPLOY_SCRIPTS[@]}"; do
    script_name=$(basename "$script")
    run_test "$script_name exists" docker run --rm "$IMAGE_NAME" test -f "$script"
done

EXECUTE_SCRIPTS=(
    "scripts/foundry/contract-upgrades/1.2.1/ExecuteNitroContracts1Point2Point1Upgrade.s.sol"
    "scripts/foundry/contract-upgrades/2.1.0/ExecuteNitroContracts2Point1Point0Upgrade.s.sol"
    "scripts/foundry/contract-upgrades/2.1.2/ExecuteNitroContracts2Point1Point2Upgrade.s.sol"
    "scripts/foundry/contract-upgrades/2.1.3/ExecuteNitroContracts2Point1Point3Upgrade.s.sol"
)

for script in "${EXECUTE_SCRIPTS[@]}"; do
    script_name=$(basename "$script")
    run_test "$script_name exists" docker run --rm "$IMAGE_NAME" test -f "$script"
done

# Test 5: Yarn scripts work
echo ""
echo "--- Yarn Scripts ---"
run_test "yarn orbit:contracts:version --help" docker run --rm "$IMAGE_NAME" yarn orbit:contracts:version --help

# Test 6: Unit tests pass
echo ""
echo "--- Unit Tests ---"
echo "Running unit tests inside container..."
if docker run --rm "$IMAGE_NAME" yarn test:unit; then
    echo "Unit tests: OK"
else
    echo "Unit tests: FAILED"
    FAILURES=$((FAILURES + 1))
fi

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
