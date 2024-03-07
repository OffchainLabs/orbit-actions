// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {DeploymentHelpersScript} from "../../helper/DeploymentHelpers.s.sol";
import {ArbitrumChecker} from "@arbitrum/nitro-contracts-1.2.1/src/libraries/ArbitrumChecker.sol";
import {MockArbSys} from "../../helper/MockArbSys.sol";

/**
 * @title DeployScript
 * @notice This script will deploy blob reader (if supported), SequencerInbox, OSP and ChallengeManager templates,
 *          and finally update templates in BridgeCreator, or generate calldata for gnosis safe
 */
contract UpgradeCreatorTemplatesScript is DeploymentHelpersScript {
    function run() public {
        bool isArbitrum = vm.envBool("PARENT_CHAIN_IS_ARBITRUM");
        if (isArbitrum) {
            // etch a mock ArbSys contract so that foundry simulate it nicely
            bytes memory mockArbSysCode = address(new MockArbSys()).code;
            vm.etch(address(100), mockArbSysCode);
        }

        vm.startBroadcast();

        // deploy OSP templates
        address osp0 = vm.envAddress("OSP_0");
        if (osp0 == address(0)) {
            osp0 = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.2.1/build/contracts/src/osp/OneStepProver0.sol/OneStepProver0.json"
            );
        }
        address ospMemory = vm.envAddress("OSP_MEMORY");
        if (ospMemory == address(0)) {
            ospMemory = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.2.1/build/contracts/src/osp/OneStepProverMemory.sol/OneStepProverMemory.json"
            );
        }
        address ospMath = vm.envAddress("OSP_MATH");
        if (ospMath == address(0)) {
            ospMath = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.2.1/build/contracts/src/osp/OneStepProverMath.sol/OneStepProverMath.json"
            );
        }
        address ospHostIo = vm.envAddress("OSP_HOST_IO");
        if (ospHostIo == address(0)) {
            ospHostIo = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.2.1/build/contracts/src/osp/OneStepProverHostIo.sol/OneStepProverHostIo.json"
            );
        }
        address ospEntry = vm.envAddress("OSP_ENTRY");
        if (ospEntry == address(0)) {
            ospEntry = deployBytecodeWithConstructorFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.2.1/build/contracts/src/osp/OneStepProofEntry.sol/OneStepProofEntry.json",
                abi.encode(osp0, ospMemory, ospMath, ospHostIo)
            );
        }

        // deploy new challenge manager templates
        address challengeManager = vm.envAddress("CHALLENGE_MANAGER");
        if (challengeManager == address(0)) {
            challengeManager = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.2.1/build/contracts/src/challenge/ChallengeManager.sol/ChallengeManager.json"
            );
        }

        // deploy blob reader
        address reader4844Address;
        if (!isArbitrum) {
            // deploy blob reader
            reader4844Address = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.2.1/out/yul/Reader4844.yul/Reader4844.json"
            );
        }

        // deploy sequencer inbox templates
        address seqInbox = deployBytecodeWithConstructorFromJSON(
            "/node_modules/@arbitrum/nitro-contracts-1.2.1/build/contracts/src/bridge/SequencerInbox.sol/SequencerInbox.json",
            abi.encode(vm.envUint("MAX_DATA_SIZE"), reader4844Address, false)
        );
        address seqInbox2 = deployBytecodeWithConstructorFromJSON(
            "/node_modules/@arbitrum/nitro-contracts-1.2.1/build/contracts/src/bridge/SequencerInbox.sol/SequencerInbox.json",
            abi.encode(vm.envUint("MAX_DATA_SIZE"), reader4844Address, true)
        );

        vm.stopBroadcast();
    }
}
