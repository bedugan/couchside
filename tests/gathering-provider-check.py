"""Check an external GatherMate2 package without running its game lifecycle.

Requires Python and lupa with Lua 5.1. No provider source is vendored here.
Usage: python gathering-provider-check.py --addon /path/to/GatherMate2
       [--saved-variables /path/to/Couchside_Gathering.lua] [--output result.json]
"""

import argparse
import hashlib
import json
from pathlib import Path

from lupa.lua51 import LuaRuntime


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--addon", type=Path, required=True)
    parser.add_argument("--saved-variables", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    toc = (args.addon / "GatherMate2.toc").read_text()
    metadata = dict(line[3:].split(": ", 1) for line in toc.splitlines() if line.startswith("## ") and ": " in line)
    loaded_files = {}
    vm = LuaRuntime(register_eval=False, register_builtins=False)
    vm.globals().providerTestVersion = metadata["Version"]
    classifier_toc = (root / "Couchside_Gathering/Couchside_Gathering.toc").read_text()
    vm.globals().classifierTestVersion = next(line.removeprefix("## Version: ") for line in classifier_toc.splitlines() if line.startswith("## Version: "))
    vm.execute("""
        nativeCalls = 0
        strmatch = string.match
        logs, commands, localeErrors = {}, {}, {}
        function GetLocale() return 'enUS' end
        function geterrorhandler()
            return function(message) table.insert(localeErrors, message) end
        end
        function CreateFrame() return {} end
        C_AddOns = { GetAddOnMetadata = function(addon)
            return addon == 'GatherMate2' and providerTestVersion or classifierTestVersion
        end }
        Minimap = {
            UpdateMouseoverAtPoint = function() nativeCalls = nativeCalls + 1 end,
            SetUsingSoftCursor = function() nativeCalls = nativeCalls + 1 end,
        }
        ns = {
            Print = function(fmt, ...) table.insert(logs, string.format(fmt, ...)) end,
            RegisterCommand = function(name, _, callback) commands[name] = callback end,
            OnReady = function(callback) callback() end,
        }
    """)

    def load(path, *arguments):
        loaded_files[str(path.relative_to(args.addon)) if path.is_relative_to(args.addon) else str(path.relative_to(root))] = hashlib.sha256(path.read_bytes()).hexdigest()
        vm.execute("assert(loadstring(...))(select(2, ...))", path.read_text(), *arguments)

    load(args.addon / "Libs/LibStub/LibStub.lua")
    load(args.addon / "Libs/AceLocale-3.0/AceLocale-3.0.lua")
    # Stub only lifecycle and display infrastructure. The locale engine, catalog
    # construction and name lookup methods below are the actual packaged code.
    vm.execute("""
        local display = {
            SetTrackingSpell = function() end,
            SetSkillProfession = function() end,
        }
        local ace = LibStub:NewLibrary('AceAddon-3.0', 999)
        function ace:NewAddon()
            return { GetModule = function() return display end }
        end
        function ace:GetAddon() return GatherMate2 end
        LibStub:NewLibrary('HereBeDragons-2.0', 999)
        LibStub:NewLibrary('HereBeDragons-Migrate', 999)
    """)
    for relative in (
        "Locales/GatherMate2-enUS.lua",
        "Locales/Vanilla/GatherMate2-Vanilla-enUS.lua",
        "GatherMate2.lua",
        "Constants.lua",
    ):
        load(args.addon / relative)
    for relative in ("ScanLog.lua", "QuestTextFilter.lua", "ResourceClassifier.lua"):
        load(root / "Couchside_Gathering" / relative, "Couchside_Gathering", vm.globals().ns)

    # Native scan 36/37 captured this texture markup preceding Earthroot. The
    # classifier must match the visible name and leave the raw tooltip intact.
    decorated = r"|TInterface\Minimap\Minimap-PositionArrows:0:0:0:0:16:32:0:16:16:32|tEarthroot"
    check_decoration = vm.eval("""function(text)
        local snapshot = { titles = {}, objectives = {} }
        local data = { lines = {{ leftText = text }} }
        local filtered = ns.QuestTextFilter.Filter(data, snapshot)
        local result = ns.ResourceClassifier.Classify(filtered, snapshot, ns.ResourceClassifier.LibraryLookup)[1]
        assert(data.lines[1].leftText == text, 'Raw tooltip changed')
        return result
    end""")
    result = check_decoration(decorated)
    assert result.kind == "resource-candidate" and result.resourceKey == "gathermate2:herb:403", "Decorated Earthroot did not match the catalog"

    def plain(value):
        if hasattr(value, "items"):
            return {str(k): plain(v) for k, v in value.items()}
        return value

    checks = []
    for category, names in (
        ("herb", ("Peacebloom", "Silverleaf", "Earthroot", "Mageroyal", "Briarthorn", "Bruiseweed", "Kingsblood")),
        ("ore", ("Copper Vein", "Tin Vein")),
    ):
        for name in names:
            result, error = vm.eval("function(name) local result, err = ns.ResourceClassifier.LibraryLookup(name); return result, err end")(name)
            assert not error and result.category == category, (name, error)
            key = result.key
            node_id = int(key.rsplit(":", 1)[1])
            provider_category = "Herb Gathering" if category == "herb" else "Mining"
            reverse = vm.globals().GatherMate2.GetNameForNode(vm.globals().GatherMate2, provider_category, node_id)
            assert reverse == name, (name, reverse)
            checks.append({"name": name, "category": category, "catalogKey": key, "reverseName": reverse})
    for name in ("__Couchside_unknown_control__", "Innkeeper Boorand Plainswind", "Devrak", "Lizzarik", "Thork", "Halija Whitestrider"):
        result, error = vm.eval("function(name) local result, err = ns.ResourceClassifier.LibraryLookup(name); return result, err end")(name)
        assert result is None and error is None, (name, error)
        checks.append({"name": name, "category": "unknown"})

    replays = []
    if args.saved_variables:
        db = vm.eval("""function(source)
            local env = {}
            local chunk = assert(loadstring(source))
            setfenv(chunk, env)
            chunk()
            return assert(env.CouchsideGatheringScanDB)
        end""")(args.saved_variables.read_text())
        vm.globals().CouchsideGatheringScanDB = db
        original = plain(db.scans)
        for scan in db.scans.values():
            vm.execute("logs = {}")
            vm.globals().commands.classify("library " + str(scan.id))
            lines = list(vm.globals().logs.values())
            assert any("Distinct entries:" in line for line in lines)
            replays.append({"scanID": scan.id, "reportLines": lines})
        assert plain(db.scans) == original, "Classifier changed saved scan evidence"
        assert len(db.providerReports) == min(10, len(replays))
        for record in db.providerReports.values():
            assert record.version == 1 and record.providerVersion == metadata["Version"]
            assert record.providerAvailable and len(record.entries) <= 40
            assert record.totalEntries == sum(record.counts.values())
    assert vm.globals().nativeCalls == 0
    assert len(vm.globals().localeErrors) == 0
    report = {
        "provider": {"version": metadata["Version"], "interface": metadata["Interface"], "loadedFileSHA256": loaded_files},
        "environment": "Isolated Lua 5.1, enUS; actual packaged locale engine, catalog construction and lookup methods",
        "limitations": "Lifecycle, frames and HBD are stubbed. No client loading, full-addon behavior, mining pins or other locales validated.",
        "checks": checks,
        "savedReplays": replays,
        "nativePointOrCursorCalls": vm.globals().nativeCalls,
        "savedScanEvidenceUnchanged": bool(args.saved_variables),
        "decoratedEarthroot": plain(result),
        "providerReportHistoryChecked": bool(args.saved_variables),
    }
    if args.output:
        args.output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
    print(f"PASS: {len(checks)} packaged lookup controls, {len(replays)} saved replays, zero native point/cursor calls")


if __name__ == "__main__":
    main()
