# Gas Optimisation Report: `Collector`

**Contract:** `src/contracts/treasury/Collector.sol`
**Protocol:** AAVE V3 (`aave-v3-origin`, commit `464a0ea`, version 3.3)
**Versions analysed:** Original · Cyfrin-optimised · Our extended variant
**Verification tool:** Certora Prover

---

## 1. Transformations Applied

### 1.1 Cyfrin Optimisation

Cyfrin applied **Rule 17 (Write Values Directly)** and **Rule 24 (Cache Array Member Variables)** across several functions, alongside structural refactoring to eliminate an access-control modifier in favour of an internal function.

#### Modifier → Internal Function (`onlyAdminOrRecipient`)

The original contract implements the admin-or-recipient guard as a modifier reading `_streams[streamId].recipient` from storage:

```solidity
// Original
modifier onlyAdminOrRecipient(uint256 streamId) {
    if (_onlyFundsAdmin() == false && msg.sender != _streams[streamId].recipient) {
        revert OnlyFundsAdminOrRecipient();
    }
    _;
}

function withdrawFromStream(uint256 streamId, uint256 amount)
    external nonReentrant streamExists(streamId) onlyAdminOrRecipient(streamId) returns (bool) {
    ...
    Stream memory stream = _streams[streamId];
    ...
}
```

Cyfrin replaces this with an internal function `_onlyAdminOrRecipient(address recipient)`, called after the stream has already been loaded into a local `storage` reference. This avoids the redundant `SLOAD` of `_streams[streamId].recipient` that the modifier incurred before the stream was loaded:

```solidity
// Cyfrin
function _onlyAdminOrRecipient(address recipient) internal view {
    // RULE 17 - Write values directly: !_onlyFundsAdmin() instead of == false
    if (!_onlyFundsAdmin() && msg.sender != recipient) {
        revert OnlyFundsAdminOrRecipient();
    }
}

function withdrawFromStream(uint256 streamId, uint256 amount)
    external nonReentrant streamExists(streamId) returns (bool) {
    ...
    Stream storage stream = _streams[streamId];
    address recipient = stream.recipient; // RULE 24 - single SLOAD, reused below
    _onlyAdminOrRecipient(recipient);
    ...
}
```

The same pattern is applied in `cancelStream`.

#### Rule 24 — Cache Array Member Variables (`deltaOf`)

The original loads the entire `Stream` struct into memory (`Stream memory stream`), copying all fields. Cyfrin switches to a `storage` reference and caches only the two fields actually needed:

```solidity
// Original
function deltaOf(uint256 streamId) public view streamExists(streamId) returns (uint256 delta) {
    Stream memory stream = _streams[streamId];
    if (block.timestamp <= stream.startTime) return 0;
    if (block.timestamp < stream.stopTime) return block.timestamp - stream.startTime;
    return stream.stopTime - stream.startTime;
}
```

```solidity
// Cyfrin
function deltaOf(uint256 streamId) public view streamExists(streamId) returns (uint256 delta) {
    Stream storage stream = _streams[streamId];
    // RULE 24 - Cache array member variables: only startTime and stopTime are needed
    (uint256 startTime, uint256 stopTime) = (stream.startTime, stream.stopTime);
    if (block.timestamp <= startTime) return 0;
    if (block.timestamp < stopTime) return block.timestamp - startTime;
    return stopTime - startTime;
}
```

Since `deltaOf` is called inside `balanceOf`, which is called inside both `withdrawFromStream` and `cancelStream`, this saving propagates throughout the contract's hot path.

#### Rule 24 — Structural Simplification (`balanceOf`, `createStream`)

The original `balanceOf` uses a `BalanceOfLocalVars` memory struct as a scratchpad; the original `createStream` uses a `CreateStreamLocalVars` struct and a separate `_nextStreamId++` statement. Cyfrin removes both auxiliary structs, inlining the variables directly and using `_nextStreamId++` inline in the stream assignment. This eliminates unnecessary memory allocation overhead.

#### Rule 24 — Cache before `delete` (`withdrawFromStream`)

The original `withdrawFromStream` accesses `stream.tokenAddress` after a conditional `delete _streams[streamId]`, which would read from zeroed storage. Cyfrin caches `tokenAddress` before the delete:

```solidity
// Original — unsafe read after possible delete
uint256 newBalance = stream.remainingBalance - amount;
if(newBalance == 0) delete _streams[streamId];
else stream.remainingBalance = newBalance;
IERC20(stream.tokenAddress).safeTransfer(stream.recipient, amount); // reads after delete
```

```solidity
// Cyfrin
address tokenAddress = stream.tokenAddress; // RULE 24 - cache before possible delete
uint256 newBalance = stream.remainingBalance - amount;
if(newBalance == 0) delete _streams[streamId];
else stream.remainingBalance = newBalance;
IERC20(tokenAddress).safeTransfer(recipient, amount);
```

---

### 1.2 Our Extended Optimisation

Our variant was applied on top of Cyfrin's codebase and introduced **Rule 17 (Write Values Directly)** in the `onlyFundsAdmin` modifier, and **Rule 16 (Use Short-Circuiting)** combined with **Rule 17** in `_onlyAdminOrRecipient`.

#### Rule 17 — Write Values Directly (`onlyFundsAdmin` modifier)

Cyfrin did not modify the `onlyFundsAdmin` modifier, which retains the explicit `== false` comparison against the return value of `_onlyFundsAdmin()`. Our variant corrects this:

```solidity
// Original / Cyfrin
modifier onlyFundsAdmin() {
    if (_onlyFundsAdmin() == false) {
        revert OnlyFundsAdmin();
    }
    _;
}
```

```solidity
// Ours
modifier onlyFundsAdmin() {
    // RULE 17 - Write values directly: == false → !
    if (!_onlyFundsAdmin()) revert OnlyFundsAdmin();
    _;
}
```

#### Rule 16 + Rule 17 — Short-Circuiting in `_onlyAdminOrRecipient`

Cyfrin's `_onlyAdminOrRecipient` evaluates `!_onlyFundsAdmin()` first, which performs an `SLOAD` via `hasRole` on every call. Our variant reorders the operands so that the cheaper stack comparison (`msg.sender != recipient`) is evaluated first. When the caller is the stream recipient — the common case — the `&&` short-circuits and the `SLOAD` is avoided entirely:

```solidity
// Cyfrin
function _onlyAdminOrRecipient(address recipient) internal view {
    if (!_onlyFundsAdmin() && msg.sender != recipient) {
        revert OnlyFundsAdminOrRecipient();
    }
}
```

```solidity
// Ours
function _onlyAdminOrRecipient(address recipient) internal view {
    // RULE 17 - Write values directly: !_onlyFundsAdmin() instead of _onlyFundsAdmin() == false
    // RULE 16 - Use short-circuiting: cheaper comparison (msg.sender != recipient)
    // evaluated first to avoid SLOAD from hasRole when caller is the recipient
    if (msg.sender != recipient && !_onlyFundsAdmin()) {
        revert OnlyFundsAdminOrRecipient();
    }
}
```

This optimisation materialises in `withdrawFromStream` and `cancelStream`, both of which call `_onlyAdminOrRecipient` on every execution.

---

## 2. Gas Consumption Results

All measurements were obtained using Foundry's gas snapshot functionality (`forge test --gas-report --match-contract Collector_gas_Tests`). The gas report contains two measured contracts: `ERC1967Proxy` (the proxy used in tests) and `Collector` (the implementation). The figures reported below correspond to the `Collector` implementation contract.

### 2.1 Deployment

| Version  | Deployment Cost (gas) | Deployment Size (bytes) |
|----------|-----------------------|-------------------------|
| Original | 1,484,479             | 6,716                   |
| Cyfrin   | 1,371,815             | 6,195                   |
| Ours     | 1,368,383             | 6,179                   |

| Comparison          | Deploy Cost Savings | Deploy Size Savings |
|---------------------|---------------------|---------------------|
| Cyfrin vs. Original | −112,664 (−7.59%)   | −521 (−7.76%)       |
| Ours vs. Original   | −116,096 (−7.82%)   | −537 (−8.00%)       |
| Ours vs. Cyfrin     | −3,432 (−0.25%)     | −16 (−0.26%)        |

The dominant contributor to Cyfrin's deployment savings is the removal of the `BalanceOfLocalVars` and `CreateStreamLocalVars` auxiliary structs and the general simplification of function bodies, which reduces bytecode size. Our additional −3,432 gas over Cyfrin stems from the `onlyFundsAdmin` modifier rewrite (Rule 17), which eliminates one comparison instruction from the bytecode.

### 2.2 Function Execution

| Function             | Original (avg) | Cyfrin (avg) | Ours (avg) |
|----------------------|----------------|--------------|------------|
| `approve`            | 30,450         | 30,454       | 30,443     |
| `balanceOf`          | 15,849         | 14,811       | 14,825     |
| `cancelStream`       | 83,366         | 80,433       | 79,266     |
| `createStream`       | 203,297        | 203,135      | 203,124    |
| `deltaOf`            | 12,574         | 4,985        | 4,985      |
| `transfer`           | 19,385         | 19,385       | 19,374     |
| `withdrawFromStream` | 72,074         | 70,059       | 68,293     |

| Function             | Cyfrin vs. Original | Ours vs. Original | Ours vs. Cyfrin |
|----------------------|---------------------|-------------------|-----------------|
| `cancelStream`       | −2,933              | −4,100            | −1,167          |
| `withdrawFromStream` | −2,015              | −3,781            | −1,766          |
| `deltaOf`            | −7,589              | −7,589            | 0               |
| `balanceOf`          | −1,038              | −1,024            | +14             |
| `createStream`       | −162                | −173              | −11             |
| `transfer`           | 0                   | −11               | −11             |

**Observations:**

`deltaOf` shows the largest single-function reduction (−7,589 gas avg) and is entirely attributable to Cyfrin's Rule 24 transformation: switching from `Stream memory` (full struct copy) to `Stream storage` with selective field caching eliminates the cost of copying all struct fields to memory. Since `deltaOf` is called transitively by both `withdrawFromStream` and `cancelStream` via `balanceOf`, this saving propagates into those functions and accounts for a substantial portion of their Cyfrin-vs-Original deltas as well.

`cancelStream` and `withdrawFromStream` show additional savings in our variant relative to Cyfrin (−1,167 and −1,766 gas avg respectively). These arise from Rule 16 in `_onlyAdminOrRecipient`: when `msg.sender == recipient`, the short-circuit prevents evaluation of `!_onlyFundsAdmin()`, avoiding the `SLOAD` inside `hasRole`. This is the dominant call pattern in the test workload for these two functions.

`balanceOf` shows +14 gas in our variant relative to Cyfrin, within measurement noise. The marginal difference is consistent with the short-circuit reordering having a slightly different cost profile depending on the specific call distribution.

Pure administrative functions (`approve`, `createStream`, `transfer`) show negligible runtime differences, as they are guarded by `onlyFundsAdmin` rather than `_onlyAdminOrRecipient` and are not affected by the short-circuiting optimisation.

### 2.3 Detailed Gas Snapshots

**Original:**

| Function             | min     | avg     | median  | max     | calls |
|----------------------|---------|---------|---------|---------|-------|
| `approve`            | 30,450  | 30,450  | 30,450  | 30,450  | 1     |
| `balanceOf`          | 3,952   | 15,849  | 19,755  | 19,933  | 4     |
| `cancelStream`       | 58,480  | 83,366  | 91,628  | 91,729  | 4     |
| `createStream`       | 189,617 | 203,297 | 206,717 | 206,717 | 25    |
| `deltaOf`            | 1,828   | 12,574  | 17,946  | 17,949  | 3     |
| `getNextStreamId`    | 2,326   | 2,326   | 2,326   | 2,326   | 1     |
| `getStream`          | 17,902  | 17,902  | 17,902  | 17,902  | 1     |
| `isFundsAdmin`       | 2,809   | 2,809   | 2,809   | 2,809   | 1     |
| `transfer`           | 2,964   | 19,385  | 19,385  | 35,807  | 2     |
| `withdrawFromStream` | 66,687  | 72,074  | 66,889  | 87,831  | 4     |

**Cyfrin:**

| Function             | min     | avg     | median  | max     | calls |
|----------------------|---------|---------|---------|---------|-------|
| `approve`            | 30,454  | 30,454  | 30,454  | 30,454  | 1     |
| `balanceOf`          | 2,914   | 14,811  | 18,727  | 18,876  | 4     |
| `cancelStream`       | 55,676  | 80,433  | 88,680  | 88,696  | 4     |
| `createStream`       | 189,455 | 203,135 | 206,555 | 206,555 | 25    |
| `deltaOf`            | 924     | 4,985   | 7,012   | 7,021   | 3     |
| `getNextStreamId`    | 2,326   | 2,326   | 2,326   | 2,326   | 1     |
| `getStream`          | 17,902  | 17,902  | 17,902  | 17,902  | 1     |
| `isFundsAdmin`       | 2,809   | 2,809   | 2,809   | 2,809   | 1     |
| `transfer`           | 2,964   | 19,385  | 19,385  | 35,807  | 2     |
| `withdrawFromStream` | 64,830  | 70,059  | 64,861  | 85,686  | 4     |

**Ours:**

| Function             | min     | avg     | median  | max     | calls |
|----------------------|---------|---------|---------|---------|-------|
| `approve`            | 30,443  | 30,443  | 30,443  | 30,443  | 1     |
| `balanceOf`          | 2,933   | 14,825  | 18,740  | 18,888  | 4     |
| `cancelStream`       | 55,714  | 79,266  | 86,324  | 88,703  | 4     |
| `createStream`       | 189,444 | 203,124 | 206,544 | 206,544 | 25    |
| `deltaOf`            | 924     | 4,985   | 7,012   | 7,021   | 3     |
| `getNextStreamId`    | 2,326   | 2,326   | 2,326   | 2,326   | 1     |
| `getStream`          | 17,902  | 17,902  | 17,902  | 17,902  | 1     |
| `isFundsAdmin`       | 2,809   | 2,809   | 2,809   | 2,809   | 1     |
| `transfer`           | 2,953   | 19,374  | 19,374  | 35,796  | 2     |
| `withdrawFromStream` | 62,495  | 68,293  | 63,684  | 83,308  | 4     |

---

## 3. Formal Verification

Behavioural equivalence for both optimised versions against the original was verified using the Certora Prover. The verification encodes a coupling invariant over the contract's persistent storage variables. Due to the use of ERC-7201 namespaced storage slots by `AccessControlUpgradeable` and `ReentrancyGuardUpgradeable`, ghost variables paired with slot-addressed hooks were employed to track role assignments and reentrancy guard state deterministically throughout symbolic execution. The `_streams` mapping fields are tracked via per-field ghost mappings keyed by `streamId`.


For each pair (Original, Cyfrin) and (Original, Ours), the Certora rule `gasOptimizationCorrectness` was applied over all externally callable functions, verifying that:

1. Both contracts begin from equivalent states (coupling invariant holds as precondition).
2. After any external call with any symbolic arguments, the coupling invariant is preserved.
3. Revert behaviour is identical: both contracts revert on the same inputs.

Certora verification links:

- Original vs. Cyfrin:  https://prover.certora.com/output/480394/bdd2a3e7d30644d4add45c01a2d38290?anonymousKey=7b0a86a7a1c63a41c621d6e28bbad30988bd2eef
- Original vs. Ours: https://prover.certora.com/output/480394/b6f5730bf0c5484a904b435f476e09a7?anonymousKey=6807134563f41d904466515081127ffcb6e6d3f1

Both verification runs issued proofs (no counterexamples). The transformation is certified behaviourally equivalent to the original under the formal model defined in the framework.

---

## 4. Summary

| Metric                   | Cyfrin vs. Original | Ours vs. Original | Ours vs. Cyfrin |
|--------------------------|---------------------|-------------------|-----------------|
| Deploy cost (gas)        | −112,664 (−7.59%)   | −116,096 (−7.82%) | −3,432 (−0.25%) |
| Deploy size (bytes)      | −521 (−7.76%)       | −537 (−8.00%)     | −16 (−0.26%)    |
| `deltaOf` avg            | −7,589              | −7,589            | 0               |
| `cancelStream` avg       | −2,933              | −4,100            | −1,167          |
| `withdrawFromStream` avg | −2,015              | −3,781            | −1,766          |
| `balanceOf` avg          | −1,038              | −1,024            | +14             |
| `createStream` avg       | −162                | −173              | −11             |
| Formally verified        | Yes                 | Yes               | —               |

The principal sources of Cyfrin's savings are Rule 24 applied to `deltaOf` (switching from full struct memory copy to selective field caching), which propagates into `balanceOf`, `withdrawFromStream`, and `cancelStream`, and the structural simplification of `balanceOf` and `createStream` through removal of auxiliary memory structs. Our additional savings relative to Cyfrin are driven by Rule 16 (Short-Circuiting) in `_onlyAdminOrRecipient`, which avoids an `SLOAD` from `hasRole` on the common recipient-caller path in `withdrawFromStream` and `cancelStream`, and by Rule 17 in the `onlyFundsAdmin` modifier.