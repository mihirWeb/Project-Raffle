// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract HelperConfig is Script{
    
    struct NetworkConfig {
        uint256 entranceFees; 
        uint256 interval;
        address vrfCoordinator; 
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
    }

    NetworkConfig public activeNetworkConfig;

    constructor(){
        if(block.chainid == 11155111){
            activeNetworkConfig = getSapoliaEthConfig();
        } else{
            activeNetworkConfig = getOrCreateSapoliaEthConfig();
        }
    }

    function getSapoliaEthConfig() public pure returns(NetworkConfig memory){
        return NetworkConfig({
            entranceFees: 0.01 ether,
            interval: 30, // in seconds
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0x0, // add it later
            callbackGasLimit: 500000
        });
    }

    function getOrCreateSapoliaEthConfig() public returns(NetworkConfig memory){

        if(activeNetworkConfig.vrfCoordinator != address(0x0)){
            return activeNetworkConfig;
        }
        uint96 baseFee = 0.25 ether; // 0.25 link
        uint96 gasPriceLink = 1e9; // 1 gwei link

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink);
        vm.stopBroadcast();

        return NetworkConfig({
            entranceFees: 0.01 ether,
            interval: 30, // in seconds
            vrfCoordinator: address(vrfCoordinatorV2Mock),
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // doesn't matter
            subscriptionId: 0x0, // add it later
            callbackGasLimit: 500000
        });
    }
}