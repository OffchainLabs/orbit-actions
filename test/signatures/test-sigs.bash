#!/bin/bash

contracts=$(./scripts/print-contracts.bash)
if [[ $? != "0" ]]; then
    echo "Failed to get contracts"
    exit 1
fi

outputDir="./test/signatures"

for contractName in $contracts; do
    echo "Checking for signature changes in $contractName"
    [ -f "$outputDir/$contractName" ] && mv "$outputDir/$contractName" "$outputDir/$contractName-old"
    forge inspect "$contractName" methods > "$outputDir/$contractName"
    diff "$outputDir/$contractName-old" "$outputDir/$contractName"
    if [[ $? != "0" ]]; then
        CHANGED=1
    fi
done

rm -f "$outputDir"/*-old

exit $CHANGED
