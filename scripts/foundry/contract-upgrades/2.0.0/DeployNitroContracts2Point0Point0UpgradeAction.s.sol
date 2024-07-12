// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {DeploymentHelpersScript} from "../../helper/DeploymentHelpers.s.sol";
import {
    NitroContracts2Point0Point0UpgradeAction,
    IOneStepProofEntry
} from "../../../../contracts/parent-chain/contract-upgrades/NitroContracts2Point0Point0UpgradeAction.sol";

/**
 * @title DeployNitroContracts2Point0Point0UpgradeActionScript
 * @notice This script deploys OSPs and ChallengeManager templates, blob reader and SequencerInbox template.
 *          Not applicable for Arbitrum based chains due to precompile call in SequencerInbox (Foundry simulation breaks).
 */
contract DeployNitroContracts2Point0Point0UpgradeActionScript is DeploymentHelpersScript {
    // ArbOS v31 https://github.com/OffchainLabs/nitro/releases/tag/consensus-v31
    bytes32 public constant WASM_MODULE_ROOT = 0x260f5fa5c3176a856893642e149cf128b5a8de9f828afec8d11184415dd8dc69;

    // ArbOS v20 https://github.com/OffchainLabs/nitro/releases/tag/consensus-v20
    bytes32 public constant COND_WASM_MODULE_ROOT = 0x260f5fa5c3176a856893642e149cf128b5a8de9f828afec8d11184415dd8dc69;

    function run() public {
        vm.startBroadcast();

        // deploy new osp from v2.0.0
        address newOsp;
        {
            address osp0 = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-2.0.0/build/contracts/src/osp/OneStepProver0.sol/OneStepProver0.json"
            );
            address ospMemory = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-2.0.0/build/contracts/src/osp/OneStepProverMemory.sol/OneStepProverMemory.json"
            );
            address ospMath = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-2.0.0/build/contracts/src/osp/OneStepProverMath.sol/OneStepProverMath.json"
            );
            address ospHostIo = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-2.0.0/build/contracts/src/osp/OneStepProverHostIo.sol/OneStepProverHostIo.json"
            );
            newOsp = deployBytecodeWithConstructorFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-2.0.0/build/contracts/src/osp/OneStepProofEntry.sol/OneStepProofEntry.json",
                abi.encode(osp0, ospMemory, ospMath, ospHostIo)
            );
        }

        // deploy condOsp from v1.3.0
        address condOsp;
        {
            address osp0 = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.3.0/build/contracts/src/osp/OneStepProver0.sol/OneStepProver0.json"
            );
            address ospMemory = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.3.0/build/contracts/src/osp/OneStepProverMemory.sol/OneStepProverMemory.json"
            );
            address ospMath = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.3.0/build/contracts/src/osp/OneStepProverMath.sol/OneStepProverMath.json"
            );
            address ospHostIo = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.3.0/build/contracts/src/osp/OneStepProverHostIo.sol/OneStepProverHostIo.json"
            );
            condOsp = deployBytecodeWithConstructorFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.3.0/build/contracts/src/osp/OneStepProofEntry.sol/OneStepProofEntry.json",
                abi.encode(osp0, ospMemory, ospMath, ospHostIo)
            );
        }

        // deploy new challenge manager from v2.0.0
        address challengeManager = deployBytecodeFromJSON(
            "/node_modules/@arbitrum/nitro-contracts-2.0.0/build/contracts/src/challenge/ChallengeManager.sol/ChallengeManager.json"
        );

        // finally deploy upgrade action
        new NitroContracts2Point0Point0UpgradeAction({
            _newWasmModuleRoot: WASM_MODULE_ROOT,
            _newChallengeManagerImpl: challengeManager,
            _osp: IOneStepProofEntry(newOsp),
            _condRoot: COND_WASM_MODULE_ROOT,
            _condOsp: IOneStepProofEntry(condOsp)
        });

        vm.stopBroadcast();
    }
}
