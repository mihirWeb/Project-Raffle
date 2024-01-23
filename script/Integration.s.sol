// this file is to create subscription id

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract CreateSubscriptionId is Script {

    function createSubsUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , ) = helperConfig.activeNetworkConfig();

        return subscriptionId(vrfCoordinator);
    }

    function subscriptionId(address vrfCoordinator) public returns(uint64){
        
        console.log("Creating subscription ID on: ", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        // with this we created the instance of our already deployed VRFcoordinatorV2Mock on vrfcoordinator address
        // so that we can access it's createSubscription function
        vm.stopBroadcast();
        console.log("Your subscription Id is: ", subId);

        return subId;
        
    }

    function run() external returns (uint64) {
        return createSubsUsingConfig();
    }
}
