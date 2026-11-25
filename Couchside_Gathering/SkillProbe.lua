-- Read-only report of the raw Herbalism/Mining values the difficulty line uses.
local _, ns = ...
local professions = { { name = "Herbalism", id = 182 }, { name = "Mining", id = 186 } }

local function Number(value)
	if issecretvalue and issecretvalue(value) then return "secret" end
	return type(value) == "number" and tostring(value) or "unknown"
end

ns.RegisterCommand("skills", "- read-only Herbalism/Mining skill report", function()
	local version, build = GetBuildInfo()
	ns.Print("Client %s (%s).", tostring(version), tostring(build))
	local read = C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID
	for _, profession in ipairs(professions) do
		if type(read) ~= "function" then
			ns.Print("%s: C_SkillInfo.GetSkillLineInfoByID missing.", profession.name)
		else
			local ok, value = pcall(read, profession.id)
			if not ok then
				ns.Print("%s: error.", profession.name)
			elseif type(value) ~= "table" or (issecretvalue and issecretvalue(value)) then
				ns.Print("%s: %s.", profession.name, value == nil and "nil (not learned?)" or "unreadable")
			else
				ns.Print("%s: rank %s/%s, modifier %s, temporary %s.", profession.name,
					Number(value.rank), Number(value.maxRank), Number(value.modifier), Number(value.tempPoints))
			end
		end
	end
	local profile = ns.ResourceDifficulty.Capture()
	ns.Print("Difficulty model sees Herbalism %s, Mining %s.", profile.herb.status, profile.ore.status)
end)
