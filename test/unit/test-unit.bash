#!/bin/bash

shopt -s globstar

hardhatFiles=$(ls ./test/unit/**/*.test.ts)
if [ -n "$hardhatFiles" ]; then
    yarn run hardhat test $hardhatFiles
    code=$?
fi

[ "$code" -ne 0 ] && exit $code

foundryFiles=$(ls ./test/unit/**/*.t.sol)
if [ -n "$foundryFiles" ]; then
    forge test --match-path "test/unit/*.t.sol"
    code=$?
fi

exit $code
