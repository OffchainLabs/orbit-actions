// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import { DeploymentHelpersScript } from '../../helper/DeploymentHelpers.s.sol';
import { CelestiaNitroContracts2Point1Point0UpgradeAction, IOneStepProofEntry } from '../../../../contracts/parent-chain/contract-upgrades/CelestiaNitroContracts2Point1Point0UpgradeAction.sol';
import { MockArbSys } from '../../helper/MockArbSys.sol';

/**
 * @title DeployCelestiaNitroContracts2Point1Point0UpgradeActionScript
 * @notice This script deploys OSPs, ChallengeManager and Rollup templates, and the upgrade action for Celestia 3.2.1
 */
contract DeployCelestiaNitroContracts2Point1Point0UpgradeActionScript is
  DeploymentHelpersScript
{
  // https://github.com/celestiaorg/nitro/releases/tag/v3.2.1-rc.1
  bytes32 public constant WASM_MODULE_ROOT =
    0xe81f986823a85105c5fd91bb53b4493d38c0c26652d23f76a7405ac889908287;

  // ArbOS v20 https://github.com/OffchainLabs/nitro/releases/tag/consensus-v20
  bytes32 public constant COND_WASM_MODULE_ROOT =
    0x184884e1eb9fefdc158f6c8ac912bb183bf3cf83f0090317e0bc4ac5860baa39;

  function run() public {
    bool isArbitrum = vm.envBool('PARENT_CHAIN_IS_ARBITRUM');
    if (isArbitrum) {
      // etch a mock ArbSys contract so that foundry simulate it nicely
      bytes memory mockArbSysCode = address(new MockArbSys()).code;
      vm.etch(address(100), mockArbSysCode);
    }

    vm.startBroadcast();

    address newOsp = vm.envAddress('NEW_OSP');

    address condOsp = vm.envAddress('COND_OSP');

    address challengeManager = vm.envAddress('NEW_CHALLENGE_MANAGER');

    address newRollupAdminLogic = vm.envAddress('NEW_ROLLUP_ADMIN');

    address newRollupUserLogic = vm.envAddress('NEW_ROLLUP_USER_LOGIC');

    address newSequencerInbox = vm.envAddress('NEW_SEQUENCER_INBOX');

    // finally deploy upgrade action
    new CelestiaNitroContracts2Point1Point0UpgradeAction({
      _newWasmModuleRoot: WASM_MODULE_ROOT,
      _newSequencerInboxImpl: newSequencerInbox,
      _newChallengeManagerImpl: challengeManager,
      _osp: IOneStepProofEntry(newOsp),
      _condRoot: COND_WASM_MODULE_ROOT,
      _condOsp: IOneStepProofEntry(condOsp),
      _newRollupAdminLogic: newRollupAdminLogic,
      _newRollupUserLogic: newRollupUserLogic
    });

    vm.stopBroadcast();
  }
}
