# Token bridge creator upgrade to 1.2.2

This script is used to deploy new token bridge creator 1.2.2 logic contracts (L1AtomicTokenBridgeCreator and L1TokenBridgeRetryableSender) and execute the upgrade or prepare the payload for the multisig.

## How to use it

Prepare the .env file according to the templates.

Script can be simulated in this directory like this (note that you may need to create the output directory `mkdir -p output`):

```bash
forge script --sender $DEPLOYER --rpc-url $PARENT_CHAIN_RPC --slow UpgradeTokenBridgeCreatorScript -vvv
```

And executed:

```bash
forge script --sender $DEPLOYER --rpc-url $PARENT_CHAIN_RPC --slow UpgradeTokenBridgeCreatorScript -vvv --verify --broadcast
```
