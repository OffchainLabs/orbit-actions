// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "forge-std/Script.sol";
import {
    NitroContracts3Point2Point0UpgradeAction
} from "../../../../contracts/parent-chain/contract-upgrades/NitroContracts3Point2Point0UpgradeAction.sol";
import {IUpgradeExecutor} from "@offchainlabs/upgrade-executor/src/IUpgradeExecutor.sol";

/**
 * @title ExecuteNitroContracts3Point2Point0UpgradeScript
 * @notice Executes nitro contracts 3.2.0 upgrade through UpgradeExecutor
 */
contract ExecuteNitroContracts3Point2Point0UpgradeScript is Script {
    function run() public {
        NitroContracts3Point2Point0UpgradeAction upgradeAction =
            NitroContracts3Point2Point0UpgradeAction(vm.envAddress("UPGRADE_ACTION_ADDRESS"));

        require(
            address(upgradeAction).code.length > 0,
            "Upgrade action contract not found at provided address, run deployment script first"
        );

        // prepare upgrade calldata
        bytes memory upgradeCalldata =
            abi.encodeCall(NitroContracts3Point2Point0UpgradeAction.perform, (vm.envAddress("ROLLUP_ADDRESS")));

        // execute the upgrade
        IUpgradeExecutor executor = IUpgradeExecutor(vm.envAddress("PARENT_UPGRADE_EXECUTOR_ADDRESS"));
        vm.startBroadcast();
        executor.execute(address(upgradeAction), upgradeCalldata);
        vm.stopBroadcast();
    }
}
