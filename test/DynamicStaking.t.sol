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
        staking.initialize(
            IERC20Upgradeable(address(token)),
            STATIC_INTEREST_RATE,
            DYNAMIC_REWARD_AMOUNT,
            DYNAMIC_REWARD_DURATION,
            IS_DYNAMIC
        );
    }

    /// @dev Test rewards for a staker if only 1 staker is present from the start to the end
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
    }

    /// @dev Test rewards for a 2 concurrent stakers if only 2 stakers are present from the start to the end
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
    }
}
