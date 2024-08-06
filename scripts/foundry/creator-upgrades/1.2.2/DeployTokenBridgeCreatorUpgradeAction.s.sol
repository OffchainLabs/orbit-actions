// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {DeploymentHelpersScript} from "../../helper/DeploymentHelpers.s.sol";
import {MockArbSys} from "../../helper/MockArbSys.sol";
import {TokenBridgeCreatorUpgradeAction1Point2Point2} from
    "../../../../contracts/parent-chain/factory-upgrades/TokenBridgeCreatorUpgradeAction1Point2Point2.sol";
/**
 * @title DeployScript
 * @notice This script will deploy new token bridge creator logic contracts and the action to be used by token bridge creator admin.
 */

contract DeployTokenBridgeCreatorUpgradeAction is DeploymentHelpersScript {
    bool public isArbitrum;

    function run() public {
        isArbitrum = vm.envBool("PARENT_CHAIN_IS_ARBITRUM");
        if (isArbitrum) {
            // etch a mock ArbSys contract so that foundry simulate it nicely
            bytes memory mockArbSysCode = address(new MockArbSys()).code;
            vm.etch(address(100), mockArbSysCode);
        }

        vm.startBroadcast();

        address newL1AtomicTokenBridgeCreatorLogic = deployBytecodeFromJSON(
            "/node_modules/@arbitrum/token-bridge-1.2.2/build/contracts/contracts/tokenbridge/ethereum/L1AtomicTokenBridgeCreator.sol/L1AtomicTokenBridgeCreator.json"
        );
        address newL1TokenBridgeRetryableSenderLogic = deployBytecodeFromJSON(
            "/node_modules/@arbitrum/token-bridge-1.2.2/build/contracts/contracts/tokenbridge/ethereum/L1TokenBridgeRetryableSender.sol/L1TokenBridgeRetryableSender.json"
        );

        // deploy TokenBridgeCreatorUpgradeAction1Point2Point2
        address(
            new TokenBridgeCreatorUpgradeAction1Point2Point2(
                newL1AtomicTokenBridgeCreatorLogic, newL1TokenBridgeRetryableSenderLogic
            )
        );

        vm.stopBroadcast();
    }
}
