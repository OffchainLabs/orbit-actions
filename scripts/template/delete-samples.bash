#!/bin/bash

shopt -s globstar

# remove sample contracts
rm contracts/Counter.sol

# remove sample unit tests
rm test/unit/Counter.test.ts test/unit/Counter.t.sol

# remove sample fork tests
rm test/fork/arb/Sample.t.sol test/fork/arb/Sample.test.ts
rm test/fork/eth/Sample.t.sol test/fork/eth/Sample.test.ts

# remove sample e2e tests
rm test/e2e/Counter.test.ts

# delete this script as it is no longer needed
rm scripts/template/delete-samples.bash
