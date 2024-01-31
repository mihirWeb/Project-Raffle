// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Raffle} from "../src/Raffle.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscriptionId, FundSubscriptionId, AddConsumer} from "./Integration.s.sol";


contract DeployRaffle is Script{

    function run() external returns(Raffle, HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 entranceFees, 
            uint256 interval, 
            address vrfCoordinator, 
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address link,
            uint256 deployerKey            
        ) = helperConfig.activeNetworkConfig();

        if(subscriptionId == 0){
            CreateSubscriptionId createSubscriptionId = new CreateSubscriptionId();
            subscriptionId = createSubscriptionId.subscriptionId(vrfCoordinator, deployerKey);

            // funding subscription
            FundSubscriptionId fundSubscriptionId = new FundSubscriptionId();
            fundSubscriptionId.fundSubId(vrfCoordinator, subscriptionId, link, deployerKey);

        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFees,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(vrfCoordinator, address(raffle), subscriptionId, deployerKey);

        return (raffle, helperConfig);
    }

}