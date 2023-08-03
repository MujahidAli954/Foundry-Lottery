// SPDX-License-Identifier: UNLICENSED

import {Script} from  "forge-std/Script.sol";

pragma solidity ^0.8.19;

contract HelperConfig is Script{

struct NetworkConfig{
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
}

function getSepoliaEthConfig() public view returns (NetworkConfig memory){
    return NetworkConfig({
        entranceFee
    })
}

}