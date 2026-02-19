# AAVE V3 Case Study

This directory contains the artifacts for the AAVE V3 case study from the work *"Ensuring Gas Optimisation Correctness by Behavioural Equivalence"*.

---

## Structure

```
.
├── aave-v3-origin/                       # Original AAVE V3 codebase (commit 464a0ea, v3.3)
├── aave-v3-origin-liquidation-gas-fixes/ # Cyfrin-optimised variant
├── aave-v3-origin-full-optimized/        # Our extended variant
├── conf/                                 # Certora configuration files for this case study
├── contracts/                            # Gas optimisation reports per contract
│   ├── PoolAddressesProviderRegistry.md
│   ├── RewardsController.md
│   └── RewardsDistributor.md
├── Harness/                              # Harness contracts for Certora verification
├── specs/                                # CVL specifications for this case study
└── license.txt
```

---

## Contract Reports

Detailed reports for each analysed contract — covering the transformations applied, code diffs, gas snapshots, and formal verification links — are available in `contracts/`:

| Contract | Report |
|----------|--------|
| `PoolAddressesProviderRegistry` | [contracts/PoolAddressesProviderRegistry.md](contracts/PoolAddressesProviderRegistry.md) |
| `RewardsController` | [contracts/RewardsController.md](contracts/RewardsController.md) |
| `RewardsDistributor` | [contracts/RewardsDistributor.md](contracts/RewardsDistributor.md) |

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