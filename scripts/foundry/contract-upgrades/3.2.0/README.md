# Nitro contracts 3.2.0 upgrade

These scripts deploy and execute the `NitroContracts3Point2Point0UpgradeAction` contract which allows Orbit chains to upgrade to [3.2.0 release](https://github.com/OffchainLabs/nitro-contracts/releases/tag/v3.2.0).

`NitroContracts3Point2Point0UpgradeAction` will perform the following action:

1. TODO: describe upgrade steps

## Requirements

This upgrade only supports upgrading from the following [nitro-contract release](https://github.com/OffchainLabs/nitro-contracts/releases):

- TODO: list supported source versions per contract

Please refer to the top [README](/README.md#check-version-and-upgrade-path) `Check Version and Upgrade Path` on how to determine your current nitro contracts version.

## Deployed instances

### Mainnets
- TODO

### Testnets
- TODO

## How to use it

1. Setup .env according to the example files, make sure you have everything correctly defined. The .env file must be in project root for recent foundry versions.

> [!CAUTION]
> The .env file must be in project root.

2. (Skip this step if you can use the deployed instances of action contract)
   `DeployNitroContracts3Point2Point0UpgradeActionScript.s.sol` script deploys templates, and upgrade action itself. It can be executed in this directory like this:

```bash
forge script --sender $DEPLOYER --rpc-url $PARENT_CHAIN_RPC --broadcast --slow DeployNitroContracts3Point2Point0UpgradeActionScript -vvv --verify --skip-simulation
# use --account XXX / --private-key XXX / --interactive / --ledger to set the account to send the transaction from
```

As a result, all templates and upgrade action are deployed. Note the last deployed address - that's the upgrade action.

3. `ExecuteNitroContracts3Point2Point0Upgrade.s.sol` script uses previously deployed upgrade action to execute the upgrade. It makes following assumptions - L1UpgradeExecutor is the rollup owner, and there is an EOA which has executor rights on the L1UpgradeExecutor. Proceed with upgrade using the owner account (the one with executor rights on L1UpgradeExecutor):

```bash
forge script --sender $EXECUTOR --rpc-url $PARENT_CHAIN_RPC --broadcast ExecuteNitroContracts3Point2Point0UpgradeScript -vvv
# use --account XXX / --private-key XXX / --interactive / --ledger to set the account to send the transaction from
```

If you have a multisig as executor, you can still run the above command without broadcasting to get the payload for the multisig transaction.

4. That's it, upgrade has been performed. TODO: add verification instructions.

## FAQ

### Q: intrinsic gas too low when running foundry script

A: try to add -g 1000 to the command
