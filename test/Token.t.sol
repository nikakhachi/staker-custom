// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/Token.sol";

/**
 * @title TokenTest Contract
 * @author Nika Khachiashvili
 * @dev Test cases for Token Contract
 * @dev It's true that OpenZeppelin has well audited contracts but let's still make sure we did
 * @dev the setup correctly
 */
contract TokenTest is Test {
    Token public token;

    function setUp() public {
        token = new Token("Test Token", "TTT");
    }

    /// @dev testing pause functionality
    function testPause() public {
        token.pause();
        vm.expectRevert(bytes("ERC20Pausable: token transfer while paused"));
        token.mint(1 ether, address(this));
    }

    /// @dev testing unpause functionality
    function testUnpause() public {
        token.pause();
        token.unpause();
        token.mint(1 ether, address(this));
    }

    /// @dev testing mint functionality
    function testMint() public {
        token.mint(1 ether, address(this));
        assertEq(token.balanceOf(address(this)), 1 ether);

        token.mint(10 ether, address(1));
        assertEq(token.balanceOf(address(1)), 10 ether);
    }

    /// @dev testing burn functionality
    function testBurn() public {
        token.mint(1 ether, address(this));
        token.burn(0.5 ether);
        assertEq(token.balanceOf(address(this)), 0.5 ether);
    }

    /// @dev testing if it reverts when calling pause functionality as non-owner
    function testUnauthorizedPause() public {
        vm.prank(address(1));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        token.pause();
    }

    /// @dev testing if it reverts when calling unpause functionality as non-owner
    function testUnauthorizedUnpause() public {
        token.pause();
        vm.prank(address(1));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        token.unpause();
    }

    /// @dev testing if it reverts when calling mint functionality as non-owner
    function testUnauthorizedMint() public {
        vm.prank(address(1));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        token.mint(1 ether, address(1));
    }

    /// @dev testing if it reverts when calling burn functionality as non-owner
    function testUnauthorizedBurn() public {
        token.mint(1 ether, address(this));
        vm.prank(address(1));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        token.burn(0.5 ether);
    }
}
