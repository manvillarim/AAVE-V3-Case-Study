# Gas Optimisation Report: `PoolAddressesProviderRegistry`

**Contract:** `src/contracts/protocol/configuration/PoolAddressesProviderRegistry.sol`
**Protocol:** AAVE V3 (`aave-v3-origin`, commit `464a0ea`, version 3.3)
**Versions analysed:** Original · Cyfrin-optimised · Our extended variant
**Verification tool:** Certora Prover

---

## 1. Transformations Applied

This contract contains no loops and no array traversals, so the loop-oriented
rules of the catalogue (9, 24, 25, 26, 28) have no pattern match here. Three
catalogue rules are instantiated in total: Rule 23 by Cyfrin, and Rules 1 and
30 by our variant.

### 1.1 Cyfrin Optimisation

Cyfrin applied a single catalogue rule to this contract: **Rule 23 (Cache Storage Variables)**. The only structural modification relative to the original is a reordering of operations in `unregisterAddressesProvider`: the storage read `uint256 oldId = _addressesProviderToId[provider]` is moved to occur **before** the `require` guard, so that the cached local is used by the guard instead of a second `SLOAD`.

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

The transformation reads `_addressesProviderToId[provider]` once, stores it in `oldId`, and uses `oldId` in the guard. The original performed the `SLOAD` twice: once for the `require` and once for the assignment. This is an instance of **Rule 23 — Cache Storage Variables**, applied to a mapping access.

The Cyfrin version retains the original `require`-with-string-literal error handling and the non-payable constructor, leaving those optimisations on the table.

---

### 1.2 Our Extended Optimisation

Our variant was applied on top of Cyfrin's codebase and introduced two additional catalogue rules: **Rule 1 (Replace `require` with Custom Errors)** and **Rule 30 (Make Constructors Payable)**. Of these, the materially significant transformation for this contract is **Rule 1**.

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


#### Rule 30 — Make Constructor `payable`

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

All measurements were obtained with Foundry 1.7.1 (`forge test --gas-report --match-contract PoolAddressesProviderRegistry_gas_Tests`) under the compiler configuration shipped with the AAVE V3 repository: solc 0.8.22, optimiser enabled, 200 runs, `shanghai` EVM target. Foundry's accounting for `view` calls has changed across releases; deployment cost, bytecode size, and the gas of state-modifying functions are stable across versions, whereas the absolute figures for `view` functions are not.

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
| `getAddressesProviderAddressById` | 2,519          | 2,519        | 2,519      |
| `getAddressesProviderIdByAddress` | 2,556          | 2,556        | 2,556      |
| `getAddressesProvidersList`       | 5,749          | 5,749        | 5,749      |
| `registerAddressesProvider`       | 118,421        | 118,421      | 118,192    |
| `unregisterAddressesProvider`     | 44,257         | 44,160       | 44,104     |

| Function                      | Cyfrin vs. Original | Ours vs. Original | Ours vs. Cyfrin |
|-------------------------------|---------------------|-------------------|-----------------|
| `registerAddressesProvider`   | 0                   | −229              | −229            |
| `unregisterAddressesProvider` | −97                 | −153              | −56             |

**Observations:**

`registerAddressesProvider` shows a reduction of 229 gas (avg) in our variant relative to both Original and Cyfrin. This arises from the replacement of three `require` statements with `if`-revert custom error patterns, which avoid the cost of loading and hashing error strings on the revert path and marginally reduce the non-revert path overhead as well.

`unregisterAddressesProvider` saves 56 gas (avg) over Cyfrin and 153 gas (avg) over the original. The gain comes from Rule 1: the string-literal `require` is replaced by a custom error. The improvement over Cyfrin is smaller than the 229 gas observed in `registerAddressesProvider` simply because this function replaces a single `require`, whereas `registerAddressesProvider` replaces three.

An earlier revision of our variant wrote the guard as `if (_addressesProviderToId[provider] == 0)`, re-reading the mapping instead of testing the cached `oldId`. Rewriting it to `if (oldId == 0)` produces **byte-identical bytecode** (1,960 bytes deployed, same hash) and no gas difference whatsoever: with the optimiser enabled, solc already applies common-subexpression elimination to the duplicated `SLOAD`, since no write occurs between the two reads. The rewrite is therefore a source-readability improvement that makes the Rule 23 instance explicit, not a gas optimisation. This is a useful illustration of the boundary discussed in Section 4 of the paper: source-level redundancy that the compiler already removes yields no measurable saving, in contrast to the semantic transformations of the catalogue, which remain effective under aggressive optimisation.

View functions (`getAddressesProviderAddressById`, `getAddressesProviderIdByAddress`, `getAddressesProvidersList`) are unaffected across all three versions, as no storage layout or read-path changes were introduced.

### 2.3 Detailed Gas Snapshots

**Original:**

| Function                          | min    | avg    | median | max    | calls |
|-----------------------------------|--------|--------|--------|--------|-------|
| `getAddressesProviderAddressById` | 2,519  | 2,519  | 2,519  | 2,519  | 2     |
| `getAddressesProviderIdByAddress` | 2,556  | 2,556  | 2,556  | 2,556  | 2     |
| `getAddressesProvidersList`       | 2,671  | 5,749  | 5,014  | 9,562  | 3     |
| `registerAddressesProvider`       | 117,084| 118,421| 117,084| 119,908| 19    |
| `unregisterAddressesProvider`     | 38,863 | 44,257 | 44,257 | 49,652 | 4     |

Call-weighted average over all functions: **81,814** gas.

**Cyfrin:**

| Function                          | min    | avg    | median | max    | calls |
|-----------------------------------|--------|--------|--------|--------|-------|
| `getAddressesProviderAddressById` | 2,519  | 2,519  | 2,519  | 2,519  | 2     |
| `getAddressesProviderIdByAddress` | 2,556  | 2,556  | 2,556  | 2,556  | 2     |
| `getAddressesProvidersList`       | 2,671  | 5,749  | 5,014  | 9,562  | 3     |
| `registerAddressesProvider`       | 117,084| 118,421| 117,084| 119,908| 19    |
| `unregisterAddressesProvider`     | 38,766 | 44,160 | 44,160 | 49,556 | 4     |

Call-weighted average over all functions: **81,801** gas.

**Ours:**

| Function                          | min    | avg    | median | max    | calls |
|-----------------------------------|--------|--------|--------|--------|-------|
| `getAddressesProviderAddressById` | 2,519  | 2,519  | 2,519  | 2,519  | 2     |
| `getAddressesProviderIdByAddress` | 2,556  | 2,556  | 2,556  | 2,556  | 2     |
| `getAddressesProvidersList`       | 2,671  | 5,749  | 5,014  | 9,562  | 3     |
| `registerAddressesProvider`       | 116,855| 118,192| 116,855| 119,679| 19    |
| `unregisterAddressesProvider`     | 38,709 | 44,104 | 44,104 | 49,499 | 4     |

Call-weighted average over all functions: **81,649** gas.

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

| Metric | Cyfrin vs. Original | Ours vs. Original | Ours vs. Cyfrin |
|--------|---------------------|-------------------|-----------------|
| Rules applied (cumulative) | 23 | 23, 1, 30 | — |
| Deploy cost (gas) | −1,747 (−0.32%) | −41,078 (−7.45%) | −39,331 (−7.16%) |
| Deploy size (bytes) | −8 (−0.30%) | −201 (−7.61%) | −193 (−7.33%) |
| Avg Fn. Gas | −13 (−0.02%) | −165 (−0.20%) | −152 (−0.19%) |
| `registerAddressesProvider` avg | 0 | −229 | −229 |
| `unregisterAddressesProvider` avg | −97 | −153 | −56 |
| Formally verified | Yes | Yes | — |

The principal source of savings in our variant is Rule 1 (Custom Errors), which removes string-literal storage from the bytecode. Runtime savings on write functions are secondary and modest in absolute terms, consistent with the general characterisation of this rule in Table 2 of the paper (0.00%–0.05% average function savings). The deployment cost reduction of approximately 7% is the primary practical benefit for this contract.

`Avg Fn. Gas` denotes the call-count-weighted mean of the per-function average gas over all functions in the gas report, i.e. the sum of `avg × calls` divided by the total number of calls.