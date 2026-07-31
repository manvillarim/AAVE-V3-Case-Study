// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {UserConfiguration} from "origin/src/contracts/protocol/libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "origin/src/contracts/protocol/libraries/types/DataTypes.sol";

contract UserConfigurationOrigin {
    using UserConfiguration for DataTypes.UserConfigurationMap;

    mapping(address => DataTypes.UserConfigurationMap) internal _usersConfig;

    function setBorrowing(address u, uint256 i, bool b) external {
        _usersConfig[u].setBorrowing(i, b);
    }

    function setUsingAsCollateral(address u, uint256 i, bool b) external {
        _usersConfig[u].setUsingAsCollateral(i, b);
    }

    function isUsingAsCollateralOrBorrowing(address u, uint256 i) external view returns (bool) {
        return _usersConfig[u].isUsingAsCollateralOrBorrowing(i);
    }

    function isBorrowing(address u, uint256 i) external view returns (bool) {
        return _usersConfig[u].isBorrowing(i);
    }

    function isUsingAsCollateral(address u, uint256 i) external view returns (bool) {
        return _usersConfig[u].isUsingAsCollateral(i);
    }

    function isUsingAsCollateralOne(address u) external view returns (bool) {
        return _usersConfig[u].isUsingAsCollateralOne();
    }

    function isBorrowingAny(address u) external view returns (bool) {
        return _usersConfig[u].isBorrowingAny();
    }

    function isEmpty(address u) external view returns (bool) {
        return _usersConfig[u].isEmpty();
    }

    function getFirstAssetIdByMask(address u, uint256 mask) external view returns (uint256) {
        return UserConfiguration._getFirstAssetIdByMask(_usersConfig[u], mask);
    }
}
