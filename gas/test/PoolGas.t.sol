// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import {PoolOrigin} from "../src/PoolOrigin.sol";
import {PoolCyfrin} from "../src/PoolCyfrin.sol";
import {PoolOurs} from "../src/PoolOurs.sol";
import {MockAddressesProvider} from "../src/MockAddressesProvider.sol";
import {IPoolAddressesProvider as IPapOrigin} from "origin/src/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPoolAddressesProvider as IPapCyfrin} from "cyfrin/src/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPoolAddressesProvider as IPapOurs} from "ours/src/contracts/interfaces/IPoolAddressesProvider.sol";

interface IPoolGetters {
    function getReserveData(address asset) external view returns (bytes memory);

    function getConfiguration(address asset) external view returns (uint256);

    function getUserConfiguration(address user) external view returns (uint256);

    function getReservesList() external view returns (address[] memory);

    function getEModeCategoryCollateralConfig(uint8 id) external view returns (bytes memory);

    function getEModeCategoryLabel(uint8 id) external view returns (string memory);

    function getReservesCount() external view returns (uint256);
}

abstract contract PoolGasBase is Test {
    address internal constant ASSET = address(0xA55E7);
    address internal constant USER = address(0xBEEF);

    function _pool() internal view virtual returns (address);

    function testGetConfiguration() public view {
        IPoolGetters(_pool()).getConfiguration(ASSET);
    }

    function testGetUserConfiguration() public view {
        IPoolGetters(_pool()).getUserConfiguration(USER);
    }

    function testGetReservesList() public view {
        IPoolGetters(_pool()).getReservesList();
    }

    function testGetEModeCategoryCollateralConfig() public view {
        IPoolGetters(_pool()).getEModeCategoryCollateralConfig(1);
    }

    function testGetEModeCategoryLabel() public view {
        IPoolGetters(_pool()).getEModeCategoryLabel(1);
    }

    function testGetReservesCount() public view {
        IPoolGetters(_pool()).getReservesCount();
    }
}

contract PoolOriginGas is PoolGasBase {
    PoolOrigin internal p;

    function setUp() public {
        p = new PoolOrigin(IPapOrigin(address(new MockAddressesProvider())));
    }

    function _pool() internal view override returns (address) {
        return address(p);
    }
}

contract PoolCyfrinGas is PoolGasBase {
    PoolCyfrin internal p;

    function setUp() public {
        p = new PoolCyfrin(IPapCyfrin(address(new MockAddressesProvider())));
    }

    function _pool() internal view override returns (address) {
        return address(p);
    }
}

contract PoolOursGas is PoolGasBase {
    PoolOurs internal p;

    function setUp() public {
        p = new PoolOurs(IPapOurs(address(new MockAddressesProvider())));
    }

    function _pool() internal view override returns (address) {
        return address(p);
    }
}
