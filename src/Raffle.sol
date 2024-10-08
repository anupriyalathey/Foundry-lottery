// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract
// Inside Contract:
// Type declarations
// State variables
// Events
// Modifiers
// Functions
// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions

// external & public view & pure functions


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8//VRFConsumerBaseV2.sol";

/**
 * @title A Sample Raffle Contract
 * @author Anupriya Lathey
 * @notice This contract is for creating a sample raffle 
 * @dev Implemnet Chainlink VRFv2
 */
contract Raffle is VRFConsumerBaseV2{
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers, 
        uint256 raffleState
    );

    /** Type Declarations */
    enum RaffleState {
        OPEN,    // 0
        CALCULATING  // 1 & so on
    }

    // bool 
    /** State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // since constant so all caps -> more gas efficient
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee; // Immutable - to reduce gas
    uint256 private immutable i_interval; // @dev Duration of lottery in seconds
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator; 
    bytes32 private immutable i_gasLane; 
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players; // since it changes the number of players, it is a storage variable not immutable. Payable - since need to pay players eth after the raffle
    uint256 private s_lastTimeStamp; // to keep track of the last time the raffle was called
    address private s_recentWinner;
    RaffleState private s_raffleState ;
    
    /** Events */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval, 
        address vrfCoordinator, 
        bytes32 gasLane, 
        uint64 subscriptionId, 
        uint32 callbackGasLimit,
        address link
        ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_raffleState = RaffleState.OPEN; // default = open
        s_lastTimeStamp = block.timestamp;
    }

    // External instead of public since we won't be calling this function from within the contract and also to reduce gas
    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH to enter the raffle");
        if(msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender)); //payable - to make an address payable
        emit EnteredRaffle(msg.sender);
    }

    // 1. Get a random number
    // 2. Use random number to pick a winner
    // 3. Be automatically called

    // When is the winner supposed to be picked?
    /**
     * @dev This is the function that the Chainlink Automation nodes call
     * to see if it's time to perform an upkeep
     * The following should be true for this to return true:
     * 1. The time interval has passed between raffle runs
     * 2. The raffle is in the OPEN state
     * 3. The contract has ETH (aka, players)
     * 4. (Implicit) The subscription is funded with LINK
     */
    function checkUpkeep(  
        bytes memory /* checkData */
        ) public view returns (bool upkeepNeeded, bytes memory /* performData */){
            bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
            bool isOpen = RaffleState.OPEN == s_raffleState;
            bool hasBalance = address(this).balance > 0;
            bool hasPlayers = s_players.length > 0;
            upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
            return(upkeepNeeded, "0x0");
    }

    // External - so that anybody can call this function but after some interval
    
    // 1. Get a random number
    // 2. Use the random number to pick a player
    // 3. Automatically called  
    
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
    
        // check if enough time has passed
     
        s_raffleState = RaffleState.CALCULATING;
        // 1. Request a RNG
        // 2. Get the random number
        // check to see if enough time has passed

        i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gas lane
            i_subscriptionId, // subscription id
            REQUEST_CONFIRMATIONS, // no. of block confirmations
            i_callbackGasLimit, // gas limit
            NUM_WORDS // number of random words
        );
    }

    // CEI - Check-Effect-Interact
    function fulfillRandomWords( uint256 /* requestId */, uint256[] memory randomWords) internal override {
       // Checks (require...)
       // Effects (Our own contract)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0); // reset the players array
        s_lastTimeStamp = block.timestamp; // reset the timestamp
        emit PickedWinner(winner);

        // Interactions 
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**Getter Functions */
    function getEntranceFee() external view returns(uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns(address) {
        return s_players[indexOfPlayer];
    }
}