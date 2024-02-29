## ArbOS Upgrade at Timestamp
These scripts empower `UpgradeArbOSVersionAtTimestampAction` contract which schedule an ArbOS at specific timestamp for existing Orbit chains. Please note that ArbOS upgrade usually have a prerequisite of upgrading nitro-contracts and wasm module root to a specific version. Please make sure to check if your orbit chain met those prerequisite before performing ArbOS upgrade.

## How to use it
Setup .env according to the example files, make sure you have the correct ArbOS version and timestamp defined in the env file.

`Deployer.s.sol` script deploys `UpgradeArbOSVersionAtTimestampAction` contract. It can be executed in this directory like this:
```
forge script --account $DEPLOYER --rpc-url $RPC --broadcast --slow ./Deployer.s.sol -vvv
```

This would deploy the upgrade action.

`ExecuteUpgrade.s.sol` script uses previously deployed upgrade action to execute the upgrade. It makes following assumptions - L2UpgradeExecutor is an arbowner, and there is an EOA which has executor rights on the L2UpgradeExecutor. Proceed with upgrade using the owner account (the one with executor rights on L2UpgradeExecutor):
```
forge script --account $EOA_OWNER --rpc-url $RPC --broadcast ./ExecuteUpgrade.s.sol -vvv
```

That's it, the ArbOS upgrade has been scheduled. You can make sure it has successfully executed by checking wasm module root:
```
cast call --rpc-url $RPC 0x000000000000000000000000000000000000006b "getScheduledUpgrade()(uint64, uint64)"
```