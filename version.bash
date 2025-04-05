#!/bin/bash

export MODULE_NAME=$1
export CPATH=$2$MODULE_NAME
export RPC=$(cat $CPATH/helm/values.yaml | yq .L1_RPC_URL | tr -d '"')

export INBOX_ADDRESS=$(cat $CPATH/.constellation/contracts.json | jq .coreContracts.inbox | tr -d '"') 
export PROXY_ADMIN_ADDRESS=$(cat $CPATH/.constellation/contracts.json | jq .coreContracts.adminProxy | tr -d '"')  
export PARENT_UPGRADE_EXECUTOR_ADDRESS=$(cat $CPATH/.constellation/contracts.json | jq .coreContracts.upgradeExecutor | tr -d '"') 
PARENT_CHAIN_ID=$(cat $CPATH/.constellation/contracts.json | jq .chainInfo.parentChainId) 
if [[ "$PARENT_CHAIN_ID" == "421614" || "$PARENT_CHAIN_ID" == "42161" ]]; then
  export PARENT_CHAIN_IS_ARBITRUM=true
else
  export PARENT_CHAIN_IS_ARBITRUM=false
fi

export MAX_DATA_SIZE=$(cast call --rpc-url $RPC $INBOX_ADDRESS "maxDataSize()(uint256)" | awk '{print $1; exit}')
echo $INBOX_ADDRESS
DEV=true INBOX_ADDRESS=$INBOX_ADDRESS yarn orbit:contracts:version --network $(echo $PARENT_CHAIN_ID | tr -d '"')
