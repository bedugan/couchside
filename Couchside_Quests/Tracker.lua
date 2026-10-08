-- Shared access to Blizzard's objective tracker: find a quest's block, and run callbacks after
-- the tracker lays itself out. Features decorate blocks with their own frames; nothing here
-- moves, reorders, or edits Blizzard's frames.

local _, ns = ...

-- Tracker modules whose blocks are keyed by questID.
local TRACKER_MODULES = {
	"CampaignQuestObjectiveTracker",
	"QuestObjectiveTracker",
	"WorldQuestObjectiveTracker",
	"BonusObjectiveTracker",
}

local layoutCallbacks = {}

ns.Tracker = {}

function ns.Tracker.FindBlock(questID)
	for _, name in ipairs(TRACKER_MODULES) do
		local module = _G[name]
		local block = module and module:GetExistingBlock(questID)
		if block and block:IsShown() then
			return block
		end
	end
end

-- Blocks are pooled and reused across quests, so decorations must be re-applied after every
-- layout pass.
function ns.Tracker.OnLayout(callback)
	table.insert(layoutCallbacks, callback)
end

local function RunLayoutCallbacks()
	for _, callback in ipairs(layoutCallbacks) do
		callback()
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
	for _, name in ipairs(TRACKER_MODULES) do
		local module = _G[name]
		if module then
			hooksecurefunc(module, "EndLayout", RunLayoutCallbacks)
		end
	end
end)
