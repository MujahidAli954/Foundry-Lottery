// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract Lottery {
    error Lottery__NotEnoughEthSent();
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    address payable[]  private s_players;


    /** Events */
    event EnteredLottery(address indexed player);

    constructor(uint256 entranceFee ,uint256 interval){
        i_entranceFee = entranceFee;
        i_interval = interval;
    }

    function enterlottery() public payable{
        // require(msg.value >= i_entranceFee,"Entrance fee should be greater than zero");
        if(msg.value < i_entranceFee){
            revert Lottery__NotEnoughEthSent();
        }
        s_players.push(payable(msg.sender));
        emit EnteredLottery(msg.sender);
    }

    
    function pickWinner() public {
    }

    /** Geters */
    function getEntranceFee() external view returns(uint256){
        return i_entranceFee;
    }
}
