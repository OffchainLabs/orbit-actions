# Set WasmModuleRoot

This script empowers `SetWasmModuleRootAction` contract which updates the wasmModuleRoot for existing Arbitrum chains, on the Rollup contract deployed on their parent chain.

## How to use it

1. Setup .env according to the example files, make sure you have the correct previous and new wasmModuleRoot. The previous wasmModuleRoot should identify the wasmModuleRoot from which you're upgrading your chain.

`DeploySetWasmModuleRootActionScript.s.sol` script deploys `SetWasmModuleRootAction` contract. It can be executed in this directory like this:

```shell
forge script --sender $DEPLOYER --rpc-url $PARENT_CHAIN_RPC --broadcast --slow ./DeploySetWasmModuleRootActionScript.s.sol -vvv --verify
# use --account XXX / --private-key XXX / --interactive / --ledger to set the account to send the transaction from
```

This will deploy the upgrade action. Update your .env file with the address of the upgrade action.

> [!CAUTION]
> The .env file must be in project root.

2. Next step is to execute the action. Assumption is that there is an EOA which has executor rights on the parent chain UpgradeExecutor. The upgrade can be executed using `cast` CLI command (part of Foundry installation), using the account with executor rights on the parent chain UpgradeExecutor to send the transaction:

```shell
(export $(cat .env | xargs) && cast send $PARENT_UPGRADE_EXECUTOR_ADDRESS "execute(address, bytes)" $UPGRADE_ACTION_ADDRESS $(cast calldata "perform(address)" $INBOX) --rpc-url $PARENT_CHAIN_RPC)
# use --account XXX / --private-key XXX / --interactive / --ledger to set the account to send the transaction from
```

If you have a multisig as the executor, you can use the following command to create the payload for calling into the `PARENT_UPGRADE_EXECUTOR_ADDRESS`:

```shell
(export $(cat .env | xargs) && cast calldata "execute(address, bytes)" $UPGRADE_ACTION_ADDRESS $(cast calldata "perform(address)" $INBOX))
```

3. That's it, the wasm module root should be updated. You can make sure it has successfully executed by checking:

```shell
# Check the current wasm module root (should be the new wasm module root)
cast call --rpc-url $PARENT_CHAIN_RPC $ROLLUP_ADDRESS "wasmModuleRoot()(bytes32)"
```
