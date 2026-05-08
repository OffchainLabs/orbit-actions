// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

interface IRollupAdminLogic {
    function upgradeSecondaryTo(address newImplementation) external;
    function upgradeTo(address newImplementation) external;
}

/**
 * @title   NitroContracts3Point2Point0UpgradeAction
 * @notice  Upgrade action for nitro contracts v3.2.0
 * @dev     Only upgrades Rollup contract, other diff between v3.2.0 and v3.1.0 are irrelevant.
 */
contract NitroContracts3Point2Point0UpgradeAction {
    address public immutable newRollupAdminLogicImpl;
    address public immutable newRollupUserLogicImpl;

    constructor(address _newRollupAdminLogicImpl, address _newRollupUserLogicImpl) {
        require(_newRollupAdminLogicImpl.code.length > 0, "invalid rollup admin logic impl");
        require(_newRollupUserLogicImpl.code.length > 0, "invalid rollup user logic impl");
        newRollupAdminLogicImpl = _newRollupAdminLogicImpl;
        newRollupUserLogicImpl = _newRollupUserLogicImpl;
    }

    function perform(address rollup) external {
        // skip sequencer inbox upgrade since it only adds custom DA header support
        // skip OSP upgrade since it only adds custom DA validation support

        // RollupAdminLogic is the primary implementation
        // RollupUserLogic is the secondary implementation
        // see: https://github.com/OffchainLabs/nitro-contracts/blob/d9a2f3353ff13c706b7807b097e7ba591d970d85/src/libraries/AdminFallbackProxy.sol#L141-L143

        IRollupAdminLogic(rollup).upgradeTo(newRollupAdminLogicImpl);
        IRollupAdminLogic(rollup).upgradeSecondaryTo(newRollupUserLogicImpl);
    }
}
