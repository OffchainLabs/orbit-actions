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
import {NitroContracts1Point2Point1UpgradeAction} from
    "../../../../contracts/parent-chain/contract-upgrades/NitroContracts1Point2Point1UpgradeAction.sol";

import {ArbitrumChecker} from "@arbitrum/nitro-contracts/src/libraries/ArbitrumChecker.sol";
import {MockArbSys} from "../../helper/MockArbSys.sol";

/**
 * @title DeployScript
 * @notice This script deploys OSPs and ChallengeManager templates, blob reader and SequencerInbox template.
 *          Not applicable for Arbitrum based chains due to precompile call in SequencerInbox (Foundry simulation breaks).
 */
contract DeployScript is Script {
    function run() public {
        bool isArbitrum = vm.envBool("PARENT_CHAIN_IS_ARBITRUM");
        if (isArbitrum) {
            // etch a mock ArbSys contract so that foundry simulate it nicely
            bytes memory mockArbSysCode = address(new MockArbSys()).code;
            vm.etch(address(100), mockArbSysCode);
        }

        vm.startBroadcast();

        // deploy OSP templates
        OneStepProver0 osp0 = new OneStepProver0();
        OneStepProverMemory ospMemory = new OneStepProverMemory();
        OneStepProverMath ospMath = new OneStepProverMath();
        OneStepProverHostIo ospHostIo = new OneStepProverHostIo();
        address osp = address(new OneStepProofEntry(osp0, ospMemory, ospMath, ospHostIo));

        // deploy new challenge manager templates
        address challengeManager = address(new ChallengeManager());

        address reader4844Address;
        if (!isArbitrum) {
            // deploy blob reader
            bytes memory reader4844Bytecode = _getReader4844Bytecode();
            assembly {
                reader4844Address := create(0, add(reader4844Bytecode, 0x20), mload(reader4844Bytecode))
            }
            require(reader4844Address != address(0), "Reader4844 could not be deployed");
        }

        // deploy sequencer inbox template
        address seqInbox = address(
            new SequencerInbox({
                _maxDataSize: 117964,
                reader4844_: IReader4844(reader4844Address),
                _isUsingFeeToken: vm.envBool("IS_FEE_TOKEN_CHAIN")
            })
        );

        // finally deploy upgrade action
        new NitroContracts1Point2Point1UpgradeAction({
            _newWasmModuleRoot: vm.envBytes32("WASM_MODULE_ROOT"),
            _newSequencerInboxImpl: seqInbox,
            _newChallengeMangerImpl: challengeManager,
            _newOsp: osp
        });

        vm.stopBroadcast();
    }

    /**
     * @notice Read Reader4844 bytecode from JSON file at ${root}/out/yul/Reader4844.yul/Reader4844.json
     */
    function _getReader4844Bytecode() internal view returns (bytes memory) {
        string memory readerBytecodeFilePath = string(
            abi.encodePacked(
                vm.projectRoot(), "/node_modules/@arbitrum/nitro-contracts/out/yul/Reader4844.yul/Reader4844.json"
            )
        );
        string memory json = vm.readFile(readerBytecodeFilePath);
        return vm.parseJsonBytes(json, ".bytecode.object");
    }
}
