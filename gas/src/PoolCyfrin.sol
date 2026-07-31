// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {PoolInstance} from "cyfrin/src/contracts/instances/PoolInstance.sol";
import {IPoolAddressesProvider} from "cyfrin/src/contracts/interfaces/IPoolAddressesProvider.sol";

contract PoolCyfrin is PoolInstance {
    constructor(IPoolAddressesProvider provider) PoolInstance(provider) {}
}
