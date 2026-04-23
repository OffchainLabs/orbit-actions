// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "forge-std/Script.sol";

interface IRollupAdmin {
    function owner() external view returns (address);
    function increaseBaseStake(uint256 newBaseStake) external;
}

/**
 * @title VerifyNitroContracts3Point2Point0Upgrade
 * @notice Verifies the upgrade to Nitro Contracts 3.2.0 by checking that
 *         increaseBaseStake (new in v3.2.0) is callable on the rollup.
 */
contract VerifyNitroContracts3Point2Point0Upgrade is Script {
    function run() public {
        address rollup = vm.envAddress("ROLLUP_ADDRESS");
        address owner = IRollupAdmin(rollup).owner();

        vm.prank(owner);
        IRollupAdmin(rollup).increaseBaseStake(type(uint256).max);

        console.log("Verification passed: increaseBaseStake is available (v3.2.0)");
    }
}
