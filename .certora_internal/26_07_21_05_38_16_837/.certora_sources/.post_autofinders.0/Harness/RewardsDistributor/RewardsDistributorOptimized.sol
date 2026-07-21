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

    function getUserRewards_instr(address[] calldata assets, address user, address reward) external returns (uint256) {
        uint256 r = this.getUserRewards(assets, user, reward);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000001,r)}
        lastGetUserRewardsReturn = r;
        return r;
    }

    function getAssetIndex_instr(address asset, address reward) external returns (uint256, uint256) {
        (uint256 n, uint256 o) = this.getAssetIndex(asset, reward);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010002,0)}
        lastAssetIndexNew = n;
        lastAssetIndexOld = o;
        return (n, o);
    }

    function _getUserAssetBalances(
        address[] calldata assets,
        address user
    ) internal view override returns (RewardsDataTypes.UserAssetBalance[] memory userAssetBalances) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00000000, 1037618708480) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00000001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00003000, assets.offset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00002000, assets.length) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00001001, user) }
        userAssetBalances = new RewardsDataTypes.UserAssetBalance[](assets.length);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020003,0)}
        for (uint256 i = 0; i < assets.length; i++) {
            userAssetBalances[i].asset = assets[i];address certora_local4 = userAssetBalances[i].asset;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000004,certora_local4)}
            userAssetBalances[i].userBalance = IScaledBalanceToken(assets[i]).scaledBalanceOf(user);uint256 certora_local5 = userAssetBalances[i].userBalance;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000005,certora_local5)}
            userAssetBalances[i].totalSupply = IScaledBalanceToken(assets[i]).scaledTotalSupply();uint256 certora_local6 = userAssetBalances[i].totalSupply;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000006,certora_local6)}
        }
        return userAssetBalances;
    }
}