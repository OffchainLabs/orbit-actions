// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "forge-std/Script.sol";

interface IInbox {
    function bridge() external view returns (address);
}

interface IBridge {
    function nativeTokenDecimals() external view returns (uint8);
    function sequencerInbox() external view returns (address);
}

interface ISequencerInbox {
    function addSequencerL2BatchFromOrigin(
        uint256 sequenceNumber,
        bytes calldata data,
        uint256 afterDelayedMessagesRead,
        address gasRefunder,
        uint256 prevMessageCount,
        uint256 newMessageCount
    ) external;
}

/**
 * @title VerifyNitroContracts2Point1Point3Upgrade
 * @notice Verifies the upgrade to Nitro Contracts 2.1.3 by checking that the addSequencerL2BatchFromOrigin function reverts with NotCodelessOrigin()
 */
contract VerifyNitroContracts2Point1Point3Upgrade is Script {
    function run() public {
        address inbox = vm.envAddress("INBOX_ADDRESS");
        
        // make sure addSequencerL2BatchFromOrigin reverts with NotCodelessOrigin()
        // old check is just tx.origin == msg.sender, now we have an extra check for codelessness
        address sequencerInbox = IBridge(IInbox(inbox).bridge()).sequencerInbox();
        address dummy = address(0x1234);
        vm.etch(dummy, hex"4321");
        vm.prank(dummy, dummy);
        vm.expectRevert(abi.encodeWithSignature("NotCodelessOrigin()"));
        ISequencerInbox(sequencerInbox).addSequencerL2BatchFromOrigin(0, "", 0, address(0), 0, 0);
    }
}
