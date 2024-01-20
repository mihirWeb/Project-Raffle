// Objectives -
// 1) get a random number
// 2) Pick a winner
// 3) Make it automatic

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


/**
 * @title a simple Raffle contract that will choose a random winner after sometime
 * @author Mihir Pratap Singh
 * @notice This contract is for creating a simple raffle
 * @dev implements chainlink VRFv2
 */

contract Raffle{

    error Raffle_NotEnoughEthSend();

    // State variables 
    address payable[] s_playerAddress;
    uint256 private immutable i_entranceFees;

    // Events 
    event EnteredRaffle(address indexed player);

    constructor(uint256 entranceFees){
        i_entranceFees = entranceFees;

    }

    function enterRaffle() external payable{
        if(msg.value < i_entranceFees){
            revert Raffle_NotEnoughEthSend();
        }

        s_playerAddress.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }
}
