// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "forge-std/Script.sol";

interface IRollupCore {
    function wasmModuleRoot() external view returns (bytes32);
}

/**
 * @title VerifyNitroContracts1Point2Point1Upgrade
 * @notice Verifies the upgrade to Nitro Contracts 1.2.1 by checking the wasmModuleRoot
 */
contract VerifyNitroContracts1Point2Point1Upgrade is Script {
    function run() public view {
        address rollup = vm.envAddress("ROLLUP");
        bytes32 wasmRoot = IRollupCore(rollup).wasmModuleRoot();
        console.log("wasmModuleRoot:");
        console.logBytes32(wasmRoot);
    }
}
