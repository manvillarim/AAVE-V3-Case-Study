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

  address public immutable EMISSION_MANAGER;
  address internal _emissionManager;

  mapping(address => RewardsDataTypes.AssetData) internal _assets;
  mapping(address => bool) internal _isRewardEnabled;
  address[] internal _rewardsList;
  address[] internal _assetsList;

  // RULE 1 - Replace require with custom errors
  error OnlyEmissionManager();
  error InvalidInput();
  error DistributionDoesNotExist();
  error IndexOverflow();

  modifier onlyEmissionManager() {
    // RULE 1 - Replace require with custom errors
    if (msg.sender != EMISSION_MANAGER) revert OnlyEmissionManager();
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
    RewardsDataTypes.RewardData storage rewardData = _assets[asset].rewards[reward];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010021,0)}
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
  function getRewardsByAsset(
    address asset
  ) external view override returns (address[] memory availableRewards) {
    uint128 rewardsCount = _assets[asset].availableRewardsCount;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000022,rewardsCount)}
    availableRewards = new address[](rewardsCount);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020039,0)}
    // RULE 9  - Avoid explicit zero initialization
    for (uint128 i; i < rewardsCount; ) {
      availableRewards[i] = _assets[asset].availableRewards[i];address certora_local79 = availableRewards[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000004f,certora_local79)}
      // RULE 26 - Pre-increment; RULE 28 - Unchecked arithmetic: i < rewardsCount guarantees no overflow
      unchecked { ++i; }
    }
  }

  /// @inheritdoc IRewardsDistributor
  function getRewardsList() external view override returns (address[] memory rewardsList) {
    rewardsList = _rewardsList;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002003a,0)}
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
    // RULE 25 - Cache array length in loops
    uint256 assetsListLength = _assetsList.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000023,assetsListLength)}
    // RULE 9  - Avoid explicit zero initialization
    for (uint256 i; i < assetsListLength; ) {
      totalAccrued += _assets[_assetsList[i]].rewards[reward].usersData[user].accrued;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000050,totalAccrued)}
      // RULE 26 - Pre-increment; RULE 28 - Unchecked arithmetic: i < assetsListLength guarantees no overflow
      unchecked { ++i; }
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
    );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010024,0)}
    // RULE 25 - Cache array length in loops
    uint256 rewardsListLength = _rewardsList.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000025,rewardsListLength)}
    uint256 userAssetBalancesLength = userAssetBalances.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000026,userAssetBalancesLength)}
    rewardsList = new address[](rewardsListLength);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002003b,0)}
    unclaimedAmounts = new uint256[](rewardsListLength);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002003c,0)}

    // RULE 9  - Avoid explicit zero initialization
    for (uint256 i; i < userAssetBalancesLength; ) {
      // RULE 24 - Cache array member variable
      RewardsDataTypes.UserAssetBalance memory userAssetBalance = userAssetBalances[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010040,0)}
      for (uint256 r; r < rewardsListLength; ) {
        rewardsList[r] = _rewardsList[r];address certora_local84 = rewardsList[r];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000054,certora_local84)}
        unclaimedAmounts[r] += _assets[userAssetBalance.asset]
          .rewards[rewardsList[r]]
          .usersData[user]
          .accrued;uint256 certora_local85 = unclaimedAmounts[r];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000055,certora_local85)}

        if (userAssetBalance.userBalance == 0) {
          // RULE 26 - Pre-increment; RULE 28 - Unchecked arithmetic: r < rewardsListLength guarantees no overflow
          unchecked { ++r; }
          continue;
        }
        unclaimedAmounts[r] += _getPendingRewards(user, rewardsList[r], userAssetBalance);uint256 certora_local86 = unclaimedAmounts[r];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000056,certora_local86)}
        // RULE 26 - Pre-increment; RULE 28 - Unchecked arithmetic: r < rewardsListLength guarantees no overflow
        unchecked { ++r; }
      }
      // RULE 26 - Pre-increment; RULE 28 - Unchecked arithmetic: i < userAssetBalancesLength guarantees no overflow
      unchecked { ++i; }
    }
  }

  /// @inheritdoc IRewardsDistributor
  function setDistributionEnd(
    address asset,
    address reward,
    uint32 newDistributionEnd
  ) external override onlyEmissionManager {
    // RULE 23 - Cache storage variables: the three event parameters are read
    // once into locals instead of being re-loaded from storage inside the emit
    (uint104 index, uint88 emissionPerSecond, uint32 oldDistributionEnd)
      = (_assets[asset].rewards[reward].index,
         _assets[asset].rewards[reward].emissionPerSecond,
         _assets[asset].rewards[reward].distributionEnd);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010027,0)}

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
    // RULE 1  - Replace require with custom errors
    // RULE 25 - Cache array length in loops
    uint256 rewardsLength = rewards.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000028,rewardsLength)}
    if (rewardsLength != newEmissionsPerSecond.length) revert InvalidInput();
    // RULE 9  - Avoid explicit zero initialization
    for (uint256 i; i < rewardsLength; ) {
      RewardsDataTypes.AssetData storage assetConfig = _assets[asset];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010041,0)}
      RewardsDataTypes.RewardData storage rewardConfig = assetConfig.rewards[rewards[i]];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010042,0)}
      uint256 decimals = assetConfig.decimals;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000043,decimals)}
      // RULE 1 - Replace require with custom errors
      if (decimals == 0 || rewardConfig.lastUpdateTimestamp == 0) revert DistributionDoesNotExist();

      (uint256 newIndex, ) = _updateRewardData(
        rewardConfig,
        IScaledBalanceToken(asset).scaledTotalSupply(),
        10 ** decimals
      );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010044,0)}

      uint256 oldEmissionPerSecond = rewardConfig.emissionPerSecond;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000045,oldEmissionPerSecond)}
      rewardConfig.emissionPerSecond = newEmissionsPerSecond[i];uint88 certora_local81 = rewardConfig.emissionPerSecond;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000051,certora_local81)}

      // RULE 23 - Cache storage variables: distributionEnd is emitted twice,
      // so it is read once into a local instead of two SLOADs
      uint32 distributionEnd = rewardConfig.distributionEnd;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000046,distributionEnd)}

      emit AssetConfigUpdated(
        asset,
        rewards[i],
        oldEmissionPerSecond,
        newEmissionsPerSecond[i],
        distributionEnd,
        distributionEnd,
        newIndex
      );
      // RULE 26 - Pre-increment; RULE 28 - Unchecked arithmetic: i < rewardsLength guarantees no overflow
      unchecked { ++i; }
    }
  }

  /**
   * @dev Configure the _assets for a specific emission
   * @param rewardsInput The array of each asset configuration
   **/
  function _configureAssets(RewardsDataTypes.RewardsConfigInput[] memory rewardsInput) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00170000, 1037618708503) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00170001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00171000, rewardsInput) }
    // RULE 25 - Cache array length in loops
    uint256 rewardsInputLength = rewardsInput.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000029,rewardsInputLength)}
    // RULE 9  - Avoid explicit zero initialization
    for (uint256 i; i < rewardsInputLength; ) {
      // RULE 24 - Cache array member variable: rewardsInput[i] accessed 10+ times
      RewardsDataTypes.RewardsConfigInput memory input = rewardsInput[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010047,0)}

      if (_assets[input.asset].decimals == 0) {
        _assetsList.push(input.asset);
      }

      uint256 decimals = _assets[input.asset].decimals = IERC20Detailed(input.asset).decimals();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000048,decimals)}

      RewardsDataTypes.RewardData storage rewardConfig = _assets[input.asset].rewards[input.reward];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010049,0)}

      if (rewardConfig.lastUpdateTimestamp == 0) {
        _assets[input.asset].availableRewards[
          _assets[input.asset].availableRewardsCount++
        ] = input.reward;
      }

      // RULE 15 - Reduce expressions: == false → !
      if (!_isRewardEnabled[input.reward]) {
        _isRewardEnabled[input.reward] = true;
        _rewardsList.push(input.reward);
      }

      (uint256 newIndex, ) = _updateRewardData(
        rewardConfig,
        input.totalSupply,
        10 ** decimals
      );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001004a,0)}

      uint88 oldEmissionsPerSecond = rewardConfig.emissionPerSecond;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000004b,oldEmissionsPerSecond)}
      uint32 oldDistributionEnd = rewardConfig.distributionEnd;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000004c,oldDistributionEnd)}
      rewardConfig.emissionPerSecond = input.emissionPerSecond;uint88 certora_local82 = rewardConfig.emissionPerSecond;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000052,certora_local82)}
      rewardConfig.distributionEnd = input.distributionEnd;uint32 certora_local83 = rewardConfig.distributionEnd;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000053,certora_local83)}

      emit AssetConfigUpdated(
        input.asset,
        input.reward,
        oldEmissionsPerSecond,
        input.emissionPerSecond,
        oldDistributionEnd,
        input.distributionEnd,
        newIndex
      );
      // RULE 26 - Pre-increment; RULE 28 - Unchecked arithmetic: i < rewardsInputLength guarantees no overflow
      unchecked { ++i; }
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
  ) internal returns (uint256 newIndex, bool indexUpdated) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00190000, 1037618708505) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00190001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00191000, rewardData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00191001, totalSupply) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00191002, assetUnit) }
    uint256 oldIndex;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000002a,oldIndex)}
    (oldIndex, newIndex) = _getAssetIndex(rewardData, totalSupply, assetUnit);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002003d,0)}
    if (newIndex != oldIndex) {
      // RULE 1 - Replace require with custom errors
      if (newIndex > type(uint104).max) revert IndexOverflow();
      indexUpdated = true;
      rewardData.index = uint104(newIndex);
    }
    rewardData.lastUpdateTimestamp = block.timestamp.toUint32();uint32 certora_local62 = rewardData.lastUpdateTimestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000003e,certora_local62)}
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
  ) internal returns (uint256 rewardsAccrued, bool dataUpdated) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001a0000, 1037618708506) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001a0001, 5) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001a1000, rewardData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001a1001, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001a1002, userBalance) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001a1003, newAssetIndex) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001a1004, assetUnit) }
    uint256 userIndex = rewardData.usersData[user].index;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000002b,userIndex)}

    if ((dataUpdated = userIndex != newAssetIndex)) {
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
  ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00180000, 1037618708504) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00180001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00181000, asset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00181001, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00181002, userBalance) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00181003, totalSupply) }
    uint256 numAvailableRewards = _assets[asset].availableRewardsCount;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000002c,numAvailableRewards)}
    if (numAvailableRewards != 0) {
      unchecked {
        uint256 assetUnit = 10 ** _assets[asset].decimals;

        for (uint128 r; r < numAvailableRewards; r++) {
          address reward = _assets[asset].availableRewards[r];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000057,reward)}
          RewardsDataTypes.RewardData storage rewardData = _assets[asset].rewards[reward];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010058,0)}

          (uint256 newAssetIndex, bool rewardDataUpdated) = _updateRewardData(
            rewardData,
            totalSupply,
            assetUnit
          );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010059,0)}

          (uint256 rewardsAccrued, bool userDataUpdated) = _updateUserData(
            rewardData,
            user,
            userBalance,
            newAssetIndex,
            assetUnit
          );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001005a,0)}

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
  ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001b0000, 1037618708507) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001b0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001b1000, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001b1001, userAssetBalances) }
    // RULE 25 - Cache array length in loops
    uint256 userAssetBalancesLength = userAssetBalances.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000002d,userAssetBalancesLength)}
    // RULE 9  - Avoid explicit zero initialization
    for (uint256 i; i < userAssetBalancesLength; ) {
      // RULE 24 - Cache array member variable
      RewardsDataTypes.UserAssetBalance memory bal = userAssetBalances[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001004d,0)}
      _updateData(bal.asset, user, bal.userBalance, bal.totalSupply);
      // RULE 26 - Pre-increment; RULE 28 - Unchecked arithmetic: i < userAssetBalancesLength guarantees no overflow
      unchecked { ++i; }
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
  ) internal view returns (uint256 unclaimedRewards) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001c0000, 1037618708508) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001c0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001c1000, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001c1001, reward) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001c1002, userAssetBalances) }
    // RULE 25 - Cache array length in loops
    uint256 userAssetBalancesLength = userAssetBalances.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000002e,userAssetBalancesLength)}
    // RULE 9  - Avoid explicit zero initialization
    for (uint256 i; i < userAssetBalancesLength; ) {
      // RULE 24 - Cache array member variable
      RewardsDataTypes.UserAssetBalance memory bal = userAssetBalances[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001004e,0)}
      if (bal.userBalance == 0) {
        unclaimedRewards += _assets[bal.asset].rewards[reward].usersData[user].accrued;
      } else {
        unclaimedRewards +=
          _getPendingRewards(user, reward, bal) +
          _assets[bal.asset].rewards[reward].usersData[user].accrued;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000005b,unclaimedRewards)}
      }
      // RULE 26 - Pre-increment; RULE 28 - Unchecked arithmetic: i < userAssetBalancesLength guarantees no overflow
      unchecked { ++i; }
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
  ) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001d0000, 1037618708509) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001d0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001d1000, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001d1001, reward) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001d1002, userAssetBalance) }
    RewardsDataTypes.RewardData storage rewardData = _assets[userAssetBalance.asset].rewards[
      reward
    ];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001002f,0)}
    uint256 assetUnit = 10 ** _assets[userAssetBalance.asset].decimals;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000030,assetUnit)}
    (, uint256 nextIndex) = _getAssetIndex(rewardData, userAssetBalance.totalSupply, assetUnit);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010031,0)}

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
  ) internal pure returns (uint256 result) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001e0000, 1037618708510) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001e0001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001e1000, userBalance) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001e1001, reserveIndex) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001e1002, userIndex) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001e1003, assetUnit) }
    result = userBalance * (reserveIndex - userIndex);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000003f,result)}
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
  ) internal view returns (uint256, uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001f0000, 1037618708511) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001f0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001f1000, rewardData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001f1001, totalSupply) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff001f1002, assetUnit) }
    uint256 oldIndex = rewardData.index;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000032,oldIndex)}
    uint256 distributionEnd = rewardData.distributionEnd;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000033,distributionEnd)}
    uint256 emissionPerSecond = rewardData.emissionPerSecond;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000034,emissionPerSecond)}
    uint256 lastUpdateTimestamp = rewardData.lastUpdateTimestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000035,lastUpdateTimestamp)}

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
      : block.timestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000036,currentTimestamp)}
    uint256 timeDelta = currentTimestamp - lastUpdateTimestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000037,timeDelta)}
    uint256 firstTerm = emissionPerSecond * timeDelta * assetUnit;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000038,firstTerm)}
    assembly {
      firstTerm := div(firstTerm, totalSupply)
    }
    return (oldIndex, (firstTerm + oldIndex));
  }

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