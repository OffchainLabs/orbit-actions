// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "forge-std/Script.sol";
import {AddWasmCacheManagerAction} from "../../../../contracts/child-chain/sty;us/AddWasmCacheManagerAction.sol";

/**
 * @title DeployAddWasmCacheManagerActionScript
 * @notice This script deploys action that's used to add pre-deployed wasm cache manager on a child chain.
 */
contract DeployAddWasmCacheManagerActionScript is Script {
    // https://github.com/OffchainLabs/nitro/releases/tag/consensus-v31
    uint256 public constant TARGET_ARBOS_VERSION = 31;

    function run() public {
        vm.startBroadcast();

        // deploy action
        new AddWasmCacheManagerAction({
            _wasmCachemanager: vm.envUint("WASM_CACHE_MANAGER_ADDRESS"),
            _targetArbOSVersion: TARGET_ARBOS_VERSION,
        });

        vm.stopBroadcast();
    }
}
