// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import '@arbitrum/nitro-contracts-2.1.0/src/osp/IOneStepProofEntry.sol';
import '@arbitrum/nitro-contracts-2.1.0/src/rollup/IRollupAdmin.sol';
import '@arbitrum/nitro-contracts-2.1.0/src/rollup/IRollupCore.sol';
import '@arbitrum/nitro-contracts-2.1.0/src/bridge/ISequencerInbox.sol';
import { ProxyAdmin } from '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol';
import { TransparentUpgradeableProxy } from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import { Address } from '@openzeppelin/contracts/utils/Address.sol';

import { IChallengeManagerUpgradeInit, IRollupUpgrade } from './CelestiaNitroContracts2Point1Point0UpgradeAction.sol';

interface IInbox {
  function bridge() external view returns (address);
  function sequencerInbox() external view returns (address);
}

interface IERC20Bridge {
  function nativeToken() external view returns (address);
}

interface IERC20Bridge_v2 {
  function nativeTokenDecimals() external view returns (uint8);
}

/**
 * @title   CelestiaNitroContracts2Point1Point3UpgradeAction
 * @notice  Upgrades a 2.1.0 or 2.1.3 chain to Celestia 2.1.3
 *          Will revert if the bridge is an ERC20Bridge below v2.x.x
 */
contract CelestiaNitroContracts2Point1Point3UpgradeAction {
  // Celestia migration requirements
  bytes32 public immutable newWasmModuleRoot;
  IOneStepProofEntry public immutable osp;
  bytes32 public immutable condRoot;
  IOneStepProofEntry public immutable condOsp;
  address public immutable newChallengeManagerImpl;
  // 2.1.3 Upgrade implementations
  address public immutable newEthInboxImpl;
  address public immutable newERC20InboxImpl;
  address public immutable newEthSequencerInboxImpl;
  address public immutable newERC20SequencerInboxImpl;

  constructor(
    address _newEthInboxImpl,
    address _newERC20InboxImpl,
    address _newEthSequencerInboxImpl,
    address _newERC20SequencerInboxImpl,
    bytes32 _newWasmModuleRoot,
    address _newChallengeManagerImpl,
    IOneStepProofEntry _osp,
    bytes32 _condRoot,
    IOneStepProofEntry _condOsp
  ) {
    require(
      Address.isContract(_newEthInboxImpl),
      'CelestiaNitroContracts2Point1Point3UpgradeAction: _newEthInboxImpl is not a contract'
    );
    require(
      Address.isContract(_newERC20InboxImpl),
      'CelestiaNitroContracts2Point1Point3UpgradeAction: _newERC20InboxImpl is not a contract'
    );
    require(
      Address.isContract(_newEthSequencerInboxImpl),
      'CelestiaNitroContracts2Point1Point3UpgradeAction: _newEthSequencerInboxImpl is not a contract'
    );
    require(
      Address.isContract(_newERC20SequencerInboxImpl),
      'CelestiaNitroContracts2Point1Point3UpgradeAction: _newERC20SequencerInboxImpl is not a contract'
    );
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

    newEthInboxImpl = _newEthInboxImpl;
    newERC20InboxImpl = _newERC20InboxImpl;
    newEthSequencerInboxImpl = _newEthSequencerInboxImpl;
    newERC20SequencerInboxImpl = _newERC20SequencerInboxImpl;

    newWasmModuleRoot = _newWasmModuleRoot;
    newChallengeManagerImpl = _newChallengeManagerImpl;
    osp = _osp;
    condRoot = _condRoot;
    condOsp = _condOsp;
  }

  function perform(
    IRollupCore rollup,
    address inbox,
    ProxyAdmin proxyAdmin
  ) external {
    address bridge = IInbox(inbox).bridge();
    address sequencerInbox = IInbox(inbox).sequencerInbox();

    bool isERC20 = false;

    // if the bridge is an ERC20Bridge below v2.x.x, revert
    try IERC20Bridge(bridge).nativeToken() returns (address) {
      isERC20 = true;
      // it is an ERC20Bridge, check if it is on v2.x.x
      try IERC20Bridge_v2(address(bridge)).nativeTokenDecimals() returns (
        uint8
      ) {} catch {
        // it is not on v2.x.x, revert
        revert(
          'CelestiaNitroContracts2Point1Point3UpgradeAction: bridge is an ERC20Bridge below v2.x.x'
        );
      }
    } catch {}

    // upgrade the sequencer inbox
    proxyAdmin.upgrade({
      proxy: TransparentUpgradeableProxy(payable((sequencerInbox))),
      implementation: isERC20
        ? newERC20SequencerInboxImpl
        : newEthSequencerInboxImpl
    });

    // upgrade the inbox
    proxyAdmin.upgrade({
      proxy: TransparentUpgradeableProxy(payable((inbox))),
      implementation: isERC20 ? newERC20InboxImpl : newEthInboxImpl
    });

    // migrate the osp to celestia
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
      'CelestiaNitroContracts2Point1Point3UpgradeAction: new challenge manager implementation set'
    );
    require(
      IChallengeManagerUpgradeInit(address(challengeManager)).osp() ==
        address(osp),
      'CelestiaNitroContracts2Point1Point3UpgradeAction: new OSP not set'
    );

    // set new wasm module root
    IRollupAdmin(address(rollup)).setWasmModuleRoot(newWasmModuleRoot);

    // verify:
    require(
      rollup.wasmModuleRoot() == newWasmModuleRoot,
      'CelestiaNitroContracts2Point1Point3UpgradeAction: wasm module root not set'
    );
  }
}
