#!/bin/bash

for i in {1..100}; do
  cast send --rpc-url $CHILD_RPC --private-key $DEPLOYMENT_PK $OWNER_ADDRESS --value 50000000 > /dev/null 2>&1
  sleep 0.25
done
