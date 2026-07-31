# Gas Optimisation Report: `Pool`

**Contract:** `src/contracts/protocol/pool/Pool.sol`
**Protocol:** AAVE V3 (`aave-v3-origin`, commit `464a0ea`, version 3.3)
**Versions analysed:** Original · Cyfrin-optimised · Our extended variant
**Verification tool:** Certora Prover

---

## 1. Transformations Applied

`Pool` is the protocol's entry point. It holds a seventeen-field reserve struct
per asset alongside the reserves list, the e-mode categories, and the per-user
configuration, and it delegates most logic to separately deployed libraries. It
is the largest subject in the case study: over four million gas to deploy and a
storage layout wide enough to force the field-wise coupling invariant described in
Section 3.

### 1.1 Cyfrin Optimisation

Cyfrin applies two rules.

**Rule 31 (Named Return Variables)** on the view getters that assemble a value
and return it: `getReserveData`, `getConfiguration`, `getUserConfiguration`,
`getReservesList`, `getEModeCategoryData`, `getEModeCategoryCollateralConfig`, and
`getEModeCategoryLabel`. Each promotes its return into the signature and drops the
local declaration and the trailing `return`.

```solidity
// Original
function getConfiguration(address asset)
    external view virtual override returns (DataTypes.ReserveConfigurationMap memory) {
  return _reserves[asset].configuration;
}

// Cyfrin
function getConfiguration(address asset)
    external view virtual override returns (DataTypes.ReserveConfigurationMap memory config) {
  config = _reserves[asset].configuration;
}
```

**Rule 9 (No Explicit Zero Initialisation)** on `getReservesList`, where
`uint256 droppedReservesCount = 0;` becomes `uint256 droppedReservesCount;`.

### 1.2 Our Extended Optimisation

On top of Cyfrin's version we apply two more rules.

**Rule 1 (Custom Errors)** replaces every `require` guard that carried an `Errors`
string constant. Eight custom errors are declared at contract level and used
across the access-control modifiers (`onlyUmbrella`, `_onlyPoolConfigurator`,
`_onlyPoolAdmin`, `_onlyBridge`), `finalizeTransfer`, the two reserve setters, the
three e-mode configuration functions, and `setLiquidationGracePeriod`.

```solidity
// Original / Cyfrin
function _onlyPoolAdmin() internal view virtual {
  require(
    IACLManager(ADDRESSES_PROVIDER.getACLManager()).isPoolAdmin(msg.sender),
    Errors.CALLER_NOT_POOL_ADMIN
  );
}

// Ours
error CallerNotPoolAdmin();
// ...
function _onlyPoolAdmin() internal view virtual {
  if (!IACLManager(ADDRESSES_PROVIDER.getACLManager()).isPoolAdmin(msg.sender))
    revert CallerNotPoolAdmin();
}
```

**Rule 26 (Pre-increment)** on the `getReservesList` loop, which also folds in the
implicit zero initialisation of the counter:

```solidity
// Cyfrin
for (uint256 i = 0; i < reservesListCount; i++) { ... }

// Ours
for (uint256 i; i < reservesListCount; ++i) { ... }
```

## 2. Gas Consumption Results

All measurements were obtained with Foundry 1.7.1 (`forge test --gas-report`)
under the compiler configuration shipped with the AAVE V3 repository: solc 0.8.22,
optimiser enabled, 200 runs, `shanghai` EVM target. `Pool` is abstract and
library-linked, so the figures come from a harness that deploys the contract
against a mock addresses provider and calls its view getters. The benchmark
exercises the read paths; the `require` guards rewritten by Rule 1 and the loop
rewritten by Rule 26 sit on the admin and state-changing functions, so their
effect shows up in deployment rather than in this runtime workload.

### 2.1 Deployment

| Version  | Deployment Cost (gas) | Deployment Size (bytes) |
|----------|----------------------:|------------------------:|
| Original | 4,683,996             | 21,704                  |
| Cyfrin   | 4,674,879             | 21,662                  |
| Ours     | 4,598,083             | 21,307                  |

| Comparison          | Deploy Cost Savings | Deploy Size Savings |
|---------------------|--------------------:|--------------------:|
| Cyfrin vs. Original | −9,117 (−0.19%)     | −42 (−0.19%)        |
| Ours vs. Original   | −85,913 (−1.83%)    | −397 (−1.83%)       |
| Ours vs. Cyfrin     | −76,796 (−1.64%)    | −355 (−1.64%)       |

Our variant removes eight `Error(string)` sites through Rule 1, which is the
dominant contributor to the −85,913 gas deployment reduction. Rule 26 and the
zero-init folding contribute the remainder by shrinking the loop instrumentation.

### 2.2 Function Execution

| Function                           | Original (avg) | Cyfrin (avg) | Ours (avg) |
|------------------------------------|---------------:|-------------:|-----------:|
| `getConfiguration`                 | 2,745          | 2,745        | 2,745      |
| `getUserConfiguration`             | 2,703          | 2,703        | 2,703      |
| `getReservesList`                  | 2,688          | 2,680        | 2,680      |
| `getReservesCount`                 | 2,414          | 2,414        | 2,414      |
| `getEModeCategoryCollateralConfig` | 2,885          | 2,885        | 2,885      |
| `getEModeCategoryLabel`            | 3,306          | 3,306        | 3,306      |

**Observations:**

The only measurable runtime delta among the benchmarked getters is
`getReservesList`, which drops from 2,688 to 2,680 gas (−8) once Cyfrin removes the
explicit zero initialisation and the separate `return`. Our Rule 26 rewrite of the
same loop leaves that figure unchanged. Every other getter reads storage directly
and is identical across the three versions. The value of the optimisations on
`Pool` is therefore in deployment, not in this read-only workload.

### 2.3 Detailed Gas Snapshots

Each getter is called once, so `min`, `avg`, `median`, and `max` coincide.

**Original:**

| Function                           | avg   | calls |
|------------------------------------|------:|------:|
| `getConfiguration`                 | 2,745 | 1     |
| `getUserConfiguration`             | 2,703 | 1     |
| `getReservesList`                  | 2,688 | 1     |
| `getReservesCount`                 | 2,414 | 1     |
| `getEModeCategoryCollateralConfig` | 2,885 | 1     |
| `getEModeCategoryLabel`            | 3,306 | 1     |

Call-weighted average over all functions: **2,790** gas.

**Cyfrin:**

| Function                           | avg   | calls |
|------------------------------------|------:|------:|
| `getConfiguration`                 | 2,745 | 1     |
| `getUserConfiguration`             | 2,703 | 1     |
| `getReservesList`                  | 2,680 | 1     |
| `getReservesCount`                 | 2,414 | 1     |
| `getEModeCategoryCollateralConfig` | 2,885 | 1     |
| `getEModeCategoryLabel`            | 3,306 | 1     |

Call-weighted average over all functions: **2,789** gas.

**Ours:** identical to Cyfrin at runtime (call-weighted average **2,789** gas);
`getReservesList` stays at 2,680, and no other getter changes.

## 3. Formal Verification

Behavioural equivalence for both optimised versions against the original was
verified with the Certora Prover. `Pool` holds a flat mapping of seventeen-field
reserve structs, which CVL can address field by field but cannot discharge when
the coupling invariant reads that many fields directly under a quantifier. The
invariant is therefore carried by ghost mappings synchronised with storage through
`Sload`/`Sstore` hooks: 56 ghost declarations, 108 hooks, and 60 conjuncts
covering the reserve struct, the e-mode categories, the reserves list, and the
per-user configuration.

```
definition couplingInv() returns bool =
    a.ADDRESSES_PROVIDER() == ao.ADDRESSES_PROVIDER() &&
    a._reservesCount == ao._reservesCount &&
    (forall address asset. ghost_a_r_cfg[asset] == ghost_ao_r_cfg[asset]) &&
    (forall address asset. ghost_a_r_li[asset]  == ghost_ao_r_li[asset])  &&
    // ... reserve fields, e-mode categories, reserves list, user config ...
    a.rdLiquidityIndex == ao.rdLiquidityIndex &&
    // ... return-capture slots ...
    a.labelLength == ao.labelLength;
```

The parametric rule `gasOptimizationCorrectness` was instantiated over fourteen
functions, checking that:

1. Both versions start from coupled states (coupling invariant as precondition).
2. After the call with any symbolic arguments, the coupling invariant is preserved.
3. Revert behaviour is identical: both versions revert on the same inputs.

Twelve of the fourteen rules are discharged under the field-wise coupling
invariant. The two that observe the e-mode `label`, a `string`, are discharged
under a whole-storage invariant that mirrors the raw slots, because CVL rejects a
`string` in a field-wise coupling invariant.

Certora verification links:

- Field-wise invariant (12 rules): [Orig–Cyfrin](https://prover.certora.com/output/480394/84a04747eae14dbe89160a4ce6d45da6?anonymousKey=5338c4f2c64311059e1eed7d183a2eaa41cd742e) · [Orig–Ours](https://prover.certora.com/output/480394/14f85676d3414d23a2d39712f176ad1a?anonymousKey=bddaa71b9cc9a866e6d6fcda763b776efb2af21e)
- Whole-storage invariant (2 e-mode label rules): [Orig–Cyfrin](https://prover.certora.com/output/480394/8e4eb844eee24ae29fc5171a97722a48?anonymousKey=9a05cdb263061db077aaa753a558e31086e39c4c) · [Orig–Ours](https://prover.certora.com/output/480394/9775711032914c39bb1b4d7c18b42db8?anonymousKey=d083658a443642ded870fd997714209134596d73)

Both runs issued proofs with no counterexamples. At this scale the prover ran for
over an hour per job, exceeding the CLI's fifteen-minute no-output timeout; the
results were retrieved by polling the job status to completion. Two settings from
AAVE's own Certora configuration were required: restricting parametric rule
instantiation to the two harnesses rather than every contract in the scene, and
raising the SMT timeout.

## 4. Summary

| Metric                     | Cyfrin vs. Original | Ours vs. Original | Ours vs. Cyfrin |
|----------------------------|---------------------|-------------------|-----------------|
| Rules applied (cumulative) | 9, 31               | 9, 31, 1, 26      | —               |
| Deploy cost (gas)          | −9,117 (−0.19%)     | −85,913 (−1.83%)  | −76,796 (−1.64%)|
| Deploy size (bytes)        | −42 (−0.19%)        | −397 (−1.83%)     | −355 (−1.64%)   |
| Avg Fn. Gas                | −1 (−0.05%)         | −1 (−0.05%)       | 0 (−0.00%)      |
| Formally verified          | Yes                 | Yes               | —               |

`Pool` is the case study's deployment-dominated subject. Rule 1 strips eight error
strings from the bytecode for the bulk of the −1.83% deployment reduction, while
the read paths keep their gas profile because the guards and loop it targets lie
outside the getter benchmark. It is also the subject that set the practical limits
of the method: the field-wise invariant would not discharge over direct storage
reads, the e-mode `label` needed a separate whole-storage invariant, and the
proofs ran long enough to expose the tooling's interactive-connection assumption.
