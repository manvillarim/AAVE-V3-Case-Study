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
  constructor(address owner)  {
    transferOwnership(owner);
  }

  /// @inheritdoc IPoolAddressesProviderRegistry
  function getAddressesProvidersList() external view override returns (address[] memory) {
    // RULE 27 - Use mappings instead of arrays for data lists
    // RULE 5 - Cache storage variables
    uint256 listSize = _addressesProvidersListSize;
    address[] memory providers = new address[](listSize);
    
    // RULE 26 - Use efficient loop increment (++ instead of +=1)
    for (uint256 i; i < listSize; ++i) {
      providers[i] = _addressesProvidersList[i];
    }
    
    return providers;
  }

  /// @inheritdoc IPoolAddressesProviderRegistry
  function registerAddressesProvider(address provider, uint256 id) external override onlyOwner {
    // RULE 1 - Replace require with custom errors
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
    // RULE 5 - Cache storage variables
    uint256 oldId = _addressesProviderToId[provider];
    if (oldId == 0) revert AddressesProviderNotRegistered();
    
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
  function _addToAddressesProvidersList(address provider) internal {
    // RULE 27 - Use mappings instead of arrays for data lists
    // RULE 5 - Cache storage variables
    uint256 currentSize = _addressesProvidersListSize;
    _addressesProvidersIndexes[provider] = currentSize;
    _addressesProvidersList[currentSize] = provider;
    unchecked{_addressesProvidersListSize++;}
  }

  /**
   * @notice Removes the addresses provider address from the list.
   * @param provider The address of the PoolAddressesProvider
   */
  function _removeFromAddressesProvidersList(address provider) internal {
    // RULE 27 - Use mappings instead of arrays for data lists
    uint256 index = _addressesProvidersIndexes[provider];
    _addressesProvidersIndexes[provider] = 0;

    // Swap the index of the last addresses provider in the list with the index of the provider to remove
    // RULE 5 - Cache storage variables
    uint256 lastIndex = _addressesProvidersListSize - 1;
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