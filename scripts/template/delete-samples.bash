#!/bin/bash

shopt -s globstar

# remove sample contracts
rm contracts/Counter.sol

# remove sample unit tests
rm test/unit/Counter.test.ts test/unit/Counter.t.sol

# remove sample fork tests
rm test/fork/Sample.t.sol test/fork/Sample.test.ts

# remove sample e2e tests
rm test/e2e/Counter.test.ts

# remove sample mock
rm test/mocks/SampleMock.sol

# delete this script as it is no longer needed
rm scripts/template/delete-samples.bash
