# Nitro contracts 2.1.0 upgrade

These scripts empower `NitroContracts2Point1Point0UpgradeAction` action contract which performs upgrade to [2.1.0 release](https://github.com/OffchainLabs/nitro-contracts/releases/tag/v2.1.0) of Nitro contracts for existing Orbit chains. Predeployed instances of the upgrade action exists on the chains listed in the following section with vanilla ArbOS32 wasm module root set. If you have a custom nitro machine, you will need to deploy the upgrade action yourself.

CelestiaNitroContracts2Point1Point0UpgradeAction will perform the following action:

1. Migrate the SequencerInbox to the celestia-v2.1.0 version
2. Migrate ChallengeManager to celestia-v2.1.0
3. Set the wasm module root to the new version
4. Set the conditional wasm root and one step proof needed to handle Celestia specific fraud proof logic inside of the ChallengeManager
5. Migrate RollupAdminLogic and RollupUserLogic contracts

Note that contracts without code changes are not upgraded. It is normal to have some contracts still in the old version after the upgrade as they are equivalent to the new version. Additionally note that only the SequencerInbox and OneStepProverHostIo contracts change for Celestia DA, but changing these requires the contracts mentioned above to be migrated.

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

## How to use it

1. Setup .env according to the example files, make sure you have everything correctly defined. The script will do some sanity checks but not everything can be checked. The .env file must be in project root for recent foundary versions.

> [!CAUTION]
> The .env file must be in project root.

2. (Skip this step if you can use the deployed instances of action contract)
   `DeployCelestiaNitroContracts2Point1Point0UpgradeActionScript.s.sol` script deploys templates, and upgrade action itself. It can be executed in this directory like this:

```bash
forge script --sender $DEPLOYER --rpc-url $PARENT_CHAIN_RPC --broadcast --slow DeployNitroContracts2Point1Point0UpgradeActionScript -vvv --verify --skip-simulation
# use --account XXX / --private-key XXX / --interactive / --ledger to set the account to send the transaction from
```

As a result, all templates and upgrade action are deployed. Note the last deployed address - that's the upgrade action.

3. `ExecuteCelestiaNitroContracts2Point1Point0Upgrade.s.sol` script uses previously deployed upgrade action to execute the upgrade. It makes following assumptions - L1UpgradeExecutor is the rollup owner, and there is an EOA which has executor rights on the L1UpgradeExecutor. Proceed with upgrade using the owner account (the one with executor rights on L1UpgradeExecutor):

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

### Q: What are the expected values in the .env

A: 

In order to deploy and execute the migration, you will need to fill out the following `.env`

```
## Deployment
NEW_OSP=
COND_OSP=
NEW_CHALLENGE_MANAGER=
NEW_ROLLUP_ADMIN=
NEW_ROLLUP_USER_LOGIC=
NEW_SEQUENCER_INBOX=
TARGET_WASM_MODULE_ROOT=
PARENT_CHAIN_IS_ARBITRUM=true
IS_FEE_TOKEN_CHAIN=false
MAX_DATA_SIZE=

## Execution
UPGRADE_ACTION_ADDRESS=
PROXY_ADMIN_ADDRESS=
PARENT_UPGRADE_EXECUTOR_ADDRESS=
INBOX_ADDRESS=
```

The deployment section is the values needed to deploy the upgrade action, most can be fetched from an existing or personally deployed `RollupCreator` from the Celestia nitro contracts repo, the exceptions are `COND_OSP` which refers to the current OSP address used by the rollup being migrated, `TARGET_WASM_MODULE_ROOT` which refers to the wasm module root currently used by the rollup, `PARENT_CHAIN_IS_ARBITRUM` if the parent chain is a chain using the Arbitrum stack, `IS_FEE_TOKEN_CHAIN` if the chain uses a non native token as a gas token (an ERC20 token), and `MAX_DATA_SIZE` referring to the maximum size of a batch, which depends on the parent chain, but reference values can be found [here](https://github.com/celestiaorg/orbit-actions/tree/main/scripts/foundry/contract-upgrades/1.2.1/env-templates) for sepolia and arbitrum sepolia.

Once deployed, the execution section of the `.env` can be filled out with the upgrade action address, the proxy admin and upgrade executor for the chain to be migrated, as well as the inbox address for the chain that is being migrated.

### Q: node error: unable to find validator machine directory for the on-chain WASM module root

```
unable to find validator machine directory for the on-chain WASM module root err="stat /home/user/target/machines/0xe81f986823a85105c5fd91bb53b4493d38c0c26652d23f76a7405ac889908287: no such file or directory"
```

A: upgrade to celestia nitro-node v3.2.1+

### Q: error generating node action: wasmroot doesn't match rollup

```
error acting as staker                   err="error advancing stake from node 0 (hash 0x0000000000000000000000000000000000000000000000000000000000000000): error generating node action: wasmroot doesn't match rollup : 0x260f5fa5c3176a856893642e149cf128b5a8de9f828afec8d11184415dd8dc69, valid: [0x8b104a2e80ac6165dc58b9048de12f301d70b02a0ab51396c22b4b4b802a16a4]"
```

A: make sure there is activity on the child chain and a new batch is posted after the upgrade

### Q: intrinsic gas too low when running foundry script

A: try to add -g 1000 to the command
