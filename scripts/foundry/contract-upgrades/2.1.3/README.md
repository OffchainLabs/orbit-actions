# Nitro contracts 2.1.3 upgrade

> [!CAUTION]
> This is a patch version and is only necessary for chains that aren't ready for v3.1.0 whose parent chains are upgrading to include EIP7702.
>
> v3.1.0 is also compatible with an EIP7702 enabled parent chain.

These scripts deploy and execute the `NitroContracts2Point1Point3UpgradeAction` contract which allows Orbit chains to upgrade to [2.1.3 release](https://github.com/OffchainLabs/nitro-contracts/releases/tag/v2.1.3). Predeployed instances of the upgrade action exist on the chains listed in the following section.

Upgrading to `v2.1.3` not required nor recommended if the chain aims to upgrade to v3.1.0 before the parent chain gets EIP7702.

You may need to perform the `v2.1.2` upgrade first if your chain uses a custom gas token and was originally deployed before `v2.0.0`. Please refer to the top [README](/README.md#check-version-and-upgrade-path) `Check Version and Upgrade Path` on how to determine your current nitro contracts version.

`NitroContracts2Point1Point3UpgradeAction` will perform the following action:

1. Upgrade the `Inbox` or `ERC20Inbox` contract to `v2.1.3`
1. Upgrade the `SequencerInbox` contract to `v2.1.3`

## Requirements

This upgrade only support upgrading from the following [nitro-contract release](https://github.com/OffchainLabs/nitro-contracts/releases):

- Inbox: v1.1.0 - v2.1.0 inclusive
- Outbox: v1.1.0 - v2.1.0 inclusive
- SequencerInbox: v1.2.1 - v2.1.0 inclusive
- Bridge: v1.1.0 - v2.1.0 inclusive (note this is not ERC20Bridge)
- ERC20Bridge: v2.0.0 - v2.1.2 inclusive
- RollupProxy: v1.1.0 - v2.1.0 inclusive
- RollupAdminLogic: v2.0.0 - v2.1.0 inclusive
- RollupUserLogic: v2.0.0 - v2.1.0 inclusive
- ChallengeManager: v2.0.0 - v2.1.0 inclusive

Please refer to the top [README](/README.md#check-version-and-upgrade-path) `Check Version and Upgrade Path` on how to determine your current nitro contracts version.

## Deployed instances

### Mainnets
- L1 Mainnet: 0x9128ef6A57B2653CF78e650Dd97d0931dCaf79A2
- L2 Arb1: 0xA350fE71079Aa86d48a8f2fDc600bbc6fa9CFE70
- L2 Nova: 0x89611a8feff5a6376ea41265a05243FFBA225a59
- L2 Base: 0x934a1e5187A5011AcECBACACF7cf6B22abE599A5

### Testnets
- L1 Sepolia: 0x82129aB330619388f46d3Cad387aEecb3843A16f
- L1 Holesky: 0x29D1bA37B3A7CC49990e1F613fdF9B33f9Cb3cEE.
- L2 ArbSepolia: 0x0E0Ee28333798F9aF0E76653beabC72F7477C287.
- L2 BaseSepolia: 0x5F6e79237387b01208FDf3a93efd455a2CADBa32.

## How to use it

1. Setup .env according to the example files, make sure you have everything correctly defined. The .env file must be in project root for recent foundry versions.

> [!CAUTION]
> The .env file must be in project root.

2. (Skip this step if you can use the deployed instances of action contract)
   `DeployNitroContracts2Point1Point3UpgradeActionScript.s.sol` script deploys templates, and upgrade action itself. It can be executed in this directory like this:

```bash
forge script --sender $DEPLOYER --rpc-url $PARENT_CHAIN_RPC --broadcast --slow DeployNitroContracts2Point1Point3UpgradeActionScript -vvv --verify --skip-simulation
# use --account XXX / --private-key XXX / --interactive / --ledger to set the account to send the transaction from
```

As a result, all templates and upgrade action are deployed. Note the last deployed address - that's the upgrade action.

3. `ExecuteNitroContracts2Point1Point3Upgrade.s.sol` script uses previously deployed upgrade action to execute the upgrade. It makes following assumptions - L1UpgradeExecutor is the rollup owner, and there is an EOA which has executor rights on the L1UpgradeExecutor. Proceed with upgrade using the owner account (the one with executor rights on L1UpgradeExecutor):

```bash
forge script --sender $EXECUTOR --rpc-url $PARENT_CHAIN_RPC --broadcast ExecuteNitroContracts2Point1Point3UpgradeScript -vvv
# use --account XXX / --private-key XXX / --interactive / --ledger to set the account to send the transaction from
```

If you have a multisig as executor, you can still run the above command without broadcasting to get the payload for the multisig transaction.

4. That's it, upgrade has been performed. You can make sure it has successfully executed by checking the native token decimals.

```bash
# should return 18
cast call --rpc-url $PARENT_CHAIN_RPC $BRIDGE "nativeTokenDecimals()(uint8)"
```

## FAQ

### Q: intrinsic gas too low when running foundry script

A: try to add -g 1000 to the command
