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
    0x8b104a2e80ac6165dc58b9048de12f301d70b02a0ab51396c22b4b4b802a16a4;

  function run() public {
    bool isArbitrum = vm.envBool('PARENT_CHAIN_IS_ARBITRUM');
    if (isArbitrum) {
      // etch a mock ArbSys contract so that foundry simulate it nicely
      bytes memory mockArbSysCode = address(new MockArbSys()).code;
      vm.etch(address(100), mockArbSysCode);
    }

    vm.startBroadcast();

    // deploy new osp from v2.1.0
    address newOsp;
    {
      address osp0 = deployBytecodeFromJSON(
        '/node_modules/@arbitrum/nitro-contracts-2.1.0/build/contracts/src/osp/OneStepProver0.sol/OneStepProver0.json'
      );
      address ospMemory = deployBytecodeFromJSON(
        '/node_modules/@arbitrum/nitro-contracts-2.1.0/build/contracts/src/osp/OneStepProverMemory.sol/OneStepProverMemory.json'
      );
      address ospMath = deployBytecodeFromJSON(
        '/node_modules/@arbitrum/nitro-contracts-2.1.0/build/contracts/src/osp/OneStepProverMath.sol/OneStepProverMath.json'
      );
      address ospHostIo;

      uint chainId = vm.envUint('CHAIN_ID');
      if (chainId == 1) {
        ospHostIo = deployBytecodeFromJSON(
          '/celestia-2.1.0/mainnet/OneStepProverHostIo.sol/OneStepProverHostIo.json'
        );
      } else if (chainId == 11155111) {
        // sepolia
        ospHostIo = deployBytecodeFromJSON(
          '/celestia-2.1.0/sepolia/OneStepProverHostIo.sol/OneStepProverHostIo.json'
        );
      } else if (chainId == 42161) {
        // arbitrum one
        ospHostIo = deployBytecodeFromJSON(
          '/celestia-2.1.0/arbitrum-one/OneStepProverHostIo.sol/OneStepProverHostIo.json'
        );
      } else if (chainId == 421614) {
        // arbitrum sepolia
        ospHostIo = deployBytecodeFromJSON(
          '/celestia-2.1.0/arbitrum-sepolia/OneStepProverHostIo.sol/OneStepProverHostIo.json'
        );
      } else if (chainId == 8453) {
        // base
        ospHostIo = deployBytecodeFromJSON(
          '/celestia-2.1.0/base/OneStepProverHostIo.sol/OneStepProverHostIo.json'
        );
      } else if (chainId == 84532) {
        // base sepolia
        ospHostIo = deployBytecodeFromJSON(
          '/celestia-2.1.0/base-sepolia/OneStepProverHostIo.sol/OneStepProverHostIo.json'
        );
      }

      newOsp = deployBytecodeWithConstructorFromJSON(
        '/node_modules/@arbitrum/nitro-contracts-2.1.0/build/contracts/src/osp/OneStepProofEntry.sol/OneStepProofEntry.json',
        abi.encode(osp0, ospMemory, ospMath, ospHostIo)
      );
    }

    // deploy condOsp from v1.3.0
    address condOsp;
    {
      address osp0 = deployBytecodeFromJSON(
        '/node_modules/@arbitrum/nitro-contracts-1.3.0/build/contracts/src/osp/OneStepProver0.sol/OneStepProver0.json'
      );
      address ospMemory = deployBytecodeFromJSON(
        '/node_modules/@arbitrum/nitro-contracts-1.3.0/build/contracts/src/osp/OneStepProverMemory.sol/OneStepProverMemory.json'
      );
      address ospMath = deployBytecodeFromJSON(
        '/node_modules/@arbitrum/nitro-contracts-1.3.0/build/contracts/src/osp/OneStepProverMath.sol/OneStepProverMath.json'
      );

      address ospHostIo = deployBytecodeFromJSON(
        '/node_modules/@arbitrum/nitro-contracts-2.1.0/build/contracts/src/osp/OneStepProverHostIo.sol/OneStepProverHostIo.json'
      );

      condOsp = deployBytecodeWithConstructorFromJSON(
        '/node_modules/@arbitrum/nitro-contracts-1.3.0/build/contracts/src/osp/OneStepProofEntry.sol/OneStepProofEntry.json',
        abi.encode(osp0, ospMemory, ospMath, ospHostIo)
      );
    }

    // deploy new challenge manager from v2.1.0
    address challengeManager = deployBytecodeFromJSON(
      '/node_modules/@arbitrum/nitro-contracts-2.1.0/build/contracts/src/challenge/ChallengeManager.sol/ChallengeManager.json'
    );

    // deploy new RollupAdminLogic contract from v2.1.0
    address newRollupAdminLogic = deployBytecodeFromJSON(
      '/node_modules/@arbitrum/nitro-contracts-2.1.0/build/contracts/src/rollup/RollupAdminLogic.sol/RollupAdminLogic.json'
    );

    // deploy new RollupUserLogic contract from v2.1.0
    address newRollupUserLogic = deployBytecodeFromJSON(
      '/node_modules/@arbitrum/nitro-contracts-2.1.0/build/contracts/src/rollup/RollupUserLogic.sol/RollupUserLogic.json'
    );

    address reader4844Address;
    if (!isArbitrum) {
      // deploy blob reader
      reader4844Address = deployBytecodeFromJSON(
        '/node_modules/@arbitrum/nitro-contracts-1.2.1/out/yul/Reader4844.yul/Reader4844.json'
      );
    }

    if (vm.envOr('DEPLOY_BOTH', false)) {
      // if true, also deploy the !IS_FEE_TOKEN_CHAIN action
      // only used to save gas cost when deploying both native and custom fee version

      // deploy sequencer inbox template
      address newSequencerInbox2 = deployBytecodeWithConstructorFromJSON(
        '/celestia-2.1.0/SequencerInbox.sol/SequencerInbox.json',
        abi.encode(
          vm.envUint('MAX_DATA_SIZE'),
          reader4844Address,
          !vm.envBool('IS_FEE_TOKEN_CHAIN')
        )
      );

      new CelestiaNitroContracts2Point1Point0UpgradeAction({
        _newWasmModuleRoot: WASM_MODULE_ROOT,
        _newSequencerInboxImpl: newSequencerInbox2,
        _newChallengeManagerImpl: challengeManager,
        _osp: IOneStepProofEntry(newOsp),
        _condRoot: COND_WASM_MODULE_ROOT,
        _condOsp: IOneStepProofEntry(condOsp),
        _newRollupAdminLogic: newRollupAdminLogic,
        _newRollupUserLogic: newRollupUserLogic
      });
    }

    address newSequencerInbox = deployBytecodeWithConstructorFromJSON(
      '/celestia-2.1.0/SequencerInbox.sol/SequencerInbox.json',
      abi.encode(
        vm.envUint('MAX_DATA_SIZE'),
        reader4844Address,
        vm.envBool('IS_FEE_TOKEN_CHAIN')
      )
    );

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
