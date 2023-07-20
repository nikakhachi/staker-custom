// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./Math.sol";

/// @title Staking Contract
/// @author Nika Khachiashvili
contract Staking is
    Initializable,
    OwnableUpgradeable,
    ERC20PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Staked(address indexed user, uint256 indexed amount);
    event Withdrawn(address indexed user, uint256 indexed amount);

    struct StakerInfo {
        uint256 stakedAmount;
        uint256 lastRewardTimestamp;
        uint256 rewardDebt;
    }

    IERC20Upgradeable public token; /// @dev The token that will be staked

    uint256 public staticInterestRate; /// @dev FORMAT: 1 ether = 100%
    uint256 public dynamicRewardsRate; /// @dev Total Rewards / Duration
    uint256 public dynamicRewardsFinishAt; /// @dev Timestamp when the rewards will stop being given out
    bool public isStakingDynamic; /// @dev If the staking is dynamic or static
    bool public isAutoCompound; /// @dev If the rewards are automatically added to the stakers wallet or not

    mapping(address => StakerInfo) public stakers; /// @dev Staker info

    uint256 public totalStaked; /// @dev Total amount of tokens staked

    /// @dev Required variables for dynamic staking
    mapping(address => uint) public userRewardPerTokenPaid; /// @dev Last reward per token paid of user
    uint256 public rewardPerToken; /// @dev Reward per token
    uint256 public lastUpdateTime; /// @dev Last timestamp when someone staked or withdrew

    /// @dev Contract Initializer
    /// @dev Runs only once on deployment
    /// @param _token token to be staked
    /// @param _isStakingDynamic if the staking is dynamic or static
    /// @param _isAutoCompound if the rewards are automatically added to the stakers wallet or not
    function initialize(
        IERC20Upgradeable _token,
        bool _isStakingDynamic,
        bool _isAutoCompound
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ERC20_init("Staking Token", "STK");
        token = _token;
        isStakingDynamic = _isStakingDynamic;
        isAutoCompound = _isAutoCompound;
    }

    /// @notice Function for staking tokens
    /// @param _amount The amount of tokens to be staked
    function stake(uint256 _amount) external whenNotPaused {
        StakerInfo storage staker = stakers[msg.sender];

        bool _isStakingDynamic = isStakingDynamic;
        if (_isStakingDynamic) {
            require(block.timestamp < dynamicRewardsFinishAt);
        } else {
            require(staticInterestRate > 0);
        }

        _handleRewards(staker, _isStakingDynamic);

        token.safeTransferFrom(msg.sender, address(this), _amount);

        staker.stakedAmount += _amount;
        totalStaked += _amount;

        emit Staked(msg.sender, _amount);
    }

    /// @notice Function for withdrawing
    /// @param _amount The amount of tokens to be withdrawn
    function withdraw(uint256 _amount) external whenNotPaused {
        StakerInfo storage staker = stakers[msg.sender];

        bool _isStakingDynamic = isStakingDynamic;
        _handleRewards(staker, _isStakingDynamic);

        staker.stakedAmount -= _amount;
        totalStaked -= _amount;

        token.safeTransfer(msg.sender, _amount);

        emit Withdrawn(msg.sender, _amount);
    }

    /// @notice Owner's function for setting rewards if the contract is dynamic
    /// @param _amount The amount of tokens to be given out
    /// @param _duration The duration of giving out the rewards
    function setDynamicRewards(
        uint256 _amount,
        uint256 _duration
    ) external onlyOwner {
        require(dynamicRewardsFinishAt < block.timestamp); /// @dev Make sure contract isn't giving rewards anymore
        require(_amount > 0); /// @dev Make sure rewards amount is more than 0
        dynamicRewardsFinishAt = block.timestamp + _duration;
        dynamicRewardsRate = _amount / _duration;
        lastUpdateTime = block.timestamp;
    }

    /// @notice Owner's function for setting static rewards if the contract is static
    function setStaticRewards(uint256 _staticInterestRate) external onlyOwner {
        require(_staticInterestRate > 0);
        staticInterestRate = _staticInterestRate;
    }

    /// @notice Get the staker info
    /// @param _address The address of the staker
    /// @return The staker info
    function getStakerInfo(
        address _address
    ) external view returns (StakerInfo memory) {
        return stakers[_address];
    }

    /// @dev calculating the pending rewards if the contract is static
    /// @param stakerInfo The staker info
    /// @return totalReward The pending rewards
    function _calculatePendingRewardStatic(
        StakerInfo storage stakerInfo
    ) internal view returns (uint256 totalReward) {
        uint256 secondsSinceLastReward = block.timestamp -
            stakerInfo.lastRewardTimestamp;

        totalReward =
            (stakerInfo.stakedAmount *
                staticInterestRate *
                secondsSinceLastReward) /
            365 days /
            1 ether;
    }

    /// @dev calculating the pending rewards and the new reward per token if the contract is dynamic
    /// @param stakerInfo The staker info
    /// @param _staker The address of the staker
    /// @return totalReward The pending rewards
    /// @return newRewardPerToken The pending rewards
    function _calculatePendingRewardDynamic(
        StakerInfo storage stakerInfo,
        address _staker
    ) internal view returns (uint256 totalReward, uint256 newRewardPerToken) {
        newRewardPerToken =
            rewardPerToken +
            ((dynamicRewardsRate * (_lastApplicableTime() - lastUpdateTime)) *
                1 ether) /
            totalStaked;
        totalReward =
            (stakerInfo.stakedAmount *
                (newRewardPerToken - userRewardPerTokenPaid[_staker])) /
            1 ether;
    }

    /// @dev Calculates the rewards and handles them (updating states and transfering them if autocompound is enabled)
    /// @param staker The staker info
    /// @param _isStakingDynamic If the staking is dynamic or static
    /// @return pendingReward The pending rewards
    function _handleRewards(
        StakerInfo storage staker,
        bool _isStakingDynamic
    ) internal returns (uint256 pendingReward) {
        if (_isStakingDynamic) {
            /// @dev We need this check here because if totalStaked is 0 and the first ever staker wants to stake,
            /// @dev calculation will fail because the formula includes division by totalStaked
            if (totalStaked > 0) {
                (
                    uint256 _pendingReward,
                    uint256 newRewardPerToken
                ) = _calculatePendingRewardDynamic(staker, msg.sender);
                pendingReward = _pendingReward;
                rewardPerToken = newRewardPerToken;
                userRewardPerTokenPaid[msg.sender] = rewardPerToken;
            }
            lastUpdateTime = _lastApplicableTime();
        } else {
            pendingReward = _calculatePendingRewardStatic(staker);
        }

        /// @dev Since the rewards are given out in another token than the staking token,
        /// @dev We will just mint them. If it was the same token as staking,
        /// @dev We would add it to the stakedAmount of staker and also totalStaked so extra
        /// @dev reward can be generated on it
        if (isAutoCompound) {
            _mint(msg.sender, pendingReward);
        } else {
            staker.rewardDebt += pendingReward;
        }
        staker.lastRewardTimestamp = block.timestamp;
    }

    /// @notice View the pending rewards of the provided address
    /// @param _address The address of the staker
    /// @return pendingRewards The pending rewards
    function viewPendingRewards(
        address _address
    ) external view returns (uint256 pendingRewards) {
        StakerInfo storage staker = stakers[_address];
        if (isStakingDynamic) {
            (pendingRewards, ) = _calculatePendingRewardDynamic(
                staker,
                _address
            );
        } else {
            pendingRewards = _calculatePendingRewardStatic(staker);
        }
    }

    /// @notice Claim the rewards in wallet
    /// @param _amount The amount of tokens to be claimed
    function getRewards(uint256 _amount) external {
        StakerInfo storage staker = stakers[msg.sender];

        bool _isStakingDynamic = isStakingDynamic;
        _handleRewards(staker, _isStakingDynamic);

        staker.rewardDebt -= _amount;

        _mint(msg.sender, _amount);
    }

    /// @dev When calculating rewards, we want to don't want to include the current timestamp
    /// @dev in the calculations if the contract isn't giving out rewards anymore.
    /// @dev Returns the last applicable time based on the current time and the finish time of giving rewards.
    /// @return The last applicable time.
    function _lastApplicableTime() internal view returns (uint) {
        return Math.min(block.timestamp, dynamicRewardsFinishAt);
    }

    /// @notice Owner's function to mint tokens for specific address
    /// @param _amount The amount of tokens to be minted
    /// @param _address The address of the receiver
    function mint(uint256 _amount, address _address) external onlyOwner {
        _mint(_address, _amount);
    }

    /// @notice Owner's function to burn tokens from his account
    /// @param _amount The amount of tokens to be burned
    function burn(uint256 _amount) external onlyOwner {
        _burn(msg.sender, _amount);
    }

    /// @notice Owner's function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Owner's function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Function for upgrading the contract
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
