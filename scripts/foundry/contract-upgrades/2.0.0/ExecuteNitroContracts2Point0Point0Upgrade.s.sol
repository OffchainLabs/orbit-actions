// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "forge-std/Script.sol";
import {
    NitroContracts1Point2Point1UpgradeAction,
    ProxyAdmin
} from "../../../../contracts/parent-chain/contract-upgrades/NitroContracts2Point0Point0UpgradeAction.sol";
import {IBridge} from "@arbitrum/nitro-contracts-2.0.0/src/bridge/IBridge.sol";
import {IRollupCore} from "@arbitrum/nitro-contracts-2.0.0/src/rollup/IRollupCore.sol";
import {IUpgradeExecutor} from "@offchainlabs/upgrade-executor/src/IUpgradeExecutor.sol";

/**
 * @title ExecuteNitroContracts1Point2Point1UpgradeScript
 * @notice This script executes nitro contracts 2.0.0 upgrade through UpgradeExecutor
 */
contract ExecuteNitroContracts2Point0Point0UpgradeScript is Script {
    function run() public {
        // used to check upgrade was successful
        bytes32 wasmModuleRoot = vm.envBytes32("WASM_MODULE_ROOT");

        vm.startBroadcast();

        // prepare upgrade calldata
        ProxyAdmin proxyAdmin = ProxyAdmin(vm.envAddress("ROLLUP_ADDRESS"));
        IRollupCore rollup = IRollupCore(vm.envAddress("PROXY_ADMIN_ADDRESS"));
        bytes memory upgradeCalldata =
            abi.encodeCall(NitroContracts1Point2Point1UpgradeAction.perform, (rollup, proxyAdmin));

        // execute the upgrade
        IUpgradeExecutor executor = IUpgradeExecutor(vm.envAddress("PARENT_UPGRADE_EXECUTOR_ADDRESS"));
        executor.execute(address(upgradeAction), upgradeCalldata);

        // sanity check, full checks are done on-chain by the upgrade action
        require(rollup.wasmModuleRoot() == upgradeAction.newWasmModuleRoot(), "Wasm module root not set");

        vm.stopBroadcast();
    }
}
