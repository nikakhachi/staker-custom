// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Staking.sol";

/// @title StakingV2 Contract
/// @author Nika Khachiashvili
/// @dev This contract is JUST FOR DEMONSTRATION PURPOSES for Upgrades
contract StakingV2 is Staking {
    /// @return the version of the contract
    function version() external pure returns (string memory) {
        return "v2";
    }
}
