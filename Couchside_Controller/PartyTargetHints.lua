-- Party targeting hints: with the controller's Party Targeting option on, each party frame shows
-- the button that targets that member, using the game's own controller glyphs (atlases named in
-- SetGamepadBindingStrings, Blizzard_SharedXML/SharedConstants.lua). D-pad glyphs are the same for
-- every controller. Face-button glyphs follow the Button labels option. Automatic reads the active
-- controller's labelStyle (C_GamePad.GetDeviceMappedState); failing that, GetBindingText, which
-- returns atlas markup such as "|A:Gamepad_Gen_1_64:24:24|a". GetBindingText gave Brian's Xbox-style
-- controller the generic "1" while the game's own interact prompt showed X. Xbox, PlayStation and
-- Nintendo pick their glyphs directly. Without a usable atlas the hint falls
-- back to a drawn D-pad or face-button diamond with the button lit in amber.
--
-- Mapping, from Gethe/wow-ui-source's forever branch, Blizzard_GamepadActionBars/TargetActionBars/
-- FriendlyTargetingActionBar.lua (RefreshGroupTargeting, SetUpFaceBottom): party1 = D-pad up,
-- party2 = right, party3 = down, party4 = left, player = face bottom, your pet = face left (SetUpFaceLeft).
-- Face right targets your target's target, which has no party frame. Only in a party, not a raid.
-- GamepadSwapFriendlyTargetActions swaps the D-pad and face-button sides (StaticOverrideActionBar).
--
-- Each hint is a child of a Blizzard party frame and shows the button for whatever unit that frame
-- displays now. Raid-style frames keep their place and get new units when the group is sorted, so
-- following the frame's unit keeps the hint right without matching units to frames. The hints are
-- anchored to Blizzard's frames, never the other way round, so they stay ours to show, move and
-- recolor in combat, and Blizzard's frames are never touched.
--
-- Hints show whenever party targeting is active, not only while the targeting button is held, so
-- they can be read before pressing. They rest dim, with a badge naming the friendly targeting
-- button to hold, and go full brightness while it is held (Blizzard's friendly targeting bar is
-- shown exactly then). The button is the left target modifier, or the right one with
-- GamepadSwapTargetModifiers (HoldBindings.lua).
--
-- Blizzard's own prompt under raid-style party frames (RaidTargetingFreeSelection's footer legend,
-- RaidTargetDPAD.lua) hard-codes GAMEPAD_SHOULDER_LEFT, so it shows LB even when swapped. While the
-- hints are active the badge takes that prompt's place and the prompt is made invisible with
-- SetAlpha(0), restored on the way out. Its Show/Hide and bindings stay Blizzard's: hiding it
-- would fight the footer, which shows and hides the legend as it activates its LB binding (AGENTS.md:
-- the smallest change to a broken Blizzard frame). Classic party frames have no such prompt, so
-- there the badge sits above the top hint.

local _, ns = ...

local POLL_SECONDS = 0.2
local BASE_FRACTION = 0.5 -- hint size as a share of a party member frame's height, at 100%
local INSIDE_FRACTION = 0.6 -- inside the frame the hint is smaller, to leave the name readable
local GAP = 2
local RESTING_ALPHA = 0.35 -- hints while the friendly targeting button is up
local LIT = { 1, 0.79, 0.3, 1 } -- amber: the button to press
local DIM = { 0.05, 0.09, 0.13, 0.9 }
local EDGE = { 0, 0, 0, 1 }

-- arm: which of the four buttons; face: on the face buttons rather than the D-pad.
local BUTTONS = {
	player = { arm = "bottom", face = true },
	party1 = { arm = "top" },
	party2 = { arm = "right" },
	party3 = { arm = "bottom" },
	party4 = { arm = "left" },
	pet = { arm = "left", face = true },
}

-- The cluster ("dpad" or "face") and arm of the button that targets unit, or nil when none does.
function ns.PartyTargetButton(unit)
	local button = BUTTONS[unit]
	if not button then
		return nil
	end
	local onFace = button.face == true
	if C_CVar.GetCVarBool("GamepadSwapFriendlyTargetActions") then
		onFace = not onFace
	end
	return onFace and "face" or "dpad", button.arm
end

-- WoW's names for the face buttons: PAD1 bottom, PAD2 right, PAD3 left, PAD4 top.
local FACE_KEYS = { bottom = "PAD1", right = "PAD2", left = "PAD3", top = "PAD4" }

-- Glyph names, as in Gamepad_<name>_64.
local DPAD_GLYPHS = { top = "Gen_Up", right = "Gen_Right", bottom = "Gen_Down", left = "Gen_Left" }
local FACE_GLYPHS = {
	xbox = { bottom = "Ltr_A", right = "Ltr_B", left = "Ltr_X", top = "Ltr_Y" },
	playstation = { bottom = "Shp_Cross", right = "Shp_Circle", left = "Shp_Square", top = "Shp_Triangle" },
	nintendo = { bottom = "Rev_B", right = "Rev_A", left = "Rev_Y", top = "Rev_X" },
}

-- The active controller's label style as the game reports it, or nil.
function ns.ControllerLabelStyle()
	local deviceID = C_GamePad.GetActiveDeviceID()
	local state = deviceID and C_GamePad.GetDeviceMappedState(deviceID)
	return state and state.labelStyle or nil
end

-- Our label set for the game's labelStyle. Matched loosely until the values are confirmed in game;
-- the style names follow the glyph prefixes (Ltr, Shp, Rev).
local function LabelsForStyle(style)
	style = style and style:lower() or ""
	if style:find("ltr") or style:find("letter") or style:find("xbox") then
		return "xbox"
	elseif style:find("shp") or style:find("shape") or style:find("playstation") then
		return "playstation"
	elseif style:find("rev") or style:find("nintendo") or style:find("switch") then
		return "nintendo"
	end
	return nil
end

local function Usable(atlas)
	return atlas and C_Texture.GetAtlasInfo(atlas) and atlas or nil
end

-- The label set ("xbox", "playstation", "nintendo") for face and shoulder glyphs, or nil for the
-- game's own binding text.
local function LabelChoice()
	local choice = ns.GetOption("partyHintLabels")
	if choice == "auto" then
		return LabelsForStyle(ns.ControllerLabelStyle())
	end
	return choice
end

local LABEL_PREFIXES = { xbox = "Ltr_", playstation = "Shp_", nintendo = "Rev_" }
local SHOULDER_GLYPHS = {
	PADLSHOULDER = "LShoulder",
	PADRSHOULDER = "RShoulder",
	PADLTRIGGER = "LTrigger",
	PADRTRIGGER = "RTrigger",
}

-- The friendly targeting button's key, and where it came from ("binding" or "default").
function ns.FriendlyModifierKey()
	local swapped = C_CVar.GetCVarBool("GamepadSwapTargetModifiers")
	local key = GetBindingKey(swapped and "GAMEPADRIGHTTARGETMODIFIER" or "GAMEPADLEFTTARGETMODIFIER")
	if key then
		return key, "binding"
	end
	return swapped and "PADRSHOULDER" or "PADLSHOULDER", "default"
end

-- The glyph atlas for the friendly targeting button, or nil.
function ns.ModifierAtlas()
	local key = ns.FriendlyModifierKey()
	local prefix = LABEL_PREFIXES[LabelChoice()]
	local glyph = SHOULDER_GLYPHS[key]
	if prefix and glyph then
		local atlas = Usable("Gamepad_" .. prefix .. glyph .. "_64")
		if atlas then
			return atlas
		end
	end
	return Usable(GetBindingText(key):match("|A:([^:|]+)"))
end

-- The game's glyph atlas for a button, or nil when there is no usable one.
function ns.ButtonAtlas(cluster, arm)
	if cluster == "dpad" then
		return Usable("Gamepad_" .. DPAD_GLYPHS[arm] .. "_64")
	end
	local labels = FACE_GLYPHS[LabelChoice()]
	if labels then
		return Usable("Gamepad_" .. labels[arm] .. "_64")
	end
	return Usable(GetBindingText(FACE_KEYS[arm]):match("|A:([^:|]+)"))
end

-- Column and row of each cell in a 3x3 grid. The D-pad uses all five; face buttons skip the center.
local CELLS = {
	center = { 1, 1 },
	top = { 1, 0 },
	right = { 2, 1 },
	bottom = { 1, 2 },
	left = { 0, 1 },
}

-- Hint point, frame point and offset for each position.
local PLACEMENTS = {
	left = { "RIGHT", "LEFT", -GAP, 0 },
	right = { "LEFT", "RIGHT", GAP, 0 },
	top = { "BOTTOM", "TOP", 0, GAP },
	bottom = { "TOP", "BOTTOM", 0, -GAP },
	inside = { "TOPRIGHT", "TOPRIGHT", -GAP, -GAP },
}

local hints = {} -- [party frame] = hint
local lastDecision
local held = false -- the friendly targeting button, as of the last frame
local badge -- "<button> hold", above the top hint

local function Decide(text)
	if text ~= lastDecision then
		lastDecision = text
		ns.Debug("Party targeting hints: %s.", text)
	end
end

local function CreateHint(frame)
	local hint = CreateFrame("Frame", nil, frame)
	hint:SetFrameLevel(frame:GetFrameLevel() + 10)
	hint.cells = {}
	for name in pairs(CELLS) do
		local edge = hint:CreateTexture(nil, "ARTWORK")
		edge:SetColorTexture(unpack(EDGE))
		local fill = hint:CreateTexture(nil, "ARTWORK", nil, 1)
		fill:SetPoint("TOPLEFT", edge, "TOPLEFT", 1, -1)
		fill:SetPoint("BOTTOMRIGHT", edge, "BOTTOMRIGHT", -1, 1)
		hint.cells[name] = { edge = edge, fill = fill }
	end
	hint.glyph = hint:CreateTexture(nil, "ARTWORK")
	hint.glyph:SetAllPoints()
	hint:Hide()
	return hint
end

-- Redraws only when what the hint shows has changed. memberHeight sizes every hint alike, so a
-- short pet frame gets a hint as big as the rest.
local function Apply(hint, frame, cluster, arm, position, scale, memberHeight)
	local fraction = BASE_FRACTION * scale * (position == "inside" and INSIDE_FRACTION or 1)
	local cell = math.max(3, math.floor(memberHeight * fraction / 3 + 0.5))
	-- A frame at the screen's left edge has no room on its left.
	if position == "left" and (frame:GetLeft() or 0) < cell * 3 + GAP then
		position = "right"
	end
	hint.position = position
	local atlas = ns.ButtonAtlas(cluster, arm)
	hint.atlas = atlas
	local key = table.concat({ cluster, arm, position, cell, atlas or "drawn" }, ":")
	if hint.key == key then
		return
	end
	hint.key = key
	hint:SetSize(cell * 3, cell * 3)
	local placement = PLACEMENTS[position] or PLACEMENTS.left
	hint:ClearAllPoints()
	hint:SetPoint(placement[1], frame, placement[2], placement[3], placement[4])
	hint.glyph:SetShown(atlas ~= nil)
	if atlas then
		hint.glyph:SetAtlas(atlas)
	end
	for name, parts in pairs(CELLS) do
		local textures = hint.cells[name]
		textures.edge:SetSize(cell, cell)
		textures.edge:SetPoint("TOPLEFT", hint, "TOPLEFT", parts[1] * cell, -parts[2] * cell)
		local shown = not atlas and (name ~= "center" or cluster == "dpad")
		textures.edge:SetShown(shown)
		textures.fill:SetShown(shown)
		textures.fill:SetColorTexture(unpack(name == arm and LIT or DIM))
	end
end

local function CreateBadge()
	local frame = CreateFrame("Frame")
	frame:SetIgnoreParentAlpha(true) -- stays bright on a dimmed hint
	frame.glyph = frame:CreateTexture(nil, "ARTWORK")
	frame.glyph:SetPoint("LEFT")
	frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	frame.text:SetPoint("LEFT", frame.glyph, "RIGHT", 3, 0)
	frame.text:SetText("hold")
	frame:Hide()
	return frame
end

-- Badge point and hint point: over the outer edge of a column of hints, or before a row.
local BADGE_PLACEMENTS = {
	left = { "BOTTOMRIGHT", "TOPRIGHT", 0, GAP },
	right = { "BOTTOMLEFT", "TOPLEFT", 0, GAP },
	top = { "RIGHT", "LEFT", -GAP, 0 },
	bottom = { "BOTTOMLEFT", "TOPLEFT", 0, GAP },
	inside = { "BOTTOMLEFT", "TOPLEFT", 0, GAP },
}

-- Blizzard's LB prompt under raid-style party frames, once the footer has built it.
local function BlizzardPrompt()
	local footer = RaidTargetingFreeSelection and RaidTargetingFreeSelection.raidTargetingFooter
	return footer and footer.inputLegend
end

local promptHidden = false
local function HideBlizzardPrompt(hide)
	local legend = BlizzardPrompt()
	if not legend or hide == promptHidden then
		return
	end
	promptHidden = hide
	legend:SetAlpha(hide and 0 or 1)
	ns.Debug("Party targeting hints: Blizzard's LB prompt %s.", hide and "hidden" or "restored")
end

-- Puts the badge in place of Blizzard's prompt when there is one, else on the top hint (the
-- leftmost, for a row). Hides it when there is no button glyph to show.
local function PlaceBadge(topHint, position, prompt)
	local atlas = topHint and ns.ModifierAtlas()
	if not atlas then
		if badge then
			badge:Hide()
		end
		return
	end
	badge = badge or CreateBadge()
	local size = topHint:GetHeight()
	local info = C_Texture.GetAtlasInfo(atlas)
	local key = table.concat({ tostring(topHint), atlas, size, topHint.position, tostring(prompt) }, ":")
	if badge.key ~= key then
		badge.key = key
		badge:SetParent(topHint)
		badge:SetFrameLevel(topHint:GetFrameLevel() + 1)
		badge.glyph:SetAtlas(atlas)
		badge.glyph:SetSize(size * info.width / info.height, size)
		local font, _, flags = GameFontHighlight:GetFont()
		badge.text:SetFont(font, math.max(8, size * 0.55), flags ~= "" and flags or "OUTLINE")
		badge:SetSize(badge.glyph:GetWidth() + 3 + badge.text:GetStringWidth(), size)
		badge:ClearAllPoints()
		if prompt then
			badge:SetPoint("TOPLEFT", prompt, "TOPLEFT")
		else
			local placement = BADGE_PLACEMENTS[position] or BADGE_PLACEMENTS.left
			badge:SetPoint(placement[1], topHint, placement[2], placement[3], placement[4])
		end
	end
	badge:SetShown(not held)
end

local function FriendlyTargetingHeld()
	local pageUnit = GamepadMainActionBarFrame and GamepadMainActionBarFrame.PageUnit
	local bar = pageUnit and pageUnit.FriendlyTargetingActionBar
	return bar ~= nil and bar:IsShown()
end

local function ApplyHeld()
	local alpha = held and 1 or RESTING_ALPHA
	for _, hint in pairs(hints) do
		hint:SetAlpha(alpha)
	end
	if badge and badge.key then
		badge:SetShown(not held and badge:GetParent():IsShown())
	end
end

-- The frames that show party members and pets, and which kind they are. Raid-style frames include
-- the player and, with pets shown, the pets; with classic party frames the player and pet frames
-- join them.
local function PartyFrames()
	local frames = {}
	local compact = CompactPartyFrame
	if compact and compact:IsVisible() and compact.memberUnitFrames then
		for _, list in ipairs({ compact.memberUnitFrames, compact.petUnitFrames or {} }) do
			for _, frame in ipairs(list) do
				table.insert(frames, frame)
			end
		end
		return frames, "raid-style"
	end
	if PartyFrame and PartyFrame:IsVisible() and PartyFrame.PartyMemberFramePool then
		for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
			table.insert(frames, frame)
		end
	end
	table.insert(frames, PlayerFrame)
	table.insert(frames, PetFrame)
	return frames, "classic"
end

-- The unit the D-pad and face buttons target through this frame. Classic frames re-point .unit in a
-- vehicle, but the buttons still target the party slot, the player and the pet.
local function TargetUnit(frame)
	if frame == PlayerFrame then
		return "player"
	elseif frame == PetFrame then
		return "pet"
	end
	return frame.unitToken or frame.unit
end

-- Automatic placement keeps hints off neighbouring frames: left of a vertical column, above a
-- horizontal row. Classic party frames sit at the screen's left edge, so their hints go right.
local function AutoPosition(frames, kind)
	if kind == "classic" then
		return "right"
	end
	local firstX, firstY
	for _, frame in ipairs(frames) do
		local x, y
		if frame:IsVisible() then
			x, y = frame:GetCenter()
		end
		if x then
			if firstX then
				return math.abs(x - firstX) > math.abs(y - firstY) and "top" or "left"
			end
			firstX, firstY = x, y
		end
	end
	return "left"
end

local function HideAll()
	for _, hint in pairs(hints) do
		hint:Hide()
	end
end

local function WhyInactive()
	if not ns.IsEnabled("partyHints") then
		return "option off"
	elseif not C_CVar.GetCVarBool("GamepadUsePartyTargeting") then
		return "Party Targeting is off"
	elseif not IsInGroup() or IsInRaid() then
		return "not in a party"
	elseif EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
		-- Edit Mode fills empty raid-style slots with the player as placeholders.
		return "Edit Mode"
	elseif not (GamepadMainActionBarFrame and GamepadMainActionBarFrame:IsVisible()) then
		return "controller interface hidden"
	end
	return nil
end

local function Refresh()
	local reason = WhyInactive()
	if reason then
		HideAll()
		if badge then
			badge:Hide()
		end
		HideBlizzardPrompt(false)
		Decide("hidden, " .. reason)
		return
	end
	local frames, kind = PartyFrames()
	local position = ns.GetOption("partyHintPosition")
	if position == "auto" then
		position = AutoPosition(frames, kind)
	end
	local scale = ns.GetOption("partyHintSize") / 100
	-- A party member's frame: the player frame is bigger than the classic party frames.
	local memberHeight
	for _, frame in ipairs(frames) do
		local unit = frame:IsVisible() and TargetUnit(frame)
		if unit and unit:find("^party%d$") then
			memberHeight = frame:GetHeight()
			break
		end
	end
	local current, marked = {}, {}
	local topHint, topY, topX
	for _, frame in ipairs(frames) do
		current[frame] = true
		local unit = frame:IsVisible() and TargetUnit(frame)
		local cluster, arm
		if unit and UnitExists(unit) then
			cluster, arm = ns.PartyTargetButton(unit)
		end
		local hint = hints[frame]
		if cluster then
			hint = hint or CreateHint(frame)
			hints[frame] = hint
			-- A horizontal row puts pet frames under their owners, so a pet's top is its owner's frame.
			local framePosition = (unit == "pet" and position == "top") and "left" or position
			Apply(hint, frame, cluster, arm, framePosition, scale, memberHeight or frame:GetHeight())
			hint:SetAlpha(held and 1 or RESTING_ALPHA)
			hint:Show()
			local x, y = frame:GetLeft(), frame:GetTop()
			if y and (not topY or y > topY + 1 or (math.abs(y - topY) <= 1 and x < topX)) then
				topHint, topY, topX = hint, y, x
			end
			table.insert(marked, ("%s %s %s %s"):format(unit, cluster, arm, hint.atlas or "drawn"))
		elseif hint then
			hint:Hide()
		end
	end
	-- Frames of the other style, after a switch between raid-style and classic party frames.
	for frame, hint in pairs(hints) do
		if not current[frame] then
			hint:Hide()
		end
	end
	local prompt = kind == "raid-style" and topHint and BlizzardPrompt() or nil
	PlaceBadge(topHint, topHint and topHint.position or position, prompt)
	HideBlizzardPrompt(prompt ~= nil and badge ~= nil and badge.key ~= nil)
	Decide(("%s frames, %s: %s; hold %s"):format(kind, position, table.concat(marked, ", "),
		ns.ModifierAtlas() or "no glyph"))
end

-- Group changes, sorting, the Party Targeting CVars and the controller interface each have their
-- own update paths. Read their result at 5Hz while the option is on instead of hooking them. A
-- client without the Party Targeting CVar (Retail has no controller action bars) never polls.
local elapsed = 0
local driver = CreateFrame("Frame")
driver:Hide()
driver:SetScript("OnUpdate", function(_, delta)
	-- The held state is read every frame so the hints brighten as the button goes down.
	local nowHeld = FriendlyTargetingHeld()
	if nowHeld ~= held then
		held = nowHeld
		ApplyHeld()
		ns.Debug("Party targeting hints: friendly targeting %s.", held and "held" or "released")
	end
	elapsed = elapsed + delta
	if elapsed >= POLL_SECONDS then
		elapsed = 0
		Refresh()
	end
end)

local function ApplyOption()
	local enabled = ns.IsEnabled("partyHints") and C_CVar.GetCVarInfo("GamepadUsePartyTargeting") ~= nil
	driver:SetShown(enabled)
	Refresh()
end

ns.OnReady(ApplyOption)
ns.OnOptionChanged(function(key)
	if key == "partyHints" or key == "partyHintPosition" or key == "partyHintSize" or key == "partyHintLabels" then
		ApplyOption()
	end
end)
