// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/Staking.sol";
import "../src/Token.sol";

/**
 * @title StakingTest Contract
 * @author Nika Khachiashvili
 * @dev Test cases for Staking Contract
 * @dev IMPORTANT: These test cases aren't ready for production use, because not all the edge, tiny very specific cases are covered
 */
contract StakingTest is Test {
    uint256 public constant INITIAL_TOKEN_SUPPLY = 1000 ether;
    uint256 public constant STATIC_INTEREST_RATE = 0.1 ether;
    uint256 public constant DYNAMIC_REWARD_AMOUNT = 10000 ether;
    uint256 public constant DYNAMIC_REWARD_DURATION = 1000000; /// @dev 1000000 seconds = 11.5 days
    bool public constant IS_DYNAMIC = true;

    Staking public staking;
    Token public token;

    function setUp() public {
        staking = new Staking();
        token = new Token("Test Token", "TST", INITIAL_TOKEN_SUPPLY);
        staking.initialize(IERC20Upgradeable(address(token)), IS_DYNAMIC);
        staking.setDynamicRewards(
            DYNAMIC_REWARD_AMOUNT,
            DYNAMIC_REWARD_DURATION
        );
    }

    /// @dev Test stake/withdraw and rewards for a staker if only 1 staker is present from the start to the end
    function testDynamicStakingFlowWithOneStaker() public {
        uint256 amountToStake = INITIAL_TOKEN_SUPPLY;
        token.approve(address(staking), amountToStake);
        staking.stake(amountToStake);

        assertEq(staking.lastUpdateTime(), block.timestamp);

        skip(DYNAMIC_REWARD_DURATION);

        assertEq(staking.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(staking)), amountToStake);
        assertEq(staking.totalStaked(), amountToStake);

        assertEq(
            staking.viewPendingRewards(address(this)),
            DYNAMIC_REWARD_AMOUNT
        );

        staking.withdraw(amountToStake);

        Staking.StakerInfo memory stakerInfo = staking.getStakerInfo(
            address(this)
        );

        assertEq(stakerInfo.stakedAmount, 0);
        assertEq(stakerInfo.lastRewardTimestamp, block.timestamp);
        assertEq(stakerInfo.rewardDebt, DYNAMIC_REWARD_AMOUNT);
    }

    /// @dev Test stake/withdraw and rewards for 2 concurrent stakers if only 2 stakers are present from the start to the end
    function testDynamicStakingFlowWithTwoConcurrentStaker() public {
        uint256 amountToStake = 1 ether;
        address staker2 = address(1);
        token.transfer(staker2, amountToStake);

        token.approve(address(staking), amountToStake);
        staking.stake(amountToStake);

        vm.prank(staker2);
        token.approve(address(staking), amountToStake);
        vm.prank(staker2);
        staking.stake(amountToStake);

        skip(DYNAMIC_REWARD_DURATION);

        assertEq(
            staking.viewPendingRewards(address(this)),
            DYNAMIC_REWARD_AMOUNT / 2
        );
        assertEq(
            staking.viewPendingRewards(staker2),
            DYNAMIC_REWARD_AMOUNT / 2
        );

        staking.withdraw(amountToStake);
        vm.prank(staker2);
        staking.withdraw(amountToStake);

        Staking.StakerInfo memory stakerInfo1 = staking.getStakerInfo(
            address(this)
        );
        Staking.StakerInfo memory stakerInfo2 = staking.getStakerInfo(staker2);

        assertEq(stakerInfo1.stakedAmount, 0);
        assertEq(stakerInfo1.lastRewardTimestamp, block.timestamp);
        assertEq(stakerInfo1.rewardDebt, DYNAMIC_REWARD_AMOUNT / 2);

        assertEq(stakerInfo2.stakedAmount, 0);
        assertEq(stakerInfo2.lastRewardTimestamp, block.timestamp);
        assertEq(stakerInfo2.rewardDebt, DYNAMIC_REWARD_AMOUNT / 2);
    }

    /// @dev Testing the flow of staking/withdrawing and rewards for multiple stakers
    /// @dev When 1 staker stakes initially and the 2nd staker stakes in the middle and hold them till the end
    function testDynamicStakingFlowWith2Stakers() public {
        /// @dev Both of the stakers will stake 1 ether;
        /// @dev staker #1 Will stake it at the start and hold it till the end
        /// @dev staker #2 Will stake it ni the middle and hold it till the end
        /// @dev meaning that by the middle, staker #1 will have maximum rewards earned which is total rewards / 2, because he was only staker
        /// @dev meanwhile during the other half, there are both stakers, so the rewards will be split between them
        /// @dev If the rewards are 10 ether, in the first half staker #1 should earn 5 ether (maximum reward)
        /// @dev and in the second half stakers should split the rewards and earn 2.5-2.5 ethers each
        /// @dev So at the end staker #1 must have 7.5 ethers and staker #2 must have 2.5 ethers

        address staker1 = address(1);
        address staker2 = address(2);
        uint256 amountToStake = 1 ether;
        token.transfer(staker1, amountToStake);
        token.transfer(staker2, amountToStake);

        vm.prank(staker1);
        token.approve(address(staking), amountToStake);
        vm.prank(staker1);
        staking.stake(amountToStake);

        skip(DYNAMIC_REWARD_DURATION / 2);

        assertEq(
            staking.viewPendingRewards(staker1),
            DYNAMIC_REWARD_AMOUNT / 2
        );

        vm.prank(staker2);
        token.approve(address(staking), amountToStake);
        vm.prank(staker2);
        staking.stake(amountToStake);

        skip(DYNAMIC_REWARD_DURATION / 2);

        assertEq(
            staking.viewPendingRewards(staker1),
            (DYNAMIC_REWARD_AMOUNT * 3) / 4
        );
        assertEq(
            staking.viewPendingRewards(staker2),
            (DYNAMIC_REWARD_AMOUNT * 1) / 4
        );

        vm.prank(staker1);
        staking.withdraw(amountToStake);
        vm.prank(staker2);
        staking.withdraw(amountToStake);

        Staking.StakerInfo memory stakerInfo1 = staking.getStakerInfo(staker1);
        Staking.StakerInfo memory stakerInfo2 = staking.getStakerInfo(staker2);

        assertEq(stakerInfo1.stakedAmount, 0);
        assertEq(stakerInfo1.lastRewardTimestamp, block.timestamp);
        assertEq(stakerInfo1.rewardDebt, (DYNAMIC_REWARD_AMOUNT * 3) / 4);

        assertEq(stakerInfo2.stakedAmount, 0);
        assertEq(stakerInfo2.lastRewardTimestamp, block.timestamp);
        assertEq(stakerInfo2.rewardDebt, (DYNAMIC_REWARD_AMOUNT * 1) / 4);
    }

    /// @dev Testing the getRewards functionality when the staking is dynamic
    /// @dev ANd making sure it doesn't mess the rewards for other stakers
    function testGetRewardsWithinTheFlowDynamic() public {
        /// @dev The flow is the same as the previous test (`testDynamicStakingFlowWith2Stakers`), View the detailed explanation there
        /// @dev The catch here is that at the 75%, staker #1 will get his rewards, And this test will make sure
        /// @dev That doesn't mess with the rewards for the stakers.
        address staker1 = address(1);
        address staker2 = address(2);
        uint256 amountToStake = 1 ether;
        token.transfer(staker1, amountToStake);
        token.transfer(staker2, amountToStake);

        vm.prank(staker1);
        token.approve(address(staking), amountToStake);
        vm.prank(staker1);
        staking.stake(amountToStake);

        skip(DYNAMIC_REWARD_DURATION / 2);

        vm.prank(staker2);
        token.approve(address(staking), amountToStake);
        vm.prank(staker2);
        staking.stake(amountToStake);

        skip(DYNAMIC_REWARD_DURATION / 4);

        uint totalRewards = staking.viewPendingRewards(staker1);
        vm.prank(staker1);
        staking.getRewards(totalRewards);

        skip(DYNAMIC_REWARD_DURATION / 4);

        vm.prank(staker1);
        staking.withdraw(amountToStake);
        vm.prank(staker2);
        staking.withdraw(amountToStake);

        Staking.StakerInfo memory stakerInfo1 = staking.getStakerInfo(staker1);
        Staking.StakerInfo memory stakerInfo2 = staking.getStakerInfo(staker2);

        assertEq(stakerInfo1.stakedAmount, 0);
        assertEq(stakerInfo1.lastRewardTimestamp, block.timestamp);
        assertEq(
            stakerInfo1.rewardDebt + staking.balanceOf(staker1),
            (DYNAMIC_REWARD_AMOUNT * 3) / 4
        );

        assertEq(stakerInfo2.stakedAmount, 0);
        assertEq(stakerInfo2.lastRewardTimestamp, block.timestamp);
        assertEq(stakerInfo2.rewardDebt, (DYNAMIC_REWARD_AMOUNT * 1) / 4);
    }

    /// @dev Testing the flow of staking/withdrawing and rewards for multiple stakers
    /// @dev When 1 staker stakes initially and the 2nd staker stakes in the middle and hold them till the end
    function testDynamicStakingFlowWith2StakersAdvanced() public {
        /// @dev staker #1 Will stake 1 ether at the start and hold it till the end
        /// @dev staker #2 Will stake 1 ether in the middle and hold it till the end
        /// @dev staker #1 Will again stake, but now 8 ether in the middle andd hold it till the end
        /// @dev If the rewards are 10 ether, in the first half staker #1 should earn 5 ether (maximum reward)
        /// @dev and in the second half staker #2 will earn 0.5 ether and staker #1 will earn 4.5 ether
        /// @dev So at the end staker #1 must have 9.5 ethers and staker #2 must have 0.5 ethers

        address staker1 = address(1);
        address staker2 = address(2);

        token.transfer(staker1, 9 ether);
        token.transfer(staker2, 1 ether);

        vm.prank(staker1);
        token.approve(address(staking), 1 ether);
        vm.prank(staker1);
        staking.stake(1 ether);

        skip(DYNAMIC_REWARD_DURATION / 2);

        assertEq(
            staking.viewPendingRewards(staker1),
            DYNAMIC_REWARD_AMOUNT / 2
        );

        vm.prank(staker2);
        token.approve(address(staking), 1 ether);
        vm.prank(staker2);
        staking.stake(1 ether);

        vm.prank(staker1);
        token.approve(address(staking), 8 ether);
        vm.prank(staker1);
        staking.stake(8 ether);

        Staking.StakerInfo memory stakerInfo1FirstHalf = staking.getStakerInfo(
            staker1
        );

        skip(DYNAMIC_REWARD_DURATION / 2);

        /// @dev We are adding reward debt because on second stake, the previous rewards are added to the reward debt automatically
        assertEq(
            staking.viewPendingRewards(staker1) +
                stakerInfo1FirstHalf.rewardDebt,
            (DYNAMIC_REWARD_AMOUNT * 95) / 100
        );
        assertEq(
            staking.viewPendingRewards(staker2),
            (DYNAMIC_REWARD_AMOUNT * 5) / 100
        );

        vm.prank(staker1);
        staking.withdraw(9 ether);
        vm.prank(staker2);
        staking.withdraw(1 ether);

        Staking.StakerInfo memory stakerInfo1 = staking.getStakerInfo(staker1);
        Staking.StakerInfo memory stakerInfo2 = staking.getStakerInfo(staker2);

        assertEq(stakerInfo1.stakedAmount, 0);
        assertEq(stakerInfo1.lastRewardTimestamp, block.timestamp);
        assertEq(stakerInfo1.rewardDebt, (DYNAMIC_REWARD_AMOUNT * 95) / 100);

        assertEq(stakerInfo2.stakedAmount, 0);
        assertEq(stakerInfo2.lastRewardTimestamp, block.timestamp);
        assertEq(stakerInfo2.rewardDebt, (DYNAMIC_REWARD_AMOUNT * 5) / 100);
    }
}
