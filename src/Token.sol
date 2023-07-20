// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "openzeppelin/token/ERC20/ERC20.sol";

/**
 * @title Token Contract
 * @author Nika Khachiashvili
 * @dev A basic ERC20 token contract.
 * @dev IMPORTANT: This token contract IS NOT the one from the Challenge.
 * @dev IMPORTANT: The ERC20 Contract that is described in the tech challenge is implemented in Staking.sol itself
 */
contract Token is ERC20 {
    /**
     * @dev Contract constructor.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     * @param _initialSupply The initial supply of tokens.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint _initialSupply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _initialSupply);
    }
}
