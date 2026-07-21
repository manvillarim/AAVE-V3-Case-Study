// SPDX-License-Identifier:  BUSL-1.1
pragma solidity ^0.8.10;

import {Collector} from "../../aave-v3-origin-full-optimized/src/contracts/treasury/Collector.sol";

contract CollectorOptimized is Collector {
    uint256 public lastDeltaOfReturn;

    function deltaOf_instr(uint256 streamId) external returns (uint256) {
        uint256 r = deltaOf(streamId);
        lastDeltaOfReturn = r;
        return r;
    }
}