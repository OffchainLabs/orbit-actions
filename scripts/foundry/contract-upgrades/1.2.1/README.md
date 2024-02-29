# Nitro contracts 1.2.1 upgrade
These scripts empower `NitroContracts1Point2Point1UpgradeAction` action contract which performs upgrade to [1.2.1 release](https://github.com/OffchainLabs/nitro-contracts/releases/tag/v1.2.1) of Nitro contracts for existing Orbit chains. This upgrade only support upgrading from nitro-contract 1.1.0 or 1.1.1 and does NOT support other versions inclduing their beta versions. Predeployed instances of the upgrade action exists on the chains listed in the following section with vanilla ArbOS20 wasm module root set. If you have a custom nitro machine, you will need to deploy the upgrade action yourself.

## Deployed instances

- L1 Sepolia: 0xA1e33965C46cD063CbfCBdC070400de22f5E61F8

## How to use it

1. Setup .env according to the example files, make sure you have the correct wasm module root defined

2. (Skip this step if you can use the deployed instances of action contract) 
`Deployer.s.sol` script deploys OSPs and ChallengeManager templates, blob reader and SequencerInbox template, and finally the upgrade action itself. Currently it is NOT applicable for chains which are hosted on Arbitrum chains. It can be executed in this directory like this:
```bash
forge script --sender $DEPLOYER --rpc-url $PARENT_CHAIN_RPC --broadcast --slow ./Deployer.s.sol -vvv --verify
```
As a result, all templates and upgrade action are deployed. Note the last deployed address - that's the upgrade action.

3. `ExecuteUpgrade.s.sol` script uses previously deployed upgrade action to execute the upgrade. It makes following assumptions - L1UpgradeExecutor is the rollup owner, and there is an EOA which has executor rights on the L1UpgradeExecutor. Proceed with upgrade using the owner account (the one with executor rights on L1UpgradeExecutor):
```bash
forge script --sender $EXECUTOR --rpc-url $PARENT_CHAIN_RPC --broadcast ./ExecuteUpgrade.s.sol -vvv
```
If you have a multisig as executor, you can still run the above command without broadcasting to get the payload for the multisig transaction.

4. That's it, upgrade has been performed. You can make sure it has successfully executed by checking wasm module root:
```bash
cast call --rpc-url $PARENT_CHAIN_RPC $ROLLUP "wasmModuleRoot()"
```