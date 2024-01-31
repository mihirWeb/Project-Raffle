// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Vm} from "forge-std/Vm.sol";

contract RaffleUnitTest is Test{

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFees; 
    uint256 interval;
    address vrfCoordinator; 
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    event EnteredRaffle(address indexed player);

    address PLAYER = makeAddr("player");

    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external{
        DeployRaffle deployRaffle = new DeployRaffle();

        (raffle, helperConfig) = deployRaffle.run();
        // helperConfig = new HelperConfig();
            (
                entranceFees, 
                interval, 
                vrfCoordinator, 
                gasLane,
                subscriptionId,
                callbackGasLimit,
                link,
                
            ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_BALANCE);
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

    function testCheckUpKeepReturnTrueIfAllParametersAreTrue() public enterRaffleAndTimePassed{

        (bool upKeep, ) = raffle.checkUpKeep("");
        assert(upKeep);
    }



    ////////////////////////////////////////////// tests for performUpKeep

    function testPerformUpKeepOnlyIfUpKeepIsTrue() public enterRaffleAndTimePassed{
        // vm.prank(PLAYER);
        // raffle.enterRaffle{value: entranceFees}();

        // vm.roll(block.number + 1);
        // vm.warp(block.timestamp + interval + 1);

        raffle.performUpkeep("");
    }

    function testPerformUpKeepRevertIfUpKeepIsFalse() public{
        
        uint256 currentBalance = 0;
        uint256 numberOfPlayers = 0;
        uint256 raffleState = 0;

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_upKeepNeeded.selector,
                currentBalance,
                numberOfPlayers,
                raffleState
            )
        );
        raffle.performUpkeep("");

    }

    function testPerformUpKeepEmitEventAndRaffleStateCheck() public enterRaffleAndTimePassed{
       
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestId = entries[1].topics[1];

        assert(uint256(requestId)>0);
        // console.log(requestId);

        Raffle.RaffleStates rState = raffle.getRaffleState();
        assert(uint256(rState) == 1);
    }

    


    ////////////////////////////////////////////////// fulfill random words tes

    function testFulfillRandomWordsWillRunAfterPerformUpKeep(uint256 randomRequestId) public enterRaffleAndTimePassed{

        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFulfillRandomWordsWillPickWinnerAndResetArray() public enterRaffleAndTimePassed{

        uint256 startingIndex = 1;
        uint256 players = 5;

        for(uint256 i=startingIndex; i<= players; i++){
            address newPlayer = address(uint160(i));
            hoax(newPlayer, STARTING_BALANCE);
            raffle.enterRaffle{value: entranceFees}();

        }

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        // console.log(requestId);

        // uint256 previousTimeStamp = block.timestamp;
        uint256 prize = STARTING_BALANCE + players*entranceFees;

        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        ); 

        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getTotalPlayers() == 0);
        assert(uint256(raffle.getRaffleState()) == 0);
        // assert(raffle.getLatestTimestamp() < block.timestamp);
        assert(raffle.getRecentWinner().balance == prize); 


    }


    /////////////////////////////////////////// MODIFIERS

    modifier enterRaffleAndTimePassed{
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFees}();

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + interval + 1);
        _;
    }
  
}