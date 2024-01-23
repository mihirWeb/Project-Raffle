// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";

contract RaffleUnitTest is Test{

    Raffle raffle;
    address PLAYER = makeAddr("player");

    function setUp() external{
        DeployRaffle deployRaffle = new DeployRaffle();
        raffle = deployRaffle.run();
        vm.deal(PLAYER, 10 ether);
    }



    /////////////////////////////  Unit tests for enterRaffle Function

    function testNotEnoughEthRevert() public{

        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle_NotEnoughEthSend.selector);
        raffle.enterRaffle();

    }
  
}