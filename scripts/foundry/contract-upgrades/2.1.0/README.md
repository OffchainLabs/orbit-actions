# Nitro contracts 2.1.0 upgrade

These scripts empower `NitroContracts2Point1Point0UpgradeAction` action contract which performs upgrade to [2.1.0 release](https://github.com/OffchainLabs/nitro-contracts/releases/tag/v2.1.0) of Nitro contracts for existing Orbit chains. Predeployed instances of the upgrade action exists on the chains listed in the following section with vanilla ArbOS31 wasm module root set. If you have a custom nitro machine, you will need to deploy the upgrade action yourself.

NitroContracts2Point1Point0UpgradeAction will perform the following action:

1. Upgrade ChallengeManager to v2.1.0
2. Set the wasm module root to the new version
3. Set the conditional wasm root and one step proof
4. Upgrade RollupAdminLogic and RollupUserLogic contracts

Note that contracts without code changes are not upgraded. It is normal to have some contracts still in the old version after the upgrade as they are equivalent to the new version. After the contract upgrade, you would need to schedule an ArbOS upgrade to ArbOS31 to enable the new features.

## Requirements

This upgrade only support upgrading from the following [nitro-contract release](https://github.com/OffchainLabs/nitro-contracts/releases):

- Inbox: v1.1.0 - v1.3.0 inclusive
- Outbox: v1.1.0 - v1.3.0 inclusive
- SequencerInbox: v1.2.1 - v2.1.0 inclusive
- Bridge: v1.1.0 - v1.3.0 inclusive
- RollupProxy: v1.1.0 - v2.1.0 inclusive
- RollupAdminLogic: v1.1.0 - v1.3.0 inclusive
- RollupUserLogic: v1.1.0 - v1.3.0 inclusive
- ChallengeManager: v1.2.1 - v1.3.0 inclusive

Please refer to the top [README](../../README.md) `Check Version and Upgrade Path` on how to determine your current nitro contracts version.

Also, expectation is that rollup being upgraded currently uses official ArbOS20 wasm module root. If other module root is used upgrade will revert with `NitroContracts2Point1Point0UpgradeAction: wasm root mismatch` message. In case you're using custom module root and want to perform this upgrade, please deploy another instance of upgrade action and provide yours wasm module root as cond root in the constructor.

## Deployed instances

### Mainnets
- L1 Mainnet: 0x9e0049B901531Aee041AD0D63FaEEefFBF442225
- L2 Arb1: 0xf6DdDf2C0C61571d2BD6F76f696287638ff012b8
- L2 Nova: 0xE2e3ab774aa0Bf4011C541F0C6b5c0B777A073c2
- L2 Base: 0x5F3bC0ff791AfCf8CbFb3AA08589e66c1711399D

### Testnets
- L1 Sepolia: 0x16f0a57F730b4C645a3b3c02B33A5a34F5a4bb6A
- L1 Holesky: 0x8fE5E84C07D8c002A8E7475df1280CA8f1979c5f
- L2 ArbSepolia: 0x7c6282fF5032aE3F66BaB070a2033979022fc059
- L2 BaseSepolia: 0x1a4B5212C58CD252345bF1E066b7d5E4f8785Ec9

## How to use it

1. Setup .env according to the example files, make sure you have everything correctly defined. The script will do some sanity checks but not everything can be checked.

2. (Skip this step if you can use the deployed instances of action contract)
   `DeployNitroContracts2Point1Point0UpgradeActionScript.s.sol` script deploys templates, and upgrade action itself. It can be executed in this directory like this:

```bash
forge script --sender $DEPLOYER --rpc-url $PARENT_CHAIN_RPC --broadcast --slow DeployNitroContracts2Point1Point0UpgradeActionScript -vvv --verify --skip-simulation
# use --account XXX / --private-key XXX / --interactive / --ledger to set the account to send the transaction from
```

As a result, all templates and upgrade action are deployed. Note the last deployed address - that's the upgrade action.

3. `ExecuteNitroContracts2Point1Point0Upgrade.s.sol` script uses previously deployed upgrade action to execute the upgrade. It makes following assumptions - L1UpgradeExecutor is the rollup owner, and there is an EOA which has executor rights on the L1UpgradeExecutor. Proceed with upgrade using the owner account (the one with executor rights on L1UpgradeExecutor):

```bash
forge script --sender $EXECUTOR --rpc-url $PARENT_CHAIN_RPC --broadcast ExecuteNitroContracts2Point1Point0UpgradeScript -vvv
# use --account XXX / --private-key XXX / --interactive / --ledger to set the account to send the transaction from
```

If you have a multisig as executor, you can still run the above command without broadcasting to get the payload for the multisig transaction.

4. That's it, upgrade has been performed. You can make sure it has successfully executed by checking wasm module root:

```bash
cast call --rpc-url $PARENT_CHAIN_RPC $ROLLUP "wasmModuleRoot()"
```

## FAQ

### Q: node error: unable to find validator machine directory for the on-chain WASM module root

```
unable to find validator machine directory for the on-chain WASM module root err="stat /home/user/target/machines/0x260f5fa5c3176a856893642e149cf128b5a8de9f828afec8d11184415dd8dc69: no such file or directory"
```

A: upgrade to nitro-node v3.1.0+

### Q: error generating node action: wasmroot doesn't match rollup

```
error acting as staker                   err="error advancing stake from node 0 (hash 0x0000000000000000000000000000000000000000000000000000000000000000): error generating node action: wasmroot doesn't match rollup : 0x260f5fa5c3176a856893642e149cf128b5a8de9f828afec8d11184415dd8dc69, valid: [0x8b104a2e80ac6165dc58b9048de12f301d70b02a0ab51396c22b4b4b802a16a4]"
```

A: make sure there is activity on the child chain and a new batch is posted after the upgrade

### Q: intrinsic gas too low when running foundry script

A: try to add -g 1000 to the command
