// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {DeploymentHelpersScript} from "../helper/DeploymentHelpers.s.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "@arbitrum/nitro-contracts-2.1.3/src/express-lane-auction/IExpressLaneAuction.sol";

/**
 * @title DeployAddWasmCacheManagerActionScript
 * @notice This script deploys CacheManager and then deploys action that's used to add cache manager on a child chain.
 */
contract DeployExpressLaneAuctionScript is DeploymentHelpersScript {
    // https://github.com/OffchainLabs/nitro/releases/tag/consensus-v32
    uint256 public constant TARGET_ARBOS_VERSION = 32;

    function run() public {
        vm.startBroadcast();

        // deploy CacheManger behind proxy
        address expressLaneAuctionLogic = deployBytecodeFromJSON(
            "/node_modules/@arbitrum/nitro-contracts-2.1.3/build/contracts/src/express-lane-auction/ExpressLaneAuction.sol/ExpressLaneAuction.json"
        );
        address expressLaneAuctionProxy = address(
            new TransparentUpgradeableProxy(
                expressLaneAuctionLogic,
                vm.envAddress("PROXY_ADMIN_ADDRESS"),
                abi.encodeCall(
                    IExpressLaneAuction.initialize,
                    InitArgs({
                        _auctioneer: vm.envAddress("AUCTIONEER_ADDRESS"),
                        _biddingToken: vm.envAddress("BIDDING_TOKEN_ADDRESS"),
                        _beneficiary: vm.envAddress("BENEFICIARY_ADDRESS"),
                        _roundTimingInfo: RoundTimingInfo({
                            offsetTimestamp: int64(uint64(block.timestamp)),
                            roundDurationSeconds: uint64(vm.envUint("ROUND_DURATION_SECONDS")),
                            auctionClosingSeconds: uint64(vm.envUint("AUCTION_CLOSING_SECONDS")),
                            reserveSubmissionSeconds: uint64(vm.envUint("RESERVE_SUBMISSION_SECONDS"))
                        }),
                        _minReservePrice: vm.envUint("MIN_RESERVE_PRICE"),
                        _auctioneerAdmin: vm.envAddress("AUCTIONEER_ADMIN_ADDRESS"),
                        _minReservePriceSetter: vm.envAddress("MIN_RESERVE_PRICE_SETTER_ADDRESS"),
                        _reservePriceSetter: vm.envAddress("RESERVE_PRICE_SETTER_ADDRESS"),
                        _reservePriceSetterAdmin: vm.envAddress("RESERVE_PRICE_SETTER_ADMIN_ADDRESS"),
                        _beneficiarySetter: vm.envAddress("BENEFICIARY_SETTER_ADDRESS"),
                        _roundTimingSetter: vm.envAddress("ROUND_TIMING_SETTER_ADDRESS"),
                        _masterAdmin: vm.envAddress("MASTER_ADMIN_ADDRESS")
                    })
                )
            )
        );
        vm.stopBroadcast();
        require(expressLaneAuctionProxy != address(0), "DEPLOYMENT_FAILED");
    }
}
