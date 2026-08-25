#!/usr/bin/env bash
# Build aave-v3-origin-renamed/ from aave-v3-origin/.
#
# WHY THIS EXISTS. The Pool subject links seven logic libraries that declare
# `external` functions and are therefore deployed and linked separately rather
# than inlined. Both the original and the optimised harness pull their own copy
# into the Certora scene, where the copies collide by name:
#
#   Error in spec file: Contract name BorrowLogic already has an entry in scope
#
# The inheritance harness of Section 5.1.1 solves exactly this problem for the
# contract under study, but it does not reach one level down to the libraries,
# because a library cannot be subclassed. `DataTypes` collides for the same
# reason once the spec has to name a struct parameter in a method signature.
#
# WHY RENAMING IS SOUND HERE. The substitution is an alpha-conversion: it
# renames declarations and every reference to them, and touches nothing else.
# It is applied only to the copy the original harness imports, so the optimised
# side is compared against untouched vendor source.
#
# Usage:  bash scripts/make_renamed_original.sh

set -euo pipefail

cd "$(dirname "$0")/.."

SRC=aave-v3-origin
DST=aave-v3-origin-renamed

# The seven libraries with `external` functions, plus DataTypes.
LIBS=(BorrowLogic BridgeLogic EModeLogic FlashLoanLogic LiquidationLogic PoolLogic SupplyLogic)
SUFFIX=Orig

rm -rf "$DST"
mkdir -p "$DST"
cp -r "$SRC/src" "$DST/src"
cp -r "$SRC/lib" "$DST/lib"

# Word-boundary substitution. `\b` does not match inside RewardsDataTypes, so
# that identifier is left alone; the same holds for any name merely containing
# a library name as a substring.
for L in "${LIBS[@]}"; do
  grep -rl "\b$L\b" "$DST/src" --include='*.sol' | xargs -r sed -i "s/\b$L\b/${L}${SUFFIX}/g"
done
grep -rl '\bDataTypes\b' "$DST/src" --include='*.sol' | xargs -r sed -i 's/\bDataTypes\b/DataTypesOrig/g'

# The substitution also rewrote the import paths (they contain the file names),
# so the files must be renamed to match.
for L in "${LIBS[@]}"; do
  find "$DST/src" -name "$L.sol" -exec bash -c 'mv "$1" "${1%/*}/'"${L}${SUFFIX}"'.sol"' _ {} \;
done
find "$DST/src" -name 'DataTypes.sol' -exec bash -c 'mv "$1" "${1%/*}/DataTypesOrig.sol"' _ {} \;

echo "built $DST"
echo "verify with: certoraRun --prover_version master conf/Pool.conf --compilation_steps_only"
