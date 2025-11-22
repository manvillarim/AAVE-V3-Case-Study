// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IScaledBalanceToken} from '../../../interfaces/IScaledBalanceToken.sol';
import {IPriceOracleGetter} from '../../../interfaces/IPriceOracleGetter.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {EModeConfiguration} from '../configuration/EModeConfiguration.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {EModeLogic} from './EModeLogic.sol';

/**
 * @title GenericLogic library
 * @author Aave
 * @notice Implements protocol-level logic to calculate and validate the state of a user
 */
library GenericLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  struct CalculateUserAccountDataVars {
    uint256 assetPrice;
    uint256 assetUnit;
    uint256 decimals;
    uint256 ltv;
    uint256 liquidationThreshold;
    address currentReserveAddress;
  }

  /**
   * @notice Calculates the user data across the reserves.
   * @dev It includes the total liquidity/collateral/borrow balances in the base currency used by the price feed,
   * the average Loan To Value, the average Liquidation Ratio, and the Health factor.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param params Additional parameters needed for the calculation
   * @return totalCollateralInBaseCurrency The total collateral of the user in the base currency used by the price feed
   * @return totalDebtInBaseCurrency The total debt of the user in the base currency used by the price feed
   * @return avgLtv The average ltv of the user
   * @return avgLiquidationThreshold The average liquidation threshold of the user
   * @return healthFactor The health factor of the user
   * @return hasZeroLtvCollateral True if the ltv is zero, false otherwise
   */
  function calculateUserAccountData(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.CalculateUserAccountDataParams memory params
  ) internal view returns (uint256 totalCollateralInBaseCurrency,
                           uint256 totalDebtInBaseCurrency,
                           uint256 avgLtv,
                           uint256 avgLiquidationThreshold,
                           uint256 healthFactor,
                           bool hasZeroLtvCollateral) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00680000, 1037618708584) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00680001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00681000, reservesData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00681001, reservesList.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00681002, eModeCategories.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00681003, params) }
    if (params.userConfig.isEmpty()) {
      return (0, 0, 0, 0, type(uint256).max, false);
    }

    CalculateUserAccountDataVars memory vars;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010051,0)}

    for(uint256 i; i<params.reservesCount; i++) {
      if (!params.userConfig.isUsingAsCollateralOrBorrowing(i)) {
        continue;
      }

      vars.currentReserveAddress = reservesList[i];address certora_local91 = vars.currentReserveAddress;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000005b,certora_local91)}

      if (vars.currentReserveAddress == address(0)) {
        continue;
      }

      DataTypes.ReserveData storage currentReserve = reservesData[vars.currentReserveAddress];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010059,0)}

      DataTypes.ReserveConfigurationMap memory currentReserveConfigCache = currentReserve.configuration;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001005a,0)}

      (vars.ltv, vars.liquidationThreshold, , vars.decimals, ) = currentReserveConfigCache
        .getParams();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002005c,0)}

      unchecked {
        vars.assetUnit = 10 ** vars.decimals;
      }

      vars.assetPrice = IPriceOracleGetter(params.oracle).getAssetPrice(vars.currentReserveAddress);uint256 certora_local93 = vars.assetPrice;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000005d,certora_local93)}

      if (vars.liquidationThreshold != 0 && params.userConfig.isUsingAsCollateral(i)) {
        uint256 userBalanceInBaseCurrency = _getUserBalanceInBaseCurrency(
          params.user,
          currentReserve,
          vars.assetPrice,
          vars.assetUnit
        );

        totalCollateralInBaseCurrency += userBalanceInBaseCurrency;

        bool isInEModeCategory =
          params.userEModeCategory != 0 &&
          EModeConfiguration.isReserveEnabledOnBitmap(
            eModeCategories[params.userEModeCategory].collateralBitmap,
            i
          );

        if (vars.ltv != 0) {
          avgLtv +=
            userBalanceInBaseCurrency *
            (isInEModeCategory ? eModeCategories[params.userEModeCategory].ltv : vars.ltv);
        } else {
          hasZeroLtvCollateral = true;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000005e,hasZeroLtvCollateral)}
        }

        avgLiquidationThreshold +=
          userBalanceInBaseCurrency *
          (isInEModeCategory ? eModeCategories[params.userEModeCategory].liquidationThreshold : vars.liquidationThreshold);
      }

      if (params.userConfig.isBorrowing(i)) {
        if (currentReserveConfigCache.getIsVirtualAccActive()) {
          totalDebtInBaseCurrency += _getUserDebtInBaseCurrency(
            params.user,
            currentReserve,
            vars.assetPrice,
            vars.assetUnit
          );
        } else {
          // custom case for GHO, which applies the GHO discount on balanceOf
          totalDebtInBaseCurrency +=
            (IERC20(currentReserve.variableDebtTokenAddress).balanceOf(params.user) *
              vars.assetPrice) /
            vars.assetUnit;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000005f,totalDebtInBaseCurrency)}
        }
      }
    }

    unchecked {
      avgLtv = totalCollateralInBaseCurrency != 0
        ? avgLtv / totalCollateralInBaseCurrency
        : 0;
      avgLiquidationThreshold = totalCollateralInBaseCurrency != 0
        ? avgLiquidationThreshold / totalCollateralInBaseCurrency
        : 0;
    }

    healthFactor = (totalDebtInBaseCurrency == 0)
      ? type(uint256).max
      : (totalCollateralInBaseCurrency.percentMul(avgLiquidationThreshold)).wadDiv(
        totalDebtInBaseCurrency
      );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000055,healthFactor)}
  }

  /**
   * @notice Calculates the maximum amount that can be borrowed depending on the available collateral, the total debt
   * and the average Loan To Value
   * @param totalCollateralInBaseCurrency The total collateral in the base currency used by the price feed
   * @param totalDebtInBaseCurrency The total borrow balance in the base currency used by the price feed
   * @param ltv The average loan to value
   * @return availableBorrowsInBaseCurrency The amount available to borrow in the base currency of the used by the price feed
   */
  function calculateAvailableBorrows(
    uint256 totalCollateralInBaseCurrency,
    uint256 totalDebtInBaseCurrency,
    uint256 ltv
  ) internal pure returns (uint256 availableBorrowsInBaseCurrency) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00690000, 1037618708585) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00690001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00691000, totalCollateralInBaseCurrency) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00691001, totalDebtInBaseCurrency) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00691002, ltv) }
    availableBorrowsInBaseCurrency = totalCollateralInBaseCurrency.percentMul(ltv);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000056,availableBorrowsInBaseCurrency)}

    if (availableBorrowsInBaseCurrency <= totalDebtInBaseCurrency) {
      return 0;
    }

    availableBorrowsInBaseCurrency = availableBorrowsInBaseCurrency - totalDebtInBaseCurrency;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000057,availableBorrowsInBaseCurrency)}
  }

  /**
   * @notice Calculates total debt of the user in the based currency used to normalize the values of the assets
   * @dev This fetches the `balanceOf` of the variable debt token for the user. For gas reasons, the
   * variable debt balance is calculated by fetching `scaledBalancesOf` normalized debt, which is cheaper than
   * fetching `balanceOf`
   * @param user The address of the user
   * @param reserve The data of the reserve for which the total debt of the user is being calculated
   * @param assetPrice The price of the asset for which the total debt of the user is being calculated
   * @param assetUnit The value representing one full unit of the asset (10^decimals)
   * @return The total debt of the user normalized to the base currency
   */
  function _getUserDebtInBaseCurrency(
    address user,
    DataTypes.ReserveData storage reserve,
    uint256 assetPrice,
    uint256 assetUnit
  ) private view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006a0000, 1037618708586) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006a0001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006a1000, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006a1001, reserve.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006a1002, assetPrice) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006a1003, assetUnit) }
    // fetching variable debt
    uint256 userTotalDebt = IScaledBalanceToken(reserve.variableDebtTokenAddress).scaledBalanceOf(
      user
    );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000052,userTotalDebt)}
    if (userTotalDebt == 0) {
      return 0;
    }

    userTotalDebt = userTotalDebt.rayMul(reserve.getNormalizedDebt()) * assetPrice;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000058,userTotalDebt)}
    unchecked {
      return userTotalDebt / assetUnit;
    }
  }

  /**
   * @notice Calculates total aToken balance of the user in the based currency used by the price oracle
   * @dev For gas reasons, the aToken balance is calculated by fetching `scaledBalancesOf` normalized debt, which
   * is cheaper than fetching `balanceOf`
   * @param user The address of the user
   * @param reserve The data of the reserve for which the total aToken balance of the user is being calculated
   * @param assetPrice The price of the asset for which the total aToken balance of the user is being calculated
   * @param assetUnit The value representing one full unit of the asset (10^decimals)
   * @return The total aToken balance of the user normalized to the base currency of the price oracle
   */
  function _getUserBalanceInBaseCurrency(
    address user,
    DataTypes.ReserveData storage reserve,
    uint256 assetPrice,
    uint256 assetUnit
  ) private view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006b0000, 1037618708587) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006b0001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006b1000, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006b1001, reserve.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006b1002, assetPrice) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006b1003, assetUnit) }
    uint256 normalizedIncome = reserve.getNormalizedIncome();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000053,normalizedIncome)}
    uint256 balance = (
      IScaledBalanceToken(reserve.aTokenAddress).scaledBalanceOf(user).rayMul(normalizedIncome)
    ) * assetPrice;uint256 certora_local84 = balance;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000054,certora_local84)}

    unchecked {
      return balance / assetUnit;
    }
  }
}
