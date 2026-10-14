-- Native macro setup is explicit and outside combat. Never edits/deletes a
-- macro, opens a native panel, picks up a cursor item or assigns a binding.
local _, ns = ...
local NAME, ICON, BODY = "Scan map", 134269, "/cs gathering scan"
local probeReady = false

local function Plain(value, kind, label)
	if issecretvalue and issecretvalue(value) then error(label .. " restricted", 0) end
	if type(value) ~= kind then error(label .. " unavailable", 0) end
	return value
end

local function Count(value, label)
	value = Plain(value, "number", label)
	if value ~= value or value < 0 or value > 2000 or value ~= math.floor(value) then error(label .. " invalid", 0) end
	return value
end

local function Persist(report)
	report.version, report.addonVersion = 1, ns.version
	report.name, report.icon, report.body = NAME, ICON, BODY
	report.serverTime = GetServerTime()
	local version, build, _, interface = GetBuildInfo()
	report.clientVersion, report.build, report.interface = version, build, interface
	local db = CouchsideGatheringScanDB
	if db and db.version == 1 then db.macroReport = ns.SnapshotTooltip(report) end
end

local function Probe()
	local report = { status = "unavailable", createAvailable = type(CreateMacro) == "function",
		countAvailable = type(GetNumMacros) == "function", infoAvailable = type(GetMacroInfo) == "function" }
	local ok, err = pcall(function()
		if not report.createAvailable or not report.countAvailable or not report.infoAvailable then error("macro APIs unavailable", 0) end
		local limits = Constants and Constants.MacroConsts
		report.accountLimit = Count(limits and limits.MAX_ACCOUNT_MACROS, "account macro limit")
		report.characterLimit = Count(limits and limits.MAX_CHARACTER_MACROS, "character macro limit")
		local account, character = GetNumMacros()
		report.accountCount, report.characterCount = Count(account, "account macro count"), Count(character, "character macro count")
		if account > report.accountLimit or character > report.characterLimit then error("macro counts exceed limits", 0) end
		local function Inspect(index)
			local name, icon, body = GetMacroInfo(index)
			name = Plain(name, "string", "macro name")
			if name == NAME then
				body = Plain(body, "string", "scan macro body")
				if body:gsub("^%s+", ""):gsub("%s+$", "") == BODY then
					if not report.existingIndex then
						report.existingIndex = index
						report.existingIcon = issecretvalue and issecretvalue(icon) and "<restricted>" or icon
					end
				else report.collision = true end
			end
		end
		for index = 1, account do Inspect(index) end
		for index = 1, character do Inspect(report.accountLimit + index) end
		report.status = report.collision and "name conflict" or report.existingIndex and "exists"
			or account >= report.accountLimit and "account macros full" or "ready"
	end)
	if not ok then report.error = tostring(err) end
	Persist(report)
	return report
end

local function Print(report)
	ns.Print("Scan macro %s: CreateMacro %s, GetNumMacros %s, GetMacroInfo %s. Icon %d; account slots %s/%s; character slots %s/%s.",
		report.status, tostring(report.createAvailable), tostring(report.countAvailable), tostring(report.infoAvailable), ICON,
		tostring(report.accountCount), tostring(report.accountLimit), tostring(report.characterCount), tostring(report.characterLimit))
	if report.error then ns.Print("Macro read: %s. No macro changed.", report.error) end
	if report.status == "name conflict" then ns.Print("A different macro is named '%s'. Choose another name for that macro before setup; it was preserved.", NAME)
	elseif report.status == "account macros full" then ns.Print("Account macro slots are full. Free a slot in the native editor, then retry.")
	elseif report.existingIndex then ns.Print("'%s' already runs %s at macro index %d. Its icon and text were preserved.", NAME, BODY, report.existingIndex)
	else ns.Print("Body: %s. Check this read-only report before /cs gathering macro create.", BODY) end
end

ns.RegisterCommand("macro", "[probe|create] - report native macro APIs or create Scan map with a map icon", function(arg)
	if arg == "" or arg == "probe" then
		local report = Probe()
		probeReady = not report.error and (report.status == "ready" or report.status == "exists")
		Print(report)
		return
	end
	if arg ~= "create" then ns.Print("Usage: /cs gathering macro [probe|create]"); return end
	if InCombatLockdown() then ns.Print("Scan macro setup requires being out of combat."); return end
	if not probeReady then ns.Print("First /cs gathering macro probe and check its native API report. No macro changed."); return end
	local report = Probe() -- Recheck slots and collisions immediately before mutation.
	if report.error or (report.status ~= "ready" and report.status ~= "exists") then Print(report); return end
	if report.existingIndex then Print(report); return end
	if ns.AutomaticScan then ns.AutomaticScan.Pause("macro setup") end
	local ok, index = pcall(CreateMacro, NAME, ICON, BODY, false)
	if not ok then
		report.status, report.error = "creation failed", tostring(index)
		Persist(report)
		ns.Print("Macro creation ERROR: %s. Inspect the native macro editor before retrying; no automatic retry.", report.error)
		return
	end
	local verified = Probe()
	local validIndex = type(index) == "number" and not (issecretvalue and issecretvalue(index))
		and index == math.floor(index) and index > 0 and index <= (report.accountLimit or 0)
	if not validIndex or verified.error or verified.collision or verified.existingIndex ~= index then
		verified.status, verified.error = "creation unverified", "returned index or saved macro did not match"
		Persist(verified)
		ns.Print("Macro creation returned, but could not be verified. Inspect '%s' in the native macro editor; no automatic retry.", NAME)
		return
	end
	verified.status, verified.createdIndex = "created", index
	Persist(verified)
	ns.Debug("Created account scan macro %d with map icon %d.", index, ICON)
	ns.Print("Created '%s' with a map icon. Use the native macro editor to assign its controller slot. Check controls before/after reload.", NAME)
	if ns.IsEnabled("autoScan") then ns.Print("Automatic scanning paused for macro setup. /cs gathering auto resume when ready.") end
end)
