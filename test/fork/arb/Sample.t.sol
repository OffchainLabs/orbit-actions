// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

contract SampleForkTest is Test {
    function testCode() public {
        // L2GatewayRouter
        assertGt(0x5288c571Fd7aD117beA99bF60FE0846C4E84F933.code.length, 0);
    }
}
