// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;


import {PoolAddressesProviderRegistry} from "../../aave-v3-origin-liquidation-gas-fixes/src/contracts/protocol/configuration/PoolAddressesProviderRegistry.sol";

contract RegistryOptimized is PoolAddressesProviderRegistry {
    constructor(address owner) PoolAddressesProviderRegistry(owner) {}
}