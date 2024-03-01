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

## Actions
*This section is also referenced in the documentation on ["How to upgrade ArbOS on your Orbit chain"](https://docs.arbitrum.io/launch-orbit-chain/how-tos/arbos-upgrade)*

### Nitro Contracts Upgrades
For ArbOS upgrades, a pre-requisite is to deploy new Nitro contracts to the parent chain of your Orbit chain before scheduling the ArbOS upgrade. These contracts include the rollup logic, fraud proof contracts, and interfaces for interacting with Nitro precompiles. 

The [`nitro-contracts 1.2.1` upgrade action](scripts/foundry/contract-upgrades/1.2.1) will deploy `nitro-contracts v1.2.1` contracts to your Orbit's parent chain. Note that this action will only work for chains with `nitro-contracts v1.1.0` or `nitro-contracts v.1.1.1`. ArbOS 20 Atlas, shipped via [Nitro v2.3.0](https://github.com/OffchainLabs/nitro/releases/tag/v2.3.0), requires [**`nitro-contracts v1.2.1`**](https://github.com/OffchainLabs/nitro-contracts/releases/tag/v1.2.1) or higher.

### Scheduling the ArbOS upgrade
Next, you will need to schedule the actual upgrade using the [ArbOS upgrade at timestamp action](scripts/foundry/arbos-upgrades/at-timestamp). 

This action schedule an upgrade of the ArbOS to a specific version at a specific timestamp.

## Common upgrade path
Here is a list of common upgrade paths that can be used to upgrade the Orbit chains.

### Nitro-Contract 1.2.1 with ArbOS 20
1. Upgrade your Nitro node(s) to [Nitro v2.3.0](https://github.com/OffchainLabs/nitro/releases/tag/v2.3.0)
1. Upgrade `nitro-contracts` to `v1.2.1` using [nitro-contract 1.2.1 upgrade action](scripts/foundry/contract-upgrades/1.2.1)
2. Schedule the ArbOS 20 Atlas upgrade using [ArbOS upgrade at timestamp action](scripts/foundry/arbos-upgrades/at-timestamp)
