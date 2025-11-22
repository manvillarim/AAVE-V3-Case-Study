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
    RewardsDataTypes.RewardData storage rewardData = _assets[asset].rewards[reward];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010005,0)}
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
    uint128 rewardsCount = _assets[asset].availableRewardsCount;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000006,rewardsCount)}
    availableRewards = new address[](rewardsCount);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002001d,0)}

    for (uint128 i; i < rewardsCount; ++i) {
      availableRewards[i] = _assets[asset].availableRewards[i];address certora_local47 = availableRewards[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000002f,certora_local47)}
    }
  }

  function getRewardsList() external view override returns (address[] memory rewardsList) {
    rewardsList = _rewardsList;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002001e,0)}
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
    uint256 assetsListLength = _assetsList.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000007,assetsListLength)}
    for (uint256 i; i < assetsListLength; ++i) {
      totalAccrued += _assets[_assetsList[i]].rewards[reward].usersData[user].accrued;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000030,totalAccrued)}
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
    );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010008,0)}
    uint256 rewardsListLength = _rewardsList.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000009,rewardsListLength)}
    rewardsList = new address[](rewardsListLength);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002001f,0)}
    unclaimedAmounts = new uint256[](rewardsListLength);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020020,0)}

    uint256 userAssetBalancesLength = userAssetBalances.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000a,userAssetBalancesLength)}
    for (uint256 i; i < userAssetBalancesLength; ++i) {
      for (uint256 r; r < rewardsListLength; ++r) {
        rewardsList[r] = _rewardsList[r];address certora_local52 = rewardsList[r];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000034,certora_local52)}
        unclaimedAmounts[r] += _assets[userAssetBalances[i].asset]
          .rewards[rewardsList[r]]
          .usersData[user]
          .accrued;uint256 certora_local53 = unclaimedAmounts[r];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000035,certora_local53)}

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
         _assets[asset].rewards[reward].distributionEnd);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001000b,0)}

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
    uint256 rewardsLength = rewards.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000c,rewardsLength)}
    for (uint256 i; i < rewardsLength; ++i) {
      RewardsDataTypes.AssetData storage assetConfig = _assets[asset];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010024,0)}
      RewardsDataTypes.RewardData storage rewardConfig = assetConfig.rewards[rewards[i]];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010025,0)}
      uint256 decimals = assetConfig.decimals;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000026,decimals)}
      if (decimals == 0 || rewardConfig.lastUpdateTimestamp == 0) revert DistributionDoesNotExist();

      (uint256 newIndex, ) = _updateRewardData(
        rewardConfig,
        IScaledBalanceToken(asset).scaledTotalSupply(),
        10 ** decimals
      );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010027,0)}

      uint256 oldEmissionPerSecond = rewardConfig.emissionPerSecond;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000028,oldEmissionPerSecond)}
      rewardConfig.emissionPerSecond = newEmissionsPerSecond[i];uint88 certora_local49 = rewardConfig.emissionPerSecond;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000031,certora_local49)}

      uint32 distributionEnd = rewardConfig.distributionEnd;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000029,distributionEnd)}

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

  function _configureAssets(RewardsDataTypes.RewardsConfigInput[] memory rewardsInput) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000f0000, 1037618708495) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000f0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000f1000, rewardsInput) }
    uint256 rewardsInputLength = rewardsInput.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000d,rewardsInputLength)}
    for (uint256 i; i < rewardsInputLength; ++i) {
      if (_assets[rewardsInput[i].asset].decimals == 0) {
        _assetsList.push(rewardsInput[i].asset);
      }

      uint256 decimals = _assets[rewardsInput[i].asset].decimals = IERC20Detailed(
        rewardsInput[i].asset
      ).decimals();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000002a,decimals)}

      RewardsDataTypes.RewardData storage rewardConfig = _assets[rewardsInput[i].asset].rewards[
        rewardsInput[i].reward
      ];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001002b,0)}

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
      );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001002c,0)}

      uint88 oldEmissionsPerSecond = rewardConfig.emissionPerSecond;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000002d,oldEmissionsPerSecond)}
      uint32 oldDistributionEnd = rewardConfig.distributionEnd;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000002e,oldDistributionEnd)}
      rewardConfig.emissionPerSecond = rewardsInput[i].emissionPerSecond;uint88 certora_local50 = rewardConfig.emissionPerSecond;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000032,certora_local50)}
      rewardConfig.distributionEnd = rewardsInput[i].distributionEnd;uint32 certora_local51 = rewardConfig.distributionEnd;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000033,certora_local51)}

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
  ) internal returns (uint256 newIndex, bool indexUpdated) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00110000, 1037618708497) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00110001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00111000, rewardData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00111001, totalSupply) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00111002, assetUnit) }
    uint256 oldIndex;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000e,oldIndex)}
    (oldIndex, newIndex) = _getAssetIndex(rewardData, totalSupply, assetUnit);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020021,0)}
    if (newIndex != oldIndex) {
      if (newIndex > type(uint104).max) revert IndexOverflow();
      indexUpdated = true;

      rewardData.index = uint104(newIndex);
    } 

    rewardData.lastUpdateTimestamp = block.timestamp.toUint32();uint32 certora_local34 = rewardData.lastUpdateTimestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000022,certora_local34)}
  }

  function _updateUserData(
    RewardsDataTypes.RewardData storage rewardData,
    address user,
    uint256 userBalance,
    uint256 newAssetIndex,
    uint256 assetUnit
  ) internal returns (uint256 rewardsAccrued, bool dataUpdated) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00120000, 1037618708498) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00120001, 5) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00121000, rewardData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00121001, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00121002, userBalance) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00121003, newAssetIndex) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00121004, assetUnit) }
    uint256 userIndex = rewardData.usersData[user].index;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000f,userIndex)}

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
  ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00100000, 1037618708496) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00100001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00101000, asset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00101001, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00101002, userBalance) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00101003, totalSupply) }
    uint256 numAvailableRewards = _assets[asset].availableRewardsCount;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000010,numAvailableRewards)}
    if (numAvailableRewards != 0) {
      unchecked {
        uint256 assetUnit = 10 ** _assets[asset].decimals;

        for (uint128 r; r < numAvailableRewards; ++r) {
          address reward = _assets[asset].availableRewards[r];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000036,reward)}
          RewardsDataTypes.RewardData storage rewardData = _assets[asset].rewards[reward];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010037,0)}

          (uint256 newAssetIndex, bool rewardDataUpdated) = _updateRewardData(
            rewardData,
            totalSupply,
            assetUnit
          );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010038,0)}

          (uint256 rewardsAccrued, bool userDataUpdated) = _updateUserData(
            rewardData,
            user,
            userBalance,
            newAssetIndex,
            assetUnit
          );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010039,0)}

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
  ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00130000, 1037618708499) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00130001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00131000, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00131001, userAssetBalances) }
    uint256 userAssetBalancesLength = userAssetBalances.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000011,userAssetBalancesLength)}
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
  ) internal view returns (uint256 unclaimedRewards) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00140000, 1037618708500) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00140001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00141000, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00141001, reward) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00141002, userAssetBalances) }
    uint256 userAssetBalancesLength = userAssetBalances.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000012,userAssetBalancesLength)}
    for (uint256 i; i < userAssetBalancesLength; ++i) {
      if (userAssetBalances[i].userBalance == 0) {
        unclaimedRewards += _assets[userAssetBalances[i].asset]
          .rewards[reward]
          .usersData[user]
          .accrued;
      } else {
        unclaimedRewards +=
          _getPendingRewards(user, reward, userAssetBalances[i]) +
          _assets[userAssetBalances[i].asset].rewards[reward].usersData[user].accrued;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000003a,unclaimedRewards)}
      }
    }
  }

  function _getPendingRewards(
    address user,
    address reward,
    RewardsDataTypes.UserAssetBalance memory userAssetBalance
  ) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00150000, 1037618708501) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00150001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00151000, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00151001, reward) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00151002, userAssetBalance) }
    RewardsDataTypes.RewardData storage rewardData = _assets[userAssetBalance.asset].rewards[
      reward
    ];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010013,0)}
    uint256 assetUnit = 10 ** _assets[userAssetBalance.asset].decimals;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000014,assetUnit)}
    (, uint256 nextIndex) = _getAssetIndex(rewardData, userAssetBalance.totalSupply, assetUnit);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010015,0)}

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
  ) internal pure returns (uint256 result) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00160000, 1037618708502) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00160001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00161000, userBalance) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00161001, reserveIndex) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00161002, userIndex) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00161003, assetUnit) }
    result = userBalance * (reserveIndex - userIndex);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000023,result)}
    assembly {
      result := div(result, assetUnit)
    }
  }

  function _getAssetIndex(
    RewardsDataTypes.RewardData storage rewardData,
    uint256 totalSupply,
    uint256 assetUnit
  ) internal view returns (uint256, uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00170000, 1037618708503) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00170001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00171000, rewardData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00171001, totalSupply) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00171002, assetUnit) }
    uint256 oldIndex = rewardData.index;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000016,oldIndex)}
    uint256 distributionEnd = rewardData.distributionEnd;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000017,distributionEnd)}
    uint256 emissionPerSecond = rewardData.emissionPerSecond;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000018,emissionPerSecond)}
    uint256 lastUpdateTimestamp = rewardData.lastUpdateTimestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000019,lastUpdateTimestamp)}

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
      : block.timestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001a,currentTimestamp)}
    uint256 timeDelta = currentTimestamp - lastUpdateTimestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001b,timeDelta)}
    uint256 firstTerm = emissionPerSecond * timeDelta * assetUnit;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001c,firstTerm)}
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
