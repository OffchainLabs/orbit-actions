// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "forge-std/Script.sol";
import {OneStepProver0} from "@arbitrum/nitro-contracts/src/osp/OneStepProver0.sol";
import {OneStepProverMemory} from "@arbitrum/nitro-contracts/src/osp/OneStepProverMemory.sol";
import {OneStepProverMath} from "@arbitrum/nitro-contracts/src/osp/OneStepProverMath.sol";
import {OneStepProverHostIo} from "@arbitrum/nitro-contracts/src/osp/OneStepProverHostIo.sol";
import {OneStepProofEntry} from "@arbitrum/nitro-contracts/src/osp/OneStepProofEntry.sol";
import {ChallengeManager} from "@arbitrum/nitro-contracts/src/challenge/ChallengeManager.sol";

/**
 * @title DeployScript
 * @notice This script deploys OSPs and ChallengeManager templates,
 */
contract DeployOspAndChallengeManagerScript is Script {
    function run() public {
        vm.startBroadcast();

        // deploy OSP templates
        OneStepProver0 osp0 = new OneStepProver0();
        OneStepProverMemory ospMemory = new OneStepProverMemory();
        OneStepProverMath ospMath = new OneStepProverMath();
        OneStepProverHostIo ospHostIo = new OneStepProverHostIo();
        new OneStepProofEntry(osp0, ospMemory, ospMath, ospHostIo);

        // deploy new challenge manager templates
        new ChallengeManager();

        vm.stopBroadcast();
    }
}
