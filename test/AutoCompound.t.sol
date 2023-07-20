// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/Staking.sol";
import "../src/Token.sol";

/**
 * @title AutoCompoundTest Contract
 * @author Nika Khachiashvili
 * @dev Test cases for AutoCompound feature
 */
contract AutoCompoundTest is Test {
    uint256 public constant INITIAL_TOKEN_SUPPLY = 1000 ether;
    uint256 public constant STATIC_INTEREST_RATE = 0.1 ether;
    uint256 public constant DYNAMIC_REWARD_AMOUNT = 1 ether;
    uint256 public constant DYNAMIC_REWARD_DURATION = 100 days;
    bool public constant IS_DYNAMIC = false;

    Staking public staking;
    Token public token;

    function setUp() public {
        staking = new Staking();
        token = new Token("Test Token", "TST", INITIAL_TOKEN_SUPPLY);
        staking.initialize(IERC20Upgradeable(address(token)), IS_DYNAMIC, true);
        staking.setStaticRewards(STATIC_INTEREST_RATE);
    }

    /// @dev Test if funds are automatically transfered to my wallet on stake (not the first time)
    function testAutoCompoundOnStake() public {
        uint256 amountToStake = INITIAL_TOKEN_SUPPLY / 2;
        token.approve(address(staking), amountToStake);
        staking.stake(amountToStake);

        uint256 interval = 365 days;

        skip(interval);

        token.approve(address(staking), amountToStake);
        staking.stake(amountToStake);

        assertEq(
            staking.balanceOf(address(this)),
            (amountToStake * STATIC_INTEREST_RATE) / 1 ether
        );

        Staking.StakerInfo memory staker = staking.getStakerInfo(address(this));
        assertEq(staker.stakedAmount, amountToStake * 2);
        assertEq(staker.lastRewardTimestamp, block.timestamp);
        assertEq(staker.rewardDebt, 0);
    }

    /// @dev Test if funds are automatically transfered to my wallet on withdraw
    function testAutoCompoundOnWithdraw() public {
        uint256 amountToStake = INITIAL_TOKEN_SUPPLY / 2;
        token.approve(address(staking), amountToStake);
        staking.stake(amountToStake);

        uint256 interval = 365 days;

        skip(interval);

        staking.withdraw(amountToStake);

        assertEq(
            staking.balanceOf(address(this)),
            (amountToStake * STATIC_INTEREST_RATE) / 1 ether
        );

        Staking.StakerInfo memory staker = staking.getStakerInfo(address(this));
        assertEq(staker.stakedAmount, 0);
        assertEq(staker.lastRewardTimestamp, block.timestamp);
        assertEq(staker.rewardDebt, 0);
    }
}
