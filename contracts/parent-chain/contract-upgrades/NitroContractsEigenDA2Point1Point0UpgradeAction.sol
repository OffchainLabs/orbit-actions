// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "@eigenda/nitro-contracts-2.1.0/src/osp/IOneStepProofEntry.sol";
import "@eigenda/nitro-contracts-2.1.0/src/rollup/IRollupAdmin.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/*
    EigendDA support:
    - modifies SequencerInbox and OneStepProverHostIO contracts
    - introduces a new RollupManager contract used for verification against the EigenDAServiceManager contract
*/

interface IChallengeManagerUpgradeInit {
    function postUpgradeInit(IOneStepProofEntry osp_, bytes32 condRoot, IOneStepProofEntry condOsp) external;
    function osp() external returns (address);
}

interface ISeqInboxUpgradeInit {
    function executeUpgrade() external;
}

interface IChallengeManagerUpgradeHandler {
    function executeUpgrade(address _updatedOsp) external;
    function getOsp() external view returns (address);
}

interface IRollupUpgrade {
    function upgradeTo(address newImplementation) external;
    function upgradeSecondaryTo(address newImplementation) external;
    function anyTrustFastConfirmer() external returns (address);
}

/// @notice Upgrades an existing Arbitrum chain to using version 2.1.0 of EigenDA x Nitro contracts.
contract NitroContractsEigenDA2Point1Point0UpgradeAction {
    address public immutable seqInboxImpl;
    address public immutable challengeMgrImpl;

    // Two OSP contracts are used to ensure cross compatibility
    // with previous bridge assertions using the PrevWASMRoot OSP contract
    // that haven't been finalized yet.

    // EigenDA v2.1.0 OSP contracts
    IOneStepProofEntry public immutable osp;
    bytes32 public immutable wasmModuleRoot;

    // Arbitrum v2.1.0 conditional OSP contracts
    IOneStepProofEntry public immutable condOsp;
    bytes32 public immutable condRoot;

    address public immutable rollupManager;
    address public immutable newRollupAdminLogic;
    address public immutable newRollupUserLogic;

    constructor(
        bytes32 _newWasmModuleRoot,
        address _newSequencerInboxImpl,
        address _newChallengeMangerImpl,
        IOneStepProofEntry _newOsp,
        IOneStepProofEntry _condOsp,
        bytes32 _condOspRoot,
        address _rollupManager, // eigenDA rollup manager contract
        address _newRollupAdminLogic,
        address _newRollupUserLogic
    ) {
        require(_newWasmModuleRoot != bytes32(0), "Invalid wasm root hash");
        // wasmModuleRoot = _newWasmModuleRoot;

        require(Address.isContract(_newSequencerInboxImpl), "Invalid Sequencer Inbox implementation");
        seqInboxImpl = _newSequencerInboxImpl;

        require(Address.isContract(_newChallengeMangerImpl), "Invalid Challenge Manager implementation");
        challengeMgrImpl = _newChallengeMangerImpl;

        require(Address.isContract(address(_newOsp)), "Invalid OSP contract");
        osp = _newOsp;
        wasmModuleRoot = _newWasmModuleRoot;

        require(Address.isContract(address(_condOsp)), 'Invalid conditional OSP contract');
        condOsp = _condOsp;
        condRoot = _condOspRoot;

        require(Address.isContract(_rollupManager), "Invalid EigenDA Rollup Manager contract");
        rollupManager = _rollupManager;

        require(
            Address.isContract(_newRollupAdminLogic),
            "NitroContracts2Point1Point0UpgradeAction: _newRollupAdminLogic is not a contract"
        );

        newRollupAdminLogic = _newRollupAdminLogic;

        require(
            Address.isContract(_newRollupUserLogic),
            "NitroContracts2Point1Point0UpgradeAction: _newRollupUserLogic is not a contract"
        );

        newRollupUserLogic = _newRollupUserLogic;
    }

    function execute(IRollupCore rollup, ProxyAdmin adminProxy) public {
        IRollupAdmin(address(rollup)).setWasmModuleRoot(wasmModuleRoot);

        // Confirm the Wasm root updated successfully on the rollupAdmin contract
        require(rollup.wasmModuleRoot() == wasmModuleRoot, "Failed to update Wasm root");

        // Upgrade the SequencerInbox and verify sufficient time variation:
        TransparentUpgradeableProxy sequencerInbox =
            TransparentUpgradeableProxy(payable(address(rollup.sequencerInbox())));
        (, uint256 blocksBeforeUpgrade,,) = ISequencerInbox(address(sequencerInbox)).maxTimeVariation();
        adminProxy.upgrade(sequencerInbox, seqInboxImpl);

        // Validate the new Sequencer Inbox implementation:
        require(adminProxy.getProxyImplementation(sequencerInbox) == seqInboxImpl, "Sequencer Inbox upgrade failed");

        (, uint256 blocksAfterUpgrade,,) = ISequencerInbox(address(sequencerInbox)).maxTimeVariation();

        require(blocksBeforeUpgrade != 0 && blocksBeforeUpgrade == blocksAfterUpgrade, "Time variation mismatch");

        // Ensure that rollup manager contract is a dependency of the rollup contract:
        ISequencerInbox(address(sequencerInbox)).setEigenDARollupManager(rollupManager);

        require(
            address(ISequencerInbox(address(sequencerInbox)).eigenDARollupManager()) == rollupManager,
            "Rollup Manager mismatch"
        );

        _upgradeChallengerManager(rollup, adminProxy);
    }

    function _upgradeChallengerManager(IRollupCore rollup, ProxyAdmin proxyAdmin) internal {
        // set the new challenge manager impl
        TransparentUpgradeableProxy challengeManager =
            TransparentUpgradeableProxy(payable(address(rollup.challengeManager())));
        proxyAdmin.upgradeAndCall(
            challengeManager,
            challengeMgrImpl,
            abi.encodeCall(IChallengeManagerUpgradeInit.postUpgradeInit, (osp, condRoot, condOsp))
        );

        // verify
        require(
            proxyAdmin.getProxyImplementation(challengeManager) == challengeMgrImpl,
            "NitroContracts2Point1Point0UpgradeAction: new challenge manager implementation set"
        );
        require(
            IChallengeManagerUpgradeInit(address(challengeManager)).osp() == address(osp),
            "NitroContracts2Point1Point0UpgradeAction: new OSP not set"
        );

        // set new wasm module root
        IRollupAdmin(address(rollup)).setWasmModuleRoot(wasmModuleRoot);

        // verify:
        require(
            rollup.wasmModuleRoot() == wasmModuleRoot,
            "NitroContracts2Point1Point0UpgradeAction: wasm module root not set"
        );

        _upgradeRollup(address(rollup));
    }

    function _upgradeRollup(address rollupProxy) internal {
        IRollupUpgrade rollup = IRollupUpgrade(rollupProxy);

        // set new logic contracts
        rollup.upgradeTo(newRollupAdminLogic);
        rollup.upgradeSecondaryTo(newRollupUserLogic);

        // verify
        require(
            rollup.anyTrustFastConfirmer() == address(0),
            "NitroContracts2Point1Point0UpgradeAction: unexpected fast confirmer address"
        );
    }
}
