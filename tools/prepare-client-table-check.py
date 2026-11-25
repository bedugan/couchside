"""Fetch pinned upstream readers into an external experiment directory.

Requires Python's standard library. Does not install packages or read WoW files.
Upstream code stays outside the Couchside repository and addon folders.
"""

import argparse
import hashlib
import json
import pathlib
import posixpath
import re
import urllib.request

TOOL_REVISION = "c2fd7bde36a712be78a5da896c995b84fbfa2545"
SCHEMA_REVISION = "d6f50d4f351193e84226aa62a36faa0f58528afa"
KEY_REVISION = "f800811762b2e9ea638bf6dfdb4707382c497943"
STUBS = {
    "src/js/log.js", "src/js/core.js", "src/js/generics.js",
    "src/js/mmap.js", "src/js/constants.js",
    "src/js/casc/casc-source-remote.js", "src/js/casc/build-cache.js",
    "src/js/casc/listfile.js", "src/js/casc/tact-keys.js",
    "src/js/casc/dbd-manifest.js", "src/js/casc/cdn-resolver.js",
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("work_directory", type=pathlib.Path)
    args = parser.parse_args()
    work = args.work_directory.resolve()
    repo = pathlib.Path(__file__).resolve().parent.parent
    if work == repo or repo in work.parents or "Interface" in work.parts or "World of Warcraft" in work.parts:
        parser.error("Use a work directory outside the repository and WoW installation")
    work.mkdir(parents=True, exist_ok=True)
    manifest = {"toolRevision": TOOL_REVISION, "schemaRevision": SCHEMA_REVISION,
                "publicKeysRevision": KEY_REVISION, "files": {}}

    def fetch(repo_name, revision, source_path, destination=None):
        target_path = destination or source_path
        url = f"https://raw.githubusercontent.com/{repo_name}/{revision}/{source_path}"
        request = urllib.request.Request(url, headers={"User-Agent": "Couchside-client-table-check"})
        with urllib.request.urlopen(request, timeout=30) as response:
            content = response.read(5 * 1024 * 1024 + 1)
        if len(content) > 5 * 1024 * 1024:
            raise ValueError(f"Source file exceeds download bound: {source_path}")
        target = work / target_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content)
        manifest["files"][target_path] = hashlib.sha256(content).hexdigest()
        return content.decode("utf8")

    queue = ["src/js/casc/casc-source-local.js", "src/js/db/WDCReader.js"]
    seen = set()
    while queue:
        source = queue.pop()
        if source in seen or source in STUBS:
            continue
        seen.add(source)
        text = fetch("Kruithne/wow.export", TOOL_REVISION, source)
        for dependency in re.findall(r"require\(['\"]([^'\"]+)['\"]\)", text):
            if dependency.startswith("."):
                target = posixpath.normpath(posixpath.join(posixpath.dirname(source), dependency))
                queue.append(target if target.endswith(".js") else target + ".js")

    fetch("Kruithne/wow.export", TOOL_REVISION, "LICENSE", "upstream-LICENSE.txt")
    fetch("wowdev/WoWDBDefs", SCHEMA_REVISION, "manifest.json", "dbd-manifest.json")
    for table in ("GameObjects", "Creature", "Lock", "LockType"):
        fetch("wowdev/WoWDBDefs", SCHEMA_REVISION, f"definitions/{table}.dbd", f"{table}.dbd")
    fetch("wowdev/TACTKeys", KEY_REVISION, "WoW.txt", "TACTKeys.txt")
    (work / "TACTKeys-revision.txt").write_text(KEY_REVISION + "\n")
    manifest["files"]["TACTKeys-revision.txt"] = hashlib.sha256((KEY_REVISION + "\n").encode()).hexdigest()
    (work / "source-manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"Prepared {len(seen)} upstream reader files in {work}. No package installation.")


if __name__ == "__main__":
    main()
