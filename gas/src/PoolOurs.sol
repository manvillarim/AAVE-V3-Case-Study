// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {PoolInstance} from "ours/src/contracts/instances/PoolInstance.sol";
import {IPoolAddressesProvider} from "ours/src/contracts/interfaces/IPoolAddressesProvider.sol";

contract PoolOurs is PoolInstance {
    constructor(IPoolAddressesProvider provider) PoolInstance(provider) {}
}
