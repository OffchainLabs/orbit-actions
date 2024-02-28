// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "forge-std/Script.sol";
import {
    NitroContracts1Point2Point1Upgrade,
    ProxyAdmin
} from "../../../../contracts/upgrade/NitroContracts1Point2Point1Upgrade.sol";
import {IRollupCore} from "@arbitrum/nitro-contracts/src/rollup/IRollupCore.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {IUpgradeExecutor, UpgradeExecutor} from "@offchainlabs/upgrade-executor/src/UpgradeExecutor.sol";

/**
 * @title DeployScript
 * @notice This script executes nitro contracts 1.2.1 upgrade through UpgradeExecutor
 */
contract DeployScript is Script {
    function run() public {
        vm.startBroadcast();

        // prepare upgrade calldata
        NitroContracts1Point2Point1Upgrade upgradeAction =
            NitroContracts1Point2Point1Upgrade(vm.envAddress("UPGRADE_ACTION_ADDRESS"));
        IRollupCore rollup = IRollupCore(vm.envAddress("ROLLUP_ADDRESS"));
        ProxyAdmin proxyAdmin = ProxyAdmin(vm.envAddress("PROXY_ADMIN_ADDRESS"));
        bytes memory upgradeCalldata = abi.encodeCall(NitroContracts1Point2Point1Upgrade.perform, (rollup, proxyAdmin));

        // execute the upgrade
        UpgradeExecutor executor = UpgradeExecutor(vm.envAddress("UPGRADE_EXECUTOR_ADDRESS"));

        console.log(address(executor));

        executor.execute(address(upgradeAction), upgradeCalldata);

        // sanity check, full checks are done on-chain by the upgrade action
        require(rollup.wasmModuleRoot() == upgradeAction.newWasmModuleRoot(), "ArbOS20Action: wasm module root not set");

        vm.stopBroadcast();
    }
}
