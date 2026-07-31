// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

contract MockAddressesProvider {
    fallback() external {
        assembly {
            mstore(0, 0)
            return(0, 32)
        }
    }
}
