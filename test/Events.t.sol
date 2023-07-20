// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @dev Doesn't matter if it imports Static or Dynamic, underlying Pausable mechanism is the same
import "./StaticStaking.t.sol";

/**
 * @title EventsTest Contract
 * @author Nika Khachiashvili
 * @dev Test cases for Staking Contract Events
 */
contract EventsTest is StaticStakingTest {
    /// @dev redeclaring events for comparsion
    event Staked(address indexed user, uint256 indexed amount);
    event Withdrawn(address indexed user, uint256 indexed amount);

    /// @dev Test "Staked" event on stake
    function testStakedEvent() public {
        uint256 amountToStake = INITIAL_TOKEN_SUPPLY;
        token.approve(address(staking), amountToStake);

        vm.expectEmit(true, true, false, false);
        emit Staked(address(this), amountToStake);
        staking.stake(amountToStake);
    }

    /// @dev Test "Withdrawn" event on stake
    function testWithdrawnEvent() public {
        uint256 amountToStake = INITIAL_TOKEN_SUPPLY;
        token.approve(address(staking), amountToStake);
        staking.stake(amountToStake);

        vm.expectEmit(true, true, false, false);
        emit Withdrawn(address(this), amountToStake);
        staking.withdraw(amountToStake);
    }
}
