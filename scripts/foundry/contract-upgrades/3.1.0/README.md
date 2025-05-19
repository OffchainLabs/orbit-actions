# Nitro contracts 3.1.0 upgrade

To upgrade to Nitro contracts 3.1.0 (BoLD), you will need to use the [BOLDUpgradeAction](https://github.com/OffchainLabs/nitro-contracts/blob/main/src/rollup/BOLDUpgradeAction.sol) from the [nitro-contract](https://github.com/OffchainLabs/nitro-contracts) repo. 

BOLDUpgradeAction will perform the following actions:

1. Upgrade bridge, inbox, rollupEventInbox, outbox, sequencerInbox to v3.1.0
2. Deploy new v3.1.0 BoLD challenge manager
3. Migrate v2 rollup into a new v3.1.0 rollup address
4. Setup the rollup according to the new config and use the latest confirmed assertion on the old rollup as genesis of the new rollup

Note that contracts without code changes are not upgraded. It is normal to have some contracts still in the old version after the upgrade as they are equivalent to the new version. There are no associated ArbOS upgrade for this version.

## Requirements

**Nitro contracts**: This upgrade only support upgrading from the following [nitro-contract release](https://github.com/OffchainLabs/nitro-contracts/releases); please refer to the top [README](../../README.md) `Check Version and Upgrade Path` on how to determine your current nitro contracts version:

- Inbox: v1.1.0 - v2.1.3 inclusive
- Outbox: any
- SequencerInbox: v1.2.1 - v2.1.3 inclusive
- Bridge
  - eth chain: v1.1.0 - v2.1.3 inclusive
  - custom-fee token chain: v2.0.0 - v2.1.3 inclusive
- RollupProxy: v1.1.0 - v2.1.3 inclusive
- RollupAdminLogic: v2.0.0 - v2.1.3 inclusive
- RollupUserLogic: v2.0.0 - v2.1.3 inclusive
- ChallengeManager: v2.0.0 - v2.1.3 inclusive

Please refer to the top [README](/README.md#check-version-and-upgrade-path) `Check Version and Upgrade Path` on how to determine your current nitro contracts version.

**Nitro node**: The minimum node version for this upgrade is Nitro v3.5.4, which introduced compatibility with pre-BoLD and BoLD chains to ensure a smooth upgrade. Nodes will automatically detect whether the chain is running pre-BoLD or BoLD Rollup and Challenge contracts and will perform the appropriate calls depending on that check.

Most of the parameters used in Nitro before v3.5.4 will stay the same when running a higher version but, depending on the type of node, you'll have to include a few more BoLD-specific parameters:

- For validator nodes: add `--node.bold.enable=true` and `--node.bold.strategy=<MakeNodes | ResolveNodes | Defensive>` to configure the validator to create and/or confirm assertions in the new Rollup contract (find more information in [How to run a validator](https://docs.arbitrum.io/run-arbitrum-node/more-types/run-validator-node#step-1-configure-and-run-your-validator))
- For all other types of node before v3.6.0: add `--node.bold.enable=true` to enable [watchtower mode](https://docs.arbitrum.io/run-arbitrum-node/run-full-node#watchtower-mode)
- For all other types of node after Nitro v3.6.0: [watchtower mode](https://docs.arbitrum.io/run-arbitrum-node/run-full-node#watchtower-mode) is automatically enabled

Additionally, after performing the upgrade, the `--chain.info-json` object also needs to be modified:

- Update the new rollup address in the `rollup.rollup` field
- Add the stake token in a new `rollup.stake-token` field

## How to use it

1. Clone nitro-contract repo

```
$ git clone https://github.com/OffchainLabs/nitro-contracts.git
$ cd nitro-contracts
```

2. Checkout the v3.1.0-qol tag

```
$ git checkout v3.1.0-qol
```

3. Install dependencies and build contracts

```
$ yarn install
$ yarn build:all
```

4. Edit `scripts/files/configs/custom.ts`, be very careful as they will override the existing configuration of your chain.

5. Setup .env in project root, make sure `CONFIG_NETWORK_NAME=custom`.

```
$ cp .env-sample .env
```

6. Run the prepare script, this will deploy the action with the specified configuration parameters. Note that `L1_PRIV_KEY` does not need to be the chain owner. Pass in the parent chain for `--network`; you can find the identifiers of these networks in the `hardhat.config.ts` file. Note that if your parent chain is an L1, you'll have to configure an additional `INFURA_KEY` env variable for its endpoint.
    - Optionally, the script can try to verify the deployed contract by setting `DISABLE_VERIFICATION` to `false`. In that case, use the correct key for verifying the contracts on the block explorer depending on your parent chain: `ETHERSCAN_API_KEY | ARBISCAN_API_KEY | NOVA_ARBISCAN_API_KEY | BASESCAN_API_KEY`

```
$ L1_PRIV_KEY=xxx yarn script:bold-prepare --network {mainnet|arb1|base|arbSepolia}
...
Verified contract BOLDUpgradeAction successfully.
Deployed contracts written to: scripts/files/sepoliaDeployedContracts.json
Done.
```

7. Make sure everything is configured correctly. It's recommended to stop all validators at this point to prevent them from confirming new assertions that might block the upgrade in the next step.

8. Run the populate lookup script, this will store the last confirmed assertion on-chain for the next step. Note that this script looks for the `NodeCreated` event of the last confirmed assertion in the last 100,000 blocks. If the `NodeCreated` event was emitted in an older block, it won't be able to find it.

```
$ L1_PRIV_KEY=xxx yarn script:bold-populate-lookup --network {mainnet|arb1|base|arbSepolia}
...
Done.
```

9. Run the upgrade script. If the `L1_PRIV_KEY` is not the chain owner, it will print the upgrade payload. Execute the payload with the chain owner. 

> [!CAUTION]
> This script will not ask for confirmation before sending the transaction!

```
$ L1_PRIV_KEY=xxx yarn script:bold-local-execute --network {mainnet|arb1|base|arbSepolia}
upgrade executor: 0x5FEe78FE9AD96c1d8557C6D6BB22Eb5A61eeD315
execute(...) call to upgrade executor: 0x1cff79cd000000000000000000000000f8199ca3702c09c78b957d4d820311125753c6d2000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a4ebe03a93000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000030000000000000000000000008a8f0a24d7e58a76fc8f77bb68c7c902b91e182e00000000000000000000000087630025e63a30ecf9ca9d580d9d95922fea6af0000000000000000000000000c32b93e581db6ebc50c08ce381143a259b92f1ed00000000000000000000000000000000000000000000000000000000
```

10. Update your nodes configuration and restart them:

  - For validator nodes: add `--node.bold.enable=true` and `--node.bold.strategy=<MakeNodes | ResolveNodes | Defensive>` to configure the validator to create and/or confirm assertions in the new Rollup contract (find more information in [How to run a validator](https://docs.arbitrum.io/run-arbitrum-node/more-types/run-validator-node#step-1-configure-and-run-your-validator))
  - For all other types of node before v3.6.0: add `--node.bold.enable=true` to enable [watchtower mode](https://docs.arbitrum.io/run-arbitrum-node/run-full-node#watchtower-mode)
  - For all other types of node after Nitro v3.6.0: [watchtower mode](https://docs.arbitrum.io/run-arbitrum-node/run-full-node#watchtower-mode) is automatically enabled

Additionally, after performing the upgrade, the `--chain.info-json` object also needs to be modified:

  - Update the new rollup address in the `rollup.rollup` field
  - Add the stake token in a new `rollup.stake-token` field

11. Once the upgrade executes, monitor assertions to ensure they are created and confirmed in the new Rollup contract. Note that the new events emitted are `AssertionCreated` (which should appear every time an assertion is posted, by default this is 1 hour) and `AssertionConfirmed` (which should only appear after a challenge period has elapsed, by default this is 7 days).

## FAQ

### Node shuts down when enabling BoLD right after the upgrade

When enabling BoLD on a validator, it will default to read only finalized information from its parent chain. If you run your node before the blocks that contain the upgrade transactions are finalized, the node will stop with the following message:

```shell
error initializing staker: could not create assertion chain: no contract code at given address
```

In this case, wait until those blocks are finalized and start your node again.
