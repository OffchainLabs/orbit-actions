#!/bin/bash

outputDir="./test/signatures"
for contractName in $(./scripts/print-contracts.bash)
do
    echo "Checking for signature changes in $contractName"
    [ -f "$outputDir/$contractName" ] && mv "$outputDir/$contractName" "$outputDir/$contractName-old"
    forge inspect "$contractName" methods > "$outputDir/$contractName"
    diff "$outputDir/$contractName-old" "$outputDir/$contractName"
    if [[ $? != "0" ]]
    then
        CHANGED=1
    fi
done

rm -f "$outputDir"/*-old

exit $CHANGED
