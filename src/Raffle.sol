// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


/**
 * @title a simple Raffle contract that will choose a random winner automatically after sometime
 * @author Mihir Pratap Singh
 * @notice This contract is for creating a simple raffle
 * @dev implements chainlink VRFv2
 */

contract Raffle is VRFConsumerBaseV2{

    // Error Handling 
    error Raffle_NotEnoughEthSend();
    error Raffle_transferFail();
    error Raffle_RaffleNotOpen();
    error Raffle_upKeepNeeded(uint256 currentBalance, uint256 playerLength, uint256 raffleState);

    // Enum
    enum RaffleStates{
        OPEN, // they are also convertible in integers, i.e 0
        CALCULATING // 1
    }

    // State variables 

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    
    uint256 private immutable i_entranceFees;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    uint256 private s_lastTimeStramp;
    address payable[] s_playerAddress;
    address private s_recentsWinner;
    RaffleStates private s_raffleState;

    // Events 
    event EnteredRaffle(address indexed player);
    event WinnerPlayer(address indexed winner);
    event RequestId(uint256 indexed requestId);

    constructor(
        uint256 entranceFees, 
        uint256 interval, 
        address vrfCoordinator, 
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
        ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFees = entranceFees;
        s_lastTimeStramp = block.timestamp;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleStates.OPEN;

    }

    function enterRaffle() external payable{
        if(msg.value < i_entranceFees){
            revert Raffle_NotEnoughEthSend();
        }
        if(s_raffleState != RaffleStates.OPEN){
            revert Raffle_RaffleNotOpen();
        }

        s_playerAddress.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    
    /**
     * @dev This is the function that chainlink automation nodes call
     * to see if its the time to perform an upkeep.
     * The following must be true for this to return true :-
     * 1) The time interval has passed between the raffle runs.
     * 2) The raffle is in the OPEN state
     * 3) The contract has Eth (aka, players)
     * 4) (Implicit) The subscription is funded with the link
     */

    function checkUpKeep(bytes memory /* performData */) /* We can cmt the argument if the funtions takes the argument but we dont want that part of code */
        public view returns(bool upKeepNeeded, bytes memory /* performData */){

            bool checkInterval = (block.timestamp - s_lastTimeStramp) >= i_interval;
            bool checkRaffleState = s_raffleState == RaffleStates.OPEN;
            bool checkEth = address(this).balance > 0;
            bool checkPlayers = s_playerAddress.length > 0;

            upKeepNeeded = (checkInterval && checkRaffleState && checkEth && checkPlayers);
            return (upKeepNeeded, "0x0");

        }



    /**
     * @dev This function will create a requestId to get our random number
     * after checking if it meets all the checkUpKeep function      
     */



    function performUpkeep(bytes calldata /* performData */) external{
        // Functionality of pickWinner-
        // 1) get a random number
        // 2) Pick a winner
        // 3) Make it automatic

        (bool upKeepNeeded, ) = checkUpKeep("");
        if(!upKeepNeeded){
            revert Raffle_upKeepNeeded( /* I am passing argument so that I can know the reason fopr revert */
                address(this).balance,
                s_playerAddress.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleStates.CALCULATING;

        // i_vrfCoordinator/COORDINATOR is a vrf coordinator address which depends on chain to chain, in simple terms this is the contract from which we will request random number
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // this is bytes32 gas lane, which tells us how much gas we want to bumb to, it's chain dependent
            i_subscriptionId, // this is our subscription id to the chainlink vrf
            REQUEST_CONFIRMATIONS, // dont know exactly but its default value is 3 and we can set higher
            i_callbackGasLimit, // the max gas we are willinh to spend to the callback function
            NUM_WORDS // how many random numbers we want in return
        );

        emit RequestId(requestId);

    }

    /**
     * @dev this is the function we need to call in order to 
     * get random numbers and it will process our request id 
     * that we made in above function and after that it will pick a winner
     */

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override { /* this is override bcz it exists in the VRFConsumerBaseV2 file, check it to know more */
        uint256 indexOfWinner = randomWords[0] % s_playerAddress.length;
        address payable winner = s_playerAddress[indexOfWinner];
        s_recentsWinner = winner;
        s_raffleState = RaffleStates.OPEN;
        emit WinnerPlayer(winner);

        s_playerAddress = new address payable[](0); // resetting the array from 0th index
        s_lastTimeStramp = block.timestamp;

        (bool callSuccess, ) = winner.call{value: address(this).balance}("");
        if(!callSuccess){
            revert Raffle_transferFail();
        }
        
    }

    // Getter Functions 

    function getEntranceFees() external view returns(uint256){
        return i_entranceFees;
    }

    function getRaffleState() external view returns(RaffleStates){
        return s_raffleState;
    }

    function getRecentWinner() external view returns(address){
        return s_recentsWinner;
    }

    function getTotalPlayers() external view returns(uint256){
        return s_playerAddress.length;
    }

    function getLatestTimestamp() external view returns(uint256){
        return s_lastTimeStramp;
    }
}
