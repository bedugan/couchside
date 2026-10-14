"""Run the local Gathering checks. Requires Python and lupa with Lua 5.1.

This validates Lua logic and packaging, not in-game taint or controller safety.
No external resource provider is required.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
CHECKS = (
    "gathering-classifier-check.py",
    "gathering-catalog-check.py",
    "gathering-legend-check.py",
    "gathering-display-check.py",
    "gathering-motion-probe-check.py",
    "gathering-dungeon-display-check.py",
    "gathering-motion-guard-check.py",
    "gathering-launch-check.py",
)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    vm = LuaRuntime(register_eval=False, register_builtins=False)
    addon = ROOT / "Couchside_Gathering"
    lua_files = sorted(addon.glob("*.lua"))
    for path in lua_files:
        vm.execute("assert(loadstring(...))", path.read_text())
    toc = (addon / "Couchside_Gathering.toc").read_text()
    entries = [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith("#")]
    assert len(entries) == len(set(entries)), "Duplicate TOC load entry"
    assert {path.name for path in lua_files} == set(entries), "TOC and Lua file inventory differ"
    assert all((addon / entry).is_file() for entry in entries)
    print(f"PASS Lua 5.1 syntax and TOC inventory: {len(lua_files)} files")
    cases, results = set(), {}
    for check in CHECKS:
        completed = subprocess.run([sys.executable, str(ROOT / "tests" / check)], cwd=ROOT, text=True, capture_output=True)
        if completed.returncode:
            print(completed.stdout, end="")
            print(completed.stderr, end="", file=sys.stderr)
            return completed.returncode
        cases.update(line.removeprefix("PASS ") for line in completed.stdout.splitlines() if line.startswith("PASS "))
        results[check] = "passed"
        print(f"PASS {check}")
    result = {"lua51Files": len(lua_files), "tocInventory": "matched", "checks": results,
              "distinctCases": len(cases), "nativeAcceptance": "Requires Brian in-game"}
    if args.output:
        args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(f"{len(cases)} distinct local cases passed. Native acceptance remains separate.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
