# Token bridge creator upgrade to 1.2.2

This script is used to deploy new token bridge creator 1.2.2 logic contracts (L1AtomicTokenBridgeCreator and L1TokenBridgeRetryableSender) and execute the upgrade or prepare the payload for the multisig.

## How to use it

1. Script `UpgradeTokenBridgeCreator.s.sol` deploys logic contract and upgrade action contract.

Script can be simulated in this directory like this:

```bash
forge script --sender $DEPLOYER --rpc-url $PARENT_CHAIN_RPC --slow ./UpgradeTokenBridgeCreator.s.sol -vvv
```

And executed:

```bash
forge script --sender $DEPLOYER --rpc-url $PARENT_CHAIN_RPC --slow ./UpgradeTokenBridgeCreator.s.sol -vvv --verify --broadcast
```
