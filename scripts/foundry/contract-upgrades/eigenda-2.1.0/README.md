# Nitro x EigenDA contracts 2.1.0 upgrade

These scripts empower `NitroContractsEigenDA2Point1Point0UpgradeAction` action contract which migrates existing orbit system contracts to using orbit x eigenda [contracts](https://github.com/Layr-Labs/nitro-contracts).

Predeployed instances of the upgrade action exists on the chains listed in the following section with vanilla ArbOS32 wasm module root set. 

`NitroContractsEigenDA2Point1Point0UpgradeAction` will perform the following action:

1. Upgrade ChallengeManager to eigenda-v2.1.0
2. Set the wasm module root to the eigenda-v2.1.0 replay artifact hash
3. Set the conditional wasm module root to the arbitrum-v2.1.0 release 
3. Upgrade SequencerInbox to eigenda-v2.1.0
4. Set a new OneStepProverEntry using the modified EigenDA OneStepProverHostIO 
5. Upgrade RollupAdminLogic and RollupUserLogic contracts to use new OSP Entry

Note that contracts without code changes are not upgraded. It is normal to have some contracts still in the old version after the upgrade as they are equivalent in the new EigenDA v2.1.0 version. 

## Requirements

This upgrade only supports upgrading from the following [nitro-contract release](https://github.com/OffchainLabs/nitro-contracts/releases/tag/v2.1.0):

- RollupManager: v2.1.0 --> eigenda-v2.1.0
- SequencerInbox: v2.1.0 --> eigenda-v2.1.0
- RollupProxy: v2.1.0 --> eigenda-v2.1.0
- RollupAdminLogic:  v2.1.0 --> eigenda-v2.1.0
- RollupUserLogic:  v2.1.0 --> eigenda-v2.1.0
- ChallengeManager:  v2.1.0 --> eigenda-v2.1.0

Please refer to the top [README](../../README.md) `Check Version and Upgrade Path` on how to determine your current nitro contracts version.

Also, expectation is that rollup being migrated currently uses the official ArbOS32 wasm module root. If other module root is used then the upgrade will revert with `NitroContractsEigenDA2Point1Point0UpgradeAction: wasm root mismatch` message. In case you're using custom module root and want to perform this upgrade, please deploy another instance of upgrade action and provide yours wasm module root as cond root in the constructor.

## Deployed instances

### Mainnets
- L1 Mainnet: 
- L2 Arb1: 
- L2 Nova: 
- L2 Base: 

### Testnets
- L1 Sepolia: 
- L1 Holesky: 
- L2 ArbSepolia: 
- L2 BaseSepolia: 

## How to use it

1. Setup `.env` according to the example files, make sure you have everything correctly defined. The script will do some sanity checks but not everything can be checked. The .env file must be in project root for recent foundry versions.

> [!CAUTION]
> The .env file must be in project root.

2. (Skip this step if you can use the deployed instances of action contract)
   `DeployNitroContractsEigenDA2Point1Point0UpgradeActionScript.s.sol` script deploys templates, and upgrade action itself. It can be executed in this directory like this:

```bash
forge script --sender $DEPLOYER --rpc-url $PARENT_CHAIN_RPC --broadcast --slow DeployNitroContractsEigenDA2Point1Point0UpgradeActionScript -vvv --verify --skip-simulation
# use --account XXX / --private-key XXX / --interactive / --ledger to set the account to send the transaction from
```

As a result, all templates and upgrade action are deployed. Note the last deployed address - that's the upgrade action.

3. `ExecuteNitroContractsEigenDA2Point1Point0UpgradeScript.s.sol` script uses previously deployed upgrade action to execute the upgrade. It makes following assumptions - L1UpgradeExecutor is the rollup owner, and there is an EOA which has executor rights on the L1UpgradeExecutor. Proceed with upgrade using the owner account (the one with executor rights on L1UpgradeExecutor):

```bash
forge script --sender $EXECUTOR --rpc-url $PARENT_CHAIN_RPC --broadcast ExecuteNitroContractsEigenDA2Point1Point0UpgradeScript -vvv
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
