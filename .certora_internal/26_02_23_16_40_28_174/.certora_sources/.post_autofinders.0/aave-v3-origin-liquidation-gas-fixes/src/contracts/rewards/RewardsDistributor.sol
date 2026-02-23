// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IScaledBalanceToken} from '../interfaces/IScaledBalanceToken.sol';
import {IERC20Detailed} from '../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {SafeCast} from '../dependencies/openzeppelin/contracts/SafeCast.sol';
import {IRewardsDistributor} from './interfaces/IRewardsDistributor.sol';
import {RewardsDataTypes} from './libraries/RewardsDataTypes.sol';

/**
 * @title RewardsDistributor
 * @notice Accounting contract to manage multiple staking distributions with multiple rewards
 * @author Aave
 **/
abstract contract RewardsDistributor is IRewardsDistributor {
  using SafeCast for uint256;

  // Manager of incentives
  address public immutable EMISSION_MANAGER;
  // Deprecated: This storage slot is kept for backwards compatibility purposes.
  address internal _emissionManager;

  // Map of rewarded asset addresses and their data (assetAddress => assetData)
  mapping(address => RewardsDataTypes.AssetData) internal _assets;

  // Map of reward assets (rewardAddress => enabled)
  mapping(address => bool) internal _isRewardEnabled;

  // Rewards list
  address[] internal _rewardsList;

  // Assets list
  address[] internal _assetsList;

  modifier onlyEmissionManager() {
    require(msg.sender == EMISSION_MANAGER, 'ONLY_EMISSION_MANAGER');
    _;
  }

  constructor(address emissionManager) {
    EMISSION_MANAGER = emissionManager;
  }

  /// @inheritdoc IRewardsDistributor
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

  /// @inheritdoc IRewardsDistributor
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

  /// @inheritdoc IRewardsDistributor
  function getDistributionEnd(
    address asset,
    address reward
  ) external view override returns (uint256) {
    return _assets[asset].rewards[reward].distributionEnd;
  }

  /// @inheritdoc IRewardsDistributor
  function getRewardsByAsset(address asset) external view override returns (address[] memory availableRewards) {
    uint128 rewardsCount = _assets[asset].availableRewardsCount;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000006,rewardsCount)}
    availableRewards = new address[](rewardsCount);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020018,0)}

    for (uint128 i; i < rewardsCount; i++) {
      availableRewards[i] = _assets[asset].availableRewards[i];address certora_local42 = availableRewards[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000002a,certora_local42)}
    }
  }

  /// @inheritdoc IRewardsDistributor
  function getRewardsList() external view override returns (address[] memory rewardsList) {
    rewardsList = _rewardsList;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020019,0)}
  }

  /// @inheritdoc IRewardsDistributor
  function getUserAssetIndex(
    address user,
    address asset,
    address reward
  ) external view override returns (uint256) {
    return _assets[asset].rewards[reward].usersData[user].index;
  }

  /// @inheritdoc IRewardsDistributor
  function getUserAccruedRewards(
    address user,
    address reward
  ) external view override returns (uint256 totalAccrued) {
    uint256 assetsListLength = _assetsList.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000007,assetsListLength)}
    for (uint256 i; i < assetsListLength; i++) {
      totalAccrued += _assets[_assetsList[i]].rewards[reward].usersData[user].accrued;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000002b,totalAccrued)}
    }
  }

  /// @inheritdoc IRewardsDistributor
  function getUserRewards(
    address[] calldata assets,
    address user,
    address reward
  ) external view override returns (uint256) {
    return _getUserReward(user, reward, _getUserAssetBalances(assets, user));
  }

  /// @inheritdoc IRewardsDistributor
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
    rewardsList = new address[](rewardsListLength);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002001a,0)}
    unclaimedAmounts = new uint256[](rewardsListLength);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002001b,0)}

    // Add unrealized rewards from user to unclaimedRewards
    for (uint256 i; i < userAssetBalances.length; i++) {
      for (uint256 r; r < rewardsListLength; r++) {
        rewardsList[r] = _rewardsList[r];address certora_local47 = rewardsList[r];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000002f,certora_local47)}
        unclaimedAmounts[r] += _assets[userAssetBalances[i].asset]
          .rewards[rewardsList[r]]
          .usersData[user]
          .accrued;uint256 certora_local48 = unclaimedAmounts[r];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000030,certora_local48)}

        if (userAssetBalances[i].userBalance == 0) {
          continue;
        }
        unclaimedAmounts[r] += _getPendingRewards(user, rewardsList[r], userAssetBalances[i]);uint256 certora_local49 = unclaimedAmounts[r];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000031,certora_local49)}
      }
    }
  }

  /// @inheritdoc IRewardsDistributor
  function setDistributionEnd(
    address asset,
    address reward,
    uint32 newDistributionEnd
  ) external override onlyEmissionManager {
    // cache event emission params using 1 SLOAD
    (uint104 index, uint88 emissionPerSecond, uint32 oldDistributionEnd)
      = (_assets[asset].rewards[reward].index,
         _assets[asset].rewards[reward].emissionPerSecond,
         _assets[asset].rewards[reward].distributionEnd);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001000a,0)}

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

  /// @inheritdoc IRewardsDistributor
  function setEmissionPerSecond(
    address asset,
    address[] calldata rewards,
    uint88[] calldata newEmissionsPerSecond
  ) external override onlyEmissionManager {
    require(rewards.length == newEmissionsPerSecond.length, 'INVALID_INPUT');
    for (uint256 i; i < rewards.length; i++) {
      RewardsDataTypes.AssetData storage assetConfig = _assets[asset];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001001f,0)}
      RewardsDataTypes.RewardData storage rewardConfig = _assets[asset].rewards[rewards[i]];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010020,0)}
      uint256 decimals = assetConfig.decimals;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000021,decimals)}
      require(
        decimals != 0 && rewardConfig.lastUpdateTimestamp != 0,
        'DISTRIBUTION_DOES_NOT_EXIST'
      );

      (uint256 newIndex, ) = _updateRewardData(
        rewardConfig,
        IScaledBalanceToken(asset).scaledTotalSupply(),
        10 ** decimals
      );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010022,0)}

      uint256 oldEmissionPerSecond = rewardConfig.emissionPerSecond;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000023,oldEmissionPerSecond)}
      rewardConfig.emissionPerSecond = newEmissionsPerSecond[i];uint88 certora_local44 = rewardConfig.emissionPerSecond;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000002c,certora_local44)}

      uint32 distributionEnd = rewardConfig.distributionEnd;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000024,distributionEnd)}

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

  /**
   * @dev Configure the _assets for a specific emission
   * @param rewardsInput The array of each asset configuration
   **/
  function _configureAssets(RewardsDataTypes.RewardsConfigInput[] memory rewardsInput) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000f0000, 1037618708495) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000f0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000f1000, rewardsInput) }
    for (uint256 i; i < rewardsInput.length; i++) {
      if (_assets[rewardsInput[i].asset].decimals == 0) {
        //never initialized before, adding to the list of assets
        _assetsList.push(rewardsInput[i].asset);
      }

      uint256 decimals = _assets[rewardsInput[i].asset].decimals = IERC20Detailed(
        rewardsInput[i].asset
      ).decimals();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000025,decimals)}

      RewardsDataTypes.RewardData storage rewardConfig = _assets[rewardsInput[i].asset].rewards[
        rewardsInput[i].reward
      ];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010026,0)}

      // Add reward address to asset available rewards if latestUpdateTimestamp is zero
      if (rewardConfig.lastUpdateTimestamp == 0) {
        _assets[rewardsInput[i].asset].availableRewards[
          _assets[rewardsInput[i].asset].availableRewardsCount++
        ] = rewardsInput[i].reward;
      }

      // Add reward address to global rewards list if still not enabled
      if (_isRewardEnabled[rewardsInput[i].reward] == false) {
        _isRewardEnabled[rewardsInput[i].reward] = true;
        _rewardsList.push(rewardsInput[i].reward);
      }

      // Due emissions is still zero, updates only latestUpdateTimestamp
      (uint256 newIndex, ) = _updateRewardData(
        rewardConfig,
        rewardsInput[i].totalSupply,
        10 ** decimals
      );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010027,0)}

      // Configure emission and distribution end of the reward per asset
      uint88 oldEmissionsPerSecond = rewardConfig.emissionPerSecond;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000028,oldEmissionsPerSecond)}
      uint32 oldDistributionEnd = rewardConfig.distributionEnd;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000029,oldDistributionEnd)}
      rewardConfig.emissionPerSecond = rewardsInput[i].emissionPerSecond;uint88 certora_local45 = rewardConfig.emissionPerSecond;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000002d,certora_local45)}
      rewardConfig.distributionEnd = rewardsInput[i].distributionEnd;uint32 certora_local46 = rewardConfig.distributionEnd;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000002e,certora_local46)}

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

  /**
   * @dev Updates the state of the distribution for the specified reward
   * @param rewardData Storage pointer to the distribution reward config
   * @param totalSupply Current total of underlying assets for this distribution
   * @param assetUnit One unit of asset (10**decimals)
   * @return newIndex The new distribution index
   * @return indexUpdated True if the index was updated, false otherwise
   **/
  function _updateRewardData(
    RewardsDataTypes.RewardData storage rewardData,
    uint256 totalSupply,
    uint256 assetUnit
  ) internal returns (uint256 newIndex, bool indexUpdated) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00110000, 1037618708497) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00110001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00111000, rewardData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00111001, totalSupply) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00111002, assetUnit) }
    uint256 oldIndex;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000b,oldIndex)}
    (oldIndex, newIndex) = _getAssetIndex(rewardData, totalSupply, assetUnit);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002001c,0)}
    if (newIndex != oldIndex) {
      require(newIndex <= type(uint104).max, 'INDEX_OVERFLOW');
      indexUpdated = true;

      //optimization: storing one after another saves one SSTORE
      rewardData.index = uint104(newIndex);
    } 

    rewardData.lastUpdateTimestamp = block.timestamp.toUint32();uint32 certora_local29 = rewardData.lastUpdateTimestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001d,certora_local29)}
  }

  /**
   * @dev Updates the state of the distribution for the specific user
   * @param rewardData Storage pointer to the distribution reward config
   * @param user The address of the user
   * @param userBalance The user balance of the asset
   * @param newAssetIndex The new index of the asset distribution
   * @param assetUnit One unit of asset (10**decimals)
   * @return rewardsAccrued The rewards accrued since the last update
   **/
  function _updateUserData(
    RewardsDataTypes.RewardData storage rewardData,
    address user,
    uint256 userBalance,
    uint256 newAssetIndex,
    uint256 assetUnit
  ) internal returns (uint256 rewardsAccrued, bool dataUpdated) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00120000, 1037618708498) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00120001, 5) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00121000, rewardData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00121001, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00121002, userBalance) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00121003, newAssetIndex) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00121004, assetUnit) }
    uint256 userIndex = rewardData.usersData[user].index;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000c,userIndex)}

    if ((dataUpdated = userIndex != newAssetIndex)) {
      // already checked for overflow in _updateRewardData
      rewardData.usersData[user].index = uint104(newAssetIndex);
      if (userBalance != 0) {
        rewardsAccrued = _getRewards(userBalance, newAssetIndex, userIndex, assetUnit);

        rewardData.usersData[user].accrued += rewardsAccrued.toUint128();
      }
    }
  }

  /**
   * @dev Iterates and accrues all the rewards for asset of the specific user
   * @param asset The address of the reference asset of the distribution
   * @param user The user address
   * @param userBalance The current user asset balance
   * @param totalSupply Total supply of the asset
   **/
  function _updateData(
    address asset,
    address user,
    uint256 userBalance,
    uint256 totalSupply
  ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00100000, 1037618708496) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00100001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00101000, asset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00101001, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00101002, userBalance) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00101003, totalSupply) }
    uint256 numAvailableRewards = _assets[asset].availableRewardsCount;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000d,numAvailableRewards)}
    if (numAvailableRewards != 0) {
      unchecked {
        uint256 assetUnit = 10 ** _assets[asset].decimals;

        for (uint128 r; r < numAvailableRewards; r++) {
          address reward = _assets[asset].availableRewards[r];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000032,reward)}
          RewardsDataTypes.RewardData storage rewardData = _assets[asset].rewards[reward];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010033,0)}

          (uint256 newAssetIndex, bool rewardDataUpdated) = _updateRewardData(
            rewardData,
            totalSupply,
            assetUnit
          );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010034,0)}

          (uint256 rewardsAccrued, bool userDataUpdated) = _updateUserData(
            rewardData,
            user,
            userBalance,
            newAssetIndex,
            assetUnit
          );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010035,0)}

          if (rewardDataUpdated || userDataUpdated) {
            emit Accrued(asset, reward, user, newAssetIndex, newAssetIndex, rewardsAccrued);
          }
        }
      }
    }
  }

  /**
   * @dev Accrues all the rewards of the assets specified in the userAssetBalances list
   * @param user The address of the user
   * @param userAssetBalances List of structs with the user balance and total supply of a set of assets
   **/
  function _updateDataMultiple(
    address user,
    RewardsDataTypes.UserAssetBalance[] memory userAssetBalances
  ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00130000, 1037618708499) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00130001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00131000, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00131001, userAssetBalances) }
    for (uint256 i; i < userAssetBalances.length; i++) {
      _updateData(
        userAssetBalances[i].asset,
        user,
        userAssetBalances[i].userBalance,
        userAssetBalances[i].totalSupply
      );
    }
  }

  /**
   * @dev Return the accrued unclaimed amount of a reward from a user over a list of distribution
   * @param user The address of the user
   * @param reward The address of the reward token
   * @param userAssetBalances List of structs with the user balance and total supply of a set of assets
   * @return unclaimedRewards The accrued rewards for the user until the moment
   **/
  function _getUserReward(
    address user,
    address reward,
    RewardsDataTypes.UserAssetBalance[] memory userAssetBalances
  ) internal view returns (uint256 unclaimedRewards) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00140000, 1037618708500) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00140001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00141000, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00141001, reward) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00141002, userAssetBalances) }
    // Add unrealized rewards
    for (uint256 i; i < userAssetBalances.length; i++) {
      if (userAssetBalances[i].userBalance == 0) {
        unclaimedRewards += _assets[userAssetBalances[i].asset]
          .rewards[reward]
          .usersData[user]
          .accrued;
      } else {
        unclaimedRewards +=
          _getPendingRewards(user, reward, userAssetBalances[i]) +
          _assets[userAssetBalances[i].asset].rewards[reward].usersData[user].accrued;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000036,unclaimedRewards)}
      }
    }
  }

  /**
   * @dev Calculates the pending (not yet accrued) rewards since the last user action
   * @param user The address of the user
   * @param reward The address of the reward token
   * @param userAssetBalance struct with the user balance and total supply of the incentivized asset
   * @return The pending rewards for the user since the last user action
   **/
  function _getPendingRewards(
    address user,
    address reward,
    RewardsDataTypes.UserAssetBalance memory userAssetBalance
  ) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00150000, 1037618708501) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00150001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00151000, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00151001, reward) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00151002, userAssetBalance) }
    RewardsDataTypes.RewardData storage rewardData = _assets[userAssetBalance.asset].rewards[
      reward
    ];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001000e,0)}
    uint256 assetUnit = 10 ** _assets[userAssetBalance.asset].decimals;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000f,assetUnit)}
    (, uint256 nextIndex) = _getAssetIndex(rewardData, userAssetBalance.totalSupply, assetUnit);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010010,0)}

    return
      _getRewards(
        userAssetBalance.userBalance,
        nextIndex,
        rewardData.usersData[user].index,
        assetUnit
      );
  }

  /**
   * @dev Internal function for the calculation of user's rewards on a distribution
   * @param userBalance Balance of the user asset on a distribution
   * @param reserveIndex Current index of the distribution
   * @param userIndex Index stored for the user, representation his staking moment
   * @param assetUnit One unit of asset (10**decimals)
   * @return result The rewards
   **/
  function _getRewards(
    uint256 userBalance,
    uint256 reserveIndex,
    uint256 userIndex,
    uint256 assetUnit
  ) internal pure returns (uint256 result) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00160000, 1037618708502) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00160001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00161000, userBalance) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00161001, reserveIndex) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00161002, userIndex) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00161003, assetUnit) }
    result = userBalance * (reserveIndex - userIndex);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001e,result)}
    assembly {
      result := div(result, assetUnit)
    }
  }

  /**
   * @dev Calculates the next value of an specific distribution index, with validations
   * @param rewardData Storage pointer to the distribution reward config
   * @param totalSupply of the asset being rewarded
   * @param assetUnit One unit of asset (10**decimals)
   * @return The new index.
   **/
  function _getAssetIndex(
    RewardsDataTypes.RewardData storage rewardData,
    uint256 totalSupply,
    uint256 assetUnit
  ) internal view returns (uint256, uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00170000, 1037618708503) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00170001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00171000, rewardData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00171001, totalSupply) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00171002, assetUnit) }
    uint256 oldIndex = rewardData.index;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000011,oldIndex)}
    uint256 distributionEnd = rewardData.distributionEnd;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000012,distributionEnd)}
    uint256 emissionPerSecond = rewardData.emissionPerSecond;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000013,emissionPerSecond)}
    uint256 lastUpdateTimestamp = rewardData.lastUpdateTimestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000014,lastUpdateTimestamp)}

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
      : block.timestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000015,currentTimestamp)}
    uint256 timeDelta = currentTimestamp - lastUpdateTimestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000016,timeDelta)}
    uint256 firstTerm = emissionPerSecond * timeDelta * assetUnit;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000017,firstTerm)}
    assembly {
      firstTerm := div(firstTerm, totalSupply)
    }
    return (oldIndex, (firstTerm + oldIndex));
  }

  /**
   * @dev Get user balances and total supply of all the assets specified by the assets parameter
   * @param assets List of assets to retrieve user balance and total supply
   * @param user Address of the user
   * @return userAssetBalances contains a list of structs with user balance and total supply of the given assets
   */
  function _getUserAssetBalances(
    address[] calldata assets,
    address user
  ) internal view virtual returns (RewardsDataTypes.UserAssetBalance[] memory userAssetBalances);

  /// @inheritdoc IRewardsDistributor
  function getAssetDecimals(address asset) external view returns (uint8) {
    return _assets[asset].decimals;
  }

  /// @inheritdoc IRewardsDistributor
  function getEmissionManager() external view returns (address) {
    return EMISSION_MANAGER;
  }
}
