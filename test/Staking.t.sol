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
}
