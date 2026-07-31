# Gas Optimisation Report: `MathUtils`

**Library:** `src/contracts/protocol/libraries/math/MathUtils.sol`
**Protocol:** AAVE V3 (`aave-v3-origin`, commit `464a0ea`, version 3.3)
**Versions analysed:** Original · Cyfrin-optimised · Our extended variant
**Verification tool:** Certora Prover

---

## 1. Transformations Applied

`MathUtils` is a library of `internal` functions with no persistent state. It is
inlined into every caller and has no independent deployed form, so it is verified
and measured through a harness that exposes its three functions externally.

### 1.1 Cyfrin Optimisation

Cyfrin applies **Rule 31 (Named Return Variables)** to `calculateLinearInterest`:
the local `result` is promoted to a named return and the trailing `return` is
removed.

```solidity
// Original
function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal view returns (uint256) {
  uint256 result = rate * (block.timestamp - uint256(lastUpdateTimestamp));
  unchecked { result = result / SECONDS_PER_YEAR; }
  return WadRayMath.RAY + result;
}

// Cyfrin
function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal view returns (uint256 result) {
  result = rate * (block.timestamp - uint256(lastUpdateTimestamp));
  unchecked { result = result / SECONDS_PER_YEAR; }
  result += WadRayMath.RAY;
}
```

### 1.2 Our Extended Optimisation

On top of Cyfrin's version we apply two rules:

* **Rule 31 (Named Return Variables)** to both `calculateCompoundedInterest`
  overloads, which Cyfrin left untouched;
* **Rule 15 (Reduce Expressions)** inside `calculateCompoundedInterest`, caching
  the common subexpression `exp * expMinusOne` that the original evaluates twice.

```solidity
// Original
uint256 secondTerm = exp * expMinusOne * basePowerTwo;
uint256 thirdTerm  = exp * expMinusOne * expMinusTwo * basePowerThree;

// Ours
uint256 expTimesExpMinusOne = exp * expMinusOne;
uint256 secondTerm = expTimesExpMinusOne * basePowerTwo;
uint256 thirdTerm  = expTimesExpMinusOne * expMinusTwo * basePowerThree;
```

Multiplication in Solidity associates to the left, so `exp * expMinusOne` is the
first product evaluated in both original expressions. Hoisting it preserves the
exact sequence of checked operations: the cached product overflows on precisely
the inputs on which the original's first multiplication overflows.

## 2. Gas Consumption Results

All measurements were obtained with Foundry 1.7.1 (`forge test --gas-report`)
under the compiler configuration shipped with the AAVE V3 repository: solc 0.8.22,
optimiser enabled, 200 runs, `shanghai` EVM target. `MathUtils` performs no
storage access, so its runtime figures isolate the arithmetic itself.

### 2.1 Deployment

| Version  | Deployment Cost (gas) | Deployment Size (bytes) |
|----------|----------------------:|------------------------:|
| Original | 246,652               | 925                     |
| Cyfrin   | 244,672               | 916                     |
| Ours     | 243,820               | 912                     |

| Comparison          | Deploy Cost Savings | Deploy Size Savings |
|---------------------|--------------------:|--------------------:|
| Cyfrin vs. Original | −1,980 (−0.80%)     | −9 (−0.97%)         |
| Ours vs. Original   | −2,832 (−1.15%)     | −13 (−1.41%)        |
| Ours vs. Cyfrin     | −852 (−0.35%)       | −4 (−0.44%)         |

### 2.2 Function Execution

| Function                         | Original (avg) | Cyfrin (avg) | Ours (avg) |
|----------------------------------|---------------:|-------------:|-----------:|
| `calculateLinearInterest`        | 666            | 665          | 665        |
| `calculateCompoundedInterest`    | 1,789          | 1,789        | 1,712      |
| `calculateCompoundedInterestNow` | 1,837          | 1,837        | 1,760      |

**Observations:**

Rule 15 saves −77 gas on both `calculateCompoundedInterest` overloads (−4.30% and
−4.19%). This is the largest relative runtime improvement in the case study,
because the subject performs no storage access to dilute it. `calculateLinearInterest`
is flat at runtime; the transformation there is Rule 31, whose effect is on the
deployed bytecode.

### 2.3 Detailed Gas Snapshots

Each function is called once, so `min`, `avg`, `median`, and `max` coincide.

| Function                         | Original | Cyfrin | Ours  |
|----------------------------------|---------:|-------:|------:|
| `calculateLinearInterest`        | 666      | 665    | 665   |
| `calculateCompoundedInterest`    | 1,789    | 1,789  | 1,712 |
| `calculateCompoundedInterestNow` | 1,837    | 1,837  | 1,760 |

Call-weighted average over all functions: **1,431** (Original), **1,430**
(Cyfrin), **1,379** (Ours) gas.

## 3. Formal Verification

Behavioural equivalence for both optimised versions against the original was
verified with the Certora Prover. The library holds no state, so the coupling
invariant is carried entirely by the return-capture instrumentation: three harness
slots holding the last value returned by each function. No ghost variables and no
hooks are required.

```
definition couplingInv() returns bool =
    a.lastLinearInterest == ao.lastLinearInterest &&
    a.lastCompoundedInterest == ao.lastCompoundedInterest &&
    a.lastCompoundedInterestNow == ao.lastCompoundedInterestNow;
```

For each pair (Original, Cyfrin) and (Original, Ours), the parametric equivalence
rule was instantiated once per function (three rules), checking that:

1. Both versions start from coupled states (coupling invariant as precondition).
2. After the call with any symbolic arguments, the coupling invariant is preserved.
3. Revert behaviour is identical: both versions revert on the same inputs. This is
   what certifies that the Rule 15 hoisting keeps the original's overflow points.

Certora verification links:

- Original vs. Cyfrin: https://prover.certora.com/output/480394/dcbf1aa316cb44048cc0380ffed5e051?anonymousKey=28c9fd6c8b316491c4bdae93baafb9aa3a411378
- Original vs. Ours: https://prover.certora.com/output/480394/d55b3f3b75f6485ebee29d9a55746c7f?anonymousKey=a66401490d393dac83b411e68efb6513d9848e5d

Both runs completed with `exit_code=0` under `rule_sanity: basic` and no
counterexamples.

## 4. Summary

| Metric                     | Cyfrin vs. Original | Ours vs. Original | Ours vs. Cyfrin |
|----------------------------|---------------------|-------------------|-----------------|
| Rules applied (cumulative) | 31                  | 31, 15            | —               |
| Deploy cost (gas)          | −1,980 (−0.80%)     | −2,832 (−1.15%)   | −852 (−0.35%)   |
| Deploy size (bytes)        | −9 (−0.97%)         | −13 (−1.41%)      | −4 (−0.44%)     |
| Avg Fn. Gas                | −1 (−0.02%)         | −52 (−3.61%)      | −51 (−3.59%)    |
| Formally verified          | Yes                 | Yes               | —               |

`MathUtils` carries the case study's largest relative runtime gain. Rule 15 removes
a repeated multiplication from both compounded-interest overloads for −4.30% and
−4.19% per call, undiluted by any storage access, and the equivalence proof
confirms the rewrite preserves the original's checked-arithmetic overflow points.
