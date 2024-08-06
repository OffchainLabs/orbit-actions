# Token bridge creator upgrade to 1.2.2

This script is used to deploy new token bridge creator 1.2.2 logic contracts (L1AtomicTokenBridgeCreator and L1TokenBridgeRetryableSender) and the upgrade action.

## How to use it

1. Script `DeployTokenBridgeCreatorUpgradeAction.s.sol` deploys logic contract and upgrade action contract. Calldata to execute the action will be stored in `${root}/scripts/foundry/creator-upgrades1.2.2/output/${chainId}.json`.

Script can be simluated in this directory like this:

```bash
forge script --sender $DEPLOYER --rpc-url $PARENT_CHAIN_RPC --slow ./DeployTokenBridgeCreatorUpgradeAction.s.sol -vvv
```

And executed:

```bash
forge script --sender $DEPLOYER --rpc-url $PARENT_CHAIN_RPC --slow ./DeployTokenBridgeCreatorUpgradeAction.s.sol -vvv --verify --broadcast
```
