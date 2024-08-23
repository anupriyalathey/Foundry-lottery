// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscriptionScript} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) { 
        HelperConfig helperConfig = new HelperConfig();
        (
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator, 
        bytes32 gasLane,
        uint64 subscriptionId, 
        uint32 callbackGasLimit,
        address link
        ) = helperConfig.activeNetworkConfig();

        if(subscriptionId == 0 ) {
            CreateSubscriptionScript createSubscription = new CreateSubscriptionScript();
            subscriptionId = createSubscription.createSubscription(vrfCoordinator);

            // Fund It

        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            link
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}