// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Raffle} from "../src/Raffle.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscriptionId} from "./Integration.s.sol";


contract DeployRaffle is Script{

    function run() external returns(Raffle){
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 entranceFees, 
            uint256 interval, 
            address vrfCoordinator, 
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            
        ) = helperConfig.activeNetworkConfig();

        if(subscriptionId == 0){
            CreateSubscriptionId createSubscriptionId = new CreateSubscriptionId();
            subscriptionId = createSubscriptionId.subscriptionId(vrfCoordinator);
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

        return raffle;
    }

}