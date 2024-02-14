#!/bin/bash

output_dir="./test/signatures"
for CONTRACTNAME in $(./scripts/print-contracts.bash)
do
    echo "Checking for signature changes in $CONTRACTNAME"
    [ -f "$output_dir/$CONTRACTNAME" ] && mv "$output_dir/$CONTRACTNAME" "$output_dir/$CONTRACTNAME-old"
    forge inspect "$CONTRACTNAME" methods > "$output_dir/$CONTRACTNAME"
    diff "$output_dir/$CONTRACTNAME-old" "$output_dir/$CONTRACTNAME"
    if [[ $? != "0" ]]
    then
        CHANGED=1
    fi
done

rm -f "$output_dir"/*-old

exit $CHANGED
