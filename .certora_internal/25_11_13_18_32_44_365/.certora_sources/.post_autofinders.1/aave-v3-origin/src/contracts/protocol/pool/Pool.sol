// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {VersionedInitializable} from '../../misc/aave-upgradeability/VersionedInitializable.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {ReserveConfiguration} from '../libraries/configuration/ReserveConfiguration.sol';
import {PoolLogic} from '../libraries/logic/PoolLogic.sol';
import {ReserveLogic} from '../libraries/logic/ReserveLogic.sol';
import {EModeLogic} from '../libraries/logic/EModeLogic.sol';
import {SupplyLogic} from '../libraries/logic/SupplyLogic.sol';
import {FlashLoanLogic} from '../libraries/logic/FlashLoanLogic.sol';
import {BorrowLogic} from '../libraries/logic/BorrowLogic.sol';
import {LiquidationLogic} from '../libraries/logic/LiquidationLogic.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import {BridgeLogic} from '../libraries/logic/BridgeLogic.sol';
import {IERC20WithPermit} from '../../interfaces/IERC20WithPermit.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IPool} from '../../interfaces/IPool.sol';
import {IACLManager} from '../../interfaces/IACLManager.sol';
import {PoolStorage} from './PoolStorage.sol';

/**
 * @title Pool contract
 * @author Aave
 * @notice Main point of interaction with an Aave protocol's market
 * - Users can:
 *   # Supply
 *   # Withdraw
 *   # Borrow
 *   # Repay
 *   # Enable/disable their supplied assets as collateral
 *   # Liquidate positions
 *   # Execute Flash Loans
 * @dev To be covered by a proxy contract, owned by the PoolAddressesProvider of the specific market
 * @dev All admin functions are callable by the PoolConfigurator contract defined also in the
 *   PoolAddressesProvider
 */
abstract contract Pool is VersionedInitializable, PoolStorage, IPool {
  using ReserveLogic for DataTypes.ReserveData;

  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  // @notice The name used to fetch the UMBRELLA contract
  bytes32 public constant UMBRELLA = 'UMBRELLA';

  /**
   * @dev Only pool configurator can call functions marked by this modifier.
   */
  modifier onlyPoolConfigurator() {
    _onlyPoolConfigurator();
    _;
  }

  /**
   * @dev Only pool admin can call functions marked by this modifier.
   */
  modifier onlyPoolAdmin() {
    _onlyPoolAdmin();
    _;
  }

  /**
   * @dev Only bridge can call functions marked by this modifier.
   */
  modifier onlyBridge() {
    _onlyBridge();
    _;
  }

  /**
   * @dev Only the umbrella contract can call functions marked by this modifier.
   */
  modifier onlyUmbrella() {
    require(ADDRESSES_PROVIDER.getAddress(UMBRELLA) == msg.sender, Errors.CALLER_NOT_UMBRELLA);
    _;
  }

  function _onlyPoolConfigurator() internal view virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01350000, 1037618708789) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01350001, 0) }
    require(
      ADDRESSES_PROVIDER.getPoolConfigurator() == msg.sender,
      Errors.CALLER_NOT_POOL_CONFIGURATOR
    );
  }

  function _onlyPoolAdmin() internal view virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01360000, 1037618708790) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01360001, 0) }
    require(
      IACLManager(ADDRESSES_PROVIDER.getACLManager()).isPoolAdmin(msg.sender),
      Errors.CALLER_NOT_POOL_ADMIN
    );
  }

  function _onlyBridge() internal view virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01370000, 1037618708791) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01370001, 0) }
    require(
      IACLManager(ADDRESSES_PROVIDER.getACLManager()).isBridge(msg.sender),
      Errors.CALLER_NOT_BRIDGE
    );
  }

  /**
   * @dev Constructor.
   * @param provider The address of the PoolAddressesProvider contract
   */
  constructor(IPoolAddressesProvider provider) {
    ADDRESSES_PROVIDER = provider;
  }

  /**
   * @notice Initializes the Pool.
   * @dev Function is invoked by the proxy contract when the Pool contract is added to the
   * PoolAddressesProvider of the market.
   * @dev Caching the address of the PoolAddressesProvider in order to reduce gas consumption on subsequent operations
   * @param provider The address of the PoolAddressesProvider
   */
  function initialize(IPoolAddressesProvider provider) external virtual;

  /// @inheritdoc IPool
  function mintUnbacked(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external virtual override onlyBridge {
    BridgeLogic.executeMintUnbacked(
      _reserves,
      _reservesList,
      _usersConfig[onBehalfOf],
      asset,
      amount,
      onBehalfOf,
      referralCode
    );
  }

  /// @inheritdoc IPool
  function backUnbacked(
    address asset,
    uint256 amount,
    uint256 fee
  ) external virtual override onlyBridge returns (uint256) {
    return
      BridgeLogic.executeBackUnbacked(_reserves[asset], asset, amount, fee, _bridgeProtocolFee);
  }

  /// @inheritdoc IPool
  function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) public virtual override {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ae0000, 1037618708654) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ae0001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ae1000, asset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ae1001, amount) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ae1002, onBehalfOf) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ae1003, referralCode) }
    SupplyLogic.executeSupply(
      _reserves,
      _reservesList,
      _usersConfig[onBehalfOf],
      DataTypes.ExecuteSupplyParams({
        asset: asset,
        amount: amount,
        onBehalfOf: onBehalfOf,
        referralCode: referralCode
      })
    );
  }

  /// @inheritdoc IPool
  function supplyWithPermit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) public virtual override {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ab0000, 1037618708651) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ab0001, 8) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ab1000, asset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ab1001, amount) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ab1002, onBehalfOf) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ab1003, referralCode) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ab1004, deadline) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ab1005, permitV) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ab1006, permitR) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ab1007, permitS) }
    try
      IERC20WithPermit(asset).permit(
        msg.sender,
        address(this),
        amount,
        deadline,
        permitV,
        permitR,
        permitS
      )
    {} catch {}
    SupplyLogic.executeSupply(
      _reserves,
      _reservesList,
      _usersConfig[onBehalfOf],
      DataTypes.ExecuteSupplyParams({
        asset: asset,
        amount: amount,
        onBehalfOf: onBehalfOf,
        referralCode: referralCode
      })
    );
  }

  /// @inheritdoc IPool
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) public virtual override returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a90000, 1037618708649) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a90001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a91000, asset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a91001, amount) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a91002, to) }
    return
      SupplyLogic.executeWithdraw(
        _reserves,
        _reservesList,
        _eModeCategories,
        _usersConfig[msg.sender],
        DataTypes.ExecuteWithdrawParams({
          asset: asset,
          amount: amount,
          to: to,
          reservesCount: _reservesCount,
          oracle: ADDRESSES_PROVIDER.getPriceOracle(),
          userEModeCategory: _usersEModeCategory[msg.sender]
        })
      );
  }

  /// @inheritdoc IPool
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) public virtual override {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00aa0000, 1037618708650) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00aa0001, 5) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00aa1000, asset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00aa1001, amount) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00aa1002, interestRateMode) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00aa1003, referralCode) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00aa1004, onBehalfOf) }
    BorrowLogic.executeBorrow(
      _reserves,
      _reservesList,
      _eModeCategories,
      _usersConfig[onBehalfOf],
      DataTypes.ExecuteBorrowParams({
        asset: asset,
        user: msg.sender,
        onBehalfOf: onBehalfOf,
        amount: amount,
        interestRateMode: DataTypes.InterestRateMode(interestRateMode),
        referralCode: referralCode,
        releaseUnderlying: true,
        reservesCount: _reservesCount,
        oracle: ADDRESSES_PROVIDER.getPriceOracle(),
        userEModeCategory: _usersEModeCategory[onBehalfOf],
        priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel()
      })
    );
  }

  /// @inheritdoc IPool
  function repay(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf
  ) public virtual override returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a20000, 1037618708642) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a20001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a21000, asset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a21001, amount) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a21002, interestRateMode) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a21003, onBehalfOf) }
    return
      BorrowLogic.executeRepay(
        _reserves,
        _reservesList,
        _usersConfig[onBehalfOf],
        DataTypes.ExecuteRepayParams({
          asset: asset,
          amount: amount,
          interestRateMode: DataTypes.InterestRateMode(interestRateMode),
          onBehalfOf: onBehalfOf,
          useATokens: false
        })
      );
  }

  /// @inheritdoc IPool
  function repayWithPermit(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) public virtual override returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a40000, 1037618708644) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a40001, 8) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a41000, asset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a41001, amount) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a41002, interestRateMode) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a41003, onBehalfOf) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a41004, deadline) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a41005, permitV) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a41006, permitR) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a41007, permitS) }
    try
      IERC20WithPermit(asset).permit(
        msg.sender,
        address(this),
        amount,
        deadline,
        permitV,
        permitR,
        permitS
      )
    {} catch {}

    {
      DataTypes.ExecuteRepayParams memory params = DataTypes.ExecuteRepayParams({
        asset: asset,
        amount: amount,
        interestRateMode: DataTypes.InterestRateMode(interestRateMode),
        onBehalfOf: onBehalfOf,
        useATokens: false
      });
      return BorrowLogic.executeRepay(_reserves, _reservesList, _usersConfig[onBehalfOf], params);
    }
  }

  /// @inheritdoc IPool
  function repayWithATokens(
    address asset,
    uint256 amount,
    uint256 interestRateMode
  ) public virtual override returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a60000, 1037618708646) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a60001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a61000, asset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a61001, amount) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a61002, interestRateMode) }
    return
      BorrowLogic.executeRepay(
        _reserves,
        _reservesList,
        _usersConfig[msg.sender],
        DataTypes.ExecuteRepayParams({
          asset: asset,
          amount: amount,
          interestRateMode: DataTypes.InterestRateMode(interestRateMode),
          onBehalfOf: msg.sender,
          useATokens: true
        })
      );
  }

  /// @inheritdoc IPool
  function setUserUseReserveAsCollateral(
    address asset,
    bool useAsCollateral
  ) public virtual override {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00af0000, 1037618708655) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00af0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00af1000, asset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00af1001, useAsCollateral) }
    SupplyLogic.executeUseReserveAsCollateral(
      _reserves,
      _reservesList,
      _eModeCategories,
      _usersConfig[msg.sender],
      asset,
      useAsCollateral,
      _reservesCount,
      ADDRESSES_PROVIDER.getPriceOracle(),
      _usersEModeCategory[msg.sender]
    );
  }

  /// @inheritdoc IPool
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) public virtual override {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a80000, 1037618708648) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a80001, 5) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a81000, collateralAsset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a81001, debtAsset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a81002, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a81003, debtToCover) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a81004, receiveAToken) }
    LiquidationLogic.executeLiquidationCall(
      _reserves,
      _reservesList,
      _usersConfig,
      _eModeCategories,
      DataTypes.ExecuteLiquidationCallParams({
        reservesCount: _reservesCount,
        debtToCover: debtToCover,
        collateralAsset: collateralAsset,
        debtAsset: debtAsset,
        user: user,
        receiveAToken: receiveAToken,
        priceOracle: ADDRESSES_PROVIDER.getPriceOracle(),
        userEModeCategory: _usersEModeCategory[user],
        priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel()
      })
    );
  }

  /// @inheritdoc IPool
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata interestRateModes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) public virtual override {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a70000, 1037618708647) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a70001, 11) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a71000, receiverAddress) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a73001, assets.offset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a72001, assets.length) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a73002, amounts.offset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a72002, amounts.length) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a73003, interestRateModes.offset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a72003, interestRateModes.length) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a71004, onBehalfOf) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a73005, params.offset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a72005, params.length) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a71006, referralCode) }
    DataTypes.FlashloanParams memory flashParams = DataTypes.FlashloanParams({
      receiverAddress: receiverAddress,
      assets: assets,
      amounts: amounts,
      interestRateModes: interestRateModes,
      onBehalfOf: onBehalfOf,
      params: params,
      referralCode: referralCode,
      flashLoanPremiumToProtocol: _flashLoanPremiumToProtocol,
      flashLoanPremiumTotal: _flashLoanPremiumTotal,
      reservesCount: _reservesCount,
      addressesProvider: address(ADDRESSES_PROVIDER),
      pool: address(this),
      userEModeCategory: _usersEModeCategory[onBehalfOf],
      isAuthorizedFlashBorrower: IACLManager(ADDRESSES_PROVIDER.getACLManager()).isFlashBorrower(
        msg.sender
      )
    });assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100df,0)}

    FlashLoanLogic.executeFlashLoan(
      _reserves,
      _reservesList,
      _eModeCategories,
      _usersConfig[onBehalfOf],
      flashParams
    );
  }

  /// @inheritdoc IPool
  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  ) public virtual override {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b00000, 1037618708656) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b00001, 6) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b01000, receiverAddress) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b01001, asset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b01002, amount) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b03003, params.offset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b02003, params.length) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b01004, referralCode) }
    DataTypes.FlashloanSimpleParams memory flashParams = DataTypes.FlashloanSimpleParams({
      receiverAddress: receiverAddress,
      asset: asset,
      amount: amount,
      params: params,
      referralCode: referralCode,
      flashLoanPremiumToProtocol: _flashLoanPremiumToProtocol,
      flashLoanPremiumTotal: _flashLoanPremiumTotal
    });assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100e0,0)}
    FlashLoanLogic.executeFlashLoanSimple(_reserves[asset], flashParams);
  }

  /// @inheritdoc IPool
  function mintToTreasury(address[] calldata assets) external virtual override {
    PoolLogic.executeMintToTreasury(_reserves, assets);
  }

  /// @inheritdoc IPool
  function getReserveData(
    address asset
  ) external view virtual override returns (DataTypes.ReserveDataLegacy memory) {
    DataTypes.ReserveData storage reserve = _reserves[asset];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100e1,0)}
    DataTypes.ReserveDataLegacy memory res;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100e2,0)}

    res.configuration = reserve.configuration;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000200eb,0)}
    res.liquidityIndex = reserve.liquidityIndex;uint128 certora_local236 = res.liquidityIndex;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000ec,certora_local236)}
    res.currentLiquidityRate = reserve.currentLiquidityRate;uint128 certora_local237 = res.currentLiquidityRate;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000ed,certora_local237)}
    res.variableBorrowIndex = reserve.variableBorrowIndex;uint128 certora_local238 = res.variableBorrowIndex;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000ee,certora_local238)}
    res.currentVariableBorrowRate = reserve.currentVariableBorrowRate;uint128 certora_local239 = res.currentVariableBorrowRate;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000ef,certora_local239)}
    res.lastUpdateTimestamp = reserve.lastUpdateTimestamp;uint40 certora_local240 = res.lastUpdateTimestamp;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000f0,certora_local240)}
    res.id = reserve.id;uint16 certora_local241 = res.id;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000f1,certora_local241)}
    res.aTokenAddress = reserve.aTokenAddress;address certora_local242 = res.aTokenAddress;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000f2,certora_local242)}
    res.variableDebtTokenAddress = reserve.variableDebtTokenAddress;address certora_local243 = res.variableDebtTokenAddress;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000f3,certora_local243)}
    res.interestRateStrategyAddress = reserve.interestRateStrategyAddress;address certora_local244 = res.interestRateStrategyAddress;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000f4,certora_local244)}
    res.accruedToTreasury = reserve.accruedToTreasury;uint128 certora_local245 = res.accruedToTreasury;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000f5,certora_local245)}
    res.unbacked = reserve.unbacked;uint128 certora_local246 = res.unbacked;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000f6,certora_local246)}
    res.isolationModeTotalDebt = reserve.isolationModeTotalDebt;uint128 certora_local247 = res.isolationModeTotalDebt;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000f7,certora_local247)}
    // This is a temporary workaround for integrations that are broken by Aave 3.2
    // While the new pool data provider is backward compatible, some integrations hard-code an old implementation
    // To allow them to not have any infrastructural blocker, a mock must be configured in the Aave Pool Addresses Provider, returning zero on all required view methods, instead of reverting
    res.stableDebtTokenAddress = ADDRESSES_PROVIDER.getAddress(bytes32('MOCK_STABLE_DEBT'));address certora_local248 = res.stableDebtTokenAddress;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000f8,certora_local248)}
    return res;
  }

  /// @inheritdoc IPool
  function getVirtualUnderlyingBalance(
    address asset
  ) external view virtual override returns (uint128) {
    return _reserves[asset].virtualUnderlyingBalance;
  }

  /// @inheritdoc IPool
  function getUserAccountData(
    address user
  )
    external
    view
    virtual
    override
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    )
  {
    return
      PoolLogic.executeGetUserAccountData(
        _reserves,
        _reservesList,
        _eModeCategories,
        DataTypes.CalculateUserAccountDataParams({
          userConfig: _usersConfig[user],
          reservesCount: _reservesCount,
          user: user,
          oracle: ADDRESSES_PROVIDER.getPriceOracle(),
          userEModeCategory: _usersEModeCategory[user]
        })
      );
  }

  /// @inheritdoc IPool
  function getConfiguration(
    address asset
  ) external view virtual override returns (DataTypes.ReserveConfigurationMap memory) {
    return _reserves[asset].configuration;
  }

  /// @inheritdoc IPool
  function getUserConfiguration(
    address user
  ) external view virtual override returns (DataTypes.UserConfigurationMap memory) {
    return _usersConfig[user];
  }

  /// @inheritdoc IPool
  function getReserveNormalizedIncome(
    address asset
  ) external view virtual override returns (uint256) {
    return _reserves[asset].getNormalizedIncome();
  }

  /// @inheritdoc IPool
  function getReserveNormalizedVariableDebt(
    address asset
  ) external view virtual override returns (uint256) {
    return _reserves[asset].getNormalizedDebt();
  }

  /// @inheritdoc IPool
  function getReservesList() external view virtual override returns (address[] memory) {
    uint256 reservesListCount = _reservesCount;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000e3,reservesListCount)}
    uint256 droppedReservesCount = 0;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000e4,droppedReservesCount)}
    address[] memory reservesList = new address[](reservesListCount);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100e5,0)}

    for (uint256 i = 0; i < reservesListCount; i++) {
      if (_reservesList[i] != address(0)) {
        reservesList[i - droppedReservesCount] = _reservesList[i];
      } else {
        droppedReservesCount++;
      }
    }

    // Reduces the length of the reserves array by `droppedReservesCount`
    assembly {
      mstore(reservesList, sub(reservesListCount, droppedReservesCount))
    }
    return reservesList;
  }

  /// @inheritdoc IPool
  function getReservesCount() external view virtual override returns (uint256) {
    return _reservesCount;
  }

  /// @inheritdoc IPool
  function getReserveAddressById(uint16 id) external view returns (address) {
    return _reservesList[id];
  }

  /// @inheritdoc IPool
  function BRIDGE_PROTOCOL_FEE() public view virtual override returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ac0000, 1037618708652) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ac0001, 0) }
    return _bridgeProtocolFee;
  }

  /// @inheritdoc IPool
  function FLASHLOAN_PREMIUM_TOTAL() public view virtual override returns (uint128) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a30000, 1037618708643) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a30001, 0) }
    return _flashLoanPremiumTotal;
  }

  /// @inheritdoc IPool
  function FLASHLOAN_PREMIUM_TO_PROTOCOL() public view virtual override returns (uint128) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ad0000, 1037618708653) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ad0001, 0) }
    return _flashLoanPremiumToProtocol;
  }

  /// @inheritdoc IPool
  function MAX_NUMBER_RESERVES() public view virtual override returns (uint16) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a50000, 1037618708645) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a50001, 0) }
    return ReserveConfiguration.MAX_RESERVES_COUNT;
  }

  /// @inheritdoc IPool
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external virtual override {
    require(msg.sender == _reserves[asset].aTokenAddress, Errors.CALLER_NOT_ATOKEN);
    SupplyLogic.executeFinalizeTransfer(
      _reserves,
      _reservesList,
      _eModeCategories,
      _usersConfig,
      DataTypes.FinalizeTransferParams({
        asset: asset,
        from: from,
        to: to,
        amount: amount,
        balanceFromBefore: balanceFromBefore,
        balanceToBefore: balanceToBefore,
        reservesCount: _reservesCount,
        oracle: ADDRESSES_PROVIDER.getPriceOracle(),
        fromEModeCategory: _usersEModeCategory[from]
      })
    );
  }

  /// @inheritdoc IPool
  function initReserve(
    address asset,
    address aTokenAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external virtual override onlyPoolConfigurator {
    if (
      PoolLogic.executeInitReserve(
        _reserves,
        _reservesList,
        DataTypes.InitReserveParams({
          asset: asset,
          aTokenAddress: aTokenAddress,
          variableDebtAddress: variableDebtAddress,
          interestRateStrategyAddress: interestRateStrategyAddress,
          reservesCount: _reservesCount,
          maxNumberReserves: MAX_NUMBER_RESERVES()
        })
      )
    ) {
      _reservesCount++;
    }
  }

  /// @inheritdoc IPool
  function dropReserve(address asset) external virtual override onlyPoolConfigurator {
    PoolLogic.executeDropReserve(_reserves, _reservesList, asset);
  }

  /// @inheritdoc IPool
  function setReserveInterestRateStrategyAddress(
    address asset,
    address rateStrategyAddress
  ) external virtual override onlyPoolConfigurator {
    require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
    require(_reserves[asset].id != 0 || _reservesList[0] == asset, Errors.ASSET_NOT_LISTED);

    _reserves[asset].interestRateStrategyAddress = rateStrategyAddress;
  }

  /// @inheritdoc IPool
  function syncIndexesState(address asset) external virtual override onlyPoolConfigurator {
    DataTypes.ReserveData storage reserve = _reserves[asset];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100e6,0)}
    DataTypes.ReserveCache memory reserveCache = reserve.cache();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100e7,0)}

    reserve.updateState(reserveCache);
  }

  /// @inheritdoc IPool
  function syncRatesState(address asset) external virtual override onlyPoolConfigurator {
    DataTypes.ReserveData storage reserve = _reserves[asset];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100e8,0)}
    DataTypes.ReserveCache memory reserveCache = reserve.cache();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100e9,0)}

    ReserveLogic.updateInterestRatesAndVirtualBalance(reserve, reserveCache, asset, 0, 0);
  }

  /// @inheritdoc IPool
  function setConfiguration(
    address asset,
    DataTypes.ReserveConfigurationMap calldata configuration
  ) external virtual override onlyPoolConfigurator {
    require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
    require(_reserves[asset].id != 0 || _reservesList[0] == asset, Errors.ASSET_NOT_LISTED);
    _reserves[asset].configuration = configuration;
  }

  /// @inheritdoc IPool
  function updateBridgeProtocolFee(
    uint256 protocolFee
  ) external virtual override onlyPoolConfigurator {
    _bridgeProtocolFee = protocolFee;
  }

  /// @inheritdoc IPool
  function updateFlashloanPremiums(
    uint128 flashLoanPremiumTotal,
    uint128 flashLoanPremiumToProtocol
  ) external virtual override onlyPoolConfigurator {
    _flashLoanPremiumTotal = flashLoanPremiumTotal;
    _flashLoanPremiumToProtocol = flashLoanPremiumToProtocol;
  }

  /// @inheritdoc IPool
  function configureEModeCategory(
    uint8 id,
    DataTypes.EModeCategoryBaseConfiguration calldata category
  ) external virtual override onlyPoolConfigurator {
    // category 0 is reserved for volatile heterogeneous assets and it's always disabled
    require(id != 0, Errors.EMODE_CATEGORY_RESERVED);
    _eModeCategories[id].ltv = category.ltv;
    _eModeCategories[id].liquidationThreshold = category.liquidationThreshold;
    _eModeCategories[id].liquidationBonus = category.liquidationBonus;
    _eModeCategories[id].label = category.label;
  }

  /// @inheritdoc IPool
  function configureEModeCategoryCollateralBitmap(
    uint8 id,
    uint128 collateralBitmap
  ) external virtual override onlyPoolConfigurator {
    // category 0 is reserved for volatile heterogeneous assets and it's always disabled
    require(id != 0, Errors.EMODE_CATEGORY_RESERVED);
    _eModeCategories[id].collateralBitmap = collateralBitmap;
  }

  /// @inheritdoc IPool
  function configureEModeCategoryBorrowableBitmap(
    uint8 id,
    uint128 borrowableBitmap
  ) external virtual override onlyPoolConfigurator {
    // category 0 is reserved for volatile heterogeneous assets and it's always disabled
    require(id != 0, Errors.EMODE_CATEGORY_RESERVED);
    _eModeCategories[id].borrowableBitmap = borrowableBitmap;
  }

  /// @inheritdoc IPool
  function getEModeCategoryData(
    uint8 id
  ) external view virtual override returns (DataTypes.EModeCategoryLegacy memory) {
    DataTypes.EModeCategory storage category = _eModeCategories[id];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100ea,0)}
    return
      DataTypes.EModeCategoryLegacy({
        ltv: category.ltv,
        liquidationThreshold: category.liquidationThreshold,
        liquidationBonus: category.liquidationBonus,
        priceSource: address(0),
        label: category.label
      });
  }

  /// @inheritdoc IPool
  function getEModeCategoryCollateralConfig(
    uint8 id
  ) external view returns (DataTypes.CollateralConfig memory) {
    return
      DataTypes.CollateralConfig({
        ltv: _eModeCategories[id].ltv,
        liquidationThreshold: _eModeCategories[id].liquidationThreshold,
        liquidationBonus: _eModeCategories[id].liquidationBonus
      });
  }

  /// @inheritdoc IPool
  function getEModeCategoryLabel(uint8 id) external view returns (string memory) {
    return _eModeCategories[id].label;
  }

  /// @inheritdoc IPool
  function getEModeCategoryCollateralBitmap(uint8 id) external view returns (uint128) {
    return _eModeCategories[id].collateralBitmap;
  }

  /// @inheritdoc IPool
  function getEModeCategoryBorrowableBitmap(uint8 id) external view returns (uint128) {
    return _eModeCategories[id].borrowableBitmap;
  }

  /// @inheritdoc IPool
  function setUserEMode(uint8 categoryId) external virtual override {
    EModeLogic.executeSetUserEMode(
      _reserves,
      _reservesList,
      _eModeCategories,
      _usersEModeCategory,
      _usersConfig[msg.sender],
      DataTypes.ExecuteSetUserEModeParams({
        reservesCount: _reservesCount,
        oracle: ADDRESSES_PROVIDER.getPriceOracle(),
        categoryId: categoryId
      })
    );
  }

  /// @inheritdoc IPool
  function getUserEMode(address user) external view virtual override returns (uint256) {
    return _usersEModeCategory[user];
  }

  /// @inheritdoc IPool
  function resetIsolationModeTotalDebt(
    address asset
  ) external virtual override onlyPoolConfigurator {
    PoolLogic.executeResetIsolationModeTotalDebt(_reserves, asset);
  }

  /// @inheritdoc IPool
  function getLiquidationGracePeriod(
    address asset
  ) external view virtual override returns (uint40) {
    return _reserves[asset].liquidationGracePeriodUntil;
  }

  /// @inheritdoc IPool
  function setLiquidationGracePeriod(
    address asset,
    uint40 until
  ) external virtual override onlyPoolConfigurator {
    require(_reserves[asset].id != 0 || _reservesList[0] == asset, Errors.ASSET_NOT_LISTED);
    PoolLogic.executeSetLiquidationGracePeriod(_reserves, asset, until);
  }

  /// @inheritdoc IPool
  function rescueTokens(
    address token,
    address to,
    uint256 amount
  ) external virtual override onlyPoolAdmin {
    PoolLogic.executeRescueTokens(token, to, amount);
  }

  /// @inheritdoc IPool
  /// @dev Deprecated: maintained for compatibility purposes
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external virtual override {
    SupplyLogic.executeSupply(
      _reserves,
      _reservesList,
      _usersConfig[onBehalfOf],
      DataTypes.ExecuteSupplyParams({
        asset: asset,
        amount: amount,
        onBehalfOf: onBehalfOf,
        referralCode: referralCode
      })
    );
  }

  /// @inheritdoc IPool
  function eliminateReserveDeficit(address asset, uint256 amount) external override onlyUmbrella {
    LiquidationLogic.executeEliminateDeficit(
      _reserves,
      _usersConfig[msg.sender],
      DataTypes.ExecuteEliminateDeficitParams({asset: asset, amount: amount})
    );
  }

  /// @inheritdoc IPool
  function getReserveDeficit(address asset) external view virtual returns (uint256) {
    return _reserves[asset].deficit;
  }

  /// @inheritdoc IPool
  function getReserveAToken(address asset) external view virtual returns (address) {
    return _reserves[asset].aTokenAddress;
  }

  /// @inheritdoc IPool
  function getReserveVariableDebtToken(address asset) external view virtual returns (address) {
    return _reserves[asset].variableDebtTokenAddress;
  }

  /// @inheritdoc IPool
  function getFlashLoanLogic() external pure returns (address) {
    return address(FlashLoanLogic);
  }

  /// @inheritdoc IPool
  function getBorrowLogic() external pure returns (address) {
    return address(BorrowLogic);
  }

  /// @inheritdoc IPool
  function getBridgeLogic() external pure returns (address) {
    return address(BridgeLogic);
  }

  /// @inheritdoc IPool
  function getEModeLogic() external pure returns (address) {
    return address(EModeLogic);
  }

  /// @inheritdoc IPool
  function getLiquidationLogic() external pure returns (address) {
    return address(LiquidationLogic);
  }

  /// @inheritdoc IPool
  function getPoolLogic() external pure returns (address) {
    return address(PoolLogic);
  }

  /// @inheritdoc IPool
  function getSupplyLogic() external pure returns (address) {
    return address(SupplyLogic);
  }
}
