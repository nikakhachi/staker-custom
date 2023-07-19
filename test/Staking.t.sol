// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/Staking.sol";

/**
 * @title StakingTest Contract
 * @author Nika Khachiashvili
 * @dev Test cases for Staking Contract
 */
contract StakingTest is Test {
    Staking public staking;

    function setUp() public {
        staking = new Staking();
        staking.initialize(
            IERC20Upgradeable(address(0)),
            0.1 ether,
            1 ether,
            100 days,
            false
        );
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
