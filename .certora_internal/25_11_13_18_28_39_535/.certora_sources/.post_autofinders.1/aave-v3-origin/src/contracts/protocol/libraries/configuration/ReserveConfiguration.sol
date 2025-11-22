// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title ReserveConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
  uint256 internal constant LTV_MASK =                       0x000000000000000000000000000000000000000000000000000000000000FFFF; // prettier-ignore
  uint256 internal constant LIQUIDATION_THRESHOLD_MASK =     0x00000000000000000000000000000000000000000000000000000000FFFF0000; // prettier-ignore
  uint256 internal constant LIQUIDATION_BONUS_MASK =         0x0000000000000000000000000000000000000000000000000000FFFF00000000; // prettier-ignore
  uint256 internal constant DECIMALS_MASK =                  0x00000000000000000000000000000000000000000000000000FF000000000000; // prettier-ignore
  uint256 internal constant ACTIVE_MASK =                    0x0000000000000000000000000000000000000000000000000100000000000000; // prettier-ignore
  uint256 internal constant FROZEN_MASK =                    0x0000000000000000000000000000000000000000000000000200000000000000; // prettier-ignore
  uint256 internal constant BORROWING_MASK =                 0x0000000000000000000000000000000000000000000000000400000000000000; // prettier-ignore
  // @notice there is an unoccupied hole of 1 bit at position 59 from pre 3.2 stableBorrowRateEnabled
  uint256 internal constant PAUSED_MASK =                    0x0000000000000000000000000000000000000000000000001000000000000000; // prettier-ignore
  uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =   0x0000000000000000000000000000000000000000000000002000000000000000; // prettier-ignore
  uint256 internal constant SILOED_BORROWING_MASK =          0x0000000000000000000000000000000000000000000000004000000000000000; // prettier-ignore
  uint256 internal constant FLASHLOAN_ENABLED_MASK =         0x0000000000000000000000000000000000000000000000008000000000000000; // prettier-ignore
  uint256 internal constant RESERVE_FACTOR_MASK =            0x00000000000000000000000000000000000000000000FFFF0000000000000000; // prettier-ignore
  uint256 internal constant BORROW_CAP_MASK =                0x00000000000000000000000000000000000FFFFFFFFF00000000000000000000; // prettier-ignore
  uint256 internal constant SUPPLY_CAP_MASK =                0x00000000000000000000000000FFFFFFFFF00000000000000000000000000000; // prettier-ignore
  uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =  0x0000000000000000000000FFFF00000000000000000000000000000000000000; // prettier-ignore
  //@notice there is an unoccupied hole of 8 bits from 168 to 176 left from pre 3.2 eModeCategory
  uint256 internal constant UNBACKED_MINT_CAP_MASK =         0x00000000000FFFFFFFFF00000000000000000000000000000000000000000000; // prettier-ignore
  uint256 internal constant DEBT_CEILING_MASK =              0x0FFFFFFFFFF00000000000000000000000000000000000000000000000000000; // prettier-ignore
  uint256 internal constant VIRTUAL_ACC_ACTIVE_MASK =        0x1000000000000000000000000000000000000000000000000000000000000000; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint256 internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
  uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
  uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
  uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;
  uint256 internal constant BORROWABLE_IN_ISOLATION_START_BIT_POSITION = 61;
  uint256 internal constant SILOED_BORROWING_START_BIT_POSITION = 62;
  uint256 internal constant FLASHLOAN_ENABLED_START_BIT_POSITION = 63;
  uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;
  uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
  uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
  uint256 internal constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;
  //@notice there is an unoccupied hole of 8 bits from 168 to 176 left from pre 3.2 eModeCategory
  uint256 internal constant UNBACKED_MINT_CAP_START_BIT_POSITION = 176;
  uint256 internal constant DEBT_CEILING_START_BIT_POSITION = 212;
  uint256 internal constant VIRTUAL_ACC_START_BIT_POSITION = 252;

  uint256 internal constant MAX_VALID_LTV = 65535;
  uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
  uint256 internal constant MAX_VALID_LIQUIDATION_BONUS = 65535;
  uint256 internal constant MAX_VALID_DECIMALS = 255;
  uint256 internal constant MAX_VALID_RESERVE_FACTOR = 65535;
  uint256 internal constant MAX_VALID_BORROW_CAP = 68719476735;
  uint256 internal constant MAX_VALID_SUPPLY_CAP = 68719476735;
  uint256 internal constant MAX_VALID_LIQUIDATION_PROTOCOL_FEE = 65535;
  uint256 internal constant MAX_VALID_UNBACKED_MINT_CAP = 68719476735;
  uint256 internal constant MAX_VALID_DEBT_CEILING = 1099511627775;

  uint256 public constant DEBT_CEILING_DECIMALS = 2;
  uint16 public constant MAX_RESERVES_COUNT = 128;

  /**
   * @notice Sets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @param ltv The new ltv
   */
  function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d20000, 1037618708690) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d20001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d21000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d21001, ltv) }
    require(ltv <= MAX_VALID_LTV, Errors.INVALID_LTV);

    self.data = (self.data & ~LTV_MASK) | ltv;uint256 certora_local14 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000e,certora_local14)}
  }

  /**
   * @notice Gets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @return The loan to value
   */
  function getLtv(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d30000, 1037618708691) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d30001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d31000, self) }
    return self.data & LTV_MASK;
  }

  /**
   * @notice Sets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @param threshold The new liquidation threshold
   */
  function setLiquidationThreshold(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 threshold
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d50000, 1037618708693) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d50001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d51000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d51001, threshold) }
    require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.INVALID_LIQ_THRESHOLD);

    self.data =
      (self.data & ~LIQUIDATION_THRESHOLD_MASK) |
      (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);uint256 certora_local15 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000f,certora_local15)}
  }

  /**
   * @notice Gets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @return The liquidation threshold
   */
  function getLiquidationThreshold(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d60000, 1037618708694) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d60001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d61000, self) }
    return (self.data & LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @notice Sets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @param bonus The new liquidation bonus
   */
  function setLiquidationBonus(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 bonus
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d40000, 1037618708692) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d40001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d41000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d41001, bonus) }
    require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.INVALID_LIQ_BONUS);

    self.data =
      (self.data & ~LIQUIDATION_BONUS_MASK) |
      (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);uint256 certora_local16 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000010,certora_local16)}
  }

  /**
   * @notice Gets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @return The liquidation bonus
   */
  function getLiquidationBonus(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d70000, 1037618708695) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d70001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d71000, self) }
    return (self.data & LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
  }

  /**
   * @notice Sets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @param decimals The decimals
   */
  function setDecimals(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 decimals
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d80000, 1037618708696) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d80001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d81000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d81001, decimals) }
    require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);

    self.data = (self.data & ~DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);uint256 certora_local17 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000011,certora_local17)}
  }

  /**
   * @notice Gets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @return The decimals of the asset
   */
  function getDecimals(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d90000, 1037618708697) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d90001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d91000, self) }
    return (self.data & DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
  }

  /**
   * @notice Sets the active state of the reserve
   * @param self The reserve configuration
   * @param active The active state
   */
  function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00da0000, 1037618708698) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00da0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00da1000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00da1001, active) }
    self.data =
      (self.data & ~ACTIVE_MASK) |
      (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);uint256 certora_local18 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000012,certora_local18)}
  }

  /**
   * @notice Gets the active state of the reserve
   * @param self The reserve configuration
   * @return The active state
   */
  function getActive(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00db0000, 1037618708699) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00db0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00db1000, self) }
    return (self.data & ACTIVE_MASK) != 0;
  }

  /**
   * @notice Sets the frozen state of the reserve
   * @param self The reserve configuration
   * @param frozen The frozen state
   */
  function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00dc0000, 1037618708700) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00dc0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00dc1000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00dc1001, frozen) }
    self.data =
      (self.data & ~FROZEN_MASK) |
      (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);uint256 certora_local19 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000013,certora_local19)}
  }

  /**
   * @notice Gets the frozen state of the reserve
   * @param self The reserve configuration
   * @return The frozen state
   */
  function getFrozen(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00dd0000, 1037618708701) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00dd0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00dd1000, self) }
    return (self.data & FROZEN_MASK) != 0;
  }

  /**
   * @notice Sets the paused state of the reserve
   * @param self The reserve configuration
   * @param paused The paused state
   */
  function setPaused(DataTypes.ReserveConfigurationMap memory self, bool paused) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00de0000, 1037618708702) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00de0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00de1000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00de1001, paused) }
    self.data =
      (self.data & ~PAUSED_MASK) |
      (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);uint256 certora_local20 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000014,certora_local20)}
  }

  /**
   * @notice Gets the paused state of the reserve
   * @param self The reserve configuration
   * @return The paused state
   */
  function getPaused(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00df0000, 1037618708703) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00df0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00df1000, self) }
    return (self.data & PAUSED_MASK) != 0;
  }

  /**
   * @notice Sets the borrowable in isolation flag for the reserve.
   * @dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the borrowed
   * amount will be accumulated in the isolated collateral's total debt exposure.
   * @dev Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations.
   * @param self The reserve configuration
   * @param borrowable True if the asset is borrowable
   */
  function setBorrowableInIsolation(
    DataTypes.ReserveConfigurationMap memory self,
    bool borrowable
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e00000, 1037618708704) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e00001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e01000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e01001, borrowable) }
    self.data =
      (self.data & ~BORROWABLE_IN_ISOLATION_MASK) |
      (uint256(borrowable ? 1 : 0) << BORROWABLE_IN_ISOLATION_START_BIT_POSITION);uint256 certora_local21 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000015,certora_local21)}
  }

  /**
   * @notice Gets the borrowable in isolation flag for the reserve.
   * @dev If the returned flag is true, the asset is borrowable against isolated collateral. Assets borrowed with
   * isolated collateral is accounted for in the isolated collateral's total debt exposure.
   * @dev Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations.
   * @param self The reserve configuration
   * @return The borrowable in isolation flag
   */
  function getBorrowableInIsolation(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e10000, 1037618708705) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e10001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e11000, self) }
    return (self.data & BORROWABLE_IN_ISOLATION_MASK) != 0;
  }

  /**
   * @notice Sets the siloed borrowing flag for the reserve.
   * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
   * @param self The reserve configuration
   * @param siloed True if the asset is siloed
   */
  function setSiloedBorrowing(
    DataTypes.ReserveConfigurationMap memory self,
    bool siloed
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ee0000, 1037618708718) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ee0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ee1000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ee1001, siloed) }
    self.data =
      (self.data & ~SILOED_BORROWING_MASK) |
      (uint256(siloed ? 1 : 0) << SILOED_BORROWING_START_BIT_POSITION);uint256 certora_local22 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000016,certora_local22)}
  }

  /**
   * @notice Gets the siloed borrowing flag for the reserve.
   * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
   * @param self The reserve configuration
   * @return The siloed borrowing flag
   */
  function getSiloedBorrowing(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ed0000, 1037618708717) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ed0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ed1000, self) }
    return (self.data & SILOED_BORROWING_MASK) != 0;
  }

  /**
   * @notice Enables or disables borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the borrowing needs to be enabled, false otherwise
   */
  function setBorrowingEnabled(
    DataTypes.ReserveConfigurationMap memory self,
    bool enabled
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ec0000, 1037618708716) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ec0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ec1000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ec1001, enabled) }
    self.data =
      (self.data & ~BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);uint256 certora_local23 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000017,certora_local23)}
  }

  /**
   * @notice Gets the borrowing state of the reserve
   * @param self The reserve configuration
   * @return The borrowing state
   */
  function getBorrowingEnabled(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ef0000, 1037618708719) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ef0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ef1000, self) }
    return (self.data & BORROWING_MASK) != 0;
  }

  /**
   * @notice Sets the reserve factor of the reserve
   * @param self The reserve configuration
   * @param reserveFactor The reserve factor
   */
  function setReserveFactor(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 reserveFactor
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f00000, 1037618708720) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f00001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f01000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f01001, reserveFactor) }
    require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.INVALID_RESERVE_FACTOR);

    self.data =
      (self.data & ~RESERVE_FACTOR_MASK) |
      (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);uint256 certora_local24 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000018,certora_local24)}
  }

  /**
   * @notice Gets the reserve factor of the reserve
   * @param self The reserve configuration
   * @return The reserve factor
   */
  function getReserveFactor(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f10000, 1037618708721) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f10001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f11000, self) }
    return (self.data & RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
  }

  /**
   * @notice Sets the borrow cap of the reserve
   * @param self The reserve configuration
   * @param borrowCap The borrow cap
   */
  function setBorrowCap(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 borrowCap
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f20000, 1037618708722) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f20001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f21000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f21001, borrowCap) }
    require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);

    self.data = (self.data & ~BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);uint256 certora_local25 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000019,certora_local25)}
  }

  /**
   * @notice Gets the borrow cap of the reserve
   * @param self The reserve configuration
   * @return The borrow cap
   */
  function getBorrowCap(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f30000, 1037618708723) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f30001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f31000, self) }
    return (self.data & BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the supply cap of the reserve
   * @param self The reserve configuration
   * @param supplyCap The supply cap
   */
  function setSupplyCap(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 supplyCap
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f40000, 1037618708724) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f40001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f41000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f41001, supplyCap) }
    require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);

    self.data = (self.data & ~SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);uint256 certora_local26 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001a,certora_local26)}
  }

  /**
   * @notice Gets the supply cap of the reserve
   * @param self The reserve configuration
   * @return The supply cap
   */
  function getSupplyCap(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f50000, 1037618708725) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f50001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f51000, self) }
    return (self.data & SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the debt ceiling in isolation mode for the asset
   * @param self The reserve configuration
   * @param ceiling The maximum debt ceiling for the asset
   */
  function setDebtCeiling(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 ceiling
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e90000, 1037618708713) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e90001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e91000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e91001, ceiling) }
    require(ceiling <= MAX_VALID_DEBT_CEILING, Errors.INVALID_DEBT_CEILING);

    self.data = (self.data & ~DEBT_CEILING_MASK) | (ceiling << DEBT_CEILING_START_BIT_POSITION);uint256 certora_local27 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001b,certora_local27)}
  }

  /**
   * @notice Gets the debt ceiling for the asset if the asset is in isolation mode
   * @param self The reserve configuration
   * @return The debt ceiling (0 = isolation mode disabled)
   */
  function getDebtCeiling(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ea0000, 1037618708714) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ea0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ea1000, self) }
    return (self.data & DEBT_CEILING_MASK) >> DEBT_CEILING_START_BIT_POSITION;
  }

  /**
   * @notice Sets the liquidation protocol fee of the reserve
   * @param self The reserve configuration
   * @param liquidationProtocolFee The liquidation protocol fee
   */
  function setLiquidationProtocolFee(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 liquidationProtocolFee
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00eb0000, 1037618708715) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00eb0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00eb1000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00eb1001, liquidationProtocolFee) }
    require(
      liquidationProtocolFee <= MAX_VALID_LIQUIDATION_PROTOCOL_FEE,
      Errors.INVALID_LIQUIDATION_PROTOCOL_FEE
    );

    self.data =
      (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) |
      (liquidationProtocolFee << LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION);uint256 certora_local28 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001c,certora_local28)}
  }

  /**
   * @dev Gets the liquidation protocol fee
   * @param self The reserve configuration
   * @return The liquidation protocol fee
   */
  function getLiquidationProtocolFee(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e20000, 1037618708706) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e20001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e21000, self) }
    return
      (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) >> LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
  }

  /**
   * @notice Sets the unbacked mint cap of the reserve
   * @param self The reserve configuration
   * @param unbackedMintCap The unbacked mint cap
   */
  function setUnbackedMintCap(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 unbackedMintCap
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e30000, 1037618708707) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e30001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e31000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e31001, unbackedMintCap) }
    require(unbackedMintCap <= MAX_VALID_UNBACKED_MINT_CAP, Errors.INVALID_UNBACKED_MINT_CAP);

    self.data =
      (self.data & ~UNBACKED_MINT_CAP_MASK) |
      (unbackedMintCap << UNBACKED_MINT_CAP_START_BIT_POSITION);uint256 certora_local29 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001d,certora_local29)}
  }

  /**
   * @dev Gets the unbacked mint cap of the reserve
   * @param self The reserve configuration
   * @return The unbacked mint cap
   */
  function getUnbackedMintCap(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e40000, 1037618708708) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e40001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e41000, self) }
    return (self.data & UNBACKED_MINT_CAP_MASK) >> UNBACKED_MINT_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the flashloanable flag for the reserve
   * @param self The reserve configuration
   * @param flashLoanEnabled True if the asset is flashloanable, false otherwise
   */
  function setFlashLoanEnabled(
    DataTypes.ReserveConfigurationMap memory self,
    bool flashLoanEnabled
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e50000, 1037618708709) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e50001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e51000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e51001, flashLoanEnabled) }
    self.data =
      (self.data & ~FLASHLOAN_ENABLED_MASK) |
      (uint256(flashLoanEnabled ? 1 : 0) << FLASHLOAN_ENABLED_START_BIT_POSITION);uint256 certora_local30 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001e,certora_local30)}
  }

  /**
   * @notice Gets the flashloanable flag for the reserve
   * @param self The reserve configuration
   * @return The flashloanable flag
   */
  function getFlashLoanEnabled(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e60000, 1037618708710) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e60001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e61000, self) }
    return (self.data & FLASHLOAN_ENABLED_MASK) != 0;
  }

  /**
   * @notice Sets the virtual account active/not state of the reserve
   * @param self The reserve configuration
   * @param active The active state
   */
  function setVirtualAccActive(
    DataTypes.ReserveConfigurationMap memory self,
    bool active
  ) internal pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e70000, 1037618708711) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e70001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e71000, self) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e71001, active) }
    self.data =
      (self.data & ~VIRTUAL_ACC_ACTIVE_MASK) |
      (uint256(active ? 1 : 0) << VIRTUAL_ACC_START_BIT_POSITION);uint256 certora_local31 = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001f,certora_local31)}
  }

  /**
   * @notice Gets the virtual account active/not state of the reserve
   * @dev The state should be true for all normal assets and should be false
   * Virtual accounting being disabled means that the asset:
   * - is GHO
   * - can never be supplied
   * - the interest rate strategy is not influenced by the virtual balance
   * @param self The reserve configuration
   * @return The active state
   */
  function getIsVirtualAccActive(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e80000, 1037618708712) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e80001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e81000, self) }
    return (self.data & VIRTUAL_ACC_ACTIVE_MASK) != 0;
  }

  /**
   * @notice Gets the configuration flags of the reserve
   * @param self The reserve configuration
   * @return The state flag representing active
   * @return The state flag representing frozen
   * @return The state flag representing borrowing enabled
   * @return The state flag representing paused
   */
  function getFlags(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (bool, bool, bool, bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f60000, 1037618708726) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f60001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f61000, self) }
    uint256 dataLocal = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000b,dataLocal)}

    return (
      (dataLocal & ACTIVE_MASK) != 0,
      (dataLocal & FROZEN_MASK) != 0,
      (dataLocal & BORROWING_MASK) != 0,
      (dataLocal & PAUSED_MASK) != 0
    );
  }

  /**
   * @notice Gets the configuration parameters of the reserve from storage
   * @param self The reserve configuration
   * @return The state param representing ltv
   * @return The state param representing liquidation threshold
   * @return The state param representing liquidation bonus
   * @return The state param representing reserve decimals
   * @return The state param representing reserve factor
   */
  function getParams(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (uint256, uint256, uint256, uint256, uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f70000, 1037618708727) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f70001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f71000, self) }
    uint256 dataLocal = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000c,dataLocal)}

    return (
      dataLocal & LTV_MASK,
      (dataLocal & LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (dataLocal & LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
      (dataLocal & DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
      (dataLocal & RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
    );
  }

  /**
   * @notice Gets the caps parameters of the reserve from storage
   * @param self The reserve configuration
   * @return The state param representing borrow cap
   * @return The state param representing supply cap.
   */
  function getCaps(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (uint256, uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f80000, 1037618708728) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f80001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f81000, self) }
    uint256 dataLocal = self.data;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000d,dataLocal)}

    return (
      (dataLocal & BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
      (dataLocal & SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
    );
  }
}
