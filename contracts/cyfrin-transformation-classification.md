# Classification of the Cyfrin audit against the catalogue

Every transformation the Cyfrin audit applies to `aave-v3-origin`, classified by
file and by transformation kind. This table is the evidence behind the coverage
figures reported in the *Threats to Validity* section of the paper.

## Counting rule

A **pair** is a (file, transformation kind) combination, counted **once per file**
however many sites in that file exhibit it. A kind is **matched** when some rule of
the catalogue expresses it, and **unmatched** when it is a structural refactoring
that no rule-based catalogue expresses.

Two kinds that look alike are kept apart:

- **cache storage variable** — a storage slot is read once into a local and reused
  inside one function body. Caller-invisible.
- **parameter data location** — a parameter's declared location changes from
  `storage` to `memory`, which changes the signature. Caller-visible, and no
  catalogue rule covers it.

## Matched kinds

| Kind | Catalogue rule |
|---|---|
| NR | `named-return-variables` |
| ZI | `avoid-zero-initialization` |
| CS | `cache-storage-variables` |
| CL | `cache-array-length` |
| CM | `cache-member-variables` |
| RE | `reduce-expressions` |
| SC | `short-circuiting` |
| LM | `limit-modifiers` |
| WD | `write-values-directly` |

## Unmatched kinds

| Kind | Description |
|---|---|
| SL | promoting struct fields to stack locals (removing an auxiliary memory struct) |
| NS | narrowing an internal helper signature |
| DL | changing a parameter data location from `storage` to `memory` |
| WF | rewriting a `while` loop as a `for` loop |
| RP | restructuring return paths (inverting an early-return guard) |

## Per-file classification

| # | File | Matched | Unmatched | Pairs |
|---|---|---|---|---|
| 1 | `PoolAddressesProviderRegistry` | CS | — | 1 |
| 2 | `UserConfiguration` | NR | DL | 2 |
| 3 | `MathUtils` | NR | — | 1 |
| 4 | `CalldataLogic` | NR | — | 1 |
| 5 | `ReserveLogic` | NR | — | 1 |
| 6 | `Pool` | NR, ZI | — | 2 |
| 7 | `RewardsController` | NR, ZI | RP | 3 |
| 8 | `RewardsDistributor` | NR, ZI, CL, CS, WD | RP | 6 |
| 9 | `Collector` | NR, LM, RE, CM, WD | SL | 6 |
| 10 | `BorrowLogic` | NR, ZI, CS | — | 3 |
| 11 | `SupplyLogic` | NR, CS | — | 2 |
| 12 | `ValidationLogic` | NR | DL, NS | 3 |
| 13 | `GenericLogic` | NR, CS | SL, WF | 4 |
| 14 | `LiquidationLogic` | NR, CS | SL, DL | 4 |
| | **Total** | **29** | **10** | **39** |

## Totals

- **39** pairs across the fourteen modified files.
- **29** match a catalogue rule; **10** do not.
- **NR** is the most frequent single kind: it occurs in **13 of the 14 files**,
  every one except `PoolAddressesProviderRegistry`. This is the observation that
  led us to add the named-return rule to the catalogue.
- The ten unmatched pairs cover five distinct kinds: `SL` in three files, `DL` in
  three, `RP` in two, and `NS` and `WF` in one each.

## Reproducing

The classification is read off the diffs:

```bash
diff -rq aave-v3-origin/src aave-v3-origin-liquidation-gas-fixes/src   # the 14 files
diff -u  aave-v3-origin/src/<path> aave-v3-origin-liquidation-gas-fixes/src/<path>
```

The NR column is checkable mechanically, by comparing the set of functions whose
`returns` clause names its variables on each side.
