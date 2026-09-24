-- Throwaway spike: does the game tell us which quest blob(s) the player is standing in?
--
-- Questions to answer in-game:
--   1. Does PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED fire for untracked quests, or only tracked/super-tracked?
--   2. Does C_Minimap.IsInsideQuestBlob(questID) answer for every quest in the log?
--   3. Do the event and the poll ever disagree?
--
-- Usage: walk around a zone with several quests (some tracked, some not).
--   Enter/leave messages print automatically.
--   /ergo  -> poll every quest in the log and compare with what the events reported.

local PREFIX = "|cff66ccff[Ergo spike]|r "

local function Print(msg)
	print(PREFIX .. msg)
end

local function Describe(questID)
	local title = C_QuestLog.GetTitleForQuestID(questID) or "?"
	local flags = {}
	if C_QuestLog.GetQuestWatchType(questID) ~= nil then
		table.insert(flags, "tracked")
	end
	if C_SuperTrack.GetSuperTrackedQuestID() == questID then
		table.insert(flags, "super")
	end
	local suffix = #flags > 0 and (" [" .. table.concat(flags, ",") .. "]") or " [untracked]"
	return ("%s (%d)%s"):format(title, questID, suffix)
end

local function CurrentMapName()
	local mapID = C_Map.GetBestMapForUnit("player")
	local info = mapID and C_Map.GetMapInfo(mapID)
	return info and ("%s (%d)"):format(info.name, mapID) or "unknown map"
end

-- What the event stream has told us, keyed by questID.
local insideByEvent = {}

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED")
frame:SetScript("OnEvent", function(_, _, questID, isInside)
	insideByEvent[questID] = isInside or nil
	Print(("%s %s"):format(isInside and "|cff00ff00ENTER|r" or "|cffff6666LEAVE|r", Describe(questID)))
end)

local function Scan()
	Print("Scan on " .. CurrentMapName())
	local _, numQuests = C_QuestLog.GetNumQuestLogEntries()
	local checked, errors = 0, 0
	local insideByPoll = {}

	-- Walk until the log runs out rather than trusting the "shown" count, which may skip collapsed headers.
	local index = 0
	while true do
		index = index + 1
		local info = C_QuestLog.GetInfo(index)
		if not info then
			break
		end
		if not info.isHeader then
			checked = checked + 1
			local ok, result = pcall(C_Minimap.IsInsideQuestBlob, info.questID)
			if not ok then
				errors = errors + 1
				Print("|cffff0000error|r " .. Describe(info.questID) .. ": " .. tostring(result))
			elseif result then
				insideByPoll[info.questID] = true
				Print("|cff00ff00inside (poll)|r " .. Describe(info.questID) .. (info.isHidden and " [hidden]" or ""))
			end
		end
	end

	-- Mismatches are the interesting part: they tell us which source to trust.
	for questID in pairs(insideByEvent) do
		if not insideByPoll[questID] then
			Print("|cffffcc00event-only|r " .. Describe(questID))
		end
	end
	for questID in pairs(insideByPoll) do
		if not insideByEvent[questID] then
			Print("|cffffcc00poll-only|r " .. Describe(questID))
		end
	end

	Print(("Checked %d of %d quests, %d errors."):format(checked, numQuests, errors))
end

SLASH_ERGONOMANCER1 = "/ergo"
SlashCmdList.ERGONOMANCER = Scan
