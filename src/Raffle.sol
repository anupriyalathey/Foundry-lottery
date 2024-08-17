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

/**
 * @title A Sample Raffle Contract
 * @author Anupriya Lathey
 * @notice This contract is for creating a sample raffle 
 * @dev Implemnet Chainlink VRFv2
 */
contract Raffle {
    error Raffle_NotEnoughEthSent();

    uint256 private immutable i_entranceFee; // Immutable - to reduce gas
    uint256 private immutable i_interval; // @dev Duration of lottery in seconds
    address payable[] private s_players; // since it changes the number of players, it is a storage variable not immutable. Payable - since need to pay players eth after the raffle
    uint256 private s_lastTimeStamp; // to keep track of the last time the raffle was called
    
    /** Events */
    event EnteredRaffle(address indexed player);

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    // External instead of public since we won't be calling this function from within the contract and also to reduce gas
    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH to enter the raffle");
        if(msg.value < i_entranceFee) {
            revert Raffle_NotEnoughEthSent();
        }
        s_players.push(payable(msg.sender)); //payable - to make an address payable
        emit EnteredRaffle(msg.sender);
    }

    // 1. Get a random number
    // 2. USe random number to pick a winner
    // 3. Be automatically called

    // External - so that anybody can call this function but after some interval
    function pickWinner() external {
        // check if enough time has passed
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert();
        }
        
    }

    /**Getter Functions */
    function getEntranceFee() external view returns(uint256) {
        return i_entranceFee;
    }
}