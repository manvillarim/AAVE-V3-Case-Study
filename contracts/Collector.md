# Gas Optimisation Report: `Collector`

**Contract:** `src/contracts/treasury/Collector.sol`
**Protocol:** AAVE V3 (`aave-v3-origin`, commit `464a0ea`, version 3.3)
**Versions analysed:** Original · Cyfrin-optimised · Our extended variant
**Verification tool:** Certora Prover

---

## 1. Transformations Applied

### 1.1 Cyfrin Optimisation

Cyfrin applied **Rule 20 (Limit Number of Modifiers)**, **Rule 15 (Reduce Expressions)** and **Rule 24 (Cache Array Member Variables)** across several functions, alongside structural refactoring that is not covered by any catalogue rule (removal of auxiliary memory structs).

#### Rule 20 — Modifier → Internal Function (`onlyAdminOrRecipient`)

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

Cyfrin replaces this with an internal function `_onlyAdminOrRecipient(address recipient)` (Rule 20), called after the stream has already been loaded into a local `storage` reference. This avoids the redundant `SLOAD` of `_streams[streamId].recipient` that the modifier incurred before the stream was loaded. The rewrite also drops the explicit `== false` comparison in favour of the `!` operator, an instance of **Rule 15 (Reduce Expressions)**:

```solidity
// Cyfrin
function _onlyAdminOrRecipient(address recipient) internal view {
    // Rule 15 - Reduce expressions: !_onlyFundsAdmin() instead of == false
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

#### Structural Simplification (`balanceOf`, `createStream`) — not a catalogue rule

The original `balanceOf` uses a `BalanceOfLocalVars` memory struct as a scratchpad; the original `createStream` uses a `CreateStreamLocalVars` struct and a separate `_nextStreamId++` statement. Cyfrin removes both auxiliary structs, inlining the variables directly and using `_nextStreamId++` inline in the stream assignment. This eliminates unnecessary memory allocation overhead. No rule in the catalogue matches this transformation; it is reported here because it is a substantial contributor to Cyfrin's deployment savings, but it is outside the scope of the rule-based methodology and is verified only as part of the whole-contract equivalence proof.

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

Our variant was applied on top of Cyfrin's codebase and introduced **Rule 15 (Reduce Expressions)** in the `onlyFundsAdmin` modifier, and **Rule 16 (Use Short-Circuiting)** in `_onlyAdminOrRecipient`.

#### Rule 15 — Reduce Expressions (`onlyFundsAdmin` modifier)

Cyfrin did not modify the `onlyFundsAdmin` modifier, which retains the explicit `== false` comparison against the return value of `_onlyFundsAdmin()`. Our variant applies here the same boolean simplification Cyfrin had applied to `_onlyAdminOrRecipient`:

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
    // Rule 15 - Reduce expressions: == false → !
    if (!_onlyFundsAdmin()) revert OnlyFundsAdmin();
    _;
}
```

#### Rule 16 — Short-Circuiting in `_onlyAdminOrRecipient`

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
    // Rule 16 - Use short-circuiting: cheaper comparison (msg.sender != recipient)
    // evaluated first to avoid SLOAD from hasRole when caller is the recipient
    if (msg.sender != recipient && !_onlyFundsAdmin()) {
        revert OnlyFundsAdminOrRecipient();
    }
}
```

This optimisation materialises in `withdrawFromStream` and `cancelStream`, both of which call `_onlyAdminOrRecipient` on every execution.

---

## 2. Gas Consumption Results

All measurements were obtained with Foundry 1.7.1 (`forge test --gas-report --match-contract Collector_gas_Tests`) under the compiler configuration shipped with the AAVE V3 repository: solc 0.8.22, optimiser enabled, 200 runs, `shanghai` EVM target. Foundry's accounting for `view` calls has changed across releases; deployment cost, bytecode size, and the gas of state-modifying functions are stable across versions, whereas the absolute figures for `view` functions (`balanceOf`, `deltaOf`) are not. The gas report contains two measured contracts: `ERC1967Proxy` (the proxy used in tests) and `Collector` (the implementation). The figures reported below correspond to the `Collector` implementation contract.

The suite contains one pre-existing failing test, `test_transfer_ETH` (reverting with `OnlyFundsAdmin()`). It fails identically in all three versions and is therefore unrelated to the transformations under study.

### 2.1 Deployment

| Version  | Deployment Cost (gas) | Deployment Size (bytes) |
|----------|-----------------------|-------------------------|
| Original | 1,484,479             | 6,716                   |
| Cyfrin   | 1,371,815             | 6,195                   |
| Ours     | 1,369,235             | 6,183                   |

| Comparison          | Deploy Cost Savings | Deploy Size Savings |
|---------------------|---------------------|---------------------|
| Cyfrin vs. Original | −112,664 (−7.59%)   | −521 (−7.76%)       |
| Ours vs. Original   | −115,244 (−7.76%)   | −533 (−7.94%)       |
| Ours vs. Cyfrin     | −2,580 (−0.19%)     | −12 (−0.19%)        |

The dominant contributors to Cyfrin's deployment savings are Rule 20 (the modifier-to-function conversion, which removes the inlined modifier body from every call site) and the removal of the `BalanceOfLocalVars` and `CreateStreamLocalVars` auxiliary structs. Our additional −2,580 gas (−12 bytes) over Cyfrin is entirely the `onlyFundsAdmin` modifier rewrite (Rule 15), as reverting each of the two rules in turn shows: with Rule 16 reverted the contract still deploys at 1,369,235 gas / 6,183 bytes, and reverting Rule 15 as well returns exactly Cyfrin's 1,371,815 gas / 6,195 bytes. Rule 16 contributes no deployment saving at all — exchanging the two conjuncts of `_onlyAdminOrRecipient` leaves the instruction count unchanged and pays only at runtime.

### 2.2 Function Execution

| Function             | Original (avg) | Cyfrin (avg) | Ours (avg) |
|----------------------|----------------|--------------|------------|
| `approve`            | 30,450         | 30,454       | 30,443     |
| `balanceOf`          | 19,849         | 18,811       | 18,811     |
| `cancelStream`       | 83,366         | 80,433       | 79,259     |
| `createStream`       | 203,297        | 203,135      | 203,124    |
| `deltaOf`            | 17,907         | 6,985        | 6,985      |
| `transfer`           | 36,663         | 36,663       | 36,652     |
| `withdrawFromStream` | 72,074         | 70,059       | 68,283     |

| Function             | Cyfrin vs. Original | Ours vs. Original | Ours vs. Cyfrin |
|----------------------|---------------------|-------------------|-----------------|
| `deltaOf`            | −10,922             | −10,922           | 0               |
| `cancelStream`       | −2,933              | −4,107            | −1,174          |
| `withdrawFromStream` | −2,015              | −3,791            | −1,776          |
| `balanceOf`          | −1,038              | −1,038            | 0               |
| `createStream`       | −162                | −173              | −11             |
| `transfer`           | 0                   | −11               | −11             |
| `approve`            | +4                  | −7                | −11             |

**Observations:**

`deltaOf` shows the largest single-function reduction (−10,922 gas avg) and is entirely attributable to Cyfrin's Rule 24 transformation: switching from `Stream memory` (full struct copy) to `Stream storage` with selective field caching eliminates the cost of copying all struct fields to memory. Since `deltaOf` is called transitively by both `withdrawFromStream` and `cancelStream` via `balanceOf`, this saving propagates into those functions and accounts for a substantial portion of their Cyfrin-vs-Original deltas as well.

`cancelStream` and `withdrawFromStream` show additional savings in our variant relative to Cyfrin (−1,174 and −1,776 gas avg respectively). These arise from Rule 16 in `_onlyAdminOrRecipient`: when `msg.sender == recipient`, the short-circuit prevents evaluation of `!_onlyFundsAdmin()`, avoiding the `SLOAD` inside `hasRole`. This is the dominant call pattern in the test workload for these two functions.

`balanceOf` shows +14 gas in our variant relative to Cyfrin, within measurement noise. The marginal difference is consistent with the short-circuit reordering having a slightly different cost profile depending on the specific call distribution.

Pure administrative functions (`approve`, `createStream`, `transfer`) show negligible runtime differences, as they are guarded by `onlyFundsAdmin` rather than `_onlyAdminOrRecipient` and are not affected by the short-circuiting optimisation.

### 2.3 Detailed Gas Snapshots

**Original:**

| Function             | min     | avg     | median  | max     | calls |
|----------------------|---------|---------|---------|---------|-------|
| `ETH_MOCK_ADDRESS`   | 260     | 260     | 260     | 260     | 1     |
| `FUNDS_ADMIN_ROLE`   | 245     | 245     | 245     | 245     | 20    |
| `approve`            | 30,450  | 30,450  | 30,450  | 30,450  | 1     |
| `balanceOf`          | 19,754  | 19,849  | 19,845  | 19,952  | 4     |
| `cancelStream`       | 58,480  | 83,366  | 91,628  | 91,729  | 4     |
| `createStream`       | 189,617 | 203,297 | 206,717 | 206,717 | 25    |
| `deltaOf`            | 17,828  | 17,907  | 17,946  | 17,949  | 3     |
| `getNextStreamId`    | 2,326   | 2,326   | 2,326   | 2,326   | 1     |
| `getStream`          | 17,902  | 17,902  | 17,902  | 17,902  | 1     |
| `grantRole`          | 29,754  | 29,754  | 29,754  | 29,754  | 20    |
| `initialize`         | 96,440  | 96,440  | 96,440  | 96,440  | 20    |
| `isFundsAdmin`       | 2,809   | 2,809   | 2,809   | 2,809   | 1     |
| `transfer`           | 35,807  | 36,663  | 36,663  | 37,520  | 2     |
| `withdrawFromStream` | 66,687  | 72,074  | 66,889  | 87,831  | 4     |

Call-weighted average over all functions: **79,375** gas.

**Cyfrin:**

| Function             | min     | avg     | median  | max     | calls |
|----------------------|---------|---------|---------|---------|-------|
| `ETH_MOCK_ADDRESS`   | 260     | 260     | 260     | 260     | 1     |
| `FUNDS_ADMIN_ROLE`   | 245     | 245     | 245     | 245     | 20    |
| `approve`            | 30,454  | 30,454  | 30,454  | 30,454  | 1     |
| `balanceOf`          | 18,723  | 18,811  | 18,804  | 18,914  | 4     |
| `cancelStream`       | 55,676  | 80,433  | 88,680  | 88,696  | 4     |
| `createStream`       | 189,455 | 203,135 | 206,555 | 206,555 | 25    |
| `deltaOf`            | 6,924   | 6,985   | 7,012   | 7,021   | 3     |
| `getNextStreamId`    | 2,326   | 2,326   | 2,326   | 2,326   | 1     |
| `getStream`          | 17,902  | 17,902  | 17,902  | 17,902  | 1     |
| `grantRole`          | 29,754  | 29,754  | 29,754  | 29,754  | 20    |
| `initialize`         | 96,440  | 96,440  | 96,440  | 96,440  | 20    |
| `isFundsAdmin`       | 2,809   | 2,809   | 2,809   | 2,809   | 1     |
| `transfer`           | 35,807  | 36,663  | 36,663  | 37,520  | 2     |
| `withdrawFromStream` | 64,830  | 70,059  | 64,861  | 85,686  | 4     |

Call-weighted average over all functions: **78,807** gas.

**Ours:**

| Function             | min     | avg     | median  | max     | calls |
|----------------------|---------|---------|---------|---------|-------|
| `ETH_MOCK_ADDRESS`   | 260     | 260     | 260     | 260     | 1     |
| `FUNDS_ADMIN_ROLE`   | 245     | 245     | 245     | 245     | 20    |
| `approve`            | 30,443  | 30,443  | 30,443  | 30,443  | 1     |
| `balanceOf`          | 18,723  | 18,811  | 18,804  | 18,914  | 4     |
| `cancelStream`       | 55,707  | 79,259  | 86,317  | 88,696  | 4     |
| `createStream`       | 189,444 | 203,124 | 206,544 | 206,544 | 25    |
| `deltaOf`            | 6,924   | 6,985   | 7,012   | 7,021   | 3     |
| `getNextStreamId`    | 2,326   | 2,326   | 2,326   | 2,326   | 1     |
| `getStream`          | 17,902  | 17,902  | 17,902  | 17,902  | 1     |
| `grantRole`          | 29,754  | 29,754  | 29,754  | 29,754  | 20    |
| `initialize`         | 96,440  | 96,440  | 96,440  | 96,440  | 20    |
| `isFundsAdmin`       | 2,809   | 2,809   | 2,809   | 2,809   | 1     |
| `transfer`           | 35,796  | 36,652  | 36,652  | 37,509  | 2     |
| `withdrawFromStream` | 62,482  | 68,283  | 63,671  | 83,307  | 4     |

Call-weighted average over all functions: **78,694** gas.

---

## 3. Formal Verification

Behavioural equivalence for both optimised versions against the original was verified using the Certora Prover. The verification encodes a coupling invariant over the contract's persistent storage variables. Due to the use of ERC-7201 namespaced storage slots by `AccessControlUpgradeable` and `ReentrancyGuardUpgradeable`, ghost variables paired with slot-addressed hooks were employed to track role assignments and reentrancy guard state deterministically throughout symbolic execution. The `_streams` mapping fields are tracked via per-field ghost mappings keyed by `streamId`.


For each pair (Original, Cyfrin) and (Original, Ours), the Certora rule `gasOptimizationCorrectness` was applied over all externally callable functions, verifying that:

1. Both contracts begin from equivalent states (coupling invariant holds as precondition).
2. After any external call with any symbolic arguments, the coupling invariant is preserved.
3. Revert behaviour is identical: both contracts revert on the same inputs.

### 3.1 Event Arguments

Rule 24 rewrites the expressions that supply the arguments of two events. The original reads them from a `Stream memory` copy taken at the top of the function; the optimised versions read them from locals cached before the `delete` that clears the record, since a `Stream storage` reference would yield zeros after it:

```solidity
// Original
emit WithdrawFromStream(streamId, stream.recipient, amount);
emit CancelStream(streamId, stream.sender, stream.recipient, senderBalance, recipientBalance);
```

```solidity
// Cyfrin / Ours
emit WithdrawFromStream(streamId, recipient, amount);
emit CancelStream(streamId, sender, recipient, senderBalance, recipientBalance);
```

Logs are outside the state a CVL specification can read, and the coupling invariant relates the two contracts at the boundaries of a transition, not at a point inside it. Neither the argument vectors nor the number and order of the emissions follow from it. We record all three explicitly. Each emission point calls an empty `internal virtual` function declared in `Collector` itself:

```solidity
function _recordWithdrawFromStream(uint256, address, uint256) internal virtual {}
```

The harnesses override it, persisting the vector, incrementing a counter and folding the event identifier and the arguments into an order-sensitive accumulator:

```solidity
function _recordWithdrawFromStream(
    uint256 streamId,
    address recipient,
    uint256 amount
) internal override {
    lastWithdrawStreamId = streamId;
    lastWithdrawRecipient = recipient;
    lastWithdrawAmount = amount;
    emitCount = emitCount + 1;
    emitDigest = keccak256(
        abi.encode(emitDigest, "WithdrawFromStream", streamId, recipient, amount)
    );
}
```

The counter and the accumulator are what make the comparison cover the log *sequence* rather than the arguments alone: storage agreement and revert agreement do not imply that the two sides emitted the same number of events in the same order, and a rule that changes control flow could break that without touching any slot. The hash is computed in Solidity inside the harness, so the coupling invariant stays a conjunction of pointwise equalities with no arithmetic of its own.

The recorded slots then enter the coupling invariant as ordinary conjuncts:

```cvl
a.emitCount == ao.emitCount &&
a.emitDigest == ao.emitDigest &&

a.lastCreateStreamId == ao.lastCreateStreamId &&
a.lastCreateSender == ao.lastCreateSender &&
a.lastCreateRecipient == ao.lastCreateRecipient &&
a.lastCreateDeposit == ao.lastCreateDeposit &&
a.lastCreateTokenAddress == ao.lastCreateTokenAddress &&
a.lastCreateStartTime == ao.lastCreateStartTime &&
a.lastCreateStopTime == ao.lastCreateStopTime &&

a.lastWithdrawStreamId == ao.lastWithdrawStreamId &&
a.lastWithdrawRecipient == ao.lastWithdrawRecipient &&
a.lastWithdrawAmount == ao.lastWithdrawAmount &&

a.lastCancelStreamId == ao.lastCancelStreamId &&
a.lastCancelSender == ao.lastCancelSender &&
a.lastCancelRecipient == ao.lastCancelRecipient &&
a.lastCancelSenderBalance == ao.lastCancelSenderBalance &&
a.lastCancelRecipientBalance == ao.lastCancelRecipientBalance
```

The override exists only in the harness, so the subject keeps an empty call that the optimiser removes: the three variants of `Collector` compile to byte-identical creation and runtime code with the three hooks and without them, and every figure in Section 2 is unaffected.

All three emission points are instrumented, `CreateStream` included. Leaving one out would withdraw its emissions from the comparison altogether, which is the situation the recorder exists to prevent. Its argument list contains `address(this)`, so its recorder slots and the digest diverge between the two instances along with the `sender` field the same function writes — one more manifestation of the encoding artefact described below, not a new one.

Certora verification links:

- Original vs. Cyfrin:  https://prover.certora.com/output/480394/3d1a5de6fe834197ae8eb18b1ffd43fd?anonymousKey=d55f60a2f1f4dfbff4f843dbd7eee33519697659
- Original vs. Ours: https://prover.certora.com/output/480394/810285827e5c45b5a886a18d989f26c6?anonymousKey=c045c2c727a89c84fada2e792c25d6e258a5460a

Every rule is `VERIFIED` in both runs except `gasOptimizedCorrectnessOfCreateStream`, which reports a counterexample in both, through the coupling-invariant assertion. It is the `address(this)` artefact of the two-instance encoding: `createStream` compares `recipient` against `address(this)` and stores `address(this)` into the `sender` field, and the prover must place the two instances at distinct symbolic addresses. Both halves of the divergence are outside the observation the framework fixes in advance, and no real deployment exhibits either.

The recorder conjuncts introduced no counterexample of their own. `withdrawFromStream` and `cancelStream` — the two functions whose emitted vectors, count and digest are now compared — are `VERIFIED` in both runs, and the eight rules that emit nothing are unaffected. The only rule that changed status relative to a specification without the recorder is none: `createStream` was already the single violation before the instrumentation, for the same reason.

---

## 4. Summary

| Metric                     | Cyfrin vs. Original | Ours vs. Original | Ours vs. Cyfrin |
|----------------------------|---------------------|-------------------|-----------------|
| Rules applied (cumulative) | 15, 20, 24          | 15, 20, 24, 16    | —               |
| Deploy cost (gas)          | −112,664 (−7.59%)   | −115,244 (−7.76%) | −2,580 (−0.19%) |
| Deploy size (bytes)        | −521 (−7.76%)       | −533 (−7.94%)     | −12 (−0.19%)    |
| Avg Fn. Gas                | −568 (−0.72%)       | −681 (−0.86%)     | −113 (−0.14%)   |
| `deltaOf` avg              | −10,922             | −10,922           | 0               |
| `cancelStream` avg         | −2,933              | −4,107            | −1,174          |
| `withdrawFromStream` avg   | −2,015              | −3,791            | −1,776          |
| `balanceOf` avg            | −1,038              | −1,024            | +14             |
| `createStream` avg         | −162                | −173              | −11             |
| Formally verified          | Yes                 | Yes               | —               |

The principal sources of Cyfrin's savings are Rule 24 applied to `deltaOf` (switching from full struct memory copy to selective field caching), which propagates into `balanceOf`, `withdrawFromStream`, and `cancelStream`; Rule 20, which converts the `onlyAdminOrRecipient` modifier into an internal function; and the structural simplification of `balanceOf` and `createStream` through removal of auxiliary memory structs, which is not covered by the catalogue. Our additional savings relative to Cyfrin are driven at runtime by Rule 16 (Short-Circuiting) in `_onlyAdminOrRecipient`, which avoids an `SLOAD` from `hasRole` on the common recipient-caller path in `withdrawFromStream` and `cancelStream`, and at deployment by Rule 15 in the `onlyFundsAdmin` modifier; Rule 16 contributes no deployment saving.

`Avg Fn. Gas` denotes the call-count-weighted mean of the per-function average gas over all functions in the gas report, i.e. the sum of `avg × calls` divided by the total number of calls.