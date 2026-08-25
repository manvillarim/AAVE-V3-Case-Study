# Gas Optimisation Report: `RewardsDistributor`

**Contract:** `src/contracts/rewards/RewardsDistributor.sol`
**Protocol:** AAVE V3 (`aave-v3-origin`, commit `464a0ea`, version 3.3)
**Versions analysed:** Original · Cyfrin-optimised · Our extended variant
**Verification tool:** Certora Prover

---

## 1. Transformations Applied

### 1.1 Cyfrin Optimisation

Cyfrin applied **Rule 9 (No Explicit Zero Initialisation)**, **Rule 23 (Cache Storage Variables)** and **Rule 25 (Cache Array Length)** to this contract. The observable modifications relative to the original are:

**`getRewardsByAsset`** — return variable declared in signature, eliminating a separate `return` statement; minor stylistic gain with no material gas impact.

**`getUserAccruedRewards`** — array length cached before the loop, eliminating a repeated `SLOAD` of `_assetsList.length` on each iteration:

```solidity
// Original
for (uint256 i = 0; i < _assetsList.length; i++) {
    totalAccrued += _assets[_assetsList[i]].rewards[reward].usersData[user].accrued;
}
return totalAccrued;
```

```solidity
// Cyfrin
uint256 assetsListLength = _assetsList.length;
for (uint256 i; i < assetsListLength; i++) {
    totalAccrued += _assets[_assetsList[i]].rewards[reward].usersData[user].accrued;
}
```

**`getAllUserRewards`** — `rewardsList.length` replaced by `_rewardsList.length` cached once before the outer loop, and `userAssetBalances[i]` accesses reduced by caching the outer loop length:

```solidity
// Original
rewardsList = new address[](_rewardsList.length);
unclaimedAmounts = new uint256[](rewardsList.length);
for (uint256 i = 0; i < userAssetBalances.length; i++) {
    for (uint256 r = 0; r < rewardsList.length; r++) { ... }
}
```

```solidity
// Cyfrin
uint256 rewardsListLength = _rewardsList.length;
rewardsList = new address[](rewardsListLength);
unclaimedAmounts = new uint256[](rewardsListLength);
for (uint256 i; i < userAssetBalances.length; i++) {
    for (uint256 r; r < rewardsListLength; r++) { ... }
}
```

**`setDistributionEnd`** (Rule 23) — three separate `SLOAD`s in the original emit are replaced by a single structured read before the write, caching `index`, `emissionPerSecond`, and `oldDistributionEnd` in one pass:

```solidity
// Original
uint256 oldDistributionEnd = _assets[asset].rewards[reward].distributionEnd;
_assets[asset].rewards[reward].distributionEnd = newDistributionEnd;
emit AssetConfigUpdated(
    asset, reward,
    _assets[asset].rewards[reward].emissionPerSecond,  // SLOAD
    _assets[asset].rewards[reward].emissionPerSecond,  // SLOAD
    oldDistributionEnd, newDistributionEnd,
    _assets[asset].rewards[reward].index               // SLOAD
);
```

```solidity
// Cyfrin
(uint104 index, uint88 emissionPerSecond, uint32 oldDistributionEnd)
    = (_assets[asset].rewards[reward].index,
       _assets[asset].rewards[reward].emissionPerSecond,
       _assets[asset].rewards[reward].distributionEnd);
_assets[asset].rewards[reward].distributionEnd = newDistributionEnd;
emit AssetConfigUpdated(
    asset, reward,
    emissionPerSecond, emissionPerSecond,
    oldDistributionEnd, newDistributionEnd,
    index
);
```

**`setEmissionPerSecond`** (Rule 23) — `distributionEnd` cached locally before the emit to avoid the redundant `SLOAD` that appeared twice in the original:

```solidity
// Original
emit AssetConfigUpdated(
    asset, rewards[i], oldEmissionPerSecond, newEmissionsPerSecond[i],
    rewardConfig.distributionEnd,   // SLOAD
    rewardConfig.distributionEnd,   // SLOAD
    newIndex
);
```

```solidity
// Cyfrin
uint32 distributionEnd = rewardConfig.distributionEnd;
emit AssetConfigUpdated(
    asset, rewards[i], oldEmissionPerSecond, newEmissionsPerSecond[i],
    distributionEnd, distributionEnd,
    newIndex
);
```

**`_configureAssets`** — post-increment `availableRewardsCount++` consolidated into the array assignment (same as Cyfrin's source version), removing a separate statement.

---

### 1.2 Our Extended Optimisation

Our variant was applied on top of Cyfrin's codebase and introduced **Rule 1 (Replace `require` with Custom Errors)**, **Rule 9 (Avoid Explicit Zero Initialisation)**, **Rule 15 (Reduce Expressions)**, **Rule 24 (Cache Array Member Variables)**, **Rule 25 (Cache Array Length)**, **Rule 26 (Efficient Loop Increment)**, and **Rule 28 (Unchecked Arithmetic for Validated Operations)**. Together with Cyfrin's Rules 9, 23 and 25, the resulting contract instantiates eight distinct catalogue rules.

#### Rule 1 — Replace `require` with Custom Errors

All `require` statements with string literals are replaced with `if`-revert custom error patterns. Custom error declarations are added at contract level:

```solidity
// RULE 1 - Replace require with custom errors
error OnlyEmissionManager();
error InvalidInput();
error DistributionDoesNotExist();
error IndexOverflow();
```

**`onlyEmissionManager` modifier:**

```solidity
// Original / Cyfrin
modifier onlyEmissionManager() {
    require(msg.sender == EMISSION_MANAGER, 'ONLY_EMISSION_MANAGER');
    _;
}
```

```solidity
// Ours
modifier onlyEmissionManager() {
    // RULE 1 - Replace require with custom errors
    if (msg.sender != EMISSION_MANAGER) revert OnlyEmissionManager();
    _;
}
```

**`setEmissionPerSecond`:**

```solidity
// Original / Cyfrin
require(rewards.length == newEmissionsPerSecond.length, 'INVALID_INPUT');
// ...
require(decimals != 0 && rewardConfig.lastUpdateTimestamp != 0, 'DISTRIBUTION_DOES_NOT_EXIST');
```

```solidity
// Ours
// RULE 1  - Replace require with custom errors
// RULE 25 - Cache array length in loops
uint256 rewardsLength = rewards.length;
if (rewardsLength != newEmissionsPerSecond.length) revert InvalidInput();
// ...
// RULE 1 - Replace require with custom errors
if (decimals == 0 || rewardConfig.lastUpdateTimestamp == 0) revert DistributionDoesNotExist();
```

**`_updateRewardData`:**

```solidity
// Original / Cyfrin
require(newIndex <= type(uint104).max, 'INDEX_OVERFLOW');
```

```solidity
// Ours
// RULE 1 - Replace require with custom errors
if (newIndex > type(uint104).max) revert IndexOverflow();
```

#### Rule 9 + Rule 25 + Rule 26 + Rule 28 — Loop Optimisations

Applied systematically to all eight loops of the contract. Each loop receives: array length cached before the loop (Rule 25), implicit zero initialisation (Rule 9), and the post-increment `i++` replaced by a pre-increment (Rule 26) wrapped in `unchecked` (Rule 28). The loop bound in every case guarantees absence of overflow.

**`getRewardsByAsset`:**

```solidity
// Cyfrin
for (uint128 i; i < rewardsCount; i++) {
    availableRewards[i] = _assets[asset].availableRewards[i];
}
```

```solidity
// Ours
// Rule 9  - Avoid explicit zero initialization
for (uint128 i; i < rewardsCount; ) {
    availableRewards[i] = _assets[asset].availableRewards[i];
    // Rules 26 + 28 - Pre-increment, unchecked: i < rewardsCount guarantees no overflow
    unchecked { ++i; }
}
```

The same pattern is applied to the remaining seven loops: `getUserAccruedRewards`, both loops in `getAllUserRewards`, `setEmissionPerSecond`, `_configureAssets`, `_updateDataMultiple`, and `_getUserReward`.

#### Rule 15 — Reduce Expressions

**`_configureAssets`:**

```solidity
// Original / Cyfrin
if (_isRewardEnabled[rewardsInput[i].reward] == false) { ... }
```

```solidity
// Ours
// Rule 15 - Reduce expressions: == false → !
if (!_isRewardEnabled[input.reward]) { ... }
```

#### Rule 24 — Cache Array Member Variables

**`_configureAssets`** — `rewardsInput[i]` is accessed ten or more times per iteration; caching it as a `memory` local eliminates repeated memory index computations:

```solidity
// Original / Cyfrin
for (uint256 i; i < rewardsInput.length; i++) {
    if (_assets[rewardsInput[i].asset].decimals == 0) { ... }
    uint256 decimals = _assets[rewardsInput[i].asset].decimals = IERC20Detailed(
        rewardsInput[i].asset).decimals();
    RewardsDataTypes.RewardData storage rewardConfig =
        _assets[rewardsInput[i].asset].rewards[rewardsInput[i].reward];
    // ... rewardsInput[i] accessed ~8 more times
}
```

```solidity
// Ours
for (uint256 i; i < rewardsInputLength; ) {
    // RULE 24 - Cache array member variable: rewardsInput[i] accessed 10+ times
    RewardsDataTypes.RewardsConfigInput memory input = rewardsInput[i];
    if (_assets[input.asset].decimals == 0) { ... }
    uint256 decimals = _assets[input.asset].decimals = IERC20Detailed(input.asset).decimals();
    RewardsDataTypes.RewardData storage rewardConfig = _assets[input.asset].rewards[input.reward];
    // ... input.field accesses throughout
    unchecked { ++i; }
}
```

Same pattern applied to `_updateDataMultiple` and `_getUserReward` (struct cached as `RewardsDataTypes.UserAssetBalance memory bal`), and to the outer loop of `getAllUserRewards` (`userAssetBalance` cached per iteration).

---

## 2. Gas Consumption Results

All measurements were obtained with Foundry 1.7.1 (`forge test --gas-report --match-contract RewardsDistributor_gas_Tests`) under the compiler configuration shipped with the AAVE V3 repository: solc 0.8.22, optimiser enabled, 200 runs, `shanghai` EVM target. Foundry's accounting for `view` calls has changed across releases; deployment cost, bytecode size, and the gas of state-modifying functions are stable across versions, whereas the absolute figures for `view` functions are not. The figures below correspond to the `MockRewardsDistributor` harness, since `RewardsDistributor` is abstract.

### 2.1 Deployment

| Version  | Deployment Cost (gas) | Deployment Size (bytes) |
|----------|-----------------------|------------------------|
| Original | 1,834,732             | 8,421                  |
| Cyfrin   | 1,807,240             | 8,291                  |
| Ours     | 1,613,633             | 7,396                  |

| Comparison          | Deploy Cost Savings      | Deploy Size Savings    |
|---------------------|--------------------------|------------------------|
| Cyfrin vs. Original | −27,492 (−1.50%)         | −130 (−1.54%)          |
| Ours vs. Original   | −221,099 (−12.05%)       | −1,025 (−12.17%)       |
| Ours vs. Cyfrin     | −193,607 (−10.71%)       | −895 (−10.79%)         |

The dominant contributor to the deployment savings in our variant is Rule 24 (Array Member Caching), which accounts for −155,837 gas (−720 bytes) of the reduction: reverting that rule alone, with every other one left in place, takes the harness from 1,613,633 gas / 7,396 bytes back to 1,769,470 gas / 8,116 bytes. Rule 1 (Custom Errors), which removes all string literals associated with `ONLY_EMISSION_MANAGER`, `INVALID_INPUT`, `DISTRIBUTION_DOES_NOT_EXIST`, and `INDEX_OVERFLOW` from the deployed bytecode, accounts for −41,262 gas (−191 bytes), and Rule 28 (Unchecked Arithmetic) for −16,230 gas (−75 bytes), by eliminating overflow check instrumentation from eight loops. Each of these figures is the effect of reverting one rule from the complete variant, so they do not add up exactly to the total.

### 2.2 Function Execution

| Function                  | Original (avg) | Cyfrin (avg) | Ours (avg) |
|---------------------------|----------------|--------------|------------|
| `configureAssets`         | 310,033        | 309,339      | 305,799    |
| `getAllUserRewards`       | 49,761         | 49,716       | 48,895     |
| `getAssetDecimals`        | 2,633          | 2,633        | 2,633      |
| `getAssetIndex`           | 10,936         | 10,936       | 10,936     |
| `getDistributionEnd`      | 2,766          | 2,766        | 2,766      |
| `getEmissionManager`      | 224            | 224          | 224        |
| `getRewardsByAsset`       | 8,154          | 8,143        | 8,143      |
| `getRewardsData`          | 2,954          | 2,954        | 2,954      |
| `getRewardsList`          | 7,318          | 7,318        | 7,318      |
| `getUserAccruedRewards`   | 12,514         | 12,318       | 12,318     |
| `getUserAssetIndex`       | 2,961          | 2,961        | 2,961      |
| `getUserRewards`          | 19,136         | 19,126       | 18,844     |
| `setDistributionEnd`      | 30,815         | 30,783       | 30,783     |
| `setEmissionPerSecond`    | 53,696         | 53,506       | 53,491     |

| Function                | Cyfrin vs. Original | Ours vs. Original | Ours vs. Cyfrin |
|-------------------------|---------------------|-------------------|-----------------|
| `configureAssets`       | −694                | −4,234            | −3,540          |
| `getAllUserRewards`      | −45                 | −866              | −821            |
| `getRewardsByAsset`     | −11                 | −11               | 0               |
| `getUserAccruedRewards` | −196                | −196              | 0               |
| `getUserRewards`        | −10                 | −292              | −282            |
| `setDistributionEnd`    | −32                 | −32               | 0               |
| `setEmissionPerSecond`  | −190                | −205              | −15             |

**Observations:**

`configureAssets` shows the largest absolute runtime reduction in our variant: −4,234 gas (avg) relative to the original and −3,540 gas (avg) relative to Cyfrin. This arises from the combination of Rule 24 (eliminating repeated memory index computations on `rewardsInput[i]`) and Rule 28 (unchecked loop increments across a loop that runs once per configured asset). The function is the most loop-intensive in the contract, making it the primary beneficiary of the combined optimisations.

`getAllUserRewards` saves −866 gas (avg) relative to the original in our variant, compared to −45 gas in Cyfrin. The gain over Cyfrin (−821 gas) comes from Rule 24 caching `userAssetBalances[i]` in the outer loop and Rule 28 on both the inner and outer loop increments.

`getUserRewards` saves −292 gas (avg) relative to the original in our variant, compared to −10 gas in Cyfrin. The gain is attributable to Rule 24 caching the `UserAssetBalance` struct in `_getUserReward` and Rule 28 on the loop increment.

`setEmissionPerSecond` saves −205 gas (avg) in our variant versus −190 gas in Cyfrin. The additional −15 gas over Cyfrin comes from Rule 1 replacing the two `require` statements in this function.

Pure view functions that perform only direct storage reads (`getAssetDecimals`, `getAssetIndex`, `getDistributionEnd`, `getEmissionManager`, `getRewardsData`, `getRewardsList`, `getUserAssetIndex`) are unaffected across all three versions, as no storage layout or read-path changes were introduced in those functions.

### 2.3 Detailed Gas Snapshots

**Original:**

| Function                  | min     | avg     | median  | max     | calls |
|---------------------------|---------|---------|---------|---------|-------|
| `configureAssets`         | 213,355 | 310,033 | 213,355 | 842,771 | 17    |
| `getAllUserRewards`       | 15,715  | 49,761  | 49,761  | 83,808  | 2     |
| `getAssetDecimals`        | 2,633   | 2,633   | 2,633   | 2,633   | 1     |
| `getAssetIndex`           | 10,936  | 10,936  | 10,936  | 10,936  | 1     |
| `getDistributionEnd`      | 2,766   | 2,766   | 2,766   | 2,766   | 1     |
| `getEmissionManager`      | 224     | 224     | 224     | 224     | 1     |
| `getRewardsByAsset`       | 5,569   | 8,154   | 8,154   | 10,739  | 2     |
| `getRewardsData`          | 2,954   | 2,954   | 2,954   | 2,954   | 1     |
| `getRewardsList`          | 5,044   | 7,318   | 7,318   | 9,592   | 2     |
| `getUserAccruedRewards`   | 7,596   | 12,514  | 12,514  | 17,432  | 2     |
| `getUserAssetIndex`       | 2,961   | 2,961   | 2,961   | 2,961   | 1     |
| `getUserRewards`          | 10,076  | 19,136  | 19,136  | 28,197  | 2     |
| `setDistributionEnd`      | 30,815  | 30,815  | 30,815  | 30,815  | 1     |
| `setEmissionPerSecond`    | 41,586  | 53,696  | 53,696  | 65,806  | 2     |

Call-weighted average over all functions: **156,250** gas.

**Cyfrin:**

| Function                  | min     | avg     | median  | max     | calls |
|---------------------------|---------|---------|---------|---------|-------|
| `configureAssets`         | 213,018 | 309,339 | 213,018 | 839,738 | 17    |
| `getAllUserRewards`       | 15,705  | 49,716  | 49,716  | 83,728  | 2     |
| `getAssetDecimals`        | 2,633   | 2,633   | 2,633   | 2,633   | 1     |
| `getAssetIndex`           | 10,936  | 10,936  | 10,936  | 10,936  | 1     |
| `getDistributionEnd`      | 2,766   | 2,766   | 2,766   | 2,766   | 1     |
| `getEmissionManager`      | 224     | 224     | 224     | 224     | 1     |
| `getRewardsByAsset`       | 5,558   | 8,143   | 8,143   | 10,728  | 2     |
| `getRewardsData`          | 2,954   | 2,954   | 2,954   | 2,954   | 1     |
| `getRewardsList`          | 5,044   | 7,318   | 7,318   | 9,592   | 2     |
| `getUserAccruedRewards`   | 7,500   | 12,318  | 12,318  | 17,136  | 2     |
| `getUserAssetIndex`       | 2,961   | 2,961   | 2,961   | 2,961   | 1     |
| `getUserRewards`          | 10,071  | 19,126  | 19,126  | 28,182  | 2     |
| `setDistributionEnd`      | 30,783  | 30,783  | 30,783  | 30,783  | 1     |
| `setEmissionPerSecond`    | 41,491  | 53,506  | 53,506  | 65,521  | 2     |

Call-weighted average over all functions: **155,896** gas.

**Ours:**

| Function                  | min     | avg     | median  | max     | calls |
|---------------------------|---------|---------|---------|---------|-------|
| `configureAssets`         | 211,204 | 305,799 | 211,204 | 825,286 | 17    |
| `getAllUserRewards`       | 15,582  | 48,895  | 48,895  | 82,209  | 2     |
| `getAssetDecimals`        | 2,633   | 2,633   | 2,633   | 2,633   | 1     |
| `getAssetIndex`           | 10,936  | 10,936  | 10,936  | 10,936  | 1     |
| `getDistributionEnd`      | 2,766   | 2,766   | 2,766   | 2,766   | 1     |
| `getEmissionManager`      | 224     | 224     | 224     | 224     | 1     |
| `getRewardsByAsset`       | 5,558   | 8,143   | 8,143   | 10,728  | 2     |
| `getRewardsData`          | 2,954   | 2,954   | 2,954   | 2,954   | 1     |
| `getRewardsList`          | 5,044   | 7,318   | 7,318   | 9,592   | 2     |
| `getUserAccruedRewards`   | 7,500   | 12,318  | 12,318  | 17,136  | 2     |
| `getUserAssetIndex`       | 2,961   | 2,961   | 2,961   | 2,961   | 1     |
| `getUserRewards`          | 9,934   | 18,844  | 18,844  | 27,755  | 2     |
| `setDistributionEnd`      | 30,783  | 30,783  | 30,783  | 30,783  | 1     |
| `setEmissionPerSecond`    | 41,486  | 53,491  | 53,491  | 65,496  | 2     |

Call-weighted average over all functions: **154,163** gas.

---

## 3. Formal Verification

Behavioural equivalence for both optimised versions against the original was verified using the Certora Prover. The verification encodes a coupling invariant over the contract's persistent storage variables. Due to the presence of nested mappings (`_assets[asset].rewards[reward].usersData[user]`) and complex storage patterns, ghost variables paired with hooks were employed to allow the prover to track these structures deterministically throughout symbolic execution.

For each pair (Original, Cyfrin) and (Original, Ours), the Certora rule `gasoptimisedCorrectness` was applied over all externally callable functions, verifying that:

1. Both contracts begin from equivalent states (coupling invariant holds as precondition).
2. After any external call with any symbolic arguments, the coupling invariant is preserved.
3. Revert behaviour is identical: both contracts revert on the same inputs.

Certora verification links:

- Original vs. Cyfrin: https://prover.certora.com/output/480394/988e4b50b4884117a1b14c56e529099a?anonymousKey=a1dfe2d31eed732ad34897366ba77005e08b4e6a
- Original vs. Ours: https://prover.certora.com/output/480394/687fec79d6b247f38d18a72157ffe9f6?anonymousKey=bfac3dd4fc37aed85b161e71a32731855323a9de

Both verification runs issued proofs (no counterexamples). The transformation is certified behaviourally equivalent to the original under the formal model defined in the framework.

---

### 3.1 Event Logs

Three of the emission points are reachable from the verified selectors. In `setDistributionEnd`, Rule 23 reads `index`, `emissionPerSecond` and `oldDistributionEnd` once into locals instead of re-loading them from storage inside the `emit`, so the expressions supplying the event arguments were rewritten. In `setEmissionPerSecond` the `emit` sits inside a loop whose header Rules 1, 9 and 25 rewrote. In `_updateData` the whole loop containing `emit Accrued` was moved inside `if (numAvailableRewards != 0) { unchecked { ... } }`.

The last two are the case a syntactic side condition cannot settle: a rewrite that changes a loop header or a guard can change how many events are emitted without touching any storage slot. Each emission point therefore calls an empty `internal virtual` recorder that the harness overrides, persisting the argument vector, incrementing `emitCount` and folding the vector into the order-sensitive accumulator `emitDigest`; the invariant compares all three.

The recorder is not added to the subject tree itself. `scripts/make_instrumented.sh` generates an instrumented copy of each tree for the prover, leaving the trees the gas benchmark reads untouched. This matters here: at `_updateData` the optimiser does not remove the empty call, so instrumenting in place would move the measured deployment cost.

All rules are `VERIFIED` in both runs, so the number, order and arguments of the emissions agree.

---

## 4. Summary

| Metric                    | Cyfrin vs. Original  | Ours vs. Original    | Ours vs. Cyfrin      |
|---------------------------|----------------------|----------------------|----------------------|
| Rules applied (cumulative)| 9, 23, 25            | 9, 23, 25, 1, 15, 24, 26, 28 | —            |
| Deploy cost (gas)         | −27,492 (−1.50%)     | −221,099 (−12.05%)   | −193,607 (−10.71%)   |
| Deploy size (bytes)       | −130 (−1.54%)        | −1,025 (−12.17%)     | −895 (−10.79%)       |
| Avg Fn. Gas               | −354 (−0.23%)        | −2,088 (−1.34%)      | −1,734 (−1.11%)      |
| `configureAssets` avg     | −694                 | −4,234               | −3,540               |
| `getAllUserRewards` avg    | −45                  | −866                 | −821                 |
| `getUserRewards` avg      | −10                  | −292                 | −282                 |
| `setEmissionPerSecond` avg| −190                 | −205                 | −15                  |
| `setDistributionEnd` avg  | −32                  | −32                  | 0                    |
| `getUserAccruedRewards` avg| −196                | −196                 | 0                    |
| Formally verified         | Yes                  | Yes                  | —                    |

The principal source of savings in our variant is Rule 24 (Array Member Caching), which accounts for −720 of the −1,025 bytes of the deployment reduction and, combined with Rules 26 and 28 (Pre-increment and Unchecked Arithmetic), drives the runtime reductions concentrated in `configureAssets`, `getAllUserRewards`, and `getUserRewards`; Rule 1 (Custom Errors) removes the string literals from the deployment bytecode and accounts for a further −191 bytes. Functions with no loop-bound or string-literal dependencies show no runtime delta across any version, as expected.

`Avg Fn. Gas` denotes the call-count-weighted mean of the per-function average gas over all functions in the gas report, i.e. the sum of `avg × calls` divided by the total number of calls.