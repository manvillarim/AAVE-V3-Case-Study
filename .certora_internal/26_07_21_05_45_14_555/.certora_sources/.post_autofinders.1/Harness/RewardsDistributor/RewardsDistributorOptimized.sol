// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {RewardsDistributor} from "../../aave-v3-origin-liquidation-gas-fixes/src/contracts/rewards/RewardsDistributor.sol";
import {RewardsDataTypes} from "../../aave-v3-origin-liquidation-gas-fixes/src/contracts/rewards/libraries/RewardsDataTypes.sol";
import {IScaledBalanceToken} from "../../aave-v3-origin-liquidation-gas-fixes/src/contracts/interfaces/IScaledBalanceToken.sol";

contract RewardsDistributorOptimized is RewardsDistributor {
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
}