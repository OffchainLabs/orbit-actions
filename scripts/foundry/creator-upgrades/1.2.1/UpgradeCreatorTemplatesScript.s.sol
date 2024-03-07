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
    bool public isArbitrum;

    function run() public {
        isArbitrum = vm.envBool("PARENT_CHAIN_IS_ARBITRUM");
        if (isArbitrum) {
            // etch a mock ArbSys contract so that foundry simulate it nicely
            bytes memory mockArbSysCode = address(new MockArbSys()).code;
            vm.etch(address(100), mockArbSysCode);
        }

        vm.startBroadcast();

        // deploy templates if not already deployed
        (
            address osp0,
            address ospMemory,
            address ospMath,
            address ospHostIo,
            address ospEntry,
            address challengeManager,
            address seqInboxEth,
            address seqInboxErc20
        ) = _deployTemplates();

        vm.stopBroadcast();
    }

    /**
     * @notice Deploy OSP, ChallengeManager and SequencerInbox templates if they're not already deployed
     */
    function _deployTemplates()
        internal
        returns (
            address osp0,
            address ospMemory,
            address ospMath,
            address ospHostIo,
            address ospEntry,
            address challengeManager,
            address seqInboxEth,
            address seqInboxErc20
        )
    {
        osp0 = vm.envAddress("OSP_0");
        if (osp0 == address(0)) {
            osp0 = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.2.1/build/contracts/src/osp/OneStepProver0.sol/OneStepProver0.json"
            );
        }
        ospMemory = vm.envAddress("OSP_MEMORY");
        if (ospMemory == address(0)) {
            ospMemory = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.2.1/build/contracts/src/osp/OneStepProverMemory.sol/OneStepProverMemory.json"
            );
        }
        ospMath = vm.envAddress("OSP_MATH");
        if (ospMath == address(0)) {
            ospMath = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.2.1/build/contracts/src/osp/OneStepProverMath.sol/OneStepProverMath.json"
            );
        }
        ospHostIo = vm.envAddress("OSP_HOST_IO");
        if (ospHostIo == address(0)) {
            ospHostIo = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.2.1/build/contracts/src/osp/OneStepProverHostIo.sol/OneStepProverHostIo.json"
            );
        }
        ospEntry = vm.envAddress("OSP_ENTRY");
        if (ospEntry == address(0)) {
            ospEntry = deployBytecodeWithConstructorFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.2.1/build/contracts/src/osp/OneStepProofEntry.sol/OneStepProofEntry.json",
                abi.encode(osp0, ospMemory, ospMath, ospHostIo)
            );
        }

        // deploy new challenge manager templates
        challengeManager = vm.envAddress("CHALLENGE_MANAGER");
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
        seqInboxEth = deployBytecodeWithConstructorFromJSON(
            "/node_modules/@arbitrum/nitro-contracts-1.2.1/build/contracts/src/bridge/SequencerInbox.sol/SequencerInbox.json",
            abi.encode(vm.envUint("MAX_DATA_SIZE"), reader4844Address, false)
        );
        seqInboxErc20 = deployBytecodeWithConstructorFromJSON(
            "/node_modules/@arbitrum/nitro-contracts-1.2.1/build/contracts/src/bridge/SequencerInbox.sol/SequencerInbox.json",
            abi.encode(vm.envUint("MAX_DATA_SIZE"), reader4844Address, true)
        );

        return (osp0, ospMemory, ospMath, ospHostIo, ospEntry, challengeManager, seqInboxEth, seqInboxErc20);
    }
}
