// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "forge-std/Script.sol";
import {
    NitroContractsEigenDA2Point1Point0UpgradeAction,
    ProxyAdmin
} from "../../../../contracts/parent-chain/contract-upgrades/NitroContractsEigenDA2Point1Point0UpgradeAction.sol";
import {IBridge} from "@eigenda/nitro-contracts-2.1.0/src/bridge/IBridge.sol";
import {IRollupCore} from "@eigenda/nitro-contracts-2.1.0/src/rollup/IRollupCore.sol";
import {IUpgradeExecutor} from "@offchainlabs/upgrade-executor/src/IUpgradeExecutor.sol";
import {IInboxBase} from "@arbitrum/nitro-contracts-1.2.1/src/bridge/IInboxBase.sol";
import {console} from "forge-std/console.sol";

/**
 * @title ExecuteNitroContractsEigenDA2Point1Point0UpgradeActionScript
 * @notice This script executes nitro contracts 2.1.0 upgrade through UpgradeExecutor
 */
contract ExecuteNitroContractsEigenDA2Point1Point0UpgradeScript is Script {

    function run() public {
        // used to check if upgrade was successful
        bytes32 wasmModuleRoot = vm.envBytes32("TARGET_WASM_MODULE_ROOT");
        address zeroAdress = address(0);
        
        NitroContractsEigenDA2Point1Point0UpgradeAction upgradeAction =
            NitroContractsEigenDA2Point1Point0UpgradeAction(vm.envAddress("UPGRADE_ACTION_ADDRESS"));

        IInboxBase inbox = IInboxBase(vm.envAddress("INBOX_ADDRESS"));
        IRollupCore rollup = IRollupCore(address(inbox.bridge().rollup()));

        // check prerequisites
        require(rollup.wasmModuleRoot() == upgradeAction.condRoot(), "Incorrect starting wasm module root");

        vm.startBroadcast();

        // prepare upgrade calldata
        ProxyAdmin proxyAdmin = ProxyAdmin(vm.envAddress("PROXY_ADMIN_ADDRESS"));
        bytes memory upgradeCalldata =
            abi.encodeCall(NitroContractsEigenDA2Point1Point0UpgradeAction.execute, (rollup, proxyAdmin));
        console.log("Loaded proxy admin", address(proxyAdmin));


        // execute the upgrade
        IUpgradeExecutor executor = IUpgradeExecutor(vm.envAddress("PARENT_UPGRADE_EXECUTOR_ADDRESS"));
        console.log("executing upgrade", address(executor));

        executor.execute(address(upgradeAction), upgradeCalldata);

        // sanity check, full checks are done on-chain by the upgrade action
        require(rollup.wasmModuleRoot() == upgradeAction.wasmModuleRoot(), "Wasm module root not set");
        require(rollup.wasmModuleRoot() == wasmModuleRoot, "Unexpected wasm module root set");

        vm.stopBroadcast();
    }
}
