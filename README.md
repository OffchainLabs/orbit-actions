# Orbit Action Contracts

A set of contracts that are similar to Arbitrum [gov-action-contracts](https://github.com/ArbitrumFoundation/governance/tree/main/src/gov-action-contracts), but are designed to be used with the Orbit chains.

## Requirments

[yarn](https://classic.yarnpkg.com/lang/en/docs/install/) and [foundry](https://book.getfoundry.sh/getting-started/installation) are required to run the scripts

Most of the action contracts only support the following ownership setup:

- Rollup Contract on Parent Chain owned by a `ParentUpgradeExecutor`
- Rollup ProxyAdmin on Parent Chain owned by a `ParentUpgradeExecutor`
- Arb Owner on the Child Orbit Chain is granted to alias of `ParentUpgradeExecutor`
- Arb Owner on the Child Orbit Chain is granted to `ChildUpgradeExecutor`

For token bridge related operations, these are the additional requirements:

- Token Bridge ProxyAdmin on Parent Chain owned by `ParentUpgradeExecutor`
- Token Bridge ProxyAdmin on Child Orbit Chain owned by `ChildUpgradeExecutor`
- Parent Chain Gateway Router and Custom Gateway owned by `ParentUpgradeExecutor`

## Setup

```
yarn install
```

## Check Version and Upgrade Path

Run the follow command to check the version of Nitro contracts deployed on the parent chain of your Orbit chain.

```
$ INBOX_ADDRESS=0xaE21fDA3de92dE2FDAF606233b2863782Ba046F9 yarn orbit:contracts:version --network arb1
Get the version of Orbit chain's nitro contracts (inbox 0xaE21fDA3de92dE2FDAF606233b2863782Ba046F9), hosted on chain 42161
Version of deployed Inbox: v1.1.1
Version of deployed Outbox: v1.1.1
Version of deployed SequencerInbox: v1.1.1
Version of deployed Bridge: v1.1.1
Version of deployed RollupProxy: v1.1.1
Version of deployed RollupAdminLogic: v1.1.1
Version of deployed RollupUserLogic: v1.1.1
This deployment can be upgraded to v1.2.1 using NitroContracts1Point2Point1UpgradeAction
```

For other networks, replace `arb1` with the network name and configure INFURA_KEY or the rpc in hardhat.config.ts

## Nitro Contracts Upgrades

_This section is also referenced in the documentation on ["How to upgrade ArbOS on your Orbit chain"](https://docs.arbitrum.io/launch-orbit-chain/how-tos/arbos-upgrade)_

For ArbOS upgrades, a pre-requisite is to deploy new Nitro contracts to the parent chain of your Orbit chain before scheduling the ArbOS upgrade. These contracts include the rollup logic, fraud proof contracts, and interfaces for interacting with Nitro precompiles.

### Nitro contracts 2.1.0

The [`nitro-contracts 2.1.0` upgrade action](scripts/foundry/contract-upgrades/2.1.0) will deploy `nitro-contracts v2.1.0` contracts to your Orbit's parent chain. Note that this action will only work for chains with `nitro-contracts v1.2.1` or `nitro-contracts v1.3.0`.

Note: nitro contracts upgrade brings support for AnyTrust fast confirmations and Stylus. However, Stylus will be enabled only when `ArbOS 31 Bianca` upgrade takes place, once it will be officially supported for Orbit chains.

### Nitro contracts 1.2.1 (for ArbOS 20 Atlas)

The [`nitro-contracts 1.2.1` upgrade action](scripts/foundry/contract-upgrades/1.2.1) will deploy `nitro-contracts v1.2.1` contracts to your Orbit's parent chain. Note that this action will only work for chains with `nitro-contracts v1.1.0` or `nitro-contracts v.1.1.1`. ArbOS 20 Atlas, shipped via [Nitro v2.3.0](https://github.com/OffchainLabs/nitro/releases/tag/v2.3.0), requires [**`nitro-contracts v1.2.1`**](https://github.com/OffchainLabs/nitro-contracts/releases/tag/v1.2.1) or higher.

## Scheduling the ArbOS upgrade

_This section is also referenced in the documentation on ["How to upgrade ArbOS on your Orbit chain"](https://docs.arbitrum.io/launch-orbit-chain/how-tos/arbos-upgrade)_

Next, you will need to schedule the actual upgrade using the [ArbOS upgrade at timestamp action](scripts/foundry/arbos-upgrades/at-timestamp).

This action schedule an upgrade of the ArbOS to a specific version at a specific timestamp.

## Common upgrade paths

Here is a list of common upgrade paths that can be used to upgrade the Orbit chains.

### ArbOS 31 Bianca

1. TBD

### ArbOS 20 Atlas

1. Upgrade your Nitro node(s) to [Nitro v2.3.1](https://github.com/OffchainLabs/nitro/releases/tag/v2.3.1)
1. Upgrade `nitro-contracts` to `v1.2.1` using [nitro-contract 1.2.1 upgrade action](scripts/foundry/contract-upgrades/1.2.1)
1. Schedule the ArbOS 20 Atlas upgrade using [ArbOS upgrade at timestamp action](scripts/foundry/arbos-upgrades/at-timestamp)

# Other Actions

## Enable Fast Confirmation

See [EnableFastConfirmAction](scripts/foundry/fast-confirm)

## Enable Stylus Cache Manager

See [setCacheManager](scripts/foundry/stylus/setCacheManager]
