#!/usr/bin/env bash
# Build the instrumented verification trees from the pristine subject trees.
#
#   aave-v3-origin                        -> aave-v3-origin-instr
#   aave-v3-origin-liquidation-gas-fixes  -> aave-v3-origin-liquidation-gas-fixes-instr
#   aave-v3-origin-full-optimized         -> aave-v3-origin-full-optimized-instr
#
# WHY THIS EXISTS. The coupling invariant compares the log a transaction
# produces: the argument vector of every event, how many events were emitted and
# in which order. CVL cannot read the log, so each emission point of a subject
# calls an empty `internal virtual` recorder that the harness overrides
# (Section 5.2.1 of the paper). The recorder has to sit inside the subject,
# because an event exists only at its emission point.
#
# WHY IT IS A COPY AND NOT AN EDIT IN PLACE. The same three trees feed the gas
# benchmark under gas/lib/{origin,cyfrin,ours}, which are symlinks to them. The
# recorder is semantically transparent -- an empty call -- but it is not always
# free in bytecode, and what decides that is the shape of the repeated argument
# expressions. Stack locals cost nothing: the optimiser removes the call at every
# emission point of Collector and PoolAddressesProviderRegistry, and at the
# `Accrued` emit of `_updateData`, even though that one sits in a conditional
# inside a loop inside an `unchecked` block. Storage and calldata reads do cost:
# the three `AssetConfigUpdated` emits of RewardsDistributor pass
# `rewardConfig.distributionEnd` and `rewardsInput[i].asset`, whose loads the
# duplicate reissues, at 89 to 262 bytes according to the variant and 134 to 350
# in RewardsController, which inherits them. Measuring gas
# on instrumented code would inflate the reported savings, and by different
# amounts in each variant. The benchmark therefore keeps the pristine trees and
# only the prover sees these copies.
#
# WHY THE COPY IS FAITHFUL. The transformation only inserts a call after an
# existing `emit`, repeating its argument expressions verbatim, and appends the
# empty declarations. It reorders nothing and rewrites no expression, so the
# instrumented pair differs exactly where the original pair differs.
#
# Usage:  bash scripts/make_instrumented.sh

set -euo pipefail

cd "$(dirname "$0")/.."

TREES=(aave-v3-origin aave-v3-origin-liquidation-gas-fixes aave-v3-origin-full-optimized)

for SRC in "${TREES[@]}"; do
  DST="${SRC}-instr"
  rm -rf "$DST"
  mkdir -p "$DST"
  cp -r "$SRC/src" "$DST/src"
  ln -s "../$SRC/lib" "$DST/lib"
  python3 scripts/instrument_emits.py "$DST"
  echo "built $DST"
done
