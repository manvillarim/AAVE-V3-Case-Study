// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title CalldataLogic library
 * @author Aave
 * @notice Library to decode calldata, used to optimize calldata size in L2Pool for transaction cost reduction
 */
library CalldataLogic {
  /**
   * @notice Decodes compressed supply params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed supply params
   * @return addr The address of the underlying reserve
   * @return amount The amount to supply
   * @return referralCode The referralCode
   */
  function decodeSupplyParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address addr, uint256 amount, uint16 referralCode) {
    uint16 assetId;

    assembly {
      assetId := and(args, 0xFFFF)
      amount := and(shr(16, args), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      referralCode := and(shr(144, args), 0xFFFF)
    }

    addr = reservesList[assetId];
  }

  /**
   * @notice Decodes compressed supply params to standard params along with permit params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed supply with permit params
   * @return asset The address of the underlying reserve
   * @return amount The amount to supply
   * @return referralCode The referralCode
   * @return deadline The deadline of the permit
   * @return permitV The V value of the permit signature
   */
  function decodeSupplyWithPermitParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address asset, uint256 amount, uint16 referralCode, uint256 deadline, uint8 permitV) {
    assembly {
      deadline := and(shr(160, args), 0xFFFFFFFF)
      permitV := and(shr(192, args), 0xFF)
    }
    (asset, amount, referralCode) = decodeSupplyParams(reservesList, args);
  }

  /**
   * @notice Decodes compressed withdraw params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed withdraw params
   * @return addr The address of the underlying reserve
   * @return amount The amount to withdraw
   */
  function decodeWithdrawParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address addr, uint256 amount) {
    uint16 assetId;
    assembly {
      assetId := and(args, 0xFFFF)
      amount := and(shr(16, args), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
    }
    if (amount == type(uint128).max) {
      amount = type(uint256).max;
    }
    addr = reservesList[assetId];
  }

  /**
   * @notice Decodes compressed borrow params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed borrow params
   * @return addr The address of the underlying reserve
   * @return amount The amount to borrow
   * @return interestRateMode The interestRateMode, 2 for variable debt, 1 is deprecated (changed on v3.2.0)
   * @return referralCode The referralCode
   */
  function decodeBorrowParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address addr, uint256 amount, uint256 interestRateMode, uint16 referralCode) {
    uint16 assetId;

    assembly {
      assetId := and(args, 0xFFFF)
      amount := and(shr(16, args), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      interestRateMode := and(shr(144, args), 0xFF)
      referralCode := and(shr(152, args), 0xFFFF)
    }

    addr = reservesList[assetId];
  }

  /**
   * @notice Decodes compressed repay params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed repay params
   * @return addr The address of the underlying reserve
   * @return amount The amount to repay
   * @return interestRateMode The interestRateMode, 2 for variable debt, 1 is deprecated (changed on v3.2.0)
   */
  function decodeRepayParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address addr, uint256 amount, uint256 interestRateMode) {
    uint16 assetId;

    assembly {
      assetId := and(args, 0xFFFF)
      amount := and(shr(16, args), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      interestRateMode := and(shr(144, args), 0xFF)
    }

    if (amount == type(uint128).max) {
      amount = type(uint256).max;
    }

    addr = reservesList[assetId];
  }

  /**
   * @notice Decodes compressed repay params to standard params along with permit params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed repay with permit params
   * @return asset The address of the underlying reserve
   * @return amount The amount to repay
   * @return interestRateMode The interestRateMode, 2 for variable debt, 1 is deprecated (changed on v3.2.0)
   * @return deadline The deadline of the permit
   * @return permitV The V value of the permit signature
   */
  function decodeRepayWithPermitParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address asset, uint256 amount, uint256 interestRateMode, uint256 deadline, uint8 permitV) {
    (asset, amount, interestRateMode) = decodeRepayParams(
      reservesList,
      args
    );

    assembly {
      deadline := and(shr(152, args), 0xFFFFFFFF)
      permitV := and(shr(184, args), 0xFF)
    }
  }

  /**
   * @notice Decodes compressed set user use reserve as collateral params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed set user use reserve as collateral params
   * @return addr The address of the underlying reserve
   * @return useAsCollateral True if to set using as collateral, false otherwise
   */
  function decodeSetUserUseReserveAsCollateralParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address addr, bool useAsCollateral) {
    uint16 assetId;
    assembly {
      assetId := and(args, 0xFFFF)
      useAsCollateral := and(shr(16, args), 0x1)
    }

    addr = reservesList[assetId];
  }

  /**
   * @notice Decodes compressed liquidation call params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args1 The first half of packed liquidation call params
   * @param args2 The second half of the packed liquidation call params
   * @return colAddr The address of the underlying collateral asset
   * @return debtAddr The address of the underlying debt asset
   * @return user The address of the user to liquidate
   * @return debtToCover The amount of debt to cover
   * @return receiveAToken True if receiving aTokens, false otherwise
   */
  function decodeLiquidationCallParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args1,
    bytes32 args2
  ) internal view returns (address colAddr, address debtAddr, address user, uint256 debtToCover, bool receiveAToken) {
    uint16 collateralAssetId;
    uint16 debtAssetId;

    assembly {
      collateralAssetId := and(args1, 0xFFFF)
      debtAssetId := and(shr(16, args1), 0xFFFF)
      user := and(shr(32, args1), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

      debtToCover := and(args2, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      receiveAToken := and(shr(128, args2), 0x1)
    }

    if (debtToCover == type(uint128).max) {
      debtToCover = type(uint256).max;
    }

    colAddr = reservesList[collateralAssetId];
    debtAddr = reservesList[debtAssetId];
  }
}
