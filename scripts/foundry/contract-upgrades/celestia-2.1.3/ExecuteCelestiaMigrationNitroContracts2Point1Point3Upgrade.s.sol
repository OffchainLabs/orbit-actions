// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import 'forge-std/Script.sol';
import { CelestiaNitroContracts2Point1Point3UpgradeAction, ProxyAdmin } from '../../../../contracts/parent-chain/contract-upgrades/CelestiaNitroContracts2Point1Point3UpgradeAction.sol';
import { IInboxBase } from '@arbitrum/nitro-contracts-2.1.3/src/bridge/IInboxBase.sol';
import { IERC20Bridge } from '@arbitrum/nitro-contracts-2.1.3/src/bridge/IERC20Bridge.sol';
import { IERC20Inbox } from '@arbitrum/nitro-contracts-2.1.3/src/bridge/IERC20Inbox.sol';
import { IUpgradeExecutor } from '@offchainlabs/upgrade-executor/src/IUpgradeExecutor.sol';
import { ISequencerInbox } from '@arbitrum/nitro-contracts-2.1.3/src/bridge/ISequencerInbox.sol';
import { IRollupCore } from '@arbitrum/nitro-contracts-2.1.0/src/rollup/IRollupCore.sol';

/**
 * @title ExecuteNitroContracts1Point2Point3UpgradeScript
 * @notice This script executes nitro contracts 2.1.3 upgrade through UpgradeExecutor
 */
contract ExecuteCelestiaMigrationNitroContracts2Point1Point3UpgradeScript is Script {
  function run() public {
    // used to check upgrade was successful
    bytes32 wasmModuleRoot = vm.envBytes32('TARGET_WASM_MODULE_ROOT');

    CelestiaNitroContracts2Point1Point3UpgradeAction upgradeAction = CelestiaNitroContracts2Point1Point3UpgradeAction(
        vm.envAddress('UPGRADE_ACTION_ADDRESS')
      );

    address inbox = vm.envAddress('INBOX_ADDRESS');

    uint256 maxDataSize = vm.envUint('MAX_DATA_SIZE');
    require(
      ISequencerInbox(upgradeAction.newEthInboxImpl()).maxDataSize() ==
        maxDataSize ||
        ISequencerInbox(upgradeAction.newERC20InboxImpl()).maxDataSize() ==
        maxDataSize ||
        ISequencerInbox(upgradeAction.newEthSequencerInboxImpl())
          .maxDataSize() ==
        maxDataSize ||
        ISequencerInbox(upgradeAction.newERC20SequencerInboxImpl())
          .maxDataSize() ==
        maxDataSize,
      'MAX_DATA_SIZE mismatch with action'
    );
    require(
      IInboxBase(inbox).maxDataSize() == maxDataSize,
      'MAX_DATA_SIZE mismatch with current deployment'
    );

    IRollupCore rollup = IRollupCore(
      address(IInboxBase(inbox).bridge().rollup())
    );

    // prepare upgrade calldata
    ProxyAdmin proxyAdmin = ProxyAdmin(vm.envAddress('PROXY_ADMIN_ADDRESS'));
    bytes memory upgradeCalldata = abi.encodeCall(
      CelestiaNitroContracts2Point1Point3UpgradeAction.perform,
      (rollup, address(inbox), proxyAdmin)
    );

    // execute the upgrade
    // action checks prerequisites, and script will fail if the action reverts
    IUpgradeExecutor executor = IUpgradeExecutor(
      vm.envAddress('PARENT_UPGRADE_EXECUTOR_ADDRESS')
    );

    vm.startBroadcast();
    executor.execute(address(upgradeAction), upgradeCalldata);

    // sanity check, full checks are done on-chain by the upgrade action
    require(
      rollup.wasmModuleRoot() == upgradeAction.newWasmModuleRoot(),
      'Wasm module root not set'
    );
    require(
      rollup.wasmModuleRoot() == wasmModuleRoot,
      'Unexpected wasm module root set'
    );

    vm.stopBroadcast();
  }
}
