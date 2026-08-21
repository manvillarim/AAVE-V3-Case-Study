# Gas Optimisation Report: `ReserveLogic`

**Library:** `src/contracts/protocol/libraries/logic/ReserveLogic.sol`
**Protocol:** AAVE V3 (`aave-v3-origin`, commit `464a0ea`, version 3.3)
**Versions analysed:** Original · Cyfrin-optimised · Our extended variant
**Verification tool:** Certora Prover

---

## 1. Transformations Applied

`ReserveLogic` maintains the per-reserve accounting state: the liquidity and
borrow indexes, the associated rates, and the reserve cache assembled before each
state update. It is a library of `internal` functions inlined into its callers,
so it is verified and measured through a harness that seeds one reserve and
exposes the functions externally.

### 1.1 Cyfrin Optimisation

Cyfrin applies **Rule 31 (Named Return Variables)** to the two functions that
build a value and hand it back, `cumulateToLiquidityIndex` and `cache`. The local
declaration is dropped, the named return is written in place, and the trailing
`return` is removed.

```solidity
// Original
function cumulateToLiquidityIndex(...) internal returns (uint256) {
  uint256 result = (amount.wadToRay().rayDiv(totalLiquidity.wadToRay()) + WadRayMath.RAY)
      .rayMul(reserve.liquidityIndex);
  reserve.liquidityIndex = result.toUint128();
  return result;
}

// Cyfrin
function cumulateToLiquidityIndex(...) internal returns (uint256 result) {
  result = (amount.wadToRay().rayDiv(totalLiquidity.wadToRay()) + WadRayMath.RAY)
      .rayMul(reserve.liquidityIndex);
  reserve.liquidityIndex = result.toUint128();
}
```

The same rewrite removes the `DataTypes.ReserveCache memory reserveCache;`
declaration and the trailing `return reserveCache;` from `cache`.

### 1.2 Our Extended Optimisation

On top of Cyfrin's version we apply **Rule 1 (Custom Errors)** to the single
`require` in `init`:

```solidity
// Original / Cyfrin
require(reserve.aTokenAddress == address(0), Errors.RESERVE_ALREADY_INITIALIZED);

// Ours
error ReserveAlreadyInitialized();
// ...
if (reserve.aTokenAddress != address(0)) revert ReserveAlreadyInitialized();
```

The saving comes from removing the `Error(string)` ABI-encoding sequence and the
`RESERVE_ALREADY_INITIALIZED` literal from the deployed bytecode.

## 2. Gas Consumption Results

All measurements were obtained with Foundry 1.7.1 (`forge test --gas-report`)
under the compiler configuration shipped with the AAVE V3 repository: solc 0.8.22,
optimiser enabled, 200 runs, `shanghai` EVM target. `ReserveLogic` is a library,
so the figures come from a harness that seeds one reserve and calls the functions
externally.

### 2.1 Deployment

| Version  | Deployment Cost (gas) | Deployment Size (bytes) |
|----------|----------------------:|------------------------:|
| Original | 486,386               | 2,033                   |
| Cyfrin   | 486,158               | 2,032                   |
| Ours     | 461,940               | 1,920                   |

| Comparison          | Deploy Cost Savings | Deploy Size Savings |
|---------------------|--------------------:|--------------------:|
| Cyfrin vs. Original | −228 (−0.05%)       | −1 (−0.05%)         |
| Ours vs. Original   | −24,446 (−5.03%)    | −113 (−5.56%)       |
| Ours vs. Cyfrin     | −24,218 (−4.98%)    | −112 (−5.51%)       |

Rule 1 accounts for almost the entire deployment reduction in our variant.
Cyfrin's named-return rewrite leaves the bytecode nearly unchanged, whereas
removing the one `Error(string)` site strips its literal and encoding sequence.

### 2.2 Function Execution

| Function                   | Original (avg) | Cyfrin (avg) | Ours (avg) |
|----------------------------|---------------:|-------------:|-----------:|
| `cumulateToLiquidityIndex` | 28,031         | 28,032       | 28,032     |
| `getNormalizedDebt`        | 6,424          | 6,424        | 6,347      |
| `getNormalizedIncome`      | 5,257          | 5,252        | 5,252      |
| `init`                     | 133,347        | 133,335      | 133,264    |

| Function                   | Cyfrin vs. Original | Ours vs. Original | Ours vs. Cyfrin |
|----------------------------|--------------------:|------------------:|----------------:|
| `cumulateToLiquidityIndex` | +1                  | +1                | 0               |
| `getNormalizedDebt`        | 0                   | −77               | −77             |
| `getNormalizedIncome`      | −5                  | −5                | 0               |
| `init`                     | −12                 | −83               | −71             |

**Observations:**

Runtime is essentially unchanged. The transformations move work off the deployed
bytecode rather than out of any execution path, so the per-function deltas stay
within a few tens of gas and reflect the optimiser re-laying out the contract
after the bytecode shrinks. The largest is `init` at −83 gas (−0.06%), the site
of the Rule 1 conversion.

### 2.3 Detailed Gas Snapshots

`seed` is the harness helper that populates one reserve before the read-path
functions run; it is identical across versions.

**Original:**

| Function                   | min     | avg     | median  | max     | calls |
|----------------------------|--------:|--------:|--------:|--------:|------:|
| `cumulateToLiquidityIndex` | 28,031  | 28,031  | 28,031  | 28,031  | 1     |
| `getNormalizedDebt`        | 6,424   | 6,424   | 6,424   | 6,424   | 1     |
| `getNormalizedIncome`      | 5,257   | 5,257   | 5,257   | 5,257   | 1     |
| `init`                     | 133,347 | 133,347 | 133,347 | 133,347 | 1     |
| `seed` (harness)           | 87,959  | 87,959  | 87,959  | 87,959  | 4     |

Call-weighted average over all functions: **65,612** gas.

**Cyfrin:**

| Function                   | min     | avg     | median  | max     | calls |
|----------------------------|--------:|--------:|--------:|--------:|------:|
| `cumulateToLiquidityIndex` | 28,032  | 28,032  | 28,032  | 28,032  | 1     |
| `getNormalizedDebt`        | 6,424   | 6,424   | 6,424   | 6,424   | 1     |
| `getNormalizedIncome`      | 5,252   | 5,252   | 5,252   | 5,252   | 1     |
| `init`                     | 133,335 | 133,335 | 133,335 | 133,335 | 1     |
| `seed` (harness)           | 87,959  | 87,959  | 87,959  | 87,959  | 4     |

Call-weighted average over all functions: **65,610** gas.

**Ours:**

| Function                   | min     | avg     | median  | max     | calls |
|----------------------------|--------:|--------:|--------:|--------:|------:|
| `cumulateToLiquidityIndex` | 28,032  | 28,032  | 28,032  | 28,032  | 1     |
| `getNormalizedDebt`        | 6,347   | 6,347   | 6,347   | 6,347   | 1     |
| `getNormalizedIncome`      | 5,252   | 5,252   | 5,252   | 5,252   | 1     |
| `init`                     | 133,264 | 133,264 | 133,264 | 133,264 | 1     |
| `seed` (harness)           | 87,959  | 87,959  | 87,959  | 87,959  | 4     |

Call-weighted average over all functions: **65,591** gas.

## 3. Formal Verification

Behavioural equivalence for both optimised versions against the original was
verified with the Certora Prover. The coupling invariant equates the two versions
field by field over the reserve struct and over the reserve-cache values each
function returns. The reserve state is a mapping of wide structs, so the invariant
is carried by ghost mappings synchronised with storage through `Sload`/`Sstore`
hooks: 27 ghost declarations, 48 hooks, and 28 conjuncts.

```
definition couplingInv() returns bool =
    (forall address asset. ghost_a_cfg[asset] == ghost_ao_cfg[asset]) &&
    (forall address asset. ghost_a_li[asset]  == ghost_ao_li[asset])  &&
    // ... ten further reserve fields ...
    a.lastNormalizedIncome == ao.lastNormalizedIncome &&
    a.lastNormalizedDebt   == ao.lastNormalizedDebt   &&
    a.lastCumulateIndex    == ao.lastCumulateIndex    &&
    // ... reserve-cache return slots ...
    a.cReserveLastUpdateTimestamp == ao.cReserveLastUpdateTimestamp;
```

For each pair (Original, Cyfrin) and (Original, Ours), the parametric rule
`gasOptimizationCorrectness` was instantiated over the six verified functions
(`getNormalizedIncome`, `getNormalizedDebt`, `cumulateToLiquidityIndex`, `cache`,
`updateState`, `init`), checking that:

1. Both versions start from coupled states (coupling invariant as precondition).
2. After the call with any symbolic arguments, the coupling invariant is preserved.
3. Revert behaviour is identical: both versions revert on the same inputs.

Certora verification links:

- Original vs. Cyfrin: https://prover.certora.com/output/480394/344d6ed8f08843ba9b4b325bfc0dee85?anonymousKey=a45de91d0d078db1c75c63f6f6ec845100665eef
- Original vs. Ours: https://prover.certora.com/output/480394/3ead42f6aebd4185b6d9107e40293c44?anonymousKey=da1551d0bb2224aba80e8f64be6abd8c011aaa94

Both runs issued proofs with no counterexamples.

## 4. Summary

| Metric                     | Cyfrin vs. Original | Ours vs. Original | Ours vs. Cyfrin |
|----------------------------|---------------------|-------------------|-----------------|
| Rules applied (cumulative) | 31                  | 31, 1             | —               |
| Deploy cost (gas)          | −228 (−0.05%)       | −24,446 (−5.03%)  | −24,218 (−4.98%)|
| Deploy size (bytes)        | −1 (−0.05%)         | −113 (−5.56%)     | −112 (−5.51%)   |
| Avg Fn. Gas                | −2 (−0.00%)         | −20 (−0.03%)      | −18 (−0.03%)    |
| Formally verified          | Yes                 | Yes               | —               |

The saving is concentrated in deployment. Rule 1 removes the one `Error(string)`
site from the bytecode for a −5.03% deployment reduction, while the read and
update paths keep their gas profile. Cyfrin's Rule 31 rewrite is behaviour- and
gas-neutral here, so our variant contributes the whole of the measurable gain.
