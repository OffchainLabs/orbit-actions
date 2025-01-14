// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

interface IERC20Bridge {
    function nativeToken() external view returns (address);
}

interface IERC20Bridge_v2 {
    function nativeTokenDecimals() external view returns (uint8);
}

interface IERC20Bridge_v2_patch {
    function forceEighteenDecimalsPatch() external;
}

/**
 * @title   DeployNitroContracts2Point1Point2UpgradeActionScript
 * @notice  Force the ERC20Bridge contract to set nativeTokenDecimals to 18.
 *          Will revert if the bridge is not an ERC20Bridge.
 *          Will revert if ERC20Bridge is not v1.x.x
 */
contract NitroContracts2Point1Point2UpgradeAction {
    address public immutable newBridgeImpl;

    constructor(address _newBridgeImpl) {
        require(
            Address.isContract(_newBridgeImpl),
            "NitroContracts2Point1Point2UpgradeAction: _newBridgeImpl is not a contract"
        );

        newBridgeImpl = _newBridgeImpl;
    }

    function perform(address bridge, ProxyAdmin proxyAdmin) external {
        // ensure the bridge is an ERC20Bridge
        try IERC20Bridge(bridge).nativeToken() returns (address) {}
        catch {
            revert("NitroContracts2Point1Point2UpgradeAction: bridge is not an ERC20Bridge");
        }

        // ensure the bridge is v1.x.x
        try IERC20Bridge_v2(address(bridge)).nativeTokenDecimals() returns (uint8) {
            revert("NitroContracts2Point1Point2UpgradeAction: bridge is not v1.x.x");
        } catch {}

        // upgrade to the new implementation and call forceEighteenDecimalsPatch
        proxyAdmin.upgradeAndCall(
            TransparentUpgradeableProxy(payable((bridge))),
            newBridgeImpl,
            abi.encodeCall(IERC20Bridge_v2_patch.forceEighteenDecimalsPatch, ())
        );

        // ensure decimals were set to 18
        require(IERC20Bridge_v2((bridge)).nativeTokenDecimals() == 18, "decimals not set to 18");
    }
}
