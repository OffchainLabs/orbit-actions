# Nitro contracts 2.0.0 upgrade
These scripts empower `NitroContracts2Point0Point0UpgradeAction` action contract which performs upgrade to [2.0.0 release](https://github.com/OffchainLabs/nitro-contracts/releases/tag/v2.0.0) of Nitro contracts for existing Orbit chains. Predeployed instances of the upgrade action exists on the chains listed in the following section with vanilla ArbOS31 wasm module root set. If you have a custom nitro machine, you will need to deploy the upgrade action yourself.

NitroContracts2Point0Point0UpgradeAction will perform the following action:
1. Upgrade ChallengeManager to v2.0.0
2. Set the wasm module root to the new version
3. Set the conditional wasm root and one step proof
4. Upgrade RollupAdminLogic and RollupUserLogic contracts

Note that contracts without code changes are not upgraded. It is normal to have some contracts still in the old version after the upgrade as they are equivalent to the new version. After the contract upgrade, you would need to schedule an ArbOS upgrade to ArbOS31 to enable the new features.

## Requirements
This upgrade only support upgrading from the following [nitro-contract release](https://github.com/OffchainLabs/nitro-contracts/releases):
- Inbox: v1.1.0 - v2.0.0 inclusive
- Outbox: v1.1.0 - v2.0.0 inclusive
- SequencerInbox: v1.2.1 - v2.0.0 inclusive
- Bridge: v1.1.0 - v2.0.0 inclusive
- RollupProxy: v1.1.0 - v2.0.0 inclusive
- RollupAdminLogic: v1.1.0 - v2.0.0 inclusive
- RollupUserLogic: v1.1.0 - v2.0.0 inclusive
- ChallengeManager: v1.2.1 - v1.3.0 inclusive

Please refer to the top [README](../../README.md) `Check Version and Upgrade Path` on how to determine your current nitro contracts version.

## Deployed instances

TBD

## How to use it

1. Setup .env according to the example files, make sure you have everything correctly defined. The script will do some sanity checks but not everything can be checked.

2. (Skip this step if you can use the deployed instances of action contract) 
`DeployNitroContracts2Point0Point0UpgradeActionScript.s.sol` script deploys templates, and upgrade action itself. It can be executed in this directory like this:
```bash
forge script --sender $DEPLOYER --rpc-url $PARENT_CHAIN_RPC --broadcast --slow ./DeployNitroContracts2Point0Point0UpgradeAction.s.sol -vvv --verify --skip-simulation
# use --account XXX / --private-key XXX / --interactive / --ledger to set the account to send the transaction from
```
As a result, all templates and upgrade action are deployed. Note the last deployed address - that's the upgrade action.

3. `ExecuteNitroContracts2Point0Point0Upgrade.s.sol` script uses previously deployed upgrade action to execute the upgrade. It makes following assumptions - L1UpgradeExecutor is the rollup owner, and there is an EOA which has executor rights on the L1UpgradeExecutor. Proceed with upgrade using the owner account (the one with executor rights on L1UpgradeExecutor):
```bash
forge script --sender $EXECUTOR --rpc-url $PARENT_CHAIN_RPC --broadcast ./ExecuteNitroContracts2Point0Point0Upgrade.s.sol -vvv
# use --account XXX / --private-key XXX / --interactive / --ledger to set the account to send the transaction from
```
If you have a multisig as executor, you can still run the above command without broadcasting to get the payload for the multisig transaction.

4. That's it, upgrade has been performed. You can make sure it has successfully executed by checking wasm module root:
```bash
cast call --rpc-url $PARENT_CHAIN_RPC $ROLLUP "wasmModuleRoot()"
```
