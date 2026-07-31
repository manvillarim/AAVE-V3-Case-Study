// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {MathUtils} from "cyfrin/src/contracts/protocol/libraries/math/MathUtils.sol";

contract MathUtilsCyfrin {
    function calculateLinearInterest(uint256 rate, uint40 t) external view returns (uint256) {
        return MathUtils.calculateLinearInterest(rate, t);
    }

    function calculateCompoundedInterest(uint256 rate, uint40 t, uint256 cur) external pure returns (uint256) {
        return MathUtils.calculateCompoundedInterest(rate, t, cur);
    }

    function calculateCompoundedInterestNow(uint256 rate, uint40 t) external view returns (uint256) {
        return MathUtils.calculateCompoundedInterest(rate, t);
    }
}
