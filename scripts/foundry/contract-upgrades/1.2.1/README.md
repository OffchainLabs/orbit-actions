# Nitro contracts 1.2.1 upgrade
These scripts empower `NitroContracts1Point2Point1UpgradeAction` action contract which performs upgrade to [1.2.1 release](https://github.com/OffchainLabs/nitro-contracts/releases/tag/v1.2.1) of Nitro contracts for existing Orbit chains. This upgrade only support upgrading from nitro-contract 1.1.0 or 1.1.1 and does NOT support other versions inclduing their beta versions. Predeployed instances of the upgrade action exists on the chains listed in the following section with vanilla ArbOS20 wasm module root set. If you have a custom nitro machine, you will need to deploy the upgrade action yourself.

## Deployed instances

- L1 Sepolia (eth fee token): 0xA1e33965C46cD063CbfCBdC070400de22f5E61F8
- L1 Sepolia (custom fee token): 0xED92b6A5483fe3825039B6420CB5B9C5471b9404
- L2 ArbSepolia (eth fee token): 0xBBB59089Dac167C158eBC82326D70792E7855fEE
- L2 ArbSepolia (custom fee token): 0xD37cBD59DF38010B9fB75deC9c9178829147b248

## How to use it

1. Setup .env according to the example files, make sure you have everything correctly defined. The script do some sanity checks but not everything can be checked.

2. (Skip this step if you can use the deployed instances of action contract) 
`Deployer.s.sol` script deploys OSPs and ChallengeManager templates, blob reader and SequencerInbox template, and finally the upgrade action itself. It can be executed in this directory like this:
```bash
forge script --sender $DEPLOYER --rpc-url $PARENT_CHAIN_RPC --broadcast --slow ./Deployer.s.sol -vvv --verify --skip-simulation
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