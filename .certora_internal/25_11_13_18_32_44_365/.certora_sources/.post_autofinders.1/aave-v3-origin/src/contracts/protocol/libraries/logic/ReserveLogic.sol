// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IVariableDebtToken} from '../../../interfaces/IVariableDebtToken.sol';
import {IReserveInterestRateStrategy} from '../../../interfaces/IReserveInterestRateStrategy.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {MathUtils} from '../math/MathUtils.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {SafeCast} from '../../../dependencies/openzeppelin/contracts/SafeCast.sol';

/**
 * @title ReserveLogic library
 * @author Aave
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeCast for uint256;
  using GPv2SafeERC20 for IERC20;
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  // See `IPool` for descriptions
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @notice Returns the ongoing normalized income for the reserve.
   * @dev A value of 1e27 means there is no income. As time passes, the income is accrued
   * @dev A value of 2*1e27 means for each unit of asset one unit of income has been accrued
   * @param reserve The reserve object
   * @return The normalized income, expressed in ray
   */
  function getNormalizedIncome(
    DataTypes.ReserveData storage reserve
  ) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01120000, 1037618708754) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01120001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01121000, reserve.slot) }
    uint40 timestamp = reserve.lastUpdateTimestamp;uint40 certora_local149 = timestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000095,certora_local149)}

    //solium-disable-next-line
    if (timestamp == block.timestamp) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.liquidityIndex;
    } else {
      return
        MathUtils.calculateLinearInterest(reserve.currentLiquidityRate, timestamp).rayMul(
          reserve.liquidityIndex
        );
    }
  }

  /**
   * @notice Returns the ongoing normalized variable debt for the reserve.
   * @dev A value of 1e27 means there is no debt. As time passes, the debt is accrued
   * @dev A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
   * @param reserve The reserve object
   * @return The normalized variable debt, expressed in ray
   */
  function getNormalizedDebt(
    DataTypes.ReserveData storage reserve
  ) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01130000, 1037618708755) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01130001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01131000, reserve.slot) }
    uint40 timestamp = reserve.lastUpdateTimestamp;uint40 certora_local150 = timestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000096,certora_local150)}

    //solium-disable-next-line
    if (timestamp == block.timestamp) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.variableBorrowIndex;
    } else {
      return
        MathUtils.calculateCompoundedInterest(reserve.currentVariableBorrowRate, timestamp).rayMul(
          reserve.variableBorrowIndex
        );
    }
  }

  /**
   * @notice Updates the liquidity cumulative index and the variable borrow index.
   * @param reserve The reserve object
   * @param reserveCache The caching layer for the reserve data
   */
  function updateState(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache
  ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01150000, 1037618708757) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01150001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01151000, reserve.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01151001, reserveCache) }
    // If time didn't pass since last stored timestamp, skip state update
    //solium-disable-next-line
    if (reserveCache.reserveLastUpdateTimestamp == uint40(block.timestamp)) {
      return;
    }

    _updateIndexes(reserve, reserveCache);
    _accrueToTreasury(reserve, reserveCache);

    //solium-disable-next-line
    reserve.lastUpdateTimestamp = uint40(block.timestamp);uint40 certora_local159 = reserve.lastUpdateTimestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000009f,certora_local159)}
    reserveCache.reserveLastUpdateTimestamp = uint40(block.timestamp);uint40 certora_local160 = reserveCache.reserveLastUpdateTimestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000a0,certora_local160)}
  }

  /**
   * @notice Accumulates a predefined amount of asset to the reserve as a fixed, instantaneous income. Used for example
   * to accumulate the flashloan fee to the reserve, and spread it between all the suppliers.
   * @param reserve The reserve object
   * @param totalLiquidity The total liquidity available in the reserve
   * @param amount The amount to accumulate
   * @return The next liquidity index of the reserve
   */
  function cumulateToLiquidityIndex(
    DataTypes.ReserveData storage reserve,
    uint256 totalLiquidity,
    uint256 amount
  ) internal returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01160000, 1037618708758) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01160001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01161000, reserve.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01161001, totalLiquidity) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01161002, amount) }
    //next liquidity index is calculated this way: `((amount / totalLiquidity) + 1) * liquidityIndex`
    //division `amount / totalLiquidity` done in ray for precision
    uint256 result = (amount.wadToRay().rayDiv(totalLiquidity.wadToRay()) + WadRayMath.RAY).rayMul(
      reserve.liquidityIndex
    );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000097,result)}
    reserve.liquidityIndex = result.toUint128();uint128 certora_local161 = reserve.liquidityIndex;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000a1,certora_local161)}
    return result;
  }

  /**
   * @notice Initializes a reserve.
   * @param reserve The reserve object
   * @param aTokenAddress The address of the overlying atoken contract
   * @param variableDebtTokenAddress The address of the overlying variable debt token contract
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   */
  function init(
    DataTypes.ReserveData storage reserve,
    address aTokenAddress,
    address variableDebtTokenAddress,
    address interestRateStrategyAddress
  ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01140000, 1037618708756) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01140001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01141000, reserve.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01141001, aTokenAddress) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01141002, variableDebtTokenAddress) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01141003, interestRateStrategyAddress) }
    require(reserve.aTokenAddress == address(0), Errors.RESERVE_ALREADY_INITIALIZED);

    reserve.liquidityIndex = uint128(WadRayMath.RAY);uint128 certora_local162 = reserve.liquidityIndex;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000a2,certora_local162)}
    reserve.variableBorrowIndex = uint128(WadRayMath.RAY);uint128 certora_local163 = reserve.variableBorrowIndex;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000a3,certora_local163)}
    reserve.aTokenAddress = aTokenAddress;address certora_local164 = reserve.aTokenAddress;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000a4,certora_local164)}
    reserve.variableDebtTokenAddress = variableDebtTokenAddress;address certora_local165 = reserve.variableDebtTokenAddress;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000a5,certora_local165)}
    reserve.interestRateStrategyAddress = interestRateStrategyAddress;address certora_local166 = reserve.interestRateStrategyAddress;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000a6,certora_local166)}
  }

  /**
   * @notice Updates the reserve current variable borrow rate and the current liquidity rate.
   * @param reserve The reserve reserve to be updated
   * @param reserveCache The caching layer for the reserve data
   * @param reserveAddress The address of the reserve to be updated
   * @param liquidityAdded The amount of liquidity added to the protocol (supply or repay) in the previous action
   * @param liquidityTaken The amount of liquidity taken from the protocol (redeem or borrow)
   */
  function updateInterestRatesAndVirtualBalance(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache,
    address reserveAddress,
    uint256 liquidityAdded,
    uint256 liquidityTaken
  ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01170000, 1037618708759) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01170001, 5) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01171000, reserve.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01171001, reserveCache) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01171002, reserveAddress) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01171003, liquidityAdded) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01171004, liquidityTaken) }
    uint256 totalVariableDebt = reserveCache.nextScaledVariableDebt.rayMul(
      reserveCache.nextVariableBorrowIndex
    );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000098,totalVariableDebt)}

    (uint256 nextLiquidityRate, uint256 nextVariableRate) = IReserveInterestRateStrategy(
      reserve.interestRateStrategyAddress
    ).calculateInterestRates(
        DataTypes.CalculateInterestRatesParams({
          unbacked: reserve.unbacked + reserve.deficit,
          liquidityAdded: liquidityAdded,
          liquidityTaken: liquidityTaken,
          totalDebt: totalVariableDebt,
          reserveFactor: reserveCache.reserveFactor,
          reserve: reserveAddress,
          usingVirtualBalance: reserveCache.reserveConfiguration.getIsVirtualAccActive(),
          virtualUnderlyingBalance: reserve.virtualUnderlyingBalance
        })
      );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010099,0)}

    reserve.currentLiquidityRate = nextLiquidityRate.toUint128();uint128 certora_local167 = reserve.currentLiquidityRate;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000a7,certora_local167)}
    reserve.currentVariableBorrowRate = nextVariableRate.toUint128();uint128 certora_local168 = reserve.currentVariableBorrowRate;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000a8,certora_local168)}

    // Only affect virtual balance if the reserve uses it
    if (reserveCache.reserveConfiguration.getIsVirtualAccActive()) {
      if (liquidityAdded > 0) {
        reserve.virtualUnderlyingBalance += liquidityAdded.toUint128();
      }
      if (liquidityTaken > 0) {
        reserve.virtualUnderlyingBalance -= liquidityTaken.toUint128();
      }
    }

    emit ReserveDataUpdated(
      reserveAddress,
      nextLiquidityRate,
      0,
      nextVariableRate,
      reserveCache.nextLiquidityIndex,
      reserveCache.nextVariableBorrowIndex
    );
  }

  /**
   * @notice Mints part of the repaid interest to the reserve treasury as a function of the reserve factor for the
   * specific asset.
   * @param reserve The reserve to be updated
   * @param reserveCache The caching layer for the reserve data
   */
  function _accrueToTreasury(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache
  ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01180000, 1037618708760) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01180001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01181000, reserve.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01181001, reserveCache) }
    if (reserveCache.reserveFactor == 0) {
      return;
    }

    //calculate the total variable debt at moment of the last interaction
    uint256 prevTotalVariableDebt = reserveCache.currScaledVariableDebt.rayMul(
      reserveCache.currVariableBorrowIndex
    );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000009a,prevTotalVariableDebt)}

    //calculate the new total variable debt after accumulation of the interest on the index
    uint256 currTotalVariableDebt = reserveCache.currScaledVariableDebt.rayMul(
      reserveCache.nextVariableBorrowIndex
    );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000009b,currTotalVariableDebt)}

    //debt accrued is the sum of the current debt minus the sum of the debt at the last update
    uint256 totalDebtAccrued = currTotalVariableDebt - prevTotalVariableDebt;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000009c,totalDebtAccrued)}

    uint256 amountToMint = totalDebtAccrued.percentMul(reserveCache.reserveFactor);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000009d,amountToMint)}

    if (amountToMint != 0) {
      reserve.accruedToTreasury += amountToMint.rayDiv(reserveCache.nextLiquidityIndex).toUint128();
    }
  }

  /**
   * @notice Updates the reserve indexes and the timestamp of the update.
   * @param reserve The reserve reserve to be updated
   * @param reserveCache The cache layer holding the cached protocol data
   */
  function _updateIndexes(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache
  ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01190000, 1037618708761) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01190001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01191000, reserve.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01191001, reserveCache) }
    // Only cumulating on the supply side if there is any income being produced
    // The case of Reserve Factor 100% is not a problem (currentLiquidityRate == 0),
    // as liquidity index should not be updated
    if (reserveCache.currLiquidityRate != 0) {
      uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(
        reserveCache.currLiquidityRate,
        reserveCache.reserveLastUpdateTimestamp
      );
      reserveCache.nextLiquidityIndex = cumulatedLiquidityInterest.rayMul(
        reserveCache.currLiquidityIndex
      );
      reserve.liquidityIndex = reserveCache.nextLiquidityIndex.toUint128();
    }

    // Variable borrow index only gets updated if there is any variable debt.
    // reserveCache.currVariableBorrowRate != 0 is not a correct validation,
    // because a positive base variable rate can be stored on
    // reserveCache.currVariableBorrowRate, but the index should not increase
    if (reserveCache.currScaledVariableDebt != 0) {
      uint256 cumulatedVariableBorrowInterest = MathUtils.calculateCompoundedInterest(
        reserveCache.currVariableBorrowRate,
        reserveCache.reserveLastUpdateTimestamp
      );
      reserveCache.nextVariableBorrowIndex = cumulatedVariableBorrowInterest.rayMul(
        reserveCache.currVariableBorrowIndex
      );
      reserve.variableBorrowIndex = reserveCache.nextVariableBorrowIndex.toUint128();
    }
  }

  /**
   * @notice Creates a cache object to avoid repeated storage reads and external contract calls when updating state and
   * interest rates.
   * @param reserve The reserve object for which the cache will be filled
   * @return The cache object
   */
  function cache(
    DataTypes.ReserveData storage reserve
  ) internal view returns (DataTypes.ReserveCache memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011a0000, 1037618708762) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011a0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011a1000, reserve.slot) }
    DataTypes.ReserveCache memory reserveCache;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001009e,0)}

    reserveCache.reserveConfiguration = reserve.configuration;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000200a9,0)}
    reserveCache.reserveFactor = reserveCache.reserveConfiguration.getReserveFactor();uint256 certora_local170 = reserveCache.reserveFactor;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000aa,certora_local170)}
    reserveCache.currLiquidityIndex = reserveCache.nextLiquidityIndex = reserve.liquidityIndex;uint256 certora_local171 = reserveCache.currLiquidityIndex;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000ab,certora_local171)}
    reserveCache.currVariableBorrowIndex = reserveCache.nextVariableBorrowIndex = reserve
      .variableBorrowIndex;uint256 certora_local172 = reserveCache.currVariableBorrowIndex;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000ac,certora_local172)}
    reserveCache.currLiquidityRate = reserve.currentLiquidityRate;uint256 certora_local173 = reserveCache.currLiquidityRate;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000ad,certora_local173)}
    reserveCache.currVariableBorrowRate = reserve.currentVariableBorrowRate;uint256 certora_local174 = reserveCache.currVariableBorrowRate;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000ae,certora_local174)}

    reserveCache.aTokenAddress = reserve.aTokenAddress;address certora_local175 = reserveCache.aTokenAddress;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000af,certora_local175)}
    reserveCache.variableDebtTokenAddress = reserve.variableDebtTokenAddress;address certora_local176 = reserveCache.variableDebtTokenAddress;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000b0,certora_local176)}

    reserveCache.reserveLastUpdateTimestamp = reserve.lastUpdateTimestamp;uint40 certora_local177 = reserveCache.reserveLastUpdateTimestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000b1,certora_local177)}

    reserveCache.currScaledVariableDebt = reserveCache.nextScaledVariableDebt = IVariableDebtToken(
      reserveCache.variableDebtTokenAddress
    ).scaledTotalSupply();uint256 certora_local178 = reserveCache.currScaledVariableDebt;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000b2,certora_local178)}

    return reserveCache;
  }
}
