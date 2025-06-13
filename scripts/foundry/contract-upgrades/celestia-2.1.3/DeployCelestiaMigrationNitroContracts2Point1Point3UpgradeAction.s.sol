// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import { DeploymentHelpersScript } from '../../helper/DeploymentHelpers.s.sol';
import { CelestiaNitroContracts2Point1Point3UpgradeAction, IOneStepProofEntry } from '../../../../contracts/parent-chain/contract-upgrades/CelestiaNitroContracts2Point1Point3UpgradeAction.sol';
import { MockArbSys } from '../../helper/MockArbSys.sol';

/**
 * @title DeployNitroContracts2Point1Point3UpgradeActionScript
 * @notice This script deploys the ERC20Bridge contract and NitroContracts2Point1Point3UpgradeAction contract.
 */
contract DeployCelestiaMigrationNitroContracts2Point1Point3UpgradeActionScript is
  DeploymentHelpersScript
{
  // https://github.com/celestiaorg/nitro/releases/tag/v3.2.1-rc.1
  bytes32 public constant WASM_MODULE_ROOT =
    0xe81f986823a85105c5fd91bb53b4493d38c0c26652d23f76a7405ac889908287;

  // ArbOS v32 bianca
  // this script assumes that the rollup we're MIGRATING (not UPDATING) is on 2.1.3 and on latest bianca
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
          '/node_modules/celestia-nitro-contracts-2.1.0-no-ir/build/contracts/src/osp/celestia/ethereum/OneStepProverHostIo.sol/OneStepProverHostIo.json'
        );
      } else if (chainId == 11155111) {
        // sepolia
        ospHostIo = deployBytecodeFromJSON(
          '/node_modules/celestia-nitro-contracts-2.1.0-no-ir/build/contracts/src/osp/celestia/sepolia/OneStepProverHostIo.sol/OneStepProverHostIo.json'
        );
      } else if (chainId == 42161) {
        // arbitrum one
        ospHostIo = deployBytecodeFromJSON(
          '/node_modules/celestia-nitro-contracts-2.1.0-no-ir/build/contracts/src/osp/celestia/arbitrum-one/OneStepProverHostIo.sol/OneStepProverHostIo.json'
        );
      } else if (chainId == 421614) {
        // arbitrum sepolia
        ospHostIo = deployBytecodeFromJSON(
          '/node_modules/celestia-nitro-contracts-2.1.0-no-ir/build/contracts/src/osp/celestia/arbitrum-sepolia/OneStepProverHostIo.sol/OneStepProverHostIo.json'
        );
      } else if (chainId == 8453) {
        // base
        ospHostIo = deployBytecodeFromJSON(
          '/node_modules/celestia-nitro-contracts-2.1.0-no-ir/build/contracts/src/osp/celestia/base/OneStepProverHostIo.sol/OneStepProverHostIo.json'
        );
      } else if (chainId == 84532) {
        // base sepolia
        ospHostIo = deployBytecodeFromJSON(
          '/node_modules/celestia-nitro-contracts-2.1.0-no-ir/build/contracts/src/osp/celestia/base-sepolia/OneStepProverHostIo.sol/OneStepProverHostIo.json'
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
        '/node_modules/@arbitrum/nitro-contracts-1.3.0/build/contracts/src/osp/OneStepProverHostIo.sol/OneStepProverHostIo.json'
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

    address reader4844Address;
    if (!isArbitrum) {
      // deploy blob reader
      reader4844Address = deployBytecodeFromJSON(
        '/node_modules/@arbitrum/nitro-contracts-2.1.3/out/yul/Reader4844.yul/Reader4844.json'
      );
    }

    // deploy new ETHInbox contract from v2.1.3
    address newEthInboxImpl = deployBytecodeWithConstructorFromJSON(
      '/node_modules/@arbitrum/nitro-contracts-2.1.3/build/contracts/src/bridge/Inbox.sol/Inbox.json',
      abi.encode(vm.envUint('MAX_DATA_SIZE'))
    );
    // deploy new ERC20Inbox contract from v2.1.3
    address newERC20InboxImpl = deployBytecodeWithConstructorFromJSON(
      '/node_modules/@arbitrum/nitro-contracts-2.1.3/build/contracts/src/bridge/ERC20Inbox.sol/ERC20Inbox.json',
      abi.encode(vm.envUint('MAX_DATA_SIZE'))
    );

    // deploy new EthSequencerInbox contract from v2.1.3
    address newEthSeqInboxImpl = deployBytecodeWithConstructorFromJSON(
      '/node_modules/celestia-nitro-contracts-2.1.3-no-ir/build/contracts/src/bridge/SequencerInbox.sol/SequencerInbox.json',
      abi.encode(vm.envUint('MAX_DATA_SIZE'), reader4844Address, false)
    );

    // deploy new Erc20SequencerInbox contract from v2.1.3
    address newErc20SeqInboxImpl = deployBytecodeWithConstructorFromJSON(
      '/node_modules/celestia-nitro-contracts-2.1.3-no-ir/build/contracts/src/bridge/SequencerInbox.sol/SequencerInbox.json',
      abi.encode(vm.envUint('MAX_DATA_SIZE'), reader4844Address, true)
    );

    // deploy upgrade action
    new CelestiaNitroContracts2Point1Point3UpgradeAction({
      _newEthInboxImpl: newEthInboxImpl,
      _newERC20InboxImpl: newERC20InboxImpl,
      _newEthSequencerInboxImpl: newEthSeqInboxImpl,
      _newERC20SequencerInboxImpl: newErc20SeqInboxImpl,
      _newWasmModuleRoot: WASM_MODULE_ROOT,
      _newChallengeManagerImpl: challengeManager,
      _osp: IOneStepProofEntry(newOsp),
      _condRoot: COND_WASM_MODULE_ROOT,
      _condOsp: IOneStepProofEntry(condOsp)
    });

    vm.stopBroadcast();
  }
}