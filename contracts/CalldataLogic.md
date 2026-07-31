# Gas Optimisation Report: `CalldataLogic`

**Library:** `src/contracts/protocol/libraries/logic/CalldataLogic.sol`
**Protocol:** AAVE V3 (`aave-v3-origin`, commit `464a0ea`, version 3.3)
**Versions analysed:** Original · Cyfrin-optimised · Our extended variant
**Verification tool:** Certora Prover

---

## 1. Transformations Applied

`CalldataLogic` decodes compressed L2 calldata. Each of its eight decoders is built
around an inline `assembly` block, and the surrounding Solidity does little more
than name the extracted fields and index `reservesList`.

### 1.1 Cyfrin Optimisation

Cyfrin applies a single rule to all eight decoders, **Rule 31 (Named Return
Variables)**. The local declarations are removed, the assembly block writes
directly into the named returns, and the trailing tuple `return` is dropped.

```solidity
// Original
function decodeSupplyParams(mapping(uint256 => address) storage reservesList, bytes32 args)
    internal view returns (address, uint256, uint16) {
  uint16 assetId; uint256 amount; uint16 referralCode;
  assembly { ... }
  return (reservesList[assetId], amount, referralCode);
}

// Cyfrin
function decodeSupplyParams(mapping(uint256 => address) storage reservesList, bytes32 args)
    internal view returns (address addr, uint256 amount, uint16 referralCode) {
  uint16 assetId;
  assembly { ... }
  addr = reservesList[assetId];
}
```

### 1.2 Our Extended Optimisation

None. No further catalogue rule matches the remaining code: there are no loops, no
repeated storage reads, no redundant comparisons, no explicit zero initialisations,
and no `require` statements left to convert. Our variant is therefore byte-identical
to Cyfrin's, and we report it as a null result rather than suppress it.

## 2. Gas Consumption Results

All measurements were obtained with Foundry 1.7.1 (`forge test --gas-report`)
under the compiler configuration shipped with the AAVE V3 repository: solc 0.8.22,
optimiser enabled, 200 runs, `shanghai` EVM target. `CalldataLogic` is a library,
so the figures come from a harness that seeds two reserves and calls the decoders
externally.

### 2.1 Deployment

| Version  | Deployment Cost (gas) | Deployment Size (bytes) |
|----------|----------------------:|------------------------:|
| Original | 399,279               | 1,629                   |
| Cyfrin   | 390,847               | 1,590                   |
| Ours     | 390,847               | 1,590                   |

| Comparison          | Deploy Cost Savings | Deploy Size Savings |
|---------------------|--------------------:|--------------------:|
| Cyfrin vs. Original | −8,432 (−2.11%)     | −39 (−2.39%)        |
| Ours vs. Original   | −8,432 (−2.11%)     | −39 (−2.39%)        |
| Ours vs. Cyfrin     | 0 (0.00%)           | 0 (0.00%)           |

Rule 31 removes the local declarations and the tuple `return` construction from
eight decoders, which is where the −2.11% deployment saving comes from.

### 2.2 Function Execution

| Function                                    | Original (avg) | Cyfrin / Ours (avg) |
|---------------------------------------------|---------------:|--------------------:|
| `decodeSupplyParams`                        | 2,742          | 2,747               |
| `decodeSupplyWithPermitParams`              | 2,942          | 2,916               |
| `decodeWithdrawParams`                      | 2,677          | 2,663               |
| `decodeBorrowParams`                        | 2,763          | 2,763               |
| `decodeRepayParams`                         | 2,824          | 2,809               |
| `decodeRepayWithPermitParams`               | 2,978          | 2,940               |
| `decodeSetUserUseReserveAsCollateralParams` | 2,552          | 2,552               |
| `decodeLiquidationCallParams`               | 5,109          | 5,088               |

**Observations:**

The rewrite saves between −14 and −38 gas on five of the eight decoders, has no
effect on two, and costs +5 gas on `decodeSupplyParams`. Named returns are not
monotonically beneficial even within a single library: the compiler can spill a
named return to memory where the original held a tuple element on the stack, which
is what raises `decodeSupplyParams`.

### 2.3 Detailed Gas Snapshots

`setReserve` is the harness helper that seeds the reserves list; it is identical
across versions. The call-weighted average below matches the reported **Avg Fn.
Gas** and is dominated by that helper.

**Original:**

| Function                                    | avg    | calls |
|---------------------------------------------|-------:|------:|
| `decodeSupplyParams`                        | 2,742  | 1     |
| `decodeSupplyWithPermitParams`              | 2,942  | 1     |
| `decodeWithdrawParams`                      | 2,677  | 1     |
| `decodeBorrowParams`                        | 2,763  | 1     |
| `decodeRepayParams`                         | 2,824  | 1     |
| `decodeRepayWithPermitParams`               | 2,978  | 1     |
| `decodeSetUserUseReserveAsCollateralParams` | 2,552  | 1     |
| `decodeLiquidationCallParams`               | 5,109  | 1     |
| `setReserve` (harness)                      | 43,882 | 16    |

Call-weighted average over all functions: **30,279** gas.

**Cyfrin and Ours** (byte-identical): decoders take the Cyfrin values above, with
`setReserve` unchanged at 43,882 gas. Call-weighted average over all functions:
**30,275** gas.

## 3. Formal Verification

Behavioural equivalence for both optimised versions against the original was
verified with the Certora Prover. The decoders are `view` and return between two
and five values each, so the coupling invariant is carried by nine return-capture
slots plus the reserves list. No ghost variables and no hooks are needed.

```
definition couplingInv() returns bool =
    (forall uint256 id. a._reservesList[id] == ao._reservesList[id]) &&
    a.lastAsset == ao.lastAsset && a.lastAsset2 == ao.lastAsset2 &&
    a.lastUser == ao.lastUser && a.lastAmount == ao.lastAmount &&
    a.lastInterestRateMode == ao.lastInterestRateMode &&
    a.lastDeadline == ao.lastDeadline &&
    a.lastReferralCode == ao.lastReferralCode &&
    a.lastPermitV == ao.lastPermitV && a.lastFlag == ao.lastFlag;
```

The inline assembly needs no special handling: the Certora Prover reasons over
compiled bytecode, in which a Yul block is indistinguishable from any other code.
For `CalldataLogic`, assembly is an obstacle to matching a catalogue rule, not to
verifying one.

For each pair (Original, Cyfrin) and (Original, Ours), the parametric equivalence
rule was instantiated over the decoders (nine rules), checking that:

1. Both versions start from coupled states (coupling invariant as precondition).
2. After the call with any symbolic arguments, the coupling invariant is preserved.
3. Revert behaviour is identical: both versions revert on the same inputs.

Certora verification links:

- Original vs. Cyfrin: https://prover.certora.com/output/480394/aa5f2052ccba497a81aba484b15bd2bc?anonymousKey=e518eaf2f9dd75ef62d809abc45367a7a89f508b
- Original vs. Ours: https://prover.certora.com/output/480394/78da7e5b9128487abb9e56e300a67a66?anonymousKey=c7d7cc5669c7965fb69b5a3c909162f605321cc2

Both runs completed with `exit_code=0` under `rule_sanity: basic` and no
counterexamples. The two runs exercise the same optimised source through different
configurations, since our variant coincides with Cyfrin's here.

## 4. Summary

| Metric                     | Cyfrin vs. Original | Ours vs. Original | Ours vs. Cyfrin |
|----------------------------|---------------------|-------------------|-----------------|
| Rules applied (cumulative) | 31                  | 31                | —               |
| Deploy cost (gas)          | −8,432 (−2.11%)     | −8,432 (−2.11%)   | 0 (0.00%)       |
| Deploy size (bytes)        | −39 (−2.39%)        | −39 (−2.39%)      | 0 (0.00%)       |
| Avg Fn. Gas                | −4 (−0.01%)         | −4 (−0.01%)       | 0 (0.00%)       |
| Formally verified          | Yes                 | Yes               | —               |

`CalldataLogic` is the case study's null result on the extended side: once Cyfrin
has applied Rule 31 to the decoders, no catalogue rule matches the assembly-heavy
remainder, so our variant equals Cyfrin's. It still verifies, and it shows that a
single rule can be non-uniform in its runtime effect, saving on five decoders and
costing five gas on one.
