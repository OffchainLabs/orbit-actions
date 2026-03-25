// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "forge-std/Script.sol";

interface IRollupCore {
    function wasmModuleRoot() external view returns (bytes32);
}

/**
 * @title VerifyNitroContracts2Point1Point0Upgrade
 * @notice Verifies the upgrade to Nitro Contracts 2.1.0 by checking the wasmModuleRoot
 */
contract VerifyNitroContracts2Point1Point0Upgrade is Script {
    function run() public view {
        address rollup = vm.envAddress("ROLLUP");
        bytes32 wasmRoot = IRollupCore(rollup).wasmModuleRoot();
        console.log("wasmModuleRoot:");
        console.logBytes32(wasmRoot);
    }
}
