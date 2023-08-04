// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract Lottery is VRFConsumerBaseV2 {
    /** error */
    error Lottery__NotEnoughEthSent();
    error Lottery__TransferFailed();
    error Lottery__LotteryNotOpen();
    error Lottery__UpKeepNotNeeded(uint256 currentBalance,uint256 numPlayers,uint256 lotteryState);

    /**Enums */

    enum LotteryState {
        OPEN,
        CALCULATING
    }


    /**State variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS=1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64  private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address private  s_recentWinner;
    address payable[]  private s_players;
    LotteryState private s_lotteryState;


    /** Events */
    event EnteredLottery(address indexed player);
    event pickedWinner(address indexed winner);

    constructor(uint256 entranceFee,
    uint256 interval,
    address vrfCoordinator,
    bytes32 gasLane,
    uint64 subscriptionId,
    uint32 callbackGasLimit)
    VRFConsumerBaseV2(vrfCoordinator)
    {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    function enterLottery() public payable{
        // require(msg.value >= i_entranceFee,"Entrance fee should be greater than zero");
        if(msg.value < i_entranceFee){
            revert Lottery__NotEnoughEthSent();
        }
        if(s_lotteryState != LotteryState.OPEN){
            revert Lottery__LotteryNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit EnteredLottery(msg.sender);
    }

    function checkUpkeep(
        bytes memory  /* checkData */
    )
        public
        view
        returns (bool upkeepNeeded, bytes memory /*performData */)
    {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >=i_interval;
        bool isOpen = LotteryState.OPEN ==s_lotteryState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance &&  hasPlayers);
        return (upkeepNeeded, "");
    }

    
    function performUpkeep(bytes calldata /* performData */) external{
        (bool upkeepNeeded,) = this.checkUpkeep("");
        if(!upkeepNeeded){
            revert Lottery__UpKeepNotNeeded(address(this).balance, s_players.length,uint256(s_lotteryState));
        }
        s_lotteryState = LotteryState.CALCULATING;
        i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

       function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
       uint256 indexOfWinner = randomWords[0] % s_players.length;
       address payable winner = s_players[indexOfWinner];
       s_recentWinner = winner;
       s_lotteryState = LotteryState.OPEN;
       s_players = new address payable[](0);
       s_lastTimeStamp = block.timestamp;
       (bool success,) = winner.call{value: address(this).balance}("");
       if(!success){
        revert Lottery__TransferFailed();
       }
       emit pickedWinner(winner);
    }



    /** Geters */
    function getEntranceFee() external view returns(uint256){
        return i_entranceFee;
    }
    function getLotteryState() external view returns(LotteryState){
        return s_lotteryState;
    }
    function getPlayer(uint256 indexOfPlayer) external view returns(address){
        return s_players[indexOfPlayer];
    }
}
