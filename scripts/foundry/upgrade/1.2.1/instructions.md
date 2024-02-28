## Nitro contracts 1.2.1 upgrade
These scripts empower `NitroContracts1Point2Point1Upgrade` action contract which performs upgrade to [1.2.1 release](https://github.com/OffchainLabs/nitro-contracts/releases/tag/v1.2.1) of Nitro contracts for existing Orbit chains.

## How to use it
`Deployer.s.sol` script deploys OSPs and ChallengeManager templates, blob reader and SequencerInbox template, and finally the upgrade action itself. Currently it is NOT applicable for chains which are hosted on Arbitrum chains. It can be executed like this:
```
forge script --account $DEPLOYER --rpc-url $RPC --broadcast --slow scripts/foundry/upgrade/1.2.1/Deployer.s.sol -vvv
```

As a result, all templates and upgrade action are deployed. Note the last deployed address - that's the upgrade action.

`ExecuteUpgrade.s.sol` script uses previously deployed upgrade action to execute the upgrade. It makes following assumptions - UpgradeExecutor is the rollup owner, and there is an EOA which has executor rights on the UpgradeExecutor. There are 4 input values which need to be provided to the script thorugh `.env` file: upgrade action, rollup, proxy admin and upgrade executor address (ie. check `.env.localL1-upgrade.example`). When `.env` is in place, proceed with upgrade using the owner account (the one with executor rights on UpgradeExecutor):
```
forge script --account $EOA_OWNER --rpc-url $RPC --broadcast scripts/foundry/upgrade/1.2.1/ExecuteUpgrade.s.sol -vvv
```

That's it, upgrade has been performed. You can make sure it has successfully executed by checking wasm module root:
```
cast call --rpc-url $RPC $ROLLUP "wasmModuleRoot()"
```