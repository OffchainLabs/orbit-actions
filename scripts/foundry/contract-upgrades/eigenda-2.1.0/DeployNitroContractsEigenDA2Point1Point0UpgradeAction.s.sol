// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {DeploymentHelpersScript} from "../../helper/DeploymentHelpers.s.sol";
import {
    NitroContractsEigenDA2Point1Point0UpgradeAction,
    IOneStepProofEntry
} from "../../../../contracts/parent-chain/contract-upgrades/NitroContractsEigenDA2Point1Point0UpgradeAction.sol";
import {MockArbSys} from "../../helper/MockArbSys.sol";
import {console} from "forge-std/console.sol";

/**
 * @title DeployEigenDANitroContracts2Point1Point0UpgradeActionScript
 * @notice This script deploys OSPs, ChallengeManager and Rollup templates, and the upgrade action.
 */
contract DeployNitroContractsEigenDA2Point1Point0UpgradeActionScript is DeploymentHelpersScript {
    // ArbOS x EigenDA v32 {LINK OFFICIAL RELEASE HERE WHEN READY}
    bytes32 public constant WASM_MODULE_ROOT = 0xddc237b76a502661518781d4fcf4b42461439cb7fc670b40f7689efcd27b9113;
    // ArbOS v32 https://github.com/OffchainLabs/nitro/releases/tag/consensus-v32
    bytes32 public constant COND_WASM_MODULE_ROOT = 0x184884e1eb9fefdc158f6c8ac912bb183bf3cf83f0090317e0bc4ac5860baa39;

    function run() public {
        bool isArbitrum = vm.envBool("PARENT_CHAIN_IS_ARBITRUM");
        if (isArbitrum) {
            // etch a mock ArbSys contract so that foundry simulate it nicely
            bytes memory mockArbSysCode = address(new MockArbSys()).code;
            vm.etch(address(100), mockArbSysCode);
        }

        address reader4844Address;
        if (!isArbitrum) {
            // deploy blob reader from arbitrum v2.1.0
            reader4844Address = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-1.2.1/out/yul/Reader4844.yul/Reader4844.json"
            );
        }

        vm.startBroadcast();

        // deploy old osp from arbitrum v2.1.0
        address oldOsp;
        {
            address osp0 = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-2.1.0/build/contracts/src/osp/OneStepProver0.sol/OneStepProver0.json"
            );
            address ospMemory = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-2.1.0/build/contracts/src/osp/OneStepProverMemory.sol/OneStepProverMemory.json"
            );
            address ospMath = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-2.1.0/build/contracts/src/osp/OneStepProverMath.sol/OneStepProverMath.json"
            );
            address ospHostIo = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-2.1.0/build/contracts/src/osp/OneStepProverHostIo.sol/OneStepProverHostIo.json"
            );
            oldOsp = deployBytecodeWithConstructorFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-2.1.0/build/contracts/src/osp/OneStepProofEntry.sol/OneStepProofEntry.json",
                abi.encode(osp0, ospMemory, ospMath, ospHostIo)
            );
        }

        // deploy new osp from v2.1.0
        address newOsp;
        {
            address osp0 = deployBytecodeFromJSON(
                "/node_modules/@eigenda/nitro-contracts-2.1.0/build/contracts/src/osp/OneStepProver0.sol/OneStepProver0.json"
            );
            address ospMemory = deployBytecodeFromJSON(
                "/node_modules/@eigenda/nitro-contracts-2.1.0/build/contracts/src/osp/OneStepProverMemory.sol/OneStepProverMemory.json"
            );
            address ospMath = deployBytecodeFromJSON(
                "/node_modules/@eigenda/nitro-contracts-2.1.0/build/contracts/src/osp/OneStepProverMath.sol/OneStepProverMath.json"
            );
            address ospHostIo = deployBytecodeFromJSON(
                "/node_modules/@eigenda/nitro-contracts-2.1.0/build/contracts/src/osp/OneStepProverHostIo.sol/OneStepProverHostIo.json"
            );
            newOsp = deployBytecodeWithConstructorFromJSON(
                "/node_modules/@eigenda/nitro-contracts-2.1.0/build/contracts/src/osp/OneStepProofEntry.sol/OneStepProofEntry.json",
                abi.encode(osp0, ospMemory, ospMath, ospHostIo)
            );
        }

        // inheritance chain for the new one step prover entry:
        // OneStepProverHostIO --immutably_held_by--> OneStepProofEntry --immutably_held_by--> ChallengeManager
        //                                                                        |              |
        //                                                                        |   immutably  |
        //                                                                        v   held by    v
        //                                                          RollupAdmin <--              --> RollupUser
        // deploying new one step prover requires upgrading
        // caller contracts to maintain a new storage
        // mapping for the new one step prover entry.
        // this immutable field pattern goes up to the core RollupAdmin
        // and RollupUser contracts.

        // understand which rollup manager to deploy based on parent chain context.
        address rollupManager;
        uint256 parentChainID = block.chainid;

        if (parentChainID == 17000 || parentChainID == 1) {
            // holesky or ETH
            console.log("(SAFE) Deploying EigenDA x Orbit L1 Blob Verifier contract");
            rollupManager = deployBytecodeFromJSON(
                "/node_modules/@eigenda/nitro-contracts-2.1.0/build/contracts/src/bridge/EigenDABlobVerifierL1.sol/EigenDABlobVerifierL1.json"
            );
        } else {
            console.log("(DANGEROUS) Deploying EigenDA x Orbit L2 Blob Verifier contract");
            rollupManager = deployBytecodeFromJSON( // non ETH or L3 deployment - this contract performs no verifications
                "/node_modules/@eigenda/nitro-contracts-2.1.0/build/contracts/src/bridge/EigenDABlobVerifierL2.sol/EigenDABlobVerifierL2.json"
            );
        }

        // deploy new challenge manager from v2.1.0
        address challengeManager = deployBytecodeFromJSON(
            "/node_modules/@eigenda/nitro-contracts-2.1.0/build/contracts/src/challenge/ChallengeManager.sol/ChallengeManager.json"
        );

        console.log("Successfully deployed EigenDA x Orbit ChallengeManager");

        // deploy new RollupAdminLogic contract from v2.1.0
        address newRollupAdminLogic = deployBytecodeFromJSON(
            "/node_modules/@eigenda/nitro-contracts-2.1.0/build/contracts/src/rollup/RollupAdminLogic.sol/RollupAdminLogic.json"
        );

        console.log("Successfully deployed EigenDA x Orbit RollupAdminLogic");

        // deploy new RollupUserLogic contract from v2.1.0
        address newRollupUserLogic = deployBytecodeFromJSON(
            "/node_modules/@eigenda/nitro-contracts-2.1.0/build/contracts/src/rollup/RollupUserLogic.sol/RollupUserLogic.json"
        );
        console.log("Successfully deployed EigenDA x Orbit RollupUserLogic");

        // deploy new new sequencer inbox from eigenda v2.1.0
        address sequencerInbox = deployBytecodeWithConstructorFromJSON(
            "/node_modules/@eigenda/nitro-contracts-2.1.0/build/contracts/src/bridge/SequencerInbox.sol/SequencerInbox.json",
            abi.encode(vm.envUint("MAX_DATA_SIZE"), reader4844Address, !vm.envBool("IS_FEE_TOKEN_CHAIN"))
        );

        // finally deploy upgrade action
        new NitroContractsEigenDA2Point1Point0UpgradeAction({
            _newWasmModuleRoot: WASM_MODULE_ROOT,
            _newSequencerInboxImpl: sequencerInbox,
            _newChallengeMangerImpl: challengeManager,
            _newOsp: IOneStepProofEntry(newOsp),
            _condOsp: IOneStepProofEntry(oldOsp),
            _condOspRoot: COND_WASM_MODULE_ROOT,
            _rollupManager: rollupManager,
            _newRollupAdminLogic: newRollupAdminLogic,
            _newRollupUserLogic: newRollupUserLogic
        });

        console.log("Successfully deployed EigenDA x Orbit 2.1.0 upgrade/migration action");

        vm.stopBroadcast();
    }
}
