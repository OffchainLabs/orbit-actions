// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "forge-std/Script.sol";
import {IInbox} from "@arbitrum/nitro-contracts-2.1.0/src/bridge/IInbox.sol";
import {ArbOwner} from "@arbitrum/nitro-contracts-2.1.0/src/precompiles/ArbOwner.sol";
/*import {UpgradeArbOSVersionAtTimestampAction} from
   "../../../../contracts/child-chain/arbos-upgrade/UpgradeArbOSVersionAtTimestampAction.sol";
*/
/**
 * @title ExecuteUpgradeArbOSVersionAtTimestampActionScript
 * @notice This script deploys UpgradeArbOSVersionAtTimestampAction
 */
contract ExecuteUpgradeArbOSVersionAtTimestampActionScript is Script {
    function run() public {
        vm.startBroadcast();
        bool multisig = vm.bool("MULTISIG")
        address parentUpgradeExecutor = vm.envAddress("PARENT_UPGRADE_EXECUTOR_ADDRESS");
        address feeWallet = vm.envAddress("EXCESS_FEE_REFUND_ADDRESS");
        uint256 arbosVersion = vm.envUint("ARBOS_VERSION");
        uint256 scheduleTimestamp = vm.envUint("SCHEDULE_TIMESTAMP");
        IInbox public inbox = IInbox(vm.envAddress("INBOX"));
        address upgradeExecutorL2 = vm.envAddress("UPGRADE_EXECUTOR_L2");
        address l2ArbOwner = 0x0000000000000000000000000000000000000070;
        
        ArbOwner arbOwner = ArbOwner(l2ArbOwner);

        bytes memory data = abi.encodeWithSelector(arbOwner.scheduleArbOSUpgrade.selector, newArbOSVersion, upgradeTimestamp);
        bytes memory onL2data = abi.encodeWithSelector("executeCall(address, bytes)", arbOwner.address, data)

        uint256 maxSubmissionCost = 0.0 ether;
        uint256 maxGas = 1_000_000;
        uint256 gasPriceBid = 10 gwei;
        uint256 gasLimit = 1000000
        
        bytes memory inboxData = abi.encodeWithSelector(inbox.createRetryableTicket.selector, upgradeExecutorL2, 0, maxSubmissionCost, 
            feeWallet, feeWallet, 
            maxGas, gasPriceBid, gasLimit.mul(gasPriceBid), onL2data)

        if (arbosVersion == 0 || scheduleTimestamp == 0) {
            revert("ARBOS_VERSION and SCHEDULE_TIMESTAMP must be set");
        }

        if (arbosVersion > type(uint64).max || scheduleTimestamp > type(uint64).max) {
            revert("ARBOS_VERSION and SCHEDULE_TIMESTAMP must be uint64");
        }

        if multisig {
            IUpgradeExecutor executor = IUpgradeExecutor(parentUpgradeExecutor);
            executor.executeCall(inbox.address, inboxData);
        } else {
            console.log("Use calldata below to initiate tx towards", executor.address)
            console.log("executeCall(inbox.address, inboxData)")
        }

        console.logBytes(inboxData);

        vm.stopBroadcast();
    }
}
