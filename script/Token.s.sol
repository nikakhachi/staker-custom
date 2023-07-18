// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import "../src/Token.sol";
import "forge-std/console.sol";

contract Deploy is Script {
    string public constant TOKEN_NAME = "Token Name Here";
    string public constant TOKEN_SYMBOL = "Token Symbol Here";

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Token token = new Token(TOKEN_NAME, TOKEN_SYMBOL);
        console.log("Token Deployed To: ", address(token));

        vm.stopBroadcast();
    }
}
