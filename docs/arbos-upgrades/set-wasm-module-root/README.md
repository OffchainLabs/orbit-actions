# Set WasmModuleRoot

This document shows how to update the wasmModuleRoot for existing Arbitrum chains, on the Rollup contract deployed on their parent chain, by using the `executeCall` method of the [UpgradeExecutor](https://github.com/OffchainLabs/upgrade-executor/blob/v1.1.1/src/UpgradeExecutor.sol#L73).

## How to update the WasmModuleRoot of a chain

1. Add the following env variables to a .env file placed in the project root:

    - `ROLLUP_ADDRESS`: address of the rollup contract of your chain
    - `WASM_MODULE_ROOT`: new wasmModuleRoot to update the chain to
    - `PARENT_UPGRADE_EXECUTOR_ADDRESS`: address of the UpgradeExecutor on the parent chain
    - `PARENT_CHAIN_RPC`: RPC of the parent chain

> [!CAUTION]
> The .env file must be in project root.

2. Call the Rollup contract to update the wasmModuleRoot. In this case, we assume that there is an EOA which has executor rights on the parent chain's UpgradeExecutor. The upgrade can be executed using the `cast` CLI command (part of Foundry installation), using the account with executor rights on the parent chain UpgradeExecutor to send the transaction:

```shell
(export $(cat .env | xargs) && cast send $PARENT_UPGRADE_EXECUTOR_ADDRESS "executeCall(address, bytes)" $ROLLUP_ADDRESS $(cast calldata "setWasmModuleRoot(bytes32)" $WASM_MODULE_ROOT) --rpc-url $PARENT_CHAIN_RPC)
# use --account XXX / --private-key XXX / --interactive / --ledger to set the account to send the transaction from
```

If you have a multisig as the executor, you can use the following command to create the payload for calling into the `PARENT_UPGRADE_EXECUTOR_ADDRESS`:

```shell
(export $(cat .env | xargs) && cast calldata "executeCall(address, bytes)" $ROLLUP_ADDRESS $(cast calldata "setWasmModuleRoot(bytes32)" $WASM_MODULE_ROOT))
```

3. That's it, the wasm module root should be updated. You can make sure it has successfully executed by checking:

```shell
# Check the current wasm module root (should be the new wasm module root)
cast call --rpc-url $PARENT_CHAIN_RPC $ROLLUP_ADDRESS "wasmModuleRoot()(bytes32)"
```
