// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {RewardsDistributor} from "../../aave-v3-origin-instr/src/contracts/rewards/RewardsDistributor.sol";
import {RewardsDataTypes} from "../../aave-v3-origin-instr/src/contracts/rewards/libraries/RewardsDataTypes.sol";
import {IScaledBalanceToken} from "../../aave-v3-origin-instr/src/contracts/interfaces/IScaledBalanceToken.sol";

contract RewardsDistributorOriginal is RewardsDistributor {
    constructor(address emissionManager) RewardsDistributor(emissionManager) {}

    uint256 public lastGetUserRewardsReturn;
    uint256 public lastAssetIndexNew;
    uint256 public lastAssetIndexOld;
    address[] public lastAllRewardsList;
    uint256[] public lastAllUnclaimedAmounts;

    function getUserRewards_instr(address[] calldata assets, address user, address reward) external returns (uint256) {
        uint256 r = this.getUserRewards(assets, user, reward);
        lastGetUserRewardsReturn = r;
        return r;
    }

    function getAllUserRewards_instr(address[] calldata assets, address user) external returns (address[] memory, uint256[] memory) {
        (address[] memory rl, uint256[] memory ua) = this.getAllUserRewards(assets, user);
        lastAllRewardsList = rl;
        lastAllUnclaimedAmounts = ua;
        return (rl, ua);
    }

    function getAssetIndex_instr(address asset, address reward) external returns (uint256, uint256) {
        (uint256 n, uint256 o) = this.getAssetIndex(asset, reward);
        lastAssetIndexNew = n;
        lastAssetIndexOld = o;
        return (n, o);
    }

    function _getUserAssetBalances(
        address[] calldata assets,
        address user
    ) internal view override returns (RewardsDataTypes.UserAssetBalance[] memory userAssetBalances) {
        userAssetBalances = new RewardsDataTypes.UserAssetBalance[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            userAssetBalances[i].asset = assets[i];
            userAssetBalances[i].userBalance = IScaledBalanceToken(assets[i]).scaledBalanceOf(user);
            userAssetBalances[i].totalSupply = IScaledBalanceToken(assets[i]).scaledTotalSupply();
        }
        return userAssetBalances;
    }

    uint256 public emitCount;
    bytes32 public emitDigest;

    address public lastAcuAsset;
    address public lastAcuReward;
    uint256 public lastAcuOldEmission;
    uint256 public lastAcuNewEmission;
    uint256 public lastAcuOldDistributionEnd;
    uint256 public lastAcuNewDistributionEnd;
    uint256 public lastAcuAssetIndex;

    address public lastAccruedAsset;
    address public lastAccruedReward;
    address public lastAccruedUser;
    uint256 public lastAccruedAssetIndex;
    uint256 public lastAccruedUserIndex;
    uint256 public lastAccruedAmount;

    function _recordAssetConfigUpdated(
        address asset,
        address reward,
        uint256 oldEmission,
        uint256 newEmission,
        uint256 oldDistributionEnd,
        uint256 newDistributionEnd,
        uint256 assetIndex
    ) internal override {
        lastAcuAsset = asset;
        lastAcuReward = reward;
        lastAcuOldEmission = oldEmission;
        lastAcuNewEmission = newEmission;
        lastAcuOldDistributionEnd = oldDistributionEnd;
        lastAcuNewDistributionEnd = newDistributionEnd;
        lastAcuAssetIndex = assetIndex;
        unchecked {
            emitCount = emitCount + 1;
        }
        emitDigest = keccak256(
            abi.encode(
                emitDigest,
                "AssetConfigUpdated",
                asset,
                reward,
                oldEmission,
                newEmission,
                oldDistributionEnd,
                newDistributionEnd,
                assetIndex
            )
        );
    }

    function _recordAccrued(
        address asset,
        address reward,
        address user,
        uint256 assetIndex,
        uint256 userIndex,
        uint256 rewardsAccrued
    ) internal override {
        lastAccruedAsset = asset;
        lastAccruedReward = reward;
        lastAccruedUser = user;
        lastAccruedAssetIndex = assetIndex;
        lastAccruedUserIndex = userIndex;
        lastAccruedAmount = rewardsAccrued;
        unchecked {
            emitCount = emitCount + 1;
        }
        emitDigest = keccak256(
            abi.encode(
                emitDigest,
                "Accrued",
                asset,
                reward,
                user,
                assetIndex,
                userIndex,
                rewardsAccrued
            )
        );
    }
}
