// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {DeploymentHelpersScript} from "../../helper/DeploymentHelpers.s.sol";
import {MockArbSys} from "../../helper/MockArbSys.sol";
import "@arbitrum/nitro-contracts-1.2.1/src/rollup/RollupCreator.sol";

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

        // updated creators with new templates
        bool creatorOwnerIsMultisig = vm.envBool("CREATOR_OWNER_IS_MULTISIG");
        // if (creatorOwnerIsMultisig) {
        //     _generateUpdateTemplatesCalldata(rollupCreator, ethSeqInbox, erc20SeqInbox);
        // } else {
        //     _updateBridgeCreatorTemplates(rollupCreator, ethSeqInbox, erc20SeqInbox);
        // }
        address rollupCreator = vm.envAddress("ROLLUP_CREATOR");
        _updateBridgeCreatorTemplates(rollupCreator, seqInboxEth, seqInboxErc20);

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

    function _updateBridgeCreatorTemplates(
        address rollupCreatorAddress,
        address newEthSeqInbox,
        address newErc20SeqInbox
    ) internal {
        BridgeCreator bridgeCreator = RollupCreator(payable(rollupCreatorAddress)).bridgeCreator();

        // update eth templates in BridgeCreator
        (IBridge bridge,, IInboxBase inbox, IRollupEventInbox rollupEventInbox, IOutbox outbox) =
            bridgeCreator.ethBasedTemplates();
        bridgeCreator.updateTemplates(
            BridgeCreator.BridgeContracts(
                bridge, ISequencerInbox(address(newEthSeqInbox)), inbox, rollupEventInbox, outbox
            )
        );

        // update erc20 templates in BridgeCreator
        (IBridge erc20Bridge,, IInboxBase erc20Inbox, IRollupEventInbox erc20RollupEventInbox, IOutbox erc20Outbox) =
            bridgeCreator.erc20BasedTemplates();
        bridgeCreator.updateERC20Templates(
            BridgeCreator.BridgeContracts(
                erc20Bridge, ISequencerInbox(address(newErc20SeqInbox)), erc20Inbox, erc20RollupEventInbox, erc20Outbox
            )
        );

        // verify
        (, ISequencerInbox _ethSeqInbox,,,) = bridgeCreator.ethBasedTemplates();
        (, ISequencerInbox _erc20SeqInbox,,,) = bridgeCreator.erc20BasedTemplates();
        require(
            address(_ethSeqInbox) == address(newEthSeqInbox) && address(_erc20SeqInbox) == address(newErc20SeqInbox),
            "Templates not updated"
        );
    }

    function _updateRollupCreatorTemplates(
        address rollupCreatorAddress,
        address newOspEntry,
        address newChallengeManager
    ) internal {
        RollupCreator rollupCreator = RollupCreator(payable(rollupCreatorAddress));

        rollupCreator.setTemplates({
            _bridgeCreator: rollupCreator.bridgeCreator(),
            _osp: IOneStepProofEntry(newOspEntry),
            _challengeManagerLogic: IChallengeManager(newChallengeManager),
            _rollupAdminLogic: rollupCreator.rollupAdminLogic(),
            _rollupUserLogic: rollupCreator.rollupUserLogic(),
            _upgradeExecutorLogic: (rollupCreator.upgradeExecutorLogic()),
            _validatorUtils: rollupCreator.validatorUtils(),
            _validatorWalletCreator: rollupCreator.validatorWalletCreator(),
            _l2FactoriesDeployer: (rollupCreator.l2FactoriesDeployer())
        });

        // verify
        require(
            address(rollupCreator.osp()) == newOspEntry
                && address(rollupCreator.challengeManagerTemplate()) == newChallengeManager,
            "Templates not updated"
        );
    }

    // function setTemplates(
    //     BridgeCreator _bridgeCreator,
    //     IOneStepProofEntry _osp,
    //     IChallengeManager _challengeManagerLogic,
    //     IRollupAdmin _rollupAdminLogic,
    //     IRollupUser _rollupUserLogic,
    //     IUpgradeExecutor _upgradeExecutorLogic,
    //     address _validatorUtils,
    //     address _validatorWalletCreator,
    //     DeployHelper _l2FactoriesDeployer
    // ) external onlyOwner {
    //     bridgeCreator = _bridgeCreator;
    //     osp = _osp;
    //     challengeManagerTemplate = _challengeManagerLogic;
    //     rollupAdminLogic = _rollupAdminLogic;
    //     rollupUserLogic = _rollupUserLogic;
    //     upgradeExecutorLogic = _upgradeExecutorLogic;
    //     validatorUtils = _validatorUtils;
    //     validatorWalletCreator = _validatorWalletCreator;
    //     l2FactoriesDeployer = _l2FactoriesDeployer;
    //     emit TemplatesUpdated();
}
