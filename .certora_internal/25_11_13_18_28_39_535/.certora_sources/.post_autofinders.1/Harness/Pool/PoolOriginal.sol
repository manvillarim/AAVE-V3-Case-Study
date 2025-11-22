// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Pool} from "../../aave-v3-origin/src/contracts/protocol/pool/Pool.sol";
import {IPoolAddressesProvider} from "../../aave-v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol";

contract PoolOriginal is Pool {
    constructor(IPoolAddressesProvider provider) Pool(provider) {}

    function getRevision() internal pure virtual override returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a10000, 1037618708641) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a10001, 0) }
        return 0x1;
    }

    function initialize(IPoolAddressesProvider provider) external virtual override initializer {
        require(provider == ADDRESSES_PROVIDER, 'INVALID_ADDRESSES_PROVIDER');
        _flashLoanPremiumTotal = 0.0009e4;
        _flashLoanPremiumToProtocol = 0;
    }
}
