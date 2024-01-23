// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";

contract RaffleUnitTest is Test{

    Raffle raffle;

    function setup() external{
        DeployRaffle deployRaffle = new DeployRaffle();
        raffle = deployRaffle.run();
    }



    /////////////////////////////  Unit tests for Enter Raffle Function
  
}