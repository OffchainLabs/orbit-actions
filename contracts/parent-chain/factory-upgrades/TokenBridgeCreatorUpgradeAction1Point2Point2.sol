// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

interface IL1AtomicTokenBridgeCreator {
    function retryableSender() external returns (address);
}

/**
 * @title TokenBridgeCreatorUpgradeAction1Point2Point2
 * @notice Upgrade token bridge creator logic contracts to token bridge releases v1.2.2.
 *         Contains support for deploying token bridge on non-18 decimals fee token chains.
 */
contract TokenBridgeCreatorUpgradeAction1Point2Point2 {
    address public newL1AtomicTokenBridgeCreatorLogic;
    address public newL1TokenBridgeRetryableSenderLogic;

    constructor(address _newL1AtomicTokenBridgeCreatorLogic, address _newL1TokenBridgeRetryableSenderLogic) {
        require(Address.isContract(_newL1AtomicTokenBridgeCreatorLogic), "Invalid token bridge creator logic");
        require(Address.isContract(_newL1TokenBridgeRetryableSenderLogic), "Invalid retryable sender logic");

        newL1AtomicTokenBridgeCreatorLogic = _newL1AtomicTokenBridgeCreatorLogic;
        newL1TokenBridgeRetryableSenderLogic = _newL1TokenBridgeRetryableSenderLogic;
    }

    function perform(ProxyAdmin proxyAdmin, address tokenBridgeCreator) external {
        address _newL1AtomicTokenBridgeCreatorLogic = newL1AtomicTokenBridgeCreatorLogic;
        address _newL1TokenBridgeRetryableSenderLogic = newL1TokenBridgeRetryableSenderLogic;

        TransparentUpgradeableProxy _tokenBridgeCreator = TransparentUpgradeableProxy(payable(tokenBridgeCreator));
        TransparentUpgradeableProxy _retryableSender =
            TransparentUpgradeableProxy(payable(IL1AtomicTokenBridgeCreator(tokenBridgeCreator).retryableSender()));

        // upgrade logic contracts
        proxyAdmin.upgrade(_tokenBridgeCreator, newL1AtomicTokenBridgeCreatorLogic);
        proxyAdmin.upgrade(_retryableSender, newL1TokenBridgeRetryableSenderLogic);

        // verify
        require(
            proxyAdmin.getProxyImplementation(_tokenBridgeCreator) == _newL1AtomicTokenBridgeCreatorLogic,
            "Token bridge creator upgrade failed"
        );
        require(
            proxyAdmin.getProxyImplementation(_retryableSender) == _newL1TokenBridgeRetryableSenderLogic,
            "Retryable sender upgrade failed"
        );
    }
}
