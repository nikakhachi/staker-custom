// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Staking.t.sol";

/**
 * @title PausableTest Contract
 * @author Nika Khachiashvili
 * @dev Test cases for Staking Contract Pausable Actions
 */
contract PausableTest is StakingTest {
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
}
