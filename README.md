# AAVE V3 Case Study

This directory contains the artifacts for the AAVE V3 case study from the work *"Ensuring Gas Optimisation Correctness by Behavioural Equivalence"*.

---


## Authors

Manoel Felipe Araújo Villarim[0009-0005-6045-4519] - mfav@cin.ufpe.br

Juliano Manabu Iyoda[0000-0001-7137-8287] - jmi@cin.ufpe.br

Márcio Lopes Cornélio[0000-0002-9801-4659] - mlc2@cin.ufpe.br

Alexandre Cabral Mota[0000-0003-4416-8123] - acm@cin.ufpe.br



## Structure

```
.
├── aave-v3-origin/                       # Original AAVE V3 codebase (commit 464a0ea, v3.3)
├── aave-v3-origin-liquidation-gas-fixes/ # Cyfrin-optimised variant
├── aave-v3-origin-full-optimized/        # Our extended variant
├── aave-v3-origin-renamed/               # Generated. Original tree with the colliding
│                                         #   external library names alpha-renamed, used
│                                         #   only by the Pool harness (see "Pool subject")
├── aave-v3-origin-instr/                 # Generated. The three trees above with an empty
├── aave-v3-origin-liquidation-gas-fixes-instr/   #   recorder call after every emit, so
├── aave-v3-origin-full-optimized-instr/  #   the coupling invariant can compare the log.
│                                         #   Only the prover reads these; the gas
│                                         #   benchmark reads the pristine trees.
├── conf/                                 # Certora configuration files for this case study
├── contracts/                            # Gas optimisation reports per subject
│   ├── PoolAddressesProviderRegistry.md
│   ├── RewardsController.md
│   ├── RewardsDistributor.md
│   ├── Collector.md
│   ├── Pool.md
│   ├── MathUtils.md
│   ├── UserConfiguration.md
│   ├── CalldataLogic.md
│   ├── ReserveLogic.md
│   └── cyfrin-transformation-classification.md
│                                         #   Classification of the Cyfrin diff
│                                         #   against the catalogue
├── gas/                                  # Foundry project measuring the library subjects
│                                         #   and Pool under both compiler profiles
├── Harness/                              # Harness contracts for Certora verification
├── specs/                                # CVL specifications for this case study
│   └── Structures/                       #   Ghost state shared by the specs above
├── scripts/                              # Generators for the four trees above, and a
│                                         #   wiring check over conf/
└── license.txt
```

---

## Contract Reports

Detailed reports for each analysed contract, covering the transformations applied, code diffs, gas snapshots, and formal verification links, are available in `contracts/`:

| Contract | Report |
|----------|--------|
| `PoolAddressesProviderRegistry` | [contracts/PoolAddressesProviderRegistry.md](contracts/PoolAddressesProviderRegistry.md) |
| `RewardsController` | [contracts/RewardsController.md](contracts/RewardsController.md) |
| `RewardsDistributor` | [contracts/RewardsDistributor.md](contracts/RewardsDistributor.md) |
| `Collector` | [contracts/Collector.md](contracts/Collector.md) |
| `Pool` | [contracts/Pool.md](contracts/Pool.md) |
| `MathUtils` | [contracts/MathUtils.md](contracts/MathUtils.md) |
| `UserConfiguration` | [contracts/UserConfiguration.md](contracts/UserConfiguration.md) |
| `CalldataLogic` | [contracts/CalldataLogic.md](contracts/CalldataLogic.md) |
| `ReserveLogic` | [contracts/ReserveLogic.md](contracts/ReserveLogic.md) |

[contracts/cyfrin-transformation-classification.md](contracts/cyfrin-transformation-classification.md)
sits alongside them and classifies every edit of the Cyfrin diff against the
catalogue of transformations, including the files no subject covers.

### Subject coverage

The Cyfrin audit modifies 14 `.sol` files: 5 contracts and 9 libraries. **Every
contract it modifies is covered here** — `PoolAddressesProviderRegistry`,
`RewardsController`, `RewardsDistributor`, `Collector` and `Pool` — together with
4 of the 9 libraries (`MathUtils`, `UserConfiguration`, `CalldataLogic`,
`ReserveLogic`).

The five libraries not covered — `GenericLogic`, `ValidationLogic`,
`SupplyLogic`, `BorrowLogic` and `LiquidationLogic` — operate on the reserve and
user state owned by `Pool` and reach external aToken, debt-token and oracle
contracts, so a faithful harness for any of them would have to reconstruct the
whole `Pool` state.

### The `Pool` subject

`Pool` links seven external logic libraries plus `DataTypes`, all of which carry
the same names in the original and optimised trees and therefore collide in the
prover's scene. `aave-v3-origin-renamed/` is a scripted alpha-renaming of the
original tree that resolves this; it is generated, not hand-edited, and only the
`Pool` harness imports from it.

---

## Requirements

1. [Certora Prover](https://www.certora.com/) — the `certora-cli` package, with the API key
   exported as `CERTORAKEY`. All 20 configurations set `"server": "production"`, so every
   run is a cloud job. Developed against `certora-cli` 8.8.0.
2. [Foundry Framework](https://getfoundry.sh/) — `forge`. Developed against forge 1.7.1.
3. `solc` on the `PATH`. No configuration pins a compiler version for the prover, so it uses
   whichever is installed (0.8.26 in the environment these runs were made in); the
   configurations set the optimiser, the EVM version and the Yul pipeline themselves. Every
   Foundry project here pins `0.8.22` in its own `foundry.toml`, so `forge` fetches that
   compiler itself and the gas figures do not depend on what is on the `PATH`.
4. Python 3, for the two tree generators and for `scripts/check_conf_wiring.py`.

The Foundry dependencies of the three subject trees — `forge-std`, `solidity-utils` and the
OpenZeppelin trees below it — are committed as ordinary files rather than submodules, even
though `aave-v3-origin/.gitmodules` still declares them as such. A clone gets them directly:
neither `git submodule update` nor `forge install` is needed.

---

## Formal Verification

### 1. Build the generated trees

Four of the trees the prover reads are generated from the three pristine ones and
are not checked in, because they are reproducible and would otherwise be a second
copy of the protocol to keep in step. Build them once, from the **repository
root**, before any verification run:

```bash
bash scripts/make_instrumented.sh       # the three *-instr trees
bash scripts/make_renamed_original.sh   # aave-v3-origin-renamed, used by the Pool harness
```

`scripts/check_conf_wiring.py` reports whether every configuration can find the
files, specs, packages and imports it names. It compiles nothing, so it separates
a wiring problem from a Solidity or CVL one:

```bash
python3 scripts/check_conf_wiring.py    # 20 configurations checked, 0 problems
```

### 2. Run a configuration

```bash
certoraRun --prover_version master conf/<NAME_OF_CONF_FILE>.conf
```

There are 20 configurations, two per subject: `<Subject>.conf` compares the
original against the Cyfrin variant and `<Subject>Ours.conf` against ours. `Pool`
carries two more, `PoolLabel.conf` and `PoolOursLabel.conf`, which discharge the
two rules that observe the e-mode `label` string under the whole-storage coupling
invariant of `specs/PoolStorageEq.spec`. The two sides of a comparison differ only
in the tree that the `aave-v3-origin-optimized` and `aave-v3-origin-optimized-instr`
packages resolve to, so switching baseline is a conf edit and never a harness edit.

To typecheck without consuming prover time, add `--compilation_steps_only`.

---

## Gas Benchmarking

### Library subjects and `Pool`

`gas/` reaches the three subject trees through `gas/lib/`, which holds symlinks rather than
vendored copies so that the benchmark always measures the same source the prover verifies.
The directory is not checked in, so recreate it once after cloning, from the **repository
root**:

```bash
mkdir -p gas/lib
ln -sfn ../../aave-v3-origin                        gas/lib/origin
ln -sfn ../../aave-v3-origin-liquidation-gas-fixes  gas/lib/cyfrin
ln -sfn ../../aave-v3-origin-full-optimized         gas/lib/ours
ln -sfn ../../aave-v3-origin/lib/forge-std          gas/lib/forge-std
```

Then:

```bash
cd gas
forge test --gas-report --match-contract '^MathUtilsOriginGas$'    # Standard profile
FOUNDRY_PROFILE=viair forge test --gas-report --match-contract '^MathUtilsOursGas$'
```

Each subject-version pair has its own test contract, so that versions with
identical bytecode (for example `CalldataLogicCyfrin` and `CalldataLogicOurs`)
are not merged into a single gas-report entry. The names are `<Subject><Version>Gas`
with `Version` one of `Origin`, `Cyfrin` and `Ours`, over five subjects:

| Subject | Test contracts |
|---------|----------------|
| `MathUtils` | `MathUtilsOriginGas`, `MathUtilsCyfrinGas`, `MathUtilsOursGas` |
| `CalldataLogic` | `CalldataLogicOriginGas`, `CalldataLogicCyfrinGas`, `CalldataLogicOursGas` |
| `UserConfiguration` | `UserConfigurationOriginGas`, `UserConfigurationCyfrinGas`, `UserConfigurationOursGas` |
| `ReserveLogic` | `RLOriginGas`, `RLCyfrinGas`, `RLOursGas` |
| `Pool` | `PoolOriginGas`, `PoolCyfrinGas`, `PoolOursGas` |

`ReserveLogic` is the one exception to the pattern: its contracts are prefixed `RL`, so
`--match-contract '^ReserveLogicOriginGas$'` matches nothing.

The Via-IR profile skips `Pool`:
the full AAVE tree does not compile through the Yul pipeline at solc 0.8.22
(`SupplyLogic` hits a "stack too deep" error).

### Contract subjects

Enter the folder of the variant you want to benchmark and run:

```bash
forge test --gas-report --match-contract <ContractName>_gas_Tests
```

For example:

```bash
cd aave-v3-origin
forge test --gas-report --match-contract PoolAddressesProviderRegistry_gas_Tests
```

```bash
cd aave-v3-origin-liquidation-gas-fixes
forge test --gas-report --match-contract RewardsDistributor_gas_Tests
```

```bash
cd aave-v3-origin-full-optimized
forge test --gas-report --match-contract RewardsDistributor_gas_Tests
```

The three trees carry the same test-contract names. Those covering the five contract
subjects are `PoolAddressesProviderRegistry_gas_Tests`, `RewardsController_gas_Tests`,
`RewardsDistributor_gas_Tests` and `Collector_gas_Tests`; `Pool` is split across
`PoolOperations_gas_Tests`, `PoolGetters_gas_Tests` and `PoolSetters_gas_Tests`.

---

## License

This project is licensed under the MIT License. See [license.txt](license.txt) for details.