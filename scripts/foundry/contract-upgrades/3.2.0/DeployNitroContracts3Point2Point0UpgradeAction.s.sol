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

        // see scripts/orbit-versioner/referentContractAddresses.json
        // there is only one address shared across all chains
        address newAdminLogic = 0xAb7A44CE7e66963d2116dCe74AB63eeF88266C82;
        address newUserLogic = 0xedC23dFC7D1e57EC07eA5ff7419634DbAe08Ed2C;

        // Deploy the action contract last. The CLI identifies the deployed action
        // by taking the last CREATE from the broadcast file.
        new NitroContracts3Point2Point0UpgradeAction{salt: 0}(newAdminLogic, newUserLogic);

        vm.stopBroadcast();
    }
}
