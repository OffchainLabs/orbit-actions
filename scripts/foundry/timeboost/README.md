# Deploy ExpressLaneAuction contract

This script deploy ExpressLaneAuction contract, the contract can then be configured in the sequencer to enable timeboost.

## How to use it

1. Setup .env according to the example files, make sure you provide correct values.

> [!CAUTION]
> The .env file must be in project root.

`DeployExpressLaneAuction.s.sol` script deploys `ExpressLaneAuction` behind a proxy. It can be executed in this directory like this:

```bash
forge script --sender $DEPLOYER --rpc-url $CHILD_CHAIN_RPC --slow ./DeployExpressLaneAuction.s.sol -vvv --verify --broadcast
# use --account XXX / --private-key XXX / --interactive / --ledger to set the account to send the transaction from
```

The deployer does not need to be the chain owner or have any admin privilege.
 