// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {DeploymentHelpersScript} from "../../helper/DeploymentHelpers.s.sol";
import {NitroContracts2Point1Point3UpgradeAction} from
    "../../../../contracts/parent-chain/contract-upgrades/NitroContracts2Point1Point3UpgradeAction.sol";
import {MockArbSys} from "../../helper/MockArbSys.sol";

/**
 * @title DeployNitroContracts2Point1Point3UpgradeActionScript
 * @notice This script deploys the ERC20Bridge contract and NitroContracts2Point1Point3UpgradeAction contract.
 */
contract DeployNitroContracts2Point1Point3UpgradeActionScript is DeploymentHelpersScript {
    function run() public {
        bool isArbitrum = vm.envBool("PARENT_CHAIN_IS_ARBITRUM");
        if (isArbitrum) {
            // etch a mock ArbSys contract so that foundry simulate it nicely
            bytes memory mockArbSysCode = address(new MockArbSys()).code;
            vm.etch(address(100), mockArbSysCode);
        }

        vm.startBroadcast();

        address reader4844Address;
        if (!isArbitrum) {
            // deploy blob reader
            reader4844Address = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-2.1.3/out/yul/Reader4844.yul/Reader4844.json"
            );
        }

        // deploy new ETHInbox contract from v2.1.3
        address newEthInboxImpl = deployBytecodeWithConstructorFromJSON(
            "/node_modules/@arbitrum/nitro-contracts-2.1.3/build/contracts/src/bridge/Inbox.sol/Inbox.json",
            abi.encode(vm.envUint("MAX_DATA_SIZE"))
        );
        // deploy new ERC20Inbox contract from v2.1.3
        address newERC20InboxImpl = deployBytecodeWithConstructorFromJSON(
            "/node_modules/@arbitrum/nitro-contracts-2.1.3/build/contracts/src/bridge/ERC20Inbox.sol/ERC20Inbox.json",
            abi.encode(vm.envUint("MAX_DATA_SIZE"))
        );

        if (vm.envOr("DEPLOY_BOTH", false)) {
            // if true, also deploy the !IS_FEE_TOKEN_CHAIN action
            // only used to save gas cost when deploying both native and custom fee version

            // deploy sequencer inbox template
            address newSeqInboxImpl2 = deployBytecodeWithConstructorFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-2.1.3/build/contracts/src/bridge/SequencerInbox.sol/SequencerInbox.json",
                abi.encode(vm.envUint("MAX_DATA_SIZE"), reader4844Address, !vm.envBool("IS_FEE_TOKEN_CHAIN"))
            );

            // finally deploy upgrade action
            new NitroContracts2Point1Point3UpgradeAction(newEthInboxImpl, newERC20InboxImpl, newSeqInboxImpl2);
        }

        // deploy new SequencerInbox contract from v2.1.3
        address newSeqInboxImpl = deployBytecodeWithConstructorFromJSON(
            "/node_modules/@arbitrum/nitro-contracts-2.1.3/build/contracts/src/bridge/SequencerInbox.sol/SequencerInbox.json",
            abi.encode(vm.envUint("MAX_DATA_SIZE"), reader4844Address, vm.envBool("IS_FEE_TOKEN_CHAIN"))
        );

        // deploy upgrade action
        new NitroContracts2Point1Point3UpgradeAction(newEthInboxImpl, newERC20InboxImpl, newSeqInboxImpl);

        vm.stopBroadcast();
    }
}
