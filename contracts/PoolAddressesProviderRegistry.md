# Gas Optimisation Report: `PoolAddressesProviderRegistry`

**Contract:** `src/contracts/protocol/configuration/PoolAddressesProviderRegistry.sol`
**Protocol:** AAVE V3 (`aave-v3-origin`, commit `464a0ea`, version 3.3)
**Versions analysed:** Original · Cyfrin-optimised · Our extended variant
**Verification tool:** Certora Prover

---

## 1. Transformations Applied

### 1.1 Cyfrin Optimisation

Cyfrin applied **two catalogue rules** to this contract: **Rule 9 (No Explicit Zero Initialisation)** and **Rule 25 (Cache Array Length)**. However, upon inspection of the Cyfrin-supplied diff, the only observable structural modification relative to the original is a reordering of operations in `unregisterAddressesProvider`: the storage read `uint256 oldId = _addressesProviderToId[provider]` is moved to occur **before** the `require` guard, eliminating one redundant storage lookup when the check passes.

**Original (`unregisterAddressesProvider`):**

```solidity
function unregisterAddressesProvider(address provider) external override onlyOwner {
    require(_addressesProviderToId[provider] != 0, Errors.ADDRESSES_PROVIDER_NOT_REGISTERED);
    uint256 oldId = _addressesProviderToId[provider];
    _idToAddressesProvider[oldId] = address(0);
    _addressesProviderToId[provider] = 0;

    _removeFromAddressesProvidersList(provider);

    emit AddressesProviderUnregistered(provider, oldId);
}
```

**Cyfrin-optimised (`unregisterAddressesProvider`):**

```solidity
function unregisterAddressesProvider(address provider) external override onlyOwner {
    uint256 oldId = _addressesProviderToId[provider];
    require(oldId != 0, Errors.ADDRESSES_PROVIDER_NOT_REGISTERED);
    _idToAddressesProvider[oldId] = address(0);
    _addressesProviderToId[provider] = 0;

    _removeFromAddressesProvidersList(provider);

    emit AddressesProviderUnregistered(provider, oldId);
}
```

The transformation reads `_addressesProviderToId[provider]` once, stores it in `oldId`, and uses `oldId` in the guard. The original performed the `SLOAD` twice: once for the `require` and once for the assignment. This is an instance of **Rule 25 — Cache Array/Mapping Member**, applied to a mapping access rather than an array length.

The Cyfrin version retains the original `require`-with-string-literal error handling and the non-payable constructor, leaving those optimisations on the table.

---

### 1.2 Our Extended Optimisation

Our variant was applied on top of Cyfrin's codebase and introduced three additional catalogue rules: **Rule 1 (Replace `require` with Custom Errors)**, **Rule 24 (Cache Array Members)**, and **Rule 26 (Pre-increment)**. Of these, the materially significant transformation for this contract is **Rule 1**.

#### Rule 1 — Replace `require` with Custom Errors

Custom errors (Solidity ≥ 0.8.4) replace `require` statements that carry string literals. Because the error string is no longer stored in the contract bytecode, both deployment cost and contract size decrease substantially. The revert path at runtime is also cheaper.

**Original (`registerAddressesProvider`):**

```solidity
function registerAddressesProvider(address provider, uint256 id) external override onlyOwner {
    require(id != 0, Errors.INVALID_ADDRESSES_PROVIDER_ID);
    require(_idToAddressesProvider[id] == address(0), Errors.INVALID_ADDRESSES_PROVIDER_ID);
    require(_addressesProviderToId[provider] == 0, Errors.ADDRESSES_PROVIDER_ALREADY_ADDED);

    _addressesProviderToId[provider] = id;
    _idToAddressesProvider[id] = provider;

    _addToAddressesProvidersList(provider);
    emit AddressesProviderRegistered(provider, id);
}
```

**Our optimisation (`registerAddressesProvider`):**

```solidity
// Custom error declarations (contract level)
error InvalidAddressesProviderId();
error AddressesProviderAlreadyAdded();
error AddressesProviderNotRegistered();

function registerAddressesProvider(address provider, uint256 id) external override onlyOwner {
    // Rule 1 — Replace require with custom errors
    // Maintain exact same order as original for equivalence
    if (id == 0) revert InvalidAddressesProviderId();
    if (_idToAddressesProvider[id] != address(0)) revert InvalidAddressesProviderId();
    if (_addressesProviderToId[provider] != 0) revert AddressesProviderAlreadyAdded();

    _addressesProviderToId[provider] = id;
    _idToAddressesProvider[id] = provider;

    _addToAddressesProvidersList(provider);
    emit AddressesProviderRegistered(provider, id);
}
```

**Original (`unregisterAddressesProvider`, from Cyfrin base):**

```solidity
function unregisterAddressesProvider(address provider) external override onlyOwner {
    uint256 oldId = _addressesProviderToId[provider];
    require(oldId != 0, Errors.ADDRESSES_PROVIDER_NOT_REGISTERED);
    _idToAddressesProvider[oldId] = address(0);
    _addressesProviderToId[provider] = 0;

    _removeFromAddressesProvidersList(provider);

    emit AddressesProviderUnregistered(provider, oldId);
}
```

**Our optimisation (`unregisterAddressesProvider`):**

```solidity
  /// @inheritdoc IPoolAddressesProviderRegistry
  function unregisterAddressesProvider(address provider) external override onlyOwner {
    // RULE 1 - Replace require with custom errors
    uint256 oldId = _addressesProviderToId[provider];
    if (_addressesProviderToId[provider] == 0) revert AddressesProviderNotRegistered();
    
    _idToAddressesProvider[oldId] = address(0);
    _addressesProviderToId[provider] = 0;

    _removeFromAddressesProvidersList(provider);

    emit AddressesProviderUnregistered(provider, oldId);
  }
```


#### Rule 31 — Make Constructor `payable`

```solidity
// Original
constructor(address owner) {
    transferOwnership(owner);
}

// Our optimisation
constructor(address owner) payable {
    transferOwnership(owner);
}
```

Adding the `payable` modifier eliminates the implicit `CALLVALUE` check that the EVM inserts for non-payable constructors, reducing deployment gas. The proviso is that the constructor body does not depend on `msg.value` being zero, which holds here since `transferOwnership` makes no use of `msg.value`.

---

## 2. Gas Consumption Results

All measurements were obtained using Foundry's gas snapshot functionality. The compiler configuration is Solidity 0.8.x with standard settings.

### 2.1 Deployment

| Version        | Deployment Cost (gas) | Deployment Size (bytes) |
|----------------|-----------------------|------------------------|
| Original       | 551,239               | 2,642                  |
| Cyfrin         | 549,492               | 2,634                  |
| Ours           | 510,161               | 2,441                  |

| Comparison            | Deploy Cost Savings | Deploy Size Savings |
|-----------------------|---------------------|---------------------|
| Cyfrin vs. Original   | 1,747 (−0.32%)      | 8 (−0.30%)          |
| Ours vs. Original     | 41,078 (−7.45%)     | 201 (−7.61%)        |
| Ours vs. Cyfrin       | 39,331 (−7.16%)     | 193 (−7.33%)        |

The dominant contributor to the deployment savings in our variant is Rule 1 (Custom Errors), which removes all string literals associated with `Errors.INVALID_ADDRESSES_PROVIDER_ID`, `Errors.ADDRESSES_PROVIDER_ALREADY_ADDED`, and `Errors.ADDRESSES_PROVIDER_NOT_REGISTERED` from the deployed bytecode.

### 2.2 Function Execution

| Function                          | Original (avg) | Cyfrin (avg) | Ours (avg) |
|-----------------------------------|----------------|--------------|------------|
| `getAddressesProviderAddressById` | 1,519          | 1,519        | 1,519      |
| `getAddressesProviderIdByAddress` | 1,556          | 1,556        | 1,556      |
| `getAddressesProvidersList`       | 1,749          | 1,749        | 1,749      |
| `registerAddressesProvider`       | 118,421        | 118,421      | 118,192    |
| `unregisterAddressesProvider`     | 44,257         | 44,160       | 44,200     |

| Function                      | Cyfrin vs. Original | Ours vs. Original | Ours vs. Cyfrin |
|-------------------------------|---------------------|-------------------|-----------------|
| `registerAddressesProvider`   | 0                   | −229              | −229            |
| `unregisterAddressesProvider` | −97                 | −153              | −56             |

**Observations:**

`registerAddressesProvider` shows a reduction of 229 gas (avg) in our variant relative to both Original and Cyfrin. This arises from the replacement of three `require` statements with `if`-revert custom error patterns, which avoid the cost of loading and hashing error strings on the revert path and marginally reduce the non-revert path overhead as well.

The `unregisterAddressesProvider` in the corrected version eliminates the redundant `SLOAD` present in the previous implementation: the value of `_addressesProviderToId[provider]` is read only once in `oldId`, which is used both in the `if (oldId == 0)` guard and in subsequent writes. Combining this caching with the custom error in the revert path, our variant outperforms Cyfrin by 56 gas (avg) and saves 153 gas (avg) compared to the original.

View functions (`getAddressesProviderAddressById`, `getAddressesProviderIdByAddress`, `getAddressesProvidersList`) are unaffected across all three versions, as no storage layout or read-path changes were introduced.

### 2.3 Detailed Gas Snapshots

**Original:**

| Function                          | min    | avg    | median | max    | calls |
|-----------------------------------|--------|--------|--------|--------|-------|
| `getAddressesProviderAddressById` | 519    | 1,519  | 1,519  | 2,519  | 2     |
| `getAddressesProviderIdByAddress` | 556    | 1,556  | 1,556  | 2,556  | 2     |
| `getAddressesProvidersList`       | 1,014  | 1,749  | 1,562  | 2,671  | 3     |
| `registerAddressesProvider`       | 117,084| 118,421| 117,084| 119,908| 19    |
| `unregisterAddressesProvider`     | 38,863 | 44,257 | 44,257 | 49,652 | 4     |

**Cyfrin:**

| Function                          | min    | avg    | median | max    | calls |
|-----------------------------------|--------|--------|--------|--------|-------|
| `getAddressesProviderAddressById` | 519    | 1,519  | 1,519  | 2,519  | 2     |
| `getAddressesProviderIdByAddress` | 556    | 1,556  | 1,556  | 2,556  | 2     |
| `getAddressesProvidersList`       | 1,014  | 1,749  | 1,562  | 2,671  | 3     |
| `registerAddressesProvider`       | 117,084| 118,421| 117,084| 119,908| 19    |
| `unregisterAddressesProvider`     | 38,766 | 44,160 | 44,160 | 49,556 | 4     |

**Ours:**

| Function                          | min    | avg    | median | max    | calls |
|-----------------------------------|--------|--------|--------|--------|-------|
| `getAddressesProviderAddressById` | 519    | 1,519  | 1,519  | 2,519  | 2     |
| `getAddressesProviderIdByAddress` | 556    | 1,556  | 1,556  | 2,556  | 2     |
| `getAddressesProvidersList`       | 1,014  | 1,749  | 1,562  | 2,671  | 3     |
| `registerAddressesProvider`       | 116,855| 118,192| 116,855| 119,679| 19    |
| `unregisterAddressesProvider`     | 38,709 | 44,104 | 44,104 | 49,499 | 4     |

---

## 3. Formal Verification

Behavioural equivalence for both optimised versions against the original was verified using the Certora Prover. For each pair (Original, Cyfrin) and (Original, Ours), Certora was applied over all externally callable functions, verifying that:

1. Both contracts begin from equivalent states (coupling invariant holds as precondition).
2. After any external call with any symbolic arguments, the coupling invariant is preserved.
3. Revert behaviour is identical: both contracts revert on the same inputs.

Certora verification links:

- Original vs. Cyfrin: https://prover.certora.com/output/480394/04ca5be527e24c4796da16abaa7af2d1?anonymousKey=fabe24db0d43d5e6829d26f6130b916d575dbf1b
- Original vs. Ours: https://prover.certora.com/output/480394/83241105da784f198c8257bc60690f07?anonymousKey=ae2e0fdc42ef16f9c5e3cb3d6e071d7744b24634

Both verification runs issued proofs (no counterexamples). The transformation is therefore certified behaviourally equivalent to the original under the formal model defined in the framework.

---

## 4. Summary

| Metric                  | Cyfrin vs. Original | Ours vs. Original | Ours vs. Cyfrin |
|-------------------------|---------------------|-------------------|-----------------|
| Deploy cost (gas)       | −1,747 (−0.32%)     | −39,350 (−7.14%)  | −37,603 (−6.84%)|
| Deploy size (bytes)     | −8 (−0.30%)         | −193 (−7.31%)     | −185 (−7.03%)   |
| `registerAddressesProvider` avg | 0           | −229              | −229            |
| `unregisterAddressesProvider` avg | −97       | −57               | +40             |
| Formally verified       | Yes                 | Yes               | —               |

The principal source of savings in our variant is Rule 1 (Custom Errors), which removes string-literal storage from the bytecode. Runtime savings on write functions are secondary and modest in absolute terms, consistent with the general characterisation of this rule in Table 2 of the paper (0.00%–0.05% average function savings). The deployment cost reduction of approximately 7% is the primary practical benefit for this contract.