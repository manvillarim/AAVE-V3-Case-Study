// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import {MathUtilsOrigin} from "../src/MathUtilsOrigin.sol";
import {MathUtilsCyfrin} from "../src/MathUtilsCyfrin.sol";
import {MathUtilsOurs} from "../src/MathUtilsOurs.sol";

import {UserConfigurationOrigin} from "../src/UserConfigurationOrigin.sol";
import {UserConfigurationCyfrin} from "../src/UserConfigurationCyfrin.sol";
import {UserConfigurationOurs} from "../src/UserConfigurationOurs.sol";

import {CalldataLogicOrigin} from "../src/CalldataLogicOrigin.sol";
import {CalldataLogicCyfrin} from "../src/CalldataLogicCyfrin.sol";
import {CalldataLogicOurs} from "../src/CalldataLogicOurs.sol";

abstract contract GasConstants is Test {
    uint256 internal constant RATE = 5e25;
    uint40 internal constant LAST = 1_000_000;
    uint256 internal constant NOW_TS = 1_030_000;

    address internal constant USER = address(0xBEEF);
    address internal constant ASSET0 = address(0xA0);
    address internal constant ASSET1 = address(0xA1);

    uint256 internal constant COLLATERAL_MASK =
        0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;

    bytes32 internal constant ARGS1 =
        bytes32(uint256(0x0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f00));
    bytes32 internal constant ARGS2 =
        bytes32(uint256(0x00112233445566778899aabbccddeeff00112233445566778899aabbccddee01));
}

abstract contract MathUtilsGasBase is GasConstants {
    function _linear(uint256 rate, uint40 t) internal view virtual returns (uint256);

    function _compounded(uint256 rate, uint40 t, uint256 cur) internal view virtual returns (uint256);

    function _compoundedNow(uint256 rate, uint40 t) internal view virtual returns (uint256);

    function setUp() public virtual {
        vm.warp(NOW_TS);
    }

    function testCalculateLinearInterest() public view {
        _linear(RATE, LAST);
    }

    function testCalculateCompoundedInterest() public view {
        _compounded(RATE, LAST, NOW_TS);
    }

    function testCalculateCompoundedInterestNow() public view {
        _compoundedNow(RATE, LAST);
    }
}

contract MathUtilsOriginGas is MathUtilsGasBase {
    MathUtilsOrigin internal c;

    function setUp() public override {
        super.setUp();
        c = new MathUtilsOrigin();
    }

    function _linear(uint256 rate, uint40 t) internal view override returns (uint256) {
        return c.calculateLinearInterest(rate, t);
    }

    function _compounded(uint256 rate, uint40 t, uint256 cur) internal view override returns (uint256) {
        return c.calculateCompoundedInterest(rate, t, cur);
    }

    function _compoundedNow(uint256 rate, uint40 t) internal view override returns (uint256) {
        return c.calculateCompoundedInterestNow(rate, t);
    }
}

contract MathUtilsCyfrinGas is MathUtilsGasBase {
    MathUtilsCyfrin internal c;

    function setUp() public override {
        super.setUp();
        c = new MathUtilsCyfrin();
    }

    function _linear(uint256 rate, uint40 t) internal view override returns (uint256) {
        return c.calculateLinearInterest(rate, t);
    }

    function _compounded(uint256 rate, uint40 t, uint256 cur) internal view override returns (uint256) {
        return c.calculateCompoundedInterest(rate, t, cur);
    }

    function _compoundedNow(uint256 rate, uint40 t) internal view override returns (uint256) {
        return c.calculateCompoundedInterestNow(rate, t);
    }
}

contract MathUtilsOursGas is MathUtilsGasBase {
    MathUtilsOurs internal c;

    function setUp() public override {
        super.setUp();
        c = new MathUtilsOurs();
    }

    function _linear(uint256 rate, uint40 t) internal view override returns (uint256) {
        return c.calculateLinearInterest(rate, t);
    }

    function _compounded(uint256 rate, uint40 t, uint256 cur) internal view override returns (uint256) {
        return c.calculateCompoundedInterest(rate, t, cur);
    }

    function _compoundedNow(uint256 rate, uint40 t) internal view override returns (uint256) {
        return c.calculateCompoundedInterestNow(rate, t);
    }
}

abstract contract UserConfigurationGasBase is GasConstants {
    function _c() internal view virtual returns (UserConfigurationOrigin);

    function _seed() internal {
        UserConfigurationOrigin c = _c();
        c.setBorrowing(USER, 3, true);
        c.setUsingAsCollateral(USER, 5, true);
    }

    function testSetBorrowing() public {
        _c().setBorrowing(USER, 7, true);
    }

    function testSetUsingAsCollateral() public {
        _c().setUsingAsCollateral(USER, 9, true);
    }

    function testIsUsingAsCollateralOrBorrowing() public view {
        _c().isUsingAsCollateralOrBorrowing(USER, 3);
    }

    function testIsBorrowing() public view {
        _c().isBorrowing(USER, 3);
    }

    function testIsUsingAsCollateral() public view {
        _c().isUsingAsCollateral(USER, 5);
    }

    function testIsUsingAsCollateralOne() public view {
        _c().isUsingAsCollateralOne(USER);
    }

    function testIsBorrowingAny() public view {
        _c().isBorrowingAny(USER);
    }

    function testIsEmpty() public view {
        _c().isEmpty(USER);
    }

    function testGetFirstAssetIdByMask() public view {
        _c().getFirstAssetIdByMask(USER, COLLATERAL_MASK);
    }
}

contract UserConfigurationOriginGas is UserConfigurationGasBase {
    UserConfigurationOrigin internal c;

    function setUp() public {
        c = new UserConfigurationOrigin();
        _seed();
    }

    function _c() internal view override returns (UserConfigurationOrigin) {
        return c;
    }
}

contract UserConfigurationCyfrinGas is UserConfigurationGasBase {
    UserConfigurationCyfrin internal c;

    function setUp() public {
        c = new UserConfigurationCyfrin();
        _seed();
    }

    function _c() internal view override returns (UserConfigurationOrigin) {
        return UserConfigurationOrigin(address(c));
    }
}

contract UserConfigurationOursGas is UserConfigurationGasBase {
    UserConfigurationOurs internal c;

    function setUp() public {
        c = new UserConfigurationOurs();
        _seed();
    }

    function _c() internal view override returns (UserConfigurationOrigin) {
        return UserConfigurationOrigin(address(c));
    }
}

abstract contract CalldataLogicGasBase is GasConstants {
    function _c() internal view virtual returns (CalldataLogicOrigin);

    function _seed() internal {
        CalldataLogicOrigin c = _c();
        c.setReserve(0, ASSET0);
        c.setReserve(1, ASSET1);
    }

    function testDecodeSupplyParams() public view {
        _c().decodeSupplyParams(ARGS1);
    }

    function testDecodeSupplyWithPermitParams() public view {
        _c().decodeSupplyWithPermitParams(ARGS1);
    }

    function testDecodeWithdrawParams() public view {
        _c().decodeWithdrawParams(ARGS1);
    }

    function testDecodeBorrowParams() public view {
        _c().decodeBorrowParams(ARGS1);
    }

    function testDecodeRepayParams() public view {
        _c().decodeRepayParams(ARGS1);
    }

    function testDecodeRepayWithPermitParams() public view {
        _c().decodeRepayWithPermitParams(ARGS1);
    }

    function testDecodeSetUserUseReserveAsCollateralParams() public view {
        _c().decodeSetUserUseReserveAsCollateralParams(ARGS1);
    }

    function testDecodeLiquidationCallParams() public view {
        _c().decodeLiquidationCallParams(ARGS1, ARGS2);
    }
}

contract CalldataLogicOriginGas is CalldataLogicGasBase {
    CalldataLogicOrigin internal c;

    function setUp() public {
        c = new CalldataLogicOrigin();
        _seed();
    }

    function _c() internal view override returns (CalldataLogicOrigin) {
        return c;
    }
}

contract CalldataLogicCyfrinGas is CalldataLogicGasBase {
    CalldataLogicCyfrin internal c;

    function setUp() public {
        c = new CalldataLogicCyfrin();
        _seed();
    }

    function _c() internal view override returns (CalldataLogicOrigin) {
        return CalldataLogicOrigin(address(c));
    }
}

contract CalldataLogicOursGas is CalldataLogicGasBase {
    CalldataLogicOurs internal c;

    function setUp() public {
        c = new CalldataLogicOurs();
        _seed();
    }

    function _c() internal view override returns (CalldataLogicOrigin) {
        return CalldataLogicOrigin(address(c));
    }
}
