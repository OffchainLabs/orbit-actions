// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "@arbitrum/nitro-contracts-1.2.1/src/bridge/IInbox.sol";
import "@arbitrum/nitro-contracts-1.2.1/src/rollup/IRollupAdmin.sol";
import "@arbitrum/nitro-contracts-1.2.1/src/rollup/IRollupCore.sol";

/// @dev    Modified from
///         https://github.com/ArbitrumFoundation/governance/blob/dcb85dc0ac0e6e5d72dd94b721c3655bec3b7639/src/gov-action-contracts/arbos-upgrade/SetWasmModuleRootAction.sol
contract SetWasmModuleRootAction {
    bytes32 public immutable previousWasmModuleRoot;
    bytes32 public immutable newWasmModuleRoot;

    constructor(bytes32 _previousWasmModuleRoot, bytes32 _newWasmModuleRoot) {
        previousWasmModuleRoot = _previousWasmModuleRoot;
        newWasmModuleRoot = _newWasmModuleRoot;
    }

    function perform(address inbox) external {
        address rollup = address(IInbox(inbox).bridge().rollup());

        // verify previous wasm module root
        require(
            IRollupCore(rollup).wasmModuleRoot() == previousWasmModuleRoot,
            "SetWasmModuleRootAction: unexpected previous wasm module root"
        );

        IRollupAdmin(rollup).setWasmModuleRoot(newWasmModuleRoot);

        // verify:
        require(
            IRollupCore(rollup).wasmModuleRoot() == newWasmModuleRoot,
            "SetWasmModuleRootAction: wasm module root not set"
        );
    }
}
