# Enable Fast Confirmation
These scripts empower `EnableFastConfirmAction` contract which enable fast confirmation for existing AnyTrust chains.

This action performs the following steps:

1. Validate fast confirmation has not been enabled yet
1. Create a Safe contract for the fast confirmation committee
1. Set the Safe contract as the fast confirmer on the rollup
1. Set the Safe contract as a validator on the rollup
1. Set setMinimumAssertionPeriod to 1 block to allow more frequent assertion

The fast confirmation committee should align with the DAS committee to maintain the trust model of the chain. All members of the fast confirmation committee must be validators, the Safe contract would initially be deployed as a N-of-N multisig regardless of the AnyTrust threshold.

## Requirements

This upgrade only support upgrading from the following [nitro-contract release](https://github.com/OffchainLabs/nitro-contracts/releases):

- RollupAdminLogic: v2.1.0 or higher
- RollupUserLogic: v2.1.0 or higher

Please refer to the top [README](../../README.md) `Check Version and Upgrade Path` on how to determine your current nitro contracts version.

## Deployed instances

- L1 mainnet: 
- L2 Arb1: 
- L1 Sepolia: 
- L2 ArbSepolia: 0xf7aA2f6B1163142Cb886a0C392D59DD5f1c4F8a2

## How to use it
1. Setup .env according to the example files, make sure your fast confirm committee is secure (it should match your DAS committee). See the previous section for predeployed instances of the action contract. If you need to deploy the action contract yourself, follow the steps below.

`DeployEnableFastConfirmAction.s.s.sol` script deploys `EnableFastConfirmAction` contract. It can be executed in this directory like this:
```bash
forge script --sender $DEPLOYER --rpc-url $PARENT_CHAIN_RPC --broadcast --slow ./DeployEnableFastConfirmAction.s.sol -vvv --verify
# use --account XXX / --private-key XXX / --interactive / --ledger to set the account to send the transaction from
```
This would deploy the EnableFastConfirmAction. Update your .env file with the address of the upgrade action.

2. Next step is to execute the action. Upgrade can be executed using `cast` CLI command (part of Foundry installation), using the owner account (the one with executor rights on parent chain UpgradeExecutor) to send the transaction:
```bash
(export $(cat .env | xargs) && cast send $PARENT_UPGRADE_EXECUTOR_ADDRESS "execute(address, bytes)" $UPGRADE_ACTION_ADDRESS $(cast calldata "perform(address, address[])" $ROLLUP \[$FAST_CONFIRM_COMMITTEE\]) --rpc-url $PARENT_CHAIN_RPC --account EXECUTOR)
# use --account XXX / --private-key XXX / --interactive / --ledger to set the account to send the transaction from
```

If you have a multisig as executor, you will can use the following command to create the payload for calling into the PARENT_UPGRADE_EXECUTOR:
```bash
(export $(cat .env | xargs) && cast calldata "execute(address, bytes)" $UPGRADE_ACTION_ADDRESS $(cast calldata "perform(address, address[])" $ROLLUP \[$FAST_CONFIRM_COMMITTEE\]))
```

3. That's it, the Fast Confirmation has been enabled. Make sure all the committee members are enabling fast confirmation on their nodes and the AnyTrust chain will start using fast confirmation.
