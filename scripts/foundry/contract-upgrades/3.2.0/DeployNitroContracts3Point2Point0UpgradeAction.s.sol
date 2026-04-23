// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {DeploymentHelpersScript} from "../../helper/DeploymentHelpers.s.sol";
import {
    NitroContracts3Point2Point0UpgradeAction
} from "../../../../contracts/parent-chain/contract-upgrades/NitroContracts3Point2Point0UpgradeAction.sol";
import {MockArbSys} from "../../helper/MockArbSys.sol";

/**
 * @title DeployNitroContracts3Point2Point0UpgradeActionScript
 * @notice Deploys implementation contracts and the NitroContracts3Point2Point0UpgradeAction contract.
 */
contract DeployNitroContracts3Point2Point0UpgradeActionScript is DeploymentHelpersScript {
    function run() public {
        vm.startBroadcast();

        address newAdminLogic = deployBytecodeWithConstructorFromJSON(
            "/node_modules/@arbitrum/nitro-contracts-3.2.0/build/contracts/src/rollup/RollupAdminLogic.sol/RollupAdminLogic.json",
            ""
        );
        address newUserLogic = deployBytecodeWithConstructorFromJSON(
            "/node_modules/@arbitrum/nitro-contracts-3.2.0/build/contracts/src/rollup/RollupUserLogic.sol/RollupUserLogic.json",
            ""
        );

        // Deploy the action contract last. The CLI identifies the deployed action
        // by taking the last CREATE from the broadcast file.
        new NitroContracts3Point2Point0UpgradeAction(newAdminLogic, newUserLogic);

        vm.stopBroadcast();
    }
}
