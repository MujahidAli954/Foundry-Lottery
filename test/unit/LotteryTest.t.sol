// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployLottery} from "../../script/DeployLottery.s.sol";
import {Lottery} from "../../src/Lottery.sol";
import {Test ,console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "../mocks/VRFCoordinatorV2Mock.sol";

contract LotteryTest is Test {
    /** Events */
    event EnteredLottery(address indexed player);
    Lottery lottery;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    function setUp() external {
        DeployLottery deployer = new DeployLottery();
        (lottery,helperConfig) = deployer.run();
        (
             entranceFee,
             interval,
             vrfCoordinator,
             gasLane,
             subscriptionId,
             callbackGasLimit,
             link
        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER,STARTING_USER_BALANCE);
    }
    function testLotteryInitializesInOpenState() public view {
        assert(lottery.getLotteryState() == Lottery.LotteryState.OPEN);
    }

    function testLotteryRevertsWhenYouDontPayEnough() public  {
        vm.prank(PLAYER);
        vm.expectRevert(Lottery.Lottery__NotEnoughEthSent.selector);
        lottery.enterLottery();
    }

    function testLotteryRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        lottery.enterLottery{value: entranceFee}(); 
        address playerRecorded = lottery.getPlayer(0);
        assert(playerRecorded == PLAYER);     
    }
    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true,false,false,false,address(lottery));
        emit EnteredLottery(PLAYER);
        lottery.enterLottery{value: entranceFee}();
    }

    function testCantEnterWhenLotteryIsCalculating() public {
        vm.prank(PLAYER);
        lottery.enterLottery{value:entranceFee}();
        vm.warp(block.timestamp + interval +1);
        vm.roll(block.number +1);
        lottery.performUpkeep("");
        vm.expectRevert(Lottery.Lottery__LotteryNotOpen.selector);
        lottery.enterLottery{value:entranceFee}();

    }

    function testCheckUpkeepReturnsFalseIfIthasNoBalance() public {
        vm.warp(block.timestamp + interval +1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        assert(upkeepNeeded == false);
    }
    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        vm.prank(PLAYER);
        lottery.enterLottery{value:entranceFee}();
        vm.warp(block.timestamp + interval +1);
        vm.roll(block.number + 1);
        lottery.performUpkeep("");
    }  
    function testPerformUpkeepCanOnlyRevertIfCheckUpkeepIsFalse()  public {
        uint256  currentBalance = 0;
        uint256 numPlayers = 0;
        uint256 lotteryState = 0;
        vm.expectRevert(abi.encodeWithSelector(Lottery.Lottery__UpKeepNotNeeded.selector,currentBalance,numPlayers,lotteryState));
        lottery.performUpkeep("");
    }
     modifier lotteryEnterAndTimePassed(){
        vm.prank(PLAYER);
        lottery.enterLottery{value:entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
     }
     fucntion testPerformUpkeepUpdatesLotteryStateAndEmitsRequestId() public lotteryEnterAndTimePassed{
        vm.recordLogs();
        lottery.performUpkeep("");
        vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 reuestId = entries[1].topics[1];

        Lottery.LotteryState rState = lottery.getLotteryState();
        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
     }

function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId)
        public
        lotteryEnteredAndTimePassed
    {
        // Arrange
        // Act / Assert
        vm.expectRevert("nonexistent request");
        // vm.mockCall could be used here...
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
            randomRequestId,
            address(lottery)
        );

        // vm.expectRevert("nonexistent request");

        // VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
        //     1,
        //     address(lottery)
        // );
    }

      }