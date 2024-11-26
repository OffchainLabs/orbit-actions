// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import '@arbitrum/nitro-contracts-2.1.0/src/osp/IOneStepProofEntry.sol';
import '@arbitrum/nitro-contracts-2.1.0/src/rollup/IRollupAdmin.sol';
import '@arbitrum/nitro-contracts-2.1.0/src/rollup/IRollupCore.sol';
import '@arbitrum/nitro-contracts-2.1.0/src/bridge/ISequencerInbox.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol';
import '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
interface IChallengeManagerUpgradeInit {
  function postUpgradeInit(
    IOneStepProofEntry osp_,
    bytes32 condRoot,
    IOneStepProofEntry condOsp
  ) external;
  function osp() external returns (address);
}

interface IRollupUpgrade {
  function upgradeTo(address newImplementation) external;
  function upgradeSecondaryTo(address newImplementation) external;
  function anyTrustFastConfirmer() external returns (address);
}

interface ISequencerInbox_v1_2_1 {
  function isUsingFeeToken() external returns (bool);
}

/**
 * @title CelestiaNitroContracts2Point1Point0UpgradeAction
 * @notice  Upgrades a 2.1.0 chain to Celestia 2.1.0
 */
contract CelestiaNitroContracts2Point1Point0UpgradeAction {
  bytes32 public immutable newWasmModuleRoot;
  address public immutable newSequencerInboxImpl;
  address public immutable newChallengeManagerImpl;
  IOneStepProofEntry public immutable osp;
  bytes32 public immutable condRoot;
  IOneStepProofEntry public immutable condOsp;

  address public immutable newRollupAdminLogic;
  address public immutable newRollupUserLogic;

  constructor(
    bytes32 _newWasmModuleRoot,
    address _newSequencerInboxImpl,
    address _newChallengeManagerImpl,
    IOneStepProofEntry _osp,
    bytes32 _condRoot,
    IOneStepProofEntry _condOsp,
    address _newRollupAdminLogic,
    address _newRollupUserLogic
  ) {
    require(
      _newWasmModuleRoot != bytes32(0),
      'NitroContracts2Point1Point0UpgradeAction: _newWasmModuleRoot is empty'
    );
    require(
      Address.isContract(_newChallengeManagerImpl),
      'NitroContracts2Point1Point0UpgradeAction: _newChallengeManagerImpl is not a contract'
    );
    require(
      Address.isContract(address(_osp)),
      'NitroContracts2Point1Point0UpgradeAction: _osp is not a contract'
    );
    require(
      Address.isContract(address(_condOsp)),
      'NitroContracts2Point1Point0UpgradeAction: _condOsp is not a contract'
    );
    require(
      Address.isContract(_newRollupAdminLogic),
      'NitroContracts2Point1Point0UpgradeAction: _newRollupAdminLogic is not a contract'
    );
    require(
      Address.isContract(_newRollupUserLogic),
      'NitroContracts2Point1Point0UpgradeAction: _newRollupUserLogic is not a contract'
    );
    require(
      Address.isContract(_newSequencerInboxImpl),
      '_newSequencerInboxImpl is not a contract'
    );

    newWasmModuleRoot = _newWasmModuleRoot;
    newChallengeManagerImpl = _newChallengeManagerImpl;
    osp = _osp;
    condRoot = _condRoot;
    condOsp = _condOsp;
    newRollupAdminLogic = _newRollupAdminLogic;
    newRollupUserLogic = _newRollupUserLogic;
    newSequencerInboxImpl = _newSequencerInboxImpl;
  }

  function perform(IRollupCore rollup, ProxyAdmin proxyAdmin) external {
    /// check if previous upgrade v1.2.1 was performed by polling function which was introduced in that version
    ISequencerInbox_v1_2_1 sequencerInbox = ISequencerInbox_v1_2_1(
      address(rollup.sequencerInbox())
    );
    try sequencerInbox.isUsingFeeToken() returns (bool) {} catch {
      revert(
        'NitroContracts2Point1Point0UpgradeAction: sequencer inbox needs to be at version >= 1.2.1'
      );
    }

    /// check that condRoot is being used
    require(
      rollup.wasmModuleRoot() == condRoot,
      'NitroContracts2Point1Point0UpgradeAction: wasm root mismatch'
    );

    /// do the upgrade
    _upgradeChallengerManagerAndInbox(rollup, proxyAdmin);
    _upgradeRollup(address(rollup));
  }

  function _upgradeChallengerManagerAndInbox(
    IRollupCore rollup,
    ProxyAdmin proxyAdmin
  ) internal {
    // set the new sequencer inbox
    TransparentUpgradeableProxy sequencerInbox = TransparentUpgradeableProxy(
      payable(address(rollup.sequencerInbox()))
    );
    (, uint256 futureBlocksBefore, , ) = ISequencerInbox(
      address(sequencerInbox)
    ).maxTimeVariation();
    proxyAdmin.upgrade(sequencerInbox, newSequencerInboxImpl);

    // verify
    require(
      proxyAdmin.getProxyImplementation(sequencerInbox) ==
        newSequencerInboxImpl,
      'new seq inbox implementation set'
    );
    (, uint256 futureBlocksAfter, , ) = ISequencerInbox(address(sequencerInbox))
      .maxTimeVariation();
    require(
      futureBlocksBefore != 0 && futureBlocksBefore == futureBlocksAfter,
      'maxTimeVariation not set'
    );
    // set the new challenge manager impl
    TransparentUpgradeableProxy challengeManager = TransparentUpgradeableProxy(
      payable(address(rollup.challengeManager()))
    );
    proxyAdmin.upgradeAndCall(
      challengeManager,
      newChallengeManagerImpl,
      abi.encodeCall(
        IChallengeManagerUpgradeInit.postUpgradeInit,
        (osp, condRoot, condOsp)
      )
    );

    // verify
    require(
      proxyAdmin.getProxyImplementation(challengeManager) ==
        newChallengeManagerImpl,
      'NitroContracts2Point1Point0UpgradeAction: new challenge manager implementation set'
    );
    require(
      IChallengeManagerUpgradeInit(address(challengeManager)).osp() ==
        address(osp),
      'NitroContracts2Point1Point0UpgradeAction: new OSP not set'
    );

    // set new wasm module root
    IRollupAdmin(address(rollup)).setWasmModuleRoot(newWasmModuleRoot);

    // verify:
    require(
      rollup.wasmModuleRoot() == newWasmModuleRoot,
      'NitroContracts2Point1Point0UpgradeAction: wasm module root not set'
    );
  }

  function _upgradeRollup(address rollupProxy) internal {
    IRollupUpgrade rollup = IRollupUpgrade(rollupProxy);

    // set new logic contracts
    rollup.upgradeTo(newRollupAdminLogic);
    rollup.upgradeSecondaryTo(newRollupUserLogic);

    // verify
    require(
      rollup.anyTrustFastConfirmer() == address(0),
      'NitroContracts2Point1Point0UpgradeAction: unexpected fast confirmer address'
    );
  }
}
