-- Adds a difficulty line to the world tooltip of a known herb or ore node.
-- Two read paths, because not every tooltip is built from tooltip data:
--   * TooltipDataProcessor post-calls (data-driven tooltips)
--   * GameTooltip OnShow, for tooltips the client fills natively
-- Both only read text and add a line. Secret text is skipped, never parsed.
-- Minimap pin tooltips are not supported: the line never appeared there in-game.
local _, ns = ...

local professions = { herb = "Herbalism", ore = "Mining" }
local SKILL_REFRESH = 1 -- seconds; a tooltip can be rebuilt every frame
local HISTORY = 5

local annotated = false -- this tooltip build already has our line
local recent = {} -- newest first, for /cs gathering tooltip
local skills, skillsTime

local function IsSecret(value)
	return issecretvalue ~= nil and issecretvalue(value)
end

local function Skills()
	local now = GetTime()
	if not skills or now - skillsTime >= SKILL_REFRESH then
		skills, skillsTime = ns.ResourceDifficulty.Capture(), now
	end
	return skills
end

local typeNames
local function TypeName(value)
	if not typeNames then
		typeNames = {}
		for name, id in pairs(Enum and Enum.TooltipDataType or {}) do typeNames[id] = name end
	end
	return typeNames[value] or tostring(value)
end

local function NodeName(text)
	local plain = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	return plain:match("^%s*(.-)%s*$")
end

-- nil on clients without supported skill reads (Retail), so nothing is added there.
local function Describe(entry, profile)
	local skill = profile[entry.category]
	if skill.status == "unsupported-client" then return end
	local result = ns.ResourceDifficulty.Evaluate(entry.name, profile)
	local profession = professions[entry.category]
	local text
	if result.key == "unknown" then
		text = ("%s difficulty unknown"):format(profession)
	elseif result.key == "red" then
		text = ("Too difficult · needs %s %d (you have %d)"):format(profession, entry.difficulty.minimum, skill.rank)
	elseif result.key == "cap" then
		text = ("At cap · %s %d/%d"):format(profession, skill.rank, skill.maximum)
	else
		text = ("%s · %s %d"):format(result.label, profession, skill.rank)
	end
	return text, result
end

local function Remember(record)
	local signature = record.source .. "\0" .. table.concat(record.lines, "\0")
	if recent[1] and recent[1].signature == signature then
		recent[1] = record
	else
		table.insert(recent, 1, record)
		recent[HISTORY + 1] = nil
		if record.matched then
			ns.Debug("Tooltip (%s, %s): %s; added %s.", record.source, record.dataType or "native",
				record.matched, record.added or "nothing")
		end
	end
	record.signature = signature
end

-- Owners can be forbidden or secret frames; the report only needs a label.
local function OwnerName(tooltip)
	local ok, name = pcall(function() return tooltip:GetOwner():GetName() end)
	return ok and type(name) == "string" and not IsSecret(name) and name or "unnamed"
end

local function Annotate(tooltip, texts, source, dataType)
	local record = { source = source, dataType = dataType, owner = OwnerName(tooltip), lines = {} }
	local entry, readable
	for _, text in ipairs(texts) do
		if IsSecret(text) then
			record.lines[#record.lines + 1] = "<secret>"
		elseif type(text) == "string" then
			readable = true
			record.lines[#record.lines + 1] = text
			entry = entry or ns.ResourceCatalog.Lookup(NodeName(text))
		end
	end
	-- Unreadable data leaves the OnShow path free to try the visible text.
	if readable then annotated = true end
	if entry then
		record.matched = entry.name
		local text, result = Describe(entry, Skills())
		if text then
			tooltip:AddLine(text, result.r, result.g, result.b)
			record.added = text
			-- Data post-calls run before Blizzard's own Show; OnShow must resize itself.
			if source == "show" then tooltip:Show() end
		end
	end
	Remember(record)
end

if TooltipDataProcessor then
	TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes, function(tooltip, data)
		if tooltip ~= GameTooltip or not ns.IsEnabled("tooltipDifficulty") then return end
		annotated = false
		local texts = {}
		if not IsSecret(data) and type(data) == "table" and type(data.lines) == "table" then
			for _, line in ipairs(data.lines) do texts[#texts + 1] = line.leftText end
		end
		Annotate(tooltip, texts, "data", type(data) == "table" and TypeName(data.type) or nil)
	end)
end

GameTooltip:HookScript("OnShow", function(tooltip)
	if annotated or not ns.IsEnabled("tooltipDifficulty") then return end
	local texts = {}
	for index = 1, tooltip:NumLines() do
		local line = _G["GameTooltipTextLeft" .. index]
		texts[#texts + 1] = line and line:GetText()
	end
	Annotate(tooltip, texts, "show")
end)
GameTooltip:HookScript("OnTooltipCleared", function() annotated = false end)
GameTooltip:HookScript("OnHide", function() annotated = false end)

ns.RegisterCommand("tooltip", "- report the last five game tooltips: how they were read, their text and any difficulty line added", function()
	ns.Print("Tooltip difficulty is %s. Herbalism: %s. Mining: %s.",
		ns.IsEnabled("tooltipDifficulty") and "on" or "off", Skills().herb.status, Skills().ore.status)
	if #recent == 0 then
		ns.Print("No tooltips seen yet. Hover a herb or ore node in the world, then run this again.")
		return
	end
	for index, record in ipairs(recent) do
		ns.Print("%d. %s via %s, owner %s: %s", index, record.dataType or "native", record.source, record.owner,
			#record.lines > 0 and table.concat(record.lines, " / "):gsub("[\r\n]+", " + ") or "<no lines>")
		ns.Print("    known: %s; added: %s", record.matched or "none", record.added or "none")
	end
end)
