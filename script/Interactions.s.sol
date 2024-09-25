// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function run() public {
        createSubscriptionUsingConfig();
    }

    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        (uint256 subId,) = createSubscription(vrfCoordinator, account);
        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator, address account) public returns (uint256, address) {
        console.log("Creating subscription on chain Id:", block.chainid);

        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your subscription Id:", subId);
        console.log("Please update the subscriptionId in your HelperConfig.s.sol");
        return (subId, vrfCoordinator);
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // = 3 LINK

    function run() public {
        fundSubscriptionUsingConfig();
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;

        address account = helperConfig.getConfig().account;
        fundSubScription(vrfCoordinator, subscriptionId, linkToken, account);
    }

    function fundSubScription(address vrfCoordinator, uint256 subscriptionId, address linkToken, address account)
        public
    {
        console.log("Fund Subscription:", subscriptionId);
        console.log("Using Vrfcoordinator:", vrfCoordinator);
        console.log("On chainId:", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }
}

contract AddConsumer is Script {
    function run() public {
        address raffle = DevOpsTools.get_most_recent_deployment("Mycontract", block.chainid);
        addConsumerUsingConfig(raffle);
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;

        address account = helperConfig.getConfig().account;
        addConsumer(raffle, vrfCoordinator, subscriptionId, account);
    }

    function addConsumer(address raffle, address coordinator, uint256 subscriptionId, address account) public {
        console.log("Adding consumer contract to vrfCoordinator:", raffle);
        console.log("Using coordinator:", coordinator);
        console.log("On chainId", block.chainid);

        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(coordinator).addConsumer(subscriptionId, raffle);
        vm.stopBroadcast();
    }
}
