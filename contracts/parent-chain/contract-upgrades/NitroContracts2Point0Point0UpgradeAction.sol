// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "@arbitrum/nitro-contracts-2.0.0/src/osp/IOneStepProofEntry.sol";
import "@arbitrum/nitro-contracts-2.0.0/src/rollup/IRollupAdmin.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

interface IChallengeManagerUpgradeInit {
    function postUpgradeInit(IOneStepProofEntry osp_, bytes32 condRoot, IOneStepProofEntry condOsp) external;
    function osp() external returns (address);
}

// @notice set wasm module root and upgrade challenge manager for stylus ArbOS upgrade
contract NitroContracts2Point0Point0UpgradeAction {
    bytes32 public immutable newWasmModuleRoot;
    address public immutable newChallengeManagerImpl;
    IOneStepProofEntry public immutable osp;
    bytes32 public immutable condRoot;
    IOneStepProofEntry public immutable condOsp;

    constructor(
        bytes32 _newWasmModuleRoot,
        address _newChallengeManagerImpl,
        IOneStepProofEntry _osp,
        bytes32 _condRoot,
        IOneStepProofEntry _condOsp
    ) {
        require(
            _newWasmModuleRoot != bytes32(0), "NitroContracts2Point0Point0UpgradeAction: _newWasmModuleRoot is empty"
        );
        require(
            Address.isContract(_newChallengeManagerImpl),
            "NitroContracts2Point0Point0UpgradeAction: _newChallengeManagerImpl is not a contract"
        );
        require(Address.isContract(address(_osp)), "NitroContracts2Point0Point0UpgradeAction: _osp is not a contract");
        require(
            Address.isContract(address(_condOsp)),
            "NitroContracts2Point0Point0UpgradeAction: _condOsp is not a contract"
        );

        newWasmModuleRoot = _newWasmModuleRoot;
        newChallengeManagerImpl = _newChallengeManagerImpl;
        osp = _osp;
        condRoot = _condRoot;
        condOsp = _condOsp;
    }

    function perform(IRollupCore rollup, ProxyAdmin proxyAdmin) external {
        // set the new challenge manager impl
        TransparentUpgradeableProxy challengeManager =
            TransparentUpgradeableProxy(payable(address(rollup.challengeManager())));
        proxyAdmin.upgradeAndCall(
            challengeManager,
            newChallengeManagerImpl,
            abi.encodeCall(IChallengeManagerUpgradeInit.postUpgradeInit, (osp, condRoot, condOsp))
        );

        // verify
        require(
            proxyAdmin.getProxyImplementation(challengeManager) == newChallengeManagerImpl,
            "NitroContracts2Point0Point0UpgradeAction: new challenge manager implementation set"
        );
        require(
            IChallengeManagerUpgradeInit(address(challengeManager)).osp() == address(osp),
            "NitroContracts2Point0Point0UpgradeAction: new OSP not set"
        );

        // set new wasm module root
        IRollupAdmin(address(rollup)).setWasmModuleRoot(newWasmModuleRoot);

        // verify:
        require(
            rollup.wasmModuleRoot() == newWasmModuleRoot,
            "NitroContracts2Point0Point0UpgradeAction: wasm module root not set"
        );
    }
}
