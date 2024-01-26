// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";

contract RaffleUnitTest is Test{

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFees; 
    uint256 interval;
    address vrfCoordinator; 
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    event EnteredRaffle(address indexed player);

    address PLAYER = makeAddr("player");

    function setUp() external{
        DeployRaffle deployRaffle = new DeployRaffle();
        helperConfig = new HelperConfig();
            (
                entranceFees, 
                interval, 
                vrfCoordinator, 
                gasLane,
                subscriptionId,
                callbackGasLimit,

            ) = helperConfig.activeNetworkConfig();
        raffle = deployRaffle.run();
        vm.deal(PLAYER, 10 ether);
    }



    /////////////////////////////  Unit tests for enterRaffle Function

    function testNotEnoughEthRevert() public{

        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle_NotEnoughEthSend.selector);
        raffle.enterRaffle();

    }

    function testEmitEventsOnEntry() public{
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false); // out of 3 indexed values and unindexed value respectivle, i expect 1 indexed value will be emitted by this event/emit 

        emit EnteredRaffle(PLAYER); // event that will emit

        raffle.enterRaffle{value: entranceFees}(); // this will also emit an event then the test will check that both values are equal or not
        
    }

    function testRevertWhenRaffleIsClosed() public{
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFees}(); // the player enters in the game
        // calculation of winner will start after interval hence set block time:-
        vm.warp(block.timestamp + interval + 1); // After every interval the block will start calculating hence so, this is calculating stage
        vm.roll(block.number + 1); // this way the block will start from new block to make sure the time gap
        // above conditions is to make sure it passes checkUpKeep function of raffle
        
        raffle.performUpkeep(""); // calculating

        // now we will try to enter in Raffle

        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        raffle.enterRaffle{value: entranceFees}();
    }




    ///////////////////////////////////////// tests for checkUpKeep


    function testCheckUpKeepReturnFalseIfRaffleHasNoBalance() public{

        // Arrange i.e. make conditions for the scenerio
        vm.warp(block.timestamp + interval +1);
        vm.roll(block.number + 1);

        // Act
        (bool upKeep, ) = raffle.checkUpKeep("");

        // Assert
        assert(!upKeep);
    }

    function testCheckUpKeepReturnFalseIfRaffleIsCalculating() public{

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFees}();

        (bool upKeep, ) = raffle.checkUpKeep("");
        console.log(upKeep);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + interval + 1);
        raffle.performUpkeep("");
        console.log(upKeep);
        assert(!upKeep);
    }

    function testCheckUpKeepReturnFalseIfEnoughTimeHasntPassed() public{

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFees}();

        vm.warp(block.timestamp);
        // raffle.performUpkeep("");
        (bool upKeep, ) = raffle.checkUpKeep("");
        assert(!upKeep);

    }

    function testCheckUpKeepReturnTrueIfAllParametersAreTrue() public{

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFees}();

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + interval + 1);

        (bool upKeep, ) = raffle.checkUpKeep("");
        assert(upKeep);
    }
  
}