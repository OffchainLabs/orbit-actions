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

**Nitro node**: The minimum node version for this upgrade is Nitro v3.5.4, which introduced compatibility with pre-BoLD and BoLD chains to ensure a smooth upgrade. Nodes will automatically detect whether the chain is running pre-BoLD or BoLD Rollup and Challenge contracts and will perform the appropriate calls depending on that check.

Most of the parameters used in Nitro before v3.5.4 will stay the same when running a higher version but, depending on the type of node, you'll have to include a few more BoLD-specific parameters:
- For validator nodes: add `--node.bold.enable=true` and `--node.bold.strategy=<MakeNodes | ResolveNodes | Defensive>` to configure the validator to create and/or confirm assertions in the new Rollup contract (find more information in [How to run a validator](/run-arbitrum-node/more-types/02-run-validator-node.mdx#step-1-configure-and-run-your-validator))
- For all other types of node: add `--node.bold.enable=true` to enable [watchtower mode](/run-arbitrum-node/03-run-full-node.mdx#watchtower-mode)

## How to use it

1. Clone nitro-contract repo
```
$ git clone https://github.com/OffchainLabs/nitro-contracts.git
$ cd nitro-contracts
```

2. Checkout the v3.1.0 tag
```
$ git checkout v3.1.0
```

3. Install dependencies and build contracts
```
$ yarn install
$ yarn build:all
```

4. Edit `scripts/files/configs/custom.ts`, be very careful as they will override existing configs

5. Setup .env in project root, make sure `CONFIG_NETWORK_NAME=custom`.
```
$ cp .env-sample .env
```

7. Run the prepare script, this will deploy the actions. L1_PRIV_KEY does not need to be the chain owner. Pass in the parent chain for `--network`
```
$ L1_PRIV_KEY=xxx INFURA_KEY=xxx ETHERSCAN_API_KEY=xxx yarn script:bold-prepare --network {mainnet|arb1|base|arbSepolia}
...
Verified contract BOLDUpgradeAction successfully.
Deployed contracts written to: scripts/files/sepoliaDeployedContracts.json
Done.
```

8. Make sure everything is configured correctly. It would be nice to temporarily shutdown all validators.

9. Run the populate lookup script, this will store the last confirmed assertion on-chain for the next step.
```
$ L1_PRIV_KEY=xxx yarn script:bold-populate-lookup
...
Done.
```

10. Run the upgrade script. If the L1_PRIV_KEY is not the chain owner, it will print the upgrade payload. Execute the payload with the chain owner. 

> [!CAUTION]
> This script will not ask for confirmation before sending the transaction!

```
$ L1_PRIV_KEY=xxx yarn script:bold-local-execute
upgrade executor: 0x5FEe78FE9AD96c1d8557C6D6BB22Eb5A61eeD315
execute(...) call to upgrade executor: 0x1cff79cd000000000000000000000000f8199ca3702c09c78b957d4d820311125753c6d2000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a4ebe03a93000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000030000000000000000000000008a8f0a24d7e58a76fc8f77bb68c7c902b91e182e00000000000000000000000087630025e63a30ecf9ca9d580d9d95922fea6af0000000000000000000000000c32b93e581db6ebc50c08ce381143a259b92f1ed00000000000000000000000000000000000000000000000000000000
```

## FAQ
