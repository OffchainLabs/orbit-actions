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

1. Upgrade your Nitro node(s) to [Celestia Nitro v3.2.1](https://github.com/celestiaorg/nitro/releases/tag/v3.2.1-rc.2)
2. Upgrade `nitro-contracts` to `celestia-2.1.0` using [nitro-contract celestia-2.1.0 upgrade action](scripts/foundry/contract-upgrades/celestia-2.1.0)

### Nitro Contracts 2.1.3

There are two paths for 2.1.3 with Celestia DA:
- Migrating a chain to use Celestia DA from upstream 2.1.0 or 2.1.2 and 2.1.3 orbit-actions
- Upgrading a chain already on Celestia DA (from 2.1.0 and 2.1.2)

For migrations, please refer to [CelestiaNitroContracts2Point1Point3UpgradeAction.s.sol](https://github.com/celestiaorg/orbit-actions/blob/main/scripts/foundry/contract-upgrades/celestia-2.1.3/DeployCelestiaNitroContracts2Point1Point3UpgradeAction.s.sol) deployment.

For upgrading a chain already on Celestia DA, refer to [this deployment script](https://github.com/celestiaorg/orbit-actions/blob/main/scripts/foundry/contract-upgrades/celestia-2.1.3/DeployNitroContracts2Point1Point3UpgradeActionCelestia.s.sol), which can then be executed with the upstream 2.1.3 execute script.

Note that for either path, you can upgrade to 2.1.2 using the canonical upgrade action, followed by the corresponding celestia action.
