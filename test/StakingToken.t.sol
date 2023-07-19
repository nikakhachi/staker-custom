// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @dev Doesn't matter if it imports Static or Dynamic, underlying Staking Token mechanism is the same
import "./StaticStaking.t.sol";

/**
 * @title StakingTokenTest Contract
 * @author Nika Khachiashvili
 * @dev Test cases for Staking Contract Token Actions
 */
contract StakingTokenTest is StaticStakingTest {
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
