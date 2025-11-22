// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {DataTypes} from '../types/DataTypes.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {SafeCast} from '../../../dependencies/openzeppelin/contracts/SafeCast.sol';

/**
 * @title IsolationModeLogic library
 * @author Aave
 * @notice Implements the base logic for handling repayments for assets borrowed in isolation mode
 */
library IsolationModeLogic {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using SafeCast for uint256;

  // See `IPool` for descriptions
  event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

  /**
   * @notice updated the isolated debt whenever a position collateralized by an isolated asset is repaid
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig The user configuration mapping
   * @param reserveCache The cached data of the reserve
   * @param repayAmount The amount being repaid
   */
  function updateIsolatedDebtIfIsolated(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ReserveCache memory reserveCache,
    uint256 repayAmount
  ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006c0000, 1037618708588) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006c0001, 5) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006c1000, reservesData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006c1001, reservesList.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006c1002, userConfig.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006c1003, reserveCache) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006c1004, repayAmount) }
    (bool isolationModeActive, address isolationModeCollateralAddress, ) = userConfig
      .getIsolationModeState(reservesData, reservesList);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010060,0)}

    if (isolationModeActive) {
      updateIsolatedDebt(reservesData, reserveCache, repayAmount, isolationModeCollateralAddress);
    }
  }

  /**
   * @notice updated the isolated debt whenever a position collateralized by an isolated asset is liquidated
   * @param reservesData The state of all the reserves
   * @param reserveCache The cached data of the reserve
   * @param repayAmount The amount being repaid
   * @param isolationModeCollateralAddress The address of the isolated collateral
   */
  function updateIsolatedDebt(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    DataTypes.ReserveCache memory reserveCache,
    uint256 repayAmount,
    address isolationModeCollateralAddress
  ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006d0000, 1037618708589) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006d0001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006d1000, reservesData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006d1001, reserveCache) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006d1002, repayAmount) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff006d1003, isolationModeCollateralAddress) }
    uint128 isolationModeTotalDebt = reservesData[isolationModeCollateralAddress]
      .isolationModeTotalDebt;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000061,isolationModeTotalDebt)}

    uint128 isolatedDebtRepaid = (repayAmount /
      10 **
        (reserveCache.reserveConfiguration.getDecimals() -
          ReserveConfiguration.DEBT_CEILING_DECIMALS)).toUint128();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000062,isolatedDebtRepaid)}

    // since the debt ceiling does not take into account the interest accrued, it might happen that amount
    // repaid > debt in isolation mode
    if (isolationModeTotalDebt <= isolatedDebtRepaid) {
      reservesData[isolationModeCollateralAddress].isolationModeTotalDebt = 0;
      emit IsolationModeTotalDebtUpdated(isolationModeCollateralAddress, 0);
    } else {
      uint256 nextIsolationModeTotalDebt = reservesData[isolationModeCollateralAddress]
        .isolationModeTotalDebt = isolationModeTotalDebt - isolatedDebtRepaid;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000063,nextIsolationModeTotalDebt)}
      emit IsolationModeTotalDebtUpdated(
        isolationModeCollateralAddress,
        nextIsolationModeTotalDebt
      );
    }
  }
}
