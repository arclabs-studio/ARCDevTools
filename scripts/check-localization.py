#!/usr/bin/env python3
"""Check String Catalog completeness for required locales.

Usage:
    check-localization.py [--locales es,fr] [--catalog PATH] [--verbose]

Auto-discovers `*.xcstrings` files from the working directory (skipping `.build`,
`DerivedData`, `Pods`, `node_modules`, `.git`). Pass `--catalog` to check a single
file. Fails with non-zero exit code if any string in any catalog is missing a
required locale or is in `new` / `needs_review` state.

Defaults:
    --locales es
    --catalog (auto-discover)
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

BAD_STATES = {"new", "needs_review"}
SKIP_DIRS = {".build", "DerivedData", "Pods", "node_modules", ".git", ".swiftpm"}


def discover_catalogs(root: Path) -> list[Path]:
    found: list[Path] = []
    for path in root.rglob("*.xcstrings"):
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        found.append(path)
    return sorted(found)


def check_catalog(path: Path, locales: list[str]) -> tuple[int, list[str]]:
    """Return (failure_count, error_messages)."""
    try:
        with path.open(encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError) as exc:
        return 1, [f"   ✗ failed to parse: {exc}"]

    strings = data.get("strings", {})
    if not strings:
        return 0, [f"   (empty catalog, skipping)"]

    failures: list[str] = []
    for locale in locales:
        missing: list[str] = []
        bad_state: list[tuple[str, str]] = []
        for key, entry in strings.items():
            locs = entry.get("localizations", {})
            if locale not in locs:
                missing.append(key)
            else:
                state = locs[locale].get("stringUnit", {}).get("state", "")
                if state in BAD_STATES:
                    bad_state.append((key, state))

        if missing:
            failures.append(f"   ✗ [{locale}] {len(missing)} key(s) missing translation:")
            failures.extend(f"      • {k!r}" for k in missing)
        if bad_state:
            failures.append(f"   ✗ [{locale}] {len(bad_state)} key(s) with incomplete state:")
            failures.extend(f"      • [{s}] {k!r}" for k, s in bad_state)

    if not failures:
        n = len(strings)
        loc_str = ", ".join(locales)
        return 0, [f"   ✓ {n} key(s) complete for: {loc_str}"]

    return len(failures), failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--locales", default="es", help="Comma-separated required locales (default: es)")
    parser.add_argument("--catalog", type=Path, help="Path to a single .xcstrings file (skips auto-discovery)")
    parser.add_argument("--verbose", action="store_true", help="List all checked catalogs even on success")
    args = parser.parse_args()

    locales = [loc.strip() for loc in args.locales.split(",") if loc.strip()]
    if not locales:
        print("error: --locales must be non-empty", file=sys.stderr)
        return 1

    if args.catalog:
        if not args.catalog.exists():
            print(f"error: catalog not found: {args.catalog}", file=sys.stderr)
            return 1
        catalogs = [args.catalog]
    else:
        catalogs = discover_catalogs(Path.cwd())
        if not catalogs:
            print("error: no .xcstrings files found", file=sys.stderr)
            return 1

    total_failures = 0
    for path in catalogs:
        rel = path.relative_to(Path.cwd()) if path.is_relative_to(Path.cwd()) else path
        count, msgs = check_catalog(path, locales)
        total_failures += count
        if count > 0 or args.verbose:
            print(f"\n{rel}")
            for msg in msgs:
                print(msg)

    if total_failures == 0:
        loc_str = ", ".join(locales)
        print(f"\n✅ All {len(catalogs)} catalog(s) complete for: {loc_str}")
        return 0

    print(f"\n❌ {total_failures} failure(s) across {len(catalogs)} catalog(s)")
    return 1


if __name__ == "__main__":
    sys.exit(main())
