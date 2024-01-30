// this file is to create subscription id

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/Mocks/LinkToken.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";


contract CreateSubscriptionId is Script {

    function createSubsUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , , , uint256 deployerKey) = helperConfig.activeNetworkConfig();

        return subscriptionId(vrfCoordinator, deployerKey);
    }

    function subscriptionId(address vrfCoordinator, uint256 deployerKey) public returns(uint64){
        
        console.log("Creating subscription ID on: ", block.chainid);
        vm.startBroadcast(deployerKey);
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

contract FundSubscriptionId is Script{

    uint96 public constant FUND_AMOUNT = 3 ether;
    
    function fundSubscriptionUsingConfig() public{
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subId,
            ,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        fundSubId(vrfCoordinator, subId, link, deployerKey);
    }

    function fundSubId(address vrfCoordinator, uint64 subId, address link, uint256 deployerKey) public{
        console.log("VRFcoordinator address: ", vrfCoordinator);
        console.log("subId value: ", subId);
        console.log("link address: ", link);

        if(block.chainid == 31337){
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        }
        else{
            vm.startBroadcast(deployerKey);
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }

    }

    function run() external{
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script{

    function addConsumerUsingConfig() public{
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subId,
            ,
            ,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumer(vrfCoordinator, raffle, subId, deployerKey);

    }

    function addConsumer(address vrfCoordinator, address raffle, uint64 subId, uint256 deployerKey) public{
        console.log("vrfcoordinator: ", vrfCoordinator);
        console.log("raffle: ", raffle);
        console.log("subId: ", subId);
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }


    function run() external{
        addConsumerUsingConfig();
    }
}
