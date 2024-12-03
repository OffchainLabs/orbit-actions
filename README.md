# Orbit Action Contracts for Celestia DA

A set of contracts that are similar to Arbitrum [gov-action-contracts](https://github.com/ArbitrumFoundation/governance/tree/main/src/gov-action-contracts), but are designed to be used with Orbit chains looking to migrate to Celestia DA

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

## Common upgrade paths

Here is a list of common upgrade paths that can be used to upgrade the Orbit chains to Celestia DA.

### [ArbOS 32 Bianca](https://docs.arbitrum.io/run-arbitrum-node/arbos-releases/arbos32) Migration to Celestia DA 

1. Upgrade your Nitro node(s) to [Nitro v3.1.2](https://github.com/OffchainLabs/nitro/releases/tag/v3.1.2)
2. Upgrade `nitro-contracts` to `celestia-2.1.0` using [nitro-contract 2.1.0 upgrade action](scripts/foundry/contract-upgrades/celestia-2.1.0)
