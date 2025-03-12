#!/bin/bash

export MODULE_NAME=$1
export DEPLOYMENT_PK=$2

export CPATH=/Users/inomurko/opt/cm2/module-driver/active-deployments/nitros/$MODULE_NAME
export OWNER_PK=$(aws secretsmanager --query SecretString --output text get-secret-value --secret-id $(cat $CPATH/helm/values.yaml | yq .accounts.OWNER_KMS_ID) | jq .privateKey | tr -d '"')
export OWNER_ADDRESS=$(cat $CPATH/helm/values.yaml | yq .accounts.OWNER_ADDRESS)

export RPC=$(cat $CPATH/helm/values.yaml | yq .L1_RPC_URL | tr -d '"')

export INBOX_ADDRESS=$(cat $CPATH/.constellation/contracts.json | jq .coreContracts.inbox | tr -d '"') 
export PROXY_ADMIN_ADDRESS=$(cat $CPATH/.constellation/contracts.json | jq .coreContracts.adminProxy | tr -d '"')  
export PARENT_UPGRADE_EXECUTOR_ADDRESS=$(cat $CPATH/.constellation/contracts.json | jq .coreContracts.upgradeExecutor | tr -d '"') 
export WASM_MODULE_ROOT=0x8b104a2e80ac6165dc58b9048de12f301d70b02a0ab51396c22b4b4b802a16a4
PARENT_CHAIN_ID=$(cat $CPATH/.constellation/contracts.json | jq .chainInfo.parentChainId) 
if [[ "$PARENT_CHAIN_ID" == "421614" || "$PARENT_CHAIN_ID" == "42161" ]]; then
  export PARENT_CHAIN_IS_ARBITRUM=true
else
  export PARENT_CHAIN_IS_ARBITRUM=false
fi

if [[ "$PARENT_CHAIN_ID" == "1" || "$PARENT_CHAIN_ID" == "11155111" ]]; then
  export ETHERSCAN_API_KEY=RWSGJAX2JJNX42SB56ADUWFN6MSB5WBHNR
else
  export ETHERSCAN_API_KEY=VAQC4ZPAQGBRUMW8AR5CVAUKE96VNM2735
fi

IS_FEE_TOKEN_CHAIN=$(cat $CPATH/.constellation/contracts.json | jq .chainInfo.nativeToken | tr -d '"') 
if [[ "$IS_FEE_TOKEN_CHAIN" == "0x0000000000000000000000000000000000000000" ]]; then
  export IS_FEE_TOKEN_CHAIN=false
else
  export IS_FEE_TOKEN_CHAIN=true
fi

export MAX_DATA_SIZE=$(cast call --rpc-url $RPC $INBOX_ADDRESS "maxDataSize()(uint256)" | awk '{print $1; exit}')

DEV=true INBOX_ADDRESS=$INBOX_ADDRESS yarn orbit:contracts:version --network $(echo $PARENT_CHAIN_ID | tr -d '"')

#ARBOS32
export TARGET_WASM_MODULE_ROOT=0x184884e1eb9fefdc158f6c8ac912bb183bf3cf83f0090317e0bc4ac5860baa39
export ROLLUP_ADDRESS=$(cat $CPATH/.constellation/contracts.json | jq .coreContracts.rollup | tr -d '"') 
export CURRENT_WASM=$(cast call --rpc-url $RPC $ROLLUP_ADDRESS "wasmModuleRoot()")
echo "Current WASM"
echo $CURRENT_WASM
echo "Target WASM"
echo $TARGET_WASM_MODULE_ROOT
echo "Deploying DeployNitroContracts2Point1Point0UpgradeActionScript"
forge script --private-key $DEPLOYMENT_PK --rpc-url $RPC --broadcast DeployNitroContracts2Point1Point0UpgradeActionScript -vvv --verify --skip-simulation

echo "Topup owner with 0.01ether"
cast send --rpc-url $RPC --private-key $DEPLOYMENT_PK $OWNER_ADDRESS --value 0.01ether
echo "Balance of "$OWNER_ADDRESS
cast from-wei $(cast balance --rpc-url $RPC $OWNER_ADDRESS)
export MULTISIG=false
#export UPGRADE_ACTION_ADDRESS=
#forge script --private-key $OWNER_PK --rpc-url $RPC --broadcast  ExecuteNitroContracts2Point1Point0UpgradeScript -vvv --verify --skip-simulation
echo "Set - --node.batch-poster.max-delay=1m on batch poster!" 
if [[ "$IS_FEE_TOKEN_CHAIN" == "0x0000000000000000000000000000000000000000" ]]; then
  echo "Make a deposit (speed up a new batch)"
  cast send --rpc-url $RPC --private-key $DEPLOYMENT_PK $INBOX_ADDRESS "depositEth(uint256)" 50000000000000 --value 50000000000000
  export CHILD_RPC=https://$(cat $CPATH/helm/values.yaml | yq .metadata.HOST | tr -d '"')/http
  for i in {1..100}; do
    cast send --rpc-url $CHILD_RPC --private-key $DEPLOYMENT_PK $OWNER_ADDRESS --value 500000000 > /dev/null 2>&1
    sleep 0.25
  done
fi
