// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "forge-std/Script.sol";
import {SetWasmModuleRootAction} from "../../../../contracts/parent-chain/rollup/SetWasmModuleRootAction.sol";

/**
 * @title DeploySetWasmModuleRootActionScript
 * @notice This script deploys SetWasmModuleRootAction
 */
contract DeploySetWasmModuleRootActionScript is Script {
    function run() public {
        bytes32 previousWasmModuleRoot = vm.envBytes32("PREVIOUS_WASM_MODULE_ROOT");
        bytes32 newWasmModuleRoot = vm.envBytes32("NEW_WASM_MODULE_ROOT");

        if (previousWasmModuleRoot == bytes32(0) || newWasmModuleRoot == bytes32(0)) {
            revert("PREVIOUS_WASM_MODULE_ROOT and NEW_WASM_MODULE_ROOT must be set");
        }

        vm.startBroadcast();

        // finally deploy upgrade action
        new SetWasmModuleRootAction({
            _previousWasmModuleRoot: previousWasmModuleRoot,
            _newWasmModuleRoot: newWasmModuleRoot
        });

        vm.stopBroadcast();
    }
}
