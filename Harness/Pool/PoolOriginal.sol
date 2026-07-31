// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {PoolInstance} from "aave-v3-origin-renamed/src/contracts/instances/PoolInstance.sol";
import {IPoolAddressesProvider} from "aave-v3-origin-renamed/src/contracts/interfaces/IPoolAddressesProvider.sol";
import {DataTypesOrig} from "aave-v3-origin-renamed/src/contracts/protocol/libraries/types/DataTypesOrig.sol";

contract PoolOriginal is PoolInstance {
    uint256 public rdConfiguration;
    uint128 public rdLiquidityIndex;
    uint128 public rdCurrentLiquidityRate;
    uint128 public rdVariableBorrowIndex;
    uint128 public rdCurrentVariableBorrowRate;
    uint40 public rdLastUpdateTimestamp;
    uint16 public rdId;
    address public rdATokenAddress;
    address public rdStableDebtTokenAddress;
    address public rdVariableDebtTokenAddress;
    address public rdInterestRateStrategyAddress;
    uint128 public rdAccruedToTreasury;
    uint128 public rdUnbacked;
    uint128 public rdIsolationModeTotalDebt;

    uint256 public lastConfiguration;
    uint256 public lastUserConfiguration;

    uint256 public lastReservesListLength;
    mapping(uint256 => address) public lastReservesList;

    uint16 public emLtv;
    uint16 public emLiquidationThreshold;
    uint16 public emLiquidationBonus;
    address public emPriceSource;
    bytes32 public emLabelHash;
    uint256 public emLabelLength;

    uint16 public ccLtv;
    uint16 public ccLiquidationThreshold;
    uint16 public ccLiquidationBonus;

    bytes32 public labelHash;
    uint256 public labelLength;

    constructor(IPoolAddressesProvider provider) PoolInstance(provider) {}

    function getReserveData_instr(address asset) external {
        DataTypesOrig.ReserveDataLegacy memory r = this.getReserveData(asset);
        rdConfiguration = r.configuration.data;
        rdLiquidityIndex = r.liquidityIndex;
        rdCurrentLiquidityRate = r.currentLiquidityRate;
        rdVariableBorrowIndex = r.variableBorrowIndex;
        rdCurrentVariableBorrowRate = r.currentVariableBorrowRate;
        rdLastUpdateTimestamp = r.lastUpdateTimestamp;
        rdId = r.id;
        rdATokenAddress = r.aTokenAddress;
        rdStableDebtTokenAddress = r.stableDebtTokenAddress;
        rdVariableDebtTokenAddress = r.variableDebtTokenAddress;
        rdInterestRateStrategyAddress = r.interestRateStrategyAddress;
        rdAccruedToTreasury = r.accruedToTreasury;
        rdUnbacked = r.unbacked;
        rdIsolationModeTotalDebt = r.isolationModeTotalDebt;
    }

    function getConfiguration_instr(address asset) external {
        lastConfiguration = this.getConfiguration(asset).data;
    }

    function getUserConfiguration_instr(address user) external {
        lastUserConfiguration = this.getUserConfiguration(user).data;
    }

    function getReservesList_instr() external {
        address[] memory list = this.getReservesList();
        lastReservesListLength = list.length;
        for (uint256 i = 0; i < list.length; i++) {
            lastReservesList[i] = list[i];
        }
    }

    function getEModeCategoryData_instr(uint8 id) external {
        DataTypesOrig.EModeCategoryLegacy memory c = this.getEModeCategoryData(id);
        emLtv = c.ltv;
        emLiquidationThreshold = c.liquidationThreshold;
        emLiquidationBonus = c.liquidationBonus;
        emPriceSource = c.priceSource;
        emLabelHash = keccak256(bytes(c.label));
        emLabelLength = bytes(c.label).length;
    }

    function getEModeCategoryCollateralConfig_instr(uint8 id) external {
        DataTypesOrig.CollateralConfig memory c = this.getEModeCategoryCollateralConfig(id);
        ccLtv = c.ltv;
        ccLiquidationThreshold = c.liquidationThreshold;
        ccLiquidationBonus = c.liquidationBonus;
    }

    function getEModeCategoryLabel_instr(uint8 id) external {
        string memory l = this.getEModeCategoryLabel(id);
        labelHash = keccak256(bytes(l));
        labelLength = bytes(l).length;
    }
}
