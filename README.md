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

### Nitro-Contract Upgrades
- [nitro-contract 1.2.1 upgrade action](scripts/foundry/contract-upgrades/1.2.1)
   
   This action upgrade the nitro-contract to version 1.2.1 from 1.1.0 or 1.1.1. This is a pre-requisite to ArbOS20.

### ArbOS Upgrades
- [ArbOS upgrade at timestamp action](scripts/foundry/arbos-upgrades/at-timestamp)

   This action schedule an upgrade of the ArbOS to a specific version at a specific timestamp.

## Common upgrade path
Here is a list of common upgrade paths that can be used to upgrade the Orbit chains.

### Nitro-Contract 1.2.1 with ArbOS 20
1. Upgrade nitro-contract to 1.2.1 using [nitro-contract 1.2.1 upgrade action](scripts/foundry/contract-upgrades/1.2.1)
2. Schedule ArbOS 20 upgrade using [ArbOS upgrade at timestamp action](scripts/foundry/arbos-upgrades/at-timestamp)
3. Make sure your all your node operators are ready to upgrade nitro-node ^2.3.0 before the scheudled upgrade time
