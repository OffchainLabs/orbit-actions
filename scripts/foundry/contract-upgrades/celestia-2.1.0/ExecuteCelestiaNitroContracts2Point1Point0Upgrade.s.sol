// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import 'forge-std/Script.sol';
import { CelestiaNitroContracts2Point1Point0UpgradeAction, ProxyAdmin } from '../../../../contracts/parent-chain/contract-upgrades/CelestiaNitroContracts2Point1Point0UpgradeAction.sol';
import { IBridge } from '@arbitrum/nitro-contracts-2.1.0/src/bridge/IBridge.sol';
import { IRollupCore } from '@arbitrum/nitro-contracts-2.1.0/src/rollup/IRollupCore.sol';
import { IUpgradeExecutor } from '@offchainlabs/upgrade-executor/src/IUpgradeExecutor.sol';
import { IInboxBase } from '@arbitrum/nitro-contracts-1.2.1/src/bridge/IInboxBase.sol';
import { IERC20Inbox } from '@arbitrum/nitro-contracts-1.2.1/src/bridge/IERC20Inbox.sol';
import { IERC20Bridge } from '@arbitrum/nitro-contracts-1.2.1/src/bridge/IERC20Bridge.sol';
import { IIsUsingFeeToken } from '../../helper/IIsUsingFeeToken.sol';
import { ISequencerInbox } from '@arbitrum/nitro-contracts-1.2.1/src/bridge/ISequencerInbox.sol';

/**
 * @title ExecuteCelestiaNitroContracts1Point2Point1UpgradeScript
 * @notice This script executes celestia nitro contracts 2.1.0 upgrade through UpgradeExecutor
 */
contract ExecuteCelestiaNitroContracts2Point1Point0UpgradeScript is Script {
  function run() public {
    // used to check upgrade was successful
    bytes32 wasmModuleRoot = vm.envBytes32('TARGET_WASM_MODULE_ROOT');

    CelestiaNitroContracts2Point1Point0UpgradeAction upgradeAction = CelestiaNitroContracts2Point1Point0UpgradeAction(
        vm.envAddress('UPGRADE_ACTION_ADDRESS')
      );

    {
      bool isFeeTokenChain = vm.envBool('IS_FEE_TOKEN_CHAIN');
      IERC20Inbox sequencerInbox = IERC20Inbox(vm.envAddress('INBOX_ADDRESS'));
      uint256 maxDataSize = vm.envUint('MAX_DATA_SIZE');
      require(
        ISequencerInbox(upgradeAction.newSequencerInboxImpl()).maxDataSize() ==
          maxDataSize,
        'MAX_DATA_SIZE mismatch with action'
      );
      address bridge = address(sequencerInbox.bridge());
      try IERC20Bridge(bridge).nativeToken() returns (address feeToken) {
        require(
          isFeeTokenChain || feeToken == address(0),
          'IS_FEE_TOKEN_CHAIN mismatch'
        );
      } catch {
        require(!isFeeTokenChain, 'IS_FEE_TOKEN_CHAIN mismatch');
      }

      try sequencerInbox.maxDataSize() returns (uint256 _maxDataSize) {
        require(
          _maxDataSize == maxDataSize,
          'MAX_DATA_SIZE mismatch with current deployment'
        );
      } catch {
        require(maxDataSize == 117964);
      }
    }

    IInboxBase inbox = IInboxBase(vm.envAddress('INBOX_ADDRESS'));

    IRollupCore rollup = IRollupCore(address(inbox.bridge().rollup()));

    vm.startBroadcast();

    // prepare upgrade calldata
    ProxyAdmin proxyAdmin = ProxyAdmin(vm.envAddress('PROXY_ADMIN_ADDRESS'));
    bytes memory upgradeCalldata = abi.encodeCall(
      CelestiaNitroContracts2Point1Point0UpgradeAction.perform,
      (rollup, proxyAdmin)
    );

    // execute the upgrade
    IUpgradeExecutor executor = IUpgradeExecutor(
      vm.envAddress('PARENT_UPGRADE_EXECUTOR_ADDRESS')
    );
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
