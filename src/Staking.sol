// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PausableUpgradeable.sol";

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
    uint256 public dynamicRewardAmount;
    uint256 public dynamicRewardDuration;
    bool public isStakingDynamic;

    mapping(address => StakerInfo) public stakers;

    uint256 public totalStaked;

    function initialize(
        IERC20Upgradeable _token,
        uint256 _staticInterestRate,
        uint256 _dynamicRewardAmount,
        uint256 _dynamicRewardDuration,
        bool _isStakingDynamic
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ERC20_init("Staking Token", "STK");

        token = _token;
        staticInterestRate = _staticInterestRate;
        dynamicRewardAmount = _dynamicRewardAmount;
        dynamicRewardDuration = _dynamicRewardDuration;
        isStakingDynamic = _isStakingDynamic;
    }

    function stake(uint256 _amount) external {
        StakerInfo storage staker = stakers[msg.sender];

        if (staker.stakedAmount > 0) {
            uint256 pendingReward = _calculatePendingReward(staker);
            if (pendingReward > 0) staker.rewardDebt += pendingReward;
        }

        staker.lastRewardTimestamp = block.timestamp;

        token.safeTransferFrom(msg.sender, address(this), _amount);

        staker.stakedAmount += _amount;
        totalStaked += _amount;

        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        StakerInfo storage staker = stakers[msg.sender];

        uint256 pendingReward = _calculatePendingReward(staker);
        if (pendingReward > 0) staker.rewardDebt += pendingReward;

        staker.stakedAmount -= _amount;
        totalStaked -= _amount;

        token.safeTransfer(msg.sender, _amount);

        emit Withdrawn(msg.sender, _amount);
    }

    function getStakerInfo(
        address _address
    ) external view returns (StakerInfo memory) {
        return stakers[_address];
    }

    function _calculatePendingReward(
        StakerInfo storage staker
    ) internal view returns (uint256 totalReward) {
        if (
            staker.stakedAmount == 0 ||
            block.timestamp <= staker.lastRewardTimestamp
        ) {
            return 0;
        }

        uint256 secondsSinceLastReward = block.timestamp -
            staker.lastRewardTimestamp;

        if (isStakingDynamic) {
            // TODO: Calculate dynamic reward
        } else {
            totalReward =
                (staker.stakedAmount *
                    staticInterestRate *
                    secondsSinceLastReward) /
                365 days /
                1 ether;
        }
    }

    function viewPendingRewards(
        address _address
    ) external view returns (uint256) {
        StakerInfo storage staker = stakers[_address];
        return _calculatePendingReward(staker);
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
