# Custom Staking Smart Contract

This smart contract implements an upgradeable staking contract, which can be set to dynamic/static by the deployer, where users can deposit their assets and earn interest.

The development tool used is the Foundry where the contracts and the tests are written, and then there's hardhat integrated which is used for writing the deployment and upgrade scripts.

## Table of Contents

- [Features](#features)
- [Testing](#testing)
- [Deploying](#deploying)

## Features

- **_stake_** - Users can stake their assets to start earning rewards by calling this function. This function will automatically calculate any previous pending rewards of the user and based on if the contract is autocompound or not, will transfer the rewards automatically to users balance or not. Event _Staked_ will be fired. This function can't be called if the contract is paused.

- **_withdraw_** - Users can call this function to withdraw any amount of the staked asset. This function will automatically calculate any previous pending rewards of the user and based on if the contract is autocompound or not, will transfer the rewards automatically to users balance or not. Event _Withdrawn_ will be fired. This function can't be called if the contract is paused.

- **_viewPendingRewards_** - By passing the address to this function, everyone can see the pending rewards of the any address. The rewards returned by this function is the amount of the rewards to be given out based on the staked amount and the timestamp of the last given reward to that address.

- **_getRewards_** - By calling this function, users can withdraw the rewards. There is no specific check for the amount requested, but if the amount requested exceedes the rewards amount that should be given out to user, the transaction will revert due to underflow.

- **_getStakerInfo_** - Get the info of ny staker by providing the address.

- **_setDynamicRewards_** - Owners function to set the amount of the rewards and the duration when the rewards will be given out. Calling this function is only possible if the previous reward giving has ended and the reward amount specified is more than 0. If the contract is static staking, this transaction will not revert, but it won't mess with the static staking flow.

- **_setStaticRewards_** - Owners function to set the annual interest rate for the rewards token, when the staking is static, can only be called once after the deployment, if the rate is already set it can't be changed anymore. If the contract is dynamic staking, this transaction will not revert, but it won't mess with the static staking flow.

- **_mint_** - Owners function to mint the specified amount of tokens to any address

- **_burn_** - Owners function to burn their tokens. Owner can't burn others tokens with this function

- **_pause_** - Owners function to pause the contract

- **_unpause_** - Owners function to unpause the contract

## Testing

To run the tests, you will have to do the following

1. Clone this repository to your local machine.
2. Run `forge install`.
3. Run `forge test` (this will also automatically compile the contracts).

## Deploying

To deploy the contract, you will have to do the following

1. Clone this repository to your local machine.
2. Run `forge install && npm install`.
3. Deploy the smart contract with ` npx hardhat run script/deploy.ts --network {network name}`

If you would like to deploy it locally, make sure to run `npx hardhat node` before the 3rd step, and deploy the smart contract with `localhost` as the "network name"
