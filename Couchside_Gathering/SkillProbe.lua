-- Explicit report only. Native skill values are evidence, not node-difficulty
-- thresholds. Do not apply saved reports to live stamps or another character.
local _, ns = ...
local professions = { { name = "Herbalism", id = 182 }, { name = "Mining", id = 186 } }

local function Read(fn, ...)
	if type(fn) ~= "function" then return { status = "missing" } end
	local ok, value = pcall(fn, ...)
	if issecretvalue and issecretvalue(value) then return { status = "restricted" } end
	if not ok then return { status = "error", detail = ns.SnapshotTooltip(value) } end
	if value == nil then return { status = "nil" } end
	local snapshot = ns.SnapshotTooltip(value)
	if type(snapshot) == "table" and snapshot.snapshotError then return { status = "unreadable" } end
	return { status = "ok", value = snapshot }
end

local function Number(value)
	return type(value) == "number" and tostring(value) or "unknown"
end

ns.RegisterCommand("skills", "[label] - read-only Herbalism/Mining skill report; keeps three samples", function(arg)
	local label = arg ~= "" and arg or "unlabelled"
	if #label > 32 or not label:match("^[%w_-]+$") then
		ns.Print("Usage: /cs gathering skills [label]. Labels: letters, digits, hyphen or underscore, up to 32 characters.")
		return
	end
	local db = CouchsideGatheringScanDB
	if not db or db.version ~= 1 then ns.Print("Skill report unavailable: unsupported scan history."); return end
	local report = { version = 1, addonVersion = ns.version, label = label,
		serverTime = GetServerTime(), character = Read(UnitGUID, "player"), skills = {}, enumeration = {} }
	local version, build, _, interface = GetBuildInfo()
	report.client = { version = version, build = build, interface = interface }
	for _, profession in ipairs(professions) do
		report.skills[profession.name] = { requestedSkillID = profession.id,
			result = Read(C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID, profession.id) }
	end
	report.skillCount = Read(C_SkillInfo and C_SkillInfo.GetNumSkillLines)
	local count = report.skillCount.value
	if type(count) == "number" and count >= 0 and count < math.huge and count % 1 == 0 then
		report.enumerationTruncated = count > 64
		for index = 1, math.min(count, 64) do
			report.enumeration[index] = Read(C_SkillInfo and C_SkillInfo.GetSkillLineInfo, index)
		end
	end
	-- Passive tooltip reads only: do not set a tooltip target, open a panel or
	-- enable the minimap soft cursor to manufacture additional evidence.
	report.tooltipVisible = Read(GameTooltip and GameTooltip.IsShown, GameTooltip)
	if report.tooltipVisible.value == true then
		report.tooltip = Read(GameTooltip and GameTooltip.GetPrimaryTooltipData, GameTooltip)
	else report.tooltip = { status = "not-shown-or-unknown" } end
	report.minimapHover = Read(C_TooltipInfo and C_TooltipInfo.GetMinimapMouseover)
	db.skillReports = db.skillReports or {}
	report.id = db.nextSkillReportID or 1
	db.nextSkillReportID = report.id + 1
	db.skillReports[#db.skillReports + 1] = report
	while #db.skillReports > 3 do table.remove(db.skillReports, 1) end
	for _, profession in ipairs(professions) do
		local result = report.skills[profession.name].result
		local value = result.status == "ok" and type(result.value) == "table" and result.value or {}
		ns.Print("%s: %s; rank %s/%s, modifier %s, temporary %s. Raw values; difficulty not inferred.",
			profession.name, result.status, Number(value.rank), Number(value.maxRank), Number(value.modifier), Number(value.tempPoints))
	end
	ns.Print("Skill report %d (%s) saved in memory; up to three retained. /reload to persist.", report.id, report.label)
	ns.Debug("Read-only gathering skill report: no cursor, panel, tracking or profession changes.")
end)
