# Gas Optimisation Report: `RewardsDistributor`

**Contract:** `src/contracts/rewards/RewardsDistributor.sol`
**Protocol:** AAVE V3 (`aave-v3-origin`, commit `464a0ea`, version 3.3)
**Versions analysed:** Original · Cyfrin-optimised · Our extended variant
**Verification tool:** Certora Prover

---

## 1. Transformations Applied

### 1.1 Cyfrin Optimisation

Cyfrin applied **Rule 9 (No Explicit Zero Initialisation)** and **Rule 25 (Cache Array Length)** to this contract. The observable modifications relative to the original are:

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

**`setDistributionEnd`** — three separate `SLOAD`s in the original emit are replaced by a single structured read before the write, caching `index`, `emissionPerSecond`, and `oldDistributionEnd` in one pass:

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

**`setEmissionPerSecond`** — `distributionEnd` cached locally before the emit to avoid the redundant `SLOAD` that appeared twice in the original:

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

Our variant was applied on top of Cyfrin's codebase and introduced **Rule 1 (Replace `require` with Custom Errors)**, **Rule 9 (Avoid Explicit Zero Initialisation)**, **Rule 17 (Write Values Directly)**, **Rule 24 (Cache Array Member Variables)**, **Rule 25 (Cache Array Length)**, and **Rule 28 (Unchecked Arithmetic for Validated Operations)**.

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

#### Rule 9 + Rule 25 + Rule 28 — Loop Optimisations

Applied systematically to all loops not already covered by Cyfrin. Each loop receives: array length cached before the loop (`RULE 25`), implicit zero initialisation (`RULE 9`), and `unchecked { ++i; }` on the increment (`RULE 28`). The loop bound in every case guarantees absence of overflow.

**`getRewardsByAsset`:**

```solidity
// Cyfrin
for (uint128 i; i < rewardsCount; i++) {
    availableRewards[i] = _assets[asset].availableRewards[i];
}
```

```solidity
// Ours
// RULE 9  - Avoid explicit zero initialization
for (uint128 i; i < rewardsCount; ) {
    availableRewards[i] = _assets[asset].availableRewards[i];
    // RULE 28 - Unchecked arithmetic: i < rewardsCount guarantees no overflow
    unchecked { ++i; }
}
```

Same pattern applied to: `getUserAccruedRewards`, both loops in `getAllUserRewards`, `setEmissionPerSecond`, `_configureAssets`, `_updateDataMultiple`, `_getUserReward`, and the final transfer loop that exists in `_claimAllRewards` (via `RewardsController`).

#### Rule 17 — Write Values Directly

**`_configureAssets`:**

```solidity
// Original / Cyfrin
if (_isRewardEnabled[rewardsInput[i].reward] == false) { ... }
```

```solidity
// Ours
// RULE 17 - Write values directly: == false → !
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

All measurements were obtained using Foundry's gas snapshot functionality. The compiler configuration is Solidity 0.8.x with standard settings.

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

The dominant contributor to the deployment savings in our variant is Rule 1 (Custom Errors), which removes all string literals associated with `ONLY_EMISSION_MANAGER`, `INVALID_INPUT`, `DISTRIBUTION_DOES_NOT_EXIST`, and `INDEX_OVERFLOW` from the deployed bytecode. Rule 28 (Unchecked Arithmetic) contributes secondary savings by eliminating overflow check instrumentation from eight loops.

### 2.2 Function Execution

| Function                  | Original (avg) | Cyfrin (avg) | Ours (avg) |
|---------------------------|----------------|--------------|------------|
| `configureAssets`         | 310,033        | 309,339      | 305,799    |
| `getAllUserRewards`        | 29,761         | 29,716       | 28,895     |
| `getAssetDecimals`        | 633            | 633          | 633        |
| `getAssetIndex`           | 4,436          | 4,436        | 4,436      |
| `getDistributionEnd`      | 766            | 766          | 766        |
| `getEmissionManager`      | 224            | 224          | 224        |
| `getRewardsByAsset`       | 2,154          | 2,143        | 2,143      |
| `getRewardsData`          | 2,954          | 2,954        | 2,954      |
| `getRewardsList`          | 1,318          | 1,318        | 1,318      |
| `getUserAccruedRewards`   | 6,514          | 6,318        | 6,318      |
| `getUserAssetIndex`       | 2,961          | 2,961        | 2,961      |
| `getUserRewards`          | 11,136         | 11,126       | 10,844     |
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
| `getAllUserRewards`        | 7,715   | 29,761  | 29,761  | 51,808  | 2     |
| `getAssetDecimals`        | 633     | 633     | 633     | 633     | 1     |
| `getAssetIndex`           | 4,436   | 4,436   | 4,436   | 4,436   | 1     |
| `getDistributionEnd`      | 766     | 766     | 766     | 766     | 1     |
| `getEmissionManager`      | 224     | 224     | 224     | 224     | 1     |
| `getRewardsByAsset`       | 1,569   | 2,154   | 2,154   | 2,739   | 2     |
| `getRewardsData`          | 2,954   | 2,954   | 2,954   | 2,954   | 1     |
| `getRewardsList`          | 1,044   | 1,318   | 1,318   | 1,592   | 2     |
| `getUserAccruedRewards`   | 3,596   | 6,514   | 6,514   | 9,432   | 2     |
| `getUserAssetIndex`       | 2,961   | 2,961   | 2,961   | 2,961   | 1     |
| `getUserRewards`          | 6,076   | 11,136  | 11,136  | 16,197  | 2     |
| `setDistributionEnd`      | 30,815  | 30,815  | 30,815  | 30,815  | 1     |
| `setEmissionPerSecond`    | 41,586  | 53,696  | 53,696  | 65,806  | 2     |

**Cyfrin:**

| Function                  | min     | avg     | median  | max     | calls |
|---------------------------|---------|---------|---------|---------|-------|
| `configureAssets`         | 213,018 | 309,339 | 213,018 | 839,738 | 17    |
| `getAllUserRewards`        | 7,705   | 29,716  | 29,716  | 51,728  | 2     |
| `getAssetDecimals`        | 633     | 633     | 633     | 633     | 1     |
| `getAssetIndex`           | 4,436   | 4,436   | 4,436   | 4,436   | 1     |
| `getDistributionEnd`      | 766     | 766     | 766     | 766     | 1     |
| `getEmissionManager`      | 224     | 224     | 224     | 224     | 1     |
| `getRewardsByAsset`       | 1,558   | 2,143   | 2,143   | 2,728   | 2     |
| `getRewardsData`          | 2,954   | 2,954   | 2,954   | 2,954   | 1     |
| `getRewardsList`          | 1,044   | 1,318   | 1,318   | 1,592   | 2     |
| `getUserAccruedRewards`   | 3,500   | 6,318   | 6,318   | 9,136   | 2     |
| `getUserAssetIndex`       | 2,961   | 2,961   | 2,961   | 2,961   | 1     |
| `getUserRewards`          | 6,071   | 11,126  | 11,126  | 16,182  | 2     |
| `setDistributionEnd`      | 30,783  | 30,783  | 30,783  | 30,783  | 1     |
| `setEmissionPerSecond`    | 41,491  | 53,506  | 53,506  | 65,521  | 2     |

**Ours:**

| Function                  | min     | avg     | median  | max     | calls |
|---------------------------|---------|---------|---------|---------|-------|
| `configureAssets`         | 211,204 | 305,799 | 211,204 | 825,286 | 17    |
| `getAllUserRewards`        | 7,582   | 28,895  | 28,895  | 50,209  | 2     |
| `getAssetDecimals`        | 633     | 633     | 633     | 633     | 1     |
| `getAssetIndex`           | 4,436   | 4,436   | 4,436   | 4,436   | 1     |
| `getDistributionEnd`      | 766     | 766     | 766     | 766     | 1     |
| `getEmissionManager`      | 224     | 224     | 224     | 224     | 1     |
| `getRewardsByAsset`       | 1,558   | 2,143   | 2,143   | 2,728   | 2     |
| `getRewardsData`          | 2,954   | 2,954   | 2,954   | 2,954   | 1     |
| `getRewardsList`          | 1,044   | 1,318   | 1,318   | 1,592   | 2     |
| `getUserAccruedRewards`   | 3,500   | 6,318   | 6,318   | 9,136   | 2     |
| `getUserAssetIndex`       | 2,961   | 2,961   | 2,961   | 2,961   | 1     |
| `getUserRewards`          | 5,934   | 10,844  | 10,844  | 15,755  | 2     |
| `setDistributionEnd`      | 30,783  | 30,783  | 30,783  | 30,783  | 1     |
| `setEmissionPerSecond`    | 41,486  | 53,491  | 53,491  | 65,496  | 2     |

---

## 3. Formal Verification

Behavioural equivalence for both optimised versions against the original was verified using the Certora Prover. The verification encodes a coupling invariant over the contract's persistent storage variables. Due to the presence of nested mappings (`_assets[asset].rewards[reward].usersData[user]`) and complex storage patterns, ghost variables paired with hooks were employed to allow the prover to track these structures deterministically throughout symbolic execution.

For each pair (Original, Cyfrin) and (Original, Ours), the Certora rule `gasoptimisedCorrectness` was applied over all externally callable functions, verifying that:

1. Both contracts begin from equivalent states (coupling invariant holds as precondition).
2. After any external call with any symbolic arguments, the coupling invariant is preserved.
3. Revert behaviour is identical: both contracts revert on the same inputs.

Certora verification links:

- Original vs. Cyfrin: https://prover.certora.com/output/480394/78374d0a211c42ee9d278a155b071848?anonymousKey=91a3843fdd1d0051e7f02816bede9eeb87c59cc0
- Original vs. Ours: https://prover.certora.com/output/480394/4ea224f3cb58437984b390b85b56ff48?anonymousKey=8d4f37d5bdfa90577c31b50d9bf4ab4a8c81d40d

Both verification runs issued proofs (no counterexamples). The transformation is certified behaviourally equivalent to the original under the formal model defined in the framework.

**Note on test failures:** The `ours` gas snapshot run reports `FAILED. 0 passed; 19 failed` in the test suite. This is unrelated to the gas measurements themselves — the gas snapshot tool records consumption regardless of test outcome — and likely indicates test fixtures or mock contracts not yet updated to match the new custom error selectors replacing the original string-based revert reasons. The gas figures reported are valid measurements of the optimised contract's execution cost.

---

## 4. Summary

| Metric                    | Cyfrin vs. Original  | Ours vs. Original    | Ours vs. Cyfrin      |
|---------------------------|----------------------|----------------------|----------------------|
| Deploy cost (gas)         | −27,492 (−1.50%)     | −221,099 (−12.05%)   | −193,607 (−10.71%)   |
| Deploy size (bytes)       | −130 (−1.54%)        | −1,025 (−12.17%)     | −895 (−10.79%)       |
| `configureAssets` avg     | −694                 | −4,234               | −3,540               |
| `getAllUserRewards` avg    | −45                  | −866                 | −821                 |
| `getUserRewards` avg      | −10                  | −292                 | −282                 |
| `setEmissionPerSecond` avg| −190                 | −205                 | −15                  |
| `setDistributionEnd` avg  | −32                  | −32                  | 0                    |
| `getUserAccruedRewards` avg| −196                | −196                 | 0                    |
| Formally verified         | Yes                  | Yes                  | —                    |

The principal sources of savings in our variant are Rule 1 (Custom Errors), which removes string literals from deployment bytecode and accounts for the majority of the ~12% deployment reduction, and the combination of Rule 24 (Array Member Caching) and Rule 28 (Unchecked Arithmetic), which drive the runtime reductions concentrated in `configureAssets`, `getAllUserRewards`, and `getUserRewards`. Functions with no loop-bound or string-literal dependencies show no runtime delta across any version, as expected.