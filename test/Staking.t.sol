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
    uint256 public constant DYNAMIC_REWARD_AMOUNT = 1 ether;
    uint256 public constant DYNAMIC_REWARD_DURATION = 100 days;
    bool public constant IS_DYNAMIC = false;

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

    /// @dev Test staking when the contract is paused
    function testStakeWhenPaused() public {
        staking.pause();
        vm.expectRevert(bytes("Pausable: paused"));
        staking.stake(1 ether);
    }

    /// @dev Test withdrawing when the contract is paused
    function testWithdrawWhenPaused() public {
        uint256 amountToStake = INITIAL_TOKEN_SUPPLY;
        token.approve(address(staking), amountToStake);
        staking.stake(amountToStake);

        staking.pause();
        vm.expectRevert(bytes("Pausable: paused"));
        staking.withdraw(amountToStake);
    }

    /// @dev testing pause functionality
    function testPause() public {
        staking.pause();
        vm.expectRevert(bytes("ERC20Pausable: token transfer while paused"));
        staking.mint(1 ether, address(this));
    }

    /// @dev testing unpause functionality
    function testUnpause() public {
        staking.pause();
        staking.unpause();
        staking.mint(1 ether, address(this));
    }

    /// @dev testing mint functionality
    function testMint() public {
        staking.mint(1 ether, address(this));
        assertEq(staking.balanceOf(address(this)), 1 ether);

        staking.mint(10 ether, address(1));
        assertEq(staking.balanceOf(address(1)), 10 ether);
    }

    /// @dev testing burn functionality
    function testBurn() public {
        staking.mint(1 ether, address(this));
        staking.burn(0.5 ether);
        assertEq(staking.balanceOf(address(this)), 0.5 ether);
    }

    /// @dev testing if it reverts when calling pause functionality as non-owner
    function testUnauthorizedPause() public {
        vm.prank(address(1));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        staking.pause();
    }

    /// @dev testing if it reverts when calling unpause functionality as non-owner
    function testUnauthorizedUnpause() public {
        staking.pause();
        vm.prank(address(1));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        staking.unpause();
    }

    /// @dev testing if it reverts when calling mint functionality as non-owner
    function testUnauthorizedMint() public {
        vm.prank(address(1));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        staking.mint(1 ether, address(1));
    }

    /// @dev testing if it reverts when calling burn functionality as non-owner
    function testUnauthorizedBurn() public {
        staking.mint(1 ether, address(this));
        vm.prank(address(1));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        staking.burn(0.5 ether);
    }
}
