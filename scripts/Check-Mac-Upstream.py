#!/usr/bin/env python3
"""Read-only upstream comparison. Never fetch, overwrite files, or move the baseline."""
import argparse
import json
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'scripts/upstream/macos-source-map.json'


def git_bytes(*args):
    result = subprocess.run(['git', '-C', str(ROOT), *args], capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr.decode(errors='replace').strip())
    return result.stdout


def blob(ref, path):
    result = subprocess.run(['git', '-C', str(ROOT), 'show', f'{ref}:{path}'], capture_output=True)
    return result.stdout if result.returncode == 0 else None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ref', required=True, help='Already fetched upstream commit or tag to compare')
    parser.add_argument('--json', action='store_true', help='Machine-readable report')
    args = parser.parse_args()
    manifest = json.loads(MANIFEST.read_text())
    target = git_bytes('rev-parse', '--verify', '--end-of-options', args.ref + '^{commit}').decode().strip()
    base = manifest['upstream_base']
    changes = git_bytes('diff', '--name-only', base, target, '--', 'DexManager', 'DXDisplayCleanup', 'tools', 'scripts').decode().splitlines()
    mapping = {entry['upstream']: entry for entry in manifest['files']}
    report = []
    for path in changes:
        entry = mapping.get(path)
        old, new = blob(base, path), blob(target, path)
        if old == new:
            continue
        if entry:
            local = ROOT / entry['mac']
            current = local.read_bytes() if local.exists() else None
            kind = 'already-matches' if current == new else 'direct-source-review' if current == old else 'mac-adaptation-review'
            report.append({'upstream': path, 'mac': entry['mac'], 'action': kind})
        else:
            kind = 'gui-parity-review' if path.startswith('DexManager/Forms/') else 'new-or-platform-file-review'
            report.append({'upstream': path, 'mac': None, 'action': kind})
    result = {'upstream': manifest['upstream'], 'baseline': base, 'target': target, 'changes': report,
              'next': 'Review source and GUI parity, integrate on a branch, build/test both architectures and a Galaxy, then update the baseline explicitly.'}
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"Upstream {base[:12]} -> {target[:12]}: {len(report)} changed files")
        for row in report:
            print(f"{row['action']:29} {row['upstream']} -> {row['mac'] or '(manual mapping)'}")
        print(result['next'])
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
