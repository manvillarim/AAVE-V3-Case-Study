// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {ReserveLogic} from "ours/src/contracts/protocol/libraries/logic/ReserveLogic.sol";
import {DataTypes} from "ours/src/contracts/protocol/libraries/types/DataTypes.sol";

contract ReserveLogicOurs {
    mapping(address => DataTypes.ReserveData) internal _reserves;

    function seed(address asset) external {
        _reserves[asset].liquidityIndex = 1e27;
        _reserves[asset].variableBorrowIndex = 1e27;
        _reserves[asset].currentLiquidityRate = 5e25;
        _reserves[asset].currentVariableBorrowRate = 7e25;
        _reserves[asset].lastUpdateTimestamp = uint40(block.timestamp);
    }

    function getNormalizedIncome(address asset) external view returns (uint256) {
        return ReserveLogic.getNormalizedIncome(_reserves[asset]);
    }

    function getNormalizedDebt(address asset) external view returns (uint256) {
        return ReserveLogic.getNormalizedDebt(_reserves[asset]);
    }

    function cumulateToLiquidityIndex(address asset, uint256 tl, uint256 amt) external returns (uint256) {
        return ReserveLogic.cumulateToLiquidityIndex(_reserves[asset], tl, amt);
    }

    function init(address asset, address a1, address a2, address a3) external {
        ReserveLogic.init(_reserves[asset], a1, a2, a3);
    }
}
