// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "./Math.sol";

contract Staking is
    Initializable,
    OwnableUpgradeable,
    ERC20PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Staked(address indexed user, uint256 indexed amount);
    event Withdrawn(address indexed user, uint256 indexed amount);

    struct StakerInfo {
        uint256 stakedAmount;
        uint256 lastRewardTimestamp;
        uint256 rewardDebt;
    }

    IERC20Upgradeable public token;

    uint256 public staticInterestRate; /// @dev FORMAT: 1 ether = 100%
    uint256 public dynamicRewardsRate;
    uint256 public dynamicRewardsFinishAt;
    bool public isStakingDynamic;

    mapping(address => StakerInfo) public stakers;

    uint256 public totalStaked;

    /// @dev Required variables for dynamic staking
    mapping(address => uint) public userRewardPerTokenPaid;
    uint public rewardPerToken;
    uint public lastUpdateTime; /// @dev Last timestamp when someone staked or withdrew

    function initialize(
        IERC20Upgradeable _token,
        bool _isStakingDynamic
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ERC20_init("Staking Token", "STK");
        token = _token;
        isStakingDynamic = _isStakingDynamic;
    }

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

    function withdraw(uint256 _amount) external whenNotPaused {
        StakerInfo storage staker = stakers[msg.sender];

        bool _isStakingDynamic = isStakingDynamic;
        _handleRewards(staker, _isStakingDynamic);

        staker.stakedAmount -= _amount;
        totalStaked -= _amount;

        token.safeTransfer(msg.sender, _amount);

        emit Withdrawn(msg.sender, _amount);
    }

    function setDynamicRewards(
        uint _amount,
        uint _duration
    ) external onlyOwner {
        require(dynamicRewardsFinishAt < block.timestamp); /// @dev Make sure contract isn't giving rewards anymore
        require(_amount > 0); /// @dev Make sure rewards amount is more than 0
        dynamicRewardsFinishAt = block.timestamp + _duration;
        dynamicRewardsRate = _amount / _duration;
        lastUpdateTime = block.timestamp;
    }

    function setStaticRewards(uint _staticInterestRate) external onlyOwner {
        require(_staticInterestRate > 0);
        staticInterestRate = _staticInterestRate;
    }

    function getStakerInfo(
        address _address
    ) external view returns (StakerInfo memory) {
        return stakers[_address];
    }

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

    function _handleRewards(
        StakerInfo storage staker,
        bool _isStakingDynamic
    ) internal returns (uint256 pendingReward) {
        if (_isStakingDynamic) {
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
        staker.rewardDebt += pendingReward;
        staker.lastRewardTimestamp = block.timestamp;
    }

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
