// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

contract SampleForkTest is Test {
    function testCode() public {
        // Arb1 Sequencer Inbox
        assertGt(0x1c479675ad559DC151F6Ec7ed3FbF8ceE79582B6.code.length, 0);
    }
}
