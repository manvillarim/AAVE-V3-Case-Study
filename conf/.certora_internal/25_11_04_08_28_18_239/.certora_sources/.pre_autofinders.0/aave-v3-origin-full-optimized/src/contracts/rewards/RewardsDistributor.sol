// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IScaledBalanceToken} from '../interfaces/IScaledBalanceToken.sol';
import {IERC20Detailed} from '../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {SafeCast} from '../dependencies/openzeppelin/contracts/SafeCast.sol';
import {IRewardsDistributor} from './interfaces/IRewardsDistributor.sol';
import {RewardsDataTypes} from './libraries/RewardsDataTypes.sol';

abstract contract RewardsDistributor is IRewardsDistributor {
  using SafeCast for uint256;

  error OnlyEmissionManager();
  error InvalidInput();
  error DistributionDoesNotExist();
  error IndexOverflow();

  address public immutable EMISSION_MANAGER;
  address internal _emissionManager;

  mapping(address => RewardsDataTypes.AssetData) internal _assets;
  mapping(address => bool) internal _isRewardEnabled;
  address[] internal _rewardsList;
  address[] internal _assetsList;

  modifier onlyEmissionManager() {
    if (msg.sender != EMISSION_MANAGER) revert OnlyEmissionManager();
    _;
  }

  constructor(address emissionManager) {
    EMISSION_MANAGER = emissionManager;
  }

  function getRewardsData(
    address asset,
    address reward
  ) external view override returns (uint256, uint256, uint256, uint256) {
    return (
      _assets[asset].rewards[reward].index,
      _assets[asset].rewards[reward].emissionPerSecond,
      _assets[asset].rewards[reward].lastUpdateTimestamp,
      _assets[asset].rewards[reward].distributionEnd
    );
  }

  function getAssetIndex(
    address asset,
    address reward
  ) external view override returns (uint256, uint256) {
    RewardsDataTypes.RewardData storage rewardData = _assets[asset].rewards[reward];
    return
      _getAssetIndex(
        rewardData,
        IScaledBalanceToken(asset).scaledTotalSupply(),
        10 ** _assets[asset].decimals
      );
  }

  function getDistributionEnd(
    address asset,
    address reward
  ) external view override returns (uint256) {
    return _assets[asset].rewards[reward].distributionEnd;
  }

  function getRewardsByAsset(address asset) external view override returns (address[] memory availableRewards) {
    uint128 rewardsCount = _assets[asset].availableRewardsCount;
    availableRewards = new address[](rewardsCount);

    for (uint128 i; i < rewardsCount; ++i) {
      availableRewards[i] = _assets[asset].availableRewards[i];
    }
  }

  function getRewardsList() external view override returns (address[] memory rewardsList) {
    rewardsList = _rewardsList;
  }

  function getUserAssetIndex(
    address user,
    address asset,
    address reward
  ) external view override returns (uint256) {
    return _assets[asset].rewards[reward].usersData[user].index;
  }

  function getUserAccruedRewards(
    address user,
    address reward
  ) external view override returns (uint256 totalAccrued) {
    uint256 assetsListLength = _assetsList.length;
    for (uint256 i; i < assetsListLength; ++i) {
      totalAccrued += _assets[_assetsList[i]].rewards[reward].usersData[user].accrued;
    }
  }

  function getUserRewards(
    address[] calldata assets,
    address user,
    address reward
  ) external view override returns (uint256) {
    return _getUserReward(user, reward, _getUserAssetBalances(assets, user));
  }

  function getAllUserRewards(
    address[] calldata assets,
    address user
  )
    external
    view
    override
    returns (address[] memory rewardsList, uint256[] memory unclaimedAmounts)
  {
    RewardsDataTypes.UserAssetBalance[] memory userAssetBalances = _getUserAssetBalances(
      assets,
      user
    );
    uint256 rewardsListLength = _rewardsList.length;
    rewardsList = new address[](rewardsListLength);
    unclaimedAmounts = new uint256[](rewardsListLength);

    uint256 userAssetBalancesLength = userAssetBalances.length;
    for (uint256 i; i < userAssetBalancesLength; ++i) {
      for (uint256 r; r < rewardsListLength; ++r) {
        rewardsList[r] = _rewardsList[r];
        unclaimedAmounts[r] += _assets[userAssetBalances[i].asset]
          .rewards[rewardsList[r]]
          .usersData[user]
          .accrued;

        if (userAssetBalances[i].userBalance != 0) {
          unclaimedAmounts[r] += _getPendingRewards(user, rewardsList[r], userAssetBalances[i]);
        }
      }
    }
  }

  function setDistributionEnd(
    address asset,
    address reward,
    uint32 newDistributionEnd
  ) external override onlyEmissionManager {
    (uint104 index, uint88 emissionPerSecond, uint32 oldDistributionEnd)
      = (_assets[asset].rewards[reward].index,
         _assets[asset].rewards[reward].emissionPerSecond,
         _assets[asset].rewards[reward].distributionEnd);

    _assets[asset].rewards[reward].distributionEnd = newDistributionEnd;

    emit AssetConfigUpdated(
      asset,
      reward,
      emissionPerSecond,
      emissionPerSecond,
      oldDistributionEnd,
      newDistributionEnd,
      index
    );
  }

  function setEmissionPerSecond(
    address asset,
    address[] calldata rewards,
    uint88[] calldata newEmissionsPerSecond
  ) external override onlyEmissionManager {
    if (rewards.length != newEmissionsPerSecond.length) revert InvalidInput();
    uint256 rewardsLength = rewards.length;
    for (uint256 i; i < rewardsLength; ++i) {
      RewardsDataTypes.AssetData storage assetConfig = _assets[asset];
      RewardsDataTypes.RewardData storage rewardConfig = assetConfig.rewards[rewards[i]];
      uint256 decimals = assetConfig.decimals;
      if (decimals == 0 || rewardConfig.lastUpdateTimestamp == 0) revert DistributionDoesNotExist();

      (uint256 newIndex, ) = _updateRewardData(
        rewardConfig,
        IScaledBalanceToken(asset).scaledTotalSupply(),
        10 ** decimals
      );

      uint256 oldEmissionPerSecond = rewardConfig.emissionPerSecond;
      rewardConfig.emissionPerSecond = newEmissionsPerSecond[i];

      uint32 distributionEnd = rewardConfig.distributionEnd;

      emit AssetConfigUpdated(
        asset,
        rewards[i],
        oldEmissionPerSecond,
        newEmissionsPerSecond[i],
        distributionEnd,
        distributionEnd,
        newIndex
      );
    }
  }

  function _configureAssets(RewardsDataTypes.RewardsConfigInput[] memory rewardsInput) internal {
    uint256 rewardsInputLength = rewardsInput.length;
    for (uint256 i; i < rewardsInputLength; ++i) {
      if (_assets[rewardsInput[i].asset].decimals == 0) {
        _assetsList.push(rewardsInput[i].asset);
      }

      uint256 decimals = _assets[rewardsInput[i].asset].decimals = IERC20Detailed(
        rewardsInput[i].asset
      ).decimals();

      RewardsDataTypes.RewardData storage rewardConfig = _assets[rewardsInput[i].asset].rewards[
        rewardsInput[i].reward
      ];

      if (rewardConfig.lastUpdateTimestamp == 0) {
        _assets[rewardsInput[i].asset].availableRewards[
          _assets[rewardsInput[i].asset].availableRewardsCount++
        ] = rewardsInput[i].reward;
      }

      if (!_isRewardEnabled[rewardsInput[i].reward]) {
        _isRewardEnabled[rewardsInput[i].reward] = true;
        _rewardsList.push(rewardsInput[i].reward);
      }

      (uint256 newIndex, ) = _updateRewardData(
        rewardConfig,
        rewardsInput[i].totalSupply,
        10 ** decimals
      );

      uint88 oldEmissionsPerSecond = rewardConfig.emissionPerSecond;
      uint32 oldDistributionEnd = rewardConfig.distributionEnd;
      rewardConfig.emissionPerSecond = rewardsInput[i].emissionPerSecond;
      rewardConfig.distributionEnd = rewardsInput[i].distributionEnd;

      emit AssetConfigUpdated(
        rewardsInput[i].asset,
        rewardsInput[i].reward,
        oldEmissionsPerSecond,
        rewardsInput[i].emissionPerSecond,
        oldDistributionEnd,
        rewardsInput[i].distributionEnd,
        newIndex
      );
    }
  }

  function _updateRewardData(
    RewardsDataTypes.RewardData storage rewardData,
    uint256 totalSupply,
    uint256 assetUnit
  ) internal returns (uint256 newIndex, bool indexUpdated) {
    uint256 oldIndex;
    (oldIndex, newIndex) = _getAssetIndex(rewardData, totalSupply, assetUnit);
    if (newIndex != oldIndex) {
      if (newIndex > type(uint104).max) revert IndexOverflow();
      indexUpdated = true;

      rewardData.index = uint104(newIndex);
    } 

    rewardData.lastUpdateTimestamp = block.timestamp.toUint32();
  }

  function _updateUserData(
    RewardsDataTypes.RewardData storage rewardData,
    address user,
    uint256 userBalance,
    uint256 newAssetIndex,
    uint256 assetUnit
  ) internal returns (uint256 rewardsAccrued, bool dataUpdated) {
    uint256 userIndex = rewardData.usersData[user].index;

    if ((dataUpdated = userIndex != newAssetIndex)) {
      rewardData.usersData[user].index = uint104(newAssetIndex);
      if (userBalance != 0) {
        rewardsAccrued = _getRewards(userBalance, newAssetIndex, userIndex, assetUnit);

        rewardData.usersData[user].accrued += rewardsAccrued.toUint128();
      }
    }
  }

  function _updateData(
    address asset,
    address user,
    uint256 userBalance,
    uint256 totalSupply
  ) internal {
    uint256 numAvailableRewards = _assets[asset].availableRewardsCount;
    if (numAvailableRewards != 0) {
      unchecked {
        uint256 assetUnit = 10 ** _assets[asset].decimals;

        for (uint128 r; r < numAvailableRewards; ++r) {
          address reward = _assets[asset].availableRewards[r];
          RewardsDataTypes.RewardData storage rewardData = _assets[asset].rewards[reward];

          (uint256 newAssetIndex, bool rewardDataUpdated) = _updateRewardData(
            rewardData,
            totalSupply,
            assetUnit
          );

          (uint256 rewardsAccrued, bool userDataUpdated) = _updateUserData(
            rewardData,
            user,
            userBalance,
            newAssetIndex,
            assetUnit
          );

          if (rewardDataUpdated || userDataUpdated) {
            emit Accrued(asset, reward, user, newAssetIndex, newAssetIndex, rewardsAccrued);
          }
        }
      }
    }
  }

  function _updateDataMultiple(
    address user,
    RewardsDataTypes.UserAssetBalance[] memory userAssetBalances
  ) internal {
    uint256 userAssetBalancesLength = userAssetBalances.length;
    for (uint256 i; i < userAssetBalancesLength; ++i) {
      _updateData(
        userAssetBalances[i].asset,
        user,
        userAssetBalances[i].userBalance,
        userAssetBalances[i].totalSupply
      );
    }
  }

  function _getUserReward(
    address user,
    address reward,
    RewardsDataTypes.UserAssetBalance[] memory userAssetBalances
  ) internal view returns (uint256 unclaimedRewards) {
    uint256 userAssetBalancesLength = userAssetBalances.length;
    for (uint256 i; i < userAssetBalancesLength; ++i) {
      if (userAssetBalances[i].userBalance == 0) {
        unclaimedRewards += _assets[userAssetBalances[i].asset]
          .rewards[reward]
          .usersData[user]
          .accrued;
      } else {
        unclaimedRewards +=
          _getPendingRewards(user, reward, userAssetBalances[i]) +
          _assets[userAssetBalances[i].asset].rewards[reward].usersData[user].accrued;
      }
    }
  }

  function _getPendingRewards(
    address user,
    address reward,
    RewardsDataTypes.UserAssetBalance memory userAssetBalance
  ) internal view returns (uint256) {
    RewardsDataTypes.RewardData storage rewardData = _assets[userAssetBalance.asset].rewards[
      reward
    ];
    uint256 assetUnit = 10 ** _assets[userAssetBalance.asset].decimals;
    (, uint256 nextIndex) = _getAssetIndex(rewardData, userAssetBalance.totalSupply, assetUnit);

    return
      _getRewards(
        userAssetBalance.userBalance,
        nextIndex,
        rewardData.usersData[user].index,
        assetUnit
      );
  }

  function _getRewards(
    uint256 userBalance,
    uint256 reserveIndex,
    uint256 userIndex,
    uint256 assetUnit
  ) internal pure returns (uint256 result) {
    result = userBalance * (reserveIndex - userIndex);
    assembly {
      result := div(result, assetUnit)
    }
  }

  function _getAssetIndex(
    RewardsDataTypes.RewardData storage rewardData,
    uint256 totalSupply,
    uint256 assetUnit
  ) internal view returns (uint256, uint256) {
    uint256 oldIndex = rewardData.index;
    uint256 distributionEnd = rewardData.distributionEnd;
    uint256 emissionPerSecond = rewardData.emissionPerSecond;
    uint256 lastUpdateTimestamp = rewardData.lastUpdateTimestamp;

    if (
      emissionPerSecond == 0 ||
      totalSupply == 0 ||
      lastUpdateTimestamp == block.timestamp ||
      lastUpdateTimestamp >= distributionEnd
    ) {
      return (oldIndex, oldIndex);
    }

    uint256 currentTimestamp = block.timestamp > distributionEnd
      ? distributionEnd
      : block.timestamp;
    uint256 timeDelta = currentTimestamp - lastUpdateTimestamp;
    uint256 firstTerm = emissionPerSecond * timeDelta * assetUnit;
    assembly {
      firstTerm := div(firstTerm, totalSupply)
    }
    return (oldIndex, (firstTerm + oldIndex));
  }

  function _getUserAssetBalances(
    address[] calldata assets,
    address user
  ) internal view virtual returns (RewardsDataTypes.UserAssetBalance[] memory userAssetBalances);

  function getAssetDecimals(address asset) external view returns (uint8) {
    return _assets[asset].decimals;
  }

  function getEmissionManager() external view returns (address) {
    return EMISSION_MANAGER;
  }
}
