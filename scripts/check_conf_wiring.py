#!/usr/bin/env python3
"""Check that every Certora configuration in conf/ is runnable as it stands.

WHY THIS EXISTS. A conf is only as good as the paths it names, and nothing in
the toolchain reports a conf that has drifted: a harness importing a tree by a
hard-coded relative path still compiles, and a package mapping left over from an
earlier layout is simply never consulted. Both failure modes are silent, and
both hide the same thing -- a run the paper reports that the artefact can no
longer reproduce.

WHAT IT CHECKS. For each conf: the harness files exist, the spec exists, every
package maps to a directory that exists, and every import reachable from the
harnesses resolves, transitively, either relatively or through the package map.

It does not compile anything. Run it before `certoraRun` to separate a wiring
problem from a Solidity or CVL one.

Usage:  python3 scripts/check_conf_wiring.py
"""
import glob
import json
import os
import re
import sys

IMPORT = re.compile(r"""import\s+(?:\{[^}]*\}\s+from\s+)?['"]([^'"]+)['"]""")


def resolve(imp, packages, importer):
    if imp.startswith('.'):
        return os.path.normpath(os.path.join(os.path.dirname(importer), imp))
    for prefix, target in packages.items():
        if imp == prefix or imp.startswith(prefix + '/'):
            return os.path.normpath(os.path.join(target, imp[len(prefix):].lstrip('/')))
    return None


def check(conf, problems):
    c = json.load(open(conf))
    packages = dict(p.split('=', 1) for p in c['packages'])

    for prefix, target in packages.items():
        if not os.path.isdir(target):
            problems.append(f"{conf}: package {prefix} -> missing directory {target}")

    spec = c['verify'].split(':', 1)[1]
    if not os.path.isfile(spec):
        problems.append(f"{conf}: missing spec {spec}")

    seen = set()

    def walk(path):
        if path in seen:
            return
        seen.add(path)
        for imp in IMPORT.findall(open(path).read()):
            target = resolve(imp, packages, path)
            if target is None:
                problems.append(f"{path}: no package prefix matches import {imp}")
            elif not os.path.isfile(target):
                problems.append(f"{path}: import {imp} resolves to missing {target}")
            else:
                walk(target)

    for entry in c['files']:
        path = entry.split(':')[0]
        if not os.path.isfile(path):
            problems.append(f"{conf}: missing harness {path}")
        else:
            walk(path)


def main():
    os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
    confs = sorted(glob.glob('conf/*.conf'))
    if not confs:
        print('no conf/*.conf found', file=sys.stderr)
        return 1
    problems = []
    for conf in confs:
        check(conf, problems)
    for p in problems:
        print('FAIL:', p)
    print(f"{len(confs)} configurations checked, {len(problems)} problems")
    if problems:
        print('If a generated tree is missing, build it with '
              'scripts/make_instrumented.sh and scripts/make_renamed_original.sh.')
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
