// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {PoolInstance} from "origin/src/contracts/instances/PoolInstance.sol";
import {IPoolAddressesProvider} from "origin/src/contracts/interfaces/IPoolAddressesProvider.sol";

contract PoolOrigin is PoolInstance {
    constructor(IPoolAddressesProvider provider) PoolInstance(provider) {}
}
