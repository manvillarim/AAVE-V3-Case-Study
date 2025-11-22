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
                           bool hasZeroLtvCollateral) {
    if (params.userConfig.isEmpty()) {
      return (0, 0, 0, 0, type(uint256).max, false);
    }

    CalculateUserAccountDataVars memory vars;

    for(uint256 i; i<params.reservesCount; i++) {
      if (!params.userConfig.isUsingAsCollateralOrBorrowing(i)) {
        continue;
      }

      vars.currentReserveAddress = reservesList[i];

      if (vars.currentReserveAddress == address(0)) {
        continue;
      }

      DataTypes.ReserveData storage currentReserve = reservesData[vars.currentReserveAddress];

      DataTypes.ReserveConfigurationMap memory currentReserveConfigCache = currentReserve.configuration;

      (vars.ltv, vars.liquidationThreshold, , vars.decimals, ) = currentReserveConfigCache
        .getParams();

      unchecked {
        vars.assetUnit = 10 ** vars.decimals;
      }

      vars.assetPrice = IPriceOracleGetter(params.oracle).getAssetPrice(vars.currentReserveAddress);

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
          hasZeroLtvCollateral = true;
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
            vars.assetUnit;
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
      );
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
  ) internal pure returns (uint256 availableBorrowsInBaseCurrency) {
    availableBorrowsInBaseCurrency = totalCollateralInBaseCurrency.percentMul(ltv);

    if (availableBorrowsInBaseCurrency <= totalDebtInBaseCurrency) {
      return 0;
    }

    availableBorrowsInBaseCurrency = availableBorrowsInBaseCurrency - totalDebtInBaseCurrency;
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
  ) private view returns (uint256) {
    // fetching variable debt
    uint256 userTotalDebt = IScaledBalanceToken(reserve.variableDebtTokenAddress).scaledBalanceOf(
      user
    );
    if (userTotalDebt == 0) {
      return 0;
    }

    userTotalDebt = userTotalDebt.rayMul(reserve.getNormalizedDebt()) * assetPrice;
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
  ) private view returns (uint256) {
    uint256 normalizedIncome = reserve.getNormalizedIncome();
    uint256 balance = (
      IScaledBalanceToken(reserve.aTokenAddress).scaledBalanceOf(user).rayMul(normalizedIncome)
    ) * assetPrice;

    unchecked {
      return balance / assetUnit;
    }
  }
}
