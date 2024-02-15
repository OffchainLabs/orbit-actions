#!/bin/bash
outputDir="./test/storage"
for contractName in $(./scripts/print-contracts.bash)
do
    echo "Checking storage change of $contractName"
    [ -f "$outputDir/$contractName" ] && mv "$outputDir/$contractName" "$outputDir/$contractName-old"
    forge inspect "$contractName" --pretty storage > "$outputDir/$contractName"
    diff "$outputDir/$contractName-old" "$outputDir/$contractName"
    if [[ $? != "0" ]]
    then
        CHANGED=1
    fi
done

rm -f "$outputDir"/*-old

exit $CHANGED