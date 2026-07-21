# Gas Optimisation Report: `RewardsController`

**Contract:** `src/contracts/rewards/RewardsController.sol`
**Protocol:** AAVE V3 (`aave-v3-origin`, commit `464a0ea`, version 3.3)
**Versions analysed:** Original · Cyfrin-optimised · Our extended variant
**Verification tool:** Certora Prover

---

## 1. Transformations Applied

### 1.1 Cyfrin Optimisation

Cyfrin applied a single catalogue rule to this contract, **Rule 9 (No Explicit Zero Initialisation)**, alongside structural refactoring that is not covered by the catalogue. Comparing the Cyfrin version against the original, the observable modifications are:

**Rule 9 — Avoid Explicit Zero Initialisation:** loop counters changed from `uint256 i = 0` to `uint256 i` across all loops, eliminating the redundant explicit initialisation since `uint256` defaults to zero.

**Original (`configureAssets`, `_getUserAssetBalances`, `_claimAllRewards`, etc.):**

```solidity
for (uint256 i = 0; i < config.length; i++) {
```

**Cyfrin-optimised:**

```solidity
for (uint256 i; i < config.length; i++) {
```

**Rule 25 is not applied by Cyfrin in this contract.** The only cached length in the Cyfrin version, `rewardsListLength` in `_claimAllRewards`, is already present in the original. The loops over `assets.length` in `_getUserAssetBalances`, `_claimRewards` and `_claimAllRewards`, and the loop over `config.length` in `configureAssets`, all still re-read the length on every iteration.

Notably, Cyfrin does **not** apply `unchecked` increments, does not replace `require` statements with custom errors, does not cache array members, and does not apply Rule 15 (removal of `== true` / `== false` comparisons). These optimisations remain exclusively in our extended variant.

One structural difference in the Cyfrin version is the refactoring of `_claimAllRewards` and `_getUserAssetBalances` to use explicit `return` statements, and a restructuring of `_claimRewards` to use an early-return pattern (`if (amount == 0) return 0`). These are behavioural-equivalent reorganisations that affect code layout but not gas at the function call level in a meaningful way.

---

### 1.2 Our Extended Optimisation

Our variant was applied on top of Cyfrin's codebase and introduced **Rules 1, 15, 24, 25, 26, and 28**. Together with Cyfrin's Rule 9, the resulting contract instantiates seven distinct catalogue rules. The transformations are applied uniformly across all loops and guard conditions in the contract.

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
// Rule 1  - Replace require with custom errors
// Rule 15 - Reduce expressions: success == true → success
if (!success) revert TransferError();
```

**Original (`_installTransferStrategy`):**

```solidity
require(address(transferStrategy) != address(0), 'STRATEGY_CAN_NOT_BE_ZERO');
require(_isContract(address(transferStrategy)) == true, 'STRATEGY_MUST_BE_CONTRACT');
```

**Our optimisation:**

```solidity
// Rule 1  - Replace require with custom errors
if (address(transferStrategy) == address(0)) revert StrategyCanNotBeZero();
// Rule 15 - Reduce expressions: == true → bare boolean
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

All measurements were obtained with Foundry 1.7.1 (`forge test --gas-report --match-contract RewardsController_gas_Tests`) under the compiler configuration shipped with the AAVE V3 repository: solc 0.8.22, optimiser enabled, 200 runs, `shanghai` EVM target. Foundry's accounting for `view` calls has changed across releases; deployment cost, bytecode size, and the gas of state-modifying functions are stable across versions, whereas the absolute figures for `view` functions are not.

### 2.1 Deployment

| Version  | Deployment Cost (gas) | Deployment Size (bytes) |
|----------|-----------------------|------------------------|
| Original | 3,097,547             | 14,293                 |
| Cyfrin   | 3,063,250             | 14,135                 |
| Ours     | 2,774,654             | 12,799                 |

| Comparison          | Deploy Cost Savings      | Deploy Size Savings   |
|---------------------|--------------------------|-----------------------|
| Cyfrin vs. Original | 34,297 (−1.11%)          | 158 (−1.11%)          |
| Ours vs. Original   | 322,893 (−10.42%)        | 1,494 (−10.45%)       |
| Ours vs. Cyfrin     | 288,596 (−9.42%)         | 1,336 (−9.45%)        |

The dominant contributor to the deployment savings in our variant is Rule 1 (Custom Errors), which removes all seven error string literals from the deployed bytecode. The combined loop optimisations (Rules 9, 24, 25, 26, 28) contribute secondarily by reducing bytecode size through simplified loop preamble and increment logic. This is the largest absolute deployment reduction observed across the four contracts of the case study.

### 2.2 Function Execution

| Function                  | Original (avg) | Cyfrin (avg) | Ours (avg) | Cyfrin vs. Orig | Ours vs. Orig | Ours vs. Cyfrin |
|---------------------------|----------------|--------------|------------|-----------------|---------------|-----------------|
| `claimAllRewards`         | 124,558        | 124,793      | 124,168    | +235            | −390          | −625            |
| `claimAllRewardsOnBehalf` | 127,225        | 127,460      | 126,835    | +235            | −390          | −625            |
| `claimAllRewardsToSelf`   | 124,001        | 124,236      | 123,611    | +235            | −390          | −625            |
| `claimRewards`            | 74,100         | 74,397       | 73,785     | +297            | −315          | −612            |
| `claimRewardsOnBehalf`    | 76,841         | 77,138       | 76,526     | +297            | −315          | −612            |
| `claimRewardsToSelf`      | 73,620         | 73,917       | 73,305     | +297            | −315          | −612            |
| `configureAssets`         | 438,442        | 437,566      | 433,161    | −876            | −5,281        | −4,405          |
| `getClaimer`              | 2,625          | 2,625        | 2,625      | 0               | 0             | 0               |
| `getRewardOracle`         | 2,649          | 2,649        | 2,649      | 0               | 0             | 0               |
| `getTransferStrategy`     | 2,648          | 2,648        | 2,648      | 0               | 0             | 0               |
| `handleAction`            | 84,206         | 84,325       | 84,324     | +119            | +118          | −1              |
| `initialize`              | 53,154         | 53,154       | 53,154     | 0               | 0             | 0               |
| `setClaimer`              | 46,079         | 46,079       | 46,079     | 0               | 0             | 0               |
| `setRewardOracle`         | 32,042         | 32,042       | 32,042     | 0               | 0             | 0               |
| `setTransferStrategy`     | 31,655         | 31,655       | 31,643     | 0               | −12           | −12             |

**Observations:**

The Cyfrin version shows a **regression** in average gas for all `claim*` functions relative to the original (+235 to +297 gas). This is an artefact of the structural refactoring: the early-return pattern in `_claimRewards` (`if (amount == 0) return 0`) and the explicit `return` statements in `_claimAllRewards` and `_getUserAssetBalances` alter the code generation path. In test suites where the non-zero-amount path is exercised, these early guards add marginal overhead. The Rule 9 savings on loop initialisation are insufficient to offset this in the tested call patterns. Cyfrin's savings are concentrated in `configureAssets` (−876 gas avg).

Our variant recovers and surpasses the original for all `claim*` functions. The custom errors (Rule 1) reduce the revert-path bytecode size and improve the non-revert path through reduced `JUMPDEST` overhead. The cached array members (Rule 24), cached lengths (Rule 25) and the pre-increment/unchecked increments (Rules 26 and 28) compound across the six loops within `configureAssets`, `_getUserAssetBalances`, `_claimRewards`, and `_claimAllRewards`. Net savings against the original range from −315 gas (`claimRewards` avg) to −390 gas (`claimAllRewards` avg), and reach −5,281 gas in `configureAssets`.

`handleAction` shows a marginal regression in both optimised versions relative to the original: +119 gas (avg) in Cyfrin's and +118 gas (avg) in ours. This function delegates entirely to `_updateData` in the parent `RewardsDistributor`, with no transformations applied in `RewardsController` itself; the small variance is attributable to code layout changes affecting jump distances in the inherited call chain.

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
| `configureAssets`         | 270,156 | 438,442 | 270,156 | 1,038,219 | 20    |
| `getClaimer`              | 2,625   | 2,625   | 2,625   | 2,625     | 1     |
| `getRewardOracle`         | 2,649   | 2,649   | 2,649   | 2,649     | 1     |
| `getTransferStrategy`     | 2,648   | 2,648   | 2,648   | 2,648     | 1     |
| `handleAction`            | 32,360  | 84,206  | 59,937  | 130,417   | 25    |
| `initialize`              | 53,154  | 53,154  | 53,154  | 53,154    | 21    |
| `setClaimer`              | 46,079  | 46,079  | 46,079  | 46,079    | 5     |
| `setRewardOracle`         | 32,042  | 32,042  | 32,042  | 32,042    | 1     |
| `setTransferStrategy`     | 31,655  | 31,655  | 31,655  | 31,655    | 1     |

Call-weighted average over all functions: **153,329** gas.

**Cyfrin:**

| Function                  | min     | avg     | median  | max       | calls |
|---------------------------|---------|---------|---------|-----------|-------|
| `claimAllRewards`         | 58,471  | 124,793 | 124,793 | 191,116   | 2     |
| `claimAllRewardsOnBehalf` | 61,138  | 127,460 | 127,460 | 193,783   | 2     |
| `claimAllRewardsToSelf`   | 57,914  | 124,236 | 124,236 | 190,559   | 2     |
| `claimRewards`            | 53,202  | 74,397  | 74,397  | 95,593    | 2     |
| `claimRewardsOnBehalf`    | 55,943  | 77,138  | 77,138  | 98,334    | 2     |
| `claimRewardsToSelf`      | 52,722  | 73,917  | 73,917  | 95,113    | 2     |
| `configureAssets`         | 269,819 | 437,566 | 269,819 | 1,035,186 | 20    |
| `getClaimer`              | 2,625   | 2,625   | 2,625   | 2,625     | 1     |
| `getRewardOracle`         | 2,649   | 2,649   | 2,649   | 2,649     | 1     |
| `getTransferStrategy`     | 2,648   | 2,648   | 2,648   | 2,648     | 1     |
| `handleAction`            | 32,515  | 84,325  | 60,081  | 130,489   | 25    |
| `initialize`              | 53,154  | 53,154  | 53,154  | 53,154    | 21    |
| `setClaimer`              | 46,079  | 46,079  | 46,079  | 46,079    | 5     |
| `setRewardOracle`         | 32,042  | 32,042  | 32,042  | 32,042    | 1     |
| `setTransferStrategy`     | 31,655  | 31,655  | 31,655  | 31,655    | 1     |

Call-weighted average over all functions: **153,200** gas.

**Ours:**

| Function                  | min     | avg     | median  | max       | calls |
|---------------------------|---------|---------|---------|-----------|-------|
| `claimAllRewards`         | 58,166  | 124,168 | 124,168 | 190,171   | 2     |
| `claimAllRewardsOnBehalf` | 60,833  | 126,835 | 126,835 | 192,838   | 2     |
| `claimAllRewardsToSelf`   | 57,609  | 123,611 | 123,611 | 189,614   | 2     |
| `claimRewards`            | 52,898  | 73,785  | 73,785  | 94,673    | 2     |
| `claimRewardsOnBehalf`    | 55,639  | 76,526  | 76,526  | 97,414    | 2     |
| `claimRewardsToSelf`      | 52,418  | 73,305  | 73,305  | 94,193    | 2     |
| `configureAssets`         | 267,996 | 433,161 | 267,996 | 1,020,605 | 20    |
| `getClaimer`              | 2,625   | 2,625   | 2,625   | 2,625     | 1     |
| `getRewardOracle`         | 2,649   | 2,649   | 2,649   | 2,649     | 1     |
| `getTransferStrategy`     | 2,648   | 2,648   | 2,648   | 2,648     | 1     |
| `handleAction`            | 32,514  | 84,324  | 60,080  | 130,488   | 25    |
| `initialize`              | 53,154  | 53,154  | 53,154  | 53,154    | 21    |
| `setClaimer`              | 46,079  | 46,079  | 46,079  | 46,079    | 5     |
| `setRewardOracle`         | 32,042  | 32,042  | 32,042  | 32,042    | 1     |
| `setTransferStrategy`     | 31,643  | 31,643  | 31,643  | 31,643    | 1     |

Call-weighted average over all functions: **152,114** gas.

---

## 3. Formal Verification

Behavioural equivalence for both optimised versions against the original was verified using the Certora Prover. Due to the complexity of the contract's state — which spans inherited storage from `RewardsDistributor` including nested mappings over assets, rewards, and users — the coupling invariant is defined over ghost variables that mirror the full persistent storage.

The coupling invariant spans the entire observable state of both `RewardsController` and its parent `RewardsDistributor`, including all per-asset, per-reward, and per-user data structures. Ghost functions were required for `getScaledUserBalanceAndSupply` to resolve HAVOC states caused by the prover's inability to summarise the external `IScaledBalanceToken` calls. Ghost variables paired with `Sload`/`Sstore` hooks maintain consistency between ghost state and concrete EVM storage throughout symbolic execution.

For each pair (Original, Cyfrin) and (Original, Ours), the Certora rule `gasoptimisedCorrectness` was applied over all externally callable functions, verifying that:

1. Both contracts begin from equivalent states (coupling invariant holds as precondition).
2. After any external call with any symbolic arguments, the coupling invariant is preserved.
3. Revert behaviour is identical: both contracts revert on the same inputs.

Certora verification links:

- Original vs. Cyfrin: https://prover.certora.com/output/480394/4c990e48e4b048d9861efec041d59b9e?anonymousKey=50fb57accbc22b04d0a64730906f2ad8b1602353
- Original vs. Ours:  https://prover.certora.com/output/480394/5c6ffb5ceeb54212b0bf7f98e4c1ec61?anonymousKey=c95406254c2dfa3d5c242232c85d1a08a0af11b1

Both verification runs issued proofs (no counterexamples). The transformations are therefore certified behaviourally equivalent to the original under the formal model defined in the framework.

---

## 4. Summary

| Metric                            | Cyfrin vs. Original | Ours vs. Original  | Ours vs. Cyfrin    |
|-----------------------------------|---------------------|--------------------|--------------------|
| Rules applied (cumulative)        | 9                   | 9, 1, 15, 24, 25, 26, 28 | —            |
| Deploy cost (gas)                 | −34,297 (−1.11%)    | −322,893 (−10.42%) | −288,596 (−9.42%)  |
| Deploy size (bytes)               | −158 (−1.11%)       | −1,494 (−10.45%)   | −1,336 (−9.45%)    |
| Avg Fn. Gas                       | −129 (−0.08%)       | −1,215 (−0.79%)    | −1,086 (−0.71%)    |
| `claimAllRewards` avg             | +235                | −390               | −625               |
| `claimAllRewardsOnBehalf` avg     | +235                | −390               | −625               |
| `claimAllRewardsToSelf` avg       | +235                | −390               | −625               |
| `claimRewards` avg                | +297                | −315               | −612               |
| `claimRewardsOnBehalf` avg        | +297                | −315               | −612               |
| `claimRewardsToSelf` avg          | +297                | −315               | −612               |
| `configureAssets` avg             | −876                | −5,281             | −4,405             |
| `handleAction` avg                | +119                | +118               | −1                 |
| `setTransferStrategy` avg         | 0                   | −12                | −12                |
| Formally verified                 | Yes                 | Yes                | —                  |

The principal source of savings in our variant is Rule 1 (Custom Errors), which removes all seven string literals from the deployed bytecode; this is the largest absolute deployment reduction of the case study, at 10.42%. At runtime, the compound effect of Rules 9, 24, 25, 26, and 28 across the six loops of the claim and configuration functions produces savings of 315–390 gas (avg) per claim function and 5,281 gas in `configureAssets`. The Cyfrin variant, by contrast, introduces marginal regressions on claim functions due to structural refactoring, with its savings concentrated in deployment size and `configureAssets`.

`Avg Fn. Gas` denotes the call-count-weighted mean of the per-function average gas over all functions in the gas report, i.e. the sum of `avg × calls` divided by the total number of calls.