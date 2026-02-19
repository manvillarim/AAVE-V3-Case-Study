# Gas Optimisation Report: `RewardsController`

**Contract:** `src/contracts/rewards/RewardsController.sol`
**Protocol:** AAVE V3 (`aave-v3-origin`, commit `464a0ea`, version 3.3)
**Versions analysed:** Original · Cyfrin-optimised · Our extended variant
**Verification tool:** Certora Prover

---

## 1. Transformations Applied

### 1.1 Cyfrin Optimisation

Cyfrin applied **Rules 9 and 25** to this contract. Comparing the Cyfrin version against the original, the observable structural modifications are:

**Rule 9 — Avoid Explicit Zero Initialisation:** loop counters changed from `uint256 i = 0` to `uint256 i` across all loops, eliminating the redundant explicit initialisation since `uint256` defaults to zero.

**Original (`configureAssets`, `_getUserAssetBalances`, `_claimAllRewards`, etc.):**

```solidity
for (uint256 i = 0; i < config.length; i++) {
```

**Cyfrin-optimised:**

```solidity
for (uint256 i; i < config.length; i++) {
```

**Rule 25 — Cache Array Length in Loops:** `_claimAllRewards` already cached `_rewardsList.length` in the original via the local variable `rewardsListLength`; Cyfrin applies the same pattern to the outer loop over `assets` in `_claimAllRewards`. However, the inner loops over `assets.length` in `_getUserAssetBalances` and `_claimRewards` are not cached in the Cyfrin version — `assets.length` is still read from calldata on each iteration, which is cheaper than storage but still avoids re-reading.

Notably, Cyfrin does **not** apply `unchecked` increments, does not replace `require` statements with custom errors, and does not apply Rule 17 (remove `== true` comparisons). These optimisations remain exclusively in our extended variant.

One structural difference in the Cyfrin version is the refactoring of `_claimAllRewards` and `_getUserAssetBalances` to use explicit `return` statements, and a restructuring of `_claimRewards` to use an early-return pattern (`if (amount == 0) return 0`). These are behavioural-equivalent reorganisations that affect code layout but not gas at the function call level in a meaningful way.

---

### 1.2 Our Extended Optimisation

Our variant was applied on top of Cyfrin's codebase and introduced **Rules 1, 15, 17, 24, 26, and 28**. The transformations are applied uniformly across all loops and guard conditions in the contract.

#### Rule 1 — Replace `require` with Custom Errors

Seven custom errors are declared at contract level, replacing all `require` statements with string literals:

```solidity
// RULE 1 - Replace require with custom errors
error InvalidToAddress();
error InvalidUserAddress();
error ClaimerUnauthorized();
error StrategyCanNotBeZero();
error StrategyMustBeContract();
error OracleMustReturnPrice();
error TransferError();
```

**Original (`onlyAuthorizedClaimers`):**

```solidity
modifier onlyAuthorizedClaimers(address claimer, address user) {
    require(_authorizedClaimers[user] == claimer, 'CLAIMER_UNAUTHORIZED');
    _;
}
```

**Our optimisation:**

```solidity
modifier onlyAuthorizedClaimers(address claimer, address user) {
    // RULE 1 - Replace require with custom errors
    if (_authorizedClaimers[user] != claimer) revert ClaimerUnauthorized();
    _;
}
```

**Original (`claimRewards`, `claimAllRewards`, `claimRewardsOnBehalf`, `claimAllRewardsOnBehalf`):**

```solidity
require(to != address(0), 'INVALID_TO_ADDRESS');
require(user != address(0), 'INVALID_USER_ADDRESS');
```

**Our optimisation:**

```solidity
// RULE 1 - Replace require with custom errors
if (to == address(0)) revert InvalidToAddress();
if (user == address(0)) revert InvalidUserAddress();
```

**Original (`_transferRewards`):**

```solidity
require(success == true, 'TRANSFER_ERROR');
```

**Our optimisation:**

```solidity
// RULE 1  - Replace require with custom errors
// RULE 17 - Write values directly: success == true → success
if (!success) revert TransferError();
```

**Original (`_installTransferStrategy`):**

```solidity
require(address(transferStrategy) != address(0), 'STRATEGY_CAN_NOT_BE_ZERO');
require(_isContract(address(transferStrategy)) == true, 'STRATEGY_MUST_BE_CONTRACT');
```

**Our optimisation:**

```solidity
// RULE 1 - Replace require with custom errors
if (address(transferStrategy) == address(0)) revert StrategyCanNotBeZero();
// RULE 17 - Write values directly: == true → bare boolean
if (!_isContract(address(transferStrategy))) revert StrategyMustBeContract();
```

**Original (`_setRewardOracle`):**

```solidity
require(rewardOracle.latestAnswer() > 0, 'ORACLE_MUST_RETURN_PRICE');
```

**Our optimisation:**

```solidity
// RULE 1 - Replace require with custom errors
if (rewardOracle.latestAnswer() <= 0) revert OracleMustReturnPrice();
```

#### Rules 9, 25, 26, 28 — Loop Optimisations

All loops receive the combined treatment: no explicit zero initialisation (Rule 9), cached array length (Rule 25), pre-increment (Rule 26), and unchecked increment block (Rule 28).

**Original (`configureAssets`):**

```solidity
for (uint256 i = 0; i < config.length; i++) {
```

**Our optimisation:**

```solidity
// RULE 25 - Cache array length in loops
uint256 configLength = config.length;
// RULE 9  - Avoid explicit zero initialization
for (uint256 i; i < configLength; ) {
    // ...
    // RULE 28 - Unchecked arithmetic: i < configLength guarantees no overflow
    unchecked { ++i; }
}
```

The same pattern is applied to all loops in `_getUserAssetBalances`, `_claimRewards`, and both the outer and inner loops of `_claimAllRewards`, including the final transfer loop.

#### Rule 24 — Cache Array Member Variables

Within loops where `assets[i]` is accessed multiple times, the value is cached in a local variable:

**Original (`_getUserAssetBalances`):**

```solidity
for (uint256 i = 0; i < assets.length; i++) {
    userAssetBalances[i].asset = assets[i];
    (userAssetBalances[i].userBalance, userAssetBalances[i].totalSupply) = IScaledBalanceToken(
        assets[i]
    ).getScaledUserBalanceAndSupply(user);
}
```

**Our optimisation:**

```solidity
for (uint256 i; i < assetsLength; ) {
    // RULE 24 - Cache array member variable
    address asset = assets[i];
    userAssetBalances[i].asset = asset;
    (userAssetBalances[i].userBalance, userAssetBalances[i].totalSupply) = IScaledBalanceToken(
        asset
    ).getScaledUserBalanceAndSupply(user);
    unchecked { ++i; }
}
```

The same caching of `assets[i]` is applied inside `_claimRewards` and `_claimAllRewards`.

---

## 2. Gas Consumption Results

All measurements were obtained using Foundry's gas snapshot functionality. The compiler configuration is Solidity 0.8.x with standard settings.

### 2.1 Deployment

| Version  | Deployment Cost (gas) | Deployment Size (bytes) |
|----------|-----------------------|------------------------|
| Original | 3,097,547             | 14,293                 |
| Cyfrin   | 3,063,250             | 14,135                 |
| Ours     | 2,938,480             | 13,556                 |

| Comparison          | Deploy Cost Savings      | Deploy Size Savings   |
|---------------------|--------------------------|-----------------------|
| Cyfrin vs. Original | 34,297 (−1.11%)          | 158 (−1.11%)          |
| Ours vs. Original   | 159,067 (−5.14%)         | 737 (−5.16%)          |
| Ours vs. Cyfrin     | 124,770 (−4.07%)         | 579 (−4.10%)          |

The dominant contributor to the deployment savings in our variant is Rule 1 (Custom Errors), which removes all seven error string literals from the deployed bytecode. The combined loop optimisations (Rules 9, 25, 26, 28) contribute secondarily by reducing bytecode size through simplified loop preamble and increment logic.

### 2.2 Function Execution

| Function                  | Original (avg) | Cyfrin (avg) | Ours (avg) | Cyfrin vs. Orig | Ours vs. Orig | Ours vs. Cyfrin |
|---------------------------|----------------|--------------|------------|-----------------|---------------|-----------------|
| `claimAllRewards`         | 124,558        | 124,793      | 124,320    | +235            | −238          | −473            |
| `claimAllRewardsOnBehalf` | 127,225        | 127,460      | 126,987    | +235            | −238          | −473            |
| `claimAllRewardsToSelf`   | 124,001        | 124,236      | 123,763    | +235            | −238          | −473            |
| `claimRewards`            | 74,100         | 74,397       | 73,949     | +297            | −151          | −448            |
| `claimRewardsOnBehalf`    | 76,841         | 77,138       | 76,690     | +297            | −151          | −448            |
| `claimRewardsToSelf`      | 73,620         | 73,917       | 73,469     | +297            | −151          | −448            |
| `configureAssets`         | 438,474        | 437,597      | 437,504    | −877            | −970          | −93             |
| `getClaimer`              | 2,625          | 2,625        | 2,625      | 0               | 0             | 0               |
| `getRewardOracle`         | 649            | 649          | 649        | 0               | 0             | 0               |
| `getTransferStrategy`     | 648            | 648          | 648        | 0               | 0             | 0               |
| `handleAction`            | 84,206         | 84,325       | 84,317     | +119            | +111          | −8              |
| `initialize`              | 53,154         | 53,154       | 53,154     | 0               | 0             | 0               |
| `setClaimer`              | 46,079         | 46,079       | 46,079     | 0               | 0             | 0               |
| `setRewardOracle`         | 32,030         | 32,030       | 32,030     | 0               | 0             | 0               |
| `setTransferStrategy`     | 31,643         | 31,643       | 31,631     | 0               | 0             | −12             |

**Observations:**

The Cyfrin version shows a **regression** in average gas for all `claim*` functions relative to the original (+235 to +297 gas). This is an artefact of the structural refactoring: the early-return pattern in `_claimRewards` (`if (amount == 0) return 0`) and the explicit `return` statements in `_claimAllRewards` and `_getUserAssetBalances` alter the code generation path. In test suites where the non-zero-amount path is exercised, these early guards add marginal overhead. The Rule 9 savings on loop initialisation are insufficient to offset this in the tested call patterns. Cyfrin's savings are concentrated in `configureAssets` (−877 gas avg) due to the loop length caching over the `config` array.

Our variant recovers and surpasses the original for all `claim*` functions. The custom errors (Rule 1) reduce the revert-path bytecode size and improve the non-revert path through reduced `JUMPDEST` overhead. The unchecked increments (Rule 28) and cached lengths (Rule 25) compound across the multiple loops within `_getUserAssetBalances`, `_claimRewards`, and `_claimAllRewards`. Net savings against the original range from −151 gas (`claimRewards` avg) to −238 gas (`claimAllRewards` avg).

`handleAction` shows a marginal regression of +111 gas (avg) relative to the original in our variant. This function delegates entirely to `_updateData` in the parent `RewardsDistributor`, with no transformations applied in `RewardsController` itself; the small variance is attributable to code layout changes affecting jump distances in the inherited call chain.

`setTransferStrategy` shows a reduction of −12 gas (avg) in our variant, arising from the custom error replacement in `_installTransferStrategy` eliminating the string literal load on the revert path.

View functions (`getClaimer`, `getRewardOracle`, `getTransferStrategy`) and pure write-throughs (`setClaimer`, `setRewardOracle`, `initialize`) are unaffected, as no storage layout or read-path changes were introduced in this contract.

### 2.3 Detailed Gas Snapshots

**Original:**

| Function                  | min     | avg     | median  | max       | calls |
|---------------------------|---------|---------|---------|-----------|-------|
| `claimAllRewards`         | 58,316  | 124,558 | 124,558 | 190,801   | 2     |
| `claimAllRewardsOnBehalf` | 60,983  | 127,225 | 127,225 | 193,468   | 2     |
| `claimAllRewardsToSelf`   | 57,759  | 124,001 | 124,001 | 190,244   | 2     |
| `claimRewards`            | 53,060  | 74,100  | 74,100  | 95,141    | 2     |
| `claimRewardsOnBehalf`    | 55,801  | 76,841  | 76,841  | 97,882    | 2     |
| `claimRewardsToSelf`      | 52,580  | 73,620  | 73,620  | 94,661    | 2     |
| `configureAssets`         | 270,168 | 438,474 | 270,168 | 1,038,327 | 20    |
| `getClaimer`              | 2,625   | 2,625   | 2,625   | 2,625     | 1     |
| `getRewardOracle`         | 649     | 649     | 649     | 649       | 1     |
| `getTransferStrategy`     | 648     | 648     | 648     | 648       | 1     |
| `handleAction`            | 32,360  | 84,206  | 59,937  | 130,417   | 25    |
| `initialize`              | 53,154  | 53,154  | 53,154  | 53,154    | 21    |
| `setClaimer`              | 46,079  | 46,079  | 46,079  | 46,079    | 5     |
| `setRewardOracle`         | 32,030  | 32,030  | 32,030  | 32,030    | 1     |
| `setTransferStrategy`     | 31,643  | 31,643  | 31,643  | 31,643    | 1     |

**Cyfrin:**

| Function                  | min     | avg     | median  | max       | calls |
|---------------------------|---------|---------|---------|-----------|-------|
| `claimAllRewards`         | 58,471  | 124,793 | 124,793 | 191,116   | 2     |
| `claimAllRewardsOnBehalf` | 61,138  | 127,460 | 127,460 | 193,783   | 2     |
| `claimAllRewardsToSelf`   | 57,914  | 124,236 | 124,236 | 190,559   | 2     |
| `claimRewards`            | 53,202  | 74,397  | 74,397  | 95,593    | 2     |
| `claimRewardsOnBehalf`    | 55,943  | 77,138  | 77,138  | 98,334    | 2     |
| `claimRewardsToSelf`      | 52,722  | 73,917  | 73,917  | 95,113    | 2     |
| `configureAssets`         | 269,831 | 437,597 | 269,831 | 1,035,294 | 20    |
| `getClaimer`              | 2,625   | 2,625   | 2,625   | 2,625     | 1     |
| `getRewardOracle`         | 649     | 649     | 649     | 649       | 1     |
| `getTransferStrategy`     | 648     | 648     | 648     | 648       | 1     |
| `handleAction`            | 32,515  | 84,325  | 60,081  | 130,489   | 25    |
| `initialize`              | 53,154  | 53,154  | 53,154  | 53,154    | 21    |
| `setClaimer`              | 46,079  | 46,079  | 46,079  | 46,079    | 5     |
| `setRewardOracle`         | 32,030  | 32,030  | 32,030  | 32,030    | 1     |
| `setTransferStrategy`     | 31,643  | 31,643  | 31,643  | 31,643    | 1     |

**Ours:**

| Function                  | min     | avg     | median  | max       | calls |
|---------------------------|---------|---------|---------|-----------|-------|
| `claimAllRewards`         | 58,248  | 124,320 | 124,320 | 190,393   | 2     |
| `claimAllRewardsOnBehalf` | 60,915  | 126,987 | 126,987 | 193,060   | 2     |
| `claimAllRewardsToSelf`   | 57,691  | 123,763 | 123,763 | 189,836   | 2     |
| `claimRewards`            | 52,980  | 73,949  | 73,949  | 94,919    | 2     |
| `claimRewardsOnBehalf`    | 55,721  | 76,690  | 76,690  | 97,660    | 2     |
| `claimRewardsToSelf`      | 52,500  | 73,469  | 73,469  | 94,439    | 2     |
| `configureAssets`         | 269,802 | 437,504 | 269,802 | 1,034,945 | 20    |
| `getClaimer`              | 2,625   | 2,625   | 2,625   | 2,625     | 1     |
| `getRewardOracle`         | 649     | 649     | 649     | 649       | 1     |
| `getTransferStrategy`     | 648     | 648     | 648     | 648       | 1     |
| `handleAction`            | 32,510  | 84,317  | 60,076  | 130,476   | 25    |
| `initialize`              | 53,154  | 53,154  | 53,154  | 53,154    | 21    |
| `setClaimer`              | 46,079  | 46,079  | 46,079  | 46,079    | 5     |
| `setRewardOracle`         | 32,030  | 32,030  | 32,030  | 32,030    | 1     |
| `setTransferStrategy`     | 31,631  | 31,631  | 31,631  | 31,631    | 1     |

---

## 3. Formal Verification

Behavioural equivalence for both optimised versions against the original was verified using the Certora Prover. Due to the complexity of the contract's state — which spans inherited storage from `RewardsDistributor` including nested mappings over assets, rewards, and users — the coupling invariant is defined over ghost variables that mirror the full persistent storage:

```
CouplingInv() ≡
    a.EMISSION_MANAGER == ao.EMISSION_MANAGER                                        ∧
    a.lastInitializedRevision == ao.lastInitializedRevision                          ∧
    a.initializing == ao.initializing                                                ∧
    (∀ user.    ghost_a_authorizedClaimers[user]  == ghost_ao_authorizedClaimers[user])  ∧
    (∀ reward.  ghost_a_transferStrategy[reward]  == ghost_ao_transferStrategy[reward])  ∧
    (∀ reward.  ghost_a_rewardOracle[reward]      == ghost_ao_rewardOracle[reward])      ∧
    (∀ asset reward user.
        ghost_a_userIndex[asset][reward][user]   == ghost_ao_userIndex[asset][reward][user]   ∧
        ghost_a_userAccrued[asset][reward][user] == ghost_ao_userAccrued[asset][reward][user]) ∧
    (∀ asset reward.
        ghost_a_rewardIndex[asset][reward]         == ghost_ao_rewardIndex[asset][reward]         ∧
        ghost_a_emissionPerSecond[asset][reward]   == ghost_ao_emissionPerSecond[asset][reward]   ∧
        ghost_a_lastUpdateTimestamp[asset][reward] == ghost_ao_lastUpdateTimestamp[asset][reward] ∧
        ghost_a_distributionEnd[asset][reward]     == ghost_ao_distributionEnd[asset][reward])    ∧
    (∀ asset.
        ghost_a_assetDecimals[asset]         == ghost_ao_assetDecimals[asset]         ∧
        ghost_a_availableRewardsCount[asset] == ghost_ao_availableRewardsCount[asset]) ∧
    (∀ asset idx.
        idx < ghost_a_availableRewardsCount[asset] →
        ghost_a_availableRewards[asset][idx] == ghost_ao_availableRewards[asset][idx]) ∧
    (∀ reward. ghost_a_isRewardEnabled[reward] == ghost_ao_isRewardEnabled[reward])  ∧
    ghost_a_rewardsListLength == ghost_ao_rewardsListLength                          ∧
    (∀ idx. idx < ghost_a_rewardsListLength →
        ghost_a_rewardsListAt[idx] == ghost_ao_rewardsListAt[idx])                   ∧
    ghost_a_assetsListLength == ghost_ao_assetsListLength                            ∧
    (∀ idx. idx < ghost_a_assetsListLength →
        ghost_a_assetsListAt[idx] == ghost_ao_assetsListAt[idx])
```

The coupling invariant spans the entire observable state of both `RewardsController` and its parent `RewardsDistributor`, including all per-asset, per-reward, and per-user data structures. Ghost functions were required for `getScaledUserBalanceAndSupply` to resolve HAVOC states caused by the prover's inability to summarise the external `IScaledBalanceToken` calls. Ghost variables paired with `Sload`/`Sstore` hooks maintain consistency between ghost state and concrete EVM storage throughout symbolic execution.

For each pair (Original, Cyfrin) and (Original, Ours), the Certora rule `gasoptimisedCorrectness` was applied over all externally callable functions, verifying that:

1. Both contracts begin from equivalent states (coupling invariant holds as precondition).
2. After any external call with any symbolic arguments, the coupling invariant is preserved.
3. Revert behaviour is identical: both contracts revert on the same inputs.

Certora verification links:

- Original vs. Cyfrin: https://prover.certora.com/output/480394/b892135b51124bc2ba3616346768252c?anonymousKey=9d0073a429fae0682c53e0ca1a24f59d66105135
- Original vs. Ours: https://prover.certora.com/output/480394/e9f73bda864d4b24a0e7ebf01d7d2006?anonymousKey=331441ecf82671285c1d6d955cfede979a96d058

Both verification runs issued proofs (no counterexamples). The transformations are therefore certified behaviourally equivalent to the original under the formal model defined in the framework.

---

## 4. Summary

| Metric                            | Cyfrin vs. Original | Ours vs. Original  | Ours vs. Cyfrin    |
|-----------------------------------|---------------------|--------------------|--------------------|
| Deploy cost (gas)                 | −34,297 (−1.11%)    | −159,067 (−5.14%)  | −124,770 (−4.07%)  |
| Deploy size (bytes)               | −158 (−1.11%)       | −737 (−5.16%)      | −579 (−4.10%)      |
| `claimAllRewards` avg             | +235                | −238               | −473               |
| `claimAllRewardsOnBehalf` avg     | +235                | −238               | −473               |
| `claimAllRewardsToSelf` avg       | +235                | −238               | −473               |
| `claimRewards` avg                | +297                | −151               | −448               |
| `claimRewardsOnBehalf` avg        | +297                | −151               | −448               |
| `claimRewardsToSelf` avg          | +297                | −151               | −448               |
| `configureAssets` avg             | −877                | −970               | −93                |
| `setTransferStrategy` avg         | 0                   | −12                | −12                |
| Formally verified                 | Yes                 | Yes                | —                  |

The principal source of savings in our variant is Rule 1 (Custom Errors), which removes all seven string literals from the deployed bytecode, yielding a 5.14% reduction in deployment cost. At runtime, the compound effect of Rules 9, 24, 25, 26, and 28 across the multiple nested loops of the claim and distribution functions produces savings of 151–238 gas (avg) per claim function. The Cyfrin variant, by contrast, introduces marginal regressions on claim functions due to structural refactoring, with its savings concentrated exclusively in deployment size and `configureAssets`.