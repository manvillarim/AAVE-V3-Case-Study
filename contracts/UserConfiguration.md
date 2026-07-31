# Gas Optimisation Report: `UserConfiguration`

**Library:** `src/contracts/protocol/libraries/configuration/UserConfiguration.sol`
**Protocol:** AAVE V3 (`aave-v3-origin`, commit `464a0ea`, version 3.3)
**Versions analysed:** Original · Cyfrin-optimised · Our extended variant
**Verification tool:** Certora Prover

---

## 1. Transformations Applied

`UserConfiguration` implements the bitmap logic for per-user borrow and collateral
flags. Each user's state is a single packed `uint256`. The library is verified and
measured through a harness holding `mapping(address => DataTypes.UserConfigurationMap)`.

### 1.1 Cyfrin Optimisation

Cyfrin applies two rules.

**Rule 23 (Cache Storage Variables)**, enabled across library boundaries. Cyfrin
adds `setBorrowingInMemory` and `setUsingAsCollateralInMemory`, memory counterparts
of the two storage-writing setters. Their purpose is to let callers (`SupplyLogic`,
`BorrowLogic`, `LiquidationLogic`) read the user's configuration word once, mutate
the cached copy, and write it back once.

**Rule 31 (Named Return Variables)** on `_getFirstAssetIdByMask`.

### 1.2 Our Extended Optimisation

On top of Cyfrin's version we apply **Rule 1 (Custom Errors)** to all seven
occurrences of the reserve-index bound check:

```solidity
// Original / Cyfrin
require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);

// Ours
if (reserveIndex >= ReserveConfiguration.MAX_RESERVES_COUNT) revert InvalidReserveIndex();
```

The strings removed are AAVE error codes, two characters long. The saving comes
almost entirely from removing the `Error(string)` ABI-encoding sequence emitted at
each site, not from the string payload, which is why it scales with the number of
sites.

## 2. Gas Consumption Results

All measurements were obtained with Foundry 1.7.1 (`forge test --gas-report`)
under the compiler configuration shipped with the AAVE V3 repository: solc 0.8.22,
optimiser enabled, 200 runs, `shanghai` EVM target.

### 2.1 Deployment

| Version  | Deployment Cost (gas) | Deployment Size (bytes) |
|----------|----------------------:|------------------------:|
| Original | 398,559               | 1,626                   |
| Cyfrin   | 397,911               | 1,623                   |
| Ours     | 350,766               | 1,405                   |

| Comparison          | Deploy Cost Savings | Deploy Size Savings |
|---------------------|--------------------:|--------------------:|
| Cyfrin vs. Original | −648 (−0.16%)       | −3 (−0.18%)         |
| Ours vs. Original   | −47,793 (−11.99%)   | −221 (−13.59%)      |
| Ours vs. Cyfrin     | −47,145 (−11.85%)   | −218 (−13.43%)      |

Rule 1 drives the −11.99% deployment reduction, the largest relative bytecode-size
saving in the case study (−13.59%). The seven `Error(string)` sites and their
encoding sequences leave the deployed bytecode.

### 2.2 Function Execution

| Function                         | Original (avg) | Cyfrin (avg) | Ours (avg) |
|----------------------------------|---------------:|-------------:|-----------:|
| `setBorrowing`                   | 42,597         | 42,597       | 42,529     |
| `setUsingAsCollateral`           | 27,214         | 27,214       | 27,146     |
| `isBorrowing`                    | 2,797          | 2,797        | 2,729      |
| `isUsingAsCollateral`            | 2,847          | 2,847        | 2,779      |
| `isUsingAsCollateralOrBorrowing` | 2,782          | 2,782        | 2,714      |
| `isBorrowingAny`                 | 2,647          | 2,647        | 2,647      |
| `isEmpty`                        | 2,682          | 2,682        | 2,682      |
| `isUsingAsCollateralOne`         | 2,853          | 2,853        | 2,853      |
| `getFirstAssetIdByMask`          | 3,022          | 2,985        | 2,985      |

**Observations:**

Rule 1 saves exactly −68 gas on every function that contains a guarded bound check
(`isBorrowing`, `isUsingAsCollateral`, `isUsingAsCollateralOrBorrowing`,
`setBorrowing`, `setUsingAsCollateral`) and exactly 0 on the other four, which
contain none. The one Cyfrin runtime change is `getFirstAssetIdByMask` at −37 gas,
from the Rule 31 named return.

### 2.3 Detailed Gas Snapshots

The two setters are called ten times each; `setBorrowing` spans 27,207–44,307 gas
(the spread between updating an already-set bit and a fresh one), the other
functions are called once.

| Function                         | Original | Cyfrin | Ours   | calls |
|----------------------------------|---------:|-------:|-------:|------:|
| `setBorrowing` (avg)             | 42,597   | 42,597 | 42,529 | 10    |
| `setUsingAsCollateral` (avg)     | 27,214   | 27,214 | 27,146 | 10    |
| `isBorrowing`                    | 2,797    | 2,797  | 2,729  | 1     |
| `isUsingAsCollateral`            | 2,847    | 2,847  | 2,779  | 1     |
| `isUsingAsCollateralOrBorrowing` | 2,782    | 2,782  | 2,714  | 1     |
| `isBorrowingAny`                 | 2,647    | 2,647  | 2,647  | 1     |
| `isEmpty`                        | 2,682    | 2,682  | 2,682  | 1     |
| `isUsingAsCollateralOne`         | 2,853    | 2,853  | 2,853  | 1     |
| `getFirstAssetIdByMask`          | 3,022    | 2,985  | 2,985  | 1     |

Call-weighted average over all functions: **26,583** (Original), **26,582**
(Cyfrin), **26,524** (Ours) gas.

## 3. Formal Verification

Behavioural equivalence for both optimised versions against the original was
verified with the Certora Prover. The coupling invariant equates the packed
configuration word for every user and the two return-capture slots. CVL addresses
the packed word directly, so no ghost variables and no hooks are required.

```
definition couplingInv() returns bool =
    (forall address user.
        a._usersConfig[user].data == ao._usersConfig[user].data
    ) &&
    a.lastBoolReturn == ao.lastBoolReturn &&
    a.lastUintReturn == ao.lastUintReturn;
```

The two memory-variant functions have no counterpart in the original, so they are
verified against the storage-writing originals under the cache-modify-write-back
pattern their real call sites use:

```solidity
// harness, original side
function setUsingAsCollateralCached_instr(address user, uint256 i, bool v) external {
    _usersConfig[user].setUsingAsCollateral(i, v);
}

// harness, optimised side
function setUsingAsCollateralCached_instr(address user, uint256 i, bool v) external {
    DataTypes.UserConfigurationMap memory cache = _usersConfig[user];
    cache.setUsingAsCollateralInMemory(i, v);
    _usersConfig[user].data = cache.data;
}
```

The parametric equivalence rule was instantiated over thirteen functions, checking
that:

1. Both versions start from coupled states (coupling invariant as precondition).
2. After the call with any symbolic arguments, the coupling invariant is preserved.
3. Revert behaviour is identical: both versions revert on the same inputs.

Certora verification links:

- Original vs. Cyfrin: https://prover.certora.com/output/480394/f7f1a89c89374bf2ad4542bf3d4b769f?anonymousKey=99282080101c9b5fea57acecfe852959305e35ac
- Original vs. Ours: https://prover.certora.com/output/480394/d4e5c781fd9043cab9fcd306ef28c9fc?anonymousKey=030c19437db085ff7e861198dc94b5022404305c

Both runs completed with `exit_code=0` under `rule_sanity: basic` and no
counterexamples.

### Compiler sensitivity

Under the Via-IR pipeline the deployment result reverses: Cyfrin's version becomes
byte-identical to the original, since the unused memory variants are eliminated,
and our variant costs +0.40% more to deploy rather than less, while still saving
−0.42% at runtime. The Rule 1 deployment benefit measured here is specific to the
legacy code generator.

## 4. Summary

| Metric                     | Cyfrin vs. Original | Ours vs. Original | Ours vs. Cyfrin |
|----------------------------|---------------------|-------------------|-----------------|
| Rules applied (cumulative) | 23, 31              | 23, 31, 1         | —               |
| Deploy cost (gas)          | −648 (−0.16%)       | −47,793 (−11.99%) | −47,145 (−11.85%)|
| Deploy size (bytes)        | −3 (−0.18%)         | −221 (−13.59%)    | −218 (−13.43%)  |
| Avg Fn. Gas                | −1 (−0.01%)         | −59 (−0.22%)      | −58 (−0.22%)    |
| Formally verified          | Yes                 | Yes               | —               |

`UserConfiguration` shows how Rule 1 scales with the number of guarded sites:
seven bound checks give the largest relative deployment-size reduction in the case
study (−13.59%) and a fixed −68 gas at each of the five call sites that reach a
guard at runtime. The gain is specific to the legacy code generator, and reverses
under Via-IR.
