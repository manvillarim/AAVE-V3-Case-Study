// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import 'forge-std/Test.sol';
import {PoolAddressesProviderRegistry} from '../../src/contracts/protocol/configuration/PoolAddressesProviderRegistry.sol';

/**
 * Gas benchmark suite for PoolAddressesProviderRegistry.
 */
/// forge-config: default.isolate = true
contract PoolAddressesProviderRegistry_gas_Tests is Test {
    PoolAddressesProviderRegistry public registry;
    
    // Mock addresses
    address owner = makeAddr('owner');
    address provider1 = makeAddr('provider1');
    address provider2 = makeAddr('provider2');
    address provider3 = makeAddr('provider3');
    
    function setUp() public {
        vm.prank(owner);
        registry = new PoolAddressesProviderRegistry(owner);
    }
    
    function test_registerAddressesProvider() external {
        vm.prank(owner);
        registry.registerAddressesProvider(provider1, 1);
        vm.snapshotGasLastCall('PoolAddressesProviderRegistry', 'registerAddressesProvider');
    }
    
    function test_registerAddressesProvider_second() external {
        vm.startPrank(owner);
        registry.registerAddressesProvider(provider1, 1);
        registry.registerAddressesProvider(provider2, 2);
        vm.snapshotGasLastCall('PoolAddressesProviderRegistry', 'registerAddressesProvider_second');
    }
    
    function test_unregisterAddressesProvider() external {
        vm.startPrank(owner);
        registry.registerAddressesProvider(provider1, 1);
        registry.unregisterAddressesProvider(provider1);
        vm.snapshotGasLastCall('PoolAddressesProviderRegistry', 'unregisterAddressesProvider');
    }
    
    function test_unregisterAddressesProvider_first() external {
        vm.startPrank(owner);
        registry.registerAddressesProvider(provider1, 1);
        registry.registerAddressesProvider(provider2, 2);
        registry.registerAddressesProvider(provider3, 3);
        registry.unregisterAddressesProvider(provider1);
        vm.snapshotGasLastCall('PoolAddressesProviderRegistry', 'unregisterAddressesProvider_first');
    }
    
    function test_unregisterAddressesProvider_middle() external {
        vm.startPrank(owner);
        registry.registerAddressesProvider(provider1, 1);
        registry.registerAddressesProvider(provider2, 2);
        registry.registerAddressesProvider(provider3, 3);
        registry.unregisterAddressesProvider(provider2);
        vm.snapshotGasLastCall('PoolAddressesProviderRegistry', 'unregisterAddressesProvider_middle');
    }
    
    function test_unregisterAddressesProvider_last() external {
        vm.startPrank(owner);
        registry.registerAddressesProvider(provider1, 1);
        registry.registerAddressesProvider(provider2, 2);
        registry.registerAddressesProvider(provider3, 3);
        registry.unregisterAddressesProvider(provider3);
        vm.snapshotGasLastCall('PoolAddressesProviderRegistry', 'unregisterAddressesProvider_last');
    }
    
    function test_getAddressesProvidersList() external {
        registry.getAddressesProvidersList();
        vm.snapshotGasLastCall('PoolAddressesProviderRegistry', 'getAddressesProvidersList');
    }
    
    function test_getAddressesProvidersList_withOneProvider() external {
        vm.prank(owner);
        registry.registerAddressesProvider(provider1, 1);
        
        registry.getAddressesProvidersList();
        vm.snapshotGasLastCall('PoolAddressesProviderRegistry', 'getAddressesProvidersList_one');
    }
    
    function test_getAddressesProvidersList_withThreeProviders() external {
        vm.startPrank(owner);
        registry.registerAddressesProvider(provider1, 1);
        registry.registerAddressesProvider(provider2, 2);
        registry.registerAddressesProvider(provider3, 3);
        vm.stopPrank();
        
        registry.getAddressesProvidersList();
        vm.snapshotGasLastCall('PoolAddressesProviderRegistry', 'getAddressesProvidersList_three');
    }
    
    function test_getAddressesProviderIdByAddress() external {
        vm.prank(owner);
        registry.registerAddressesProvider(provider1, 1);
        
        registry.getAddressesProviderIdByAddress(provider1);
        vm.snapshotGasLastCall('PoolAddressesProviderRegistry', 'getAddressesProviderIdByAddress');
    }
    
    function test_getAddressesProviderIdByAddress_notRegistered() external {
        registry.getAddressesProviderIdByAddress(provider1);
        vm.snapshotGasLastCall('PoolAddressesProviderRegistry', 'getAddressesProviderIdByAddress_notRegistered');
    }
    
    function test_getAddressesProviderAddressById() external {
        vm.prank(owner);
        registry.registerAddressesProvider(provider1, 1);
        
        registry.getAddressesProviderAddressById(1);
        vm.snapshotGasLastCall('PoolAddressesProviderRegistry', 'getAddressesProviderAddressById');
    }
    
    function test_getAddressesProviderAddressById_notRegistered() external {
        registry.getAddressesProviderAddressById(999);
        vm.snapshotGasLastCall('PoolAddressesProviderRegistry', 'getAddressesProviderAddressById_notRegistered');
    }
}