// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    // VRF Mock Values
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    // Link / ETH price
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;
}

contract HelperConfig is CodeConstants, Script {
    /*Errors */
    error HelperConfig__InvalidChainId();

    struct NetWorkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
        address link;
        address account; // who broadcast the transactions
    }

    NetWorkConfig public localNetWorkConfig;
    mapping(uint256 chainId => NetWorkConfig) public netWorkConfigs;

    constructor() {
        netWorkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaETH();
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetWorkConfig memory) {
        if (netWorkConfigs[chainId].vrfCoordinator != address(0)) {
            return netWorkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilETHConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns (NetWorkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaETH() public pure returns (NetWorkConfig memory) {
        return
            NetWorkConfig({
                entranceFee: 0.01 ether, //1e16
                interval: 30, // 30 seconds
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                callbackGasLimit: 500000, //500,000
                subscriptionId: 41003678604292545293609046172020122620436418140789591760747526987642326637953,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                account: 0xDc900033937A6957174070e9721a4113Dd0E0D84
            });
    }

    function getOrCreateAnvilETHConfig() public returns (NetWorkConfig memory) {
        //check to see if we set an active network config
        if (localNetWorkConfig.vrfCoordinator != address(0)) {
            return localNetWorkConfig;
        }
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UINT_LINK
        );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        localNetWorkConfig = NetWorkConfig({
            entranceFee: 0.01 ether,
            interval: 30, // 30 seconds
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000,
            subscriptionId: 0,
            link: address(linkToken),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        });

        return localNetWorkConfig;
    }
}
