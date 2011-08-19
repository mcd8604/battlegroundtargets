-- -------------------------------------------------------------------------- --
--                                                                            --
-- Download: http://www.wowace.com/addons/battlegroundtargets/                --
-- Forum   : http://forums.wowace.com/showthread.php?t=19618                  --
--                                                                            --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- BattlegroundTargets by kunda                                               --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- BattlegroundTargets is a simple 'Enemy Unit Frame' for battlegrounds.      --
--                                                                            --
-- Features:                                                                  --
-- # Shows all battleground enemies with role, class and name.                --
--   - Left-click to target an enemy.                                         --
--   - Right-click to set target AND focus.                                   --
-- # Independent settings for '10 vs 10', '15 vs 15' and '40 vs 40'.          --
-- # Health Bar and Health Percent                                            --
-- # Specialization                                                           --
-- # Target Indicator                                                         --
-- # Target Count                                                             --
-- # Focus Indicator                                                          --
--                                                                            --
-- # It should be impossible to produce an ADDON_ACTION_BLOCKED error message --
--   by tainting the used secure templates. This includes configuration.      --
--                                                                            --
-- # Works with all officially supported languages:                           --
--   English (Default), deDE, esES/esMX, frFR, koKR, ruRU, zhCN and zhTW.     --
--                                                                            --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- NOTES:                                                                     --
-- # Health Bar and Health Percent:                                           --
--   - It's impossible to get 100% precise health values from all enemy       --
--     players all the time! The result is ALWAYS imprecise and wonky         --
--     regardless of the used technique. (This is intended and restricted by  --
--     Blizzard (the API) ... and that's good)                                --
--     A raidmember/raidpet MUST target(focus/mouseover) an enemy OR          --
--     you/yourpet MUST target/focus/mouseover an enemy to get the health!    --
--   - This feature enables three events:                                     --
--                         - UNIT_TARGET                                      --
--                         - UNIT_HEALTH_FREQUENT                             --
--                         - UPDATE_MOUSEOVER_UNIT                            --
--   - This feature works WITHOUT: combatlog scan                             --
--                    and WITHOUT: SendAddonMessage()                         --
--     - The use of SendAddonMessage() can give better results, I guess 2-10% --
--       in 10vs10/15vs15 and >25% in 40vs40 by transmitting focus/mouseover  --
--       information to other players. I may include (opt-in) this in some    --
--       future release if I ever add a 'range check' feature, because a      --
--       'range check' requires SendAddonMessage() for suitable data.         --
--     - The use of a combatlog scan is useless for health check because the  --
--       disadvantages (mass CPU usage in combat) far outweigh the benefit.   --
--   IT'S NOT RECOMMENDED TO ENABLE THIS FEATURE IN '40 vs 40' BATTLEGROUNDS! --
--                                                                            --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- slash commands: /bgt - /bgtargets - /battlegroundtargets                   --
--                                                                            --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- Credits:                                                                   --
-- - Talented from Jerry (for a list of all localized talent specs)           --
--                                                                            --
-- -------------------------------------------------------------------------- --

-- ---------------------------------------------------------------------------------------------------------------------
BattlegroundTargets_Options = {} -- SavedVariable options table
local BattlegroundTargets = CreateFrame("Frame") -- container

local L   = BattlegroundTargets_Localization -- localization table
local T   = BattlegroundTargets_Talents      -- localized talents
local BGN = BattlegroundTargets_BGNames      -- localized battleground names

local GVAR = {}     -- UI Widgets
local TEMPLATE = {} -- Templates

local AddonIcon = "Interface\\AddOns\\BattlegroundTargets\\BattlegroundTargets-texture-button"

local _G                      = _G
local GetTime                 = _G.GetTime
local InCombatLockdown        = _G.InCombatLockdown
local IsInInstance            = _G.IsInInstance
local IsRatedBattleground     = _G.IsRatedBattleground
local GetRealZoneText         = _G.GetRealZoneText
local GetBattlefieldStatus    = _G.GetBattlefieldStatus
local GetNumBattlefieldScores = _G.GetNumBattlefieldScores
local GetBattlefieldScore     = _G.GetBattlefieldScore
local UnitName                = _G.UnitName
local UnitFactionGroup        = _G.UnitFactionGroup
local UnitHealthMax           = _G.UnitHealthMax
local UnitHealth              = _G.UnitHealth
local math_min                = _G.math.min
local math_max                = _G.math.max
local math_floor              = _G.math.floor
local string_find             = _G.string.find
local string_match            = _G.string.match
local string_format           = _G.string.format
local table_sort              = _G.table.sort
local table_wipe              = _G.table.wipe
local pairs                   = _G.pairs

local inWorld
local inBattleground
local inCombat
local reCheckBG
local reSizeCheck = 0 -- check bgname if normal bgname check fails (reason: sometimes GetBattlefieldStatus and GetRealZoneText returns nil)
local reSetLayout
local isConfig
local testDataLoaded

local scoreUpdateThrottle = GetTime()
local scoreUpdateFrequency = 1

local targetName, targetRealm
local focusName, focusRealm

local playerFaction   = 0 -- player Faction
local oppositeFaction = 0 -- opposite Faction

local ENEMY_Data = {}         -- numerical | all data
local ENEMY_Names = {}        -- key/value | key = enemyName, value = count
local ENEMY_Name2Button = {}  -- key/value | key = enemyName, value = button number
local ENEMY_Name2Percent = {} -- key/value | key = enemyName, value = health in percent
local TARGET_Names = {}       -- key/value | key = friendName, value = enemyName

local testSize = 10
local buttonWidth = 150
local buttonHeight = 20

local healthBarWidth = 0.01

local sizeOffset     = 5
local sizeBarHeight = 14

local fontPath = _G["GameFontNormal"]:GetFont()

local currentSize = 10
local rbgSize = 10
local bgSize = {
	["Alterac Valley"] = 40,
	["Warsong Gulch"] = 10,
	["Arathi Basin"] = 15,
	["Eye of the Storm"] = 15,
	["Strand of the Ancients"] = 15,
	["Isle of Conquest"] = 40,
	["The Battle for Gilneas"] = 10,
	["Twin Peaks"] = 10, 
}

local bgSizeINT = {
	[1] = 10,
	[2] = 15,
	[3] = 40,
}

local sortBy = {
	[1] = ROLE.." / "..CLASS.." / "..NAME,
	[2] = ROLE.." / "..NAME,
	[3] = CLASS.." / "..ROLE.." / "..NAME,
	[4] = CLASS.." / "..NAME,
	[5] = NAME,
}

local classcolors = {}
for class, color in pairs(RAID_CLASS_COLORS) do
	classcolors[class] = {r = color.r, g = color.g, b = color.b}
end

local _HEAL    = 1
local _TANK    = 2
local _DAMAGE  = 3
local _UNKNOWN = 4
local classimg = "Interface\\WorldStateFrame\\Icons-Classes"
local classes = {
	DEATHKNIGHT = {icon = {0.26562500, 0.48437500, 0.51562500, 0.73437500}, -- ( 68/256, 124/256, 132/256, 188/256)
	               spec = {[1] = {role = _TANK,    icon = "Interface\\Icons\\Spell_Deathknight_BloodPresence"},    -- Blood
	                       [2] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Deathknight_FrostPresence"},    -- Frost
	                       [3] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Deathknight_UnholyPresence"},   -- Unholy
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	DRUID       = {icon = {0.75781250, 0.97656250, 0.01562500, 0.23437500}, -- (194/256, 250/256,   4/256,  60/256)
	               spec = {[1] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Nature_StarFall"},              -- Balance
	                       [2] = {role = _TANK,    icon = "Interface\\Icons\\Ability_Racial_BearForm"},            -- Feral Combat
	                       [3] = {role = _HEAL,    icon = "Interface\\Icons\\Spell_Nature_HealingTouch"},          -- Restoration
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	HUNTER      = {icon = {0.01953125, 0.23828125, 0.26562500, 0.48437500}, -- (  5/256,  61/256,  68/256, 124/256)
	               spec = {[1] = {role = _DAMAGE,  icon = "Interface\\Icons\\Ability_Hunter_BestialDiscipline"},   -- Beast Mastery
	                       [2] = {role = _DAMAGE,  icon = "Interface\\Icons\\Ability_Hunter_FocusedAim"},          -- Marksmanship
	                       [3] = {role = _DAMAGE,  icon = "Interface\\Icons\\Ability_Hunter_Camouflage"},          -- Survival
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	MAGE        = {icon = {0.26562500, 0.48437500, 0.01562500, 0.23437500}, -- ( 68/256, 124/256,   4/256,  60/256)
	               spec = {[1] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Holy_MagicalSentry"},           -- Arcane
	                       [2] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Fire_FireBolt02"},              -- Fire
	                       [3] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Frost_FrostBolt02"},            -- Frost
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	PALADIN     = {icon = {0.01953125, 0.23828125, 0.51562500, 0.73437500}, -- (  5/256,  61/256, 132/256, 188/256)
	               spec = {[1] = {role = _HEAL,    icon = "Interface\\Icons\\Spell_Holy_HolyBolt"},                -- Holy
	                       [2] = {role = _TANK,    icon = "Interface\\Icons\\Ability_Paladin_ShieldoftheTemplar"}, -- Protection
	                       [3] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Holy_AuraOfLight"},             -- Retribution
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	PRIEST      = {icon = {0.51171875, 0.73046875, 0.26562500, 0.48437500}, -- (131/256, 187/256,  68/256, 124/256)
	               spec = {[1] = {role = _HEAL,    icon = "Interface\\Icons\\Spell_Holy_PowerWordShield"},         -- Discipline
	                       [2] = {role = _HEAL,    icon = "Interface\\Icons\\Spell_Holy_GuardianSpirit"},          -- Holy
	                       [3] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain"},        -- Shadow
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	ROGUE       = {icon = {0.51171875, 0.73046875, 0.01562500, 0.23437500}, -- (131/256, 187/256,   4/256,  60/256)
	               spec = {[1] = {role = _DAMAGE,  icon = "Interface\\Icons\\Ability_Rogue_Eviscerate"},           -- Assassination
	                       [2] = {role = _DAMAGE,  icon = "Interface\\Icons\\Ability_BackStab"},                   -- Combat
	                       [3] = {role = _DAMAGE,  icon = "Interface\\Icons\\Ability_Stealth"},                    -- Subtlety
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	SHAMAN      = {icon = {0.26562500, 0.48437500, 0.26562500, 0.48437500}, -- ( 68/256, 124/256,  68/256, 124/256)
	               spec = {[1] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Nature_Lightning"},             -- Elemental
	                       [2] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Nature_LightningShield"},       -- Enhancement
	                       [3] = {role = _HEAL,    icon = "Interface\\Icons\\Spell_Nature_MagicImmunity"},         -- Restoration
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	WARLOCK     = {icon = {0.75781250, 0.97656250, 0.26562500, 0.48437500}, -- (194/256, 250/256,  68/256, 124/256)
	               spec = {[1] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Shadow_DeathCoil"},             -- Affliction
	                       [2] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Shadow_Metamorphosis"},         -- Demonology
	                       [3] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Shadow_RainOfFire"},            -- Destruction
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	WARRIOR     = {icon = {0.01953125, 0.23828125, 0.01562500, 0.23437500}, -- (  5/256,  61/256,   4/256,  60/256)
	               spec = {[1] = {role = _DAMAGE,  icon = "Interface\\Icons\\Ability_Warrior_SavageBlow"},         -- Arms
	                       [2] = {role = _DAMAGE,  icon = "Interface\\Icons\\Ability_Warrior_InnerRage"},          -- Fury
	                       [3] = {role = _TANK,    icon = "Interface\\Icons\\Ability_Warrior_DefensiveStance"},    -- Protection
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	ZZZFAILURE  = {icon = {0, 0, 0, 0},
	               spec = {[1] = {role = _UNKNOWN, icon = nil},   -- unknown
	                       [2] = {role = _UNKNOWN, icon = nil},   -- unknown
	                       [3] = {role = _UNKNOWN, icon = nil},   -- unknown
	                       [4] = {role = _UNKNOWN, icon = nil}}}, -- unknown
}

local function rt(H,E,M,P) return E,P,E,M,H,P,H,M end -- magical 180 degree texture cut center rotation

local Textures = {
	BattlegroundTargetsIcons = {path= "Interface\\Addons\\BattlegroundTargets\\BattlegroundTargets-texture-icons.tga"}, -- Textures.BattlegroundTargetsIcons.path
	SliderKnob       = {coords     =    {19/64, 30/64,  8/32, 25/32}},
	SliderBG         = {coordsL    =    { 1/64,  6/64, 26/32, 32/32},
	                    coordsM    =    { 9/64, 10/64, 26/32, 32/32},
	                    coordsR    =    {13/64, 18/64, 26/32, 32/32},
	                    coordsLdis =    { 1/64,  6/64,  1/32,  7/32},
	                    coordsMdis =    { 9/64, 10/64,  1/32,  7/32},
	                    coordsRdis =    {13/64, 18/64,  1/32,  7/32}},
	Expand           = {coords     =    { 1/64, 18/64,  8/32, 25/32}},
	Collapse         = {coords     = {rt( 1/64, 18/64,  8/32, 25/32)}}, -- 180 degree rota
	RoleIcon         = {[1]        =    {32/64, 48/64, 16/32, 32/32},   -- HEAL
	                    [2]        =    {48/64, 64/64,  0/32, 16/32},   -- TANK
	                    [3]        =    {32/64, 48/64,  0/32, 16/32},   -- DAMAGE
	                    [4]        =    {48/64, 64/64, 16/32, 32/32}},  -- UNKNOWN
}

local raidUnitID = {}
for i = 1, 40 do
	raidUnitID["raid"..i] = 1
	raidUnitID["raidpet"..i] = 1
end
local playerUnitID = {}
playerUnitID["target"] = 1
playerUnitID["pet"] = 1
playerUnitID["focus"] = 1
playerUnitID["mouseover"] = 1
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
local function NOOP() end
-- ---------------------------------------------------------------------------------------------------------------------

local function SortByTitlePullDownFunc(value)
	BattlegroundTargets_Options.ButtonSortBySize[currentSize] = value
	BattlegroundTargets:EnableConfigMode()
end

-- ---------------------------------------------------------------------------------------------------------------------
-- Template BorderTRBL START ----------------------------------------
TEMPLATE.BorderTRBL = function(frame) -- TRBL = Top-Right-Bottom-Left
	frame.FrameBorder = frame:CreateTexture(nil, "BORDER")
	frame.FrameBorder:SetPoint("TOPLEFT", 1, -1)
	frame.FrameBorder:SetPoint("BOTTOMRIGHT", -1, 1)
	frame.FrameBorder:SetTexture(0, 0, 0, 1)
	frame.FrameBackground = frame:CreateTexture(nil, "BACKGROUND")
	frame.FrameBackground:SetPoint("TOPLEFT", 0, 0)
	frame.FrameBackground:SetPoint("BOTTOMRIGHT", 0, 0)
	frame.FrameBackground:SetTexture(0.8, 0.2, 0.2, 1)
end
-- Template BorderTRBL END ----------------------------------------

-- Template TextButton START ----------------------------------------
TEMPLATE.DisableTextButton = function(button)
	button.Border:SetTexture(0.4, 0.4, 0.4, 1)
	button:Disable()
end

TEMPLATE.EnableTextButton = function(button, action)
	local buttoncolor
	if action == 1 then
		bordercolor = {0.73, 0.26, 0.21, 1}
	elseif action == 2 then
		bordercolor = {0.43, 0.32, 0.68, 1}
	elseif action == 3 then
		bordercolor = {0.24, 0.46, 0.21, 1}
	else
		bordercolor = {1, 1, 1, 1}
	end
	button.Border:SetTexture(bordercolor[1], bordercolor[2], bordercolor[3], bordercolor[4])
	button:Enable()
end

TEMPLATE.TextButton = function(button, text, action)
	local buttoncolor
	local bordercolor
	if action == 1 then
		button:SetNormalFontObject("GameFontNormal")
		button:SetDisabledFontObject("GameFontDisable") 
		buttoncolor = {0.38, 0, 0, 1}
		bordercolor = {0.73, 0.26, 0.21, 1}
	elseif action == 2 then
		button:SetNormalFontObject("GameFontWhiteSmall")
		button:SetDisabledFontObject("GameFontDisableSmall")
		buttoncolor = {0, 0, 0.5, 1}
		bordercolor = {0.43, 0.32, 0.68, 1}
	elseif action == 3 then
		button:SetNormalFontObject("GameFontWhiteSmall")
		button:SetDisabledFontObject("GameFontDisableSmall")
		buttoncolor = {0, 0.2, 0, 1}
		bordercolor = {0.24, 0.46, 0.21, 1}
	else
		button:SetNormalFontObject("GameFontNormal")
		button:SetDisabledFontObject("GameFontDisable")
		buttoncolor = {0, 0, 0, 1}
		bordercolor = {1, 1, 1, 1}
	end

	button.Background = button:CreateTexture(nil, "BORDER")
	button.Background:SetPoint("TOPLEFT", 1, -1)
	button.Background:SetPoint("BOTTOMRIGHT", -1, 1)
	button.Background:SetTexture(0, 0, 0, 1)

	button.Border = button:CreateTexture(nil, "BACKGROUND")
	button.Border:SetPoint("TOPLEFT", 0, 0)
	button.Border:SetPoint("BOTTOMRIGHT", 0, 0)
	button.Border:SetTexture(bordercolor[1], bordercolor[2], bordercolor[3], bordercolor[4])

	button.Normal = button:CreateTexture(nil, "ARTWORK")
	button.Normal:SetPoint("TOPLEFT", 2, -2)
	button.Normal:SetPoint("BOTTOMRIGHT", -2, 2)
	button.Normal:SetTexture(buttoncolor[1], buttoncolor[2], buttoncolor[3], buttoncolor[4])
	button:SetNormalTexture(button.Normal)

	button.Disabled = button:CreateTexture(nil, "OVERLAY")
	button.Disabled:SetPoint("TOPLEFT", 3, -3)
	button.Disabled:SetPoint("BOTTOMRIGHT", -3, 3)
	button.Disabled:SetTexture(0.6, 0.6, 0.6, 0.2)
	button:SetDisabledTexture(button.Disabled)

	button.Highlight = button:CreateTexture(nil, "OVERLAY")
	button.Highlight:SetPoint("TOPLEFT", 3, -3)
	button.Highlight:SetPoint("BOTTOMRIGHT", -3, 3)
	button.Highlight:SetTexture(0.6, 0.6, 0.6, 0.2)
	button:SetHighlightTexture(button.Highlight)

	button:SetPushedTextOffset(1, -1)	
	button:SetText(text)
end
-- Template TextButton END ----------------------------------------

-- Template IconButton START ----------------------------------------
TEMPLATE.IconButton = function(button, cut)
	button.Back = button:CreateTexture(nil, "BORDER")
	button.Back:SetPoint("TOPLEFT", 1, -1)
	button.Back:SetPoint("BOTTOMRIGHT", -1, 1)
	button.Back:SetTexture(0, 0, 0, 1)

	button.Border = button:CreateTexture(nil, "BACKGROUND")
	button.Border:SetPoint("TOPLEFT", 0, 0)
	button.Border:SetPoint("BOTTOMRIGHT", 0, 0)
	button.Border:SetTexture(0.8, 0.2, 0.2, 1)

	if cut == 1 then
		button.Normal = button:CreateTexture(nil, "ARTWORK")
		button.Normal:SetPoint("TOPLEFT", 3, -3)
		button.Normal:SetPoint("BOTTOMRIGHT", -3, 3)
		button.Normal:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
		button.Normal:SetTexCoord(8/32, 22/32, 10/32, 22/32)
		button:SetNormalTexture(button.Normal)
		button.Push = button:CreateTexture(nil, "ARTWORK")
		button.Push:SetPoint("TOPLEFT", 4, -4)
		button.Push:SetPoint("BOTTOMRIGHT", -4, 4)
		button.Push:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
		button.Push:SetTexCoord(8/32, 22/32, 10/32, 22/32)
		button:SetPushedTexture(button.Push)
	elseif cut == 2 then
		button.Normal = button:CreateTexture(nil, "ARTWORK")
		button.Normal:SetPoint("TOPLEFT", 3, -3)
		button.Normal:SetPoint("BOTTOMRIGHT", -3, 3)
		button.Normal:SetTexture("Interface\\GossipFrame\\BinderGossipIcon")
		button:SetNormalTexture(button.Normal)
		button.Push = button:CreateTexture(nil, "ARTWORK")
		button.Push:SetPoint("TOPLEFT", 4, -4)
		button.Push:SetPoint("BOTTOMRIGHT", -4, 4)
		button.Push:SetTexture("Interface\\GossipFrame\\BinderGossipIcon")
		button:SetPushedTexture(button.Push)
	end

	button.Highlight = button:CreateTexture(nil, "OVERLAY")
	button.Highlight:SetPoint("TOPLEFT", 3, -3)
	button.Highlight:SetPoint("BOTTOMRIGHT", -3, 3)
	button.Highlight:SetTexture(0.6, 0.6, 0.6, 0.2)
	button:SetHighlightTexture(button.Highlight)
end
-- Template IconButton END ----------------------------------------

-- Template CheckButton START ----------------------------------------
TEMPLATE.DisableCheckButton = function(button)
	button.Text:SetTextColor(0.5, 0.5, 0.5)
	button.Border:SetTexture(0.4, 0.4, 0.4, 1)
	button:Disable()
end

TEMPLATE.EnableCheckButton = function(button)
	button.Text:SetTextColor(1, 1, 1)
	button.Border:SetTexture(0.8, 0.2, 0.2, 1)
	button:Enable()
end

TEMPLATE.CheckButton = function(button, size, space, text)
	button.Border = button:CreateTexture(nil, "BACKGROUND")
	button.Border:SetWidth( size )
	button.Border:SetHeight( size )
	button.Border:SetPoint("LEFT", 0, 0)
	button.Border:SetTexture(0.4, 0.4, 0.4, 1)

	button.Background = button:CreateTexture(nil, "BORDER")
	button.Background:SetPoint("TOPLEFT", button.Border, "TOPLEFT", 1, -1)
	button.Background:SetPoint("BOTTOMRIGHT", button.Border, "BOTTOMRIGHT", -1, 1)
	button.Background:SetTexture(0, 0, 0, 1)

	button.Normal = button:CreateTexture(nil, "ARTWORK")
	button.Normal:SetPoint("TOPLEFT", button.Border, "TOPLEFT", 1, -1)
	button.Normal:SetPoint("BOTTOMRIGHT", button.Border, "BOTTOMRIGHT", -1, 1)
	button.Normal:SetTexture(0, 0, 0, 1)
	button:SetNormalTexture(button.Normal)

	button.Push = button:CreateTexture(nil, "ARTWORK")
	button.Push:SetPoint("TOPLEFT", button.Border, "TOPLEFT", 4, -4)
	button.Push:SetPoint("BOTTOMRIGHT", button.Border, "BOTTOMRIGHT", -4, 4)
	button.Push:SetTexture(0.4, 0.4, 0.4, 0.5)
	button:SetPushedTexture(button.Push)

	button.Disabled = button:CreateTexture(nil, "ARTWORK")
	button.Disabled:SetPoint("TOPLEFT", button.Border, "TOPLEFT", 3, -3)
	button.Disabled:SetPoint("BOTTOMRIGHT", button.Border, "BOTTOMRIGHT", -3, 3)
	button.Disabled:SetTexture(0.4, 0.4, 0.4, 0.5)
	button:SetDisabledTexture(button.Disabled)

	button.Checked = button:CreateTexture(nil, "ARTWORK")
	button.Checked:SetWidth( size )
	button.Checked:SetHeight( size )
	button.Checked:SetPoint("LEFT", 0, 0)
	button.Checked:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	button:SetCheckedTexture(button.Checked)

	button.Text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	button.Text:SetHeight( size )
	button.Text:SetPoint("LEFT", button.Normal, "RIGHT", space, 0)
	button.Text:SetJustifyH("LEFT")
	button.Text:SetText(text)
	button.Text:SetTextColor(1, 1, 1, 1)

	button:SetWidth(size + space + button.Text:GetStringWidth() + space)
	button:SetHeight(size)

	button.Highlight = button:CreateTexture(nil, "OVERLAY")
	button.Highlight:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
	button.Highlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
	button.Highlight:SetTexture(1, 1, 1, 0.1)
	button.Highlight:Hide()

	button:SetScript("OnEnter", function() button.Highlight:Show() end)
	button:SetScript("OnLeave", function() button.Highlight:Hide() end)
end
-- Template CheckButton END ----------------------------------------

-- Template TabButton START ----------------------------------------
TEMPLATE.SetTabButton = function(button, showIt)
	if showIt then
		button.TextureBottom:SetTexture(0, 0, 0, 1)
		button.TextureBorder:SetTexture(0.8, 0.2, 0.2, 1)
	else
		button.TextureBottom:SetTexture(0.8, 0.2, 0.2, 1)
		button.TextureBorder:SetTexture(0.4, 0.4, 0.4, 0.4)
	end
end

TEMPLATE.DisableTabButton = function(button)
	button.Text:SetTextColor(0.5, 0.5, 0.5, 1)
	button:Disable()
end

TEMPLATE.EnableTabButton = function(button, active)
	if active then
		button.Text:SetTextColor(0, 0.75, 0, 1)
	else
		button.Text:SetTextColor(1, 0, 0, 1)
	end
	button:Enable()
end

TEMPLATE.TabButton = function(button, text, active)
	button.Texture = button:CreateTexture(nil, "BORDER")
	button.Texture:SetPoint("TOPLEFT", 1, -1)
	button.Texture:SetPoint("BOTTOMRIGHT", -1, 1)
	button.Texture:SetTexture(0, 0, 0, 1)

	button.TextureBorder = button:CreateTexture(nil, "BACKGROUND")
	button.TextureBorder:SetPoint("TOPLEFT", 0, 0)
	button.TextureBorder:SetPoint("BOTTOMRIGHT", -1, 1)
	button.TextureBorder:SetPoint("TOPRIGHT" ,0, 0)
	button.TextureBorder:SetPoint("BOTTOMLEFT" ,1, 1)
	button.TextureBorder:SetTexture(0.8, 0.2, 0.2, 1)

	button.TextureBottom = button:CreateTexture(nil, "ARTWORK")
	button.TextureBottom:SetPoint("TOPLEFT", button, "BOTTOMLEFT" ,1, 2)
	button.TextureBottom:SetPoint("BOTTOMLEFT" ,1, 1)
	button.TextureBottom:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT" ,-1, 2)
	button.TextureBottom:SetPoint("BOTTOMRIGHT" ,-1, 1)
	button.TextureBottom:SetTexture(0.8, 0.2, 0.2, 1)

	button.TextureHighlight = button:CreateTexture(nil, "ARTWORK")
	button.TextureHighlight:SetPoint("TOPLEFT", 3, -3)
	button.TextureHighlight:SetPoint("BOTTOMRIGHT", -3, 3)
	button.TextureHighlight:SetTexture(1, 1, 1, 0.2)
	button:SetHighlightTexture(button.TextureHighlight)

	button.Text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	button.Text:SetText(text)
	button.Text:SetWidth( button.Text:GetStringWidth()+10 )
	button.Text:SetHeight(12)
	button.Text:SetPoint("CENTER", button, "CENTER", 0, 0)
	button.Text:SetJustifyH("CENTER")
	button.Text:SetTextColor(1, 1, 1, 1)

	if active then
		button.Text:SetTextColor(0, 0.75, 0, 1)
	else
		button.Text:SetTextColor(1, 0, 0, 1)
	end
end
-- Template TabButton END ----------------------------------------

-- Template Slider START ----------------------------------------
TEMPLATE.DisableSlider = function(slider)
	slider.textMin:SetTextColor(0.5, 0.5, 0.5, 1)
	slider.textMax:SetTextColor(0.5, 0.5, 0.5, 1)
	slider.sliderBGL:SetTexCoord(unpack(Textures.SliderBG.coordsLdis))
	slider.sliderBGM:SetTexCoord(unpack(Textures.SliderBG.coordsMdis))
	slider.sliderBGR:SetTexCoord(unpack(Textures.SliderBG.coordsRdis))
	slider.thumb:SetTexCoord(0, 0, 0, 0)
	slider:Disable()
end

TEMPLATE.EnableSlider = function(slider)
	slider.textMin:SetTextColor(0.8, 0.8, 0.8, 1)
	slider.textMax:SetTextColor(0.8, 0.8, 0.8, 1)
	slider.sliderBGL:SetTexCoord(unpack(Textures.SliderBG.coordsL))
	slider.sliderBGM:SetTexCoord(unpack(Textures.SliderBG.coordsM))
	slider.sliderBGR:SetTexCoord(unpack(Textures.SliderBG.coordsR))
	slider.thumb:SetTexCoord(unpack(Textures.SliderKnob.coords))
	slider:Enable()
end

TEMPLATE.Slider = function(slider, width, step, minVal, maxVal, curVal, func, measure)
	slider:SetWidth(width)
	slider:SetHeight(17)
	slider:SetValueStep(step) 
	slider:SetMinMaxValues(minVal, maxVal)
	slider:SetValue(curVal)
	slider:SetOrientation("HORIZONTAL")

	slider.textMin = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	slider.textMin:SetPoint("TOP", slider, "BOTTOM", 0, -1)
	slider.textMin:SetPoint("LEFT", slider, "LEFT", 0, 0)
	slider.textMin:SetJustifyH("CENTER")
	slider.textMin:SetTextColor(0.8, 0.8, 0.8, 1)
	if measure == "%" then
		slider.textMin:SetText(minVal.."%")
	elseif measure == "K" then
		slider.textMin:SetText((minVal/1000).."k")
	elseif measure == "H" then
		slider.textMin:SetText((minVal/100))
	elseif measure == "px" then
		slider.textMin:SetText(minVal.."px")
	elseif measure == "blank" then
		slider.textMin:SetText("")
	else
		slider.textMin:SetText(minVal)
	end
	slider.textMax = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	slider.textMax:SetPoint("TOP", slider, "BOTTOM", 0, -1)
	slider.textMax:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
	slider.textMax:SetJustifyH("CENTER")
	slider.textMax:SetTextColor(0.8, 0.8, 0.8, 1)
	if measure == "%" then
		slider.textMax:SetText(maxVal.."%")
	elseif measure == "K" then
		slider.textMax:SetText((maxVal/1000).."k")
	elseif measure == "H" then
		slider.textMax:SetText((maxVal/100))
	elseif measure == "px" then
		slider.textMax:SetText(maxVal.."px")
	elseif measure == "blank" then
		slider.textMax:SetText("")
	else
		slider.textMax:SetText(maxVal)
	end

	slider.sliderBGL = slider:CreateTexture(nil, "BACKGROUND")
	slider.sliderBGL:SetWidth(5)
	slider.sliderBGL:SetHeight(6)
	slider.sliderBGL:SetPoint("LEFT", slider, "LEFT", 0, 0)
	slider.sliderBGL:SetTexture(Textures.BattlegroundTargetsIcons.path)
	slider.sliderBGL:SetTexCoord(unpack(Textures.SliderBG.coordsL))
	slider.sliderBGM = slider:CreateTexture(nil, "BACKGROUND")
	slider.sliderBGM:SetWidth(width-5-5)
	slider.sliderBGM:SetHeight(6)
	slider.sliderBGM:SetPoint("LEFT", slider.sliderBGL, "RIGHT", 0, 0)
	slider.sliderBGM:SetTexture(Textures.BattlegroundTargetsIcons.path)
	slider.sliderBGM:SetTexCoord(unpack(Textures.SliderBG.coordsM))
	slider.sliderBGR = slider:CreateTexture(nil, "BACKGROUND")
	slider.sliderBGR:SetWidth(5)
	slider.sliderBGR:SetHeight(6)
	slider.sliderBGR:SetPoint("LEFT", slider.sliderBGM, "RIGHT", 0, 0)
	slider.sliderBGR:SetTexture(Textures.BattlegroundTargetsIcons.path)
	slider.sliderBGR:SetTexCoord(unpack(Textures.SliderBG.coordsR))

	slider.thumb = slider:CreateTexture(nil, "BORDER")
	slider.thumb:SetWidth(11)
	slider.thumb:SetHeight(17)
	slider.thumb:SetTexture(Textures.BattlegroundTargetsIcons.path)
	slider.thumb:SetTexCoord(unpack(Textures.SliderKnob.coords))
	slider:SetThumbTexture(slider.thumb)

	slider:SetScript("OnValueChanged", function(self, value)
		if func then
			func(self, value)
		end
	end)
end
-- Template Slider END ----------------------------------------

-- Template PullDownMenu START ----------------------------------------
TEMPLATE.DisablePullDownMenu = function(button)
	button.PullDownMenu:Hide()
	button.PullDownButtonBorder:SetTexture(0.4, 0.4, 0.4, 1)
	button:Disable()
end

TEMPLATE.EnablePullDownMenu = function(button)
	button.PullDownButtonBorder:SetTexture(0.8, 0.2, 0.2, 1)
	button:Enable()
end

TEMPLATE.PullDownMenu = function(button, contentName, buttonText, pulldownWidth, contentNum, func)
	button.PullDownButtonBG = button:CreateTexture(nil, "BORDER")
	button.PullDownButtonBG:SetPoint("TOPLEFT", 1, -1)
	button.PullDownButtonBG:SetPoint("BOTTOMRIGHT", -1, 1)
	button.PullDownButtonBG:SetTexture(0, 0, 0, 1)

	button.PullDownButtonBorder = button:CreateTexture(nil, "BACKGROUND")
	button.PullDownButtonBorder:SetPoint("TOPLEFT", 0, 0)
	button.PullDownButtonBorder:SetPoint("BOTTOMRIGHT", 0, 0)
	button.PullDownButtonBorder:SetTexture(0.4, 0.4, 0.4, 1)

	button.PullDownButtonExpand = button:CreateTexture(nil, "OVERLAY")
	button.PullDownButtonExpand:SetHeight(14)
	button.PullDownButtonExpand:SetWidth(14)
	button.PullDownButtonExpand:SetPoint("RIGHT", button, "RIGHT", -2, 0)
	button.PullDownButtonExpand:SetTexture(Textures.BattlegroundTargetsIcons.path)
	button.PullDownButtonExpand:SetTexCoord(unpack(Textures.Expand.coords))
	button:SetNormalTexture(button.PullDownButtonExpand)

	button.PullDownButtonDisabled = button:CreateTexture(nil, "OVERLAY")
	button.PullDownButtonDisabled:SetPoint("TOPLEFT", 3, -3)
	button.PullDownButtonDisabled:SetPoint("BOTTOMRIGHT", -3, 3)
	button.PullDownButtonDisabled:SetTexture(0.6, 0.6, 0.6, 0.2)
	button:SetDisabledTexture(button.PullDownButtonDisabled)

	button.PullDownButtonHighlight = button:CreateTexture(nil, "OVERLAY")
	button.PullDownButtonHighlight:SetPoint("TOPLEFT", 1, -1)
	button.PullDownButtonHighlight:SetPoint("BOTTOMRIGHT", -1, 1)
	button.PullDownButtonHighlight:SetTexture(0.6, 0.6, 0.6, 0.2)
	button:SetHighlightTexture(button.PullDownButtonHighlight)

	button.PullDownButtonText = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	button.PullDownButtonText:SetHeight(sizeBarHeight)
	button.PullDownButtonText:SetPoint("LEFT", sizeOffset+2, 0)
	button.PullDownButtonText:SetJustifyH("LEFT")
	button.PullDownButtonText:SetText(buttonText)
	button.PullDownButtonText:SetTextColor(1, 1, 0.5, 1)

	button.PullDownMenu = CreateFrame("Frame", nil, button)
	TEMPLATE.BorderTRBL(button.PullDownMenu)
	button.PullDownMenu:EnableMouse(true)
	button.PullDownMenu:SetToplevel(true)
	button.PullDownMenu:SetHeight(sizeOffset+(contentNum*sizeBarHeight)+sizeOffset)
	button.PullDownMenu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, 1)
	button.PullDownMenu:Hide()

	local function OnLeave()
		if not button:IsMouseOver() and not button.PullDownMenu:IsMouseOver() then
			button.PullDownMenu:Hide()
			button.PullDownButtonExpand:SetTexCoord(unpack(Textures.Expand.coords))
		end
	end

	local autoWidth = 0
	for i = 1, contentNum do
		if not button.PullDownMenu.Button then button.PullDownMenu.Button = {} end
		button.PullDownMenu.Button[i] = CreateFrame("Button", nil, button.PullDownMenu)
		button.PullDownMenu.Button[i]:SetHeight(sizeBarHeight)
		button.PullDownMenu.Button[i]:SetFrameLevel( button.PullDownMenu:GetFrameLevel() + 5 )
		if i == 1 then
			button.PullDownMenu.Button[i]:SetPoint("TOPLEFT", button.PullDownMenu, "TOPLEFT", sizeOffset, -sizeOffset)
		else
			button.PullDownMenu.Button[i]:SetPoint("TOPLEFT", button.PullDownMenu.Button[(i-1)], "BOTTOMLEFT", 0, 0)
		end

		button.PullDownMenu.Button[i].Text = button.PullDownMenu.Button[i]:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		button.PullDownMenu.Button[i].Text:SetHeight(sizeBarHeight)
		button.PullDownMenu.Button[i].Text:SetPoint("LEFT", 2, 0)
		button.PullDownMenu.Button[i].Text:SetJustifyH("LEFT")
		button.PullDownMenu.Button[i].Text:SetTextColor(1, 1, 1, 1)

		button.PullDownMenu.Button[i]:SetScript("OnLeave", OnLeave)
		button.PullDownMenu.Button[i]:SetScript("OnClick", function()
			button.value1 = button.PullDownMenu.Button[i].value1
			button.PullDownButtonText:SetText( button.PullDownMenu.Button[i].Text:GetText() )
			button.PullDownMenu:Hide()
			button.PullDownButtonExpand:SetTexCoord(unpack(Textures.Expand.coords))
			if func then
				func(button.value1)
			end
		end)

		button.PullDownMenu.Button[i].Highlight = button.PullDownMenu.Button[i]:CreateTexture(nil, "ARTWORK")
		button.PullDownMenu.Button[i].Highlight:SetPoint("TOPLEFT", 0, 0)
		button.PullDownMenu.Button[i].Highlight:SetPoint("BOTTOMRIGHT", 0, 0)
		button.PullDownMenu.Button[i].Highlight:SetTexture(1, 1, 1, 0.2)
		button.PullDownMenu.Button[i]:SetHighlightTexture(button.PullDownMenu.Button[i].Highlight)

		if contentName == "SortBy" then
			button.PullDownMenu.Button[i].Text:SetText(sortBy[i])
			button.PullDownMenu.Button[i].value1 = i
		end
		button.PullDownMenu.Button[i]:Show()

		if pulldownWidth == 0 then
			local w = button.PullDownMenu.Button[i].Text:GetStringWidth()+15+18
			if w > autoWidth then
				autoWidth = w
			end
		end
	end

	local newWidth = pulldownWidth
	if pulldownWidth == 0 then
		newWidth = autoWidth
	end

	button.PullDownButtonText:SetWidth(newWidth-sizeOffset-sizeOffset)
	button.PullDownMenu:SetWidth(newWidth)
	for i = 1, contentNum do
		button.PullDownMenu.Button[i]:SetWidth(newWidth-sizeOffset-sizeOffset)
		button.PullDownMenu.Button[i].Text:SetWidth(newWidth-sizeOffset-sizeOffset)
	end
	button:SetWidth(newWidth)

	button.PullDownMenu:SetScript("OnLeave", OnLeave)
	button.PullDownMenu:SetScript("OnHide", function(self) self:Hide() end) -- for esc close

	button:SetScript("OnLeave", OnLeave)
	button:SetScript("OnClick", function()
		if button.PullDownMenu:IsShown() then
			button.PullDownMenu:Hide()
			button.PullDownButtonExpand:SetTexCoord(unpack(Textures.Expand.coords))
		else
			button.PullDownMenu:Show()
			button.PullDownButtonExpand:SetTexCoord(unpack(Textures.Collapse.coords))
		end
	end)
end
-- Template PullDownMenu END ----------------------------------------
-- ---------------------------------------------------------------------------------------------------------------------



-- ---------------------------------------------------------------------------------------------------------------------
local function Print(...)
	print("|cffffff7fBattlegroundTargets:|r", ...)
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:InitOptions()
	SlashCmdList["BATTLEGROUNDTARGETS"] = function()
		BattlegroundTargets:Frame_Toggle(GVAR.OptionsFrame)
	end
	SLASH_BATTLEGROUNDTARGETS1 = "/bgt"
	SLASH_BATTLEGROUNDTARGETS2 = "/bgtargets"
	SLASH_BATTLEGROUNDTARGETS3 = "/battlegroundtargets"

	if BattlegroundTargets_Options.version == nil then
		BattlegroundTargets_Options.version = 3
	end

	if BattlegroundTargets_Options.version == 1 then
		if BattlegroundTargets_Options.ButtonFontSize then
			if BattlegroundTargets_Options.ButtonFontSize[10] then
				if     BattlegroundTargets_Options.ButtonFontSize[10] == 1 then BattlegroundTargets_Options.ButtonFontSize[10] =  9
				elseif BattlegroundTargets_Options.ButtonFontSize[10] == 2 then BattlegroundTargets_Options.ButtonFontSize[10] = 10
				elseif BattlegroundTargets_Options.ButtonFontSize[10] == 3 then BattlegroundTargets_Options.ButtonFontSize[10] = 12
				elseif BattlegroundTargets_Options.ButtonFontSize[10] == 4 then BattlegroundTargets_Options.ButtonFontSize[10] = 14
				elseif BattlegroundTargets_Options.ButtonFontSize[10] == 5 then BattlegroundTargets_Options.ButtonFontSize[10] = 16
				end
			end
			if BattlegroundTargets_Options.ButtonFontSize[15] then
				if     BattlegroundTargets_Options.ButtonFontSize[15] == 1 then BattlegroundTargets_Options.ButtonFontSize[15] =  9
				elseif BattlegroundTargets_Options.ButtonFontSize[15] == 2 then BattlegroundTargets_Options.ButtonFontSize[15] = 10
				elseif BattlegroundTargets_Options.ButtonFontSize[15] == 3 then BattlegroundTargets_Options.ButtonFontSize[15] = 12
				elseif BattlegroundTargets_Options.ButtonFontSize[15] == 4 then BattlegroundTargets_Options.ButtonFontSize[15] = 14
				elseif BattlegroundTargets_Options.ButtonFontSize[15] == 5 then BattlegroundTargets_Options.ButtonFontSize[15] = 16
				end
			end
			if BattlegroundTargets_Options.ButtonFontSize[40] then
				if     BattlegroundTargets_Options.ButtonFontSize[40] == 1 then BattlegroundTargets_Options.ButtonFontSize[40] =  9
				elseif BattlegroundTargets_Options.ButtonFontSize[40] == 2 then BattlegroundTargets_Options.ButtonFontSize[40] = 10
				elseif BattlegroundTargets_Options.ButtonFontSize[40] == 3 then BattlegroundTargets_Options.ButtonFontSize[40] = 12
				elseif BattlegroundTargets_Options.ButtonFontSize[40] == 4 then BattlegroundTargets_Options.ButtonFontSize[40] = 14
				elseif BattlegroundTargets_Options.ButtonFontSize[40] == 5 then BattlegroundTargets_Options.ButtonFontSize[40] = 16
				end
			end
			Print("Fontsize update! Please check Configuration.")
		end
		BattlegroundTargets_Options.version = 2
	end

	if BattlegroundTargets_Options.version == 2 then
		-- rename ButtonShowCrosshairs to ButtonShowTargetIndicator
		if BattlegroundTargets_Options.ButtonShowCrosshairs then
			BattlegroundTargets_Options.ButtonShowTargetIndicator = {}
			if BattlegroundTargets_Options.ButtonShowCrosshairs[10] then
				BattlegroundTargets_Options.ButtonShowTargetIndicator[10] = true
			else
				BattlegroundTargets_Options.ButtonShowTargetIndicator[10] = false
			end
			if BattlegroundTargets_Options.ButtonShowCrosshairs[15] then
				BattlegroundTargets_Options.ButtonShowTargetIndicator[15] = true
			else
				BattlegroundTargets_Options.ButtonShowTargetIndicator[15] = false
			end
			if BattlegroundTargets_Options.ButtonShowCrosshairs[40] then
				BattlegroundTargets_Options.ButtonShowTargetIndicator[40] = true
			else
				BattlegroundTargets_Options.ButtonShowTargetIndicator[40] = false
			end
			BattlegroundTargets_Options.ButtonShowCrosshairs = nil
		end
		BattlegroundTargets_Options.version = 3
	end

	if BattlegroundTargets_Options.pos                           == nil then BattlegroundTargets_Options.pos                           = {}    end
	if BattlegroundTargets_Options.MinimapButton                 == nil then BattlegroundTargets_Options.MinimapButton                 = false end
	if BattlegroundTargets_Options.MinimapButtonPos              == nil then BattlegroundTargets_Options.MinimapButtonPos              = -90   end

	if BattlegroundTargets_Options.IndependentPositioning        == nil then BattlegroundTargets_Options.IndependentPositioning        = {}    end
	if BattlegroundTargets_Options.IndependentPositioning[10]    == nil then BattlegroundTargets_Options.IndependentPositioning[10]    = false end
	if BattlegroundTargets_Options.IndependentPositioning[15]    == nil then BattlegroundTargets_Options.IndependentPositioning[15]    = false end
	if BattlegroundTargets_Options.IndependentPositioning[40]    == nil then BattlegroundTargets_Options.IndependentPositioning[40]    = false end

	if BattlegroundTargets_Options.ButtonEnableBracket           == nil then BattlegroundTargets_Options.ButtonEnableBracket           = {}    end
	if BattlegroundTargets_Options.ButtonShowSpec                == nil then BattlegroundTargets_Options.ButtonShowSpec                = {}    end
	if BattlegroundTargets_Options.ButtonClassIcon               == nil then BattlegroundTargets_Options.ButtonClassIcon               = {}    end
	if BattlegroundTargets_Options.ButtonShowRealm               == nil then BattlegroundTargets_Options.ButtonShowRealm               = {}    end
	if BattlegroundTargets_Options.ButtonShowTargetIndicator     == nil then BattlegroundTargets_Options.ButtonShowTargetIndicator     = {}    end
	if BattlegroundTargets_Options.ButtonTargetScale             == nil then BattlegroundTargets_Options.ButtonTargetScale             = {}    end
	if BattlegroundTargets_Options.ButtonShowTargetCount         == nil then BattlegroundTargets_Options.ButtonShowTargetCount         = {}    end
	if BattlegroundTargets_Options.ButtonShowFocusIndicator      == nil then BattlegroundTargets_Options.ButtonShowFocusIndicator      = {}    end
	if BattlegroundTargets_Options.ButtonFocusScale              == nil then BattlegroundTargets_Options.ButtonFocusScale              = {}    end
	if BattlegroundTargets_Options.ButtonShowHealthBar           == nil then BattlegroundTargets_Options.ButtonShowHealthBar           = {}    end
	if BattlegroundTargets_Options.ButtonShowHealthText          == nil then BattlegroundTargets_Options.ButtonShowHealthText          = {}    end
	if BattlegroundTargets_Options.ButtonSortBySize              == nil then BattlegroundTargets_Options.ButtonSortBySize              = {}    end
	if BattlegroundTargets_Options.ButtonFontSize                == nil then BattlegroundTargets_Options.ButtonFontSize                = {}    end
	if BattlegroundTargets_Options.ButtonScale                   == nil then BattlegroundTargets_Options.ButtonScale                   = {}    end
	if BattlegroundTargets_Options.ButtonWidth                   == nil then BattlegroundTargets_Options.ButtonWidth                   = {}    end
	if BattlegroundTargets_Options.ButtonHeight                  == nil then BattlegroundTargets_Options.ButtonHeight                  = {}    end

	if BattlegroundTargets_Options.ButtonEnableBracket[10]       == nil then BattlegroundTargets_Options.ButtonEnableBracket[10]       = false end
	if BattlegroundTargets_Options.ButtonShowSpec[10]            == nil then BattlegroundTargets_Options.ButtonShowSpec[10]            = false end
	if BattlegroundTargets_Options.ButtonClassIcon[10]           == nil then BattlegroundTargets_Options.ButtonClassIcon[10]           = false end
	if BattlegroundTargets_Options.ButtonShowRealm[10]           == nil then BattlegroundTargets_Options.ButtonShowRealm[10]           = true  end
	if BattlegroundTargets_Options.ButtonShowTargetIndicator[10] == nil then BattlegroundTargets_Options.ButtonShowTargetIndicator[10] = true  end
	if BattlegroundTargets_Options.ButtonTargetScale[10]         == nil then BattlegroundTargets_Options.ButtonTargetScale[10]         = 1.2   end
	if BattlegroundTargets_Options.ButtonShowTargetCount[10]     == nil then BattlegroundTargets_Options.ButtonShowTargetCount[10]     = false end
	if BattlegroundTargets_Options.ButtonShowFocusIndicator[10]  == nil then BattlegroundTargets_Options.ButtonShowFocusIndicator[10]  = true  end
	if BattlegroundTargets_Options.ButtonFocusScale[10]          == nil then BattlegroundTargets_Options.ButtonFocusScale[10]          = 1.2   end
	if BattlegroundTargets_Options.ButtonShowHealthBar[10]       == nil then BattlegroundTargets_Options.ButtonShowHealthBar[10]       = false end
	if BattlegroundTargets_Options.ButtonShowHealthText[10]      == nil then BattlegroundTargets_Options.ButtonShowHealthText[10]      = false end
	if BattlegroundTargets_Options.ButtonSortBySize[10]          == nil then BattlegroundTargets_Options.ButtonSortBySize[10]          = 1     end
	if BattlegroundTargets_Options.ButtonFontSize[10]            == nil then BattlegroundTargets_Options.ButtonFontSize[10]            = 12    end
	if BattlegroundTargets_Options.ButtonScale[10]               == nil then BattlegroundTargets_Options.ButtonScale[10]               = 1     end
	if BattlegroundTargets_Options.ButtonWidth[10]               == nil then BattlegroundTargets_Options.ButtonWidth[10]               = 150   end
	if BattlegroundTargets_Options.ButtonHeight[10]              == nil then BattlegroundTargets_Options.ButtonHeight[10]              = 20    end

	if BattlegroundTargets_Options.ButtonEnableBracket[15]       == nil then BattlegroundTargets_Options.ButtonEnableBracket[15]       = false end
	if BattlegroundTargets_Options.ButtonShowSpec[15]            == nil then BattlegroundTargets_Options.ButtonShowSpec[15]            = false end
	if BattlegroundTargets_Options.ButtonClassIcon[15]           == nil then BattlegroundTargets_Options.ButtonClassIcon[15]           = false end
	if BattlegroundTargets_Options.ButtonShowRealm[15]           == nil then BattlegroundTargets_Options.ButtonShowRealm[15]           = true  end
	if BattlegroundTargets_Options.ButtonShowTargetIndicator[15] == nil then BattlegroundTargets_Options.ButtonShowTargetIndicator[15] = true  end
	if BattlegroundTargets_Options.ButtonTargetScale[15]         == nil then BattlegroundTargets_Options.ButtonTargetScale[15]         = 1.2   end
	if BattlegroundTargets_Options.ButtonShowTargetCount[15]     == nil then BattlegroundTargets_Options.ButtonShowTargetCount[15]     = false end
	if BattlegroundTargets_Options.ButtonShowFocusIndicator[15]  == nil then BattlegroundTargets_Options.ButtonShowFocusIndicator[15]  = true  end
	if BattlegroundTargets_Options.ButtonFocusScale[15]          == nil then BattlegroundTargets_Options.ButtonFocusScale[15]          = 1.2   end
	if BattlegroundTargets_Options.ButtonShowHealthBar[15]       == nil then BattlegroundTargets_Options.ButtonShowHealthBar[15]       = false end
	if BattlegroundTargets_Options.ButtonShowHealthText[15]      == nil then BattlegroundTargets_Options.ButtonShowHealthText[15]      = false end
	if BattlegroundTargets_Options.ButtonSortBySize[15]          == nil then BattlegroundTargets_Options.ButtonSortBySize[15]          = 1     end
	if BattlegroundTargets_Options.ButtonFontSize[15]            == nil then BattlegroundTargets_Options.ButtonFontSize[15]            = 12    end
	if BattlegroundTargets_Options.ButtonScale[15]               == nil then BattlegroundTargets_Options.ButtonScale[15]               = 1     end
	if BattlegroundTargets_Options.ButtonWidth[15]               == nil then BattlegroundTargets_Options.ButtonWidth[15]               = 150   end
	if BattlegroundTargets_Options.ButtonHeight[15]              == nil then BattlegroundTargets_Options.ButtonHeight[15]              = 20    end

	if BattlegroundTargets_Options.ButtonEnableBracket[40]       == nil then BattlegroundTargets_Options.ButtonEnableBracket[40]       = false end
	if BattlegroundTargets_Options.ButtonShowSpec[40]            == nil then BattlegroundTargets_Options.ButtonShowSpec[40]            = false end
	if BattlegroundTargets_Options.ButtonClassIcon[40]           == nil then BattlegroundTargets_Options.ButtonClassIcon[40]           = false end
	if BattlegroundTargets_Options.ButtonShowRealm[40]           == nil then BattlegroundTargets_Options.ButtonShowRealm[40]           = true  end
	if BattlegroundTargets_Options.ButtonShowTargetIndicator[40] == nil then BattlegroundTargets_Options.ButtonShowTargetIndicator[40] = true  end
	if BattlegroundTargets_Options.ButtonTargetScale[40]         == nil then BattlegroundTargets_Options.ButtonTargetScale[40]         = 1.2   end
	if BattlegroundTargets_Options.ButtonShowTargetCount[40]     == nil then BattlegroundTargets_Options.ButtonShowTargetCount[40]     = false end
	if BattlegroundTargets_Options.ButtonShowFocusIndicator[40]  == nil then BattlegroundTargets_Options.ButtonShowFocusIndicator[40]  = false end
	if BattlegroundTargets_Options.ButtonFocusScale[40]          == nil then BattlegroundTargets_Options.ButtonFocusScale[40]          = 1.2   end
	if BattlegroundTargets_Options.ButtonShowHealthBar[40]       == nil then BattlegroundTargets_Options.ButtonShowHealthBar[40]       = false end
	if BattlegroundTargets_Options.ButtonShowHealthText[40]      == nil then BattlegroundTargets_Options.ButtonShowHealthText[40]      = false end
	if BattlegroundTargets_Options.ButtonSortBySize[40]          == nil then BattlegroundTargets_Options.ButtonSortBySize[40]          = 1     end
	if BattlegroundTargets_Options.ButtonFontSize[40]            == nil then BattlegroundTargets_Options.ButtonFontSize[40]            = 10    end
	if BattlegroundTargets_Options.ButtonScale[40]               == nil then BattlegroundTargets_Options.ButtonScale[40]               = 0.9   end
	if BattlegroundTargets_Options.ButtonWidth[40]               == nil then BattlegroundTargets_Options.ButtonWidth[40]               = 80    end
	if BattlegroundTargets_Options.ButtonHeight[40]              == nil then BattlegroundTargets_Options.ButtonHeight[40]              = 16    end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:LDBcheck()
	if LibStub and LibStub:GetLibrary("CallbackHandler-1.0", true) and LibStub:GetLibrary("LibDataBroker-1.1", true) then
		LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("BattlegroundTargets", {
			type = "launcher",
			icon = AddonIcon,
			OnClick = function(self, button)
				BattlegroundTargets:Frame_Toggle(GVAR.OptionsFrame)
			end,
		})
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:CreateInterfaceOptions()
	GVAR.InterfaceOptions = CreateFrame("Frame", "BattlegroundTargets_InterfaceOptions")
	GVAR.InterfaceOptions.name = "BattlegroundTargets"

	GVAR.InterfaceOptions.Title = GVAR.InterfaceOptions:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	GVAR.InterfaceOptions.Title:SetText("BattlegroundTargets")
	GVAR.InterfaceOptions.Title:SetJustifyH("LEFT")
	GVAR.InterfaceOptions.Title:SetJustifyV("TOP")
	GVAR.InterfaceOptions.Title:SetPoint("TOPLEFT", 16, -16)

	GVAR.InterfaceOptions.CONFIG = CreateFrame("Button", nil, GVAR.InterfaceOptions)
	TEMPLATE.TextButton(GVAR.InterfaceOptions.CONFIG, L["Open Configuration"], 1)
	GVAR.InterfaceOptions.CONFIG:SetWidth(180)
	GVAR.InterfaceOptions.CONFIG:SetHeight(22)
	GVAR.InterfaceOptions.CONFIG:SetPoint("TOPLEFT", GVAR.InterfaceOptions.Title, "BOTTOMLEFT", 0, -10)
	GVAR.InterfaceOptions.CONFIG:SetScript("OnClick", function(self)
		InterfaceOptionsFrame_Show()
		HideUIPanel(GameMenuFrame)
		BattlegroundTargets:Frame_Toggle(GVAR.OptionsFrame)
	end)

	GVAR.InterfaceOptions.SlashCommandText = GVAR.InterfaceOptions:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.InterfaceOptions.SlashCommandText:SetText("/bgt - /bgtargets - /battlegroundtargets")
	GVAR.InterfaceOptions.SlashCommandText:SetNonSpaceWrap(true)
	GVAR.InterfaceOptions.SlashCommandText:SetPoint("LEFT", GVAR.InterfaceOptions.CONFIG, "RIGHT", 10, 0)
	GVAR.InterfaceOptions.SlashCommandText:SetTextColor(1, 1, 0.49, 1)

	InterfaceOptions_AddCategory(GVAR.InterfaceOptions)
end
-- ---------------------------------------------------------------------------------------------------------------------



-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:CreateFrames()
	GVAR.MainFrame = CreateFrame("Frame", "BattlegroundTargets_MainFrame", UIParent)
	TEMPLATE.BorderTRBL(GVAR.MainFrame)
	GVAR.MainFrame:EnableMouse(true)
	GVAR.MainFrame:SetMovable(true)
	GVAR.MainFrame:SetResizable(true)
	GVAR.MainFrame:SetToplevel(true)
	GVAR.MainFrame:SetClampedToScreen(true)
	GVAR.MainFrame:SetWidth(150)
	GVAR.MainFrame:SetHeight(20)
	GVAR.MainFrame:SetScript("OnShow", function() BattlegroundTargets:MainFrameShow() end)
	GVAR.MainFrame:SetScript("OnEnter", function() GVAR.MainFrame.Movetext:SetTextColor(1, 1, 1, 1) end)
	GVAR.MainFrame:SetScript("OnLeave", function() GVAR.MainFrame.Movetext:SetTextColor(0.3, 0.3, 0.3, 1) end)
	GVAR.MainFrame:SetScript("OnMouseDown", function()
		if inCombat or InCombatLockdown() then return end
		GVAR.MainFrame:StartMoving()
	end)
	GVAR.MainFrame:SetScript("OnMouseUp", function()
		if inCombat or InCombatLockdown() then return end
		GVAR.MainFrame:StopMovingOrSizing()
		BattlegroundTargets:Frame_SavePosition("BattlegroundTargets_MainFrame")
	end)
	GVAR.MainFrame:Hide()

	GVAR.MainFrame.Movetext = GVAR.MainFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.MainFrame.Movetext:SetWidth(150)
	GVAR.MainFrame.Movetext:SetHeight(20)
	GVAR.MainFrame.Movetext:SetPoint("CENTER", 0, 0)
	GVAR.MainFrame.Movetext:SetJustifyH("CENTER")
	GVAR.MainFrame.Movetext:SetText(L["click & move"])
	GVAR.MainFrame.Movetext:SetTextColor(0.3, 0.3, 0.3, 1)

	local function OnEnter(self)
		self.HighlightBackground:SetTexture(1, 1, 0.49, 1)
	end
	local function OnLeave(self)
		if self.isTarget then
			self.HighlightBackground:SetTexture(0.5, 0.5, 0.5, 1)
		else
			self.HighlightBackground:SetTexture(0, 0, 0, 1)
		end
	end

	GVAR.TargetButton = {}
	for i = 1, 40 do
		GVAR.TargetButton[i] = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
		GVAR.TargetButton[i]:SetWidth(buttonWidth)
		GVAR.TargetButton[i]:SetHeight(buttonHeight)
		if i == 1 then
			GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.MainFrame, "BOTTOMLEFT", 0, 0)
		else
			GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[(i-1)], "BOTTOMLEFT", 0, 0)
		end
		GVAR.TargetButton[i]:Hide()

		GVAR.TargetButton[i].HighlightBackground = GVAR.TargetButton[i]:CreateTexture(nil, "BACKGROUND")
		GVAR.TargetButton[i].HighlightBackground:SetWidth(buttonWidth)
		GVAR.TargetButton[i].HighlightBackground:SetHeight(buttonHeight)
		GVAR.TargetButton[i].HighlightBackground:SetPoint("TOPLEFT", 0, 0)
		GVAR.TargetButton[i].HighlightBackground:SetTexture(0, 0, 0, 1)

		GVAR.TargetButton[i].RoleTextureBackground = GVAR.TargetButton[i]:CreateTexture(nil, "BORDER")
		GVAR.TargetButton[i].RoleTextureBackground:SetWidth((buttonHeight-2)*3)
		GVAR.TargetButton[i].RoleTextureBackground:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].RoleTextureBackground:SetPoint("LEFT", GVAR.TargetButton[i], "LEFT", 1, 0)
		GVAR.TargetButton[i].RoleTextureBackground:SetTexture(0, 0, 0, 1)

		GVAR.TargetButton[i].RoleTexture = GVAR.TargetButton[i]:CreateTexture(nil, "ARTWORK")
		GVAR.TargetButton[i].RoleTexture:SetWidth(buttonHeight-2)
		GVAR.TargetButton[i].RoleTexture:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].RoleTexture:SetPoint("LEFT", GVAR.TargetButton[i], "LEFT", 1, 0)
		GVAR.TargetButton[i].RoleTexture:SetTexture(Textures.BattlegroundTargetsIcons.path)

		GVAR.TargetButton[i].SpecTexture = GVAR.TargetButton[i]:CreateTexture(nil, "ARTWORK")
		GVAR.TargetButton[i].SpecTexture:SetWidth(buttonHeight-2)
		GVAR.TargetButton[i].SpecTexture:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].SpecTexture:SetPoint("LEFT", GVAR.TargetButton[i].RoleTexture, "RIGHT", 0, 0)
		GVAR.TargetButton[i].SpecTexture:SetTexCoord(5/64, 59/64, 5/64, 59/64)

		GVAR.TargetButton[i].ClassTexture = GVAR.TargetButton[i]:CreateTexture(nil, "ARTWORK")
		GVAR.TargetButton[i].ClassTexture:SetWidth(buttonHeight-2)
		GVAR.TargetButton[i].ClassTexture:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].ClassTexture:SetPoint("LEFT", GVAR.TargetButton[i].SpecTexture, "RIGHT", 0, 0)
		GVAR.TargetButton[i].ClassTexture:SetTexture(classimg)

		GVAR.TargetButton[i].ClassColorBackground = GVAR.TargetButton[i]:CreateTexture(nil, "BORDER")
		GVAR.TargetButton[i].ClassColorBackground:SetWidth((buttonWidth-2) - (buttonHeight-2) - (buttonHeight-2))
		GVAR.TargetButton[i].ClassColorBackground:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].ClassColorBackground:SetPoint("LEFT", GVAR.TargetButton[i].ClassTexture, "RIGHT", 0, 0)
		GVAR.TargetButton[i].ClassColorBackground:SetTexture(0.7, 0.7, 0.7, 1)

		GVAR.TargetButton[i].HealthBar = GVAR.TargetButton[i]:CreateTexture(nil, "ARTWORK")
		GVAR.TargetButton[i].HealthBar:SetWidth((buttonWidth-2) - (buttonHeight-2) - (buttonHeight-2))
		GVAR.TargetButton[i].HealthBar:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].HealthBar:SetPoint("LEFT", GVAR.TargetButton[i].ClassColorBackground, "LEFT", 0, 0)
		GVAR.TargetButton[i].HealthBar:SetTexture(0.7, 0.7, 0.7, 1)

		GVAR.TargetButton[i].HealthText = GVAR.TargetButton[i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		GVAR.TargetButton[i].HealthText:SetWidth((buttonWidth-2) - (buttonHeight-2) - (buttonHeight-2) -2)
		GVAR.TargetButton[i].HealthText:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].HealthText:SetPoint("RIGHT", GVAR.TargetButton[i].ClassColorBackground, "RIGHT", 0, 0)
		GVAR.TargetButton[i].HealthText:SetJustifyH("RIGHT")

		GVAR.TargetButton[i].Name = GVAR.TargetButton[i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		GVAR.TargetButton[i].Name:SetWidth((buttonWidth-2) - (buttonHeight-2) - (buttonHeight-2) -2)
		GVAR.TargetButton[i].Name:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].Name:SetPoint("LEFT", GVAR.TargetButton[i].ClassTexture, "RIGHT", 2, 0)
		GVAR.TargetButton[i].Name:SetJustifyH("LEFT")

		GVAR.TargetButton[i].TargetCountBackground = GVAR.TargetButton[i]:CreateTexture(nil, "BORDER")
		GVAR.TargetButton[i].TargetCountBackground:SetWidth(20)
		GVAR.TargetButton[i].TargetCountBackground:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].TargetCountBackground:SetPoint("RIGHT", GVAR.TargetButton[i], "RIGHT", -1, 0)
		GVAR.TargetButton[i].TargetCountBackground:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].TargetCountBackground:SetAlpha(1)

		GVAR.TargetButton[i].TargetCount = GVAR.TargetButton[i]:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		GVAR.TargetButton[i].TargetCount:SetWidth(20)
		GVAR.TargetButton[i].TargetCount:SetHeight(buttonHeight-4)
		GVAR.TargetButton[i].TargetCount:SetPoint("CENTER", GVAR.TargetButton[i].TargetCountBackground, "CENTER", 0, 0)
		GVAR.TargetButton[i].TargetCount:SetJustifyH("CENTER")

		GVAR.TargetButton[i].TargetTexture = GVAR.TargetButton[i]:CreateTexture(nil, "BORDER")
		GVAR.TargetButton[i].TargetTexture:SetWidth(buttonHeight-2)
		GVAR.TargetButton[i].TargetTexture:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].TargetTexture:SetPoint("LEFT", GVAR.TargetButton[i], "RIGHT", 0, 0)
		GVAR.TargetButton[i].TargetTexture:SetTexture(AddonIcon)
		GVAR.TargetButton[i].TargetTexture:SetAlpha(0)

		GVAR.TargetButton[i].FocusTexture = GVAR.TargetButton[i]:CreateTexture(nil, "ARTWORK")
		GVAR.TargetButton[i].FocusTexture:SetWidth(buttonHeight-2)
		GVAR.TargetButton[i].FocusTexture:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].FocusTexture:SetPoint("LEFT", GVAR.TargetButton[i], "RIGHT", 0, 0)
		GVAR.TargetButton[i].FocusTexture:SetTexture("Interface\\Minimap\\Tracking\\Focus")
		GVAR.TargetButton[i].FocusTexture:SetAlpha(0)

		GVAR.TargetButton[i]:RegisterForClicks("AnyUp")
		GVAR.TargetButton[i]:SetAttribute("type1", "macro")
		GVAR.TargetButton[i]:SetAttribute("type2", "macro")
		GVAR.TargetButton[i]:SetAttribute("macrotext1", "")
		GVAR.TargetButton[i]:SetAttribute("macrotext2", "")
		GVAR.TargetButton[i]:SetScript("OnEnter", OnEnter)
		GVAR.TargetButton[i]:SetScript("OnLeave", OnLeave)
	end

	GVAR.WorldStateScoreWarning = CreateFrame("Frame", nil, WorldStateScoreFrame)
	TEMPLATE.BorderTRBL(GVAR.WorldStateScoreWarning)
	GVAR.WorldStateScoreWarning:SetToplevel(true)
	GVAR.WorldStateScoreWarning:SetWidth(400)
	GVAR.WorldStateScoreWarning:SetHeight(60)
	GVAR.WorldStateScoreWarning:SetPoint("BOTTOM", WorldStateScoreFrame, "TOP", 0, 10)
	GVAR.WorldStateScoreWarning:Hide()

	GVAR.WorldStateScoreWarning.Texture1 = GVAR.WorldStateScoreWarning:CreateTexture(nil, "ARTWORK")
	GVAR.WorldStateScoreWarning.Texture1:SetWidth(41)
	GVAR.WorldStateScoreWarning.Texture1:SetHeight(32)
	GVAR.WorldStateScoreWarning.Texture1:SetPoint("LEFT", GVAR.WorldStateScoreWarning, "LEFT", 17, 0)
	GVAR.WorldStateScoreWarning.Texture1:SetTexture("Interface\\DialogFrame\\DialogAlertIcon")
	GVAR.WorldStateScoreWarning.Texture1:SetTexCoord(11/64, 52/64, 16/64, 48/64)

	GVAR.WorldStateScoreWarning.Texture2 = GVAR.WorldStateScoreWarning:CreateTexture(nil, "ARTWORK")
	GVAR.WorldStateScoreWarning.Texture2:SetWidth(41)
	GVAR.WorldStateScoreWarning.Texture2:SetHeight(32)
	GVAR.WorldStateScoreWarning.Texture2:SetPoint("RIGHT", GVAR.WorldStateScoreWarning, "RIGHT", -17, 0)
	GVAR.WorldStateScoreWarning.Texture2:SetTexture("Interface\\DialogFrame\\DialogAlertIcon")
	GVAR.WorldStateScoreWarning.Texture2:SetTexCoord(11/64, 52/64, 16/64, 48/64)

	GVAR.WorldStateScoreWarning.Text = GVAR.WorldStateScoreWarning:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	GVAR.WorldStateScoreWarning.Text:SetWidth(250)
	GVAR.WorldStateScoreWarning.Text:SetHeight(60)
	GVAR.WorldStateScoreWarning.Text:SetPoint("CENTER", 0, 0)
	GVAR.WorldStateScoreWarning.Text:SetJustifyH("CENTER")
	GVAR.WorldStateScoreWarning.Text:SetText(L["BattlegroundTargets does not update if this Tab is opened."])
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:CreateOptionsFrame()
	if BattlegroundTargets_OptionsFrame then return end

	local frameWidth  = 400
	local frameHeight = 601
	local tabWidth = floor( (frameWidth/3)-10 )

	GVAR.OptionsFrame = CreateFrame("Frame", "BattlegroundTargets_OptionsFrame", UIParent)
	TEMPLATE.BorderTRBL(GVAR.OptionsFrame)
	GVAR.OptionsFrame:EnableMouse(true)
	GVAR.OptionsFrame:SetMovable(true)
	GVAR.OptionsFrame:SetToplevel(true)
	GVAR.OptionsFrame:SetClampedToScreen(true)
	GVAR.OptionsFrame:SetClampRectInsets((frameWidth-50)/2, -((frameWidth-50)/2), -(frameHeight-35), frameHeight-35)
	GVAR.OptionsFrame:SetWidth(frameWidth)
	GVAR.OptionsFrame:SetHeight(frameHeight)
	GVAR.OptionsFrame:SetScript("OnShow", function() if not inWorld then return end BattlegroundTargets:OptionsFrameShow() end)
	GVAR.OptionsFrame:SetScript("OnHide", function() if not inWorld then return end BattlegroundTargets:OptionsFrameHide() end)
	GVAR.OptionsFrame:SetScript("OnMouseWheel", NOOP)
	GVAR.OptionsFrame:Hide()

	GVAR.OptionsFrame.Base = CreateFrame("Frame", nil, GVAR.OptionsFrame)
	TEMPLATE.BorderTRBL(GVAR.OptionsFrame.Base)
	GVAR.OptionsFrame.Base:SetWidth(frameWidth)
	GVAR.OptionsFrame.Base:SetHeight(76) -- 8+16+12+12+8+20
	GVAR.OptionsFrame.Base:SetPoint("TOPLEFT", GVAR.OptionsFrame, "TOPLEFT", 0, 0)
	GVAR.OptionsFrame.Base:EnableMouse(true)

	GVAR.OptionsFrame.Title = GVAR.OptionsFrame.Base:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	GVAR.OptionsFrame.Title:SetWidth(frameWidth)
	GVAR.OptionsFrame.Title:SetPoint("TOPLEFT", GVAR.OptionsFrame.Base, "TOPLEFT", 0, -8)
	GVAR.OptionsFrame.Title:SetJustifyH("CENTER")
	GVAR.OptionsFrame.Title:SetText("BattlegroundTargets")

	GVAR.OptionsFrame.TitleWarning = GVAR.OptionsFrame.Base:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	GVAR.OptionsFrame.TitleWarning:SetWidth(frameWidth)
	GVAR.OptionsFrame.TitleWarning:SetPoint("TOP", GVAR.OptionsFrame.Title, "BOTTOM", 0, -12)
	GVAR.OptionsFrame.TitleWarning:SetJustifyH("CENTER")
	GVAR.OptionsFrame.TitleWarning:SetText(L["Out of combat: Configuration enabled."])
	GVAR.OptionsFrame.TitleWarning:SetTextColor(0, 0.75, 0, 1)

	GVAR.OptionsFrame.TitleTexture = GVAR.OptionsFrame.Base:CreateTexture(nil, "ARTWORK")
	GVAR.OptionsFrame.TitleTexture:SetWidth(32)
	GVAR.OptionsFrame.TitleTexture:SetHeight(32)
	GVAR.OptionsFrame.TitleTexture:SetPoint("TOPLEFT", 12, -12)
	GVAR.OptionsFrame.TitleTexture:SetTexture(AddonIcon)

	GVAR.OptionsFrame.TitleTexture2 = GVAR.OptionsFrame.Base:CreateTexture(nil, "ARTWORK")
	GVAR.OptionsFrame.TitleTexture2:SetWidth(32)
	GVAR.OptionsFrame.TitleTexture2:SetHeight(32)
	GVAR.OptionsFrame.TitleTexture2:SetPoint("TOPRIGHT", -12, -12)
	GVAR.OptionsFrame.TitleTexture2:SetTexture(AddonIcon)

	-- - tabs
	local w1 = ( frameWidth-(3*tabWidth)-(2*5) ) / 2

	GVAR.OptionsFrame.TestRaidSize10 = CreateFrame("Button", nil, GVAR.OptionsFrame.Base)
	TEMPLATE.TabButton(GVAR.OptionsFrame.TestRaidSize10, L["10 vs 10"], BattlegroundTargets_Options.ButtonEnableBracket[10])
	GVAR.OptionsFrame.TestRaidSize10:SetWidth(tabWidth)
	GVAR.OptionsFrame.TestRaidSize10:SetHeight(20)
	GVAR.OptionsFrame.TestRaidSize10:SetPoint("BOTTOMLEFT", GVAR.OptionsFrame.Base, "BOTTOMLEFT", w1, -1)
	GVAR.OptionsFrame.TestRaidSize10:SetScript("OnClick", function()
		if testSize == 10 then return end
		testSize = 10
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize10, true)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize15, nil)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize40, nil)
		BattlegroundTargets:CheckForEnabledBracket(testSize)
		if BattlegroundTargets_Options.ButtonEnableBracket[testSize] then
			BattlegroundTargets:EnableConfigMode()
		else
			BattlegroundTargets:DisableConfigMode()
		end
	end)

	GVAR.OptionsFrame.TestRaidSize15 = CreateFrame("Button", nil, GVAR.OptionsFrame.Base)
	TEMPLATE.TabButton(GVAR.OptionsFrame.TestRaidSize15, L["15 vs 15"], BattlegroundTargets_Options.ButtonEnableBracket[15])
	GVAR.OptionsFrame.TestRaidSize15:SetWidth(tabWidth)
	GVAR.OptionsFrame.TestRaidSize15:SetHeight(20)
	GVAR.OptionsFrame.TestRaidSize15:SetPoint("BOTTOMLEFT", GVAR.OptionsFrame.Base, "BOTTOMLEFT", w1+(tabWidth+5), -1)
	GVAR.OptionsFrame.TestRaidSize15:SetScript("OnClick", function()
		if testSize == 15 then return end
		testSize = 15
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize10, nil)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize15, true)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize40, nil)
		BattlegroundTargets:CheckForEnabledBracket(testSize)
		if BattlegroundTargets_Options.ButtonEnableBracket[testSize] then
			BattlegroundTargets:EnableConfigMode()
		else
			BattlegroundTargets:DisableConfigMode()
		end
	end)

	GVAR.OptionsFrame.TestRaidSize40 = CreateFrame("Button", nil, GVAR.OptionsFrame.Base)
	TEMPLATE.TabButton(GVAR.OptionsFrame.TestRaidSize40, L["40 vs 40"], BattlegroundTargets_Options.ButtonEnableBracket[40])
	GVAR.OptionsFrame.TestRaidSize40:SetWidth(tabWidth)
	GVAR.OptionsFrame.TestRaidSize40:SetHeight(20)
	GVAR.OptionsFrame.TestRaidSize40:SetPoint("BOTTOMLEFT", GVAR.OptionsFrame.Base, "BOTTOMLEFT", w1+((tabWidth+5)*2), -1)
	GVAR.OptionsFrame.TestRaidSize40:SetScript("OnClick", function()
		if testSize == 40 then return end
		testSize = 40
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize10, nil)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize15, nil)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize40, true)
		BattlegroundTargets:CheckForEnabledBracket(testSize)
		if BattlegroundTargets_Options.ButtonEnableBracket[testSize] then
			BattlegroundTargets:EnableConfigMode()
		else
			BattlegroundTargets:DisableConfigMode()
		end
	end)

	if testSize == 10 then
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize10, true)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize15, nil)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize40, nil)
	elseif testSize == 15 then
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize10, nil)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize15, true)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize40, nil)
	elseif testSize == 40 then
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize10, nil)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize15, nil)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize40, true)
	end



	-- - enable bracket
	GVAR.OptionsFrame.EnableBracket = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.EnableBracket, 16, 4, L["Enable"])
	GVAR.OptionsFrame.EnableBracket:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.EnableBracket:SetPoint("TOP", GVAR.OptionsFrame.Base, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.EnableBracket:SetChecked(BattlegroundTargets_Options.ButtonEnableBracket[currentSize])
	GVAR.OptionsFrame.EnableBracket:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonEnableBracket[currentSize] = not BattlegroundTargets_Options.ButtonEnableBracket[currentSize]
		GVAR.OptionsFrame.EnableBracket:SetChecked(BattlegroundTargets_Options.ButtonEnableBracket[currentSize])

		BattlegroundTargets:CheckForEnabledBracket(currentSize)

		if BattlegroundTargets_Options.ButtonEnableBracket[currentSize] then
			BattlegroundTargets:EnableConfigMode()
		else
			BattlegroundTargets:DisableConfigMode()
		end
	end)

	-- - independent positioning
	GVAR.OptionsFrame.IndependentPos = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.IndependentPos, 16, 4, L["Independent Positioning"])
	GVAR.OptionsFrame.IndependentPos:SetPoint("LEFT", GVAR.OptionsFrame.EnableBracket.Text, "RIGHT", 50, 0)
	GVAR.OptionsFrame.IndependentPos:SetChecked(BattlegroundTargets_Options.IndependentPositioning[currentSize])
	GVAR.OptionsFrame.IndependentPos:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.IndependentPositioning[currentSize] = not BattlegroundTargets_Options.IndependentPositioning[currentSize]
		GVAR.OptionsFrame.IndependentPos:SetChecked(BattlegroundTargets_Options.IndependentPositioning[currentSize])
		if not BattlegroundTargets_Options.IndependentPositioning[currentSize] then
			BattlegroundTargets_Options.pos["BattlegroundTargets_MainFrame"..currentSize.."_posX"] = nil
			BattlegroundTargets_Options.pos["BattlegroundTargets_MainFrame"..currentSize.."_posY"] = nil
			if inCombat or InCombatLockdown() then
				reCheckBG = true
				return
			end
			BattlegroundTargets:Frame_SetupPosition("BattlegroundTargets_MainFrame")
		end
	end)

	-- - show spec
	GVAR.OptionsFrame.ShowSpec = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowSpec, 16, 4, L["Show Specialization"])
	GVAR.OptionsFrame.ShowSpec:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ShowSpec:SetPoint("TOP", GVAR.OptionsFrame.EnableBracket, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ShowSpec:SetChecked(BattlegroundTargets_Options.ButtonShowSpec[currentSize])
	GVAR.OptionsFrame.ShowSpec:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowSpec[currentSize] = not BattlegroundTargets_Options.ButtonShowSpec[currentSize]
		GVAR.OptionsFrame.ShowSpec:SetChecked(BattlegroundTargets_Options.ButtonShowSpec[currentSize])
		BattlegroundTargets:EnableConfigMode()
	end)

	-- - class icon
	GVAR.OptionsFrame.ClassIcon = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ClassIcon, 16, 4, L["Show Class Icon"])
	GVAR.OptionsFrame.ClassIcon:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ClassIcon:SetPoint("TOP", GVAR.OptionsFrame.ShowSpec, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ClassIcon:SetChecked(BattlegroundTargets_Options.ButtonClassIcon[currentSize])
	GVAR.OptionsFrame.ClassIcon:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonClassIcon[currentSize] = not BattlegroundTargets_Options.ButtonClassIcon[currentSize]
		GVAR.OptionsFrame.ClassIcon:SetChecked(BattlegroundTargets_Options.ButtonClassIcon[currentSize])
		BattlegroundTargets:EnableConfigMode()
	end)

	-- - show realm
	GVAR.OptionsFrame.ShowRealm = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowRealm, 16, 4, L["Show Realm"])
	GVAR.OptionsFrame.ShowRealm:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ShowRealm:SetPoint("TOP", GVAR.OptionsFrame.ClassIcon, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ShowRealm:SetChecked(BattlegroundTargets_Options.ButtonShowRealm[currentSize])
	GVAR.OptionsFrame.ShowRealm:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowRealm[currentSize] = not BattlegroundTargets_Options.ButtonShowRealm[currentSize]
		GVAR.OptionsFrame.ShowRealm:SetChecked(BattlegroundTargets_Options.ButtonShowRealm[currentSize])
		BattlegroundTargets:EnableConfigMode()
	end)

	-- - show target indicator
	GVAR.OptionsFrame.ShowTargetIndicator = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowTargetIndicator, 16, 4, L["Show Target Indicator"])
	GVAR.OptionsFrame.ShowTargetIndicator:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ShowTargetIndicator:SetPoint("TOP", GVAR.OptionsFrame.ShowRealm, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ShowTargetIndicator:SetChecked(BattlegroundTargets_Options.ButtonShowTargetIndicator[currentSize])
	GVAR.OptionsFrame.ShowTargetIndicator:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowTargetIndicator[currentSize] = not BattlegroundTargets_Options.ButtonShowTargetIndicator[currentSize]
		GVAR.OptionsFrame.ShowTargetIndicator:SetChecked(BattlegroundTargets_Options.ButtonShowTargetIndicator[currentSize])

		if BattlegroundTargets_Options.ButtonShowTargetIndicator[currentSize] then
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.TargetScaleSlider)
		else
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.TargetScaleSlider)
		end

		BattlegroundTargets:EnableConfigMode()
	end)

	-- - target indicator scale
	GVAR.OptionsFrame.TargetScaleSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.TargetScaleSliderText = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")

	TEMPLATE.Slider(GVAR.OptionsFrame.TargetScaleSlider, 80, 10, 100, 200, BattlegroundTargets_Options.ButtonTargetScale[currentSize]*100,
	function(self, value)
		BattlegroundTargets_Options.ButtonTargetScale[currentSize] = value/100
		GVAR.OptionsFrame.TargetScaleSliderText:SetText((BattlegroundTargets_Options.ButtonTargetScale[currentSize]*100).."%")
		BattlegroundTargets:EnableConfigMode()
	end,
	"blank")
	GVAR.OptionsFrame.TargetScaleSlider:SetPoint("LEFT", GVAR.OptionsFrame.ShowTargetIndicator, "RIGHT", 20, 0)

	GVAR.OptionsFrame.TargetScaleSliderText:SetHeight(20)
	GVAR.OptionsFrame.TargetScaleSliderText:SetPoint("LEFT", GVAR.OptionsFrame.TargetScaleSlider, "RIGHT", 5, 0)
	GVAR.OptionsFrame.TargetScaleSliderText:SetJustifyH("LEFT")
	GVAR.OptionsFrame.TargetScaleSliderText:SetText((BattlegroundTargets_Options.ButtonTargetScale[currentSize]*100).."%")
	GVAR.OptionsFrame.TargetScaleSliderText:SetTextColor(1, 1, 0.49, 1)

	-- - show targetcount
	GVAR.OptionsFrame.ShowTargetCount = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowTargetCount, 16, 4, L["Show Target Count"])
	GVAR.OptionsFrame.ShowTargetCount:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ShowTargetCount:SetPoint("TOP", GVAR.OptionsFrame.ShowTargetIndicator, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ShowTargetCount:SetChecked(BattlegroundTargets_Options.ButtonShowTargetCount[currentSize])
	GVAR.OptionsFrame.ShowTargetCount:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowTargetCount[currentSize] = not BattlegroundTargets_Options.ButtonShowTargetCount[currentSize]
		GVAR.OptionsFrame.ShowTargetCount:SetChecked(BattlegroundTargets_Options.ButtonShowTargetCount[currentSize])
		BattlegroundTargets:EnableConfigMode()
	end)

	-- - show focus indicator
	GVAR.OptionsFrame.ShowFocusIndicator = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowFocusIndicator, 16, 4, L["Show Focus Indicator"])
	GVAR.OptionsFrame.ShowFocusIndicator:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ShowFocusIndicator:SetPoint("TOP", GVAR.OptionsFrame.ShowTargetCount, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ShowFocusIndicator:SetChecked(BattlegroundTargets_Options.ButtonShowFocusIndicator[currentSize])
	GVAR.OptionsFrame.ShowFocusIndicator:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowFocusIndicator[currentSize] = not BattlegroundTargets_Options.ButtonShowFocusIndicator[currentSize]
		GVAR.OptionsFrame.ShowFocusIndicator:SetChecked(BattlegroundTargets_Options.ButtonShowFocusIndicator[currentSize])

		if BattlegroundTargets_Options.ButtonShowFocusIndicator[currentSize] then
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.FocusScaleSlider)
		else
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.FocusScaleSlider)
		end

		BattlegroundTargets:EnableConfigMode()
	end)

	-- - focus indicator scale
	GVAR.OptionsFrame.FocusScaleSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.FocusScaleSliderText = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")

	TEMPLATE.Slider(GVAR.OptionsFrame.FocusScaleSlider, 80, 10, 100, 200, BattlegroundTargets_Options.ButtonFocusScale[currentSize]*100,
	function(self, value)
		BattlegroundTargets_Options.ButtonFocusScale[currentSize] = value/100
		GVAR.OptionsFrame.FocusScaleSliderText:SetText((BattlegroundTargets_Options.ButtonFocusScale[currentSize]*100).."%")
		BattlegroundTargets:EnableConfigMode()
	end,
	"blank")
	GVAR.OptionsFrame.FocusScaleSlider:SetPoint("LEFT", GVAR.OptionsFrame.ShowFocusIndicator, "RIGHT", 20, 0)

	GVAR.OptionsFrame.FocusScaleSliderText:SetHeight(20)
	GVAR.OptionsFrame.FocusScaleSliderText:SetPoint("LEFT", GVAR.OptionsFrame.FocusScaleSlider, "RIGHT", 5, 0)
	GVAR.OptionsFrame.FocusScaleSliderText:SetJustifyH("LEFT")
	GVAR.OptionsFrame.FocusScaleSliderText:SetText((BattlegroundTargets_Options.ButtonFocusScale[currentSize]*100).."%")
	GVAR.OptionsFrame.FocusScaleSliderText:SetTextColor(1, 1, 0.49, 1)

	-- - show healt bar
	GVAR.OptionsFrame.ShowHealthBar = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowHealthBar, 16, 4, L["Show Health Bar"])
	GVAR.OptionsFrame.ShowHealthBar:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ShowHealthBar:SetPoint("TOP", GVAR.OptionsFrame.ShowFocusIndicator, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ShowHealthBar:SetChecked(BattlegroundTargets_Options.ButtonShowHealthBar[currentSize])
	GVAR.OptionsFrame.ShowHealthBar:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowHealthBar[currentSize] = not BattlegroundTargets_Options.ButtonShowHealthBar[currentSize]
		GVAR.OptionsFrame.ShowHealthBar:SetChecked(BattlegroundTargets_Options.ButtonShowHealthBar[currentSize])

		if BattlegroundTargets_Options.ButtonShowHealthBar[currentSize] then
			TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowHealthText)
		else
			TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowHealthText)
		end

		BattlegroundTargets:EnableConfigMode()
	end)

	-- - show healt text
	GVAR.OptionsFrame.ShowHealthText = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowHealthText, 16, 4, L["Show Percent"])
	GVAR.OptionsFrame.ShowHealthText:SetPoint("LEFT", GVAR.OptionsFrame.ShowHealthBar.Text, "RIGHT", 20, 0)
	GVAR.OptionsFrame.ShowHealthText:SetChecked(BattlegroundTargets_Options.ButtonShowHealthText[currentSize])
	GVAR.OptionsFrame.ShowHealthText:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowHealthText[currentSize] = not BattlegroundTargets_Options.ButtonShowHealthText[currentSize]
		GVAR.OptionsFrame.ShowHealthText:SetChecked(BattlegroundTargets_Options.ButtonShowHealthText[currentSize])
		BattlegroundTargets:EnableConfigMode()
	end)

	-- - sort by
	GVAR.OptionsFrame.SortByTitle = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.SortByTitle:SetHeight(20)
	GVAR.OptionsFrame.SortByTitle:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.SortByTitle:SetPoint("TOP", GVAR.OptionsFrame.ShowHealthBar, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.SortByTitle:SetJustifyH("LEFT")
	GVAR.OptionsFrame.SortByTitle:SetText(L["Sort By"]..":")
	GVAR.OptionsFrame.SortByTitle:SetTextColor(1, 1, 1, 1)

	GVAR.OptionsFrame.SortByTitlePullDown = CreateFrame("Button", nil, GVAR.OptionsFrame)
	TEMPLATE.PullDownMenu(GVAR.OptionsFrame.SortByTitlePullDown, "SortBy", sortBy[ BattlegroundTargets_Options.ButtonSortBySize[currentSize] ], 0, #sortBy, SortByTitlePullDownFunc)
	GVAR.OptionsFrame.SortByTitlePullDown:SetPoint("LEFT", GVAR.OptionsFrame.SortByTitle, "RIGHT", 10, 0)
	GVAR.OptionsFrame.SortByTitlePullDown:SetHeight(18)
	TEMPLATE.EnablePullDownMenu(GVAR.OptionsFrame.SortByTitlePullDown)

	-- - fontsize
	GVAR.OptionsFrame.FontTitle = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.FontTitle:SetHeight(20)
	GVAR.OptionsFrame.FontTitle:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.FontTitle:SetPoint("TOP", GVAR.OptionsFrame.SortByTitle, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.FontTitle:SetJustifyH("LEFT")
	GVAR.OptionsFrame.FontTitle:SetText(L["Text Size"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonFontSize[currentSize]).."|r")
	GVAR.OptionsFrame.FontTitle:SetTextColor(1, 1, 1, 1)

	GVAR.OptionsFrame.FontSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	TEMPLATE.Slider(GVAR.OptionsFrame.FontSlider, 150, 1, 5, 20, BattlegroundTargets_Options.ButtonFontSize[currentSize],
	function(self, value)
		BattlegroundTargets_Options.ButtonFontSize[currentSize] = value
		GVAR.OptionsFrame.FontTitle:SetText(L["Text Size"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonFontSize[currentSize]).."|r")
		BattlegroundTargets:EnableConfigMode()
	end,
	nil)
	GVAR.OptionsFrame.FontSlider:SetPoint("LEFT", GVAR.OptionsFrame.FontTitle, "LEFT", 0, 0)
	GVAR.OptionsFrame.FontSlider:SetPoint("TOP", GVAR.OptionsFrame.FontTitle, "BOTTOM", 0, 5)

	-- - scale
	GVAR.OptionsFrame.ScaleTitle = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.ScaleTitle:SetHeight(20)
	GVAR.OptionsFrame.ScaleTitle:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ScaleTitle:SetPoint("TOP", GVAR.OptionsFrame.FontSlider, "BOTTOM", 0, -20)
	GVAR.OptionsFrame.ScaleTitle:SetJustifyH("LEFT")
	GVAR.OptionsFrame.ScaleTitle:SetText(L["Scale"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonScale[currentSize]*100).."%|r")
	GVAR.OptionsFrame.ScaleTitle:SetTextColor(1, 1, 1, 1)

	GVAR.OptionsFrame.ScaleSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	TEMPLATE.Slider(GVAR.OptionsFrame.ScaleSlider, 180, 5, 50, 200, BattlegroundTargets_Options.ButtonScale[currentSize]*100,
	function(self, value)
		BattlegroundTargets_Options.ButtonScale[currentSize] = value/100
		GVAR.OptionsFrame.ScaleTitle:SetText(L["Scale"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonScale[currentSize]*100).."%|r")
		BattlegroundTargets:EnableConfigMode()
	end,
	"%")
	GVAR.OptionsFrame.ScaleSlider:SetPoint("LEFT", GVAR.OptionsFrame.ScaleTitle, "LEFT", 0, 0)
	GVAR.OptionsFrame.ScaleSlider:SetPoint("TOP", GVAR.OptionsFrame.ScaleTitle, "BOTTOM", 0, 5)

	-- - width
	GVAR.OptionsFrame.WidthTitle = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.WidthTitle:SetHeight(20)
	GVAR.OptionsFrame.WidthTitle:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.WidthTitle:SetPoint("TOP", GVAR.OptionsFrame.ScaleSlider, "BOTTOM", 0, -20)
	GVAR.OptionsFrame.WidthTitle:SetJustifyH("LEFT")
	GVAR.OptionsFrame.WidthTitle:SetText(L["Width"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonWidth[currentSize]).."px|r")
	GVAR.OptionsFrame.WidthTitle:SetTextColor(1, 1, 1, 1)

	GVAR.OptionsFrame.WidthSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	TEMPLATE.Slider(GVAR.OptionsFrame.WidthSlider, 180, 5, 50, 300, BattlegroundTargets_Options.ButtonWidth[currentSize],
	function(self, value)
		BattlegroundTargets_Options.ButtonWidth[currentSize] = value
		GVAR.OptionsFrame.WidthTitle:SetText(L["Width"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonWidth[currentSize]).."px|r")
		BattlegroundTargets:EnableConfigMode()
	end,
	"px")
	GVAR.OptionsFrame.WidthSlider:SetPoint("LEFT", GVAR.OptionsFrame.WidthTitle, "LEFT", 0, 0)
	GVAR.OptionsFrame.WidthSlider:SetPoint("TOP", GVAR.OptionsFrame.WidthTitle, "BOTTOM", 0, 5)

	-- - height
	GVAR.OptionsFrame.HeightTitle = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.HeightTitle:SetHeight(20)
	GVAR.OptionsFrame.HeightTitle:SetPoint("LEFT", GVAR.OptionsFrame.WidthSlider, "RIGHT", 20, 0)
	GVAR.OptionsFrame.HeightTitle:SetPoint("TOP", GVAR.OptionsFrame.WidthTitle, "TOP", 0, 0)
	GVAR.OptionsFrame.HeightTitle:SetJustifyH("LEFT")
	GVAR.OptionsFrame.HeightTitle:SetText(L["Height"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonHeight[currentSize]).."px|r")
	GVAR.OptionsFrame.HeightTitle:SetTextColor(1, 1, 1, 1)

	GVAR.OptionsFrame.HeightSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	TEMPLATE.Slider(GVAR.OptionsFrame.HeightSlider, 180, 1, 10, 25, BattlegroundTargets_Options.ButtonHeight[currentSize],
	function(self, value)
		BattlegroundTargets_Options.ButtonHeight[currentSize] = value
		GVAR.OptionsFrame.HeightTitle:SetText(L["Height"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonHeight[currentSize]).."px|r")
		BattlegroundTargets:EnableConfigMode()
	end,
	"px")
	GVAR.OptionsFrame.HeightSlider:SetPoint("LEFT", GVAR.OptionsFrame.HeightTitle, "LEFT", 0, 0)
	GVAR.OptionsFrame.HeightSlider:SetPoint("TOP", GVAR.OptionsFrame.HeightTitle, "BOTTOM", 0, 5)



	GVAR.OptionsFrame.Dummy = CreateFrame("Frame", nil, GVAR.OptionsFrame)
	TEMPLATE.BorderTRBL(GVAR.OptionsFrame.Dummy)
	GVAR.OptionsFrame.Dummy:SetWidth(frameWidth)
	GVAR.OptionsFrame.Dummy:SetHeight(1)
	GVAR.OptionsFrame.Dummy:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 0, 0)
	GVAR.OptionsFrame.Dummy:SetPoint("TOP", GVAR.OptionsFrame.HeightSlider.textMin, "BOTTOM", 0, -10)

	GVAR.OptionsFrame.General = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	GVAR.OptionsFrame.General:SetHeight(20)
	GVAR.OptionsFrame.General:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.General:SetPoint("TOP", GVAR.OptionsFrame.Dummy, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.General:SetJustifyH("LEFT")
	GVAR.OptionsFrame.General:SetText(L["General Settings"]..":")

	-- - minimap button
	GVAR.OptionsFrame.Minimap = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.Minimap, 16, 4, L["Show Minimap-Button"])
	GVAR.OptionsFrame.Minimap:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.Minimap:SetPoint("TOP", GVAR.OptionsFrame.General, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.Minimap:SetChecked(BattlegroundTargets_Options.MinimapButton)
	TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.Minimap)
	GVAR.OptionsFrame.Minimap:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.MinimapButton = not BattlegroundTargets_Options.MinimapButton
		BattlegroundTargets:CreateMinimapButton()
	end)

	-- - close
	GVAR.OptionsFrame.CloseConfig = CreateFrame("Button", nil, GVAR.OptionsFrame)
	TEMPLATE.TextButton(GVAR.OptionsFrame.CloseConfig, L["Close Configuration"], 1)
	GVAR.OptionsFrame.CloseConfig:SetPoint("BOTTOM", GVAR.OptionsFrame, "BOTTOM", 0, 10)
	GVAR.OptionsFrame.CloseConfig:SetWidth(frameWidth-20)
	GVAR.OptionsFrame.CloseConfig:SetHeight(30)
	GVAR.OptionsFrame.CloseConfig:SetScript("OnClick", function() GVAR.OptionsFrame:Hide() end)



	-- Mover
	GVAR.OptionsFrame.MoverTop = CreateFrame("Frame", nil, GVAR.OptionsFrame)
	TEMPLATE.BorderTRBL(GVAR.OptionsFrame.MoverTop)
	GVAR.OptionsFrame.MoverTop:SetWidth(frameWidth)
	GVAR.OptionsFrame.MoverTop:SetHeight(20)
	GVAR.OptionsFrame.MoverTop:SetPoint("BOTTOM", GVAR.OptionsFrame, "TOP", 0, -1)
	GVAR.OptionsFrame.MoverTop:EnableMouse(true)
	GVAR.OptionsFrame.MoverTop:EnableMouseWheel(true)
	GVAR.OptionsFrame.MoverTop:SetScript("OnMouseWheel", NOOP)
	GVAR.OptionsFrame.MoverTopText = GVAR.OptionsFrame.MoverTop:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.MoverTopText:SetPoint("CENTER", GVAR.OptionsFrame.MoverTop, "CENTER", 0, 0)
	GVAR.OptionsFrame.MoverTopText:SetJustifyH("CENTER")
	GVAR.OptionsFrame.MoverTopText:SetTextColor(0.3, 0.3, 0.3, 1)
	GVAR.OptionsFrame.MoverTopText:SetText(L["click & move"])

	GVAR.OptionsFrame.Close = CreateFrame("Button", nil, GVAR.OptionsFrame.MoverTop)
	TEMPLATE.IconButton(GVAR.OptionsFrame.Close, 1)
	GVAR.OptionsFrame.Close:SetWidth(20)
	GVAR.OptionsFrame.Close:SetHeight(20)
	GVAR.OptionsFrame.Close:SetPoint("RIGHT", GVAR.OptionsFrame.MoverTop, "RIGHT", 0, 0)
	GVAR.OptionsFrame.Close:SetScript("OnClick", function() GVAR.OptionsFrame:Hide() end)

	GVAR.OptionsFrame.MoverBottom = CreateFrame("Frame", nil, GVAR.OptionsFrame)
	TEMPLATE.BorderTRBL(GVAR.OptionsFrame.MoverBottom)
	GVAR.OptionsFrame.MoverBottom:SetWidth(frameWidth)
	GVAR.OptionsFrame.MoverBottom:SetHeight(20)
	GVAR.OptionsFrame.MoverBottom:SetPoint("TOP", GVAR.OptionsFrame, "BOTTOM", 0, 1)
	GVAR.OptionsFrame.MoverBottom:EnableMouse(true)
	GVAR.OptionsFrame.MoverBottom:EnableMouseWheel(true)
	GVAR.OptionsFrame.MoverBottom:SetScript("OnMouseWheel", NOOP)
	GVAR.OptionsFrame.MoverBottomText = GVAR.OptionsFrame.MoverBottom:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.MoverBottomText:SetPoint("CENTER", GVAR.OptionsFrame.MoverBottom, "CENTER", 0, 0)
	GVAR.OptionsFrame.MoverBottomText:SetJustifyH("CENTER")
	GVAR.OptionsFrame.MoverBottomText:SetTextColor(0.3, 0.3, 0.3, 1)
	GVAR.OptionsFrame.MoverBottomText:SetText(L["click & move"])

	GVAR.OptionsFrame.MoverTop:SetScript("OnEnter", function() GVAR.OptionsFrame.MoverTopText:SetTextColor(1, 1, 1, 1) end)
	GVAR.OptionsFrame.MoverTop:SetScript("OnLeave", function() GVAR.OptionsFrame.MoverTopText:SetTextColor(0.3, 0.3, 0.3, 1) end)
	GVAR.OptionsFrame.MoverTop:SetScript("OnMouseDown", function() GVAR.OptionsFrame:StartMoving() end)
	GVAR.OptionsFrame.MoverTop:SetScript("OnMouseUp", function() GVAR.OptionsFrame:StopMovingOrSizing() BattlegroundTargets:Frame_SavePosition("BattlegroundTargets_OptionsFrame") end)

	GVAR.OptionsFrame.MoverBottom:SetScript("OnEnter", function() GVAR.OptionsFrame.MoverBottomText:SetTextColor(1, 1, 1, 1) end)
	GVAR.OptionsFrame.MoverBottom:SetScript("OnLeave", function() GVAR.OptionsFrame.MoverBottomText:SetTextColor(0.3, 0.3, 0.3, 1) end)
	GVAR.OptionsFrame.MoverBottom:SetScript("OnMouseDown", function() GVAR.OptionsFrame:StartMoving() end)
	GVAR.OptionsFrame.MoverBottom:SetScript("OnMouseUp", function() GVAR.OptionsFrame:StopMovingOrSizing() BattlegroundTargets:Frame_SavePosition("BattlegroundTargets_OptionsFrame") end)
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:SetOptions()
	GVAR.OptionsFrame.EnableBracket:SetChecked(BattlegroundTargets_Options.ButtonEnableBracket[currentSize])
	GVAR.OptionsFrame.IndependentPos:SetChecked(BattlegroundTargets_Options.IndependentPositioning[currentSize])

	GVAR.OptionsFrame.ShowSpec:SetChecked(BattlegroundTargets_Options.ButtonShowSpec[currentSize])
	GVAR.OptionsFrame.ClassIcon:SetChecked(BattlegroundTargets_Options.ButtonClassIcon[currentSize])
	GVAR.OptionsFrame.ShowRealm:SetChecked(BattlegroundTargets_Options.ButtonShowRealm[currentSize])

	GVAR.OptionsFrame.ShowTargetIndicator:SetChecked(BattlegroundTargets_Options.ButtonShowTargetIndicator[currentSize])
	GVAR.OptionsFrame.TargetScaleSlider:SetValue(BattlegroundTargets_Options.ButtonTargetScale[currentSize]*100)
	GVAR.OptionsFrame.TargetScaleSliderText:SetText((BattlegroundTargets_Options.ButtonTargetScale[currentSize]*100).."%")

	GVAR.OptionsFrame.ShowTargetCount:SetChecked(BattlegroundTargets_Options.ButtonShowTargetCount[currentSize])

	GVAR.OptionsFrame.ShowFocusIndicator:SetChecked(BattlegroundTargets_Options.ButtonShowFocusIndicator[currentSize])
	GVAR.OptionsFrame.FocusScaleSlider:SetValue(BattlegroundTargets_Options.ButtonFocusScale[currentSize]*100)
	GVAR.OptionsFrame.FocusScaleSliderText:SetText((BattlegroundTargets_Options.ButtonFocusScale[currentSize]*100).."%")

	GVAR.OptionsFrame.ShowHealthBar:SetChecked(BattlegroundTargets_Options.ButtonShowHealthBar[currentSize])
	GVAR.OptionsFrame.ShowHealthText:SetChecked(BattlegroundTargets_Options.ButtonShowHealthText[currentSize])

	GVAR.OptionsFrame.SortByTitlePullDown.PullDownButtonText:SetText(sortBy[ BattlegroundTargets_Options.ButtonSortBySize[currentSize] ])

	GVAR.OptionsFrame.FontSlider:SetValue(BattlegroundTargets_Options.ButtonFontSize[currentSize])
	GVAR.OptionsFrame.FontTitle:SetText(L["Text Size"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonFontSize[currentSize]).."|r")

	GVAR.OptionsFrame.ScaleSlider:SetValue(BattlegroundTargets_Options.ButtonScale[currentSize]*100)
	GVAR.OptionsFrame.ScaleTitle:SetText(L["Scale"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonScale[currentSize]*100).."%|r")

	GVAR.OptionsFrame.WidthSlider:SetValue(BattlegroundTargets_Options.ButtonWidth[currentSize])
	GVAR.OptionsFrame.WidthTitle:SetText(L["Width"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonWidth[currentSize]).."px|r")

	GVAR.OptionsFrame.HeightSlider:SetValue(BattlegroundTargets_Options.ButtonHeight[currentSize])
	GVAR.OptionsFrame.HeightTitle:SetText(L["Height"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonHeight[currentSize]).."px|r")
end

function BattlegroundTargets:CheckForEnabledBracket(bracketSize)
	if BattlegroundTargets_Options.ButtonEnableBracket[bracketSize] then
		if bracketSize == 10 then
			GVAR.OptionsFrame.TestRaidSize10.Text:SetTextColor(0, 0.75, 0, 1)
		elseif bracketSize == 15 then
			GVAR.OptionsFrame.TestRaidSize15.Text:SetTextColor(0, 0.75, 0, 1)
		elseif bracketSize == 40 then
			GVAR.OptionsFrame.TestRaidSize40.Text:SetTextColor(0, 0.75, 0, 1)
		end

		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.IndependentPos)

		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowSpec)
		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ClassIcon)
		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowRealm)

		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowTargetIndicator)
		if BattlegroundTargets_Options.ButtonShowTargetIndicator[bracketSize] then
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.TargetScaleSlider)
		else
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.TargetScaleSlider)
		end

		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowTargetCount)

		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowFocusIndicator)
		if BattlegroundTargets_Options.ButtonShowFocusIndicator[bracketSize] then
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.FocusScaleSlider)
		else
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.FocusScaleSlider)
		end

		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowHealthBar)
		if BattlegroundTargets_Options.ButtonShowHealthBar[bracketSize] then
			TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowHealthText)
		else
			TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowHealthText)
		end

		TEMPLATE.EnablePullDownMenu(GVAR.OptionsFrame.SortByTitlePullDown)
		GVAR.OptionsFrame.SortByTitle:SetTextColor(1, 1, 1, 1)

		TEMPLATE.EnableSlider(GVAR.OptionsFrame.FontSlider)
		GVAR.OptionsFrame.FontTitle:SetTextColor(1, 1, 1, 1)
		TEMPLATE.EnableSlider(GVAR.OptionsFrame.ScaleSlider)
		GVAR.OptionsFrame.ScaleTitle:SetTextColor(1, 1, 1, 1)
		TEMPLATE.EnableSlider(GVAR.OptionsFrame.WidthSlider)
		GVAR.OptionsFrame.WidthTitle:SetTextColor(1, 1, 1, 1)
		TEMPLATE.EnableSlider(GVAR.OptionsFrame.HeightSlider)
		GVAR.OptionsFrame.HeightTitle:SetTextColor(1, 1, 1, 1)
	else
		if bracketSize == 10 then
			GVAR.OptionsFrame.TestRaidSize10.Text:SetTextColor(1, 0, 0, 1)
		elseif bracketSize == 15 then
			GVAR.OptionsFrame.TestRaidSize15.Text:SetTextColor(1, 0, 0, 1)
		elseif bracketSize == 40 then
			GVAR.OptionsFrame.TestRaidSize40.Text:SetTextColor(1, 0, 0, 1)
		end

		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.IndependentPos)

		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowSpec)
		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ClassIcon)
		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowRealm)
		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowTargetIndicator)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.TargetScaleSlider)
		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowTargetCount)
		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowFocusIndicator)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.FocusScaleSlider)
		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowHealthBar)
		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowHealthText)

		TEMPLATE.DisablePullDownMenu(GVAR.OptionsFrame.SortByTitlePullDown)
		GVAR.OptionsFrame.SortByTitle:SetTextColor(0.5, 0.5, 0.5, 1)

		TEMPLATE.DisableSlider(GVAR.OptionsFrame.FontSlider)
		GVAR.OptionsFrame.FontTitle:SetTextColor(0.5, 0.5, 0.5, 1)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.ScaleSlider)
		GVAR.OptionsFrame.ScaleTitle:SetTextColor(0.5, 0.5, 0.5, 1)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.WidthSlider)
		GVAR.OptionsFrame.WidthTitle:SetTextColor(0.5, 0.5, 0.5, 1)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.HeightSlider)
		GVAR.OptionsFrame.HeightTitle:SetTextColor(0.5, 0.5, 0.5, 1)
	end
end

function BattlegroundTargets:DisableInsecureConfigWidges()
	GVAR.OptionsFrame.TitleWarning:SetText(L["In combat: Configuration locked!"])
	GVAR.OptionsFrame.TitleWarning:SetTextColor(0.8, 0.2, 0.2, 1)

	TEMPLATE.DisableTabButton(GVAR.OptionsFrame.TestRaidSize10)
	TEMPLATE.DisableTabButton(GVAR.OptionsFrame.TestRaidSize15)
	TEMPLATE.DisableTabButton(GVAR.OptionsFrame.TestRaidSize40)

	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.EnableBracket)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.IndependentPos)

	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowSpec)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ClassIcon)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowRealm)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowTargetIndicator)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.TargetScaleSlider)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowTargetCount)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowFocusIndicator)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.FocusScaleSlider)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowHealthBar)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowHealthText)

	TEMPLATE.DisablePullDownMenu(GVAR.OptionsFrame.SortByTitlePullDown)
	GVAR.OptionsFrame.SortByTitle:SetTextColor(0.5, 0.5, 0.5, 1)

	TEMPLATE.DisableSlider(GVAR.OptionsFrame.FontSlider)
	GVAR.OptionsFrame.FontTitle:SetTextColor(0.5, 0.5, 0.5, 1)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.ScaleSlider)
	GVAR.OptionsFrame.ScaleTitle:SetTextColor(0.5, 0.5, 0.5, 1)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.WidthSlider)
	GVAR.OptionsFrame.WidthTitle:SetTextColor(0.5, 0.5, 0.5, 1)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.HeightSlider)
	GVAR.OptionsFrame.HeightTitle:SetTextColor(0.5, 0.5, 0.5, 1)
end

function BattlegroundTargets:EnableInsecureConfigWidges()
	GVAR.OptionsFrame.TitleWarning:SetText(L["Out of combat: Configuration enabled."])
	GVAR.OptionsFrame.TitleWarning:SetTextColor(0, 0.75, 0, 1)

	TEMPLATE.EnableTabButton(GVAR.OptionsFrame.TestRaidSize10, BattlegroundTargets_Options.ButtonEnableBracket[10])
	TEMPLATE.EnableTabButton(GVAR.OptionsFrame.TestRaidSize15, BattlegroundTargets_Options.ButtonEnableBracket[15])
	TEMPLATE.EnableTabButton(GVAR.OptionsFrame.TestRaidSize40, BattlegroundTargets_Options.ButtonEnableBracket[40])

	TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.EnableBracket)

	BattlegroundTargets:CheckForEnabledBracket(testSize)
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:CreateMinimapButton()
	if not BattlegroundTargets_Options.MinimapButton then
		if BattlegroundTargets_MinimapButton then
			BattlegroundTargets_MinimapButton:Hide()
		end
		return
	else
		if BattlegroundTargets_MinimapButton then
			BattlegroundTargets_MinimapButton:Show()
			return
		end
	end

	if BattlegroundTargets_MinimapButton then return end

	local function MoveMinimapButton()
		local xpos
		local ypos
		local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
		if minimapShape == "SQUARE" then
			xpos = 110 * cos(BattlegroundTargets_Options.MinimapButtonPos or 0)
			ypos = 110 * sin(BattlegroundTargets_Options.MinimapButtonPos or 0)
			xpos = math.max(-82, math.min(xpos, 84))
			ypos = math.max(-86, math.min(ypos, 82))
		else
			xpos = 80 * cos(BattlegroundTargets_Options.MinimapButtonPos or 0)
			ypos = 80 * sin(BattlegroundTargets_Options.MinimapButtonPos or 0)
		end
		BattlegroundTargets_MinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 54-xpos, ypos-54)
	end

	local function DragMinimapButton()
		local xpos, ypos = GetCursorPosition()
		local xmin, ymin = Minimap:GetLeft() or 400, Minimap:GetBottom() or 400
		local scale = Minimap:GetEffectiveScale()
		xpos = xmin-xpos/scale+70
		ypos = ypos/scale-ymin-70
		BattlegroundTargets_Options.MinimapButtonPos = math.deg(math.atan2(ypos, xpos))
		MoveMinimapButton()
	end

	local MinimapButton = CreateFrame("Button", "BattlegroundTargets_MinimapButton", Minimap)
	MinimapButton:EnableMouse(true)
	MinimapButton:SetMovable(true)
	MinimapButton:SetToplevel(true)
	MinimapButton:SetWidth(32)
	MinimapButton:SetHeight(32)
	MinimapButton:SetPoint("TOPLEFT")
	MinimapButton:SetFrameStrata("LOW")
	MinimapButton:RegisterForClicks("AnyUp")
	MinimapButton:RegisterForDrag("LeftButton")

	local texture = MinimapButton:CreateTexture(nil, "ARTWORK")
	texture:SetWidth(54)
	texture:SetHeight(54)
	texture:SetPoint("TOPLEFT")
	texture:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

	local texture = MinimapButton:CreateTexture(nil, "BACKGROUND")
	texture:SetWidth(24)
	texture:SetHeight(24)
	texture:SetPoint("TOPLEFT", 2, -4)
	texture:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

	local NormalTexture = MinimapButton:CreateTexture(nil, "ARTWORK")
	NormalTexture:SetWidth(12)
	NormalTexture:SetHeight(14)
	NormalTexture:SetPoint("TOPLEFT", 10.5, -8.5)
	NormalTexture:SetTexture(AddonIcon)
	NormalTexture:SetTexCoord(2/16, 14/16, 1/16, 15/16)
	MinimapButton:SetNormalTexture(NormalTexture)

	local PushedTexture = MinimapButton:CreateTexture(nil, "ARTWORK")
	PushedTexture:SetWidth(10)
	PushedTexture:SetHeight(12)
	PushedTexture:SetPoint("TOPLEFT", 11.5, -9.5)
	PushedTexture:SetTexture(AddonIcon)
	PushedTexture:SetTexCoord(2/16, 14/16, 1/16, 15/16)
	MinimapButton:SetPushedTexture(PushedTexture)

	local HighlightTexture = MinimapButton:CreateTexture(nil, "ARTWORK")
	HighlightTexture:SetPoint("TOPLEFT", 0, 0)
	HighlightTexture:SetPoint("BOTTOMRIGHT", 0, 0)
	HighlightTexture:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	MinimapButton:SetHighlightTexture(HighlightTexture)

	MinimapButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("BattlegroundTargets", 1, 0.82, 0, 1)
		GameTooltip:Show()
	end)
	MinimapButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	MinimapButton:SetScript("OnClick", function(self, button) BattlegroundTargets:Frame_Toggle(GVAR.OptionsFrame) end)
	MinimapButton:SetScript("OnDragStart", function(self) self:LockHighlight() self:SetScript("OnUpdate", DragMinimapButton) end)
	MinimapButton:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) self:UnlockHighlight() end)

	MoveMinimapButton()
end
-- ---------------------------------------------------------------------------------------------------------------------



-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:SetupButtonLayout()
	if inCombat or InCombatLockdown() then
		reCheckBG = true
		reSetLayout = true
		return
	end
	local scale  = BattlegroundTargets_Options.ButtonScale[currentSize]
	local width  = BattlegroundTargets_Options.ButtonWidth[currentSize]
	local height = BattlegroundTargets_Options.ButtonHeight[currentSize]

	local fontHeight = BattlegroundTargets_Options.ButtonFontSize[currentSize]
	if height < fontHeight then
		fontHeight = height
	end

	local withIconWidth
	if BattlegroundTargets_Options.ButtonShowSpec[currentSize] and BattlegroundTargets_Options.ButtonClassIcon[currentSize] then
		withIconWidth = (width - ((height-2)*3)) - 2
	elseif BattlegroundTargets_Options.ButtonShowSpec[currentSize] or BattlegroundTargets_Options.ButtonClassIcon[currentSize] then
		withIconWidth = (width - ((height-2)*2)) - 2
	else
		withIconWidth = (width - ((height-2)*1)) - 2
	end

	for i = 1, 40 do
		GVAR.TargetButton[i]:SetScale(scale)

		GVAR.TargetButton[i]:SetWidth(width)
		GVAR.TargetButton[i]:SetHeight(height)
		GVAR.TargetButton[i].HighlightBackground:SetWidth(width)
		GVAR.TargetButton[i].HighlightBackground:SetHeight(height)

		if BattlegroundTargets_Options.ButtonShowSpec[currentSize] and BattlegroundTargets_Options.ButtonClassIcon[currentSize] then
			GVAR.TargetButton[i].RoleTextureBackground:SetWidth((height-2)*3)
			GVAR.TargetButton[i].RoleTextureBackground:SetHeight(height-2)
		elseif BattlegroundTargets_Options.ButtonShowSpec[currentSize] or BattlegroundTargets_Options.ButtonClassIcon[currentSize] then
			GVAR.TargetButton[i].RoleTextureBackground:SetWidth((height-2)*2)
			GVAR.TargetButton[i].RoleTextureBackground:SetHeight(height-2)
		else
			GVAR.TargetButton[i].RoleTextureBackground:SetWidth(height-2)
			GVAR.TargetButton[i].RoleTextureBackground:SetHeight(height-2)
		end

		GVAR.TargetButton[i].RoleTexture:SetWidth(height-2)
		GVAR.TargetButton[i].RoleTexture:SetHeight(height-2)
		GVAR.TargetButton[i].SpecTexture:SetWidth(height-2)
		GVAR.TargetButton[i].SpecTexture:SetHeight(height-2)
		GVAR.TargetButton[i].ClassTexture:SetWidth(height-2)
		GVAR.TargetButton[i].ClassTexture:SetHeight(height-2)

		GVAR.TargetButton[i].ClassColorBackground:SetHeight(height-2)
		GVAR.TargetButton[i].HealthBar:SetHeight(height-2)

		if BattlegroundTargets_Options.ButtonShowSpec[currentSize] and BattlegroundTargets_Options.ButtonClassIcon[currentSize] then
			GVAR.TargetButton[i].SpecTexture:Show()
			GVAR.TargetButton[i].ClassTexture:Show()
			GVAR.TargetButton[i].ClassTexture:SetPoint("LEFT", GVAR.TargetButton[i].SpecTexture, "RIGHT", 0, 0)
			GVAR.TargetButton[i].ClassColorBackground:SetPoint("LEFT", GVAR.TargetButton[i].ClassTexture, "RIGHT", 0, 0)
			GVAR.TargetButton[i].Name:SetPoint("LEFT", GVAR.TargetButton[i].ClassTexture, "RIGHT", 2, 0)
		elseif BattlegroundTargets_Options.ButtonShowSpec[currentSize] then
			GVAR.TargetButton[i].SpecTexture:Show()
			GVAR.TargetButton[i].ClassTexture:Hide()
			GVAR.TargetButton[i].ClassColorBackground:SetPoint("LEFT", GVAR.TargetButton[i].SpecTexture, "RIGHT", 0, 0)
			GVAR.TargetButton[i].Name:SetPoint("LEFT", GVAR.TargetButton[i].SpecTexture, "RIGHT", 2, 0)
		elseif BattlegroundTargets_Options.ButtonClassIcon[currentSize] then
			GVAR.TargetButton[i].SpecTexture:Hide()
			GVAR.TargetButton[i].ClassTexture:Show()
			GVAR.TargetButton[i].ClassTexture:SetPoint("LEFT", GVAR.TargetButton[i].RoleTexture, "RIGHT", 0, 0)
			GVAR.TargetButton[i].ClassColorBackground:SetPoint("LEFT", GVAR.TargetButton[i].ClassTexture, "RIGHT", 0, 0)
			GVAR.TargetButton[i].Name:SetPoint("LEFT", GVAR.TargetButton[i].ClassTexture, "RIGHT", 2, 0)
		else
			GVAR.TargetButton[i].SpecTexture:Hide()
			GVAR.TargetButton[i].ClassTexture:Hide()
			GVAR.TargetButton[i].ClassColorBackground:SetPoint("LEFT", GVAR.TargetButton[i].RoleTexture, "RIGHT", 0, 0)
			GVAR.TargetButton[i].Name:SetPoint("LEFT", GVAR.TargetButton[i].RoleTexture, "RIGHT", 2, 0)
		end

		GVAR.TargetButton[i].Name:SetFont(fontPath, BattlegroundTargets_Options.ButtonFontSize[currentSize], "")
		GVAR.TargetButton[i].Name:SetShadowOffset(0, 0)
		GVAR.TargetButton[i].Name:SetShadowColor(0, 0, 0, 0)
		GVAR.TargetButton[i].Name:SetTextColor(0, 0, 0, 1)
		GVAR.TargetButton[i].Name:SetHeight(fontHeight)

		GVAR.TargetButton[i].HealthText:SetFont(fontPath, BattlegroundTargets_Options.ButtonFontSize[currentSize], "OUTLINE")
		GVAR.TargetButton[i].HealthText:SetShadowOffset(0, 0)
		GVAR.TargetButton[i].HealthText:SetShadowColor(0, 0, 0, 0)
		GVAR.TargetButton[i].HealthText:SetTextColor(1, 1, 1, 1)
		GVAR.TargetButton[i].HealthText:SetHeight(fontHeight)
		GVAR.TargetButton[i].HealthText:SetAlpha(0.6)

		if BattlegroundTargets_Options.ButtonShowTargetCount[currentSize] then
			healthBarWidth = withIconWidth-20
			GVAR.TargetButton[i].ClassColorBackground:SetWidth(withIconWidth-20)
			GVAR.TargetButton[i].HealthBar:SetWidth(withIconWidth-20)
			GVAR.TargetButton[i].Name:SetWidth(withIconWidth-20-2)
			GVAR.TargetButton[i].TargetCountBackground:SetHeight(height-2)
			GVAR.TargetButton[i].TargetCountBackground:Show()
			GVAR.TargetButton[i].TargetCount:SetFont(fontPath, BattlegroundTargets_Options.ButtonFontSize[currentSize], "")
			GVAR.TargetButton[i].TargetCount:SetShadowOffset(0, 0)
			GVAR.TargetButton[i].TargetCount:SetShadowColor(0, 0, 0, 0)
			GVAR.TargetButton[i].TargetCount:SetHeight(fontHeight)
			GVAR.TargetButton[i].TargetCount:SetTextColor(1, 1, 1, 1)
			GVAR.TargetButton[i].TargetCount:SetText("0")
			GVAR.TargetButton[i].TargetCount:Show()
		else
			healthBarWidth = withIconWidth
			GVAR.TargetButton[i].ClassColorBackground:SetWidth(withIconWidth)
			GVAR.TargetButton[i].HealthBar:SetWidth(withIconWidth)
			GVAR.TargetButton[i].Name:SetWidth(withIconWidth-2)
			GVAR.TargetButton[i].TargetCountBackground:Hide()
			GVAR.TargetButton[i].TargetCount:Hide()
		end

		if BattlegroundTargets_Options.ButtonShowTargetIndicator[currentSize] then
			local quad = (height-2) * BattlegroundTargets_Options.ButtonTargetScale[currentSize]
			GVAR.TargetButton[i].TargetTexture:SetWidth(quad)
			GVAR.TargetButton[i].TargetTexture:SetHeight(quad)
			GVAR.TargetButton[i].TargetTexture:Show()
		else
			GVAR.TargetButton[i].TargetTexture:Hide()
		end

		if BattlegroundTargets_Options.ButtonShowFocusIndicator[currentSize] then
			local quad = (height-2) * BattlegroundTargets_Options.ButtonFocusScale[currentSize]
			GVAR.TargetButton[i].FocusTexture:SetWidth(quad)
			GVAR.TargetButton[i].FocusTexture:SetHeight(quad)
			GVAR.TargetButton[i].FocusTexture:Show()
		else
			GVAR.TargetButton[i].FocusTexture:Hide()
		end
	end
	reSetLayout = false
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:Frame_Toggle(frame, show)
	if show then
		frame:Show()
	else
		if frame:IsShown() then
			frame:Hide()
		else
			frame:Show()
		end
	end
end

function BattlegroundTargets:Frame_SetupPosition(frameName)
	if frameName == "BattlegroundTargets_MainFrame" then
		if BattlegroundTargets_Options.IndependentPositioning[currentSize] and BattlegroundTargets_Options.pos[frameName..currentSize.."_posX"] then
			_G[frameName]:ClearAllPoints()
			_G[frameName]:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", BattlegroundTargets_Options.pos[frameName..currentSize.."_posX"], BattlegroundTargets_Options.pos[frameName..currentSize.."_posY"])
		elseif BattlegroundTargets_Options.pos[frameName.."_posX"] then
			_G[frameName]:ClearAllPoints()
			_G[frameName]:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", BattlegroundTargets_Options.pos[frameName.."_posX"], BattlegroundTargets_Options.pos[frameName.."_posY"])
		else
			_G[frameName]:ClearAllPoints()
			_G[frameName]:SetPoint("TOPRIGHT", GVAR.OptionsFrame, "TOPLEFT", -50, 19)
		end
	elseif frameName == "BattlegroundTargets_OptionsFrame" then
		if BattlegroundTargets_Options.pos[frameName.."_posX"] then
			_G[frameName]:ClearAllPoints()
			_G[frameName]:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", BattlegroundTargets_Options.pos[frameName.."_posX"], BattlegroundTargets_Options.pos[frameName.."_posY"])
		else
			_G[frameName]:ClearAllPoints()
			_G[frameName]:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
		end
	end
end

function BattlegroundTargets:Frame_SavePosition(frameName)
	local x,y
	if frameName == "BattlegroundTargets_MainFrame" and BattlegroundTargets_Options.IndependentPositioning[currentSize] then
		x = frameName..currentSize.."_posX"
		y = frameName..currentSize.."_posY"
	else
		x = frameName.."_posX"
		y = frameName.."_posY"
	end
	BattlegroundTargets_Options.pos[x] = _G[frameName]:GetLeft()
	BattlegroundTargets_Options.pos[y] = _G[frameName]:GetTop()
	_G[frameName]:ClearAllPoints()
	_G[frameName]:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", BattlegroundTargets_Options.pos[x], BattlegroundTargets_Options.pos[y])
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:MainFrameShow()
	if inCombat or InCombatLockdown() then return end
	BattlegroundTargets:Frame_SetupPosition("BattlegroundTargets_MainFrame")
	GVAR.MainFrame:StartMoving()
	GVAR.MainFrame:StopMovingOrSizing()
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:OptionsFrameHide()
	PlaySound("igQuestListClose")
	isConfig = false
	testDataLoaded = false
	TEMPLATE.EnableTextButton(GVAR.InterfaceOptions.CONFIG, 1)
	BattlegroundTargets:DisableConfigMode()
end

function BattlegroundTargets:OptionsFrameShow()
	PlaySound("igQuestListOpen")
	isConfig = true
	TEMPLATE.DisableTextButton(GVAR.InterfaceOptions.CONFIG)
	BattlegroundTargets:Frame_SetupPosition("BattlegroundTargets_OptionsFrame")
	GVAR.OptionsFrame:StartMoving()
	GVAR.OptionsFrame:StopMovingOrSizing()

	if inBattleground then
		testSize = currentSize
	end

	if testSize == 10 then
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize10, true)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize15, nil)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize40, nil)
	elseif testSize == 15 then
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize10, nil)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize15, true)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize40, nil)
	elseif testSize == 40 then
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize10, nil)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize15, nil)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize40, true)
	end

	if inCombat or InCombatLockdown() then
		BattlegroundTargets:DisableInsecureConfigWidges()
	else
		BattlegroundTargets:EnableInsecureConfigWidges()
	end

	if BattlegroundTargets_Options.ButtonEnableBracket[testSize] then
		BattlegroundTargets:EnableConfigMode()
	else
		BattlegroundTargets:DisableConfigMode()
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:EnableConfigMode()
	if inCombat or InCombatLockdown() then
		reCheckBG = true
		reSetLayout = true
		return
	end

	-- Test Data START
	if not testDataLoaded then
		table_wipe(ENEMY_Data)

		ENEMY_Data[1] = {}
		ENEMY_Data[1].name = TARGET.."aa-Alterac Mountains"
		ENEMY_Data[1].classToken = "DRUID"
		ENEMY_Data[1].talentSpec = T.DRUID[3]
		ENEMY_Data[2] = {}
		ENEMY_Data[2].name = TARGET.."bb-Ragnaros"
		ENEMY_Data[2].classToken = "PRIEST"
		ENEMY_Data[2].talentSpec = T.PRIEST[3]
		ENEMY_Data[3] = {}
		ENEMY_Data[3].name = TARGET.."cc-Blackrock"
		ENEMY_Data[3].classToken = "WARLOCK"
		ENEMY_Data[3].talentSpec = T.WARLOCK[1]
		ENEMY_Data[4] = {}
		ENEMY_Data[4].name = TARGET.."dd-Wildhammer"
		ENEMY_Data[4].classToken = "HUNTER"
		ENEMY_Data[4].talentSpec = T.HUNTER[3]
		ENEMY_Data[5] = {}
		ENEMY_Data[5].name = TARGET.."ee-Khaz'goroth"
		ENEMY_Data[5].classToken = "WARRIOR"
		ENEMY_Data[5].talentSpec = T.WARRIOR[3]
		ENEMY_Data[6] = {}
		ENEMY_Data[6].name = TARGET.."ff-Xavius"
		ENEMY_Data[6].classToken = "ROGUE"
		ENEMY_Data[6].talentSpec = T.ROGUE[2]
		ENEMY_Data[7] = {}
		ENEMY_Data[7].name = TARGET.."gg-Area 52"
		ENEMY_Data[7].classToken = "SHAMAN"
		ENEMY_Data[7].talentSpec = T.SHAMAN[3]
		ENEMY_Data[8] = {}
		ENEMY_Data[8].name = TARGET.."hh-Blackmoore"
		ENEMY_Data[8].classToken = "PALADIN"
		ENEMY_Data[8].talentSpec = T.PALADIN[3]
		ENEMY_Data[9] = {}
		ENEMY_Data[9].name = TARGET.."ii-Scarshield Legion"
		ENEMY_Data[9].classToken = "MAGE"
		ENEMY_Data[9].talentSpec = T.MAGE[3]
		ENEMY_Data[10] = {}
		ENEMY_Data[10].name = TARGET.."jj-Conseil des Ombres"
		ENEMY_Data[10].classToken = "DEATHKNIGHT"
		ENEMY_Data[10].talentSpec = T.DEATHKNIGHT[2]
		ENEMY_Data[11] = {}
		ENEMY_Data[11].name = TARGET.."kk-Archimonde"
		ENEMY_Data[11].classToken = "DRUID"
		ENEMY_Data[11].talentSpec = T.DRUID[1]
		ENEMY_Data[12] = {}
		ENEMY_Data[12].name = TARGET.."ll-Nefarian"
		ENEMY_Data[12].classToken = "DEATHKNIGHT"
		ENEMY_Data[12].talentSpec = T.DEATHKNIGHT[3]
		ENEMY_Data[13] = {}
		ENEMY_Data[13].name = TARGET.."mm-Trollbane"
		ENEMY_Data[13].classToken = "PALADIN"
		ENEMY_Data[13].talentSpec = T.PALADIN[3]
		ENEMY_Data[14] = {}
		ENEMY_Data[14].name = TARGET.."nn-Un'Goro"
		ENEMY_Data[14].classToken = "MAGE"
		ENEMY_Data[14].talentSpec = T.MAGE[1]
		ENEMY_Data[15] = {}
		ENEMY_Data[15].name = TARGET.."oo-Teldrassil"
		ENEMY_Data[15].classToken = "SHAMAN"
		ENEMY_Data[15].talentSpec = T.SHAMAN[2]
		ENEMY_Data[16] = {}
		ENEMY_Data[16].name = TARGET.."pp-Rexxar"
		ENEMY_Data[16].classToken = "ROGUE"
		ENEMY_Data[16].talentSpec = T.ROGUE[1]
		ENEMY_Data[17] = {}
		ENEMY_Data[17].name = TARGET.."qq-Gilneas"
		ENEMY_Data[17].classToken = "WARLOCK"
		ENEMY_Data[17].talentSpec = T.WARLOCK[2]
		ENEMY_Data[18] = {}
		ENEMY_Data[18].name = TARGET.."rr-Terokkar"
		ENEMY_Data[18].classToken = "PRIEST"
		ENEMY_Data[18].talentSpec = T.PRIEST[3]
		ENEMY_Data[19] = {}
		ENEMY_Data[19].name = TARGET.."ss-Zuluhed"
		ENEMY_Data[19].classToken = "WARRIOR"
		ENEMY_Data[19].talentSpec = T.WARRIOR[1]
		ENEMY_Data[20] = {}
		ENEMY_Data[20].name = TARGET.."tt-Archimonde"
		ENEMY_Data[20].classToken = "DRUID"
		ENEMY_Data[20].talentSpec = T.DRUID[2]
		ENEMY_Data[21] = {}
		ENEMY_Data[21].name = TARGET.."uu-Anub'arak"
		ENEMY_Data[21].classToken = "PRIEST"
		ENEMY_Data[21].talentSpec = T.PRIEST[3]
		ENEMY_Data[22] = {}
		ENEMY_Data[22].name = TARGET.."vv-Kul Tiras"
		ENEMY_Data[22].classToken = "WARRIOR"
		ENEMY_Data[22].talentSpec = T.WARRIOR[1]
		ENEMY_Data[23] = {}
		ENEMY_Data[23].name = TARGET.."ww-Garrosh"
		ENEMY_Data[23].classToken = "SHAMAN"
		ENEMY_Data[23].talentSpec = T.SHAMAN[1]
		ENEMY_Data[24] = {}
		ENEMY_Data[24].name = TARGET.."xx-Durotan"
		ENEMY_Data[24].classToken = "HUNTER"
		ENEMY_Data[24].talentSpec = T.HUNTER[2]
		ENEMY_Data[25] = {}
		ENEMY_Data[25].name = TARGET.."yy-Thrall"
		ENEMY_Data[25].classToken = "SHAMAN"
		ENEMY_Data[25].talentSpec = T.SHAMAN[2]
		ENEMY_Data[26] = {}
		ENEMY_Data[26].name = TARGET.."zz-Frostmourne"
		ENEMY_Data[26].classToken = "WARLOCK"
		ENEMY_Data[26].talentSpec = T.WARLOCK[3]
		ENEMY_Data[27] = {}
		ENEMY_Data[27].name = TARGET.."ab-Stormrage"
		ENEMY_Data[27].classToken = "PRIEST"
		ENEMY_Data[27].talentSpec = T.PRIEST[2]
		ENEMY_Data[28] = {}
		ENEMY_Data[28].name = TARGET.."cd-Les Sentinelles"
		ENEMY_Data[28].classToken = "MAGE"
		ENEMY_Data[28].talentSpec = T.MAGE[2]
		ENEMY_Data[29] = {}
		ENEMY_Data[29].name = TARGET.."ef-Arthas"
		ENEMY_Data[29].classToken = "ROGUE"
		ENEMY_Data[29].talentSpec = T.ROGUE[3]
		ENEMY_Data[30] = {}
		ENEMY_Data[30].name = TARGET.."gh-Bronzebeard"
		ENEMY_Data[30].classToken = "DRUID"
		ENEMY_Data[30].talentSpec = T.DRUID[1]
		ENEMY_Data[31] = {}
		ENEMY_Data[31].name = TARGET.."ij-Forscherliga"
		ENEMY_Data[31].classToken = "HUNTER"
		ENEMY_Data[31].talentSpec = T.HUNTER[3]
		ENEMY_Data[32] = {}
		ENEMY_Data[32].name = TARGET.."kl-Deephome"
		ENEMY_Data[32].classToken = "WARRIOR"
		ENEMY_Data[32].talentSpec = T.WARRIOR[2]
		ENEMY_Data[33] = {}
		ENEMY_Data[33].name = TARGET.."mn-Arthas"
		ENEMY_Data[33].classToken = "PALADIN"
		ENEMY_Data[33].talentSpec = T.PALADIN[1]
		ENEMY_Data[34] = {}
		ENEMY_Data[34].name = TARGET.."op-Blade's Edge"
		ENEMY_Data[34].classToken = "MAGE"
		ENEMY_Data[34].talentSpec = T.MAGE[3]
		ENEMY_Data[35] = {}
		ENEMY_Data[35].name = TARGET.."qr-Talnivarr"
		ENEMY_Data[35].classToken = "DEATHKNIGHT"
		ENEMY_Data[35].talentSpec =  T.DEATHKNIGHT[3]
		ENEMY_Data[36] = {}
		ENEMY_Data[36].name = TARGET.."st-Steamwheedle Cartel"
		ENEMY_Data[36].classToken = "MAGE"
		ENEMY_Data[36].talentSpec = T.MAGE[2]
		ENEMY_Data[37] = {}
		ENEMY_Data[37].name = TARGET.."uv-Naxxramas"
		ENEMY_Data[37].classToken = "HUNTER"
		ENEMY_Data[37].talentSpec = T.HUNTER[2]
		ENEMY_Data[38] = {}
		ENEMY_Data[38].name = TARGET.."wx-Archimonde"
		ENEMY_Data[38].classToken = "WARLOCK"
		ENEMY_Data[38].talentSpec = T.WARLOCK[1]
		ENEMY_Data[39] = {}
		ENEMY_Data[39].name = TARGET.."yz-Nazjatar"
		ENEMY_Data[39].classToken = "WARLOCK"
		ENEMY_Data[39].talentSpec = T.WARLOCK[2]
		ENEMY_Data[40] = {}
		ENEMY_Data[40].name = TARGET.."zz-Drak'thul"
		ENEMY_Data[40].classToken = "ROGUE"
		ENEMY_Data[40].talentSpec = nil

		for i = 1, 40 do
			local role = 4
			local spec = 4
			if ENEMY_Data[i].talentSpec and ENEMY_Data[i].classToken and T[ ENEMY_Data[i].classToken ] then
				if ENEMY_Data[i].talentSpec == T[ ENEMY_Data[i].classToken ][1] then
					role = classes[ ENEMY_Data[i].classToken ].spec[1].role
					spec = 1
				elseif ENEMY_Data[i].talentSpec == T[ ENEMY_Data[i].classToken ][2] then
					role = classes[ ENEMY_Data[i].classToken ].spec[2].role
					spec = 2
				elseif ENEMY_Data[i].talentSpec == T[ ENEMY_Data[i].classToken ][3] then
					role = classes[ ENEMY_Data[i].classToken ].spec[3].role
					spec = 3
				end
			end
			ENEMY_Data[i].specNum = spec
			ENEMY_Data[i].talentSpec = role
		end

		testDataLoaded = true
	end
	-- Test Data END

	currentSize = testSize
	BattlegroundTargets:Frame_SetupPosition("BattlegroundTargets_MainFrame")
	BattlegroundTargets:SetOptions()

	GVAR.MainFrame:Show()
	GVAR.MainFrame:EnableMouse(true)
	GVAR.MainFrame:SetHeight(20)
	GVAR.MainFrame.Movetext:Show()
	GVAR.TargetButton[1]:SetPoint("TOPLEFT", GVAR.MainFrame, "BOTTOMLEFT", 0, 0)

	BattlegroundTargets:SetupButtonLayout()

	for i = 1, 40 do
		GVAR.TargetButton[i].TargetTexture:SetAlpha(0)
		GVAR.TargetButton[i].HighlightBackground:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].isTarget = nil
		GVAR.TargetButton[i].TargetCount:SetText("0")
		GVAR.TargetButton[i].FocusTexture:SetAlpha(0)
		GVAR.TargetButton[i].HealthBar:SetWidth(healthBarWidth)
		GVAR.TargetButton[i].HealthText:SetText("")

		if i < currentSize+1 then
			GVAR.TargetButton[i]:Show()
			if BattlegroundTargets_Options.ButtonShowHealthBar[currentSize] then
				local width = healthBarWidth/currentSize*(currentSize+1-i)
				local percent = math_floor( ((1/(healthBarWidth / width))*100) + 0.5 )
				GVAR.TargetButton[i].HealthBar:SetWidth( width )
				if BattlegroundTargets_Options.ButtonShowHealthText[currentSize] then
					GVAR.TargetButton[i].HealthText:SetText(percent)
				end
			end
		else
			GVAR.TargetButton[i]:Hide()
		end
	end
	if BattlegroundTargets_Options.ButtonShowTargetIndicator[currentSize] then
		GVAR.TargetButton[2].TargetTexture:SetAlpha(1)
		GVAR.TargetButton[2].HighlightBackground:SetTexture(0.5, 0.5, 0.5, 1)
		GVAR.TargetButton[2].isTarget = 1
	end
	if BattlegroundTargets_Options.ButtonShowFocusIndicator[currentSize] then
		GVAR.TargetButton[5].FocusTexture:SetAlpha(1)
	end

	BattlegroundTargets:UpdateLayout()
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:DisableConfigMode()
	if inCombat or InCombatLockdown() then
		reCheckBG = true
		reSetLayout = true
		return
	end

	currentSize = testSize
	BattlegroundTargets:SetOptions()

	BattlegroundTargets:Frame_Toggle(GVAR.MainFrame)
	for i = 1, 40 do
		GVAR.TargetButton[i]:Hide()
		GVAR.TargetButton[i].TargetTexture:SetAlpha(0)
		GVAR.TargetButton[i].TargetCount:SetText("0")
		GVAR.TargetButton[i].FocusTexture:SetAlpha(0)
		GVAR.TargetButton[i].HealthBar:SetWidth(healthBarWidth)
		GVAR.TargetButton[i].HealthText:SetText("")
	end
	BattlegroundTargets:BattlefieldCheck()
	BattlegroundTargets:CheckPlayerFocus()
	BattlegroundTargets:CheckPlayerTarget()
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:UpdateLayout()
	local sortfunc
	if BattlegroundTargets_Options.ButtonSortBySize[currentSize] == 1 then -- ROLE / CLASS / NAME
		sortfunc = function(a, b)
			if a.talentSpec == b.talentSpec then
				if a.classToken == b.classToken then
					if a.name < b.name then return true end
				elseif a.classToken < b.classToken then return true end
			elseif a.talentSpec < b.talentSpec then return true end
		end
	elseif BattlegroundTargets_Options.ButtonSortBySize[currentSize] == 2 then -- ROLE / NAME
		sortfunc = function(a, b)
			if a.talentSpec == b.talentSpec then
				if a.name < b.name then return true end
			elseif a.talentSpec < b.talentSpec then return true end
		end
	elseif BattlegroundTargets_Options.ButtonSortBySize[currentSize] == 3 then -- CLASS / ROLE / NAME
		sortfunc = function(a, b)
			if a.classToken == b.classToken then
				if a.talentSpec == b.talentSpec then
					if a.name < b.name then return true end
				elseif a.talentSpec < b.talentSpec then return true end
			elseif a.classToken < b.classToken then return true end
		end
	elseif BattlegroundTargets_Options.ButtonSortBySize[currentSize] == 4 then -- CLASS / NAME
		sortfunc = function(a, b)
			if a.classToken == b.classToken then
				if a.name < b.name then return true end
			elseif a.classToken < b.classToken then return true end
		end
	elseif BattlegroundTargets_Options.ButtonSortBySize[currentSize] == 5 then -- NAME
		sortfunc = function(a, b)
			if a.name < b.name then return true end
		end
	end
	table_sort(ENEMY_Data, sortfunc)

	local ButtonShowSpec            = BattlegroundTargets_Options.ButtonShowSpec[currentSize]
	local ButtonClassIcon           = BattlegroundTargets_Options.ButtonClassIcon[currentSize]
	local ButtonShowRealm           = BattlegroundTargets_Options.ButtonShowRealm[currentSize]
	local ButtonShowTargetCount     = BattlegroundTargets_Options.ButtonShowTargetCount[currentSize]
	local ButtonShowHealthBar       = BattlegroundTargets_Options.ButtonShowHealthBar[currentSize]
	local ButtonShowHealthText      = BattlegroundTargets_Options.ButtonShowHealthText[currentSize]
	local ButtonShowTargetIndicator = BattlegroundTargets_Options.ButtonShowTargetIndicator[currentSize]
	local ButtonShowFocusIndicator  = BattlegroundTargets_Options.ButtonShowFocusIndicator[currentSize]

	for i = 1, currentSize do
		if ENEMY_Data[i] then
			ENEMY_Name2Button[ ENEMY_Data[i].name ] = i

			local r = classcolors[ ENEMY_Data[i].classToken ].r
			local g = classcolors[ ENEMY_Data[i].classToken ].g
			local b = classcolors[ ENEMY_Data[i].classToken ].b
			GVAR.TargetButton[i].ClassColorBackground:SetTexture(r*0.5, g*0.5, b*0.5, 1)
			GVAR.TargetButton[i].HealthBar:SetTexture(r, g, b, 1)

			if ButtonShowSpec then
				GVAR.TargetButton[i].SpecTexture:SetTexture(classes[ ENEMY_Data[i].classToken ].spec[ ENEMY_Data[i].specNum ].icon)
			end

			if ButtonClassIcon then
				GVAR.TargetButton[i].ClassTexture:SetTexCoord(classes[ ENEMY_Data[i].classToken ].icon[1], classes[ ENEMY_Data[i].classToken ].icon[2], classes[ ENEMY_Data[i].classToken ].icon[3], classes[ ENEMY_Data[i].classToken ].icon[4])
			end

			GVAR.TargetButton[i].RoleTexture:SetTexCoord(Textures.RoleIcon[ENEMY_Data[i].talentSpec][1], Textures.RoleIcon[ENEMY_Data[i].talentSpec][2], Textures.RoleIcon[ENEMY_Data[i].talentSpec][3], Textures.RoleIcon[ENEMY_Data[i].talentSpec][4])
			local name = ENEMY_Data[i].name
			if not ButtonShowRealm then
				if string_find(name, "-", 1, true) then
					name = string_match(name, "(.-)%-(.*)$")
				end
			end
			GVAR.TargetButton[i].Name:SetText(name)
			if not inCombat or not InCombatLockdown() then
				GVAR.TargetButton[i]:SetAttribute("macrotext1", "/target "..ENEMY_Data[i].name)
				GVAR.TargetButton[i]:SetAttribute("macrotext2", "/target "..ENEMY_Data[i].name.."\n/focus")
			end

			if ButtonShowTargetCount then
				if ENEMY_Names[ ENEMY_Data[i].name ] and GVAR.TargetButton[ ENEMY_Name2Button[ ENEMY_Data[i].name ] ] then
					GVAR.TargetButton[ ENEMY_Name2Button[ ENEMY_Data[i].name ] ].TargetCount:SetText( ENEMY_Names[ ENEMY_Data[i].name ] )
				end
			end

			if ButtonShowHealthBar then
				if ENEMY_Names[ ENEMY_Data[i].name ] and ENEMY_Name2Percent[ ENEMY_Data[i].name ] then
					local width = healthBarWidth * (ENEMY_Name2Percent[ ENEMY_Data[i].name ] / 100)
					width = math_max(0.01, width)
					width = math_min(healthBarWidth, width)
					GVAR.TargetButton[ i ].HealthBar:SetWidth( width )

					if ButtonShowHealthText then
						GVAR.TargetButton[ i ].HealthText:SetText( ENEMY_Name2Percent[ ENEMY_Data[i].name ] )
					end
				end
			end

			if targetName and ButtonShowTargetIndicator then
				if ENEMY_Data[i].name == targetName then
					GVAR.TargetButton[i].TargetTexture:SetAlpha(1)
				else
					GVAR.TargetButton[i].TargetTexture:SetAlpha(0)
				end
			end

			if focusName and ButtonShowFocusIndicator then
				if ENEMY_Data[i].name == focusName then
					GVAR.TargetButton[i].FocusTexture:SetAlpha(1)
				else
					GVAR.TargetButton[i].FocusTexture:SetAlpha(0)
				end
			end

		else
			GVAR.TargetButton[i].ClassColorBackground:SetTexture(0.5, 0.5, 0.5, 0.5)
			GVAR.TargetButton[i].HealthBar:SetTexture(0.5, 0.5, 0.5, 0.5)
			GVAR.TargetButton[i].HealthText:SetText("")
			GVAR.TargetButton[i].SpecTexture:SetTexture(nil)
			GVAR.TargetButton[i].ClassTexture:SetTexCoord(0, 0, 0, 0)
			GVAR.TargetButton[i].RoleTexture:SetTexCoord(0, 0, 0, 0)
			GVAR.TargetButton[i].Name:SetText("")
			if not inCombat or not InCombatLockdown() then
				GVAR.TargetButton[i]:SetAttribute("macrotext1", "")
				GVAR.TargetButton[i]:SetAttribute("macrotext2", "")
			end
		end
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
local function BattlefieldUpdateTargets(forceUpdate)
	if not inWorld then return end
	if not inBattleground then return end
	if WorldStateScoreFrame:IsShown() and WorldStateScoreFrame.selectedTab and WorldStateScoreFrame.selectedTab > 1 then return end -- WorldStateScoreFrameTab_OnClick (WorldStateFrame.lua) | PanelTemplates_SetTab (UIPanelTemplates.lua) | Button WorldStateScoreFrameTab1/2/3 (WorldStateFrame.xml)

	if not forceUpdate then
		local curTime = GetTime()
		if scoreUpdateThrottle + scoreUpdateFrequency > curTime then return end
		scoreUpdateThrottle = curTime
	end

	SetBattlefieldScoreFaction()

	table_wipe(ENEMY_Data)

	local x = 1
	local numScores = GetNumBattlefieldScores()
	for index = 1, numScores do
		local name, _, _, _, _, faction, _, _, classToken, _, _, _, _, _, _, talentSpec = GetBattlefieldScore(index)
		if name then
			if faction == oppositeFaction then

				local role = 4
				local spec = 4
				local class = "ZZZFAILURE"
				if classToken then
					class = classToken
					if talentSpec then
						if T[classToken] then
							if talentSpec == T[classToken][1] then
								role = classes[classToken].spec[1].role
								spec = 1
							elseif talentSpec == T[classToken][2] then
								role = classes[classToken].spec[2].role
								spec = 2
							elseif talentSpec == T[classToken][3] then
								role = classes[classToken].spec[3].role
								spec = 3
							end
						end
					end
				end

				ENEMY_Data[x] = {}
				ENEMY_Data[x].name = name
				ENEMY_Data[x].classToken = class
				ENEMY_Data[x].specNum = spec
				ENEMY_Data[x].talentSpec = role
				x = x + 1

				if not ENEMY_Names[name] then
					ENEMY_Names[name] = 0
				end

			end
		end
	end

	BattlegroundTargets:UpdateLayout()

	if reSizeCheck < 10 then
		local queueStatus, queueMapName, bgName
		for i=1, MAX_BATTLEFIELD_QUEUES do
			queueStatus, queueMapName = GetBattlefieldStatus(i)
			if queueStatus == "active" then
				bgName = queueMapName
				break
			end
		end

		if bgName and BGN[bgName] then
			BattlegroundTargets:BattlefieldCheck()
		else
			local zone = GetRealZoneText()
			if zone and BGN[zone] then
				BattlegroundTargets:BattlefieldCheck()
			else
				reSizeCheck = reSizeCheck + 1
			end
		end
	end

end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:BattlefieldCheck()
	if not inWorld then return end
	local _, instanceType = IsInInstance()

	if instanceType == "pvp" then
		inBattleground = true

		local isRatedBG = IsRatedBattleground()

		if isRatedBG then
			currentSize = rbgSize
			reSizeCheck = 10
		else
			local queueStatus, queueMapName, bgName
			for i=1, MAX_BATTLEFIELD_QUEUES do
				queueStatus, queueMapName = GetBattlefieldStatus(i)
				if queueStatus == "active" then
					bgName = queueMapName
					break
				end
			end

			if bgName and BGN[bgName] then
				currentSize = bgSize[ BGN[bgName] ]
				reSizeCheck = 10
			else
				local zone = GetRealZoneText()
				if zone and BGN[zone] then
					currentSize = bgSize[ BGN[zone] ]
					reSizeCheck = 10
				else
					if reSizeCheck >= 10 then
						Print(bgName, L["is not localized! Please contact addon author. Thanks."])
					end
					currentSize = 10
					reSizeCheck = reSizeCheck + 1
				end
			end
		end

		local faction = GetBattlefieldArenaFaction()
		if faction then
			if faction == 0 then
				playerFaction   = 0 -- Horde or Alliance
				oppositeFaction = 1 -- Alliance or Horde
			elseif faction == 1 then
				playerFaction   = 1 -- Alliance or Horde
				oppositeFaction = 0 -- Horde or Alliance
			end
		end

		if inCombat or InCombatLockdown() then
			reCheckBG = true
		else
			reCheckBG = false

			if BattlegroundTargets_Options.ButtonEnableBracket[currentSize] then

				GVAR.MainFrame:Show()
				GVAR.MainFrame:EnableMouse(false)
				GVAR.MainFrame:SetHeight(0.001)
				GVAR.MainFrame.Movetext:Hide()
				GVAR.TargetButton[1]:SetPoint("TOPLEFT", GVAR.MainFrame, "BOTTOMLEFT", 0, -(20 / BattlegroundTargets_Options.ButtonScale[currentSize]))

				BattlefieldUpdateTargets(1)
				BattlegroundTargets:SetupButtonLayout()

				for i = 1, 40 do
					if i < currentSize+1 then
						GVAR.TargetButton[i]:Show()
					else
						GVAR.TargetButton[i]:Hide()
					end
				end

			else

				GVAR.MainFrame:Hide()
				for i = 1, 40 do
					GVAR.TargetButton[i]:Hide()
				end

			end

		end

		if BattlegroundTargets_Options.ButtonEnableBracket[currentSize] then
			if BattlegroundTargets_Options.ButtonShowHealthBar[currentSize] then
				BattlegroundTargets:RegisterEvent("UNIT_TARGET")
				BattlegroundTargets:RegisterEvent("UNIT_HEALTH_FREQUENT")
				BattlegroundTargets:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
			end
			if BattlegroundTargets_Options.ButtonShowTargetCount[currentSize] then
				BattlegroundTargets:RegisterEvent("UNIT_TARGET")
			end
			if BattlegroundTargets_Options.ButtonShowTargetIndicator[currentSize] then
				BattlegroundTargets:RegisterEvent("PLAYER_TARGET_CHANGED")
			end
			if BattlegroundTargets_Options.ButtonShowFocusIndicator[currentSize] then
				BattlegroundTargets:RegisterEvent("PLAYER_FOCUS_CHANGED")
			end
			BattlegroundTargets:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
		end
	else
		inBattleground = false
		reSizeCheck = 0

		BattlegroundTargets:UnregisterEvent("UNIT_HEALTH_FREQUENT")
		BattlegroundTargets:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
		BattlegroundTargets:UnregisterEvent("UNIT_TARGET")
		BattlegroundTargets:UnregisterEvent("PLAYER_TARGET_CHANGED")
		BattlegroundTargets:UnregisterEvent("PLAYER_FOCUS_CHANGED")
		BattlegroundTargets:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE")

		if not isConfig then
			table_wipe(ENEMY_Data)
		end
		table_wipe(ENEMY_Names)
		table_wipe(ENEMY_Name2Button)
		table_wipe(TARGET_Names)

		if inCombat or InCombatLockdown() then
			reCheckBG = true
		else
			reCheckBG = false

			GVAR.MainFrame:Hide()
			for i = 1, 40 do
				GVAR.TargetButton[i]:Hide()
			end
		end

	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:CheckPlayerTarget()
	if isConfig then return end
	if not inWorld then return end
	if not inBattleground then return end
	if not BattlegroundTargets_Options.ButtonShowTargetIndicator[currentSize] then return end

	targetName, targetRealm = UnitName("target")
	if targetRealm and targetRealm ~= "" then
		targetName = targetName.."-"..targetRealm
	end

	for i = 1, currentSize do
		GVAR.TargetButton[i].TargetTexture:SetAlpha(0)
		GVAR.TargetButton[i].HighlightBackground:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].isTarget = nil
	end

	if targetName and ENEMY_Names[targetName] and GVAR.TargetButton[ ENEMY_Name2Button[targetName] ] then
		GVAR.TargetButton[ ENEMY_Name2Button[targetName] ].TargetTexture:SetAlpha(1)
		GVAR.TargetButton[ ENEMY_Name2Button[targetName] ].HighlightBackground:SetTexture(0.5, 0.5, 0.5, 1)
		GVAR.TargetButton[ ENEMY_Name2Button[targetName] ].isTarget = 1
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:CheckPlayerFocus()
	if isConfig then return end
	if not inWorld then return end
	if not inBattleground then return end
	if not BattlegroundTargets_Options.ButtonShowFocusIndicator[currentSize] then return end

	focusName, focusRealm = UnitName("focus")
	if focusRealm and focusRealm ~= "" then
		focusName = focusName.."-"..focusRealm
	end

	for i = 1, currentSize do
		GVAR.TargetButton[i].FocusTexture:SetAlpha(0)
	end

	if focusName and ENEMY_Names[focusName] and GVAR.TargetButton[ ENEMY_Name2Button[focusName] ] then
		GVAR.TargetButton[ ENEMY_Name2Button[focusName] ].FocusTexture:SetAlpha(1)
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:CheckUnitTarget(unitID)
	if isConfig then return end
	if not inWorld then return end
	if not inBattleground then return end

	local ButtonShowTargetCount = BattlegroundTargets_Options.ButtonShowTargetCount[currentSize]
	local ButtonShowHealthBar   = BattlegroundTargets_Options.ButtonShowHealthBar[currentSize]

	if not ButtonShowTargetCount and not ButtonShowHealthBar then return end

	local friendName, friendRealm, enemyID, enemyName, enemyRealm

	if unitID == "player" then
		friendName = UnitName("player")
		enemyID = "target"
		enemyName, enemyRealm = UnitName(enemyID)
		if enemyRealm and enemyRealm ~= "" then
			enemyName = enemyName.."-"..enemyRealm
		end
	else
		friendName, friendRealm = UnitName(unitID)
		if friendRealm and friendRealm ~= "" then
			friendName = friendName.."-"..friendRealm
		end
		enemyID = unitID.."target"
		enemyName, enemyRealm = UnitName(enemyID)
		if enemyRealm and enemyRealm ~= "" then
			enemyName = enemyName.."-"..enemyRealm
		end
	end

	if ButtonShowTargetCount then
		if friendName then
			if enemyName then
				TARGET_Names[friendName] = enemyName
			else
				TARGET_Names[friendName] = nil
			end
		end

		for eName in pairs(ENEMY_Names) do
			ENEMY_Names[eName] = 0
		end

		for _, eName in pairs(TARGET_Names) do
			if ENEMY_Names[eName] then
				ENEMY_Names[eName] = ENEMY_Names[eName] + 1
			end
		end

		for i = 1, currentSize do
			if ENEMY_Data[i] and ENEMY_Names[ ENEMY_Data[i].name ] then
				GVAR.TargetButton[i].TargetCount:SetText( ENEMY_Names[ ENEMY_Data[i].name ] )
			end
		end
	end

	if ButtonShowHealthBar then
		if enemyName then
			BattlegroundTargets:CheckUnitHealth(enemyID, enemyName)
		end
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:CheckUnitHealth(unitID, unitName)
	if isConfig then return end
	if not inWorld then return end
	if not inBattleground then return end
	if not BattlegroundTargets_Options.ButtonShowHealthBar[currentSize] then return end

	local targetID, targetName, targetRealm
	if not unitName then
		if raidUnitID[unitID] then
			targetID = unitID.."target"
		else
			if playerUnitID[unitID] then
				targetID = unitID
			else
				return
			end
		end

		targetName, targetRealm = UnitName(targetID)
		if targetRealm and targetRealm ~= "" then
			targetName = targetName.."-"..targetRealm
		end
	else
		targetID = unitID
		targetName = unitName
	end

	if not targetName then return end
	if not ENEMY_Names[targetName] then return end

	local maxHealth = UnitHealthMax(targetID)
	if not maxHealth then return end

	local health = UnitHealth(targetID)
	if not health then return end

	local width = 0.01
	local percent = 0
	if maxHealth > 0 and health > 0 then
		local hvalue = maxHealth / health
		width = healthBarWidth / hvalue
		width = math_max(0.01, width)
		width = math_min(healthBarWidth, width)
		percent = math_floor( ((1/hvalue)*100) + 0.5 )
		percent = math_max(0, percent)
		percent = math_min(100, percent)
	end

	ENEMY_Name2Percent[targetName] = percent

	if GVAR.TargetButton[ ENEMY_Name2Button[targetName] ] then
		GVAR.TargetButton[ ENEMY_Name2Button[targetName] ].HealthBar:SetWidth( width )
		if BattlegroundTargets_Options.ButtonShowHealthText[currentSize] then
			GVAR.TargetButton[ ENEMY_Name2Button[targetName] ].HealthText:SetText( percent )
		end
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
local function OnEvent(self, event, arg1)
	if event == "PLAYER_REGEN_DISABLED" then
		inCombat = true
		if isConfig then
			BattlegroundTargets:DisableInsecureConfigWidges()
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		inCombat = false
		BattlegroundTargets:EnableInsecureConfigWidges()
		if reCheckBG then
			BattlegroundTargets:BattlefieldCheck()
		end
		if reSetLayout then
			BattlegroundTargets:SetupButtonLayout()
		end
		if isConfig then
			if BattlegroundTargets_Options.ButtonEnableBracket[currentSize] then
				BattlegroundTargets:EnableConfigMode()
			else
				BattlegroundTargets:DisableConfigMode()
			end
		end
	elseif event == "UPDATE_BATTLEFIELD_SCORE" then
		if isConfig then return end
		BattlefieldUpdateTargets()
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		if isConfig then return end
		BattlegroundTargets:BattlefieldCheck()

	elseif event == "UNIT_TARGET" then
		BattlegroundTargets:CheckUnitTarget(arg1)
	elseif event == "PLAYER_FOCUS_CHANGED" then
		BattlegroundTargets:CheckPlayerFocus()
	elseif event == "PLAYER_TARGET_CHANGED" then
		BattlegroundTargets:CheckPlayerTarget()
	elseif event == "UNIT_HEALTH_FREQUENT" then
		BattlegroundTargets:CheckUnitHealth(arg1)
	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		BattlegroundTargets:CheckUnitHealth("mouseover")

	elseif event == "PLAYER_LOGIN" then
		if UnitFactionGroup("player") == "Horde" then
			playerFaction   = 0 -- Horde
			oppositeFaction = 1 -- Alliance
		else
			playerFaction   = 1 -- Alliance
			oppositeFaction = 0 -- Horde
		end

		BattlegroundTargets:InitOptions()
		BattlegroundTargets:CreateInterfaceOptions()
		BattlegroundTargets:LDBcheck()
		BattlegroundTargets:CreateFrames()
		BattlegroundTargets:CreateOptionsFrame()
		BattlegroundTargets:SetupButtonLayout()

		hooksecurefunc("PanelTemplates_SetTab", function(frame)
			if frame and frame == WorldStateScoreFrame then
				if WorldStateScoreFrame.selectedTab > 1 then
					GVAR.WorldStateScoreWarning:Show()
				else
					GVAR.WorldStateScoreWarning:Hide()
				end
			end
		end)

		table.insert(UISpecialFrames, "BattlegroundTargets_OptionsFrame")
		BattlegroundTargets:UnregisterEvent("PLAYER_LOGIN")
	elseif event == "PLAYER_ENTERING_WORLD" then
		inWorld = true
		BattlegroundTargets:BattlefieldCheck()
		BattlegroundTargets:CreateMinimapButton()

		if not BattlegroundTargets_Options.FirstRun then
			BattlegroundTargets:Frame_Toggle(GVAR.OptionsFrame)
			BattlegroundTargets_Options.FirstRun = true
		end

		BattlegroundTargets:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

BattlegroundTargets:RegisterEvent("PLAYER_REGEN_DISABLED")
BattlegroundTargets:RegisterEvent("PLAYER_REGEN_ENABLED")
BattlegroundTargets:RegisterEvent("ZONE_CHANGED_NEW_AREA")
BattlegroundTargets:RegisterEvent("PLAYER_LOGIN")
BattlegroundTargets:RegisterEvent("PLAYER_ENTERING_WORLD")
BattlegroundTargets:SetScript("OnEvent", OnEvent) -- start the Mystical Machine