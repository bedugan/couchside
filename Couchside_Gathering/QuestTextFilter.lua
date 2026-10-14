-- Match the live quest log, not a catalog of herb names. Unidentified tooltip
-- text stays visible. The scan freezes this read-only snapshot before querying.
local _, ns = ...

local function Normalize(text)
	return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
		:gsub("|T.-|t", "")
		:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function ObjectiveKey(text)
	text = Normalize(text):gsub("^%-%s*", "")
	text = text:gsub("^%d+%s*/%s*%d+%s+", "")
	text = text:gsub("%s*:%s*%d+%s*/%s*%d+%s*$", "")
	text = text:gsub("%s+%d+%s*/%s*%d+%s*$", "")
	return Normalize(text)
end

local function BuildSnapshot()
	local snapshot = { available = false, entries = {}, titles = {}, objectives = {}, warnings = {} }
	if not C_QuestLog or not C_QuestLog.GetInfo then
		snapshot.error = "quest-log API unavailable; no quest text excluded"
		return snapshot
	end
	local ok, err = pcall(function()
		local index = 1
		while true do
			local info = C_QuestLog.GetInfo(index)
			if not info then break end
			if not info.isHeader and info.questID and info.questID > 0 and info.title then
				local entry = { questID = info.questID, title = Normalize(info.title), objectives = {} }
				snapshot.entries[#snapshot.entries + 1] = entry
				snapshot.titles[entry.title] = info.questID
				local readable, objectives = pcall(function()
					return C_QuestLog.GetQuestObjectives(info.questID)
				end)
				if readable and objectives then
					for _, objective in ipairs(objectives) do
						if objective.text and objective.text ~= "" then
							entry.objectives[#entry.objectives + 1] = objective.text
							local key = ObjectiveKey(objective.text)
							if key ~= "" then snapshot.objectives[key] = info.questID end
						end
					end
				else
					snapshot.warnings[#snapshot.warnings + 1] = { questID = info.questID,
						message = readable and "objectives unavailable" or tostring(objectives) }
				end
			end
			index = index + 1
		end
	end)
	if not ok then
		-- Do not present a partial log snapshot as a complete exclusion set.
		return { available = false, entries = {}, titles = {}, objectives = {}, warnings = {},
			error = tostring(err) .. "; no quest text excluded" }
	end
	snapshot.available = true
	return snapshot
end

local function Filter(data, snapshot)
	local kept, removed, seen = {}, {}, {}
	for _, line in ipairs(data and data.lines or {}) do
		for _, field in ipairs({ "leftText", "rightText" }) do
			for raw in (line[field] or ""):gmatch("[^\r\n]+") do
				local text = Normalize(raw)
				local questID = snapshot.titles[text]
				local reason = questID and "quest title" or nil
				if not questID and (text:match("^%-%s+") or text:match("%d+%s*/%s*%d+")) then
					-- A plain resource name can also be an objective name. Require
					-- a bullet or progress counter before matching objective text.
					questID = snapshot.objectives[ObjectiveKey(text)]
					reason = questID and "quest objective" or nil
				end
				if questID then
					removed[#removed + 1] = { text = text, questID = questID, reason = reason }
				elseif text ~= "" and not seen[text] then
					seen[text] = true
					kept[#kept + 1] = text
				end
			end
		end
	end
	return { text = table.concat(kept, " / "), entries = kept, removed = removed }
end

ns.QuestTextFilter = { Snapshot = BuildSnapshot, Filter = Filter }
