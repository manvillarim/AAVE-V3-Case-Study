// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ReserveConfiguration} from './ReserveConfiguration.sol';

/**
 * @title UserConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the user configuration
 */
library UserConfiguration {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  uint256 internal constant BORROWING_MASK =
    0x5555555555555555555555555555555555555555555555555555555555555555;
  uint256 internal constant COLLATERAL_MASK =
    0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;

  /**
   * @notice Sets if the user is borrowing the reserve identified by reserveIndex
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @param borrowing True if the user is borrowing the reserve, false otherwise
   */
  function setBorrowing(
    DataTypes.UserConfigurationMap storage self,
    uint256 reserveIndex,
    bool borrowing
  ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00580000, 1037618708568) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00580001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00581000, self.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00581001, reserveIndex) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00581002, borrowing) }
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      uint256 bit = 1 << (reserveIndex << 1);
      if (borrowing) {
        self.data |= bit;
      } else {
        self.data &= ~bit;uint256 certora_local34 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000022,certora_local34)}
      }
    }
  }
  // a version of the previous function that modifies user config in memory
  function setBorrowingInMemory(
    DataTypes.UserConfigurationMap memory self,
    uint256 reserveIndex,
    bool borrowing
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00590000, 1037618708569) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00590001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00591000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00591001, reserveIndex) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00591002, borrowing) }
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      uint256 bit = 1 << (reserveIndex << 1);
      if (borrowing) {
        self.data |= bit;
      } else {
        self.data &= ~bit;uint256 certora_local35 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000023,certora_local35)}
      }
    }
  }

  /**
   * @notice Sets if the user is using as collateral the reserve identified by reserveIndex
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @param usingAsCollateral True if the user is using the reserve as collateral, false otherwise
   */
  function setUsingAsCollateral(
    DataTypes.UserConfigurationMap storage self,
    uint256 reserveIndex,
    bool usingAsCollateral
  ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005b0000, 1037618708571) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005b0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005b1000, self.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005b1001, reserveIndex) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005b1002, usingAsCollateral) }
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      uint256 bit = 1 << ((reserveIndex << 1) + 1);
      if (usingAsCollateral) {
        self.data |= bit;
      } else {
        self.data &= ~bit;uint256 certora_local36 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000024,certora_local36)}
      }
    }
  }
  // a version of the previous function that modifies user config in memory
  function setUsingAsCollateralInMemory(
    DataTypes.UserConfigurationMap memory self,
    uint256 reserveIndex,
    bool usingAsCollateral
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005c0000, 1037618708572) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005c0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005c1000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005c1001, reserveIndex) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005c1002, usingAsCollateral) }
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      uint256 bit = 1 << ((reserveIndex << 1) + 1);
      if (usingAsCollateral) {
        self.data |= bit;
      } else {
        self.data &= ~bit;uint256 certora_local37 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000025,certora_local37)}
      }
    }
  }

  /**
   * @notice Returns if a user has been using the reserve for borrowing or as collateral
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the user has been using a reserve for borrowing or as collateral, false otherwise
   */
  function isUsingAsCollateralOrBorrowing(
    DataTypes.UserConfigurationMap memory self,
    uint256 reserveIndex
  ) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005a0000, 1037618708570) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005a0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005a1000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005a1001, reserveIndex) }
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      return (self.data >> (reserveIndex << 1)) & 3 != 0;
    }
  }

  /**
   * @notice Validate a user has been using the reserve for borrowing
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the user has been using a reserve for borrowing, false otherwise
   */
  function isBorrowing(
    DataTypes.UserConfigurationMap memory self,
    uint256 reserveIndex
  ) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005d0000, 1037618708573) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005d0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005d1000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005d1001, reserveIndex) }
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      return (self.data >> (reserveIndex << 1)) & 1 != 0;
    }
  }

  /**
   * @notice Validate a user has been using the reserve as collateral
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the user has been using a reserve as collateral, false otherwise
   */
  function isUsingAsCollateral(
    DataTypes.UserConfigurationMap memory self,
    uint256 reserveIndex
  ) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005e0000, 1037618708574) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005e0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005e1000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005e1001, reserveIndex) }
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      return (self.data >> ((reserveIndex << 1) + 1)) & 1 != 0;
    }
  }

  /**
   * @notice Checks if a user has been supplying only one reserve as collateral
   * @dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
   * @param self The configuration object
   * @return True if the user has been supplying as collateral one reserve, false otherwise
   */
  function isUsingAsCollateralOne(
    DataTypes.UserConfigurationMap memory self
  ) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005f0000, 1037618708575) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005f0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005f1000, self) }
    uint256 collateralData = self.data & COLLATERAL_MASK;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000020,collateralData)}
    return collateralData != 0 && (collateralData & (collateralData - 1) == 0);
  }

  /**
   * @notice Checks if a user has been supplying any reserve as collateral
   * @param self The configuration object
   * @return True if the user has been supplying as collateral any reserve, false otherwise
   */
  function isUsingAsCollateralAny(
    DataTypes.UserConfigurationMap memory self
  ) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00600000, 1037618708576) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00600001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00601000, self) }
    return self.data & COLLATERAL_MASK != 0;
  }

  /**
   * @notice Checks if a user has been borrowing only one asset
   * @dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
   * @param self The configuration object
   * @return True if the user has been supplying as collateral one reserve, false otherwise
   */
  function isBorrowingOne(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00610000, 1037618708577) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00610001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00611000, self) }
    uint256 borrowingData = self.data & BORROWING_MASK;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000021,borrowingData)}
    return borrowingData != 0 && (borrowingData & (borrowingData - 1) == 0);
  }

  /**
   * @notice Checks if a user has been borrowing from any reserve
   * @param self The configuration object
   * @return True if the user has been borrowing any reserve, false otherwise
   */
  function isBorrowingAny(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00620000, 1037618708578) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00620001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00621000, self) }
    return self.data & BORROWING_MASK != 0;
  }

  /**
   * @notice Checks if a user has not been using any reserve for borrowing or supply
   * @param self The configuration object
   * @return True if the user has not been borrowing or supplying any reserve, false otherwise
   */
  function isEmpty(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00630000, 1037618708579) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00630001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00631000, self) }
    return self.data == 0;
  }

  /**
   * @notice Returns the Isolation Mode state of the user
   * @param self The configuration object
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @return True if the user is in isolation mode, false otherwise
   * @return The address of the only asset used as collateral
   * @return The debt ceiling of the reserve
   */
  function getIsolationModeState(
    DataTypes.UserConfigurationMap memory self,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList
  ) internal view returns (bool, address, uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00640000, 1037618708580) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00640001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00641000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00641001, reservesData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00641002, reservesList.slot) }
    if (isUsingAsCollateralOne(self)) {
      uint256 assetId = _getFirstAssetIdByMask(self, COLLATERAL_MASK);

      address assetAddress = reservesList[assetId];
      uint256 ceiling = reservesData[assetAddress].configuration.getDebtCeiling();
      if (ceiling != 0) {
        return (true, assetAddress, ceiling);
      }
    }
    return (false, address(0), 0);
  }

  /**
   * @notice Returns the siloed borrowing state for the user
   * @param self The configuration object
   * @param reservesData The data of all the reserves
   * @param reservesList The reserve list
   * @return True if the user has borrowed a siloed asset, false otherwise
   * @return The address of the only borrowed asset
   */
  function getSiloedBorrowingState(
    DataTypes.UserConfigurationMap memory self,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList
  ) internal view returns (bool, address) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00650000, 1037618708581) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00650001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00651000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00651001, reservesData.slot) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00651002, reservesList.slot) }
    if (isBorrowingOne(self)) {
      uint256 assetId = _getFirstAssetIdByMask(self, BORROWING_MASK);
      address assetAddress = reservesList[assetId];
      if (reservesData[assetAddress].configuration.getSiloedBorrowing()) {
        return (true, assetAddress);
      }
    }

    return (false, address(0));
  }

  /**
   * @notice Returns the address of the first asset flagged in the bitmap given the corresponding bitmask
   * @param self The configuration object
   * @return id The index of the first asset flagged in the bitmap once the corresponding mask is applied
   */
  function _getFirstAssetIdByMask(
    DataTypes.UserConfigurationMap memory self,
    uint256 mask
  ) internal pure returns (uint256 id) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00660000, 1037618708582) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00660001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00661000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00661001, mask) }
    unchecked {
      uint256 bitmapData = self.data & mask;
      uint256 firstAssetPosition = bitmapData & ~(bitmapData - 1);

      while ((firstAssetPosition >>= 2) != 0) {
        id += 1;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000026,id)}
      }
    }
  }
}
