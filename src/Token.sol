// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "openzeppelin/token/ERC20/extensions/ERC20Pausable.sol";
import "openzeppelin/access/Ownable.sol";

/**
 * @title Token Contract
 * @author Nika Khachiashvili
 * @dev A basic ERC20 token contract.
 */
contract Token is Ownable, ERC20Pausable {
    /**
     * @dev Contract constructor.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     */
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {}

    function mint(uint256 _amount, address _address) external onlyOwner {
        _mint(_address, _amount);
    }

    function burn(uint256 _amount) external onlyOwner {
        _burn(msg.sender, _amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
