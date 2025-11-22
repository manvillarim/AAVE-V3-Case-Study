// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {Address} from '../../../dependencies/openzeppelin/contracts/Address.sol';
import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IPriceOracleGetter} from '../../../interfaces/IPriceOracleGetter.sol';
import {IAToken} from '../../../interfaces/IAToken.sol';
import {IPriceOracleSentinel} from '../../../interfaces/IPriceOracleSentinel.sol';
import {IPoolAddressesProvider} from '../../../interfaces/IPoolAddressesProvider.sol';
import {IAccessControl} from '../../../dependencies/openzeppelin/contracts/IAccessControl.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {EModeConfiguration} from '../configuration/EModeConfiguration.sol';
import {Errors} from '../helpers/Errors.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {GenericLogic} from './GenericLogic.sol';
import {SafeCast} from '../../../dependencies/openzeppelin/contracts/SafeCast.sol';
import {IncentivizedERC20} from '../../tokenization/base/IncentivizedERC20.sol';

/**
 * @title ValidationLogic library
 * @author Aave
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeCast for uint256;
  using GPv2SafeERC20 for IERC20;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using Address for address;

  // Factor to apply to "only-variable-debt" liquidity rate to get threshold for rebalancing, expressed in bps
  // A value of 0.9e4 results in 90%
  uint256 public constant REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD = 0.9e4;

  // Minimum health factor allowed under any circumstance
  // A value of 0.95e18 results in 0.95
  uint256 public constant MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 0.95e18;

  /**
   * @dev Minimum health factor to consider a user position healthy
   * A value of 1e18 results in 1
   */
  uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;

  /**
   * @dev Role identifier for the role allowed to supply isolated reserves as collateral
   */
  bytes32 public constant ISOLATED_COLLATERAL_SUPPLIER_ROLE =
    keccak256('ISOLATED_COLLATERAL_SUPPLIER');

  /**
   * @notice Validates a supply action.
   * @param reserveCache The cached data of the reserve
   * @param amount The amount to be supplied
   */
  function validateSupply(
    DataTypes.ReserveCache memory reserveCache,
    DataTypes.ReserveData storage reserve,
    uint256 amount,
    address onBehalfOf
  ) internal view {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011b0000, 1037618708763) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011b0001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011b1000, reserveCache) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011b1001, reserve.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011b1002, amount) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011b1003, onBehalfOf) }
    require(amount != 0, Errors.INVALID_AMOUNT);

    (bool isActive, bool isFrozen, , bool isPaused) = reserveCache.reserveConfiguration.getFlags();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100c1,0)}
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);
    require(!isFrozen, Errors.RESERVE_FROZEN);
    require(onBehalfOf != reserveCache.aTokenAddress, Errors.SUPPLY_TO_ATOKEN);

    uint256 supplyCap = reserveCache.reserveConfiguration.getSupplyCap();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000c2,supplyCap)}
    require(
      supplyCap == 0 ||
        ((IAToken(reserveCache.aTokenAddress).scaledTotalSupply() +
          uint256(reserve.accruedToTreasury)).rayMul(reserveCache.nextLiquidityIndex) + amount) <=
        supplyCap * (10 ** reserveCache.reserveConfiguration.getDecimals()),
      Errors.SUPPLY_CAP_EXCEEDED
    );
  }

  /**
   * @notice Validates a withdraw action.
   * @param reserveCache The cached data of the reserve
   * @param amount The amount to be withdrawn
   * @param userBalance The balance of the user
   */
  function validateWithdraw(
    DataTypes.ReserveCache memory reserveCache,
    uint256 amount,
    uint256 userBalance
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011c0000, 1037618708764) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011c0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011c1000, reserveCache) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011c1001, amount) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011c1002, userBalance) }
    require(amount != 0, Errors.INVALID_AMOUNT);
    require(amount <= userBalance, Errors.NOT_ENOUGH_AVAILABLE_USER_BALANCE);

    (bool isActive, , , bool isPaused) = reserveCache.reserveConfiguration.getFlags();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100c3,0)}
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);
  }

  struct ValidateBorrowLocalVars {
    uint256 currentLtv;
    uint256 collateralNeededInBaseCurrency;
    uint256 userCollateralInBaseCurrency;
    uint256 userDebtInBaseCurrency;
    uint256 availableLiquidity;
    uint256 healthFactor;
    uint256 totalDebt;
    uint256 totalSupplyVariableDebt;
    uint256 reserveDecimals;
    uint256 borrowCap;
    uint256 amountInBaseCurrency;
    uint256 assetUnit;
    address siloedBorrowingAddress;
    bool isActive;
    bool isFrozen;
    bool isPaused;
    bool borrowingEnabled;
    bool siloedBorrowingEnabled;
  }

  /**
   * @notice Validates a borrow action.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param params Additional params needed for the validation
   */
  function validateBorrow(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.ValidateBorrowParams memory params
  ) internal view {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011e0000, 1037618708766) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011e0001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011e1000, reservesData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011e1001, reservesList.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011e1002, eModeCategories.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011e1003, params) }
    require(params.amount != 0, Errors.INVALID_AMOUNT);

    ValidateBorrowLocalVars memory vars;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100c4,0)}

    (vars.isActive, vars.isFrozen, vars.borrowingEnabled, vars.isPaused) = params
      .reserveCache
      .reserveConfiguration
      .getFlags();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000200ce,0)}

    require(vars.isActive, Errors.RESERVE_INACTIVE);
    require(!vars.isPaused, Errors.RESERVE_PAUSED);
    require(!vars.isFrozen, Errors.RESERVE_FROZEN);
    require(vars.borrowingEnabled, Errors.BORROWING_NOT_ENABLED);
    require(
      !params.reserveCache.reserveConfiguration.getIsVirtualAccActive() ||
        IERC20(params.reserveCache.aTokenAddress).totalSupply() >= params.amount,
      Errors.INVALID_AMOUNT
    );

    require(
      params.priceOracleSentinel == address(0) ||
        IPriceOracleSentinel(params.priceOracleSentinel).isBorrowAllowed(),
      Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
    );

    //validate interest rate mode
    require(
      params.interestRateMode == DataTypes.InterestRateMode.VARIABLE,
      Errors.INVALID_INTEREST_RATE_MODE_SELECTED
    );

    vars.reserveDecimals = params.reserveCache.reserveConfiguration.getDecimals();uint256 certora_local207 = vars.reserveDecimals;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000cf,certora_local207)}
    vars.borrowCap = params.reserveCache.reserveConfiguration.getBorrowCap();uint256 certora_local208 = vars.borrowCap;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000d0,certora_local208)}
    unchecked {
      vars.assetUnit = 10 ** vars.reserveDecimals;
    }

    if (vars.borrowCap != 0) {
      vars.totalSupplyVariableDebt = params.reserveCache.currScaledVariableDebt.rayMul(
        params.reserveCache.nextVariableBorrowIndex
      );

      vars.totalDebt = vars.totalSupplyVariableDebt + params.amount;

      unchecked {
        require(vars.totalDebt <= vars.borrowCap * vars.assetUnit, Errors.BORROW_CAP_EXCEEDED);
      }
    }

    if (params.isolationModeActive) {
      // check that the asset being borrowed is borrowable in isolation mode AND
      // the total exposure is no bigger than the collateral debt ceiling
      require(
        params.reserveCache.reserveConfiguration.getBorrowableInIsolation(),
        Errors.ASSET_NOT_BORROWABLE_IN_ISOLATION
      );

      require(
        reservesData[params.isolationModeCollateralAddress].isolationModeTotalDebt +
          (params.amount /
            10 ** (vars.reserveDecimals - ReserveConfiguration.DEBT_CEILING_DECIMALS))
            .toUint128() <=
          params.isolationModeDebtCeiling,
        Errors.DEBT_CEILING_EXCEEDED
      );
    }

    if (params.userEModeCategory != 0) {
      require(
        EModeConfiguration.isReserveEnabledOnBitmap(
          eModeCategories[params.userEModeCategory].borrowableBitmap,
          reservesData[params.asset].id
        ),
        Errors.NOT_BORROWABLE_IN_EMODE
      );
    }

    (
      vars.userCollateralInBaseCurrency,
      vars.userDebtInBaseCurrency,
      vars.currentLtv,
      ,
      vars.healthFactor,

    ) = GenericLogic.calculateUserAccountData(
      reservesData,
      reservesList,
      eModeCategories,
      DataTypes.CalculateUserAccountDataParams({
        userConfig: params.userConfig,
        reservesCount: params.reservesCount,
        user: params.userAddress,
        oracle: params.oracle,
        userEModeCategory: params.userEModeCategory
      })
    );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000200d1,0)}

    require(vars.userCollateralInBaseCurrency != 0, Errors.COLLATERAL_BALANCE_IS_ZERO);
    require(vars.currentLtv != 0, Errors.LTV_VALIDATION_FAILED);

    require(
      vars.healthFactor > HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
    );

    vars.amountInBaseCurrency =
      IPriceOracleGetter(params.oracle).getAssetPrice(params.asset) *
      params.amount;uint256 certora_local210 = vars.amountInBaseCurrency;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000d2,certora_local210)}
    unchecked {
      vars.amountInBaseCurrency /= vars.assetUnit;
    }

    //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
    vars.collateralNeededInBaseCurrency = (vars.userDebtInBaseCurrency + vars.amountInBaseCurrency)
      .percentDiv(vars.currentLtv);uint256 certora_local211 = vars.collateralNeededInBaseCurrency;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000d3,certora_local211)} //LTV is calculated in percentage

    require(
      vars.collateralNeededInBaseCurrency <= vars.userCollateralInBaseCurrency,
      Errors.COLLATERAL_CANNOT_COVER_NEW_BORROW
    );

    if (params.userConfig.isBorrowingAny()) {
      (vars.siloedBorrowingEnabled, vars.siloedBorrowingAddress) = params
        .userConfig
        .getSiloedBorrowingState(reservesData, reservesList);

      if (vars.siloedBorrowingEnabled) {
        require(vars.siloedBorrowingAddress == params.asset, Errors.SILOED_BORROWING_VIOLATION);
      } else {
        require(
          !params.reserveCache.reserveConfiguration.getSiloedBorrowing(),
          Errors.SILOED_BORROWING_VIOLATION
        );
      }
    }
  }

  /**
   * @notice Validates a repay action.
   * @param reserveCache The cached data of the reserve
   * @param amountSent The amount sent for the repayment. Can be an actual value or uint(-1)
   * @param onBehalfOf The address of the user msg.sender is repaying for
   * @param debt The borrow balance of the user
   */
  function validateRepay(
    DataTypes.ReserveCache memory reserveCache,
    uint256 amountSent,
    DataTypes.InterestRateMode interestRateMode,
    address onBehalfOf,
    uint256 debt
  ) internal view {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011f0000, 1037618708767) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011f0001, 5) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011f1000, reserveCache) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011f1001, amountSent) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011f1002, interestRateMode) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011f1003, onBehalfOf) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011f1004, debt) }
    require(amountSent != 0, Errors.INVALID_AMOUNT);
    require(
      interestRateMode == DataTypes.InterestRateMode.VARIABLE,
      Errors.INVALID_INTEREST_RATE_MODE_SELECTED
    );
    require(
      amountSent != type(uint256).max || msg.sender == onBehalfOf,
      Errors.NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF
    );

    (bool isActive, , , bool isPaused) = reserveCache.reserveConfiguration.getFlags();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100c5,0)}
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);

    require(debt != 0, Errors.NO_DEBT_OF_SELECTED_TYPE);
  }

  /**
   * @notice Validates the action of setting an asset as collateral.
   * @param reserveCache The cached data of the reserve
   * @param userBalance The balance of the user
   */
  function validateSetUseReserveAsCollateral(
    DataTypes.ReserveCache memory reserveCache,
    uint256 userBalance
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011d0000, 1037618708765) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011d0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011d1000, reserveCache) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011d1001, userBalance) }
    require(userBalance != 0, Errors.UNDERLYING_BALANCE_ZERO);

    (bool isActive, , , bool isPaused) = reserveCache.reserveConfiguration.getFlags();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100c6,0)}
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);
  }

  /**
   * @notice Validates a flashloan action.
   * @param reservesData The state of all the reserves
   * @param assets The assets being flash-borrowed
   * @param amounts The amounts for each asset being borrowed
   */
  function validateFlashloan(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    address[] memory assets,
    uint256[] memory amounts
  ) internal view {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01200000, 1037618708768) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01200001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01201000, reservesData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01201001, assets) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01201002, amounts) }
    require(assets.length == amounts.length, Errors.INCONSISTENT_FLASHLOAN_PARAMS);
    for (uint256 i = 0; i < assets.length; i++) {
      for (uint256 j = i + 1; j < assets.length; j++) {
        require(assets[i] != assets[j], Errors.INCONSISTENT_FLASHLOAN_PARAMS);
      }
      validateFlashloanSimple(reservesData[assets[i]], amounts[i]);
    }
  }

  /**
   * @notice Validates a flashloan action.
   * @param reserve The state of the reserve
   */
  function validateFlashloanSimple(
    DataTypes.ReserveData storage reserve,
    uint256 amount
  ) internal view {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01210000, 1037618708769) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01210001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01211000, reserve.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01211001, amount) }
    DataTypes.ReserveConfigurationMap memory configuration = reserve.configuration;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100c7,0)}
    require(!configuration.getPaused(), Errors.RESERVE_PAUSED);
    require(configuration.getActive(), Errors.RESERVE_INACTIVE);
    require(configuration.getFlashLoanEnabled(), Errors.FLASHLOAN_DISABLED);
    require(
      !configuration.getIsVirtualAccActive() ||
        IERC20(reserve.aTokenAddress).totalSupply() >= amount,
      Errors.INVALID_AMOUNT
    );
  }

  struct ValidateLiquidationCallLocalVars {
    bool collateralReserveActive;
    bool collateralReservePaused;
    bool principalReserveActive;
    bool principalReservePaused;
    bool isCollateralEnabled;
  }

  /**
   * @notice Validates the liquidation action.
   * @param userConfig The user configuration mapping
   * @param collateralReserve The reserve data of the collateral
   * @param debtReserve The reserve data of the debt
   * @param params Additional parameters needed for the validation
   */
  function validateLiquidationCall(
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ReserveData storage collateralReserve,
    DataTypes.ReserveData storage debtReserve,
    DataTypes.ValidateLiquidationCallParams memory params
  ) internal view {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01220000, 1037618708770) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01220001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01221000, userConfig.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01221001, collateralReserve.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01221002, debtReserve.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01221003, params) }
    ValidateLiquidationCallLocalVars memory vars;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100c8,0)}

    (vars.collateralReserveActive, , , vars.collateralReservePaused) = collateralReserve
      .configuration
      .getFlags();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000200d4,0)}

    (vars.principalReserveActive, , , vars.principalReservePaused) = params
      .debtReserveCache
      .reserveConfiguration
      .getFlags();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000200d5,0)}

    require(vars.collateralReserveActive && vars.principalReserveActive, Errors.RESERVE_INACTIVE);
    require(!vars.collateralReservePaused && !vars.principalReservePaused, Errors.RESERVE_PAUSED);

    require(
      params.priceOracleSentinel == address(0) ||
        params.healthFactor < MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD ||
        IPriceOracleSentinel(params.priceOracleSentinel).isLiquidationAllowed(),
      Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
    );

    require(
      collateralReserve.liquidationGracePeriodUntil < uint40(block.timestamp) &&
        debtReserve.liquidationGracePeriodUntil < uint40(block.timestamp),
      Errors.LIQUIDATION_GRACE_SENTINEL_CHECK_FAILED
    );

    require(
      params.healthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.HEALTH_FACTOR_NOT_BELOW_THRESHOLD
    );

    vars.isCollateralEnabled =
      collateralReserve.configuration.getLiquidationThreshold() != 0 &&
      userConfig.isUsingAsCollateral(collateralReserve.id);bool certora_local214 = vars.isCollateralEnabled;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000d6,certora_local214)}

    //if collateral isn't enabled as collateral by user, it cannot be liquidated
    require(vars.isCollateralEnabled, Errors.COLLATERAL_CANNOT_BE_LIQUIDATED);
    require(params.totalDebt != 0, Errors.SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER);
  }

  /**
   * @notice Validates the health factor of a user.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param userConfig The state of the user for the specific reserve
   * @param user The user to validate health factor of
   * @param userEModeCategory The users active efficiency mode category
   * @param reservesCount The number of available reserves
   * @param oracle The price oracle
   */
  function validateHealthFactor(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap memory userConfig,
    address user,
    uint8 userEModeCategory,
    uint256 reservesCount,
    address oracle
  ) internal view returns (uint256, bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01230000, 1037618708771) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01230001, 8) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01231000, reservesData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01231001, reservesList.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01231002, eModeCategories.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01231003, userConfig) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01231004, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01231005, userEModeCategory) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01231006, reservesCount) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01231007, oracle) }
    (, , , , uint256 healthFactor, bool hasZeroLtvCollateral) = GenericLogic
      .calculateUserAccountData(
        reservesData,
        reservesList,
        eModeCategories,
        DataTypes.CalculateUserAccountDataParams({
          userConfig: userConfig,
          reservesCount: reservesCount,
          user: user,
          oracle: oracle,
          userEModeCategory: userEModeCategory
        })
      );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100c9,0)}

    require(
      healthFactor >= HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
    );

    return (healthFactor, hasZeroLtvCollateral);
  }

  /**
   * @notice Validates the health factor of a user and the ltv of the asset being withdrawn.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param userConfig The state of the user for the specific reserve
   * @param asset The asset for which the ltv will be validated
   * @param from The user from which the aTokens are being transferred
   * @param reservesCount The number of available reserves
   * @param oracle The price oracle
   * @param userEModeCategory The users active efficiency mode category
   */
  function validateHFAndLtv(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap memory userConfig,
    address asset,
    address from,
    uint256 reservesCount,
    address oracle,
    uint8 userEModeCategory
  ) internal view {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01240000, 1037618708772) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01240001, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01241000, reservesData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01241001, reservesList.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01241002, eModeCategories.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01241003, userConfig) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01241004, asset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01241005, from) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01241006, reservesCount) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01241007, oracle) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01241008, userEModeCategory) }
    DataTypes.ReserveData memory reserve = reservesData[asset];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100ca,0)}

    (, bool hasZeroLtvCollateral) = validateHealthFactor(
      reservesData,
      reservesList,
      eModeCategories,
      userConfig,
      from,
      userEModeCategory,
      reservesCount,
      oracle
    );assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100cb,0)}

    require(
      !hasZeroLtvCollateral || reserve.configuration.getLtv() == 0,
      Errors.LTV_VALIDATION_FAILED
    );
  }

  /**
   * @notice Validates a transfer action.
   * @param reserve The reserve object
   */
  function validateTransfer(DataTypes.ReserveData storage reserve) internal view {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01250000, 1037618708773) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01250001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01251000, reserve.slot) }
    require(!reserve.configuration.getPaused(), Errors.RESERVE_PAUSED);
  }

  /**
   * @notice Validates a drop reserve action.
   * @param reservesList The addresses of all the active reserves
   * @param reserve The reserve object
   * @param asset The address of the reserve's underlying asset
   */
  function validateDropReserve(
    mapping(uint256 => address) storage reservesList,
    DataTypes.ReserveData storage reserve,
    address asset
  ) internal view {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01260000, 1037618708774) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01260001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01261000, reservesList.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01261001, reserve.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01261002, asset) }
    require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
    require(reserve.id != 0 || reservesList[0] == asset, Errors.ASSET_NOT_LISTED);
    require(
      IERC20(reserve.variableDebtTokenAddress).totalSupply() == 0,
      Errors.VARIABLE_DEBT_SUPPLY_NOT_ZERO
    );
    require(
      IERC20(reserve.aTokenAddress).totalSupply() == 0 && reserve.accruedToTreasury == 0,
      Errors.UNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO
    );
  }

  /**
   * @notice Validates the action of setting efficiency mode.
   * @param eModeCategories a mapping storing configurations for all efficiency mode categories
   * @param userConfig the user configuration
   * @param reservesCount The total number of valid reserves
   * @param categoryId The id of the category
   */
  function validateSetUserEMode(
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap memory userConfig,
    uint256 reservesCount,
    uint8 categoryId
  ) internal view {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01270000, 1037618708775) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01270001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01271000, eModeCategories.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01271001, userConfig) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01271002, reservesCount) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01271003, categoryId) }
    DataTypes.EModeCategory storage eModeCategory = eModeCategories[categoryId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100cc,0)}
    // category is invalid if the liq threshold is not set
    require(
      categoryId == 0 || eModeCategory.liquidationThreshold != 0,
      Errors.INCONSISTENT_EMODE_CATEGORY
    );

    // eMode can always be enabled if the user hasn't supplied anything
    if (userConfig.isEmpty()) {
      return;
    }

    // if user is trying to set another category than default we require that
    // either the user is not borrowing, or it's borrowing assets of categoryId
    if (categoryId != 0) {
      unchecked {
        for (uint256 i = 0; i < reservesCount; i++) {
          if (userConfig.isBorrowing(i)) {
            require(
              EModeConfiguration.isReserveEnabledOnBitmap(eModeCategory.borrowableBitmap, i),
              Errors.NOT_BORROWABLE_IN_EMODE
            );
          }
        }
      }
    }
  }

  /**
   * @notice Validates the action of activating the asset as collateral.
   * @dev Only possible if the asset has non-zero LTV and the user is not in isolation mode
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig the user configuration
   * @param reserveConfig The reserve configuration
   * @return True if the asset can be activated as collateral, false otherwise
   */
  function validateUseAsCollateral(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ReserveConfigurationMap memory reserveConfig
  ) internal view returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01280000, 1037618708776) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01280001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01281000, reservesData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01281001, reservesList.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01281002, userConfig.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01281003, reserveConfig) }
    if (reserveConfig.getLtv() == 0) {
      return false;
    }
    if (!userConfig.isUsingAsCollateralAny()) {
      return true;
    }
    (bool isolationModeActive, , ) = userConfig.getIsolationModeState(reservesData, reservesList);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100cd,0)}

    return (!isolationModeActive && reserveConfig.getDebtCeiling() == 0);
  }

  /**
   * @notice Validates if an asset should be automatically activated as collateral in the following actions: supply,
   * transfer, mint unbacked, and liquidate
   * @dev This is used to ensure that isolated assets are not enabled as collateral automatically
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig the user configuration
   * @param reserveConfig The reserve configuration
   * @return True if the asset can be activated as collateral, false otherwise
   */
  function validateAutomaticUseAsCollateral(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ReserveConfigurationMap memory reserveConfig,
    address aTokenAddress
  ) internal view returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01290000, 1037618708777) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01290001, 5) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01291000, reservesData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01291001, reservesList.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01291002, userConfig.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01291003, reserveConfig) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01291004, aTokenAddress) }
    if (reserveConfig.getDebtCeiling() != 0) {
      // ensures only the ISOLATED_COLLATERAL_SUPPLIER_ROLE can enable collateral as side-effect of an action
      IPoolAddressesProvider addressesProvider = IncentivizedERC20(aTokenAddress)
        .POOL()
        .ADDRESSES_PROVIDER();
      if (
        !IAccessControl(addressesProvider.getACLManager()).hasRole(
          ISOLATED_COLLATERAL_SUPPLIER_ROLE,
          msg.sender
        )
      ) return false;
    }
    return validateUseAsCollateral(reservesData, reservesList, userConfig, reserveConfig);
  }
}
