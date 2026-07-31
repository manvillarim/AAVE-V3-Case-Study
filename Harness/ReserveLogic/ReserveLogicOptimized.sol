// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {ReserveLogic} from "aave-v3-origin-optimized/src/contracts/protocol/libraries/logic/ReserveLogic.sol";
import {DataTypes} from "aave-v3-origin-optimized/src/contracts/protocol/libraries/types/DataTypes.sol";

contract ReserveLogicOptimized {
    using ReserveLogic for DataTypes.ReserveData;

    mapping(address => DataTypes.ReserveData) internal _reserves;

    uint256 public lastNormalizedIncome;
    uint256 public lastNormalizedDebt;
    uint256 public lastCumulateIndex;

    uint256 public cCurrScaledVariableDebt;
    uint256 public cNextScaledVariableDebt;
    uint256 public cCurrLiquidityIndex;
    uint256 public cNextLiquidityIndex;
    uint256 public cCurrVariableBorrowIndex;
    uint256 public cNextVariableBorrowIndex;
    uint256 public cCurrLiquidityRate;
    uint256 public cCurrVariableBorrowRate;
    uint256 public cReserveFactor;
    uint256 public cReserveConfiguration;
    address public cATokenAddress;
    address public cVariableDebtTokenAddress;
    uint40 public cReserveLastUpdateTimestamp;

    function getNormalizedIncome_instr(address asset) external {
        lastNormalizedIncome = ReserveLogic.getNormalizedIncome(_reserves[asset]);
    }

    function getNormalizedDebt_instr(address asset) external {
        lastNormalizedDebt = ReserveLogic.getNormalizedDebt(_reserves[asset]);
    }

    function cumulateToLiquidityIndex_instr(
        address asset,
        uint256 totalLiquidity,
        uint256 amount
    ) external {
        lastCumulateIndex = ReserveLogic.cumulateToLiquidityIndex(
            _reserves[asset],
            totalLiquidity,
            amount
        );
    }

    function cache_instr(address asset) external {
        DataTypes.ReserveCache memory c = ReserveLogic.cache(_reserves[asset]);
        cCurrScaledVariableDebt = c.currScaledVariableDebt;
        cNextScaledVariableDebt = c.nextScaledVariableDebt;
        cCurrLiquidityIndex = c.currLiquidityIndex;
        cNextLiquidityIndex = c.nextLiquidityIndex;
        cCurrVariableBorrowIndex = c.currVariableBorrowIndex;
        cNextVariableBorrowIndex = c.nextVariableBorrowIndex;
        cCurrLiquidityRate = c.currLiquidityRate;
        cCurrVariableBorrowRate = c.currVariableBorrowRate;
        cReserveFactor = c.reserveFactor;
        cReserveConfiguration = c.reserveConfiguration.data;
        cATokenAddress = c.aTokenAddress;
        cVariableDebtTokenAddress = c.variableDebtTokenAddress;
        cReserveLastUpdateTimestamp = c.reserveLastUpdateTimestamp;
    }

    function updateState_instr(address asset) external {
        DataTypes.ReserveCache memory c = ReserveLogic.cache(_reserves[asset]);
        ReserveLogic.updateState(_reserves[asset], c);
    }

    function init_instr(
        address asset,
        address aTokenAddress,
        address variableDebtTokenAddress,
        address interestRateStrategyAddress
    ) external {
        ReserveLogic.init(
            _reserves[asset],
            aTokenAddress,
            variableDebtTokenAddress,
            interestRateStrategyAddress
        );
    }
}
