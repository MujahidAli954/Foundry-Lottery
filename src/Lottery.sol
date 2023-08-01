// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";


contract Lottery {
    /** error */
    error Lottery__NotEnoughEthSent();


    /**State variables */
    uint256 private constant REQUEST_CONFIRMATIONS = 3;
    uint256 private constant NUM_WORDS=1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    address private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64  private immutable i_subscriptionId;
    uint256 private immutable i_callbackGasLimit;
    address payable[]  private s_players;


    /** Events */
    event EnteredLottery(address indexed player);

    constructor(uint256 entranceFee ,uint256 interval,address vrfCoordinator,bytes32 gasLane,uint64 subscriptionId,uint256 callbackGasLimit){
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = vrfCoordinator;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
    }

    function enterlottery() public payable{
        // require(msg.value >= i_entranceFee,"Entrance fee should be greater than zero");
        if(msg.value < i_entranceFee){
            revert Lottery__NotEnoughEthSent();
        }
        s_players.push(payable(msg.sender));
        emit EnteredLottery(msg.sender);
    }

    
    function pickWinner() external {
        if((block.timestamp - s_lastTimeStamp) < i_interval){
            revert();
        }
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    /** Geters */
    function getEntranceFee() external view returns(uint256){
        return i_entranceFee;
    }
}
