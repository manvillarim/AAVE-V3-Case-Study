// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {RewardsDistributor} from "../../aave-v3-origin/src/contracts/rewards/RewardsDistributor.sol";
import {RewardsDataTypes} from "../../aave-v3-origin/src/contracts/rewards/libraries/RewardsDataTypes.sol";
import {IScaledBalanceToken} from "../../aave-v3-origin/src/contracts/interfaces/IScaledBalanceToken.sol";

contract RewardsDistributorOriginal is RewardsDistributor {
    constructor(address emissionManager) RewardsDistributor(emissionManager) {}
    
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