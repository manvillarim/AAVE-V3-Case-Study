// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {MathUtils} from "aave-v3-origin/src/contracts/protocol/libraries/math/MathUtils.sol";

contract MathUtilsOriginal {
    uint256 public lastLinearInterest;
    uint256 public lastCompoundedInterest;
    uint256 public lastCompoundedInterestNow;

    function calculateLinearInterest_instr(
        uint256 rate,
        uint40 lastUpdateTimestamp
    ) external returns (uint256) {
        uint256 r = MathUtils.calculateLinearInterest(rate, lastUpdateTimestamp);
        lastLinearInterest = r;
        return r;
    }

    function calculateCompoundedInterest_instr(
        uint256 rate,
        uint40 lastUpdateTimestamp,
        uint256 currentTimestamp
    ) external returns (uint256) {
        uint256 r = MathUtils.calculateCompoundedInterest(rate, lastUpdateTimestamp, currentTimestamp);
        lastCompoundedInterest = r;
        return r;
    }

    function calculateCompoundedInterestNow_instr(
        uint256 rate,
        uint40 lastUpdateTimestamp
    ) external returns (uint256) {
        uint256 r = MathUtils.calculateCompoundedInterest(rate, lastUpdateTimestamp);
        lastCompoundedInterestNow = r;
        return r;
    }
}
