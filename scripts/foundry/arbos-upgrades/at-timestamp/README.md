# ArbOS Upgrade at Timestamp
These scripts empower `UpgradeArbOSVersionAtTimestampAction` contract which schedule an ArbOS at specific timestamp for existing Orbit chains. Please note that ArbOS upgrade usually have a prerequisite of upgrading nitro-contracts and wasm module root to a specific version. Please make sure to check if your orbit chain met those prerequisite before performing ArbOS upgrade.

## How to use it
Setup .env according to the example files, make sure you have the correct ArbOS version and timestamp defined in the env file.

`Deployer.s.sol` script deploys `UpgradeArbOSVersionAtTimestampAction` contract. It can be executed in this directory like this:
```
forge script --account DEPLOYER --rpc-url $CHILD_CHAIN_RPC --broadcast --slow ./Deployer.s.sol -vvv
```

This would deploy the upgrade action.

Next step is to execute the ArbOs upgrade action. Assumption is that child chain UpgradeExecutor is the arbowner, and there is an EOA which has executor rights on the child chain UpgradeExecutor. Upgrade can be executed using `cast` CLI command (part of Foundry installation), using the owner account (the one with executor rights on child chain UpgradeExecutor) to send the transaction:
```
cast send --account L3_OWNER --rpc-url $CHILD_CHAIN_RPC $CHILD_CHAIN_EXECUTOR "execute(address,bytes)" $ACTION  $(cast sig "perform()")
```

That's it, the ArbOS upgrade has been scheduled. You can make sure it has successfully executed by checking:
```
cast call --rpc-url $CHILD_CHAIN_RPC 0x000000000000000000000000000000000000006b "getScheduledUpgrade()(uint64, uint64)"
```