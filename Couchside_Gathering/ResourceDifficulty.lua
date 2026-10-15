-- Current-character skill reads plus a pure Classic reference-band model.
-- No saved skill report is consumed. Nonzero bonuses remain unknown until
-- their interpretation is verified on Forever. This is not an exact chance.
local _, ns = ...
local ids = { herb = 182, ore = 186 }
local styles = {
	unknown = { label = "Unknown", r = 1, g = 1, b = 1 },
	gray = { label = "No gain", r = 0.773, g = 0.796, b = 0.816 },
	green = { label = "Low", r = 0.510, g = 0.902, b = 0.427 },
	yellow = { label = "Medium", r = 1, g = 0.894, b = 0.467 },
	orange = { label = "High", r = 1, g = 0.682, b = 0.310 },
	red = { label = "Too difficult", r = 1, g = 0.467, b = 0.439 },
	cap = { label = "At cap", r = 0.773, g = 0.796, b = 0.816 },
}

local function Number(value)
	if issecretvalue and issecretvalue(value) then return end
	if type(value) == "number" and value == value and value >= 0 and value < math.huge and value % 1 == 0 then return value end
end

local function Capture()
	local ok, version = pcall(GetBuildInfo)
	local supported = ok and not (issecretvalue and issecretvalue(version))
		and type(version) == "string" and version:match("^1%.60%.") ~= nil
	local profile, parts = {}, {}
	for _, category in ipairs({ "herb", "ore" }) do
		local skill = { status = "unsupported-client" }
		if supported then
			local read, value = pcall(function()
				if not C_SkillInfo or type(C_SkillInfo.GetSkillLineInfoByID) ~= "function" then return { status = "missing" } end
				local raw = C_SkillInfo.GetSkillLineInfoByID(ids[category])
				if issecretvalue and issecretvalue(raw) then return { status = "restricted" } end
				if raw == nil then return { status = "nil" } end
				if type(raw) ~= "table" then return { status = "invalid" } end
				local id, rank, maximum = Number(raw.skillID), Number(raw.rank), Number(raw.maxRank)
				local modifier, temporary = Number(raw.modifier), Number(raw.tempPoints)
				if id ~= ids[category] or not rank or rank < 1 or not maximum or maximum < rank
					or modifier == nil or temporary == nil then return { status = "invalid" } end
				if modifier ~= 0 or temporary ~= 0 then return { status = "unverified-bonus" } end
				return { status = "ok", rank = rank, maximum = maximum }
			end)
			skill = read and value or { status = "error" }
		end
		profile[category] = skill
		parts[#parts + 1] = category .. ":" .. skill.status .. ":" .. tostring(skill.rank) .. ":" .. tostring(skill.maximum)
	end
	profile.signature = table.concat(parts, ";")
	return profile
end

local function Evaluate(text, profile)
	local entry = ns.ResourceCatalog.Lookup(text)
	local skill = entry and profile and profile[entry.category]
	local band = entry and entry.difficulty
	local key, reason = "unknown", "reference bands or current skill unavailable"
	if band and skill and skill.status == "ok" and Number(skill.rank) and skill.rank >= 1
		and Number(skill.maximum) and skill.maximum >= skill.rank then
		if skill.rank < band.minimum then key, reason = "red", "below Classic minimum skill"
		elseif skill.rank >= skill.maximum then key, reason = "cap", "current training cap reached"
		elseif skill.rank >= band.gray then key, reason = "gray", "at or above Classic gray threshold"
		elseif skill.rank >= band.green then key, reason = "green", "Classic green band"
		elseif skill.rank >= band.yellow then key, reason = "yellow", "Classic yellow band"
		else key, reason = "orange", "Classic orange band" end
	end
	local style = styles[key]
	return { key = key, label = style.label, r = style.r, g = style.g, b = style.b, reason = reason }
end

ns.ResourceDifficulty = { Capture = Capture, Evaluate = Evaluate, version = "classic-reference-v1" }
