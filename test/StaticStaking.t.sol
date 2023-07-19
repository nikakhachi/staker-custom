// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Staking.t.sol";

/**
 * @title StaticStakingTest Contract
 * @author Nika Khachiashvili
 * @dev Test cases for Actions and Functionalities for Static Staking
 */
contract StaticStakingTest is StakingTest {
    /// @dev Test staking when user hasn't previously staked and the staking is static
    function testInitialStakeStatic() public {
        uint256 amountToStake = INITIAL_TOKEN_SUPPLY;
        token.approve(address(staking), amountToStake);
        staking.stake(amountToStake);

        assertEq(staking.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(staking)), amountToStake);
        assertEq(staking.totalStaked(), amountToStake);

        Staking.StakerInfo memory staker = staking.getStakerInfo(address(this));
        assertEq(staker.stakedAmount, amountToStake);
        assertEq(staker.lastRewardTimestamp, block.timestamp);
        assertEq(staker.rewardDebt, 0);
    }

    /// @dev Test staking when user has already staked and the staking is static
    function testSecondStakeStatic() public {
        uint256 amountToStake = INITIAL_TOKEN_SUPPLY / 2;
        token.approve(address(staking), amountToStake);
        staking.stake(amountToStake);

        uint interval = 100 days;

        skip(interval);

        token.approve(address(staking), amountToStake);
        staking.stake(amountToStake);

        assertEq(staking.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(staking)), amountToStake * 2);
        assertEq(staking.totalStaked(), amountToStake * 2);

        Staking.StakerInfo memory staker = staking.getStakerInfo(address(this));
        assertEq(staker.stakedAmount, amountToStake * 2);
        assertEq(staker.lastRewardTimestamp, block.timestamp);
        assertEq(
            staker.rewardDebt,
            _calculateStaticRewards(
                amountToStake,
                interval,
                STATIC_INTEREST_RATE
            )
        );
    }

    /// @dev Test if the pending rewards are calculated correctly
    function testPendingRewardsStatic() public {
        uint256 amountToStake = INITIAL_TOKEN_SUPPLY;
        token.approve(address(staking), amountToStake);
        staking.stake(amountToStake);

        uint interval = 10 days;

        skip(interval);

        uint stakerInfo = staking.viewPendingRewards(address(this));
        assertEq(
            stakerInfo,
            _calculateStaticRewards(
                amountToStake,
                interval,
                STATIC_INTEREST_RATE
            )
        );
    }

    /// @dev Test withdrawing when the staking is static
    function testPendingRewardStaticCalculation() public {
        uint256 amountToStake = INITIAL_TOKEN_SUPPLY;
        token.approve(address(staking), amountToStake);
        staking.stake(amountToStake);

        uint interval = 100 days;

        skip(interval);

        assertEq(
            staking.viewPendingRewards(address(this)),
            _calculateStaticRewards(
                amountToStake,
                interval,
                STATIC_INTEREST_RATE
            )
        );
    }

    /// @dev Test withdrawing when the staking is static
    function testWithdrawStatic() public {
        uint256 amountToStake = INITIAL_TOKEN_SUPPLY;
        token.approve(address(staking), amountToStake);
        staking.stake(amountToStake);

        uint interval = 100 days;

        skip(interval);

        staking.withdraw(amountToStake);

        assertEq(staking.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(this)), INITIAL_TOKEN_SUPPLY);
        assertEq(token.balanceOf(address(staking)), 0);
        assertEq(staking.totalStaked(), 0);

        Staking.StakerInfo memory stakerInfo = staking.getStakerInfo(
            address(this)
        );
        assertEq(stakerInfo.stakedAmount, 0);
        assertEq(stakerInfo.lastRewardTimestamp, block.timestamp);
        assertEq(
            stakerInfo.rewardDebt,
            _calculateStaticRewards(
                amountToStake,
                interval,
                STATIC_INTEREST_RATE
            )
        );
    }

    function _calculateStaticRewards(
        uint256 _amount,
        uint256 _interval,
        uint256 _interestRate
    ) internal pure returns (uint256) {
        return (_amount * _interestRate * _interval) / 1 ether / 365 days;
    }
}
