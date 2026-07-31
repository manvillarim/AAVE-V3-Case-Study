// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {ReserveLogicOrigin} from "../src/ReserveLogicOrigin.sol";
import {ReserveLogicCyfrin} from "../src/ReserveLogicCyfrin.sol";
import {ReserveLogicOurs} from "../src/ReserveLogicOurs.sol";

abstract contract RLGasBase is Test {
    address constant ASSET = address(0xA55E7);

    function _c() internal view virtual returns (ReserveLogicOrigin);

    function testGetNormalizedIncome() public view {
        _c().getNormalizedIncome(ASSET);
    }

    function testGetNormalizedDebt() public view {
        _c().getNormalizedDebt(ASSET);
    }

    function testCumulateToLiquidityIndex() public {
        _c().cumulateToLiquidityIndex(ASSET, 1e24, 1e21);
    }

    function testInit() public {
        _c().init(address(0xBEEF), address(1), address(2), address(3));
    }
}

contract RLOriginGas is RLGasBase {
    ReserveLogicOrigin internal c;
    function setUp() public { c = new ReserveLogicOrigin(); c.seed(ASSET); vm.warp(block.timestamp + 3600); }
    function _c() internal view override returns (ReserveLogicOrigin) { return c; }
}

contract RLCyfrinGas is RLGasBase {
    ReserveLogicCyfrin internal c;
    function setUp() public { c = new ReserveLogicCyfrin(); c.seed(ASSET); vm.warp(block.timestamp + 3600); }
    function _c() internal view override returns (ReserveLogicOrigin) { return ReserveLogicOrigin(address(c)); }
}

contract RLOursGas is RLGasBase {
    ReserveLogicOurs internal c;
    function setUp() public { c = new ReserveLogicOurs(); c.seed(ASSET); vm.warp(block.timestamp + 3600); }
    function _c() internal view override returns (ReserveLogicOrigin) { return ReserveLogicOrigin(address(c)); }
}
