// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {UserConfiguration} from "aave-v3-origin/src/contracts/protocol/libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "aave-v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";

contract UserConfigurationOriginal {
    using UserConfiguration for DataTypes.UserConfigurationMap;

    mapping(address => DataTypes.UserConfigurationMap) internal _usersConfig;

    bool public lastBoolReturn;
    uint256 public lastUintReturn;

    function setBorrowing_instr(address user, uint256 reserveIndex, bool borrowing) external {
        _usersConfig[user].setBorrowing(reserveIndex, borrowing);
    }

    function setBorrowingCached_instr(address user, uint256 reserveIndex, bool borrowing) external {
        _usersConfig[user].setBorrowing(reserveIndex, borrowing);
    }

    function setUsingAsCollateral_instr(address user, uint256 reserveIndex, bool usingAsCollateral) external {
        _usersConfig[user].setUsingAsCollateral(reserveIndex, usingAsCollateral);
    }

    function setUsingAsCollateralCached_instr(address user, uint256 reserveIndex, bool usingAsCollateral) external {
        _usersConfig[user].setUsingAsCollateral(reserveIndex, usingAsCollateral);
    }

    function isUsingAsCollateralOrBorrowing_instr(address user, uint256 reserveIndex) external returns (bool) {
        bool r = _usersConfig[user].isUsingAsCollateralOrBorrowing(reserveIndex);
        lastBoolReturn = r;
        return r;
    }

    function isBorrowing_instr(address user, uint256 reserveIndex) external returns (bool) {
        bool r = _usersConfig[user].isBorrowing(reserveIndex);
        lastBoolReturn = r;
        return r;
    }

    function isUsingAsCollateral_instr(address user, uint256 reserveIndex) external returns (bool) {
        bool r = _usersConfig[user].isUsingAsCollateral(reserveIndex);
        lastBoolReturn = r;
        return r;
    }

    function isUsingAsCollateralOne_instr(address user) external returns (bool) {
        bool r = _usersConfig[user].isUsingAsCollateralOne();
        lastBoolReturn = r;
        return r;
    }

    function isUsingAsCollateralAny_instr(address user) external returns (bool) {
        bool r = _usersConfig[user].isUsingAsCollateralAny();
        lastBoolReturn = r;
        return r;
    }

    function isBorrowingOne_instr(address user) external returns (bool) {
        bool r = _usersConfig[user].isBorrowingOne();
        lastBoolReturn = r;
        return r;
    }

    function isBorrowingAny_instr(address user) external returns (bool) {
        bool r = _usersConfig[user].isBorrowingAny();
        lastBoolReturn = r;
        return r;
    }

    function isEmpty_instr(address user) external returns (bool) {
        bool r = _usersConfig[user].isEmpty();
        lastBoolReturn = r;
        return r;
    }

    function getFirstAssetIdByMask_instr(address user, uint256 mask) external returns (uint256) {
        uint256 r = UserConfiguration._getFirstAssetIdByMask(_usersConfig[user], mask);
        lastUintReturn = r;
        return r;
    }
}
