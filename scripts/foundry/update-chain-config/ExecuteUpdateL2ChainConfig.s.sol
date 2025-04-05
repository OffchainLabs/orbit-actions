// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "forge-std/Script.sol";
import {IERC20Inbox} from "@arbitrum/nitro-contracts-2.1.0/src/bridge/IERC20Inbox.sol";
import {IInbox} from "@arbitrum/nitro-contracts-2.1.0/src/bridge/IInbox.sol";
import {IUpgradeExecutor} from "@offchainlabs/upgrade-executor/src/IUpgradeExecutor.sol";
import {ArbOwner} from "@arbitrum/nitro-contracts-2.1.0/src/precompiles/ArbOwner.sol";
import {console} from "forge-std/console.sol";
import "forge-std/interfaces/IERC20.sol";

contract ExecuteUpdateL2ChainConfigScript is Script {
    function run() public {
        bool ct = vm.envBool("CUSTOM_TOKEN_ENABLED");
        bool multisig = vm.envBool("MULTISIG");
        address parentUpgradeExecutor = vm.envAddress("PARENT_UPGRADE_EXECUTOR_ADDRESS");
        address upgradeExecutorL2 = vm.envAddress("UPGRADE_EXECUTOR_L2");
        string memory chainData = vm.readFile("/tmp/yala2.json");
        address l2ArbOwner = 0x0000000000000000000000000000000000000070;
        IUpgradeExecutor executor = IUpgradeExecutor(parentUpgradeExecutor);
        ArbOwner arbOwner = ArbOwner(l2ArbOwner);


        bytes memory data =
            abi.encodeWithSelector(arbOwner.setChainConfig.selector, chainData);

        bytes memory onL2data = abi.encodeWithSelector(executor.executeCall.selector, l2ArbOwner, data);

        bytes memory inboxData;
        if (ct) {
            uint256 maxFeePerGas = 10 gwei;
            uint256 gasLimit = 1_000_0000;
            uint256 gasPrice = 10 gwei;
            uint256 tokenTotalFeeAmount = gasLimit * gasPrice;
            inboxData = abi.encodeCall(
            IERC20Inbox.createRetryableTicket,
                (
                    upgradeExecutorL2,
                    0,
                    0,
                    vm.envAddress("EXCESS_FEE_REFUND_ADDRESS"),
                    vm.envAddress("EXCESS_FEE_REFUND_ADDRESS"),
                    gasLimit,
                    maxFeePerGas,
                    tokenTotalFeeAmount,
                    onL2data
                )
            );
        } else {
            uint256 gasLimit = 20000000;
            uint256 maxFeePerGas = 0.00000002 ether;
            uint maxSubmissionCost = 0.1 ether;
            inboxData = abi.encodeCall(
            IInbox.createRetryableTicket,
                (
                    upgradeExecutorL2,
                    0,
                    maxSubmissionCost,
                    vm.envAddress("EXCESS_FEE_REFUND_ADDRESS"),
                    vm.envAddress("EXCESS_FEE_REFUND_ADDRESS"),
                    gasLimit, 
                    maxFeePerGas,
                    onL2data
                )
            );
        }
        

      //  uint256 gasPrice = 10 gwei;
      //  uint256 gasLimit = 1_000_0000;
      //  uint256 maxGas = 1_000_0000;
      //  bytes memory inboxData = abi.encodeCall(
      //      IERC20Inbox.createRetryableTicket,
      //      (
      //          upgradeExecutorL2,
      //          0,
      //         0,
      //          vm.envAddress("EXCESS_FEE_REFUND_ADDRESS"),
      //          vm.envAddress("EXCESS_FEE_REFUND_ADDRESS"),
      //          maxGas,
      //          gasPrice,
      //          gasLimit * gasPrice,
      //          onL2data
      //      )
      //  );


        if (ct) {
            bytes memory approveERC20Inbox =
                abi.encodeCall(IERC20.approve, (vm.envAddress("INBOX_ADDRESS"), 2 ** 256 - 1));
            if (!multisig) {
                vm.startBroadcast();
                executor.executeCall(vm.envAddress("CUSTOM_TOKEN"), approveERC20Inbox);
                vm.stopBroadcast();
            } else {
                console.log("First TX:");
                console.logString("L1 executor executeCall(vm.envAddress(CUSTOM_TOKEN), approveERC20Inbox)");
                console.log("Executor address");
                console.logAddress(parentUpgradeExecutor);
                console.logString("Custom token address");
                console.logAddress(vm.envAddress("CUSTOM_TOKEN"));
                console.logString("Calldata:");
                console.logBytes(approveERC20Inbox);
            }
        }

        if (!multisig) {
            vm.startBroadcast();

            //{ value: 100000 gwei } for non fee token chains

            executor.executeCall{ value: 1 ether }(vm.envAddress("INBOX_ADDRESS"), inboxData);
            vm.stopBroadcast();
        } else {
            console.log("Use calldata below to initiate tx towards %s", "executor");
            console.logString("executor.executeCall(inbox.address, inboxData)");
            console.logString("Create Retryable Ticket");
            console.log("Executor");
            console.logAddress(parentUpgradeExecutor);
            console.log("INBOX_ADDRESS");
            console.logAddress(vm.envAddress("INBOX_ADDRESS"));
            console.log("Calldata");
            console.logBytes(inboxData);
        }
    }
}
