// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "forge-std/Test.sol";

import {Bridge, IOwnable} from "@arbitrum/nitro-contracts-2.1.2/src/bridge/Bridge.sol";
import {
    ERC20Bridge as ERC20Bridge_2_1_0,
    IOwnable as IOwnable_2_1_0
} from "@arbitrum/nitro-contracts-2.1.0/src/bridge/ERC20Bridge.sol";
import {Bridge as Bridge_2_1_0} from "@arbitrum/nitro-contracts-2.1.0/src/bridge/Bridge.sol";
import {ERC20Inbox as ERC20Inbox_2_1_0} from "@arbitrum/nitro-contracts-2.1.0/src/bridge/ERC20Inbox.sol";
import {
    Inbox as Inbox_2_1_0, IInboxBase as IInboxBase_2_1_0
} from "@arbitrum/nitro-contracts-2.1.0/src/bridge/Inbox.sol";
import {
    SequencerInbox as SequencerInbox_2_1_0,
    ISequencerInbox as ISequencerInbox_2_1_0
} from "@arbitrum/nitro-contracts-2.1.0/src/bridge/SequencerInbox.sol";
import {IReader4844 as IReader4844_2_1_0} from "@arbitrum/nitro-contracts-2.1.0/src/libraries/IReader4844.sol";

import {ERC20Bridge as ERC20Bridge_1_3_0} from "@arbitrum/nitro-contracts-1.3.0/src/bridge/ERC20Bridge.sol";

import {NitroContracts2Point1Point3UpgradeAction} from
    "contracts/parent-chain/contract-upgrades/NitroContracts2Point1Point3UpgradeAction.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {IUpgradeExecutor} from "@offchainlabs/upgrade-executor/src/IUpgradeExecutor.sol";
import {DeploymentHelpersScript} from "../../scripts/foundry/helper/DeploymentHelpers.s.sol";

interface IUpgradeExecutorExtended is IUpgradeExecutor {
    function initialize(address admin, address[] memory executors) external;
}

contract FakeToken {
    uint256 public decimals = 18;

    function allowance(address, address) external pure returns (uint256) {
        return 0;
    }

    function approve(address, uint256) external pure returns (bool) {
        return true;
    }
}

contract NitroContracts2Point1Point3UpgradeActionTest is Test, DeploymentHelpersScript {
    uint256 maxDataSize = 100_000; // dummy value

    IUpgradeExecutorExtended upgradeExecutor;

    address fakeToken;

    ProxyAdmin proxyAdmin;

    address fakeRollup = address(0xFF00);
    address fakeReader = address(0xFF01);

    address erc20Bridge_2_1_0;
    address bridge_2_1_0;
    address erc20SequencerInbox_2_1_0;
    address sequencerInbox_2_1_0;
    address erc20Inbox_2_1_0;
    address inbox_2_1_0;

    address newEthInboxImpl;
    address newERC20InboxImpl;
    address newEthSeqInboxImpl;
    address newErc20SeqInboxImpl;

    function setUp() public {
        // deploy a proxy admin
        proxyAdmin = new ProxyAdmin();

        // deploy an upgrade executor
        address[] memory execs = new address[](1);
        execs[0] = address(this);
        upgradeExecutor = IUpgradeExecutorExtended(
            address(
                new TransparentUpgradeableProxy(
                    deployBytecodeFromJSON(
                        "/node_modules/@offchainlabs/upgrade-executor/build/contracts/src/UpgradeExecutor.sol/UpgradeExecutor.json"
                    ),
                    address(proxyAdmin),
                    ""
                )
            )
        );
        upgradeExecutor.initialize(address(this), execs);

        proxyAdmin.transferOwnership(address(upgradeExecutor));

        // deploy a fake token
        fakeToken = address(new FakeToken());

        // deploy an ERC20Bridge on v2.1.0
        erc20Bridge_2_1_0 =
            address(new TransparentUpgradeableProxy(address(new ERC20Bridge_2_1_0()), address(proxyAdmin), ""));

        // deploy an ETH Bridge on v2.1.0
        bridge_2_1_0 = address(new TransparentUpgradeableProxy(address(new Bridge_2_1_0()), address(proxyAdmin), ""));

        // deploy an ERC20 SequencerInbox on v2.1.0
        erc20SequencerInbox_2_1_0 = address(
            new TransparentUpgradeableProxy(
                address(new SequencerInbox_2_1_0(maxDataSize, IReader4844_2_1_0(fakeReader), true)),
                address(proxyAdmin),
                ""
            )
        );

        // deploy an ETH SequencerInbox on v2.1.0
        sequencerInbox_2_1_0 = address(
            new TransparentUpgradeableProxy(
                address(new SequencerInbox_2_1_0(maxDataSize, IReader4844_2_1_0(fakeReader), false)),
                address(proxyAdmin),
                ""
            )
        );

        // deploy an ERC20Inbox on v2.1.0
        erc20Inbox_2_1_0 = address(
            new TransparentUpgradeableProxy(address(new ERC20Inbox_2_1_0(maxDataSize)), address(proxyAdmin), "")
        );

        // deploy an ETH Inbox on v2.1.0
        inbox_2_1_0 =
            address(new TransparentUpgradeableProxy(address(new Inbox_2_1_0(maxDataSize)), address(proxyAdmin), ""));

        // initialize everything
        Bridge_2_1_0(bridge_2_1_0).initialize(IOwnable_2_1_0(fakeRollup));
        ERC20Bridge_2_1_0(erc20Bridge_2_1_0).initialize(IOwnable_2_1_0(fakeRollup), fakeToken);
        SequencerInbox_2_1_0(sequencerInbox_2_1_0).initialize(
            Bridge_2_1_0(bridge_2_1_0), ISequencerInbox_2_1_0.MaxTimeVariation(10, 10, 10, 10)
        );
        SequencerInbox_2_1_0(erc20SequencerInbox_2_1_0).initialize(
            Bridge_2_1_0(erc20Bridge_2_1_0), ISequencerInbox_2_1_0.MaxTimeVariation(10, 10, 10, 10)
        );
        Inbox_2_1_0(inbox_2_1_0).initialize(Bridge_2_1_0(bridge_2_1_0), SequencerInbox_2_1_0(sequencerInbox_2_1_0));
        ERC20Inbox_2_1_0(erc20Inbox_2_1_0).initialize(
            Bridge_2_1_0(erc20Bridge_2_1_0), SequencerInbox_2_1_0(erc20SequencerInbox_2_1_0)
        );
    }

    // copied from deployment script
    function _deployActionScript() internal returns (NitroContracts2Point1Point3UpgradeAction) {
        bool isArbitrum = false;
        address reader4844Address;
        if (!isArbitrum) {
            // deploy blob reader
            reader4844Address = deployBytecodeFromJSON(
                "/node_modules/@arbitrum/nitro-contracts-2.1.3/out/yul/Reader4844.yul/Reader4844.json"
            );
        }

        // deploy new ETHInbox contract from v2.1.3
        newEthInboxImpl = deployBytecodeWithConstructorFromJSON(
            "/node_modules/@arbitrum/nitro-contracts-2.1.3/build/contracts/src/bridge/Inbox.sol/Inbox.json",
            abi.encode(maxDataSize)
        );
        // deploy new ERC20Inbox contract from v2.1.3
        newERC20InboxImpl = deployBytecodeWithConstructorFromJSON(
            "/node_modules/@arbitrum/nitro-contracts-2.1.3/build/contracts/src/bridge/ERC20Inbox.sol/ERC20Inbox.json",
            abi.encode(maxDataSize)
        );

        // deploy new EthSequencerInbox contract from v2.1.3
        newEthSeqInboxImpl = deployBytecodeWithConstructorFromJSON(
            "/node_modules/@arbitrum/nitro-contracts-2.1.3/build/contracts/src/bridge/SequencerInbox.sol/SequencerInbox.json",
            abi.encode(maxDataSize, reader4844Address, false)
        );

        // deploy new Erc20SequencerInbox contract from v2.1.3
        newErc20SeqInboxImpl = deployBytecodeWithConstructorFromJSON(
            "/node_modules/@arbitrum/nitro-contracts-2.1.3/build/contracts/src/bridge/SequencerInbox.sol/SequencerInbox.json",
            abi.encode(maxDataSize, reader4844Address, true)
        );

        // deploy upgrade action
        return new NitroContracts2Point1Point3UpgradeAction(
            newEthInboxImpl, newERC20InboxImpl, newEthSeqInboxImpl, newErc20SeqInboxImpl
        );
    }

    function testEth() public {
        NitroContracts2Point1Point3UpgradeAction action = _deployActionScript();
        upgradeExecutor.execute(address(action), abi.encodeCall(action.perform, (inbox_2_1_0, proxyAdmin)));

        // check correctly upgraded
        assertEq(proxyAdmin.getProxyImplementation(TransparentUpgradeableProxy(payable(inbox_2_1_0))), newEthInboxImpl);
        assertEq(
            proxyAdmin.getProxyImplementation(TransparentUpgradeableProxy(payable(sequencerInbox_2_1_0))),
            newEthSeqInboxImpl
        );
    }

    function testERC20() public {
        NitroContracts2Point1Point3UpgradeAction action = _deployActionScript();
        upgradeExecutor.execute(address(action), abi.encodeCall(action.perform, (erc20Inbox_2_1_0, proxyAdmin)));

        // check correctly upgraded
        assertEq(
            proxyAdmin.getProxyImplementation(TransparentUpgradeableProxy(payable(erc20Inbox_2_1_0))), newERC20InboxImpl
        );
        assertEq(
            proxyAdmin.getProxyImplementation(TransparentUpgradeableProxy(payable(erc20SequencerInbox_2_1_0))),
            newErc20SeqInboxImpl
        );
    }

    function testERC20BelowV2() public {
        // just downgrade the bridge to v1.3.0 to simulate a v1.3.0 chain
        address newImpl = address(new ERC20Bridge_1_3_0());
        vm.prank(address(upgradeExecutor));
        proxyAdmin.upgrade(TransparentUpgradeableProxy(payable(erc20Bridge_2_1_0)), newImpl);

        NitroContracts2Point1Point3UpgradeAction action = _deployActionScript();

        vm.expectRevert("NitroContracts2Point1Point3UpgradeAction: bridge is an ERC20Bridge below v2.x.x");
        upgradeExecutor.execute(address(action), abi.encodeCall(action.perform, (erc20Inbox_2_1_0, proxyAdmin)));
    }

    function testNotInbox() public {
        NitroContracts2Point1Point3UpgradeAction action = _deployActionScript();
        vm.mockCallRevert(address(inbox_2_1_0), abi.encodeWithSelector(IInboxBase_2_1_0.allowListEnabled.selector), "");
        vm.expectRevert("NitroContracts2Point1Point3UpgradeAction: inbox is not an inbox");
        upgradeExecutor.execute(address(action), abi.encodeCall(action.perform, (inbox_2_1_0, proxyAdmin)));
    }
}
