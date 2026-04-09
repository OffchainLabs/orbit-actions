// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

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
        bool isArbitrum = vm.envBool("PARENT_CHAIN_IS_ARBITRUM");
        if (isArbitrum) {
            bytes memory mockArbSysCode = address(new MockArbSys()).code;
            vm.etch(address(100), mockArbSysCode);
        }

        vm.startBroadcast();

        // TODO: deploy new implementation contracts

        // Deploy the action contract last. The CLI identifies the deployed action
        // by taking the last CREATE from the broadcast file.
        new NitroContracts3Point2Point0UpgradeAction();

        vm.stopBroadcast();
    }
}
