// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "forge-std/Script.sol";

interface IInbox {
    function bridge() external view returns (address);
}

interface IBridge {
    function nativeTokenDecimals() external view returns (uint8);
}

/**
 * @title VerifyNitroContracts2Point1Point2Upgrade
 * @notice Verifies the upgrade to Nitro Contracts 2.1.2 by checking nativeTokenDecimals
 */
contract VerifyNitroContracts2Point1Point2Upgrade is Script {
    function run() public view {
        address inbox = vm.envAddress("INBOX_ADDRESS");
        address bridge = IInbox(inbox).bridge();
        uint8 decimals = IBridge(bridge).nativeTokenDecimals();
        console.log("nativeTokenDecimals:", decimals);
    }
}
