// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;


import {PoolAddressesProviderRegistry} from "aave-v3-origin-optimized-instr/src/contracts/protocol/configuration/PoolAddressesProviderRegistry.sol";

contract RegistryOptimized is PoolAddressesProviderRegistry {
    constructor(address owner) payable PoolAddressesProviderRegistry(owner) {}

    uint256 public emitCount;
    bytes32 public emitDigest;

    address public lastRegisteredProvider;
    uint256 public lastRegisteredId;
    address public lastUnregisteredProvider;
    uint256 public lastUnregisteredId;

    function _recordAddressesProviderRegistered(
        address provider,
        uint256 id
    ) internal override {
        lastRegisteredProvider = provider;
        lastRegisteredId = id;
        unchecked {
            emitCount = emitCount + 1;
        }
        emitDigest = keccak256(
            abi.encode(emitDigest, "AddressesProviderRegistered", provider, id)
        );
    }

    function _recordAddressesProviderUnregistered(
        address provider,
        uint256 id
    ) internal override {
        lastUnregisteredProvider = provider;
        lastUnregisteredId = id;
        unchecked {
            emitCount = emitCount + 1;
        }
        emitDigest = keccak256(
            abi.encode(emitDigest, "AddressesProviderUnregistered", provider, id)
        );
    }
}
