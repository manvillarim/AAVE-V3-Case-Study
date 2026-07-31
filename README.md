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
├── aave-v3-origin-renamed/               # Original tree with the colliding external
│                                         #   library names alpha-renamed, used only by
│                                         #   the Pool harness (see "Pool subject" below)
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
│   └── ReserveLogic.md
│                                         #   of the Cyfrin diff against the catalogue
├── gas/                                  # Foundry project measuring the library subjects
│                                         #   and Pool under both compiler profiles
├── Harness/                              # Harness contracts for Certora verification
├── specs/                                # CVL specifications for this case study
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

1. [Certora Prover](https://www.certora.com/) (with a valid API key)
2. [Foundry Framework](https://getfoundry.sh/)

---

## Formal Verification

Run from the **repository root**:

```bash
certoraRun.py --prover_version master conf/<NAME_OF_CONF_FILE>.conf
```

---

## Gas Benchmarking

### Library subjects and `Pool`

```bash
cd gas
forge test --gas-report --match-contract '^MathUtilsOriginGas$'    # Standard profile
FOUNDRY_PROFILE=viair forge test --gas-report --match-contract '^MathUtilsOursGas$'
```

Each subject-version pair has its own test contract, so that versions with
identical bytecode (for example `CalldataLogicCyfrin` and `CalldataLogicOurs`)
are not merged into a single gas-report entry. The Via-IR profile skips `Pool`:
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

---

## License

This project is licensed under the MIT License. See [license.txt](license.txt) for details.