// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

interface IInbox {
    function bridge() external view returns (address);
    function sequencerInbox() external view returns (address);
    function allowListEnabled() external view returns (bool);
}

interface IERC20Bridge {
    function nativeToken() external view returns (address);
}

interface IERC20Bridge_v2 {
    function nativeTokenDecimals() external view returns (uint8);
}

/**
 * @title   NitroContracts2Point1Point3UpgradeAction
 * @notice  Upgrade the bridge to Inbox and SequencerInbox to v2.1.3
 *          Will revert if the bridge is an ERC20Bridge below v2.x.x
 */
contract NitroContracts2Point1Point3UpgradeAction {
    address public immutable newEthInboxImpl;
    address public immutable newERC20InboxImpl;
    address public immutable newEthSequencerInboxImpl;
    address public immutable newERC20SequencerInboxImpl;

    constructor(
        address _newEthInboxImpl,
        address _newERC20InboxImpl,
        address _newEthSequencerInboxImpl,
        address _newERC20SequencerInboxImpl
    ) {
        require(
            Address.isContract(_newEthInboxImpl),
            "NitroContracts2Point1Point3UpgradeAction: _newEthInboxImpl is not a contract"
        );
        require(
            Address.isContract(_newERC20InboxImpl),
            "NitroContracts2Point1Point3UpgradeAction: _newERC20InboxImpl is not a contract"
        );
        require(
            Address.isContract(_newEthSequencerInboxImpl),
            "NitroContracts2Point1Point3UpgradeAction: _newEthSequencerInboxImpl is not a contract"
        );
        require(
            Address.isContract(_newERC20SequencerInboxImpl),
            "NitroContracts2Point1Point3UpgradeAction: _newERC20SequencerInboxImpl is not a contract"
        );

        newEthInboxImpl = _newEthInboxImpl;
        newERC20InboxImpl = _newERC20InboxImpl;
        newEthSequencerInboxImpl = _newEthSequencerInboxImpl;
        newERC20SequencerInboxImpl = _newERC20SequencerInboxImpl;
    }

    function perform(address inbox, ProxyAdmin proxyAdmin) external {
        // older upgrade action used to use the "rollup" address as the argument
        // for 2.1.3 we cannot discover the inbox from the rollup, so instead we have to supply the inbox address
        // this can be dangerous because both `bridge()` and `sequencerInbox()` also exists in the rollup contract
        // the following check makes sure inbox is inbox as `allowListEnabled()` only exists in the inbox contract
        try IInbox(inbox).allowListEnabled() returns (bool) {}
        catch {
            revert("NitroContracts2Point1Point3UpgradeAction: inbox is not an inbox");
        }

        address bridge = IInbox(inbox).bridge();
        address sequencerInbox = IInbox(inbox).sequencerInbox();

        bool isERC20 = false;

        // if the bridge is an ERC20Bridge below v2.x.x, revert
        try IERC20Bridge(bridge).nativeToken() returns (address) {
            isERC20 = true;
            // it is an ERC20Bridge, check if it is on v2.x.x
            try IERC20Bridge_v2(address(bridge)).nativeTokenDecimals() returns (uint8) {}
            catch {
                // it is not on v2.x.x, revert
                revert("NitroContracts2Point1Point3UpgradeAction: bridge is an ERC20Bridge below v2.x.x");
            }
        } catch {}

        // upgrade the sequencer inbox
        proxyAdmin.upgrade({
            proxy: TransparentUpgradeableProxy(payable((sequencerInbox))),
            implementation: isERC20 ? newERC20SequencerInboxImpl : newEthSequencerInboxImpl
        });

        // upgrade the inbox
        proxyAdmin.upgrade({
            proxy: TransparentUpgradeableProxy(payable((inbox))),
            implementation: isERC20 ? newERC20InboxImpl : newEthInboxImpl
        });
    }
}
