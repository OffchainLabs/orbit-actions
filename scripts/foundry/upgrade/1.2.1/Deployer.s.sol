// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "forge-std/Script.sol";
import {OneStepProver0} from "@arbitrum/nitro-contracts/src/osp/OneStepProver0.sol";
import {OneStepProverMemory} from "@arbitrum/nitro-contracts/src/osp/OneStepProverMemory.sol";
import {OneStepProverMath} from "@arbitrum/nitro-contracts/src/osp/OneStepProverMath.sol";
import {OneStepProverHostIo} from "@arbitrum/nitro-contracts/src/osp/OneStepProverHostIo.sol";
import {OneStepProofEntry} from "@arbitrum/nitro-contracts/src/osp/OneStepProofEntry.sol";
import {ChallengeManager} from "@arbitrum/nitro-contracts/src/challenge/ChallengeManager.sol";
import {SequencerInbox} from "@arbitrum/nitro-contracts/src/bridge/SequencerInbox.sol";
import {IReader4844} from "@arbitrum/nitro-contracts/src/libraries/IReader4844.sol";

/**
 * @title DeployScript
 * @notice This script deploys OSPs and ChallengeManager templates,
 */
contract DeployScript is Script {
    function run() public {
        uint256 _chainId = block.chainid;
        if (_chainId == 42161 || _chainId == 42170 || _chainId == 421614) {
            revert("Chain ID not supported");
        }

        vm.startBroadcast();

        // deploy OSP templates
        OneStepProver0 osp0 = new OneStepProver0();
        OneStepProverMemory ospMemory = new OneStepProverMemory();
        OneStepProverMath ospMath = new OneStepProverMath();
        OneStepProverHostIo ospHostIo = new OneStepProverHostIo();
        new OneStepProofEntry(osp0, ospMemory, ospMath, ospHostIo);

        // deploy new challenge manager templates
        new ChallengeManager();

        // deploy blob reader
        bytes memory reader4844Bytecode = _getReader4844Bytecode();
        address reader4844Address;
        assembly {
            reader4844Address := create(0, add(reader4844Bytecode, 0x20), mload(reader4844Bytecode))
        }
        require(reader4844Address != address(0), "Reader4844 could not be deployed");

        // deploy sequencer inbox template
        new SequencerInbox({_maxDataSize: 117964, reader4844_: IReader4844(reader4844Address), _isUsingFeeToken: false});

        vm.stopBroadcast();
    }

    /**
     * @notice Read Reader4844 bytecode from JSON file at ${root}/out/yul/Reader4844.yul/Reader4844.json
     */
    function _getReader4844Bytecode() internal returns (bytes memory) {
        string memory readerBytecodeFilePath = string(
            abi.encodePacked(
                vm.projectRoot(), "/node_modules/@arbitrum/nitro-contracts/out/yul/Reader4844.yul/Reader4844.json"
            )
        );
        string memory json = vm.readFile(readerBytecodeFilePath);
        return vm.parseJsonBytes(json, ".bytecode.object");
    }
}
