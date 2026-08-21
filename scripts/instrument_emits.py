#!/usr/bin/env python3
"""Insert an empty-recorder call after every emission point of the subjects.

Called by scripts/make_instrumented.sh with the root of a freshly copied tree.
For each subject file it duplicates every `emit <Event>(...);` as
`_record<Event>(...);`, repeating the argument expressions verbatim, and appends
the matching `internal virtual` declarations with empty bodies.
"""
import os
import re
import sys

# file -> [(event name, recorder name, solidity parameter types)]
SUBJECTS = {
    'src/contracts/treasury/Collector.sol': [
        ('CreateStream', '_recordCreateStream',
         ['uint256', 'address', 'address', 'uint256', 'address', 'uint256', 'uint256']),
        ('WithdrawFromStream', '_recordWithdrawFromStream',
         ['uint256', 'address', 'uint256']),
        ('CancelStream', '_recordCancelStream',
         ['uint256', 'address', 'address', 'uint256', 'uint256']),
    ],
    'src/contracts/protocol/configuration/PoolAddressesProviderRegistry.sol': [
        ('AddressesProviderRegistered', '_recordAddressesProviderRegistered',
         ['address', 'uint256']),
        ('AddressesProviderUnregistered', '_recordAddressesProviderUnregistered',
         ['address', 'uint256']),
    ],
    'src/contracts/rewards/RewardsDistributor.sol': [
        ('AssetConfigUpdated', '_recordAssetConfigUpdated',
         ['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256', 'uint256']),
        ('Accrued', '_recordAccrued',
         ['address', 'address', 'address', 'uint256', 'uint256', 'uint256']),
    ],
    'src/contracts/rewards/RewardsController.sol': [
        ('ClaimerSet', '_recordClaimerSet', ['address', 'address']),
        ('RewardsClaimed', '_recordRewardsClaimed',
         ['address', 'address', 'address', 'address', 'uint256']),
        ('TransferStrategyInstalled', '_recordTransferStrategyInstalled',
         ['address', 'address']),
        ('RewardOracleUpdated', '_recordRewardOracleUpdated', ['address', 'address']),
    ],
}


def duplicate_emits(src, event, recorder):
    """After every `emit <event>( ... );` insert the same call to <recorder>."""
    pat = re.compile(r'(^[ \t]*)emit[ \t]+' + event + r'\(', re.M)
    out, i, count = [], 0, 0
    while True:
        m = pat.search(src, i)
        if not m:
            out.append(src[i:])
            return ''.join(out), count
        j, depth = m.end() - 1, 0
        while True:
            if src[j] == '(':
                depth += 1
            elif src[j] == ')':
                depth -= 1
                if depth == 0:
                    break
            j += 1
        k = j + 1
        while src[k] in ' \t':
            k += 1
        if src[k] != ';':
            raise SystemExit('unterminated emit: ' + src[m.start():k + 40])
        end = k + 1
        block = src[m.start():end]
        call = re.sub(r'^' + re.escape(m.group(1)) + r'emit[ \t]+' + event,
                      m.group(1) + recorder, block, count=1, flags=re.M)
        out.append(src[i:end])
        out.append('\n' + call)
        i, count = end, count + 1


def declaration(recorder, types):
    if len(types) <= 3:
        return '  function %s(%s) internal virtual {}' % (recorder, ', '.join(types))
    body = ',\n'.join('    ' + t for t in types)
    return '  function %s(\n%s\n  ) internal virtual {}' % (recorder, body)


def append_declarations(src, decls):
    s = src.rstrip()
    if not s.endswith('}'):
        raise SystemExit('file does not end in a contract body')
    return s[:s.rfind('}')].rstrip('\n') + '\n\n' + '\n\n'.join(decls) + '\n}\n'


def main(root):
    for rel, events in SUBJECTS.items():
        path = os.path.join(root, rel)
        if not os.path.exists(path):
            raise SystemExit('missing subject: ' + path)
        src = open(path).read()
        decls, total = [], 0
        for event, recorder, types in events:
            src, n = duplicate_emits(src, event, recorder)
            if n == 0:
                raise SystemExit('no emission point for %s in %s' % (event, rel))
            decls.append(declaration(recorder, types))
            total += n
        open(path, 'w').write(append_declarations(src, decls))
        print('  %-62s %d emission points' % (os.path.basename(rel), total))


if __name__ == '__main__':
    main(sys.argv[1])
