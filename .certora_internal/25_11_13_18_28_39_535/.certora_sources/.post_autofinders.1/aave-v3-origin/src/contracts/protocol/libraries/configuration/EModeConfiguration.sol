// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Errors} from '../helpers/Errors.sol';
import {ReserveConfiguration} from './ReserveConfiguration.sol';

/**
 * @title EModeConfiguration library
 * @author BGD Labs
 * @notice Implements the bitmap logic to handle the eMode configuration
 */
library EModeConfiguration {
  /**
   * @notice Sets a bit in a given bitmap that represents the reserve index range
   * @dev The supplied bitmap is supposed to be a uint128 in which each bit represents a reserve
   * @param bitmap The bitmap
   * @param reserveIndex The index of the reserve in the bitmap
   * @param enabled True if the reserveIndex should be enabled on the bitmap, false otherwise
   * @return The altered bitmap
   */
  function setReserveBitmapBit(
    uint128 bitmap,
    uint256 reserveIndex,
    bool enabled
  ) internal pure returns (uint128) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d00000, 1037618708688) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d00001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d01000, bitmap) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d01001, reserveIndex) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d01002, enabled) }
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      uint128 bit = uint128(1 << reserveIndex);
      if (enabled) {
        return bitmap | bit;
      } else {
        return bitmap & ~bit;
      }
    }
  }

  /**
   * @notice Validates if a reserveIndex is flagged as enabled on a given bitmap
   * @param bitmap The bitmap
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the reserveindex is flagged true
   */
  function isReserveEnabledOnBitmap(
    uint128 bitmap,
    uint256 reserveIndex
  ) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d10000, 1037618708689) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d10001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d11000, bitmap) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d11001, reserveIndex) }
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      return (bitmap >> reserveIndex) & 1 != 0;
    }
  }
}
