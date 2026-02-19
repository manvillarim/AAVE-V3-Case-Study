// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Ownable} from '../../dependencies/openzeppelin/contracts/Ownable.sol';
import {IPoolAddressesProviderRegistry} from '../../interfaces/IPoolAddressesProviderRegistry.sol';

/**
 * @title PoolAddressesProviderRegistry
 * @author Aave
 * @notice Main registry of PoolAddressesProvider of Aave markets.
 * @dev Used for indexing purposes of Aave protocol's markets. The id assigned to a PoolAddressesProvider refers to the
 * market it is connected with, for example with `1` for the Aave main market and `2` for the next created.
 */
contract PoolAddressesProviderRegistry is Ownable, IPoolAddressesProviderRegistry {
  // RULE 1 - Replace require with custom errors
  error InvalidAddressesProviderId();
  error AddressesProviderAlreadyAdded();
  error AddressesProviderNotRegistered();

  // Map of address provider ids (addressesProvider => id)
  mapping(address => uint256) private _addressesProviderToId;
  // Map of id to address provider (id => addressesProvider)
  mapping(uint256 => address) private _idToAddressesProvider;
  
  // RULE 27 - Use mappings instead of arrays for data lists
  // Replaced: address[] private _addressesProvidersList;
  mapping(uint256 => address) private _addressesProvidersList;
  uint256 private _addressesProvidersListSize;
  
  // Map of address provider list indexes (addressesProvider => indexInList)
  mapping(address => uint256) private _addressesProvidersIndexes;

  /**
   * @dev Constructor.
   * @param owner The owner address of this contract.
   */
  // RULE 31 - Make Constructors Payable
  constructor(address owner) payable {
    transferOwnership(owner);
  }

  /// @inheritdoc IPoolAddressesProviderRegistry
  function getAddressesProvidersList() external view override returns (address[] memory) {
    // RULE 27 - Use mappings instead of arrays for data lists
    // RULE 5 - Cache storage variables
    uint256 listSize = _addressesProvidersListSize;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000002,listSize)}
    address[] memory providers = new address[](listSize);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010003,0)}
    
    // RULE 26 - Use efficient loop increment (++ instead of +=1)
    for (uint256 i; i < listSize; ++i) {
      providers[i] = _addressesProvidersList[i];address certora_local8 = providers[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000008,certora_local8)}
    }
    
    return providers;
  }

  /// @inheritdoc IPoolAddressesProviderRegistry
  function registerAddressesProvider(address provider, uint256 id) external override onlyOwner {
    // RULE 1 - Replace require with custom errors
    // Maintain exact same order as original for equivalence
    if (id == 0) revert InvalidAddressesProviderId();
    if (_idToAddressesProvider[id] != address(0)) revert InvalidAddressesProviderId();
    if (_addressesProviderToId[provider] != 0) revert AddressesProviderAlreadyAdded();

    _addressesProviderToId[provider] = id;
    _idToAddressesProvider[id] = provider;

    _addToAddressesProvidersList(provider);
    emit AddressesProviderRegistered(provider, id);
  }

  /// @inheritdoc IPoolAddressesProviderRegistry
  function unregisterAddressesProvider(address provider) external override onlyOwner {
    // RULE 1 - Replace require with custom errors
    // Maintain exact same order as original: check FIRST, then read
    if (_addressesProviderToId[provider] == 0) revert AddressesProviderNotRegistered();
    uint256 oldId = _addressesProviderToId[provider];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000004,oldId)}
    
    _idToAddressesProvider[oldId] = address(0);
    _addressesProviderToId[provider] = 0;

    _removeFromAddressesProvidersList(provider);

    emit AddressesProviderUnregistered(provider, oldId);
  }

  /// @inheritdoc IPoolAddressesProviderRegistry
  function getAddressesProviderIdByAddress(
    address addressesProvider
  ) external view override returns (uint256) {
    return _addressesProviderToId[addressesProvider];
  }

  /// @inheritdoc IPoolAddressesProviderRegistry
  function getAddressesProviderAddressById(uint256 id) external view override returns (address) {
    return _idToAddressesProvider[id];
  }

  /**
   * @notice Adds the addresses provider address to the list.
   * @param provider The address of the PoolAddressesProvider
   */
  function _addToAddressesProvidersList(address provider) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00070000, 1037618708487) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00070001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00071000, provider) }
    // RULE 27 - Use mappings instead of arrays for data lists
    // RULE 5 - Cache storage variables
    uint256 currentSize = _addressesProvidersListSize;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000005,currentSize)}
    _addressesProvidersIndexes[provider] = currentSize;
    _addressesProvidersList[currentSize] = provider;
    unchecked {
      _addressesProvidersListSize++; // Using unchecked to match array.push() in older Solidity or for gas optimization
    }
  }

  /**
   * @notice Removes the addresses provider address from the list.
   * @param provider The address of the PoolAddressesProvider
   */
  function _removeFromAddressesProvidersList(address provider) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00080000, 1037618708488) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00080001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00081000, provider) }
    // RULE 27 - Use mappings instead of arrays for data lists
    uint256 index = _addressesProvidersIndexes[provider];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000006,index)}
    _addressesProvidersIndexes[provider] = 0;

    // Swap the index of the last addresses provider in the list with the index of the provider to remove
    // RULE 5 - Cache storage variables
    uint256 lastIndex = _addressesProvidersListSize - 1;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000007,lastIndex)}
    if (index < lastIndex) {
      address lastProvider = _addressesProvidersList[lastIndex];
      _addressesProvidersList[index] = lastProvider;
      _addressesProvidersIndexes[lastProvider] = index;
    }
    delete _addressesProvidersList[lastIndex];
    unchecked {
      _addressesProvidersListSize--; // Safe decrement after bounds check
    }
  }
}