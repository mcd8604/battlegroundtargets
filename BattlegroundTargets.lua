-- -------------------------------------------------------------------------- --
--                                                                            --
-- Download: http://www.wowace.com/addons/battlegroundtargets/files           --
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
--   - Left-click : set target                                                --
--   - Right-click: set focus                                                 --
-- # Independent settings for '10 vs 10', '15 vs 15' and '40 vs 40'.          --
-- # Specialization                                                           --
-- # Target                                                                   --
-- # Main Assist Target                                                       --
-- # Focus                                                                    --
-- # Enemy Flag Carrier                                                       --
-- # Target Count                                                             --
-- # Health                                                                   --
-- # Range Check                                                              --
--                                                                            --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- NOTES:                                                                     --
-- # All CPU intensive events are disabled if you are not in a battleground   --
--   OR if that feature is disabled.                                          --
--   This 3 events are always enabled:                                        --
--   - PLAYER_REGEN_DISABLED and PLAYER_REGEN_ENABLED                         --
--   - ZONE_CHANGED_NEW_AREA -> for bg check                                  --
--                                                                            --
-- # Range Check: --------------------------------------- VERY HIGH CPU USAGE --
--   - Events: Combat Log: - COMBAT_LOG_EVENT_UNFILTERED                      --
--             Class:      - PLAYER_TARGET_CHANGED                            --
--                           UNIT_HEALTH_FREQUENT                             --
--                           UPDATE_MOUSEOVER_UNIT                            --
--                           UNIT_TARGET                                      --
--   - It's impossible to get 100% precise range data from enemies with the   --
--     current WoW API.                                                       --
--   - This feature is a compromise between CPU usage (FPS), lag/network      --
--     bandwidth (no SendAdd0nMessage), fast and easy visual recognition and  --
--     suitable data.                                                         --
--                                                                            --
-- # Health: ------------------------------------------------- HIGH CPU USAGE --
--   - Events:             - UNIT_TARGET                                      --
--                         - UNIT_HEALTH_FREQUENT                             --
--                         - UPDATE_MOUSEOVER_UNIT                            --
--   - It's impossible to get 100% precise health data from enemies with the  --
--     current WoW API.                                                       --
--     A raidmember/raidpet MUST target(focus/mouseover) an enemy OR          --
--     you/yourpet MUST target/focus/mouseover an enemy to get the health!    --
--                                                                            --
-- # Target Count: ----------------------------------------- MEDIUM CPU USAGE --
--   - Event:              - UNIT_TARGET                                      --
--                                                                            --
-- # Main Assist Target: ----------------------------------- MEDIUM CPU USAGE --
--   - Events:             - RAID_ROSTER_UPDATE                               --
--                         - UNIT_TARGET                                      --
--                                                                            --
-- # Leader: ------------------------------------------- LOW MEDIUM CPU USAGE --
--   - Event:              - UNIT_TARGET                                      --
--                                                                            --
-- # Target: -------------------------------------------------- LOW CPU USAGE --
--   - Event:              - PLAYER_TARGET_CHANGED                            --
--                                                                            --
-- # Focus: --------------------------------------------------- LOW CPU USAGE --
--   - Event:              - PLAYER_FOCUS_CHANGED                             --
--                                                                            --
-- # Enemy Flag Carrier: --------------------------------- VERY LOW CPU USAGE --
--   - Events:             - CHAT_MSG_BG_SYSTEM_HORDE                         --
--                         - CHAT_MSG_BG_SYSTEM_ALLIANCE                      --
--                                                                            --
-- # No SendAdd0nMessage(): ------------------------------------------------- --
--   This AddOn does not use/need SendAdd0nMessage().                         --
--   The use of SendAdd0nMessage() can give better results by transmitting    --
--   information to other players. This has certain pros and cons.            --
--   I may include (opt-in) this in some future release, maybe. idontknow     --
--                                                                            --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- slash commands: /bgt - /bgtargets - /battlegroundtargets                   --
--                                                                            --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- Credits:                                                                   --
-- - Talented from Jerry (Thanks for some localized talent specs)             --
-- - Thanks to all who helped with the localization.                          --
--                                                                            --
-- -------------------------------------------------------------------------- --

-- ---------------------------------------------------------------------------------------------------------------------
BattlegroundTargets_Options = {} -- SavedVariable options table
local BattlegroundTargets = CreateFrame("Frame") -- container

local L   = BattlegroundTargets_Localization -- localization table
local T   = BattlegroundTargets_Talents      -- localized talents
local BGN = BattlegroundTargets_BGNames      -- localized battleground names
local FL  = BattlegroundTargets_Flag         -- localized flag picked/dropped/captured

local GVAR = {}     -- UI Widgets
local TEMPLATE = {} -- Templates
local OPT = {}      -- local SavedVariable table (BattlegroundTargets_Options.Button*)

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
local UnitIsPartyLeader       = _G.UnitIsPartyLeader
local GetSpellInfo            = _G.GetSpellInfo
local IsSpellInRange          = _G.IsSpellInRange
local CheckInteractDistance   = _G.CheckInteractDistance
local GetNumRaidMembers       = _G.GetNumRaidMembers
local GetRaidRosterInfo       = _G.GetRaidRosterInfo
local math_min                = _G.math.min
local math_max                = _G.math.max
local math_floor              = _G.math.floor
local math_random             = _G.math.random
local string_find             = _G.string.find
local string_match            = _G.string.match
local string_format           = _G.string.format
local table_sort              = _G.table.sort
local table_wipe              = _G.table.wipe
local pairs                   = _G.pairs
local tonumber                = _G.tonumber

local inWorld
local inBattleground
local inCombat
local reCheckBG
local reSizeCheck = 0 -- check bgname if normal bgname check fails (reason: sometimes GetBattlefieldStatus and GetRealZoneText returns nil)
local reSetLayout
local isConfig
local testDataLoaded
local isTarget = 0
local hasFlag
local isDead
local isLeader
local isAssistName
local isAssistUnitId
local rangeSpellName -- for class-spell based range check

local scoreUpdateThrottle  = GetTime() -- UPDATE_BATTLEFIELD_SCORE BattlefieldScoreUpdate()
local scoreUpdateFrequency = 1
local rangeUpdateThrottle  = GetTime() -- UpdateRange() display only
local rangeUpdateFrequency = 0.5
local classRangeFrequency  = 0.2       -- UNIT_HEALTH_FREQUENT CheckUnitHealth()
local combatlogThrottle    = 0         -- COMBAT_LOG_EVENT_UNFILTERED
local combatlogFrequency   = math_random(1,3) -- 50/50 or 66/33 or 75/25 (%Yes/%No) => 64/36 = 36% cl msgs filtered
local assistThrottle       = GetTime() -- UNIT_TARGET (assist only) - the bruteforce part
local assistFrequency      = 0.5

local playerName = UnitName("player")
local playerClass, playerClassEN = UnitClass("player")
local targetName, targetRealm
local focusName, focusRealm
local assistTargetName, assistTargetRealm

local playerFactionDEF   = 0 -- player Faction (DEFAULT)
local oppositeFactionDEF = 0 -- opposite Faction (DEFAULT)
local playerFactionBG    = 0 -- player Faction in Battleground
local oppositeFactionBG  = 0 -- opposite Faction in Battleground

local ENEMY_Data = {}         -- numerical | all data
local ENEMY_Names = {}        -- key/value | key = enemyName, value = count
local ENEMY_Name2Button = {}  -- key/value | key = enemyName, value = button number
local ENEMY_Name2Percent = {} -- key/value | key = enemyName, value = health in percent
local ENEMY_Name2Range = {}   -- key/value | key = enemyName, value = time of last contact
local FRIEND_Names = {}       -- key/value | key = friendName, value = -
local TARGET_Names = {}       -- key/value | key = friendName, value = enemyName
local SPELL_Range = {}        -- key/value | key = spellId, value = maxRange

local testSize = 10
local testIcon1 = 2
local testIcon2 = 5
local testIcon3 = 3
local testIcon4 = 4
local testHealth = {}
local testRange = {}
local testLeader = 4

local healthBarWidth = 0.01

local sizeOffset    = 5
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
	[1] = ROLE.." / "..CLASS.."* / "..NAME,
	[2] = ROLE.." / "..NAME,
	[3] = CLASS.."* / "..ROLE.." / "..NAME,
	[4] = CLASS.."* / "..NAME,
	[5] = NAME,
}

local locale = GetLocale()
local sortDetail = {
	[1] = "*"..CLASS.." ("..locale..")",
	[2] = "*"..CLASS.." (english)",
	[3] = "*"..CLASS.." (Blizzard)",
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
	DEATHKNIGHT = {icon = {0.26562501, 0.48437501, 0.51562501, 0.73437501}, -- ( 68/256, 124/256, 132/256, 188/256)
	               spec = {[1] = {role = _TANK,    icon = "Interface\\Icons\\Spell_Deathknight_BloodPresence"},    -- Blood
	                       [2] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Deathknight_FrostPresence"},    -- Frost
	                       [3] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Deathknight_UnholyPresence"},   -- Unholy
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	DRUID       = {icon = {0.75781251, 0.97656251, 0.01562501, 0.23437501}, -- (194/256, 250/256,   4/256,  60/256)
	               spec = {[1] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Nature_StarFall"},              -- Balance
	                       [2] = {role = _TANK,    icon = "Interface\\Icons\\Ability_Racial_BearForm"},            -- Feral Combat
	                       [3] = {role = _HEAL,    icon = "Interface\\Icons\\Spell_Nature_HealingTouch"},          -- Restoration
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	HUNTER      = {icon = {0.01953125, 0.23828125, 0.26562501, 0.48437501}, -- (  5/256,  61/256,  68/256, 124/256)
	               spec = {[1] = {role = _DAMAGE,  icon = "Interface\\Icons\\Ability_Hunter_BestialDiscipline"},   -- Beast Mastery
	                       [2] = {role = _DAMAGE,  icon = "Interface\\Icons\\Ability_Hunter_FocusedAim"},          -- Marksmanship
	                       [3] = {role = _DAMAGE,  icon = "Interface\\Icons\\Ability_Hunter_Camouflage"},          -- Survival
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	MAGE        = {icon = {0.26562501, 0.48437501, 0.01562501, 0.23437501}, -- ( 68/256, 124/256,   4/256,  60/256)
	               spec = {[1] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Holy_MagicalSentry"},           -- Arcane
	                       [2] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Fire_FireBolt02"},              -- Fire
	                       [3] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Frost_FrostBolt02"},            -- Frost
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	PALADIN     = {icon = {0.01953125, 0.23828125, 0.51562501, 0.73437501}, -- (  5/256,  61/256, 132/256, 188/256)
	               spec = {[1] = {role = _HEAL,    icon = "Interface\\Icons\\Spell_Holy_HolyBolt"},                -- Holy
	                       [2] = {role = _TANK,    icon = "Interface\\Icons\\Ability_Paladin_ShieldoftheTemplar"}, -- Protection
	                       [3] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Holy_AuraOfLight"},             -- Retribution
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	PRIEST      = {icon = {0.51171875, 0.73046875, 0.26562501, 0.48437501}, -- (131/256, 187/256,  68/256, 124/256)
	               spec = {[1] = {role = _HEAL,    icon = "Interface\\Icons\\Spell_Holy_PowerWordShield"},         -- Discipline
	                       [2] = {role = _HEAL,    icon = "Interface\\Icons\\Spell_Holy_GuardianSpirit"},          -- Holy
	                       [3] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain"},        -- Shadow
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	ROGUE       = {icon = {0.51171875, 0.73046875, 0.01562501, 0.23437501}, -- (131/256, 187/256,   4/256,  60/256)
	               spec = {[1] = {role = _DAMAGE,  icon = "Interface\\Icons\\Ability_Rogue_Eviscerate"},           -- Assassination
	                       [2] = {role = _DAMAGE,  icon = "Interface\\Icons\\Ability_BackStab"},                   -- Combat
	                       [3] = {role = _DAMAGE,  icon = "Interface\\Icons\\Ability_Stealth"},                    -- Subtlety
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	SHAMAN      = {icon = {0.26562501, 0.48437501, 0.26562501, 0.48437501}, -- ( 68/256, 124/256,  68/256, 124/256)
	               spec = {[1] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Nature_Lightning"},             -- Elemental
	                       [2] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Nature_LightningShield"},       -- Enhancement
	                       [3] = {role = _HEAL,    icon = "Interface\\Icons\\Spell_Nature_MagicImmunity"},         -- Restoration
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	WARLOCK     = {icon = {0.75781251, 0.97656251, 0.26562501, 0.48437501}, -- (194/256, 250/256,  68/256, 124/256)
	               spec = {[1] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Shadow_DeathCoil"},             -- Affliction
	                       [2] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Shadow_Metamorphosis"},         -- Demonology
	                       [3] = {role = _DAMAGE,  icon = "Interface\\Icons\\Spell_Shadow_RainOfFire"},            -- Destruction
	                       [4] = {role = _UNKNOWN, icon = nil}}},
	WARRIOR     = {icon = {0.01953125, 0.23828125, 0.01562501, 0.23437501}, -- (  5/256,  61/256,   4/256,  60/256)
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

local classes_LOCALIZED = {}
FillLocalizedClassList(classes_LOCALIZED, false)

local classes_BLIZZ = {}
for i = 1, #CLASS_SORT_ORDER do
	classes_BLIZZ[ CLASS_SORT_ORDER[i] ] = i
end

local classesINT_LOCALIZED = { -- .cid .loc
 [1] = {cid = "DEATHKNIGHT", blizz = classes_BLIZZ.DEATHKNIGHT or  2, eng = "Death Knight", loc = classes_LOCALIZED.DEATHKNIGHT or "Death Knight"},
 [2] = {cid = "DRUID",       blizz = classes_BLIZZ.DRUID       or  6, eng = "Druid",        loc = classes_LOCALIZED.DRUID or "Druid"},
 [3] = {cid = "HUNTER",      blizz = classes_BLIZZ.HUNTER      or 10, eng = "Hunter",       loc = classes_LOCALIZED.HUNTER or "Hunter"},
 [4] = {cid = "MAGE",        blizz = classes_BLIZZ.MAGE        or  8, eng = "Mage",         loc = classes_LOCALIZED.MAGE or "Mage"},
 [5] = {cid = "PALADIN",     blizz = classes_BLIZZ.PALADIN     or  3, eng = "Paladin",      loc = classes_LOCALIZED.PALADIN or "Paladin"},
 [6] = {cid = "PRIEST",      blizz = classes_BLIZZ.PRIEST      or  4, eng = "Priest",       loc = classes_LOCALIZED.PRIEST or "Priest"},
 [7] = {cid = "ROGUE",       blizz = classes_BLIZZ.ROGUE       or  7, eng = "Rogue",        loc = classes_LOCALIZED.ROGUE or "Rogue"},
 [8] = {cid = "SHAMAN",      blizz = classes_BLIZZ.SHAMAN      or  5, eng = "Shaman",       loc = classes_LOCALIZED.SHAMAN or "Shaman"},
 [9] = {cid = "WARLOCK",     blizz = classes_BLIZZ.WARLOCK     or  9, eng = "Warlock",      loc = classes_LOCALIZED.WARLOCK or "Warlock"},
[10] = {cid = "WARRIOR",     blizz = classes_BLIZZ.WARRIOR     or  1, eng = "Warrior",      loc = classes_LOCALIZED.WARRIOR or "Warrior"},
}

local ranges = {}
ranges.DEATHKNIGHT = 47541 -- Death Coil        (30yd/m) - Lvl 55
ranges.DRUID       =  5176 -- Wrath             (40yd/m) - Lvl  1
ranges.HUNTER      =    75 -- Auto Shot       (5-40yd/m) - Lvl  1
ranges.MAGE        =   133 -- Fireball          (40yd/m) - Lvl  1
ranges.PALADIN     = 62124 -- Hand of Reckoning (30yd/m) - Lvl 14
ranges.PRIEST      =   589 -- Shadow Word: Pain (40yd/m) - Lvl  4
ranges.ROGUE       =  6770 -- Sap               (10yd/m) - Lvl 10
ranges.SHAMAN      =   403 -- Lightning Bolt    (30yd/m) - Lvl  1
ranges.WARLOCK     =   686 -- Shadow Bolt       (40yd/m) - Lvl  1
ranges.WARRIOR     =   100 -- Charge          (8-25yd/m) - Lvl  3

local rangeTypeName = {}
rangeTypeName[1] = COMBAT_LOG.." |cffffff79(0-73)|r"

local function rt(H,E,M,P) return E,P,E,M,H,P,H,M end -- magical 180 degree texture cut center rotation

local Textures = {
	BattlegroundTargetsIcons = {path= "Interface\\AddOns\\BattlegroundTargets\\BattlegroundTargets-texture-icons.tga"}, -- Textures.BattlegroundTargetsIcons.path
	SliderKnob       = {coords     =    {19/64, 30/64,  1/32, 18/32}},
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
	Shuffler         = {coords     =    {19/64, 30/64, 21/32, 32/32}},
	ShufflerFlat     = {coords     =    { 6/64, 13/64, 19/32, 21/32}},
}

local raidUnitID = {}
for i = 1, 40 do
	raidUnitID["raid"..i] = 1
	raidUnitID["raidpet"..i] = 1
end
local playerUnitID = {}
playerUnitID["target"] = 1
playerUnitID["pettarget"] = 1
playerUnitID["focus"] = 1
playerUnitID["mouseover"] = 1
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
local function Print(...)
	print("|cffffff7fBattlegroundTargets:|r", ...)
end

local function ClassHexColor(class)
	local hex = string_format("%.2x%.2x%.2x", classcolors[class].r*255, classcolors[class].g*255, classcolors[class].b*255)
	return hex or "cccccc"
end

local function NOOP() end

local function Desaturation(texture, desaturation)
	local shaderSupported = texture:SetDesaturated(desaturation)
	if not shaderSupported then
		if desaturation then
			texture:SetVertexColor(0.5, 0.5, 0.5)
		else
			texture:SetVertexColor(1.0, 1.0, 1.0)
		end
	end
end

local function SortByPullDownFunc(value) -- PDFUNC
	BattlegroundTargets_Options.ButtonSortBy[currentSize] = value
	                        OPT.ButtonSortBy[currentSize] = value
	BattlegroundTargets:EnableConfigMode()
end

local function SortDetailPullDownFunc(value) -- PDFUNC
	BattlegroundTargets_Options.ButtonSortDetail[currentSize] = value
	                        OPT.ButtonSortDetail[currentSize] = value
	BattlegroundTargets:EnableConfigMode()
end

local function RangeCheckTypePullDownFunc(value) -- PDFUNC
	if value == 1 then
		BattlegroundTargets_Options.ButtonAvgRangeCheck[currentSize]   = true
		                        OPT.ButtonAvgRangeCheck[currentSize]   = true
		BattlegroundTargets_Options.ButtonClassRangeCheck[currentSize] = false
		                        OPT.ButtonClassRangeCheck[currentSize] = false
	elseif value == 2 then
		BattlegroundTargets_Options.ButtonAvgRangeCheck[currentSize]   = false
		                        OPT.ButtonAvgRangeCheck[currentSize]   = false
		BattlegroundTargets_Options.ButtonClassRangeCheck[currentSize] = true
		                        OPT.ButtonClassRangeCheck[currentSize] = true
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

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
	elseif action == 4 then
		bordercolor = {0.73, 0.26, 0.21, 1}
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
		button:SetNormalFontObject("GameFontNormalSmall")
		button:SetDisabledFontObject("GameFontDisableSmall")
		buttoncolor = {0, 0, 0.5, 1}
		bordercolor = {0.43, 0.32, 0.68, 1}
	elseif action == 3 then
		button:SetNormalFontObject("GameFontNormalSmall")
		button:SetDisabledFontObject("GameFontDisableSmall")
		buttoncolor = {0, 0.2, 0, 1}
		bordercolor = {0.24, 0.46, 0.21, 1}
	elseif action == 4 then
		button:SetNormalFontObject("GameFontNormalSmall")
		button:SetDisabledFontObject("GameFontDisableSmall") 
		buttoncolor = {0.38, 0, 0, 1}
		bordercolor = {0.73, 0.26, 0.21, 1}
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
--TEMPLATE.DisableIconButton = function(button)
--	button.Border:SetTexture(0.4, 0.4, 0.4, 1)
--	button:Disable()
--end

--TEMPLATE.EnableIconButton = function(button)
--	button.Border:SetTexture(0.8, 0.2, 0.2, 1)
--	button:Enable()
--end

TEMPLATE.IconButton = function(button, cut)
	button.Back = button:CreateTexture(nil, "BORDER")
	button.Back:SetPoint("TOPLEFT", 1, -1)
	button.Back:SetPoint("BOTTOMRIGHT", -1, 1)
	button.Back:SetTexture(0, 0, 0, 1)

	button.Border = button:CreateTexture(nil, "BACKGROUND")
	button.Border:SetPoint("TOPLEFT", 0, 0)
	button.Border:SetPoint("BOTTOMRIGHT", 0, 0)
	button.Border:SetTexture(0.8, 0.2, 0.2, 1)

	button.Highlight = button:CreateTexture(nil, "OVERLAY")
	button.Highlight:SetPoint("TOPLEFT", 3, -3)
	button.Highlight:SetPoint("BOTTOMRIGHT", -3, 3)
	button.Highlight:SetTexture(0.6, 0.6, 0.6, 0.2)
	button:SetHighlightTexture(button.Highlight)

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

	button.Disabled = button:CreateTexture(nil, "ARTWORK")
	button.Disabled:SetPoint("TOPLEFT", 3, -3)
	button.Disabled:SetPoint("BOTTOMRIGHT", -3, 3)
	button.Disabled:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
	button.Disabled:SetTexCoord(8/32, 22/32, 10/32, 22/32)
	button:SetDisabledTexture(button.Disabled)
	Desaturation(button.Disabled, true)
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
	slider.Background:SetTexture(0, 0, 0, 0)
	slider:SetScript("OnEnter", NOOP)
	slider:SetScript("OnLeave", NOOP)
	slider:Disable()
end

TEMPLATE.EnableSlider = function(slider)
	slider.textMin:SetTextColor(0.8, 0.8, 0.8, 1)
	slider.textMax:SetTextColor(0.8, 0.8, 0.8, 1)
	slider.sliderBGL:SetTexCoord(unpack(Textures.SliderBG.coordsL))
	slider.sliderBGM:SetTexCoord(unpack(Textures.SliderBG.coordsM))
	slider.sliderBGR:SetTexCoord(unpack(Textures.SliderBG.coordsR))
	slider.thumb:SetTexCoord(unpack(Textures.SliderKnob.coords))
	slider:SetScript("OnEnter", function() slider.Background:SetTexture(1, 1, 1, 0.1) end)
	slider:SetScript("OnLeave", function() slider.Background:SetTexture(0, 0, 0, 0) end)
	slider:Enable()
end

TEMPLATE.Slider = function(slider, width, step, minVal, maxVal, curVal, func, measure)
	slider:SetWidth(width)
	slider:SetHeight(16)
	slider:SetValueStep(step) 
	slider:SetMinMaxValues(minVal, maxVal)
	slider:SetValue(curVal)
	slider:SetOrientation("HORIZONTAL")

	slider.Background = slider:CreateTexture(nil, "BACKGROUND")
	slider.Background:SetWidth(width)
	slider.Background:SetHeight(16)
	slider.Background:SetPoint("LEFT", 0, 0)
	slider.Background:SetTexture(0, 0, 0, 0)

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

	slider:SetScript("OnEnter", function() slider.Background:SetTexture(1, 1, 1, 0.1) end)
	slider:SetScript("OnLeave", function() slider.Background:SetTexture(0, 0, 0, 0) end)
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
	button.PullDownButtonText:SetTextColor(1, 1, 0.49, 1)

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
				func(button.value1) -- PDFUNC
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
		elseif contentName == "SortDetail" then
			button.PullDownMenu.Button[i].Text:SetText(sortDetail[i])
			button.PullDownMenu.Button[i].value1 = i	
		elseif contentName == "RangeType" then
			button.PullDownMenu.Button[i].Text:SetText(rangeTypeName[i])
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
function BattlegroundTargets:InitOptions()
	SlashCmdList["BATTLEGROUNDTARGETS"] = function()
		BattlegroundTargets:Frame_Toggle(GVAR.OptionsFrame)
	end
	SLASH_BATTLEGROUNDTARGETS1 = "/bgt"
	SLASH_BATTLEGROUNDTARGETS2 = "/bgtargets"
	SLASH_BATTLEGROUNDTARGETS3 = "/battlegroundtargets"

	if BattlegroundTargets_Options.version == nil then
		BattlegroundTargets_Options.version = 8
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
		if BattlegroundTargets_Options.ButtonShowCrosshairs then -- rename ButtonShowCrosshairs to ButtonShowTargetIndicator
			BattlegroundTargets_Options.ButtonShowTargetIndicator = {}
			if BattlegroundTargets_Options.ButtonShowCrosshairs[10] then BattlegroundTargets_Options.ButtonShowTargetIndicator[10] = true else BattlegroundTargets_Options.ButtonShowTargetIndicator[10] = false end
			if BattlegroundTargets_Options.ButtonShowCrosshairs[15] then BattlegroundTargets_Options.ButtonShowTargetIndicator[15] = true else BattlegroundTargets_Options.ButtonShowTargetIndicator[15] = false end
			if BattlegroundTargets_Options.ButtonShowCrosshairs[40] then BattlegroundTargets_Options.ButtonShowTargetIndicator[40] = true else BattlegroundTargets_Options.ButtonShowTargetIndicator[40] = false end
			BattlegroundTargets_Options.ButtonShowCrosshairs = nil
		end
		BattlegroundTargets_Options.version = 3
	end

	if BattlegroundTargets_Options.version == 3 then
		if BattlegroundTargets_Options.ButtonShowTargetIndicator then -- rename ButtonShowTargetIndicator to ButtonShowTarget
			BattlegroundTargets_Options.ButtonShowTarget = {}
			if BattlegroundTargets_Options.ButtonShowTargetIndicator[10] then BattlegroundTargets_Options.ButtonShowTarget[10] = true else BattlegroundTargets_Options.ButtonShowTarget[10] = false end
			if BattlegroundTargets_Options.ButtonShowTargetIndicator[15] then BattlegroundTargets_Options.ButtonShowTarget[15] = true else BattlegroundTargets_Options.ButtonShowTarget[15] = false end
			if BattlegroundTargets_Options.ButtonShowTargetIndicator[40] then BattlegroundTargets_Options.ButtonShowTarget[40] = true else BattlegroundTargets_Options.ButtonShowTarget[40] = false end
			BattlegroundTargets_Options.ButtonShowTargetIndicator = nil
		end
		if BattlegroundTargets_Options.ButtonShowFocusIndicator then -- rename ButtonShowFocusIndicator to ButtonShowFocus
			BattlegroundTargets_Options.ButtonShowFocus = {}
			if BattlegroundTargets_Options.ButtonShowFocusIndicator[10] then BattlegroundTargets_Options.ButtonShowFocus[10] = true else BattlegroundTargets_Options.ButtonShowFocus[10] = false end
			if BattlegroundTargets_Options.ButtonShowFocusIndicator[15] then BattlegroundTargets_Options.ButtonShowFocus[15] = true else BattlegroundTargets_Options.ButtonShowFocus[15] = false end
			if BattlegroundTargets_Options.ButtonShowFocusIndicator[40] then BattlegroundTargets_Options.ButtonShowFocus[40] = true else BattlegroundTargets_Options.ButtonShowFocus[40] = false end
			BattlegroundTargets_Options.ButtonShowFocusIndicator = nil
		end
		BattlegroundTargets_Options.version = 4
	end
	
	if BattlegroundTargets_Options.version == 4 then
		if BattlegroundTargets_Options.ButtonShowRealm then -- rename ButtonShowRealm to ButtonHideRealm
			BattlegroundTargets_Options.ButtonHideRealm = {}
			if BattlegroundTargets_Options.ButtonShowRealm[10] then BattlegroundTargets_Options.ButtonHideRealm[10] = false else BattlegroundTargets_Options.ButtonHideRealm[10] = true end
			if BattlegroundTargets_Options.ButtonShowRealm[15] then BattlegroundTargets_Options.ButtonHideRealm[15] = false else BattlegroundTargets_Options.ButtonHideRealm[15] = true end
			if BattlegroundTargets_Options.ButtonShowRealm[40] then BattlegroundTargets_Options.ButtonHideRealm[40] = false else BattlegroundTargets_Options.ButtonHideRealm[40] = true end
			BattlegroundTargets_Options.ButtonShowRealm = nil
		end
		BattlegroundTargets_Options.version = 5
	end

	if BattlegroundTargets_Options.version == 5 then
		if BattlegroundTargets_Options.ButtonSortBySize then -- rename ButtonSortBySize to ButtonSortBy
			BattlegroundTargets_Options.ButtonSortBy = {}
			if BattlegroundTargets_Options.ButtonSortBySize[10] then BattlegroundTargets_Options.ButtonSortBy[10] = BattlegroundTargets_Options.ButtonSortBySize[10] end
			if BattlegroundTargets_Options.ButtonSortBySize[15] then BattlegroundTargets_Options.ButtonSortBy[15] = BattlegroundTargets_Options.ButtonSortBySize[15] end
			if BattlegroundTargets_Options.ButtonSortBySize[40] then BattlegroundTargets_Options.ButtonSortBy[40] = BattlegroundTargets_Options.ButtonSortBySize[40] end
			BattlegroundTargets_Options.ButtonSortBySize = nil
		end
		local x
		if BattlegroundTargets_Options.ButtonTargetScale then
			if BattlegroundTargets_Options.ButtonTargetScale[10] > 2 then x=1 BattlegroundTargets_Options.ButtonTargetScale[10] = 2 end
			if BattlegroundTargets_Options.ButtonTargetScale[15] > 2 then x=1 BattlegroundTargets_Options.ButtonTargetScale[15] = 2 end
			if BattlegroundTargets_Options.ButtonTargetScale[40] > 2 then x=1 BattlegroundTargets_Options.ButtonTargetScale[40] = 2 end
		end
		if BattlegroundTargets_Options.ButtonFocusScale then
			if BattlegroundTargets_Options.ButtonFocusScale[10] > 2 then x=1 BattlegroundTargets_Options.ButtonFocusScale[10] = 2 end
			if BattlegroundTargets_Options.ButtonFocusScale[15] > 2 then x=1 BattlegroundTargets_Options.ButtonFocusScale[15] = 2 end
			if BattlegroundTargets_Options.ButtonFocusScale[40] > 2 then x=1 BattlegroundTargets_Options.ButtonFocusScale[40] = 2 end
		end
		if BattlegroundTargets_Options.ButtonFlagScale then
			if BattlegroundTargets_Options.ButtonFlagScale[10] > 2 then x=1 BattlegroundTargets_Options.ButtonFlagScale[10] = 2 end
			if BattlegroundTargets_Options.ButtonFlagScale[15] > 2 then x=1 BattlegroundTargets_Options.ButtonFlagScale[15] = 2 end
			if BattlegroundTargets_Options.ButtonFlagScale[40] > 2 then x=1 BattlegroundTargets_Options.ButtonFlagScale[40] = 2 end
		end
		if BattlegroundTargets_Options.ButtonAssistScale then
			if BattlegroundTargets_Options.ButtonAssistScale[10] > 2 then x=1 BattlegroundTargets_Options.ButtonAssistScale[10] = 2 end
			if BattlegroundTargets_Options.ButtonAssistScale[15] > 2 then x=1 BattlegroundTargets_Options.ButtonAssistScale[15] = 2 end
			if BattlegroundTargets_Options.ButtonAssistScale[40] > 2 then x=1 BattlegroundTargets_Options.ButtonAssistScale[40] = 2 end
		end
		if x then
			Print("Icon scale update! 200% is now maximum. Please check Configuration.")
		end
		BattlegroundTargets_Options.version = 6
	end

	if BattlegroundTargets_Options.version == 6 then
		if BattlegroundTargets_Options.ButtonShowHealthBar then -- update for health bar and health text independence
			if BattlegroundTargets_Options.ButtonShowHealthText[10] == true and BattlegroundTargets_Options.ButtonShowHealthBar[10] == false then
				BattlegroundTargets_Options.ButtonShowHealthText[10] = false
			end
			if BattlegroundTargets_Options.ButtonShowHealthText[15] == true and BattlegroundTargets_Options.ButtonShowHealthBar[15] == false then
				BattlegroundTargets_Options.ButtonShowHealthText[15] = false
			end
			if BattlegroundTargets_Options.ButtonShowHealthText[40] == true and BattlegroundTargets_Options.ButtonShowHealthBar[40] == false then
				BattlegroundTargets_Options.ButtonShowHealthText[40] = false
			end
		end
		BattlegroundTargets_Options.version = 7
	end

	if BattlegroundTargets_Options.version == 7 then
		if BattlegroundTargets_Options.ButtonEnableBracket then -- rename ButtonEnableBracket to EnableBracket
			BattlegroundTargets_Options.EnableBracket = {}
			if BattlegroundTargets_Options.ButtonEnableBracket[10] == true then BattlegroundTargets_Options.EnableBracket[10] = true else BattlegroundTargets_Options.EnableBracket[10] = false end
			if BattlegroundTargets_Options.ButtonEnableBracket[15] == true then BattlegroundTargets_Options.EnableBracket[15] = true else BattlegroundTargets_Options.EnableBracket[15] = false end
			if BattlegroundTargets_Options.ButtonEnableBracket[40] == true then BattlegroundTargets_Options.EnableBracket[40] = true else BattlegroundTargets_Options.EnableBracket[40] = false end
			BattlegroundTargets_Options.ButtonEnableBracket = nil
		end
		BattlegroundTargets_Options.version = 8
	end

	if BattlegroundTargets_Options.pos                        == nil then BattlegroundTargets_Options.pos                        = {}    end
	if BattlegroundTargets_Options.MinimapButton              == nil then BattlegroundTargets_Options.MinimapButton              = false end
	if BattlegroundTargets_Options.MinimapButtonPos           == nil then BattlegroundTargets_Options.MinimapButtonPos           = -90   end

	if BattlegroundTargets_Options.EnableBracket              == nil then BattlegroundTargets_Options.EnableBracket              = {}    end
	if BattlegroundTargets_Options.EnableBracket[10]          == nil then BattlegroundTargets_Options.EnableBracket[10]          = false end
	if BattlegroundTargets_Options.EnableBracket[15]          == nil then BattlegroundTargets_Options.EnableBracket[15]          = false end
	if BattlegroundTargets_Options.EnableBracket[40]          == nil then BattlegroundTargets_Options.EnableBracket[40]          = false end

	if BattlegroundTargets_Options.IndependentPositioning     == nil then BattlegroundTargets_Options.IndependentPositioning     = {}    end
	if BattlegroundTargets_Options.IndependentPositioning[10] == nil then BattlegroundTargets_Options.IndependentPositioning[10] = false end
	if BattlegroundTargets_Options.IndependentPositioning[15] == nil then BattlegroundTargets_Options.IndependentPositioning[15] = false end
	if BattlegroundTargets_Options.IndependentPositioning[40] == nil then BattlegroundTargets_Options.IndependentPositioning[40] = false end

	if BattlegroundTargets_Options.ButtonShowSpec             == nil then BattlegroundTargets_Options.ButtonShowSpec             = {}    end
	if BattlegroundTargets_Options.ButtonClassIcon            == nil then BattlegroundTargets_Options.ButtonClassIcon            = {}    end
	if BattlegroundTargets_Options.ButtonHideRealm            == nil then BattlegroundTargets_Options.ButtonHideRealm            = {}    end
	if BattlegroundTargets_Options.ButtonShowLeader           == nil then BattlegroundTargets_Options.ButtonShowLeader           = {}    end
	if BattlegroundTargets_Options.ButtonShowTarget           == nil then BattlegroundTargets_Options.ButtonShowTarget           = {}    end
	if BattlegroundTargets_Options.ButtonTargetScale          == nil then BattlegroundTargets_Options.ButtonTargetScale          = {}    end
	if BattlegroundTargets_Options.ButtonTargetPosition       == nil then BattlegroundTargets_Options.ButtonTargetPosition       = {}    end
	if BattlegroundTargets_Options.ButtonShowAssist           == nil then BattlegroundTargets_Options.ButtonShowAssist           = {}    end
	if BattlegroundTargets_Options.ButtonAssistScale          == nil then BattlegroundTargets_Options.ButtonAssistScale          = {}    end
	if BattlegroundTargets_Options.ButtonAssistPosition       == nil then BattlegroundTargets_Options.ButtonAssistPosition       = {}    end
	if BattlegroundTargets_Options.ButtonShowFocus            == nil then BattlegroundTargets_Options.ButtonShowFocus            = {}    end
	if BattlegroundTargets_Options.ButtonFocusScale           == nil then BattlegroundTargets_Options.ButtonFocusScale           = {}    end
	if BattlegroundTargets_Options.ButtonFocusPosition        == nil then BattlegroundTargets_Options.ButtonFocusPosition        = {}    end
	if BattlegroundTargets_Options.ButtonShowFlag             == nil then BattlegroundTargets_Options.ButtonShowFlag             = {}    end
	if BattlegroundTargets_Options.ButtonFlagScale            == nil then BattlegroundTargets_Options.ButtonFlagScale            = {}    end
	if BattlegroundTargets_Options.ButtonFlagPosition         == nil then BattlegroundTargets_Options.ButtonFlagPosition         = {}    end
	if BattlegroundTargets_Options.ButtonShowTargetCount      == nil then BattlegroundTargets_Options.ButtonShowTargetCount      = {}    end
	if BattlegroundTargets_Options.ButtonShowHealthBar        == nil then BattlegroundTargets_Options.ButtonShowHealthBar        = {}    end
	if BattlegroundTargets_Options.ButtonShowHealthText       == nil then BattlegroundTargets_Options.ButtonShowHealthText       = {}    end
	if BattlegroundTargets_Options.ButtonRangeCheck           == nil then BattlegroundTargets_Options.ButtonRangeCheck           = {}    end
	if BattlegroundTargets_Options.ButtonAvgRangeCheck        == nil then BattlegroundTargets_Options.ButtonAvgRangeCheck        = {}    end
	if BattlegroundTargets_Options.ButtonClassRangeCheck      == nil then BattlegroundTargets_Options.ButtonClassRangeCheck      = {}    end
	if BattlegroundTargets_Options.ButtonRangeAlpha           == nil then BattlegroundTargets_Options.ButtonRangeAlpha           = {}    end
	if BattlegroundTargets_Options.ButtonSortBy               == nil then BattlegroundTargets_Options.ButtonSortBy               = {}    end
	if BattlegroundTargets_Options.ButtonSortDetail           == nil then BattlegroundTargets_Options.ButtonSortDetail           = {}    end
	if BattlegroundTargets_Options.ButtonFontSize             == nil then BattlegroundTargets_Options.ButtonFontSize             = {}    end
	if BattlegroundTargets_Options.ButtonScale                == nil then BattlegroundTargets_Options.ButtonScale                = {}    end
	if BattlegroundTargets_Options.ButtonWidth                == nil then BattlegroundTargets_Options.ButtonWidth                = {}    end
	if BattlegroundTargets_Options.ButtonHeight               == nil then BattlegroundTargets_Options.ButtonHeight               = {}    end

	if BattlegroundTargets_Options.ButtonShowSpec[10]         == nil then BattlegroundTargets_Options.ButtonShowSpec[10]         = false end
	if BattlegroundTargets_Options.ButtonClassIcon[10]        == nil then BattlegroundTargets_Options.ButtonClassIcon[10]        = false end
	if BattlegroundTargets_Options.ButtonHideRealm[10]        == nil then BattlegroundTargets_Options.ButtonHideRealm[10]        = false end
	if BattlegroundTargets_Options.ButtonShowLeader[10]       == nil then BattlegroundTargets_Options.ButtonShowLeader[10]       = false end
	if BattlegroundTargets_Options.ButtonShowTarget[10]       == nil then BattlegroundTargets_Options.ButtonShowTarget[10]       = true  end
	if BattlegroundTargets_Options.ButtonTargetScale[10]      == nil then BattlegroundTargets_Options.ButtonTargetScale[10]      = 1.2   end
	if BattlegroundTargets_Options.ButtonTargetPosition[10]   == nil then BattlegroundTargets_Options.ButtonTargetPosition[10]   = 100   end
	if BattlegroundTargets_Options.ButtonShowAssist[10]       == nil then BattlegroundTargets_Options.ButtonShowAssist[10]       = false end
	if BattlegroundTargets_Options.ButtonAssistScale[10]      == nil then BattlegroundTargets_Options.ButtonAssistScale[10]      = 1.5   end
	if BattlegroundTargets_Options.ButtonAssistPosition[10]   == nil then BattlegroundTargets_Options.ButtonAssistPosition[10]   = 100   end
	if BattlegroundTargets_Options.ButtonShowFocus[10]        == nil then BattlegroundTargets_Options.ButtonShowFocus[10]        = false end
	if BattlegroundTargets_Options.ButtonFocusScale[10]       == nil then BattlegroundTargets_Options.ButtonFocusScale[10]       = 1     end
	if BattlegroundTargets_Options.ButtonFocusPosition[10]    == nil then BattlegroundTargets_Options.ButtonFocusPosition[10]    = 65    end
	if BattlegroundTargets_Options.ButtonShowFlag[10]         == nil then BattlegroundTargets_Options.ButtonShowFlag[10]         = false end
	if BattlegroundTargets_Options.ButtonFlagScale[10]        == nil then BattlegroundTargets_Options.ButtonFlagScale[10]        = 1.2   end
	if BattlegroundTargets_Options.ButtonFlagPosition[10]     == nil then BattlegroundTargets_Options.ButtonFlagPosition[10]     = 55    end
	if BattlegroundTargets_Options.ButtonShowTargetCount[10]  == nil then BattlegroundTargets_Options.ButtonShowTargetCount[10]  = false end
	if BattlegroundTargets_Options.ButtonShowHealthBar[10]    == nil then BattlegroundTargets_Options.ButtonShowHealthBar[10]    = false end
	if BattlegroundTargets_Options.ButtonShowHealthText[10]   == nil then BattlegroundTargets_Options.ButtonShowHealthText[10]   = false end
	if BattlegroundTargets_Options.ButtonRangeCheck[10]       == nil then BattlegroundTargets_Options.ButtonRangeCheck[10]       = false end
	if BattlegroundTargets_Options.ButtonAvgRangeCheck[10]    == nil then BattlegroundTargets_Options.ButtonAvgRangeCheck[10]    = false end
	if BattlegroundTargets_Options.ButtonClassRangeCheck[10]  == nil then BattlegroundTargets_Options.ButtonClassRangeCheck[10]  = true  end
	if BattlegroundTargets_Options.ButtonRangeAlpha[10]       == nil then BattlegroundTargets_Options.ButtonRangeAlpha[10]       = 1     end
	if BattlegroundTargets_Options.ButtonSortBy[10]           == nil then BattlegroundTargets_Options.ButtonSortBy[10]           = 1     end
	if BattlegroundTargets_Options.ButtonSortDetail[10]       == nil then BattlegroundTargets_Options.ButtonSortDetail[10]       = 3     end
	if BattlegroundTargets_Options.ButtonFontSize[10]         == nil then BattlegroundTargets_Options.ButtonFontSize[10]         = 12    end
	if BattlegroundTargets_Options.ButtonScale[10]            == nil then BattlegroundTargets_Options.ButtonScale[10]            = 1     end
	if BattlegroundTargets_Options.ButtonWidth[10]            == nil then BattlegroundTargets_Options.ButtonWidth[10]            = 160   end
	if BattlegroundTargets_Options.ButtonHeight[10]           == nil then BattlegroundTargets_Options.ButtonHeight[10]           = 20    end

	if BattlegroundTargets_Options.ButtonShowSpec[15]         == nil then BattlegroundTargets_Options.ButtonShowSpec[15]         = false end
	if BattlegroundTargets_Options.ButtonClassIcon[15]        == nil then BattlegroundTargets_Options.ButtonClassIcon[15]        = false end
	if BattlegroundTargets_Options.ButtonHideRealm[15]        == nil then BattlegroundTargets_Options.ButtonHideRealm[15]        = false end
	if BattlegroundTargets_Options.ButtonShowLeader[15]       == nil then BattlegroundTargets_Options.ButtonShowLeader[15]       = false end
	if BattlegroundTargets_Options.ButtonShowTarget[15]       == nil then BattlegroundTargets_Options.ButtonShowTarget[15]       = true  end
	if BattlegroundTargets_Options.ButtonTargetScale[15]      == nil then BattlegroundTargets_Options.ButtonTargetScale[15]      = 1.2   end
	if BattlegroundTargets_Options.ButtonTargetPosition[15]   == nil then BattlegroundTargets_Options.ButtonTargetPosition[15]   = 100   end
	if BattlegroundTargets_Options.ButtonShowAssist[15]       == nil then BattlegroundTargets_Options.ButtonShowAssist[15]       = false end
	if BattlegroundTargets_Options.ButtonAssistScale[15]      == nil then BattlegroundTargets_Options.ButtonAssistScale[15]      = 1.5   end
	if BattlegroundTargets_Options.ButtonAssistPosition[15]   == nil then BattlegroundTargets_Options.ButtonAssistPosition[15]   = 100   end
	if BattlegroundTargets_Options.ButtonShowFocus[15]        == nil then BattlegroundTargets_Options.ButtonShowFocus[15]        = false end
	if BattlegroundTargets_Options.ButtonFocusScale[15]       == nil then BattlegroundTargets_Options.ButtonFocusScale[15]       = 1     end
	if BattlegroundTargets_Options.ButtonFocusPosition[15]    == nil then BattlegroundTargets_Options.ButtonFocusPosition[15]    = 65    end
	if BattlegroundTargets_Options.ButtonShowFlag[15]         == nil then BattlegroundTargets_Options.ButtonShowFlag[15]         = false end
	if BattlegroundTargets_Options.ButtonFlagScale[15]        == nil then BattlegroundTargets_Options.ButtonFlagScale[15]        = 1.2   end
	if BattlegroundTargets_Options.ButtonFlagPosition[15]     == nil then BattlegroundTargets_Options.ButtonFlagPosition[15]     = 55    end
	if BattlegroundTargets_Options.ButtonShowTargetCount[15]  == nil then BattlegroundTargets_Options.ButtonShowTargetCount[15]  = false end
	if BattlegroundTargets_Options.ButtonShowHealthBar[15]    == nil then BattlegroundTargets_Options.ButtonShowHealthBar[15]    = false end
	if BattlegroundTargets_Options.ButtonShowHealthText[15]   == nil then BattlegroundTargets_Options.ButtonShowHealthText[15]   = false end
	if BattlegroundTargets_Options.ButtonRangeCheck[15]       == nil then BattlegroundTargets_Options.ButtonRangeCheck[15]       = false end
	if BattlegroundTargets_Options.ButtonAvgRangeCheck[15]    == nil then BattlegroundTargets_Options.ButtonAvgRangeCheck[15]    = false end
	if BattlegroundTargets_Options.ButtonClassRangeCheck[15]  == nil then BattlegroundTargets_Options.ButtonClassRangeCheck[15]  = true  end
	if BattlegroundTargets_Options.ButtonRangeAlpha[15]       == nil then BattlegroundTargets_Options.ButtonRangeAlpha[15]       = 1     end
	if BattlegroundTargets_Options.ButtonSortBy[15]           == nil then BattlegroundTargets_Options.ButtonSortBy[15]           = 1     end
	if BattlegroundTargets_Options.ButtonSortDetail[15]       == nil then BattlegroundTargets_Options.ButtonSortDetail[15]       = 3     end
	if BattlegroundTargets_Options.ButtonFontSize[15]         == nil then BattlegroundTargets_Options.ButtonFontSize[15]         = 12    end
	if BattlegroundTargets_Options.ButtonScale[15]            == nil then BattlegroundTargets_Options.ButtonScale[15]            = 1     end
	if BattlegroundTargets_Options.ButtonWidth[15]            == nil then BattlegroundTargets_Options.ButtonWidth[15]            = 160   end
	if BattlegroundTargets_Options.ButtonHeight[15]           == nil then BattlegroundTargets_Options.ButtonHeight[15]           = 20    end

	if BattlegroundTargets_Options.ButtonShowSpec[40]         == nil then BattlegroundTargets_Options.ButtonShowSpec[40]         = false end
	if BattlegroundTargets_Options.ButtonClassIcon[40]        == nil then BattlegroundTargets_Options.ButtonClassIcon[40]        = false end
	if BattlegroundTargets_Options.ButtonHideRealm[40]        == nil then BattlegroundTargets_Options.ButtonHideRealm[40]        = false end
	if BattlegroundTargets_Options.ButtonShowLeader[40]       == nil then BattlegroundTargets_Options.ButtonShowLeader[40]       = false end
	if BattlegroundTargets_Options.ButtonShowTarget[40]       == nil then BattlegroundTargets_Options.ButtonShowTarget[40]       = true  end
	if BattlegroundTargets_Options.ButtonTargetScale[40]      == nil then BattlegroundTargets_Options.ButtonTargetScale[40]      = 1     end
	if BattlegroundTargets_Options.ButtonTargetPosition[40]   == nil then BattlegroundTargets_Options.ButtonTargetPosition[40]   = 100   end
	if BattlegroundTargets_Options.ButtonShowAssist[40]       == nil then BattlegroundTargets_Options.ButtonShowAssist[40]       = false end
	if BattlegroundTargets_Options.ButtonAssistScale[40]      == nil then BattlegroundTargets_Options.ButtonAssistScale[40]      = 1     end
	if BattlegroundTargets_Options.ButtonAssistPosition[40]   == nil then BattlegroundTargets_Options.ButtonAssistPosition[40]   = 75    end
	if BattlegroundTargets_Options.ButtonShowFocus[40]        == nil then BattlegroundTargets_Options.ButtonShowFocus[40]        = false end
	if BattlegroundTargets_Options.ButtonFocusScale[40]       == nil then BattlegroundTargets_Options.ButtonFocusScale[40]       = 1     end
	if BattlegroundTargets_Options.ButtonFocusPosition[40]    == nil then BattlegroundTargets_Options.ButtonFocusPosition[40]    = 65    end
	if BattlegroundTargets_Options.ButtonShowFlag[40]         == nil then BattlegroundTargets_Options.ButtonShowFlag[40]         = false end
	if BattlegroundTargets_Options.ButtonFlagScale[40]        == nil then BattlegroundTargets_Options.ButtonFlagScale[40]        = 1     end
	if BattlegroundTargets_Options.ButtonFlagPosition[40]     == nil then BattlegroundTargets_Options.ButtonFlagPosition[40]     = 100   end
	if BattlegroundTargets_Options.ButtonShowTargetCount[40]  == nil then BattlegroundTargets_Options.ButtonShowTargetCount[40]  = false end
	if BattlegroundTargets_Options.ButtonShowHealthBar[40]    == nil then BattlegroundTargets_Options.ButtonShowHealthBar[40]    = false end
	if BattlegroundTargets_Options.ButtonShowHealthText[40]   == nil then BattlegroundTargets_Options.ButtonShowHealthText[40]   = false end
	if BattlegroundTargets_Options.ButtonRangeCheck[40]       == nil then BattlegroundTargets_Options.ButtonRangeCheck[40]       = false end
	if BattlegroundTargets_Options.ButtonAvgRangeCheck[40]    == nil then BattlegroundTargets_Options.ButtonAvgRangeCheck[40]    = false end
	if BattlegroundTargets_Options.ButtonClassRangeCheck[40]  == nil then BattlegroundTargets_Options.ButtonClassRangeCheck[40]  = true  end
	if BattlegroundTargets_Options.ButtonRangeAlpha[40]       == nil then BattlegroundTargets_Options.ButtonRangeAlpha[40]       = 1     end
	if BattlegroundTargets_Options.ButtonSortBy[40]           == nil then BattlegroundTargets_Options.ButtonSortBy[40]           = 1     end
	if BattlegroundTargets_Options.ButtonSortDetail[40]       == nil then BattlegroundTargets_Options.ButtonSortDetail[40]       = 3     end
	if BattlegroundTargets_Options.ButtonFontSize[40]         == nil then BattlegroundTargets_Options.ButtonFontSize[40]         = 10    end
	if BattlegroundTargets_Options.ButtonScale[40]            == nil then BattlegroundTargets_Options.ButtonScale[40]            = 0.9   end
	if BattlegroundTargets_Options.ButtonWidth[40]            == nil then BattlegroundTargets_Options.ButtonWidth[40]            = 80    end
	if BattlegroundTargets_Options.ButtonHeight[40]           == nil then BattlegroundTargets_Options.ButtonHeight[40]           = 16    end

	for i = 1, #bgSizeINT do
		if not OPT.ButtonShowSpec        then OPT.ButtonShowSpec        = {} end OPT.ButtonShowSpec[ bgSizeINT[i] ]        = BattlegroundTargets_Options.ButtonShowSpec[ bgSizeINT[i] ]       
		if not OPT.ButtonClassIcon       then OPT.ButtonClassIcon       = {} end OPT.ButtonClassIcon[ bgSizeINT[i] ]       = BattlegroundTargets_Options.ButtonClassIcon[ bgSizeINT[i] ]      
		if not OPT.ButtonHideRealm       then OPT.ButtonHideRealm       = {} end OPT.ButtonHideRealm[ bgSizeINT[i] ]       = BattlegroundTargets_Options.ButtonHideRealm[ bgSizeINT[i] ]      
		if not OPT.ButtonShowLeader      then OPT.ButtonShowLeader      = {} end OPT.ButtonShowLeader[ bgSizeINT[i] ]      = BattlegroundTargets_Options.ButtonShowLeader[ bgSizeINT[i] ]     
		if not OPT.ButtonShowTarget      then OPT.ButtonShowTarget      = {} end OPT.ButtonShowTarget[ bgSizeINT[i] ]      = BattlegroundTargets_Options.ButtonShowTarget[ bgSizeINT[i] ]     
		if not OPT.ButtonTargetScale     then OPT.ButtonTargetScale     = {} end OPT.ButtonTargetScale[ bgSizeINT[i] ]     = BattlegroundTargets_Options.ButtonTargetScale[ bgSizeINT[i] ]    
		if not OPT.ButtonTargetPosition  then OPT.ButtonTargetPosition  = {} end OPT.ButtonTargetPosition[ bgSizeINT[i] ]  = BattlegroundTargets_Options.ButtonTargetPosition[ bgSizeINT[i] ] 
		if not OPT.ButtonShowAssist      then OPT.ButtonShowAssist      = {} end OPT.ButtonShowAssist[ bgSizeINT[i] ]      = BattlegroundTargets_Options.ButtonShowAssist[ bgSizeINT[i] ]     
		if not OPT.ButtonAssistScale     then OPT.ButtonAssistScale     = {} end OPT.ButtonAssistScale[ bgSizeINT[i] ]     = BattlegroundTargets_Options.ButtonAssistScale[ bgSizeINT[i] ]    
		if not OPT.ButtonAssistPosition  then OPT.ButtonAssistPosition  = {} end OPT.ButtonAssistPosition[ bgSizeINT[i] ]  = BattlegroundTargets_Options.ButtonAssistPosition[ bgSizeINT[i] ] 
		if not OPT.ButtonShowFocus       then OPT.ButtonShowFocus       = {} end OPT.ButtonShowFocus[ bgSizeINT[i] ]       = BattlegroundTargets_Options.ButtonShowFocus[ bgSizeINT[i] ]      
		if not OPT.ButtonFocusScale      then OPT.ButtonFocusScale      = {} end OPT.ButtonFocusScale[ bgSizeINT[i] ]      = BattlegroundTargets_Options.ButtonFocusScale[ bgSizeINT[i] ]     
		if not OPT.ButtonFocusPosition   then OPT.ButtonFocusPosition   = {} end OPT.ButtonFocusPosition[ bgSizeINT[i] ]   = BattlegroundTargets_Options.ButtonFocusPosition[ bgSizeINT[i] ]  
		if not OPT.ButtonShowFlag        then OPT.ButtonShowFlag        = {} end OPT.ButtonShowFlag[ bgSizeINT[i] ]        = BattlegroundTargets_Options.ButtonShowFlag[ bgSizeINT[i] ]       
		if not OPT.ButtonFlagScale       then OPT.ButtonFlagScale       = {} end OPT.ButtonFlagScale[ bgSizeINT[i] ]       = BattlegroundTargets_Options.ButtonFlagScale[ bgSizeINT[i] ]      
		if not OPT.ButtonFlagPosition    then OPT.ButtonFlagPosition    = {} end OPT.ButtonFlagPosition[ bgSizeINT[i] ]    = BattlegroundTargets_Options.ButtonFlagPosition[ bgSizeINT[i] ]   
		if not OPT.ButtonShowTargetCount then OPT.ButtonShowTargetCount = {} end OPT.ButtonShowTargetCount[ bgSizeINT[i] ] = BattlegroundTargets_Options.ButtonShowTargetCount[ bgSizeINT[i] ]
		if not OPT.ButtonShowHealthBar   then OPT.ButtonShowHealthBar   = {} end OPT.ButtonShowHealthBar[ bgSizeINT[i] ]   = BattlegroundTargets_Options.ButtonShowHealthBar[ bgSizeINT[i] ]  
		if not OPT.ButtonShowHealthText  then OPT.ButtonShowHealthText  = {} end OPT.ButtonShowHealthText[ bgSizeINT[i] ]  = BattlegroundTargets_Options.ButtonShowHealthText[ bgSizeINT[i] ] 
		if not OPT.ButtonRangeCheck      then OPT.ButtonRangeCheck      = {} end OPT.ButtonRangeCheck[ bgSizeINT[i] ]      = BattlegroundTargets_Options.ButtonRangeCheck[ bgSizeINT[i] ]     
		if not OPT.ButtonAvgRangeCheck   then OPT.ButtonAvgRangeCheck   = {} end OPT.ButtonAvgRangeCheck[ bgSizeINT[i] ]   = BattlegroundTargets_Options.ButtonAvgRangeCheck[ bgSizeINT[i] ]  
		if not OPT.ButtonClassRangeCheck then OPT.ButtonClassRangeCheck = {} end OPT.ButtonClassRangeCheck[ bgSizeINT[i] ] = BattlegroundTargets_Options.ButtonClassRangeCheck[ bgSizeINT[i] ]
		if not OPT.ButtonRangeAlpha      then OPT.ButtonRangeAlpha      = {} end OPT.ButtonRangeAlpha[ bgSizeINT[i] ]      = BattlegroundTargets_Options.ButtonRangeAlpha[ bgSizeINT[i] ]     
		if not OPT.ButtonSortBy          then OPT.ButtonSortBy          = {} end OPT.ButtonSortBy[ bgSizeINT[i] ]          = BattlegroundTargets_Options.ButtonSortBy[ bgSizeINT[i] ]         
		if not OPT.ButtonSortDetail      then OPT.ButtonSortDetail      = {} end OPT.ButtonSortDetail[ bgSizeINT[i] ]      = BattlegroundTargets_Options.ButtonSortDetail[ bgSizeINT[i] ]     
		if not OPT.ButtonFontSize        then OPT.ButtonFontSize        = {} end OPT.ButtonFontSize[ bgSizeINT[i] ]        = BattlegroundTargets_Options.ButtonFontSize[ bgSizeINT[i] ]       
		if not OPT.ButtonScale           then OPT.ButtonScale           = {} end OPT.ButtonScale[ bgSizeINT[i] ]           = BattlegroundTargets_Options.ButtonScale[ bgSizeINT[i] ]          
		if not OPT.ButtonWidth           then OPT.ButtonWidth           = {} end OPT.ButtonWidth[ bgSizeINT[i] ]           = BattlegroundTargets_Options.ButtonWidth[ bgSizeINT[i] ]          
		if not OPT.ButtonHeight          then OPT.ButtonHeight          = {} end OPT.ButtonHeight[ bgSizeINT[i] ]          = BattlegroundTargets_Options.ButtonHeight[ bgSizeINT[i] ]         
	end	
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
		self.HighlightT:SetTexture(1, 1, 0.49, 1)
		self.HighlightR:SetTexture(1, 1, 0.49, 1)
		self.HighlightB:SetTexture(1, 1, 0.49, 1)
		self.HighlightL:SetTexture(1, 1, 0.49, 1)
		--BattlegroundTargets:BruteForceUpdate()
	end
	local function OnLeave(self)
		if isTarget == self.buttonNum then
			self.HighlightT:SetTexture(0.5, 0.5, 0.5, 1)
			self.HighlightR:SetTexture(0.5, 0.5, 0.5, 1)
			self.HighlightB:SetTexture(0.5, 0.5, 0.5, 1)
			self.HighlightL:SetTexture(0.5, 0.5, 0.5, 1)
		else
			self.HighlightT:SetTexture(0, 0, 0, 1)
			self.HighlightR:SetTexture(0, 0, 0, 1)
			self.HighlightB:SetTexture(0, 0, 0, 1)
			self.HighlightL:SetTexture(0, 0, 0, 1)
		end
	end

	local buttonWidth = 150
	local buttonHeight = 20

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

		GVAR.TargetButton[i].HighlightT = GVAR.TargetButton[i]:CreateTexture(nil, "BACKGROUND")
		GVAR.TargetButton[i].HighlightT:SetWidth(buttonWidth)
		GVAR.TargetButton[i].HighlightT:SetHeight(1)
		GVAR.TargetButton[i].HighlightT:SetPoint("TOP", 0, 0)
		GVAR.TargetButton[i].HighlightT:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].HighlightR = GVAR.TargetButton[i]:CreateTexture(nil, "BACKGROUND")
		GVAR.TargetButton[i].HighlightR:SetWidth(1)
		GVAR.TargetButton[i].HighlightR:SetHeight(buttonHeight)
		GVAR.TargetButton[i].HighlightR:SetPoint("RIGHT", 0, 0)
		GVAR.TargetButton[i].HighlightR:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].HighlightB = GVAR.TargetButton[i]:CreateTexture(nil, "BACKGROUND")
		GVAR.TargetButton[i].HighlightB:SetWidth(buttonWidth)
		GVAR.TargetButton[i].HighlightB:SetHeight(1)
		GVAR.TargetButton[i].HighlightB:SetPoint("BOTTOM", 0, 0)
		GVAR.TargetButton[i].HighlightB:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].HighlightL = GVAR.TargetButton[i]:CreateTexture(nil, "BACKGROUND")
		GVAR.TargetButton[i].HighlightL:SetWidth(1)
		GVAR.TargetButton[i].HighlightL:SetHeight(buttonHeight)
		GVAR.TargetButton[i].HighlightL:SetPoint("LEFT", 0, 0)
		GVAR.TargetButton[i].HighlightL:SetTexture(0, 0, 0, 1)

		GVAR.TargetButton[i].Background = GVAR.TargetButton[i]:CreateTexture(nil, "BACKGROUND")
		GVAR.TargetButton[i].Background:SetWidth(buttonWidth-2)
		GVAR.TargetButton[i].Background:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].Background:SetPoint("TOPLEFT", 1, -1)
		GVAR.TargetButton[i].Background:SetTexture(0, 0, 0, 1)

		GVAR.TargetButton[i].RangeTexture = GVAR.TargetButton[i]:CreateTexture(nil, "BORDER")
		GVAR.TargetButton[i].RangeTexture:SetWidth((buttonHeight-2)/2)
		GVAR.TargetButton[i].RangeTexture:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].RangeTexture:SetPoint("LEFT", GVAR.TargetButton[i], "LEFT", 1, 0)
		GVAR.TargetButton[i].RangeTexture:SetTexture(0, 0, 0, 0)

		GVAR.TargetButton[i].RoleTexture = GVAR.TargetButton[i]:CreateTexture(nil, "BORDER")
		GVAR.TargetButton[i].RoleTexture:SetWidth(buttonHeight-2)
		GVAR.TargetButton[i].RoleTexture:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].RoleTexture:SetPoint("LEFT", GVAR.TargetButton[i].RangeTexture, "RIGHT", 0, 0)
		GVAR.TargetButton[i].RoleTexture:SetTexture(Textures.BattlegroundTargetsIcons.path)

		GVAR.TargetButton[i].SpecTexture = GVAR.TargetButton[i]:CreateTexture(nil, "BORDER")
		GVAR.TargetButton[i].SpecTexture:SetWidth(buttonHeight-2)
		GVAR.TargetButton[i].SpecTexture:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].SpecTexture:SetPoint("LEFT", GVAR.TargetButton[i].RoleTexture, "RIGHT", 0, 0)
		GVAR.TargetButton[i].SpecTexture:SetTexCoord(0.07812501, 0.92187499, 0.07812501, 0.92187499)--(5/64, 59/64, 5/64, 59/64)

		GVAR.TargetButton[i].ClassTexture = GVAR.TargetButton[i]:CreateTexture(nil, "BORDER")
		GVAR.TargetButton[i].ClassTexture:SetWidth(buttonHeight-2)
		GVAR.TargetButton[i].ClassTexture:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].ClassTexture:SetPoint("LEFT", GVAR.TargetButton[i].SpecTexture, "RIGHT", 0, 0)
		GVAR.TargetButton[i].ClassTexture:SetTexture(classimg)

		GVAR.TargetButton[i].LeaderTexture = GVAR.TargetButton[i]:CreateTexture(nil, "ARTWORK")
		GVAR.TargetButton[i].LeaderTexture:SetWidth((buttonHeight-2)/1.5)
		GVAR.TargetButton[i].LeaderTexture:SetHeight((buttonHeight-2)/1.5)
		GVAR.TargetButton[i].LeaderTexture:SetPoint("LEFT", GVAR.TargetButton[i], "LEFT", -((buttonHeight-2)/1.5)/2, 0)
		GVAR.TargetButton[i].LeaderTexture:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
		GVAR.TargetButton[i].LeaderTexture:SetAlpha(0)

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

		GVAR.TargetButton[i].TargetCountBackground = GVAR.TargetButton[i]:CreateTexture(nil, "ARTWORK")--(nil, "BORDER")
		GVAR.TargetButton[i].TargetCountBackground:SetWidth(20)
		GVAR.TargetButton[i].TargetCountBackground:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].TargetCountBackground:SetPoint("RIGHT", GVAR.TargetButton[i], "RIGHT", -1, 0)
		GVAR.TargetButton[i].TargetCountBackground:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].TargetCountBackground:SetAlpha(1)

		GVAR.TargetButton[i].TargetCount = GVAR.TargetButton[i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		GVAR.TargetButton[i].TargetCount:SetWidth(20)
		GVAR.TargetButton[i].TargetCount:SetHeight(buttonHeight-4)
		GVAR.TargetButton[i].TargetCount:SetPoint("CENTER", GVAR.TargetButton[i].TargetCountBackground, "CENTER", 0, 0)
		GVAR.TargetButton[i].TargetCount:SetJustifyH("CENTER")

		GVAR.TargetButton[i].TargetTexture = GVAR.TargetButton[i]:CreateTexture(nil, "OVERLAY")
		GVAR.TargetButton[i].TargetTexture:SetWidth(buttonHeight-2)
		GVAR.TargetButton[i].TargetTexture:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].TargetTexture:SetPoint("LEFT", GVAR.TargetButton[i], "RIGHT", 0, 0)
		GVAR.TargetButton[i].TargetTexture:SetTexture(AddonIcon)
		GVAR.TargetButton[i].TargetTexture:SetAlpha(0)

		GVAR.TargetButton[i].FocusTexture = GVAR.TargetButton[i]:CreateTexture(nil, "OVERLAY")
		GVAR.TargetButton[i].FocusTexture:SetWidth(buttonHeight-2)
		GVAR.TargetButton[i].FocusTexture:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].FocusTexture:SetPoint("LEFT", GVAR.TargetButton[i], "RIGHT", 0, 0)
		GVAR.TargetButton[i].FocusTexture:SetTexture("Interface\\Minimap\\Tracking\\Focus")
		GVAR.TargetButton[i].FocusTexture:SetTexCoord(0.03125001, 0.96874999, 0.03125001, 0.96874999)--(1/32, 31/32, 1/32, 31/32)
		GVAR.TargetButton[i].FocusTexture:SetAlpha(0)

		GVAR.TargetButton[i].FlagTexture = GVAR.TargetButton[i]:CreateTexture(nil, "OVERLAY")
		GVAR.TargetButton[i].FlagTexture:SetWidth(buttonHeight-2)
		GVAR.TargetButton[i].FlagTexture:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].FlagTexture:SetPoint("LEFT", GVAR.TargetButton[i], "RIGHT", 0, 0)
		GVAR.TargetButton[i].FlagTexture:SetTexCoord(0.15625001, 0.84374999, 0.15625001, 0.84374999)--(5/32, 27/32, 5/32, 27/32)
		if playerFactionDEF == 0 then -- setup_flag_texture
			GVAR.TargetButton[i].FlagTexture:SetTexture("Interface\\WorldStateFrame\\HordeFlag")
		else
			GVAR.TargetButton[i].FlagTexture:SetTexture("Interface\\WorldStateFrame\\AllianceFlag")
		end
		GVAR.TargetButton[i].FlagTexture:SetAlpha(0)

		GVAR.TargetButton[i].AssistTexture = GVAR.TargetButton[i]:CreateTexture(nil, "OVERLAY")
		GVAR.TargetButton[i].AssistTexture:SetWidth(buttonHeight-2)
		GVAR.TargetButton[i].AssistTexture:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].AssistTexture:SetPoint("LEFT", GVAR.TargetButton[i], "RIGHT", 0, 0)
		GVAR.TargetButton[i].AssistTexture:SetTexCoord(0.07812501, 0.92187499, 0.07812501, 0.92187499)--(5/64, 59/64, 5/64, 59/64)
		GVAR.TargetButton[i].AssistTexture:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
		GVAR.TargetButton[i].AssistTexture:SetAlpha(0)

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
	GVAR.WorldStateScoreWarning.Texture1:SetWidth(62)
	GVAR.WorldStateScoreWarning.Texture1:SetHeight(54)
	GVAR.WorldStateScoreWarning.Texture1:SetPoint("LEFT", GVAR.WorldStateScoreWarning, "LEFT", 12.5, 0)
	GVAR.WorldStateScoreWarning.Texture1:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
	GVAR.WorldStateScoreWarning.Texture1:SetTexCoord(1/64, 63/64, 1/64, 55/64)

	GVAR.WorldStateScoreWarning.Texture2 = GVAR.WorldStateScoreWarning:CreateTexture(nil, "ARTWORK")
	GVAR.WorldStateScoreWarning.Texture2:SetWidth(62)
	GVAR.WorldStateScoreWarning.Texture2:SetHeight(54)
	GVAR.WorldStateScoreWarning.Texture2:SetPoint("RIGHT", GVAR.WorldStateScoreWarning, "RIGHT", -12.5, 0)
	GVAR.WorldStateScoreWarning.Texture2:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
	GVAR.WorldStateScoreWarning.Texture2:SetTexCoord(1/64, 63/64, 1/64, 55/64)

	GVAR.WorldStateScoreWarning.Text = GVAR.WorldStateScoreWarning:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	GVAR.WorldStateScoreWarning.Text:SetWidth(250)
	GVAR.WorldStateScoreWarning.Text:SetHeight(60)
	GVAR.WorldStateScoreWarning.Text:SetPoint("CENTER", 0, 0)
	GVAR.WorldStateScoreWarning.Text:SetJustifyH("CENTER")
	GVAR.WorldStateScoreWarning.Text:SetText(L["BattlegroundTargets does not update if this Tab is opened."])

	GVAR.WorldStateScoreWarning.Close = CreateFrame("Button", nil, GVAR.WorldStateScoreWarning)
	TEMPLATE.IconButton(GVAR.WorldStateScoreWarning.Close, 1)
	GVAR.WorldStateScoreWarning.Close:SetWidth(20)
	GVAR.WorldStateScoreWarning.Close:SetHeight(20)
	GVAR.WorldStateScoreWarning.Close:SetPoint("TOPRIGHT", GVAR.WorldStateScoreWarning, "TOPRIGHT", 0, 0)
	GVAR.WorldStateScoreWarning.Close:SetScript("OnClick", function() GVAR.WorldStateScoreWarning:Hide() end)
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:CreateOptionsFrame()
	if BattlegroundTargets_OptionsFrame then return end

	BattlegroundTargets:DefaultShuffle()

	local frameWidth  = 480
	local frameHeight = 631
	local tabWidth = math_floor( (frameWidth/3)-10 )

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

	-- tabs
	local w1 = ( frameWidth-(3*tabWidth)-(2*5) ) / 2

	GVAR.OptionsFrame.TestRaidSize10 = CreateFrame("Button", nil, GVAR.OptionsFrame.Base)
	TEMPLATE.TabButton(GVAR.OptionsFrame.TestRaidSize10, L["10 vs 10"], BattlegroundTargets_Options.EnableBracket[10])
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
		if BattlegroundTargets_Options.EnableBracket[testSize] then
			BattlegroundTargets:EnableConfigMode()
		else
			BattlegroundTargets:DisableConfigMode()
		end
	end)

	GVAR.OptionsFrame.TestRaidSize15 = CreateFrame("Button", nil, GVAR.OptionsFrame.Base)
	TEMPLATE.TabButton(GVAR.OptionsFrame.TestRaidSize15, L["15 vs 15"], BattlegroundTargets_Options.EnableBracket[15])
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
		if BattlegroundTargets_Options.EnableBracket[testSize] then
			BattlegroundTargets:EnableConfigMode()
		else
			BattlegroundTargets:DisableConfigMode()
		end
	end)

	GVAR.OptionsFrame.TestRaidSize40 = CreateFrame("Button", nil, GVAR.OptionsFrame.Base)
	TEMPLATE.TabButton(GVAR.OptionsFrame.TestRaidSize40, L["40 vs 40"], BattlegroundTargets_Options.EnableBracket[40])
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
		if BattlegroundTargets_Options.EnableBracket[testSize] then
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



	-- enable bracket
	GVAR.OptionsFrame.EnableBracket = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.EnableBracket, 16, 4, L["Enable"])
	GVAR.OptionsFrame.EnableBracket:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.EnableBracket:SetPoint("TOP", GVAR.OptionsFrame.Base, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.EnableBracket:SetChecked(BattlegroundTargets_Options.EnableBracket[currentSize])
	GVAR.OptionsFrame.EnableBracket:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.EnableBracket[currentSize] = not BattlegroundTargets_Options.EnableBracket[currentSize]
		GVAR.OptionsFrame.EnableBracket:SetChecked(BattlegroundTargets_Options.EnableBracket[currentSize])
		BattlegroundTargets:CheckForEnabledBracket(currentSize)
		if BattlegroundTargets_Options.EnableBracket[currentSize] then
			BattlegroundTargets:EnableConfigMode()
		else
			BattlegroundTargets:DisableConfigMode()
		end
	end)

	-- independent positioning
	GVAR.OptionsFrame.IndependentPos = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.IndependentPos, 16, 4, L["Independent Positioning"])
	GVAR.OptionsFrame.IndependentPos:SetPoint("LEFT", GVAR.OptionsFrame.EnableBracket, "RIGHT", 50, 0)
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



	GVAR.OptionsFrame.Dummy1 = CreateFrame("Frame", nil, GVAR.OptionsFrame)
	TEMPLATE.BorderTRBL(GVAR.OptionsFrame.Dummy1)
	GVAR.OptionsFrame.Dummy1:SetWidth(frameWidth-26-26)
	GVAR.OptionsFrame.Dummy1:SetHeight(1)
	GVAR.OptionsFrame.Dummy1:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 26, 0)
	GVAR.OptionsFrame.Dummy1:SetPoint("TOP", GVAR.OptionsFrame.IndependentPos, "BOTTOM", 0, -10)



	-- copy settings
	GVAR.OptionsFrame.CopySettings = CreateFrame("Button", nil, GVAR.OptionsFrame)
	TEMPLATE.TextButton(GVAR.OptionsFrame.CopySettings, string_format(L["Copy this settings to '%s'"], L["15 vs 15"]), 4)
	GVAR.OptionsFrame.CopySettings:SetPoint("TOP", GVAR.OptionsFrame.Dummy1, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.CopySettings:SetWidth(GVAR.OptionsFrame.CopySettings:GetTextWidth()+40)
	GVAR.OptionsFrame.CopySettings:SetHeight(20)
	GVAR.OptionsFrame.CopySettings:SetScript("OnClick", function() BattlegroundTargets:CopySettings(currentSize) end)

	-- show spec
	GVAR.OptionsFrame.ShowSpec = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowSpec, 16, 4, L["Show Specialization"])
	GVAR.OptionsFrame.ShowSpec:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ShowSpec:SetPoint("TOP", GVAR.OptionsFrame.CopySettings, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ShowSpec:SetChecked(OPT.ButtonShowSpec[currentSize])
	GVAR.OptionsFrame.ShowSpec:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowSpec[currentSize] = not BattlegroundTargets_Options.ButtonShowSpec[currentSize]
		                        OPT.ButtonShowSpec[currentSize] = not                         OPT.ButtonShowSpec[currentSize]
		GVAR.OptionsFrame.ShowSpec:SetChecked(OPT.ButtonShowSpec[currentSize])
		BattlegroundTargets:EnableConfigMode()
	end)

	-- class icon
	GVAR.OptionsFrame.ClassIcon = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ClassIcon, 16, 4, L["Show Class Icon"])
	GVAR.OptionsFrame.ClassIcon:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ClassIcon:SetPoint("TOP", GVAR.OptionsFrame.ShowSpec, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ClassIcon:SetChecked(OPT.ButtonClassIcon[currentSize])
	GVAR.OptionsFrame.ClassIcon:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonClassIcon[currentSize] = not BattlegroundTargets_Options.ButtonClassIcon[currentSize]
		                        OPT.ButtonClassIcon[currentSize] = not                         OPT.ButtonClassIcon[currentSize]
		GVAR.OptionsFrame.ClassIcon:SetChecked(OPT.ButtonClassIcon[currentSize])
		BattlegroundTargets:EnableConfigMode()
	end)

	-- show leader
	GVAR.OptionsFrame.ShowLeader = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowLeader, 16, 4, L["Show Leader"])
	GVAR.OptionsFrame.ShowLeader:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", (frameWidth-10-10)/2, 0)
	GVAR.OptionsFrame.ShowLeader:SetPoint("TOP", GVAR.OptionsFrame.ShowSpec, "TOP", 0, 0)
	GVAR.OptionsFrame.ShowLeader:SetChecked(OPT.ButtonShowLeader[currentSize])
	GVAR.OptionsFrame.ShowLeader:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowLeader[currentSize] = not BattlegroundTargets_Options.ButtonShowLeader[currentSize]
		                        OPT.ButtonShowLeader[currentSize] = not                         OPT.ButtonShowLeader[currentSize]
		GVAR.OptionsFrame.ShowLeader:SetChecked(OPT.ButtonShowLeader[currentSize])
		BattlegroundTargets:EnableConfigMode()
	end)

	-- show realm
	GVAR.OptionsFrame.ShowRealm = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowRealm, 16, 4, L["Hide Realm"])
	GVAR.OptionsFrame.ShowRealm:SetPoint("LEFT", GVAR.OptionsFrame.ShowLeader, "LEFT", 0, 0)
	GVAR.OptionsFrame.ShowRealm:SetPoint("TOP", GVAR.OptionsFrame.ShowLeader, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ShowRealm:SetChecked(OPT.ButtonHideRealm[currentSize])
	GVAR.OptionsFrame.ShowRealm:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonHideRealm[currentSize] = not BattlegroundTargets_Options.ButtonHideRealm[currentSize]
		                        OPT.ButtonHideRealm[currentSize] = not                         OPT.ButtonHideRealm[currentSize]
		GVAR.OptionsFrame.ShowRealm:SetChecked(OPT.ButtonHideRealm[currentSize])
		BattlegroundTargets:EnableConfigMode()
	end)



	-- show targetcount
	GVAR.OptionsFrame.ShowTargetCount = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowTargetCount, 16, 4, L["Show Target Count"])
	GVAR.OptionsFrame.ShowTargetCount:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ShowTargetCount:SetPoint("TOP", GVAR.OptionsFrame.ClassIcon, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ShowTargetCount:SetChecked(OPT.ButtonShowTargetCount[currentSize])
	GVAR.OptionsFrame.ShowTargetCount:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowTargetCount[currentSize] = not BattlegroundTargets_Options.ButtonShowTargetCount[currentSize]
		                        OPT.ButtonShowTargetCount[currentSize] = not                         OPT.ButtonShowTargetCount[currentSize]
		GVAR.OptionsFrame.ShowTargetCount:SetChecked(OPT.ButtonShowTargetCount[currentSize])
		BattlegroundTargets:EnableConfigMode()
	end)



	-- ----- icons ----------------------------------------
	local iconW = 0
	-- show target indicator
	GVAR.OptionsFrame.ShowTargetIndicator = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowTargetIndicator, 16, 4, L["Show Target"])
	GVAR.OptionsFrame.ShowTargetIndicator:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ShowTargetIndicator:SetPoint("TOP", GVAR.OptionsFrame.ShowTargetCount, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ShowTargetIndicator:SetChecked(OPT.ButtonShowTarget[currentSize])
	GVAR.OptionsFrame.ShowTargetIndicator:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowTarget[currentSize] = not BattlegroundTargets_Options.ButtonShowTarget[currentSize]
		                        OPT.ButtonShowTarget[currentSize] = not                         OPT.ButtonShowTarget[currentSize]
		GVAR.OptionsFrame.ShowTargetIndicator:SetChecked(OPT.ButtonShowTarget[currentSize])
		if OPT.ButtonShowTarget[currentSize] then
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.TargetScaleSlider)
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.TargetPositionSlider)
		else
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.TargetScaleSlider)
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.TargetPositionSlider)
		end
		BattlegroundTargets:EnableConfigMode()
	end)
	local iw = GVAR.OptionsFrame.ShowTargetIndicator:GetWidth()
	if iw > iconW then
		iconW = iw
	end

	-- target indicator scale
	GVAR.OptionsFrame.TargetScaleSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.TargetScaleSliderText = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	TEMPLATE.Slider(GVAR.OptionsFrame.TargetScaleSlider, 85, 10, 100, 200, OPT.ButtonTargetScale[currentSize]*100,
	function(self, value)
		BattlegroundTargets_Options.ButtonTargetScale[currentSize] = value/100
		                        OPT.ButtonTargetScale[currentSize] = value/100
		GVAR.OptionsFrame.TargetScaleSliderText:SetText((OPT.ButtonTargetScale[currentSize]*100).."%")
		BattlegroundTargets:EnableConfigMode()
	end,
	"blank")
	GVAR.OptionsFrame.TargetScaleSlider:SetPoint("LEFT", GVAR.OptionsFrame.ShowTargetIndicator, "RIGHT", 10, 0)
	GVAR.OptionsFrame.TargetScaleSliderText:SetHeight(20)
	GVAR.OptionsFrame.TargetScaleSliderText:SetPoint("LEFT", GVAR.OptionsFrame.TargetScaleSlider, "RIGHT", 5, 0)
	GVAR.OptionsFrame.TargetScaleSliderText:SetJustifyH("LEFT")
	GVAR.OptionsFrame.TargetScaleSliderText:SetText((OPT.ButtonTargetScale[currentSize]*100).."%")
	GVAR.OptionsFrame.TargetScaleSliderText:SetTextColor(1, 1, 0.49, 1)

	-- target indicator position
	GVAR.OptionsFrame.TargetPositionSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.TargetPositionSliderText = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	TEMPLATE.Slider(GVAR.OptionsFrame.TargetPositionSlider, 85, 5, 0, 100, OPT.ButtonTargetPosition[currentSize],
	function(self, value)
		BattlegroundTargets_Options.ButtonTargetPosition[currentSize] = value
		                        OPT.ButtonTargetPosition[currentSize] = value
		GVAR.OptionsFrame.TargetPositionSliderText:SetText(OPT.ButtonTargetPosition[currentSize])
		BattlegroundTargets:EnableConfigMode()
	end,
	"blank")
	GVAR.OptionsFrame.TargetPositionSlider:SetPoint("LEFT", GVAR.OptionsFrame.TargetScaleSlider, "RIGHT", 50, 0)
	GVAR.OptionsFrame.TargetPositionSliderText:SetHeight(20)
	GVAR.OptionsFrame.TargetPositionSliderText:SetPoint("LEFT", GVAR.OptionsFrame.TargetPositionSlider, "RIGHT", 5, 0)
	GVAR.OptionsFrame.TargetPositionSliderText:SetJustifyH("LEFT")
	GVAR.OptionsFrame.TargetPositionSliderText:SetText(OPT.ButtonTargetPosition[currentSize])
	GVAR.OptionsFrame.TargetPositionSliderText:SetTextColor(1, 1, 0.49, 1)

	-- show focus indicator
	GVAR.OptionsFrame.ShowFocusIndicator = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowFocusIndicator, 16, 4, L["Show Focus"])
	GVAR.OptionsFrame.ShowFocusIndicator:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ShowFocusIndicator:SetPoint("TOP", GVAR.OptionsFrame.ShowTargetIndicator, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ShowFocusIndicator:SetChecked(OPT.ButtonShowFocus[currentSize])
	GVAR.OptionsFrame.ShowFocusIndicator:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowFocus[currentSize] = not BattlegroundTargets_Options.ButtonShowFocus[currentSize]
		                        OPT.ButtonShowFocus[currentSize] = not                         OPT.ButtonShowFocus[currentSize]
		GVAR.OptionsFrame.ShowFocusIndicator:SetChecked(OPT.ButtonShowFocus[currentSize])
		if OPT.ButtonShowFocus[currentSize] then
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.FocusScaleSlider)
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.FocusPositionSlider)
		else
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.FocusScaleSlider)
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.FocusPositionSlider)
		end
		BattlegroundTargets:EnableConfigMode()
	end)
	local iw = GVAR.OptionsFrame.ShowFocusIndicator:GetWidth()
	if iw > iconW then
		iconW = iw
	end

	-- focus indicator scale
	GVAR.OptionsFrame.FocusScaleSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.FocusScaleSliderText = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	TEMPLATE.Slider(GVAR.OptionsFrame.FocusScaleSlider, 85, 10, 100, 200, OPT.ButtonFocusScale[currentSize]*100,
	function(self, value)
		BattlegroundTargets_Options.ButtonFocusScale[currentSize] = value/100
		                        OPT.ButtonFocusScale[currentSize] = value/100
		GVAR.OptionsFrame.FocusScaleSliderText:SetText((OPT.ButtonFocusScale[currentSize]*100).."%")
		BattlegroundTargets:EnableConfigMode()
	end,
	"blank")
	GVAR.OptionsFrame.FocusScaleSlider:SetPoint("LEFT", GVAR.OptionsFrame.ShowFocusIndicator, "RIGHT", 10, 0)
	GVAR.OptionsFrame.FocusScaleSliderText:SetHeight(20)
	GVAR.OptionsFrame.FocusScaleSliderText:SetPoint("LEFT", GVAR.OptionsFrame.FocusScaleSlider, "RIGHT", 5, 0)
	GVAR.OptionsFrame.FocusScaleSliderText:SetJustifyH("LEFT")
	GVAR.OptionsFrame.FocusScaleSliderText:SetText((OPT.ButtonFocusScale[currentSize]*100).."%")
	GVAR.OptionsFrame.FocusScaleSliderText:SetTextColor(1, 1, 0.49, 1)

	-- focus indicator position
	GVAR.OptionsFrame.FocusPositionSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.FocusPositionSliderText = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	TEMPLATE.Slider(GVAR.OptionsFrame.FocusPositionSlider, 85, 5, 0, 100, OPT.ButtonFocusPosition[currentSize],
	function(self, value)
		BattlegroundTargets_Options.ButtonFocusPosition[currentSize] = value
		                        OPT.ButtonFocusPosition[currentSize] = value
		GVAR.OptionsFrame.FocusPositionSliderText:SetText(OPT.ButtonFocusPosition[currentSize])
		BattlegroundTargets:EnableConfigMode()
	end,
	"blank")
	GVAR.OptionsFrame.FocusPositionSlider:SetPoint("LEFT", GVAR.OptionsFrame.FocusScaleSlider, "RIGHT", 50, 0)
	GVAR.OptionsFrame.FocusPositionSliderText:SetHeight(20)
	GVAR.OptionsFrame.FocusPositionSliderText:SetPoint("LEFT", GVAR.OptionsFrame.FocusPositionSlider, "RIGHT", 5, 0)
	GVAR.OptionsFrame.FocusPositionSliderText:SetJustifyH("LEFT")
	GVAR.OptionsFrame.FocusPositionSliderText:SetText(OPT.ButtonFocusPosition[currentSize])
	GVAR.OptionsFrame.FocusPositionSliderText:SetTextColor(1, 1, 0.49, 1)

	-- show flag
	GVAR.OptionsFrame.ShowFlag = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowFlag, 16, 4, L["Show Flag Carrier"])
	GVAR.OptionsFrame.ShowFlag:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ShowFlag:SetPoint("TOP", GVAR.OptionsFrame.ShowFocusIndicator, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ShowFlag:SetChecked(OPT.ButtonShowFlag[currentSize])
	TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowFlag)
	GVAR.OptionsFrame.ShowFlag:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowFlag[currentSize] = not BattlegroundTargets_Options.ButtonShowFlag[currentSize]
		                        OPT.ButtonShowFlag[currentSize] = not                         OPT.ButtonShowFlag[currentSize]
		if OPT.ButtonShowFlag[currentSize] then
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.FlagScaleSlider)
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.FlagPositionSlider)
		else
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.FlagScaleSlider)
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.FlagPositionSlider)
		end
		BattlegroundTargets:EnableConfigMode()
	end)
	local iw = GVAR.OptionsFrame.ShowFlag:GetWidth()
	if iw > iconW then
		iconW = iw
	end

	-- flag scale
	GVAR.OptionsFrame.FlagScaleSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.FlagScaleSliderText = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	TEMPLATE.Slider(GVAR.OptionsFrame.FlagScaleSlider, 85, 10, 100, 200, OPT.ButtonFlagScale[currentSize]*100,
	function(self, value)
		BattlegroundTargets_Options.ButtonFlagScale[currentSize] = value/100
		                        OPT.ButtonFlagScale[currentSize] = value/100
		GVAR.OptionsFrame.FlagScaleSliderText:SetText((OPT.ButtonFlagScale[currentSize]*100).."%")
		BattlegroundTargets:EnableConfigMode()
	end,
	"blank")
	GVAR.OptionsFrame.FlagScaleSlider:SetPoint("LEFT", GVAR.OptionsFrame.ShowFlag, "RIGHT", 10, 0)
	GVAR.OptionsFrame.FlagScaleSliderText:SetHeight(20)
	GVAR.OptionsFrame.FlagScaleSliderText:SetPoint("LEFT", GVAR.OptionsFrame.FlagScaleSlider, "RIGHT", 5, 0)
	GVAR.OptionsFrame.FlagScaleSliderText:SetJustifyH("LEFT")
	GVAR.OptionsFrame.FlagScaleSliderText:SetText((OPT.ButtonFlagScale[currentSize]*100).."%")
	GVAR.OptionsFrame.FlagScaleSliderText:SetTextColor(1, 1, 0.49, 1)

	-- flag position
	GVAR.OptionsFrame.FlagPositionSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.FlagPositionSliderText = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	TEMPLATE.Slider(GVAR.OptionsFrame.FlagPositionSlider, 85, 5, 0, 100, OPT.ButtonFlagPosition[currentSize],
	function(self, value)
		BattlegroundTargets_Options.ButtonFlagPosition[currentSize] = value
		                        OPT.ButtonFlagPosition[currentSize] = value
		GVAR.OptionsFrame.FlagPositionSliderText:SetText(OPT.ButtonFlagPosition[currentSize])
		BattlegroundTargets:EnableConfigMode()
	end,
	"blank")
	GVAR.OptionsFrame.FlagPositionSlider:SetPoint("LEFT", GVAR.OptionsFrame.FlagScaleSlider, "RIGHT", 50, 0)
	GVAR.OptionsFrame.FlagPositionSliderText:SetHeight(20)
	GVAR.OptionsFrame.FlagPositionSliderText:SetPoint("LEFT", GVAR.OptionsFrame.FlagPositionSlider, "RIGHT", 5, 0)
	GVAR.OptionsFrame.FlagPositionSliderText:SetJustifyH("LEFT")
	GVAR.OptionsFrame.FlagPositionSliderText:SetText(OPT.ButtonFlagPosition[currentSize])
	GVAR.OptionsFrame.FlagPositionSliderText:SetTextColor(1, 1, 0.49, 1)

	-- show assist
	GVAR.OptionsFrame.ShowAssist = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowAssist, 16, 4, L["Show Main Assist Target"])
	GVAR.OptionsFrame.ShowAssist:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ShowAssist:SetPoint("TOP", GVAR.OptionsFrame.ShowFlag, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ShowAssist:SetChecked(OPT.ButtonShowAssist[currentSize])
	TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowAssist)
	GVAR.OptionsFrame.ShowAssist:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowAssist[currentSize] = not BattlegroundTargets_Options.ButtonShowAssist[currentSize]
		                        OPT.ButtonShowAssist[currentSize] = not                         OPT.ButtonShowAssist[currentSize]
		if OPT.ButtonShowAssist[currentSize] then
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.AssistScaleSlider)
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.AssistPositionSlider)
		else
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.AssistScaleSlider)
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.AssistPositionSlider)
		end
		BattlegroundTargets:EnableConfigMode()
	end)
	local iw = GVAR.OptionsFrame.ShowAssist:GetWidth()
	if iw > iconW then
		iconW = iw
	end

	-- assist scale
	GVAR.OptionsFrame.AssistScaleSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.AssistScaleSliderText = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	TEMPLATE.Slider(GVAR.OptionsFrame.AssistScaleSlider, 85, 10, 100, 200, OPT.ButtonAssistScale[currentSize]*100,
	function(self, value)
		BattlegroundTargets_Options.ButtonAssistScale[currentSize] = value/100
		                        OPT.ButtonAssistScale[currentSize] = value/100
		GVAR.OptionsFrame.AssistScaleSliderText:SetText((OPT.ButtonAssistScale[currentSize]*100).."%")
		BattlegroundTargets:EnableConfigMode()
	end,
	"blank")
	GVAR.OptionsFrame.AssistScaleSlider:SetPoint("LEFT", GVAR.OptionsFrame.ShowAssist, "RIGHT", 10, 0)
	GVAR.OptionsFrame.AssistScaleSliderText:SetHeight(20)
	GVAR.OptionsFrame.AssistScaleSliderText:SetPoint("LEFT", GVAR.OptionsFrame.AssistScaleSlider, "RIGHT", 5, 0)
	GVAR.OptionsFrame.AssistScaleSliderText:SetJustifyH("LEFT")
	GVAR.OptionsFrame.AssistScaleSliderText:SetText((OPT.ButtonAssistScale[currentSize]*100).."%")
	GVAR.OptionsFrame.AssistScaleSliderText:SetTextColor(1, 1, 0.49, 1)

	-- assist position
	GVAR.OptionsFrame.AssistPositionSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.AssistPositionSliderText = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	TEMPLATE.Slider(GVAR.OptionsFrame.AssistPositionSlider, 85, 5, 0, 100, OPT.ButtonAssistPosition[currentSize],
	function(self, value)
		BattlegroundTargets_Options.ButtonAssistPosition[currentSize] = value
		                        OPT.ButtonAssistPosition[currentSize] = value
		GVAR.OptionsFrame.AssistPositionSliderText:SetText(OPT.ButtonAssistPosition[currentSize])
		BattlegroundTargets:EnableConfigMode()
	end,
	"blank")
	GVAR.OptionsFrame.AssistPositionSlider:SetPoint("LEFT", GVAR.OptionsFrame.AssistScaleSlider, "RIGHT", 50, 0)
	GVAR.OptionsFrame.AssistPositionSliderText:SetHeight(20)
	GVAR.OptionsFrame.AssistPositionSliderText:SetPoint("LEFT", GVAR.OptionsFrame.AssistPositionSlider, "RIGHT", 5, 0)
	GVAR.OptionsFrame.AssistPositionSliderText:SetJustifyH("LEFT")
	GVAR.OptionsFrame.AssistPositionSliderText:SetText(OPT.ButtonAssistPosition[currentSize])
	GVAR.OptionsFrame.AssistPositionSliderText:SetTextColor(1, 1, 0.49, 1)


	GVAR.OptionsFrame.TargetScaleSlider:SetPoint("LEFT", GVAR.OptionsFrame.ShowTargetIndicator, "LEFT", iconW+10, 0)
	GVAR.OptionsFrame.FocusScaleSlider:SetPoint("LEFT", GVAR.OptionsFrame.ShowFocusIndicator, "LEFT", iconW+10, 0)
	GVAR.OptionsFrame.FlagScaleSlider:SetPoint("LEFT", GVAR.OptionsFrame.ShowFlag, "LEFT", iconW+10, 0)
	GVAR.OptionsFrame.AssistScaleSlider:SetPoint("LEFT", GVAR.OptionsFrame.ShowAssist, "LEFT", iconW+10, 0)
	-- ----- icons ----------------------------------------



	-- show healt bar
	GVAR.OptionsFrame.ShowHealthBar = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowHealthBar, 16, 4, L["Show Health Bar"])
	GVAR.OptionsFrame.ShowHealthBar:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ShowHealthBar:SetPoint("TOP", GVAR.OptionsFrame.ShowAssist, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ShowHealthBar:SetChecked(OPT.ButtonShowHealthBar[currentSize])
	GVAR.OptionsFrame.ShowHealthBar:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowHealthBar[currentSize] = not BattlegroundTargets_Options.ButtonShowHealthBar[currentSize]
		                        OPT.ButtonShowHealthBar[currentSize] = not                         OPT.ButtonShowHealthBar[currentSize]
		GVAR.OptionsFrame.ShowHealthBar:SetChecked(OPT.ButtonShowHealthBar[currentSize])
		BattlegroundTargets:EnableConfigMode()
	end)

	-- show healt text
	GVAR.OptionsFrame.ShowHealthText = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowHealthText, 16, 4, L["Show Percent"])
	GVAR.OptionsFrame.ShowHealthText:SetPoint("LEFT", GVAR.OptionsFrame.ShowHealthBar.Text, "RIGHT", 20, 0)
	GVAR.OptionsFrame.ShowHealthText:SetChecked(OPT.ButtonShowHealthText[currentSize])
	GVAR.OptionsFrame.ShowHealthText:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowHealthText[currentSize] = not BattlegroundTargets_Options.ButtonShowHealthText[currentSize]
		                        OPT.ButtonShowHealthText[currentSize] = not                         OPT.ButtonShowHealthText[currentSize]
		GVAR.OptionsFrame.ShowHealthText:SetChecked(OPT.ButtonShowHealthText[currentSize])
		BattlegroundTargets:EnableConfigMode()
	end)



	-- ----- range check ----------------------------------------
	local rangeW = 0
	local rangeWtxt = 0
		----- text
		local _, _, _, _, _, _, _, minRange, maxRange = GetSpellInfo(ranges[playerClassEN])
		rangeTypeName[2] = CLASS.." |cffffff79("..(minRange or "?").."-"..(maxRange or "?")..")|r"
		local buttonName = rangeTypeName[1]
		if OPT.ButtonClassRangeCheck[currentSize] then
			buttonName = rangeTypeName[2]
		end
		local rangeInfoTxt = ""
		rangeInfoTxt = rangeInfoTxt..rangeTypeName[1]..":\n"
		rangeInfoTxt = rangeInfoTxt.." |cffffffff"..L["This option uses CombatLog scanning."].."|r\n\n\n\n"
		rangeInfoTxt = rangeInfoTxt..rangeTypeName[2]..":\n"
		rangeInfoTxt = rangeInfoTxt.." |cffffffff"..L["This option uses a pre-defined spell to check range:"].."|r\n"
		table_sort(classesINT_LOCALIZED, function(a, b) if a.loc < b.loc then return true end end)
		for i = 1, #classesINT_LOCALIZED do
			local name, _, _, _, _, _, _, minRange, maxRange = GetSpellInfo(ranges[ classesINT_LOCALIZED[i].cid ])
			if classesINT_LOCALIZED[i].cid == playerClassEN then
				rangeInfoTxt = rangeInfoTxt..">>> "
			end
			rangeInfoTxt = rangeInfoTxt.." |cff"..ClassHexColor(classesINT_LOCALIZED[i].cid)..classesINT_LOCALIZED[i].loc.."|r  "..(minRange or "?").."-"..(maxRange or "?").."  |cffffffff"..(name or UNKNOWN).."|r  |cffbbbbbb(spellID="..ranges[ classesINT_LOCALIZED[i].cid ]..")|r"
			if classesINT_LOCALIZED[i].cid == playerClassEN then
				rangeInfoTxt = rangeInfoTxt.." <<<"
			end
			rangeInfoTxt = rangeInfoTxt.."\n"
		end
		rangeInfoTxt = rangeInfoTxt.."\n\n\n|cffffffff"..L["Disable this option if you have CPU/FPS problems in combat."].."|r"
		----- text
	-- range check
	GVAR.OptionsFrame.RangeCheck = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.RangeCheck, 16, 4, L["Show Range"])
	GVAR.OptionsFrame.RangeCheck:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.RangeCheck:SetPoint("TOP", GVAR.OptionsFrame.ShowHealthBar, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.RangeCheck:SetChecked(OPT.ButtonRangeCheck[currentSize])
	GVAR.OptionsFrame.RangeCheck:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonRangeCheck[currentSize] = not BattlegroundTargets_Options.ButtonRangeCheck[currentSize]
		                        OPT.ButtonRangeCheck[currentSize] = not                         OPT.ButtonRangeCheck[currentSize]
		GVAR.OptionsFrame.RangeCheck:SetChecked(OPT.ButtonRangeCheck[currentSize])
		if OPT.ButtonRangeCheck[currentSize] then
			TEMPLATE.EnablePullDownMenu(GVAR.OptionsFrame.RangeCheckTypePullDown)
			GVAR.OptionsFrame.RangeCheckInfo:Enable() Desaturation(GVAR.OptionsFrame.RangeCheckInfo.Texture, false)
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.RangeAlphaSlider)
		else
			TEMPLATE.DisablePullDownMenu(GVAR.OptionsFrame.RangeCheckTypePullDown)
			GVAR.OptionsFrame.RangeCheckInfo:Disable() Desaturation(GVAR.OptionsFrame.RangeCheckInfo.Texture, true)
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.RangeAlphaSlider)
		end
		BattlegroundTargets:EnableConfigMode()
	end)
	rangeW = rangeW + 10 + GVAR.OptionsFrame.RangeCheck:GetWidth()

	-- range check info
	GVAR.OptionsFrame.RangeCheckInfo = CreateFrame("Button", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.RangeCheckInfo:SetWidth(16)
	GVAR.OptionsFrame.RangeCheckInfo:SetHeight(16)
	GVAR.OptionsFrame.RangeCheckInfo:SetPoint("LEFT", GVAR.OptionsFrame.RangeCheck, "RIGHT", 10, 0)
	GVAR.OptionsFrame.RangeCheckInfo.Texture = GVAR.OptionsFrame.RangeCheckInfo:CreateTexture(nil, "ARTWORK")
	GVAR.OptionsFrame.RangeCheckInfo.Texture:SetWidth(16)
	GVAR.OptionsFrame.RangeCheckInfo.Texture:SetHeight(16)
	GVAR.OptionsFrame.RangeCheckInfo.Texture:SetPoint("LEFT", 0, 0)
	GVAR.OptionsFrame.RangeCheckInfo.Texture:SetTexture("Interface\\FriendsFrame\\InformationIcon")
	GVAR.OptionsFrame.RangeCheckInfo.TextFrame = CreateFrame("Frame", nil, GVAR.OptionsFrame)
	TEMPLATE.BorderTRBL(GVAR.OptionsFrame.RangeCheckInfo.TextFrame)
	GVAR.OptionsFrame.RangeCheckInfo.TextFrame:SetToplevel(true)
	GVAR.OptionsFrame.RangeCheckInfo.TextFrame:SetPoint("BOTTOM", GVAR.OptionsFrame.RangeCheckInfo.Texture, "TOP", 0, 0)
	GVAR.OptionsFrame.RangeCheckInfo.TextFrame:Hide()
	GVAR.OptionsFrame.RangeCheckInfo.Text = GVAR.OptionsFrame.RangeCheckInfo.TextFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.RangeCheckInfo.Text:SetPoint("CENTER", 0, 0)
	GVAR.OptionsFrame.RangeCheckInfo.Text:SetJustifyH("LEFT")
	GVAR.OptionsFrame.RangeCheckInfo.Text:SetText(rangeInfoTxt)
	GVAR.OptionsFrame.RangeCheckInfo.Text:SetTextColor(1, 1, 0.49, 1)
	GVAR.OptionsFrame.RangeCheckInfo:SetScript("OnEnter", function() GVAR.OptionsFrame.RangeCheckInfo.TextFrame:Show() end)
	GVAR.OptionsFrame.RangeCheckInfo:SetScript("OnLeave", function() GVAR.OptionsFrame.RangeCheckInfo.TextFrame:Hide() end)
	rangeW = rangeW + 10 + 16
		-----
		local txtWidth = GVAR.OptionsFrame.RangeCheckInfo.Text:GetStringWidth()
		local txtHeight = GVAR.OptionsFrame.RangeCheckInfo.Text:GetStringHeight()
		GVAR.OptionsFrame.RangeCheckInfo.TextFrame:SetWidth(txtWidth+20)
		GVAR.OptionsFrame.RangeCheckInfo.TextFrame:SetHeight(txtHeight+20)
		GVAR.OptionsFrame.RangeCheckInfo.Text:SetWidth(txtWidth+10)
		GVAR.OptionsFrame.RangeCheckInfo.Text:SetHeight(txtHeight+10)
		-----

	-- range type
	GVAR.OptionsFrame.RangeCheckTypePullDown = CreateFrame("Button", nil, GVAR.OptionsFrame)
	TEMPLATE.PullDownMenu(
		GVAR.OptionsFrame.RangeCheckTypePullDown,
		"RangeType",
		buttonName,
		0,
		2,
		RangeCheckTypePullDownFunc
	)
	GVAR.OptionsFrame.RangeCheckTypePullDown:SetPoint("LEFT", GVAR.OptionsFrame.RangeCheckInfo, "RIGHT", 10, 0)
	GVAR.OptionsFrame.RangeCheckTypePullDown:SetHeight(18)
	TEMPLATE.EnablePullDownMenu(GVAR.OptionsFrame.RangeCheckTypePullDown)
	rangeW = rangeW + 10 + GVAR.OptionsFrame.RangeCheckTypePullDown:GetWidth()

	-- range alpha
	GVAR.OptionsFrame.RangeAlphaSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.RangeAlphaValue = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	TEMPLATE.Slider(GVAR.OptionsFrame.RangeAlphaSlider, 85, 5, 0, 100, OPT.ButtonRangeAlpha[currentSize]*100,
	function(self, value)
		BattlegroundTargets_Options.ButtonRangeAlpha[currentSize] = value/100
		                        OPT.ButtonRangeAlpha[currentSize] = value/100
		GVAR.OptionsFrame.RangeAlphaValue:SetText((OPT.ButtonRangeAlpha[currentSize]*100).."%")
		BattlegroundTargets:EnableConfigMode()
	end,
	"blank")
	GVAR.OptionsFrame.RangeAlphaSlider:SetPoint("LEFT", GVAR.OptionsFrame.RangeCheckTypePullDown, "RIGHT", 10, 0)
	GVAR.OptionsFrame.RangeAlphaValue:SetHeight(16)
	GVAR.OptionsFrame.RangeAlphaValue:SetPoint("LEFT", GVAR.OptionsFrame.RangeAlphaSlider, "RIGHT", 5, 0)
	GVAR.OptionsFrame.RangeAlphaValue:SetJustifyH("LEFT")
	GVAR.OptionsFrame.RangeAlphaValue:SetText((OPT.ButtonRangeAlpha[currentSize]*100).."%")
	GVAR.OptionsFrame.RangeAlphaValue:SetTextColor(1, 1, 0.49, 1)
	rangeW = rangeW + 10 + GVAR.OptionsFrame.RangeAlphaSlider:GetWidth() + 50
	-- ----- range check ----------------------------------------



	-- sort by
	GVAR.OptionsFrame.SortByTitle = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.SortByTitle:SetHeight(16)
	GVAR.OptionsFrame.SortByTitle:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.SortByTitle:SetPoint("TOP", GVAR.OptionsFrame.RangeCheck, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.SortByTitle:SetJustifyH("LEFT")
	GVAR.OptionsFrame.SortByTitle:SetText(L["Sort By"]..":")
	GVAR.OptionsFrame.SortByTitle:SetTextColor(1, 1, 1, 1)

	GVAR.OptionsFrame.SortByPullDown = CreateFrame("Button", nil, GVAR.OptionsFrame)
	TEMPLATE.PullDownMenu(
		GVAR.OptionsFrame.SortByPullDown,
		"SortBy",
		sortBy[ OPT.ButtonSortBy[currentSize] ],
		0,
		#sortBy,
		SortByPullDownFunc
	)
	GVAR.OptionsFrame.SortByPullDown:SetPoint("LEFT", GVAR.OptionsFrame.SortByTitle, "RIGHT", 10, 0)
	GVAR.OptionsFrame.SortByPullDown:SetHeight(18)
	TEMPLATE.EnablePullDownMenu(GVAR.OptionsFrame.SortByPullDown)

	-- sort detail
	GVAR.OptionsFrame.SortDetailPullDown = CreateFrame("Button", nil, GVAR.OptionsFrame)
	TEMPLATE.PullDownMenu(
		GVAR.OptionsFrame.SortDetailPullDown,
		"SortDetail",
		sortBy[ OPT.ButtonSortDetail[currentSize] ],
		0,
		#sortDetail,
		SortDetailPullDownFunc
	)
	GVAR.OptionsFrame.SortDetailPullDown:SetPoint("LEFT", GVAR.OptionsFrame.SortByPullDown, "RIGHT", 10, 0)
	GVAR.OptionsFrame.SortDetailPullDown:SetHeight(18)
	TEMPLATE.EnablePullDownMenu(GVAR.OptionsFrame.SortDetailPullDown)

	-- sort info
		----- text
		local infoTxt1 = sortDetail[1]..":\n"
		table_sort(classesINT_LOCALIZED, function(a, b) if a.loc < b.loc then return true end end)
		for i = 1, #classesINT_LOCALIZED do
			infoTxt1 = infoTxt1.." |cff"..ClassHexColor(classesINT_LOCALIZED[i].cid)..classesINT_LOCALIZED[i].loc.."|r"
			if i <= #classesINT_LOCALIZED then
				infoTxt1 = infoTxt1.."\n"
			end
		end
		local infoTxt2 = sortDetail[2]..":\n"
		table_sort(classesINT_LOCALIZED, function(a, b) if a.eng < b.eng then return true end end)
		for i = 1, #classesINT_LOCALIZED do
			infoTxt2 = infoTxt2.." |cff"..ClassHexColor(classesINT_LOCALIZED[i].cid)..classesINT_LOCALIZED[i].loc.." ("..classesINT_LOCALIZED[i].eng..")|r"
			if i <= #classesINT_LOCALIZED then
				infoTxt2 = infoTxt2.."\n"
			end
		end
		local infoTxt3 = sortDetail[3]..":\n"
		table_sort(classesINT_LOCALIZED, function(a, b) if a.blizz < b.blizz then return true end end)
		for i = 1, #classesINT_LOCALIZED do
			infoTxt3 = infoTxt3.." |cff"..ClassHexColor(classesINT_LOCALIZED[i].cid)..classesINT_LOCALIZED[i].loc.."|r"
			if i <= #classesINT_LOCALIZED then
				infoTxt3 = infoTxt3.."\n"
			end
		end
		----- text
	GVAR.OptionsFrame.SortInfo = CreateFrame("Button", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.SortInfo:SetWidth(16)
	GVAR.OptionsFrame.SortInfo:SetHeight(16)
	GVAR.OptionsFrame.SortInfo:SetPoint("LEFT", GVAR.OptionsFrame.SortDetailPullDown, "RIGHT", 10, 0)
	GVAR.OptionsFrame.SortInfo.Texture = GVAR.OptionsFrame.SortInfo:CreateTexture(nil, "ARTWORK")
	GVAR.OptionsFrame.SortInfo.Texture:SetWidth(16)
	GVAR.OptionsFrame.SortInfo.Texture:SetHeight(16)
	GVAR.OptionsFrame.SortInfo.Texture:SetPoint("LEFT", 0, 0)
	GVAR.OptionsFrame.SortInfo.Texture:SetTexture("Interface\\FriendsFrame\\InformationIcon")
	GVAR.OptionsFrame.SortInfo.TextFrame = CreateFrame("Frame", nil, GVAR.OptionsFrame.SortInfo)
	TEMPLATE.BorderTRBL(GVAR.OptionsFrame.SortInfo.TextFrame)
	GVAR.OptionsFrame.SortInfo.TextFrame:SetToplevel(true)
	GVAR.OptionsFrame.SortInfo.TextFrame:SetPoint("BOTTOM", GVAR.OptionsFrame.SortInfo.Texture, "TOP", 0, 0)
	GVAR.OptionsFrame.SortInfo.TextFrame:Hide()
	GVAR.OptionsFrame.SortInfo.Text1 = GVAR.OptionsFrame.SortInfo.TextFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.SortInfo.Text1:SetPoint("TOPLEFT", GVAR.OptionsFrame.SortInfo.TextFrame, "TOPLEFT", 10, -10)
	GVAR.OptionsFrame.SortInfo.Text1:SetJustifyH("LEFT")
	GVAR.OptionsFrame.SortInfo.Text1:SetText(infoTxt1)
	GVAR.OptionsFrame.SortInfo.Text1:SetTextColor(1, 1, 0.49, 1)
	GVAR.OptionsFrame.SortInfo.Text2 = GVAR.OptionsFrame.SortInfo.TextFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.SortInfo.Text2:SetPoint("LEFT", GVAR.OptionsFrame.SortInfo.Text1, "RIGHT", 0, 0)
	GVAR.OptionsFrame.SortInfo.Text2:SetJustifyH("LEFT")
	GVAR.OptionsFrame.SortInfo.Text2:SetText(infoTxt2)
	GVAR.OptionsFrame.SortInfo.Text2:SetTextColor(1, 1, 0.49, 1)
	GVAR.OptionsFrame.SortInfo.Text3 = GVAR.OptionsFrame.SortInfo.TextFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.SortInfo.Text3:SetPoint("LEFT", GVAR.OptionsFrame.SortInfo.Text2, "RIGHT", 0, 0)
	GVAR.OptionsFrame.SortInfo.Text3:SetJustifyH("LEFT")
	GVAR.OptionsFrame.SortInfo.Text3:SetText(infoTxt3)
	GVAR.OptionsFrame.SortInfo.Text3:SetTextColor(1, 1, 0.49, 1)
	GVAR.OptionsFrame.SortInfo:SetScript("OnEnter", function() GVAR.OptionsFrame.SortInfo.TextFrame:Show() end)
	GVAR.OptionsFrame.SortInfo:SetScript("OnLeave", function() GVAR.OptionsFrame.SortInfo.TextFrame:Hide() end)
		-----
		local txtWidth1 = GVAR.OptionsFrame.SortInfo.Text1:GetStringWidth()
		local txtWidth2 = GVAR.OptionsFrame.SortInfo.Text2:GetStringWidth()
		local txtWidth3 = GVAR.OptionsFrame.SortInfo.Text3:GetStringWidth()
		GVAR.OptionsFrame.SortInfo.Text1:SetWidth(txtWidth1+10)
		GVAR.OptionsFrame.SortInfo.Text2:SetWidth(txtWidth2+10)
		GVAR.OptionsFrame.SortInfo.Text3:SetWidth(txtWidth3+10)
		GVAR.OptionsFrame.SortInfo.TextFrame:SetWidth(10+ txtWidth1+10 + txtWidth2+10 + txtWidth3+10 +10)
		local txtHeight = GVAR.OptionsFrame.SortInfo.Text1:GetStringHeight()
		GVAR.OptionsFrame.SortInfo.Text1:SetHeight(txtHeight+10)
		GVAR.OptionsFrame.SortInfo.Text2:SetHeight(txtHeight+10)
		GVAR.OptionsFrame.SortInfo.Text3:SetHeight(txtHeight+10)
		GVAR.OptionsFrame.SortInfo.TextFrame:SetHeight(10+ txtHeight+10 +10)
		-----



	-- ----- sliders ----------------------------------------
	local sliderW = 0
	-- fontsize
	GVAR.OptionsFrame.FontTitle = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.FontSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.FontValue = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.FontTitle:SetHeight(16)
	GVAR.OptionsFrame.FontTitle:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.FontTitle:SetPoint("TOP", GVAR.OptionsFrame.SortByTitle, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.FontTitle:SetJustifyH("LEFT")
	GVAR.OptionsFrame.FontTitle:SetText(L["Text Size"]..":")
	GVAR.OptionsFrame.FontTitle:SetTextColor(1, 1, 1, 1)
	TEMPLATE.Slider(GVAR.OptionsFrame.FontSlider, 150, 1, 5, 20, OPT.ButtonFontSize[currentSize],
	function(self, value)
		BattlegroundTargets_Options.ButtonFontSize[currentSize] = value
		                        OPT.ButtonFontSize[currentSize] = value
		GVAR.OptionsFrame.FontValue:SetText(OPT.ButtonFontSize[currentSize])
		BattlegroundTargets:EnableConfigMode()
	end,
	"blank")
	GVAR.OptionsFrame.FontSlider:SetPoint("LEFT", GVAR.OptionsFrame.FontTitle, "RIGHT", 20, 0)
	GVAR.OptionsFrame.FontValue:SetHeight(20)
	GVAR.OptionsFrame.FontValue:SetPoint("LEFT", GVAR.OptionsFrame.FontSlider, "RIGHT", 5, 0)
	GVAR.OptionsFrame.FontValue:SetJustifyH("LEFT")
	GVAR.OptionsFrame.FontValue:SetText(OPT.ButtonFontSize[currentSize])
	GVAR.OptionsFrame.FontValue:SetTextColor(1, 1, 0.49, 1)
	local sw = GVAR.OptionsFrame.FontTitle:GetStringWidth()
	if sw > sliderW then
		sliderW = sw
	end

	-- scale
	GVAR.OptionsFrame.ScaleTitle = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.ScaleSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.ScaleValue = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.ScaleTitle:SetHeight(16)
	GVAR.OptionsFrame.ScaleTitle:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ScaleTitle:SetPoint("TOP", GVAR.OptionsFrame.FontSlider, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ScaleTitle:SetJustifyH("LEFT")
	GVAR.OptionsFrame.ScaleTitle:SetText(L["Scale"]..":")
	GVAR.OptionsFrame.ScaleTitle:SetTextColor(1, 1, 1, 1)
	TEMPLATE.Slider(GVAR.OptionsFrame.ScaleSlider, 180, 5, 50, 200, OPT.ButtonScale[currentSize]*100,
	function(self, value)
		BattlegroundTargets_Options.ButtonScale[currentSize] = value/100
		                        OPT.ButtonScale[currentSize] = value/100
		GVAR.OptionsFrame.ScaleValue:SetText((OPT.ButtonScale[currentSize]*100).."%")
		BattlegroundTargets:EnableConfigMode()
	end,
	"blank")
	GVAR.OptionsFrame.ScaleSlider:SetPoint("LEFT", GVAR.OptionsFrame.ScaleTitle, "RIGHT", 20, 0)
	GVAR.OptionsFrame.ScaleValue:SetHeight(20)
	GVAR.OptionsFrame.ScaleValue:SetPoint("LEFT", GVAR.OptionsFrame.ScaleSlider, "RIGHT", 5, 0)
	GVAR.OptionsFrame.ScaleValue:SetJustifyH("LEFT")
	GVAR.OptionsFrame.ScaleValue:SetText((OPT.ButtonScale[currentSize]*100).."%")
	GVAR.OptionsFrame.ScaleValue:SetTextColor(1, 1, 0.49, 1)
	local sw = GVAR.OptionsFrame.ScaleTitle:GetStringWidth()
	if sw > sliderW then
		sliderW = sw
	end

	-- width
	GVAR.OptionsFrame.WidthTitle = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.WidthSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.WidthValue = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.WidthTitle:SetHeight(16)
	GVAR.OptionsFrame.WidthTitle:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.WidthTitle:SetPoint("TOP", GVAR.OptionsFrame.ScaleSlider, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.WidthTitle:SetJustifyH("LEFT")
	GVAR.OptionsFrame.WidthTitle:SetText(L["Width"]..":")
	GVAR.OptionsFrame.WidthTitle:SetTextColor(1, 1, 1, 1)
	TEMPLATE.Slider(GVAR.OptionsFrame.WidthSlider, 180, 5, 50, 300, OPT.ButtonWidth[currentSize],
	function(self, value)
		BattlegroundTargets_Options.ButtonWidth[currentSize] = value
		                        OPT.ButtonWidth[currentSize] = value
		GVAR.OptionsFrame.WidthValue:SetText(OPT.ButtonWidth[currentSize].."px")
		BattlegroundTargets:EnableConfigMode()
	end,
	"blank")
	GVAR.OptionsFrame.WidthSlider:SetPoint("LEFT", GVAR.OptionsFrame.WidthTitle, "RIGHT", 20, 0)
	GVAR.OptionsFrame.WidthValue:SetHeight(20)
	GVAR.OptionsFrame.WidthValue:SetPoint("LEFT", GVAR.OptionsFrame.WidthSlider, "RIGHT", 5, 0)
	GVAR.OptionsFrame.WidthValue:SetJustifyH("LEFT")
	GVAR.OptionsFrame.WidthValue:SetText(OPT.ButtonWidth[currentSize].."px")
	GVAR.OptionsFrame.WidthValue:SetTextColor(1, 1, 0.49, 1)
	local sw = GVAR.OptionsFrame.WidthTitle:GetStringWidth()
	if sw > sliderW then
		sliderW = sw
	end

	-- height
	GVAR.OptionsFrame.HeightTitle = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.HeightSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.HeightValue = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.HeightTitle:SetHeight(16)
	GVAR.OptionsFrame.HeightTitle:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.HeightTitle:SetPoint("TOP", GVAR.OptionsFrame.WidthTitle, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.HeightTitle:SetJustifyH("LEFT")
	GVAR.OptionsFrame.HeightTitle:SetText(L["Height"]..":")
	GVAR.OptionsFrame.HeightTitle:SetTextColor(1, 1, 1, 1)
	TEMPLATE.Slider(GVAR.OptionsFrame.HeightSlider, 180, 1, 10, 30, OPT.ButtonHeight[currentSize],
	function(self, value)
		BattlegroundTargets_Options.ButtonHeight[currentSize] = value
		                        OPT.ButtonHeight[currentSize] = value
		GVAR.OptionsFrame.HeightValue:SetText(OPT.ButtonHeight[currentSize].."px")
		BattlegroundTargets:EnableConfigMode()
	end,
	"blank")
	GVAR.OptionsFrame.HeightSlider:SetPoint("LEFT", GVAR.OptionsFrame.HeightTitle, "RIGHT", 20, 0)
	GVAR.OptionsFrame.HeightValue:SetHeight(20)
	GVAR.OptionsFrame.HeightValue:SetPoint("LEFT", GVAR.OptionsFrame.HeightSlider, "RIGHT", 5, 0)
	GVAR.OptionsFrame.HeightValue:SetJustifyH("LEFT")
	GVAR.OptionsFrame.HeightValue:SetText(OPT.ButtonHeight[currentSize].."px")
	GVAR.OptionsFrame.HeightValue:SetTextColor(1, 1, 0.49, 1)
	local sw = GVAR.OptionsFrame.HeightTitle:GetStringWidth()
	if sw > sliderW then
		sliderW = sw
	end

	GVAR.OptionsFrame.FontSlider:SetPoint("LEFT", GVAR.OptionsFrame.FontTitle, "LEFT", sliderW+10, 0)
	GVAR.OptionsFrame.ScaleSlider:SetPoint("LEFT", GVAR.OptionsFrame.ScaleTitle, "LEFT", sliderW+10, 0)
	GVAR.OptionsFrame.WidthSlider:SetPoint("LEFT", GVAR.OptionsFrame.WidthTitle, "LEFT", sliderW+10, 0)
	GVAR.OptionsFrame.HeightSlider:SetPoint("LEFT", GVAR.OptionsFrame.HeightTitle, "LEFT", sliderW+10, 0)
	-- ----- sliders ----------------------------------------



	GVAR.OptionsFrame.Dummy2 = CreateFrame("Frame", nil, GVAR.OptionsFrame)
	TEMPLATE.BorderTRBL(GVAR.OptionsFrame.Dummy2)
	GVAR.OptionsFrame.Dummy2:SetWidth(frameWidth)
	GVAR.OptionsFrame.Dummy2:SetHeight(1)
	GVAR.OptionsFrame.Dummy2:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 0, 0)
	GVAR.OptionsFrame.Dummy2:SetPoint("TOP", GVAR.OptionsFrame.HeightSlider, "BOTTOM", 0, -10)



	-- general settings
	GVAR.OptionsFrame.General = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	GVAR.OptionsFrame.General:SetHeight(20)
	GVAR.OptionsFrame.General:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.General:SetPoint("TOP", GVAR.OptionsFrame.Dummy2, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.General:SetJustifyH("LEFT")
	GVAR.OptionsFrame.General:SetText(L["General Settings"]..":")

	-- minimap button
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

	-- close
	GVAR.OptionsFrame.CloseConfig = CreateFrame("Button", nil, GVAR.OptionsFrame)
	TEMPLATE.TextButton(GVAR.OptionsFrame.CloseConfig, L["Close Configuration"], 1)
	GVAR.OptionsFrame.CloseConfig:SetPoint("TOP", GVAR.OptionsFrame.Minimap, "BOTTOM", 0, -15)
	GVAR.OptionsFrame.CloseConfig:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.CloseConfig:SetWidth(frameWidth-20)
	GVAR.OptionsFrame.CloseConfig:SetHeight(30)
	GVAR.OptionsFrame.CloseConfig:SetScript("OnClick", function() GVAR.OptionsFrame:Hide() end)



	-- ----- setup width ----------------------------------------
	frameWidth = 10 + iconW + 10 + GVAR.OptionsFrame.TargetScaleSlider:GetWidth() + 50 + GVAR.OptionsFrame.TargetPositionSlider:GetWidth() + 50
	if rangeW > frameWidth then
		frameWidth = rangeW
	end
	if frameWidth < 400 then frameWidth = 400 end
	GVAR.OptionsFrame:SetClampRectInsets((frameWidth-50)/2, -((frameWidth-50)/2), -(frameHeight-35), frameHeight-35)
	GVAR.OptionsFrame:SetWidth(frameWidth)
	GVAR.OptionsFrame.Base:SetWidth(frameWidth)
	GVAR.OptionsFrame.Title:SetWidth(frameWidth)
	GVAR.OptionsFrame.TitleWarning:SetWidth(frameWidth)
	local tabWidth = math_floor( (frameWidth/3)-10 )
	local w1 = ( frameWidth-(3*tabWidth)-(2*5) ) / 2
	GVAR.OptionsFrame.TestRaidSize10:SetWidth(tabWidth)
	GVAR.OptionsFrame.TestRaidSize15:SetWidth(tabWidth)
	GVAR.OptionsFrame.TestRaidSize40:SetWidth(tabWidth)
	GVAR.OptionsFrame.TestRaidSize10:SetPoint("BOTTOMLEFT", GVAR.OptionsFrame.Base, "BOTTOMLEFT", w1, -1)
	GVAR.OptionsFrame.TestRaidSize15:SetPoint("BOTTOMLEFT", GVAR.OptionsFrame.Base, "BOTTOMLEFT", w1+(tabWidth+5), -1)
	GVAR.OptionsFrame.TestRaidSize40:SetPoint("BOTTOMLEFT", GVAR.OptionsFrame.Base, "BOTTOMLEFT", w1+((tabWidth+5)*2), -1)
	GVAR.OptionsFrame.Dummy1:SetWidth(frameWidth-26-26)
	GVAR.OptionsFrame.Dummy2:SetWidth(frameWidth)
	GVAR.OptionsFrame.CloseConfig:SetWidth(frameWidth-20)
	-- ----- setup width ----------------------------------------



	-- testshuffler
	GVAR.OptionsFrame.TestShuffler = CreateFrame("Button", nil, GVAR.OptionsFrame)
	GVAR.OptionsFrame.TestShuffler.shuffleStyle = true
	GVAR.OptionsFrame.TestShuffler:SetPoint("BOTTOM", GVAR.OptionsFrame.HeightSlider, "BOTTOM", 0, 0)
	GVAR.OptionsFrame.TestShuffler:SetPoint("RIGHT", GVAR.OptionsFrame, "RIGHT", -10, 0)
	GVAR.OptionsFrame.TestShuffler:SetWidth(32)
	GVAR.OptionsFrame.TestShuffler:SetHeight(32)
	GVAR.OptionsFrame.TestShuffler:Hide()
	GVAR.OptionsFrame.TestShuffler:SetScript("OnClick", function() BattlegroundTargets:ShufflerFunc("OnClick") end)
	GVAR.OptionsFrame.TestShuffler:SetScript("OnEnter", function() BattlegroundTargets:ShufflerFunc("OnEnter") end)
	GVAR.OptionsFrame.TestShuffler:SetScript("OnLeave", function() BattlegroundTargets:ShufflerFunc("OnLeave") end)
	GVAR.OptionsFrame.TestShuffler:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then BattlegroundTargets:ShufflerFunc("OnMouseDown") end
	end)
	GVAR.OptionsFrame.TestShuffler.Texture = GVAR.OptionsFrame.TestShuffler:CreateTexture(nil, "ARTWORK")
	GVAR.OptionsFrame.TestShuffler.Texture:SetWidth(32)
	GVAR.OptionsFrame.TestShuffler.Texture:SetHeight(32)
	GVAR.OptionsFrame.TestShuffler.Texture:SetPoint("CENTER", 0, 0)
	GVAR.OptionsFrame.TestShuffler.Texture:SetTexture("Interface\\Icons\\INV_Sigil_Thorim")
	GVAR.OptionsFrame.TestShuffler:SetNormalTexture(GVAR.OptionsFrame.TestShuffler.Texture)
	GVAR.OptionsFrame.TestShuffler.TextureHighlight = GVAR.OptionsFrame.TestShuffler:CreateTexture(nil, "OVERLAY")
	GVAR.OptionsFrame.TestShuffler.TextureHighlight:SetWidth(32)
	GVAR.OptionsFrame.TestShuffler.TextureHighlight:SetHeight(32)
	GVAR.OptionsFrame.TestShuffler.TextureHighlight:SetPoint("CENTER", 0, 0)
	GVAR.OptionsFrame.TestShuffler.TextureHighlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
	GVAR.OptionsFrame.TestShuffler:SetHighlightTexture(GVAR.OptionsFrame.TestShuffler.TextureHighlight)

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
	GVAR.OptionsFrame.EnableBracket:SetChecked(BattlegroundTargets_Options.EnableBracket[currentSize])
	GVAR.OptionsFrame.IndependentPos:SetChecked(BattlegroundTargets_Options.IndependentPositioning[currentSize])

	if currentSize == 10 then
		GVAR.OptionsFrame.CopySettings:SetText(string_format(L["Copy this settings to '%s'"], L["15 vs 15"]))
	elseif currentSize == 15 then
		GVAR.OptionsFrame.CopySettings:SetText(string_format(L["Copy this settings to '%s'"], L["10 vs 10"]))
	end

	GVAR.OptionsFrame.ShowSpec:SetChecked(OPT.ButtonShowSpec[currentSize])
	GVAR.OptionsFrame.ClassIcon:SetChecked(OPT.ButtonClassIcon[currentSize])
	GVAR.OptionsFrame.ShowLeader:SetChecked(OPT.ButtonShowLeader[currentSize])
	GVAR.OptionsFrame.ShowRealm:SetChecked(OPT.ButtonHideRealm[currentSize])

	GVAR.OptionsFrame.ShowTargetIndicator:SetChecked(OPT.ButtonShowTarget[currentSize])
	GVAR.OptionsFrame.TargetScaleSlider:SetValue(OPT.ButtonTargetScale[currentSize]*100)
	GVAR.OptionsFrame.TargetScaleSliderText:SetText((OPT.ButtonTargetScale[currentSize]*100).."%")
	GVAR.OptionsFrame.TargetPositionSlider:SetValue(OPT.ButtonTargetPosition[currentSize])
	GVAR.OptionsFrame.TargetPositionSliderText:SetText(OPT.ButtonTargetPosition[currentSize])

	GVAR.OptionsFrame.ShowFocusIndicator:SetChecked(OPT.ButtonShowFocus[currentSize])
	GVAR.OptionsFrame.FocusScaleSlider:SetValue(OPT.ButtonFocusScale[currentSize]*100)
	GVAR.OptionsFrame.FocusScaleSliderText:SetText((OPT.ButtonFocusScale[currentSize]*100).."%")
	GVAR.OptionsFrame.FocusPositionSlider:SetValue(OPT.ButtonFocusPosition[currentSize])
	GVAR.OptionsFrame.FocusPositionSliderText:SetText(OPT.ButtonFocusPosition[currentSize])

	GVAR.OptionsFrame.ShowFlag:SetChecked(OPT.ButtonShowFlag[currentSize])
	GVAR.OptionsFrame.FlagScaleSlider:SetValue(OPT.ButtonFlagScale[currentSize]*100)
	GVAR.OptionsFrame.FlagScaleSliderText:SetText((OPT.ButtonFlagScale[currentSize]*100).."%")
	GVAR.OptionsFrame.FlagPositionSlider:SetValue(OPT.ButtonFlagPosition[currentSize])
	GVAR.OptionsFrame.FlagPositionSliderText:SetText(OPT.ButtonFlagPosition[currentSize])

	GVAR.OptionsFrame.ShowAssist:SetChecked(OPT.ButtonShowAssist[currentSize])
	GVAR.OptionsFrame.AssistScaleSlider:SetValue(OPT.ButtonAssistScale[currentSize]*100)
	GVAR.OptionsFrame.AssistScaleSliderText:SetText((OPT.ButtonAssistScale[currentSize]*100).."%")
	GVAR.OptionsFrame.AssistPositionSlider:SetValue(OPT.ButtonAssistPosition[currentSize])
	GVAR.OptionsFrame.AssistPositionSliderText:SetText(OPT.ButtonAssistPosition[currentSize])

	GVAR.OptionsFrame.ShowTargetCount:SetChecked(OPT.ButtonShowTargetCount[currentSize])

	GVAR.OptionsFrame.ShowHealthBar:SetChecked(OPT.ButtonShowHealthBar[currentSize])
	GVAR.OptionsFrame.ShowHealthText:SetChecked(OPT.ButtonShowHealthText[currentSize])

	GVAR.OptionsFrame.RangeCheck:SetChecked(OPT.ButtonRangeCheck[currentSize])
	GVAR.OptionsFrame.RangeCheckTypePullDown.PullDownButtonText:SetText(rangeTypeName[1])
	if OPT.ButtonClassRangeCheck[currentSize] then
		GVAR.OptionsFrame.RangeCheckTypePullDown.PullDownButtonText:SetText(rangeTypeName[2])
	end
	GVAR.OptionsFrame.RangeAlphaSlider:SetValue(OPT.ButtonRangeAlpha[currentSize]*100)
	GVAR.OptionsFrame.RangeAlphaValue:SetText((OPT.ButtonRangeAlpha[currentSize]*100).."%")

	GVAR.OptionsFrame.SortByPullDown.PullDownButtonText:SetText(sortBy[ OPT.ButtonSortBy[currentSize] ])
	GVAR.OptionsFrame.SortDetailPullDown.PullDownButtonText:SetText(sortDetail[ OPT.ButtonSortDetail[currentSize] ])
	local ButtonSortBy = OPT.ButtonSortBy[currentSize]
	if ButtonSortBy == 1 or ButtonSortBy == 3 or ButtonSortBy == 4 then
		GVAR.OptionsFrame.SortDetailPullDown:Show()
		GVAR.OptionsFrame.SortInfo:Show()
	else
		GVAR.OptionsFrame.SortDetailPullDown:Hide()
		GVAR.OptionsFrame.SortInfo:Hide()
	end

	GVAR.OptionsFrame.FontSlider:SetValue(OPT.ButtonFontSize[currentSize])
	GVAR.OptionsFrame.FontValue:SetText(OPT.ButtonFontSize[currentSize])

	GVAR.OptionsFrame.ScaleSlider:SetValue(OPT.ButtonScale[currentSize]*100)
	GVAR.OptionsFrame.ScaleValue:SetText((OPT.ButtonScale[currentSize]*100).."%")

	GVAR.OptionsFrame.WidthSlider:SetValue(OPT.ButtonWidth[currentSize])
	GVAR.OptionsFrame.WidthValue:SetText(OPT.ButtonWidth[currentSize].."px")

	GVAR.OptionsFrame.HeightSlider:SetValue(OPT.ButtonHeight[currentSize])
	GVAR.OptionsFrame.HeightValue:SetText(OPT.ButtonHeight[currentSize].."px")
end

function BattlegroundTargets:CheckForEnabledBracket(bracketSize)
	if BattlegroundTargets_Options.EnableBracket[bracketSize] then
		if bracketSize == 10 then
			GVAR.OptionsFrame.TestRaidSize10.Text:SetTextColor(0, 0.75, 0, 1)
		elseif bracketSize == 15 then
			GVAR.OptionsFrame.TestRaidSize15.Text:SetTextColor(0, 0.75, 0, 1)
		elseif bracketSize == 40 then
			GVAR.OptionsFrame.TestRaidSize40.Text:SetTextColor(0, 0.75, 0, 1)
		end

		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.IndependentPos)

		if bracketSize == 40 then
 			GVAR.OptionsFrame.CopySettings:Hide()
		else
			GVAR.OptionsFrame.CopySettings:Show()
			TEMPLATE.EnableTextButton(GVAR.OptionsFrame.CopySettings, 4)
		end

		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowSpec)
		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ClassIcon)
		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowLeader)
		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowRealm)

		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowTargetIndicator)
		if OPT.ButtonShowTarget[bracketSize] then
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.TargetScaleSlider)
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.TargetPositionSlider)
		else
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.TargetScaleSlider)
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.TargetPositionSlider)
		end
		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowFocusIndicator)
		if OPT.ButtonShowFocus[bracketSize] then
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.FocusScaleSlider)
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.FocusPositionSlider)
		else
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.FocusScaleSlider)
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.FocusPositionSlider)
		end
		if bracketSize == 40 then
			TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowFlag)
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.FlagScaleSlider)
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.FlagPositionSlider)
		else
			TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowFlag)
			if OPT.ButtonShowFlag[bracketSize] then
				TEMPLATE.EnableSlider(GVAR.OptionsFrame.FlagScaleSlider)
				TEMPLATE.EnableSlider(GVAR.OptionsFrame.FlagPositionSlider)
			else
				TEMPLATE.DisableSlider(GVAR.OptionsFrame.FlagScaleSlider)
				TEMPLATE.DisableSlider(GVAR.OptionsFrame.FlagPositionSlider)
			end
		end
		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowAssist)
		if OPT.ButtonShowAssist[bracketSize] then
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.AssistScaleSlider)
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.AssistPositionSlider)
		else
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.AssistScaleSlider)
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.AssistPositionSlider)
		end

		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowTargetCount)

		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowHealthBar)
		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowHealthText)

		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.RangeCheck)
		if OPT.ButtonRangeCheck[bracketSize] then
			TEMPLATE.EnablePullDownMenu(GVAR.OptionsFrame.RangeCheckTypePullDown)
			GVAR.OptionsFrame.RangeCheckInfo:Enable() Desaturation(GVAR.OptionsFrame.RangeCheckInfo.Texture, false)
			TEMPLATE.EnableSlider(GVAR.OptionsFrame.RangeAlphaSlider)
		else
			TEMPLATE.DisablePullDownMenu(GVAR.OptionsFrame.RangeCheckTypePullDown)
			GVAR.OptionsFrame.RangeCheckInfo:Disable() Desaturation(GVAR.OptionsFrame.RangeCheckInfo.Texture, true)
			TEMPLATE.DisableSlider(GVAR.OptionsFrame.RangeAlphaSlider)
		end

		TEMPLATE.EnablePullDownMenu(GVAR.OptionsFrame.SortByPullDown)
		GVAR.OptionsFrame.SortByTitle:SetTextColor(1, 1, 1, 1)
		TEMPLATE.EnablePullDownMenu(GVAR.OptionsFrame.SortDetailPullDown)
		GVAR.OptionsFrame.SortInfo:Enable() Desaturation(GVAR.OptionsFrame.SortInfo.Texture, false)

		TEMPLATE.EnableSlider(GVAR.OptionsFrame.FontSlider)
		GVAR.OptionsFrame.FontTitle:SetTextColor(1, 1, 1, 1)
		TEMPLATE.EnableSlider(GVAR.OptionsFrame.ScaleSlider)
		GVAR.OptionsFrame.ScaleTitle:SetTextColor(1, 1, 1, 1)
		TEMPLATE.EnableSlider(GVAR.OptionsFrame.WidthSlider)
		GVAR.OptionsFrame.WidthTitle:SetTextColor(1, 1, 1, 1)
		TEMPLATE.EnableSlider(GVAR.OptionsFrame.HeightSlider)
		GVAR.OptionsFrame.HeightTitle:SetTextColor(1, 1, 1, 1)
		GVAR.OptionsFrame.TestShuffler:Show()
	else
		if bracketSize == 10 then
			GVAR.OptionsFrame.TestRaidSize10.Text:SetTextColor(1, 0, 0, 1)
		elseif bracketSize == 15 then
			GVAR.OptionsFrame.TestRaidSize15.Text:SetTextColor(1, 0, 0, 1)
		elseif bracketSize == 40 then
			GVAR.OptionsFrame.TestRaidSize40.Text:SetTextColor(1, 0, 0, 1)
		end

		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.IndependentPos)

		if bracketSize == 40 then
 			GVAR.OptionsFrame.CopySettings:Hide()
		else
			GVAR.OptionsFrame.CopySettings:Show()
			TEMPLATE.DisableTextButton(GVAR.OptionsFrame.CopySettings, 4)
		end

		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowSpec)
		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ClassIcon)
		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowLeader)
		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowRealm)

		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowTargetIndicator)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.TargetScaleSlider)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.TargetPositionSlider)
		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowFocusIndicator)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.FocusScaleSlider)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.FocusPositionSlider)
		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowFlag)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.FlagScaleSlider)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.FlagPositionSlider)
		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowAssist)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.AssistScaleSlider)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.AssistPositionSlider)

		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowTargetCount)

		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowHealthBar)
		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowHealthText)

		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.RangeCheck)
		TEMPLATE.DisablePullDownMenu(GVAR.OptionsFrame.RangeCheckTypePullDown)
		GVAR.OptionsFrame.RangeCheckInfo:Disable() Desaturation(GVAR.OptionsFrame.RangeCheckInfo.Texture, true)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.RangeAlphaSlider)

		TEMPLATE.DisablePullDownMenu(GVAR.OptionsFrame.SortByPullDown)
		GVAR.OptionsFrame.SortByTitle:SetTextColor(0.5, 0.5, 0.5, 1)
		TEMPLATE.DisablePullDownMenu(GVAR.OptionsFrame.SortDetailPullDown)
		GVAR.OptionsFrame.SortInfo:Disable() Desaturation(GVAR.OptionsFrame.SortInfo.Texture, true)

		TEMPLATE.DisableSlider(GVAR.OptionsFrame.FontSlider)
		GVAR.OptionsFrame.FontTitle:SetTextColor(0.5, 0.5, 0.5, 1)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.ScaleSlider)
		GVAR.OptionsFrame.ScaleTitle:SetTextColor(0.5, 0.5, 0.5, 1)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.WidthSlider)
		GVAR.OptionsFrame.WidthTitle:SetTextColor(0.5, 0.5, 0.5, 1)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.HeightSlider)
		GVAR.OptionsFrame.HeightTitle:SetTextColor(0.5, 0.5, 0.5, 1)
		GVAR.OptionsFrame.TestShuffler:Hide()
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

	TEMPLATE.DisableTextButton(GVAR.OptionsFrame.CopySettings)

	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowSpec)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ClassIcon)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowLeader)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowRealm)

	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowTargetIndicator)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.TargetScaleSlider)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.TargetPositionSlider)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowFocusIndicator)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.FocusScaleSlider)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.FocusPositionSlider)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowFlag)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.FlagScaleSlider)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.FlagPositionSlider)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowAssist)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.AssistScaleSlider)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.AssistPositionSlider)

	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowTargetCount)

	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowHealthBar)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowHealthText)

	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.RangeCheck)
	TEMPLATE.DisablePullDownMenu(GVAR.OptionsFrame.RangeCheckTypePullDown)
	GVAR.OptionsFrame.RangeCheckInfo:Disable() Desaturation(GVAR.OptionsFrame.RangeCheckInfo.Texture, true)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.RangeAlphaSlider)

	TEMPLATE.DisablePullDownMenu(GVAR.OptionsFrame.SortByPullDown)
	GVAR.OptionsFrame.SortByTitle:SetTextColor(0.5, 0.5, 0.5, 1)
	TEMPLATE.DisablePullDownMenu(GVAR.OptionsFrame.SortDetailPullDown)
	GVAR.OptionsFrame.SortInfo:Disable() Desaturation(GVAR.OptionsFrame.SortInfo.Texture, true)

	TEMPLATE.DisableSlider(GVAR.OptionsFrame.FontSlider)
	GVAR.OptionsFrame.FontTitle:SetTextColor(0.5, 0.5, 0.5, 1)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.ScaleSlider)
	GVAR.OptionsFrame.ScaleTitle:SetTextColor(0.5, 0.5, 0.5, 1)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.WidthSlider)
	GVAR.OptionsFrame.WidthTitle:SetTextColor(0.5, 0.5, 0.5, 1)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.HeightSlider)
	GVAR.OptionsFrame.HeightTitle:SetTextColor(0.5, 0.5, 0.5, 1)
	GVAR.OptionsFrame.TestShuffler:Hide()
end

function BattlegroundTargets:EnableInsecureConfigWidges()
	GVAR.OptionsFrame.TitleWarning:SetText(L["Out of combat: Configuration enabled."])
	GVAR.OptionsFrame.TitleWarning:SetTextColor(0, 0.75, 0, 1)

	TEMPLATE.EnableTabButton(GVAR.OptionsFrame.TestRaidSize10, BattlegroundTargets_Options.EnableBracket[10])
	TEMPLATE.EnableTabButton(GVAR.OptionsFrame.TestRaidSize15, BattlegroundTargets_Options.EnableBracket[15])
	TEMPLATE.EnableTabButton(GVAR.OptionsFrame.TestRaidSize40, BattlegroundTargets_Options.EnableBracket[40])

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

	local ButtonScale           = OPT.ButtonScale[currentSize]
	local ButtonWidth           = OPT.ButtonWidth[currentSize]
	local ButtonHeight          = OPT.ButtonHeight[currentSize]
	local ButtonFontSize        = OPT.ButtonFontSize[currentSize]
	local ButtonShowSpec        = OPT.ButtonShowSpec[currentSize]
	local ButtonClassIcon       = OPT.ButtonClassIcon[currentSize]
	local ButtonShowTargetCount = OPT.ButtonShowTargetCount[currentSize]
	local ButtonShowTarget      = OPT.ButtonShowTarget[currentSize]
	local ButtonTargetScale     = OPT.ButtonTargetScale[currentSize]
	local ButtonTargetPosition  = OPT.ButtonTargetPosition[currentSize]
	local ButtonShowFocus       = OPT.ButtonShowFocus[currentSize]
	local ButtonFocusScale      = OPT.ButtonFocusScale[currentSize]
	local ButtonFocusPosition   = OPT.ButtonFocusPosition[currentSize]
	local ButtonShowFlag        = OPT.ButtonShowFlag[currentSize]
	local ButtonFlagScale       = OPT.ButtonFlagScale[currentSize]
	local ButtonFlagPosition    = OPT.ButtonFlagPosition[currentSize]
	local ButtonShowAssist      = OPT.ButtonShowAssist[currentSize]
	local ButtonAssistScale     = OPT.ButtonAssistScale[currentSize]
	local ButtonAssistPosition  = OPT.ButtonAssistPosition[currentSize]
	local ButtonRangeCheck      = OPT.ButtonRangeCheck[currentSize]

	local backfallFontSize = ButtonFontSize
	if ButtonHeight < ButtonFontSize then
		backfallFontSize = ButtonHeight
	end

	local withIconWidth
	if ButtonShowSpec and ButtonClassIcon then
		if ButtonRangeCheck then
			withIconWidth = (ButtonWidth - ( ((ButtonHeight-2)*3) + ((ButtonHeight-2)/2) ) ) - 2
		else
			withIconWidth = (ButtonWidth - ((ButtonHeight-2)*3)) - 2
		end
	elseif ButtonShowSpec or ButtonClassIcon then
		if ButtonRangeCheck then
			withIconWidth = (ButtonWidth - ( ((ButtonHeight-2)*2) + ((ButtonHeight-2)/2) ) ) - 2
		else
			withIconWidth = (ButtonWidth - ((ButtonHeight-2)*2)) - 2
		end
	else
		if ButtonRangeCheck then
			withIconWidth = (ButtonWidth - ( ((ButtonHeight-2)*1) + ((ButtonHeight-2)/2) ) ) - 2
		else
			withIconWidth = (ButtonWidth - ((ButtonHeight-2)*1)) - 2
		end
	end

	for i = 1, 40 do
		GVAR.TargetButton[i]:SetScale(ButtonScale)

		GVAR.TargetButton[i]:SetWidth(ButtonWidth)
		GVAR.TargetButton[i]:SetHeight(ButtonHeight)
		GVAR.TargetButton[i].HighlightT:SetWidth(ButtonWidth)
		GVAR.TargetButton[i].HighlightR:SetHeight(ButtonHeight)
		GVAR.TargetButton[i].HighlightB:SetWidth(ButtonWidth)
		GVAR.TargetButton[i].HighlightL:SetHeight(ButtonHeight)
		GVAR.TargetButton[i].Background:SetWidth(ButtonWidth-2)
		GVAR.TargetButton[i].Background:SetHeight(ButtonHeight-2)

		if ButtonRangeCheck then
			GVAR.TargetButton[i].RangeTexture:Show()
			GVAR.TargetButton[i].RangeTexture:SetWidth((ButtonHeight-2)/2)
			GVAR.TargetButton[i].RangeTexture:SetHeight(ButtonHeight-2)
			GVAR.TargetButton[i].RoleTexture:SetPoint("LEFT", GVAR.TargetButton[i].RangeTexture, "RIGHT", 0, 0)
		else
			GVAR.TargetButton[i].RangeTexture:Hide()
			GVAR.TargetButton[i].RoleTexture:SetPoint("LEFT", GVAR.TargetButton[i], "LEFT", 1, 0)
		end
		GVAR.TargetButton[i].RoleTexture:SetWidth(ButtonHeight-2)
		GVAR.TargetButton[i].RoleTexture:SetHeight(ButtonHeight-2)
		GVAR.TargetButton[i].SpecTexture:SetWidth(ButtonHeight-2)
		GVAR.TargetButton[i].SpecTexture:SetHeight(ButtonHeight-2)
		GVAR.TargetButton[i].ClassTexture:SetWidth(ButtonHeight-2)
		GVAR.TargetButton[i].ClassTexture:SetHeight(ButtonHeight-2)
		GVAR.TargetButton[i].LeaderTexture:SetWidth((ButtonHeight-2)/1.5)
		GVAR.TargetButton[i].LeaderTexture:SetHeight((ButtonHeight-2)/1.5)
		GVAR.TargetButton[i].LeaderTexture:SetPoint("LEFT", GVAR.TargetButton[i], "LEFT", -((ButtonHeight-2)/1.5)/2, 0)

		GVAR.TargetButton[i].ClassColorBackground:SetHeight(ButtonHeight-2)
		GVAR.TargetButton[i].HealthBar:SetHeight(ButtonHeight-2)

		if ButtonShowSpec and ButtonClassIcon then
			GVAR.TargetButton[i].SpecTexture:Show()
			GVAR.TargetButton[i].ClassTexture:Show()
			GVAR.TargetButton[i].ClassTexture:SetPoint("LEFT", GVAR.TargetButton[i].SpecTexture, "RIGHT", 0, 0)
			GVAR.TargetButton[i].ClassColorBackground:SetPoint("LEFT", GVAR.TargetButton[i].ClassTexture, "RIGHT", 0, 0)
			GVAR.TargetButton[i].Name:SetPoint("LEFT", GVAR.TargetButton[i].ClassTexture, "RIGHT", 2, 0)
		elseif ButtonShowSpec then
			GVAR.TargetButton[i].SpecTexture:Show()
			GVAR.TargetButton[i].ClassTexture:Hide()
			GVAR.TargetButton[i].ClassColorBackground:SetPoint("LEFT", GVAR.TargetButton[i].SpecTexture, "RIGHT", 0, 0)
			GVAR.TargetButton[i].Name:SetPoint("LEFT", GVAR.TargetButton[i].SpecTexture, "RIGHT", 2, 0)
		elseif ButtonClassIcon then
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

		GVAR.TargetButton[i].Name:SetFont(fontPath, ButtonFontSize, "")
		GVAR.TargetButton[i].Name:SetShadowOffset(0, 0)
		GVAR.TargetButton[i].Name:SetShadowColor(0, 0, 0, 0)
		GVAR.TargetButton[i].Name:SetTextColor(0, 0, 0, 1)
		GVAR.TargetButton[i].Name:SetHeight(backfallFontSize)

		GVAR.TargetButton[i].HealthText:SetFont(fontPath, ButtonFontSize, "OUTLINE")
		GVAR.TargetButton[i].HealthText:SetShadowOffset(0, 0)
		GVAR.TargetButton[i].HealthText:SetShadowColor(0, 0, 0, 0)
		GVAR.TargetButton[i].HealthText:SetTextColor(1, 1, 1, 1)
		GVAR.TargetButton[i].HealthText:SetHeight(backfallFontSize)
		GVAR.TargetButton[i].HealthText:SetAlpha(0.6)

		if ButtonShowTargetCount then
			healthBarWidth = withIconWidth-20
			GVAR.TargetButton[i].ClassColorBackground:SetWidth(withIconWidth-20)
			GVAR.TargetButton[i].HealthBar:SetWidth(withIconWidth-20)
			GVAR.TargetButton[i].Name:SetWidth(withIconWidth-20-2)
			GVAR.TargetButton[i].TargetCountBackground:SetHeight(ButtonHeight-2)
			GVAR.TargetButton[i].TargetCountBackground:Show()
			GVAR.TargetButton[i].TargetCount:SetFont(fontPath, ButtonFontSize, "")
			GVAR.TargetButton[i].TargetCount:SetShadowOffset(0, 0)
			GVAR.TargetButton[i].TargetCount:SetShadowColor(0, 0, 0, 0)
			GVAR.TargetButton[i].TargetCount:SetHeight(backfallFontSize)
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

		if ButtonShowTarget then
			local quad = (ButtonHeight-2) * ButtonTargetScale
			GVAR.TargetButton[i].TargetTexture:SetWidth(quad)
			GVAR.TargetButton[i].TargetTexture:SetHeight(quad)
			local leftPos = -((ButtonHeight-2) * ButtonTargetScale)
			if ButtonTargetPosition >= 100 then
				leftPos = ButtonWidth
			elseif ButtonTargetPosition > 0 then
				leftPos = ( (((ButtonHeight-2) * ButtonTargetScale) + ButtonWidth) * (ButtonTargetPosition/100) ) - ((ButtonHeight-2) * ButtonTargetScale)
			end
			GVAR.TargetButton[i].TargetTexture:SetPoint("LEFT", GVAR.TargetButton[i], "LEFT", leftPos, 0)
			GVAR.TargetButton[i].TargetTexture:Show()
		else
			GVAR.TargetButton[i].TargetTexture:Hide()
		end

		if ButtonShowFocus then
			local quad = (ButtonHeight-2) * ButtonFocusScale
			GVAR.TargetButton[i].FocusTexture:SetWidth(quad)
			GVAR.TargetButton[i].FocusTexture:SetHeight(quad)
			local leftPos = -((ButtonHeight-2) * ButtonFocusScale)
			if ButtonFocusPosition >= 100 then
				leftPos = ButtonWidth
			elseif ButtonFocusPosition > 0 then
				leftPos = ( (((ButtonHeight-2) * ButtonFocusScale) + ButtonWidth) * (ButtonFocusPosition/100) ) - ((ButtonHeight-2) * ButtonFocusScale)
			end
			GVAR.TargetButton[i].FocusTexture:SetPoint("LEFT", GVAR.TargetButton[i], "LEFT", leftPos, 0)
			GVAR.TargetButton[i].FocusTexture:Show()
		else
			GVAR.TargetButton[i].FocusTexture:Hide()
		end

		if ButtonShowFlag then
			local quad = (ButtonHeight-2) * ButtonFlagScale
			GVAR.TargetButton[i].FlagTexture:SetWidth(quad)
			GVAR.TargetButton[i].FlagTexture:SetHeight(quad)
			local leftPos = -((ButtonHeight-2) * ButtonFlagScale)
			if ButtonFlagPosition >= 100 then
				leftPos = ButtonWidth
			elseif ButtonFlagPosition > 0 then
				leftPos = ( (((ButtonHeight-2) * ButtonFlagScale) + ButtonWidth) * (ButtonFlagPosition/100) ) - ((ButtonHeight-2) * ButtonFlagScale)
			end
			GVAR.TargetButton[i].FlagTexture:SetPoint("LEFT", GVAR.TargetButton[i], "LEFT", leftPos, 0)
			GVAR.TargetButton[i].FlagTexture:Show()
		else
			GVAR.TargetButton[i].FlagTexture:Hide()
		end

		if ButtonShowAssist then
			local quad = (ButtonHeight-2) * ButtonAssistScale
			GVAR.TargetButton[i].AssistTexture:SetWidth(quad)
			GVAR.TargetButton[i].AssistTexture:SetHeight(quad)
			local leftPos = -((ButtonHeight-2) * ButtonAssistScale)
			if ButtonAssistPosition >= 100 then
				leftPos = ButtonWidth
			elseif ButtonAssistPosition > 0 then
				leftPos = ( (((ButtonHeight-2) * ButtonAssistScale) + ButtonWidth) * (ButtonAssistPosition/100) ) - ((ButtonHeight-2) * ButtonAssistScale)
			end
			GVAR.TargetButton[i].AssistTexture:SetPoint("LEFT", GVAR.TargetButton[i], "LEFT", leftPos, 0)
			GVAR.TargetButton[i].AssistTexture:Show()
		else
			GVAR.TargetButton[i].AssistTexture:Hide()
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
	--GVAR.MainFrame:StartMoving()
	--GVAR.MainFrame:StopMovingOrSizing()
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

	if BattlegroundTargets_Options.EnableBracket[testSize] then
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
		ENEMY_Data[1].name = TARGET.."_Aa-Alterac Mountains"
		ENEMY_Data[1].classToken = "DRUID"
		ENEMY_Data[1].talentSpec = T.DRUID[3]
		ENEMY_Data[2] = {}
		ENEMY_Data[2].name = TARGET.."_Bb-Ragnaros"
		ENEMY_Data[2].classToken = "PRIEST"
		ENEMY_Data[2].talentSpec = T.PRIEST[3]
		ENEMY_Data[3] = {}
		ENEMY_Data[3].name = TARGET.."_Cc-Blackrock"
		ENEMY_Data[3].classToken = "WARLOCK"
		ENEMY_Data[3].talentSpec = T.WARLOCK[1]
		ENEMY_Data[4] = {}
		ENEMY_Data[4].name = TARGET.."_Dd-Wildhammer"
		ENEMY_Data[4].classToken = "HUNTER"
		ENEMY_Data[4].talentSpec = T.HUNTER[3]
		ENEMY_Data[5] = {}
		ENEMY_Data[5].name = TARGET.."_Ee-Khaz'goroth"
		ENEMY_Data[5].classToken = "WARRIOR"
		ENEMY_Data[5].talentSpec = T.WARRIOR[3]
		ENEMY_Data[6] = {}
		ENEMY_Data[6].name = TARGET.."_Ff-Xavius"
		ENEMY_Data[6].classToken = "ROGUE"
		ENEMY_Data[6].talentSpec = T.ROGUE[2]
		ENEMY_Data[7] = {}
		ENEMY_Data[7].name = TARGET.."_Gg-Area 52"
		ENEMY_Data[7].classToken = "SHAMAN"
		ENEMY_Data[7].talentSpec = T.SHAMAN[3]
		ENEMY_Data[8] = {}
		ENEMY_Data[8].name = TARGET.."_Hh-Blackmoore"
		ENEMY_Data[8].classToken = "PALADIN"
		ENEMY_Data[8].talentSpec = T.PALADIN[3]
		ENEMY_Data[9] = {}
		ENEMY_Data[9].name = TARGET.."_Ii-Scarshield Legion"
		ENEMY_Data[9].classToken = "MAGE"
		ENEMY_Data[9].talentSpec = T.MAGE[3]
		ENEMY_Data[10] = {}
		ENEMY_Data[10].name = TARGET.."_Jj-Conseil des Ombres"
		ENEMY_Data[10].classToken = "DEATHKNIGHT"
		ENEMY_Data[10].talentSpec = T.DEATHKNIGHT[2]
		ENEMY_Data[11] = {}
		ENEMY_Data[11].name = TARGET.."_Kk-Archimonde"
		ENEMY_Data[11].classToken = "DRUID"
		ENEMY_Data[11].talentSpec = T.DRUID[1]
		ENEMY_Data[12] = {}
		ENEMY_Data[12].name = TARGET.."_Ll-Nefarian"
		ENEMY_Data[12].classToken = "DEATHKNIGHT"
		ENEMY_Data[12].talentSpec = T.DEATHKNIGHT[3]
		ENEMY_Data[13] = {}
		ENEMY_Data[13].name = TARGET.."_Mm-Trollbane"
		ENEMY_Data[13].classToken = "PALADIN"
		ENEMY_Data[13].talentSpec = T.PALADIN[3]
		ENEMY_Data[14] = {}
		ENEMY_Data[14].name = TARGET.."_Nn-Un'Goro"
		ENEMY_Data[14].classToken = "MAGE"
		ENEMY_Data[14].talentSpec = T.MAGE[1]
		ENEMY_Data[15] = {}
		ENEMY_Data[15].name = TARGET.."_Oo-Teldrassil"
		ENEMY_Data[15].classToken = "SHAMAN"
		ENEMY_Data[15].talentSpec = T.SHAMAN[2]
		ENEMY_Data[16] = {}
		ENEMY_Data[16].name = TARGET.."_Pp-Rexxar"
		ENEMY_Data[16].classToken = "ROGUE"
		ENEMY_Data[16].talentSpec = T.ROGUE[1]
		ENEMY_Data[17] = {}
		ENEMY_Data[17].name = TARGET.."_Qq-Gilneas"
		ENEMY_Data[17].classToken = "WARLOCK"
		ENEMY_Data[17].talentSpec = T.WARLOCK[2]
		ENEMY_Data[18] = {}
		ENEMY_Data[18].name = TARGET.."_Rr-Terokkar"
		ENEMY_Data[18].classToken = "PRIEST"
		ENEMY_Data[18].talentSpec = T.PRIEST[3]
		ENEMY_Data[19] = {}
		ENEMY_Data[19].name = TARGET.."_Ss-Zuluhed"
		ENEMY_Data[19].classToken = "WARRIOR"
		ENEMY_Data[19].talentSpec = T.WARRIOR[1]
		ENEMY_Data[20] = {}
		ENEMY_Data[20].name = TARGET.."_Tt-Archimonde"
		ENEMY_Data[20].classToken = "DRUID"
		ENEMY_Data[20].talentSpec = T.DRUID[2]
		ENEMY_Data[21] = {}
		ENEMY_Data[21].name = TARGET.."_Uu-Anub'arak"
		ENEMY_Data[21].classToken = "PRIEST"
		ENEMY_Data[21].talentSpec = T.PRIEST[3]
		ENEMY_Data[22] = {}
		ENEMY_Data[22].name = TARGET.."_Vv-Kul Tiras"
		ENEMY_Data[22].classToken = "WARRIOR"
		ENEMY_Data[22].talentSpec = T.WARRIOR[1]
		ENEMY_Data[23] = {}
		ENEMY_Data[23].name = TARGET.."_Ww-Garrosh"
		ENEMY_Data[23].classToken = "SHAMAN"
		ENEMY_Data[23].talentSpec = T.SHAMAN[1]
		ENEMY_Data[24] = {}
		ENEMY_Data[24].name = TARGET.."_Xx-Durotan"
		ENEMY_Data[24].classToken = "HUNTER"
		ENEMY_Data[24].talentSpec = T.HUNTER[2]
		ENEMY_Data[25] = {}
		ENEMY_Data[25].name = TARGET.."_Yy-Thrall"
		ENEMY_Data[25].classToken = "SHAMAN"
		ENEMY_Data[25].talentSpec = T.SHAMAN[2]
		ENEMY_Data[26] = {}
		ENEMY_Data[26].name = TARGET.."_Zz-Frostmourne"
		ENEMY_Data[26].classToken = "WARLOCK"
		ENEMY_Data[26].talentSpec = T.WARLOCK[3]
		ENEMY_Data[27] = {}
		ENEMY_Data[27].name = TARGET.."_Ab-Stormrage"
		ENEMY_Data[27].classToken = "PRIEST"
		ENEMY_Data[27].talentSpec = T.PRIEST[2]
		ENEMY_Data[28] = {}
		ENEMY_Data[28].name = TARGET.."_Cd-Les Sentinelles"
		ENEMY_Data[28].classToken = "MAGE"
		ENEMY_Data[28].talentSpec = T.MAGE[2]
		ENEMY_Data[29] = {}
		ENEMY_Data[29].name = TARGET.."_Ef-Arthas"
		ENEMY_Data[29].classToken = "ROGUE"
		ENEMY_Data[29].talentSpec = T.ROGUE[3]
		ENEMY_Data[30] = {}
		ENEMY_Data[30].name = TARGET.."_Gh-Bronzebeard"
		ENEMY_Data[30].classToken = "DRUID"
		ENEMY_Data[30].talentSpec = T.DRUID[1]
		ENEMY_Data[31] = {}
		ENEMY_Data[31].name = TARGET.."_Ij-Forscherliga"
		ENEMY_Data[31].classToken = "HUNTER"
		ENEMY_Data[31].talentSpec = T.HUNTER[3]
		ENEMY_Data[32] = {}
		ENEMY_Data[32].name = TARGET.."_Kl-Deephome"
		ENEMY_Data[32].classToken = "WARRIOR"
		ENEMY_Data[32].talentSpec = T.WARRIOR[2]
		ENEMY_Data[33] = {}
		ENEMY_Data[33].name = TARGET.."_Mn-Arthas"
		ENEMY_Data[33].classToken = "PALADIN"
		ENEMY_Data[33].talentSpec = T.PALADIN[1]
		ENEMY_Data[34] = {}
		ENEMY_Data[34].name = TARGET.."_Op-Blade's Edge"
		ENEMY_Data[34].classToken = "MAGE"
		ENEMY_Data[34].talentSpec = T.MAGE[3]
		ENEMY_Data[35] = {}
		ENEMY_Data[35].name = TARGET.."_Qr-Talnivarr"
		ENEMY_Data[35].classToken = "DEATHKNIGHT"
		ENEMY_Data[35].talentSpec =  T.DEATHKNIGHT[3]
		ENEMY_Data[36] = {}
		ENEMY_Data[36].name = TARGET.."_St-Steamwheedle Cartel"
		ENEMY_Data[36].classToken = "MAGE"
		ENEMY_Data[36].talentSpec = T.MAGE[2]
		ENEMY_Data[37] = {}
		ENEMY_Data[37].name = TARGET.."_Uv-Naxxramas"
		ENEMY_Data[37].classToken = "HUNTER"
		ENEMY_Data[37].talentSpec = T.HUNTER[2]
		ENEMY_Data[38] = {}
		ENEMY_Data[38].name = TARGET.."_Wx-Archimonde"
		ENEMY_Data[38].classToken = "WARLOCK"
		ENEMY_Data[38].talentSpec = T.WARLOCK[1]
		ENEMY_Data[39] = {}
		ENEMY_Data[39].name = TARGET.."_Yz-Nazjatar"
		ENEMY_Data[39].classToken = "WARLOCK"
		ENEMY_Data[39].talentSpec = T.WARLOCK[2]
		ENEMY_Data[40] = {}
		ENEMY_Data[40].name = TARGET.."_Zz-Drak'thul"
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

	GVAR.MainFrame:Show() -- HiDE
	GVAR.MainFrame:EnableMouse(true)
	GVAR.MainFrame:SetHeight(20)
	GVAR.MainFrame.Movetext:Show()
	GVAR.TargetButton[1]:SetPoint("TOPLEFT", GVAR.MainFrame, "BOTTOMLEFT", 0, 0)

	BattlegroundTargets:ShufflerFunc("ShuffleCheck")
	BattlegroundTargets:SetupButtonLayout()

	local ButtonShowHealthBar   = OPT.ButtonShowHealthBar[currentSize]
	local ButtonShowHealthText  = OPT.ButtonShowHealthText[currentSize]
	local ButtonRangeCheck      = OPT.ButtonRangeCheck[currentSize]
	local ButtonAvgRangeCheck   = OPT.ButtonAvgRangeCheck[currentSize]
	local ButtonClassRangeCheck = OPT.ButtonClassRangeCheck[currentSize]
	local ButtonRangeAlpha      = OPT.ButtonRangeAlpha[currentSize]

	for i = 1, 40 do
		GVAR.TargetButton[i].TargetTexture:SetAlpha(0)
		GVAR.TargetButton[i].HighlightT:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].HighlightR:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].HighlightB:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].HighlightL:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].TargetCount:SetText("0")
		GVAR.TargetButton[i].FocusTexture:SetAlpha(0)
		GVAR.TargetButton[i].HealthBar:SetWidth(healthBarWidth)
		GVAR.TargetButton[i].HealthText:SetText("")
		GVAR.TargetButton[i].FlagTexture:SetAlpha(0)
		GVAR.TargetButton[i].AssistTexture:SetAlpha(0)

		GVAR.TargetButton[i].ClassColorBackground:SetAlpha(1)
		GVAR.TargetButton[i].HealthBar:SetAlpha(1)
		GVAR.TargetButton[i].RoleTexture:SetAlpha(1)
		GVAR.TargetButton[i].SpecTexture:SetAlpha(1)
		GVAR.TargetButton[i].ClassTexture:SetAlpha(1)
		GVAR.TargetButton[i].LeaderTexture:SetAlpha(0)

		if i < currentSize+1 then

			if ButtonShowHealthBar or ButtonShowHealthText then
				if ButtonShowHealthBar then
					local width = healthBarWidth * (testHealth[i] / 100)
					width = math_max(0.01, width)
					width = math_min(healthBarWidth, width)
					GVAR.TargetButton[i].HealthBar:SetWidth( width )
				end
				if ButtonShowHealthText then
					GVAR.TargetButton[i].HealthText:SetText( testHealth[i] )
				end
			end

			if ButtonRangeCheck then
				if (ButtonAvgRangeCheck or ButtonClassRangeCheck) and testRange[i] < 40 then
					GVAR.TargetButton[i].RangeTexture:SetAlpha(1)
					GVAR.TargetButton[i].HealthBar:SetAlpha(1)
					GVAR.TargetButton[i].RoleTexture:SetAlpha(1)
					GVAR.TargetButton[i].SpecTexture:SetAlpha(1)
					GVAR.TargetButton[i].ClassTexture:SetAlpha(1)
				else
					GVAR.TargetButton[i].RangeTexture:SetAlpha(0)
					GVAR.TargetButton[i].HealthBar:SetAlpha(ButtonRangeAlpha)
					GVAR.TargetButton[i].RoleTexture:SetAlpha(ButtonRangeAlpha)
					GVAR.TargetButton[i].SpecTexture:SetAlpha(ButtonRangeAlpha)
					GVAR.TargetButton[i].ClassTexture:SetAlpha(ButtonRangeAlpha)
				end
			end

			GVAR.TargetButton[i]:Show()
		else
			GVAR.TargetButton[i]:Hide()
		end
	end
	isTarget = 0
	if OPT.ButtonShowTarget[currentSize] then
		GVAR.TargetButton[testIcon1].TargetTexture:SetAlpha(1)
		GVAR.TargetButton[testIcon1].HighlightT:SetTexture(0.5, 0.5, 0.5, 1)
		GVAR.TargetButton[testIcon1].HighlightR:SetTexture(0.5, 0.5, 0.5, 1)
		GVAR.TargetButton[testIcon1].HighlightB:SetTexture(0.5, 0.5, 0.5, 1)
		GVAR.TargetButton[testIcon1].HighlightL:SetTexture(0.5, 0.5, 0.5, 1)
		isTarget = testIcon1
	end
	if OPT.ButtonShowFocus[currentSize] then
		GVAR.TargetButton[testIcon2].FocusTexture:SetAlpha(1)
	end
	if OPT.ButtonShowFlag[currentSize] then
		if currentSize == 10 or currentSize == 15 then
			GVAR.TargetButton[testIcon3].FlagTexture:SetAlpha(1)
		end
	end
	if OPT.ButtonShowAssist[currentSize] then
		GVAR.TargetButton[testIcon4].AssistTexture:SetAlpha(1)
	end
	if OPT.ButtonShowLeader[currentSize] then
		GVAR.TargetButton[testLeader].LeaderTexture:SetAlpha(0.75)
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
		GVAR.TargetButton[i].HighlightT:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].HighlightR:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].HighlightB:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].HighlightL:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].TargetTexture:SetAlpha(0)
		GVAR.TargetButton[i].AssistTexture:SetAlpha(0)
		GVAR.TargetButton[i].FocusTexture:SetAlpha(0)
		GVAR.TargetButton[i].FlagTexture:SetAlpha(0)
		GVAR.TargetButton[i].TargetCount:SetText("0")
		GVAR.TargetButton[i].HealthBar:SetWidth(healthBarWidth)
		GVAR.TargetButton[i].HealthText:SetText("")
		GVAR.TargetButton[i].RangeTexture:SetAlpha(0)
		GVAR.TargetButton[i].LeaderTexture:SetAlpha(0)

		GVAR.TargetButton[i].ClassColorBackground:SetAlpha(1)
		GVAR.TargetButton[i].HealthBar:SetAlpha(1)
		GVAR.TargetButton[i].RoleTexture:SetAlpha(1)
		GVAR.TargetButton[i].SpecTexture:SetAlpha(1)
		GVAR.TargetButton[i].ClassTexture:SetAlpha(1)
	end
	isTarget = 0

	BattlegroundTargets:BattlefieldCheck()

	if not inBattleground then return end

	BattlegroundTargets:CheckPlayerTarget()
	BattlegroundTargets:CheckAssist()
	BattlegroundTargets:CheckPlayerFocus()

	if OPT.ButtonRangeCheck[currentSize] then
		BattlegroundTargets:UpdateRange(GetTime())
	end

	if OPT.ButtonShowFlag[currentSize] then
		if hasFlag and ENEMY_Name2Button[hasFlag] and GVAR.TargetButton[ ENEMY_Name2Button[hasFlag] ] then
			GVAR.TargetButton[ ENEMY_Name2Button[hasFlag] ].FlagTexture:SetAlpha(1)
		end
	end

	if OPT.ButtonShowLeader[currentSize] then
		if isLeader and ENEMY_Name2Button[isLeader] and GVAR.TargetButton[ ENEMY_Name2Button[isLeader] ] then
			GVAR.TargetButton[ ENEMY_Name2Button[isLeader] ].LeaderTexture:SetAlpha(0.75)
		end
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:DefaultShuffle()
	for i = 1, 40 do
		testHealth[i] = math_random(0, 100)
		testRange[i]  = math_random(0, 100)
	end
	testIcon1  = math_random(10) if testIcon1  == 0 then testIcon1  = math_random(10) if testIcon1  == 0 then testIcon1  = 1 end end
	testIcon2  = math_random(10) if testIcon2  == 0 then testIcon2  = math_random(10) if testIcon2  == 0 then testIcon2  = 1 end end
	testIcon3  = math_random(10) if testIcon3  == 0 then testIcon3  = math_random(10) if testIcon3  == 0 then testIcon3  = 1 end end
	testIcon4  = math_random(10) if testIcon4  == 0 then testIcon4  = math_random(10) if testIcon4  == 0 then testIcon4  = 1 end end
	testLeader = math_random(10) if testLeader == 0 then testLeader = math_random(10) if testLeader == 0 then testLeader = 1 end end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:ShufflerFunc(what)
	if what == "OnLeave" then
		GVAR.OptionsFrame:SetScript("OnUpdate", nil)
		GVAR.OptionsFrame.TestShuffler.Texture:SetWidth(32)
		GVAR.OptionsFrame.TestShuffler.Texture:SetHeight(32)
		GVAR.OptionsFrame.TestShuffler.TextureHighlight:SetWidth(32)
		GVAR.OptionsFrame.TestShuffler.TextureHighlight:SetHeight(32)
	elseif what == "OnEnter" then
		GVAR.OptionsFrame.TestShuffler.elapsed = 1
		GVAR.OptionsFrame.TestShuffler.progBit = true
		if not GVAR.OptionsFrame.TestShuffler.progNum then GVAR.OptionsFrame.TestShuffler.progNum = 0 end
		if not GVAR.OptionsFrame.TestShuffler.progModi then GVAR.OptionsFrame.TestShuffler.progModi = 0 end
		GVAR.OptionsFrame:SetScript("OnUpdate", function(self, elap)
			if inCombat then GVAR.OptionsFrame:SetScript("OnUpdate", nil) return end
			GVAR.OptionsFrame.TestShuffler.elapsed = GVAR.OptionsFrame.TestShuffler.elapsed + elap
			if GVAR.OptionsFrame.TestShuffler.elapsed < 0.4 then return end
			GVAR.OptionsFrame.TestShuffler.elapsed = 0
			BattlegroundTargets:Shuffle(GVAR.OptionsFrame.TestShuffler.shuffleStyle)
		end)
	elseif what == "OnClick" then
		GVAR.OptionsFrame.TestShuffler.Texture:SetWidth(32)
		GVAR.OptionsFrame.TestShuffler.Texture:SetHeight(32)
		GVAR.OptionsFrame.TestShuffler.TextureHighlight:SetWidth(32)
		GVAR.OptionsFrame.TestShuffler.TextureHighlight:SetHeight(32)
		GVAR.OptionsFrame.TestShuffler.shuffleStyle = not GVAR.OptionsFrame.TestShuffler.shuffleStyle
		if GVAR.OptionsFrame.TestShuffler.shuffleStyle then
			GVAR.OptionsFrame.TestShuffler.Texture:SetTexture("Interface\\Icons\\INV_Sigil_Thorim")
		else
			GVAR.OptionsFrame.TestShuffler.Texture:SetTexture("Interface\\Icons\\INV_Sigil_Mimiron")
		end
	elseif what == "OnMouseDown" then
		GVAR.OptionsFrame.TestShuffler.Texture:SetWidth(30)
		GVAR.OptionsFrame.TestShuffler.Texture:SetHeight(30)
		GVAR.OptionsFrame.TestShuffler.TextureHighlight:SetWidth(30)
		GVAR.OptionsFrame.TestShuffler.TextureHighlight:SetHeight(30)
	elseif what == "ShuffleCheck" then
		local num = 0
		if OPT.ButtonShowLeader[currentSize]     then num = num + 1 end
		if OPT.ButtonShowTarget[currentSize]     then num = num + 1 end
		if OPT.ButtonShowFocus[currentSize]      then num = num + 1 end
		if OPT.ButtonShowFlag[currentSize]       then num = num + 1 end
		if OPT.ButtonShowAssist[currentSize]     then num = num + 1 end
		if OPT.ButtonShowHealthBar[currentSize]  then num = num + 1 end
		if OPT.ButtonShowHealthText[currentSize] then num = num + 1 end
		if OPT.ButtonRangeCheck[currentSize]     then num = num + 1 end
		if num > 0 then
			GVAR.OptionsFrame.TestShuffler:Show()
		else
			GVAR.OptionsFrame.TestShuffler:Hide()
		end
	end
end

function BattlegroundTargets:Shuffle(shuffleStyle)
	GVAR.OptionsFrame.TestShuffler.progBit = not GVAR.OptionsFrame.TestShuffler.progBit
	if GVAR.OptionsFrame.TestShuffler.progBit then
		GVAR.OptionsFrame.TestShuffler.TextureHighlight:SetAlpha(0)
	else
		GVAR.OptionsFrame.TestShuffler.TextureHighlight:SetAlpha(0.5)
	end	

	if shuffleStyle then
		BattlegroundTargets:DefaultShuffle()
	else
		if GVAR.OptionsFrame.TestShuffler.progModi == 0 then
			GVAR.OptionsFrame.TestShuffler.progNum = GVAR.OptionsFrame.TestShuffler.progNum + 1
		else
			GVAR.OptionsFrame.TestShuffler.progNum = GVAR.OptionsFrame.TestShuffler.progNum - 1
		end
		if GVAR.OptionsFrame.TestShuffler.progNum >= 10 then
			GVAR.OptionsFrame.TestShuffler.progNum = 10
			GVAR.OptionsFrame.TestShuffler.progModi = 1
		elseif GVAR.OptionsFrame.TestShuffler.progNum <= 1 then
			GVAR.OptionsFrame.TestShuffler.progNum = 1
			GVAR.OptionsFrame.TestShuffler.progModi = 0
		end
		testIcon1  = GVAR.OptionsFrame.TestShuffler.progNum
		testIcon2  = GVAR.OptionsFrame.TestShuffler.progNum
		testIcon3  = GVAR.OptionsFrame.TestShuffler.progNum
		testIcon4  = GVAR.OptionsFrame.TestShuffler.progNum
		testLeader = GVAR.OptionsFrame.TestShuffler.progNum
		for i = 1, 40 do
			testHealth[i] = GVAR.OptionsFrame.TestShuffler.progNum*10
			testRange[i] = 100
		end
		testRange[GVAR.OptionsFrame.TestShuffler.progNum] = 30
	end

	local ButtonShowHealthBar  = OPT.ButtonShowHealthBar[currentSize]
	local ButtonShowHealthText = OPT.ButtonShowHealthText[currentSize]
	local ButtonRangeCheck = OPT.ButtonRangeCheck[currentSize]
	local ButtonRangeAlpha = OPT.ButtonRangeAlpha[currentSize]

	for i = 1, 40 do
		-- health
		if ButtonShowHealthBar or ButtonShowHealthText then
			if i < currentSize+1 then
				if ButtonShowHealthBar then
					local width = healthBarWidth * (testHealth[i] / 100)
					width = math_max(0.01, width)
					width = math_min(healthBarWidth, width)
					GVAR.TargetButton[i].HealthBar:SetWidth(width)
				end
				if ButtonShowHealthText then
					GVAR.TargetButton[i].HealthText:SetText(testHealth[i])
				end
			end
		end

		-- range
		if ButtonRangeCheck then
			if testRange[i] < 40 then
				GVAR.TargetButton[i].RangeTexture:SetAlpha(1)
				GVAR.TargetButton[i].HealthBar:SetAlpha(1)
				GVAR.TargetButton[i].RoleTexture:SetAlpha(1)
				GVAR.TargetButton[i].SpecTexture:SetAlpha(1)
				GVAR.TargetButton[i].ClassTexture:SetAlpha(1)
			else
				GVAR.TargetButton[i].RangeTexture:SetAlpha(0)
				GVAR.TargetButton[i].HealthBar:SetAlpha(ButtonRangeAlpha)
				GVAR.TargetButton[i].RoleTexture:SetAlpha(ButtonRangeAlpha)
				GVAR.TargetButton[i].SpecTexture:SetAlpha(ButtonRangeAlpha)
				GVAR.TargetButton[i].ClassTexture:SetAlpha(ButtonRangeAlpha)
			end
		end

		-- leader, target, focus, flag, assist
		GVAR.TargetButton[i].LeaderTexture:SetAlpha(0)
		GVAR.TargetButton[i].TargetTexture:SetAlpha(0)
		GVAR.TargetButton[i].HighlightT:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].HighlightR:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].HighlightB:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].HighlightL:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].FocusTexture:SetAlpha(0)
		GVAR.TargetButton[i].FlagTexture:SetAlpha(0)
		GVAR.TargetButton[i].AssistTexture:SetAlpha(0)
	end

	-- leader, target, focus, flag, assist
	isTarget = 0
	if OPT.ButtonShowTarget[currentSize] then
		GVAR.TargetButton[testIcon1].TargetTexture:SetAlpha(1)
		GVAR.TargetButton[testIcon1].HighlightT:SetTexture(0.5, 0.5, 0.5, 1)
		GVAR.TargetButton[testIcon1].HighlightR:SetTexture(0.5, 0.5, 0.5, 1)
		GVAR.TargetButton[testIcon1].HighlightB:SetTexture(0.5, 0.5, 0.5, 1)
		GVAR.TargetButton[testIcon1].HighlightL:SetTexture(0.5, 0.5, 0.5, 1)
		isTarget = testIcon1
	end
	if OPT.ButtonShowFocus[currentSize] then
		GVAR.TargetButton[testIcon2].FocusTexture:SetAlpha(1)
	end
	if OPT.ButtonShowFlag[currentSize] then
		if currentSize == 10 or currentSize == 15 then
			GVAR.TargetButton[testIcon3].FlagTexture:SetAlpha(1)
		end
	end
	if OPT.ButtonShowAssist[currentSize] then
		GVAR.TargetButton[testIcon4].AssistTexture:SetAlpha(1)
	end
	if OPT.ButtonShowLeader[currentSize] then
		GVAR.TargetButton[testLeader].LeaderTexture:SetAlpha(0.75)
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:CopySettings(sourceSize)
	local destinationSize = 10
	if sourceSize == 10 then
		destinationSize = 15
	end

	BattlegroundTargets_Options.ButtonShowSpec[destinationSize]          = BattlegroundTargets_Options.ButtonShowSpec[sourceSize]
	                        OPT.ButtonShowSpec[destinationSize]          =                         OPT.ButtonShowSpec[sourceSize]
	BattlegroundTargets_Options.ButtonClassIcon[destinationSize]         = BattlegroundTargets_Options.ButtonClassIcon[sourceSize]
	                        OPT.ButtonClassIcon[destinationSize]         =                         OPT.ButtonClassIcon[sourceSize]
	BattlegroundTargets_Options.ButtonShowLeader[destinationSize]        = BattlegroundTargets_Options.ButtonShowLeader[sourceSize]
	                        OPT.ButtonShowLeader[destinationSize]        =                         OPT.ButtonShowLeader[sourceSize]
	BattlegroundTargets_Options.ButtonHideRealm[destinationSize]         = BattlegroundTargets_Options.ButtonHideRealm[sourceSize]
	                        OPT.ButtonHideRealm[destinationSize]         =                         OPT.ButtonHideRealm[sourceSize]
	BattlegroundTargets_Options.ButtonShowTarget[destinationSize]        = BattlegroundTargets_Options.ButtonShowTarget[sourceSize]
	                        OPT.ButtonShowTarget[destinationSize]        =                         OPT.ButtonShowTarget[sourceSize]
	BattlegroundTargets_Options.ButtonTargetScale[destinationSize]       = BattlegroundTargets_Options.ButtonTargetScale[sourceSize]
	                        OPT.ButtonTargetScale[destinationSize]       =                         OPT.ButtonTargetScale[sourceSize]
	BattlegroundTargets_Options.ButtonTargetPosition[destinationSize]    = BattlegroundTargets_Options.ButtonTargetPosition[sourceSize]
	                        OPT.ButtonTargetPosition[destinationSize]    =                         OPT.ButtonTargetPosition[sourceSize]
	BattlegroundTargets_Options.ButtonShowTargetCount[destinationSize]   = BattlegroundTargets_Options.ButtonShowTargetCount[sourceSize]
	                        OPT.ButtonShowTargetCount[destinationSize]   =                         OPT.ButtonShowTargetCount[sourceSize]
	BattlegroundTargets_Options.ButtonShowFocus[destinationSize]         = BattlegroundTargets_Options.ButtonShowFocus[sourceSize]
	                        OPT.ButtonShowFocus[destinationSize]         =                         OPT.ButtonShowFocus[sourceSize]
	BattlegroundTargets_Options.ButtonFocusScale[destinationSize]        = BattlegroundTargets_Options.ButtonFocusScale[sourceSize]
	                        OPT.ButtonFocusScale[destinationSize]        =                         OPT.ButtonFocusScale[sourceSize]
	BattlegroundTargets_Options.ButtonFocusPosition[destinationSize]     = BattlegroundTargets_Options.ButtonFocusPosition[sourceSize]
	                        OPT.ButtonFocusPosition[destinationSize]     =                         OPT.ButtonFocusPosition[sourceSize]
	BattlegroundTargets_Options.ButtonShowFlag[destinationSize]          = BattlegroundTargets_Options.ButtonShowFlag[sourceSize]
	                        OPT.ButtonShowFlag[destinationSize]          =                         OPT.ButtonShowFlag[sourceSize]
	BattlegroundTargets_Options.ButtonFlagScale[destinationSize]         = BattlegroundTargets_Options.ButtonFlagScale[sourceSize]
	                        OPT.ButtonFlagScale[destinationSize]         =                         OPT.ButtonFlagScale[sourceSize]
	BattlegroundTargets_Options.ButtonFlagPosition[destinationSize]      = BattlegroundTargets_Options.ButtonFlagPosition[sourceSize]
	                        OPT.ButtonFlagPosition[destinationSize]      =                         OPT.ButtonFlagPosition[sourceSize]
	BattlegroundTargets_Options.ButtonShowAssist[destinationSize]        = BattlegroundTargets_Options.ButtonShowAssist[sourceSize]
	                        OPT.ButtonShowAssist[destinationSize]        =                         OPT.ButtonShowAssist[sourceSize]
	BattlegroundTargets_Options.ButtonAssistScale[destinationSize]       = BattlegroundTargets_Options.ButtonAssistScale[sourceSize]
	                        OPT.ButtonAssistScale[destinationSize]       =                         OPT.ButtonAssistScale[sourceSize]
	BattlegroundTargets_Options.ButtonAssistPosition[destinationSize]    = BattlegroundTargets_Options.ButtonAssistPosition[sourceSize]
	                        OPT.ButtonAssistPosition[destinationSize]    =                         OPT.ButtonAssistPosition[sourceSize]
	BattlegroundTargets_Options.ButtonShowHealthBar[destinationSize]     = BattlegroundTargets_Options.ButtonShowHealthBar[sourceSize]
	                        OPT.ButtonShowHealthBar[destinationSize]     =                         OPT.ButtonShowHealthBar[sourceSize]
	BattlegroundTargets_Options.ButtonShowHealthText[destinationSize]    = BattlegroundTargets_Options.ButtonShowHealthText[sourceSize]
	                        OPT.ButtonShowHealthText[destinationSize]    =                         OPT.ButtonShowHealthText[sourceSize]
	BattlegroundTargets_Options.ButtonRangeCheck[destinationSize]        = BattlegroundTargets_Options.ButtonRangeCheck[sourceSize]
	                        OPT.ButtonRangeCheck[destinationSize]        =                         OPT.ButtonRangeCheck[sourceSize]
	BattlegroundTargets_Options.ButtonAvgRangeCheck[destinationSize]     = BattlegroundTargets_Options.ButtonAvgRangeCheck[sourceSize]
	                        OPT.ButtonAvgRangeCheck[destinationSize]     =                         OPT.ButtonAvgRangeCheck[sourceSize]
	BattlegroundTargets_Options.ButtonClassRangeCheck[destinationSize]   = BattlegroundTargets_Options.ButtonClassRangeCheck[sourceSize]
	                        OPT.ButtonClassRangeCheck[destinationSize]   =                         OPT.ButtonClassRangeCheck[sourceSize]
	BattlegroundTargets_Options.ButtonRangeAlpha[destinationSize]        = BattlegroundTargets_Options.ButtonRangeAlpha[sourceSize]
	                        OPT.ButtonRangeAlpha[destinationSize]        =                         OPT.ButtonRangeAlpha[sourceSize]
	BattlegroundTargets_Options.ButtonSortBy[destinationSize]            = BattlegroundTargets_Options.ButtonSortBy[sourceSize]
	                        OPT.ButtonSortBy[destinationSize]            =                         OPT.ButtonSortBy[sourceSize]
	BattlegroundTargets_Options.ButtonSortDetail[destinationSize]        = BattlegroundTargets_Options.ButtonSortDetail[sourceSize]
	                        OPT.ButtonSortDetail[destinationSize]        =                         OPT.ButtonSortDetail[sourceSize]
	BattlegroundTargets_Options.ButtonFontSize[destinationSize]          = BattlegroundTargets_Options.ButtonFontSize[sourceSize]
	                        OPT.ButtonFontSize[destinationSize]          =                         OPT.ButtonFontSize[sourceSize]
	BattlegroundTargets_Options.ButtonScale[destinationSize]             = BattlegroundTargets_Options.ButtonScale[sourceSize]
	                        OPT.ButtonScale[destinationSize]             =                         OPT.ButtonScale[sourceSize]
	BattlegroundTargets_Options.ButtonWidth[destinationSize]             = BattlegroundTargets_Options.ButtonWidth[sourceSize]
	                        OPT.ButtonWidth[destinationSize]             =                         OPT.ButtonWidth[sourceSize]
	BattlegroundTargets_Options.ButtonHeight[destinationSize]            = BattlegroundTargets_Options.ButtonHeight[sourceSize]
	                        OPT.ButtonHeight[destinationSize]            =                         OPT.ButtonHeight[sourceSize]

	if destinationSize == 10 then
		testSize = 10
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize10, true)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize15, nil)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize40, nil)
		BattlegroundTargets:CheckForEnabledBracket(testSize)
		if BattlegroundTargets_Options.EnableBracket[testSize] then
			BattlegroundTargets:EnableConfigMode()
		else
			BattlegroundTargets:DisableConfigMode()
		end
	else
		testSize = 15
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize10, nil)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize15, true)
		TEMPLATE.SetTabButton(GVAR.OptionsFrame.TestRaidSize40, nil)
		BattlegroundTargets:CheckForEnabledBracket(testSize)
		if BattlegroundTargets_Options.EnableBracket[testSize] then
			BattlegroundTargets:EnableConfigMode()
		else
			BattlegroundTargets:DisableConfigMode()
		end
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:UpdateLayout()
	local sortfunc
	local ButtonSortBy = OPT.ButtonSortBy[currentSize]
	local ButtonSortDetail = OPT.ButtonSortDetail[currentSize]
	if ButtonSortBy == 1 then -- ROLE / CLASS / NAME

		if ButtonSortDetail == 3 then -- ### 3
			sortfunc = function(a, b)
				if a.talentSpec == b.talentSpec then
					if classes_BLIZZ[ a.classToken ] == classes_BLIZZ[ b.classToken ] then
						if a.name < b.name then return true end
					elseif classes_BLIZZ[ a.classToken ] < classes_BLIZZ[ b.classToken ] then return true end
				elseif a.talentSpec < b.talentSpec then return true end
			end
		elseif ButtonSortDetail == 1 then -- ### 1
			sortfunc = function(a, b)
				if a.talentSpec == b.talentSpec then
					if classes_LOCALIZED[ a.classToken ] == classes_LOCALIZED[ b.classToken ] then
						if a.name < b.name then return true end
					elseif classes_LOCALIZED[ a.classToken ] < classes_LOCALIZED[ b.classToken ] then return true end
				elseif a.talentSpec < b.talentSpec then return true end
			end
		else -- ### 2
			sortfunc = function(a, b)
				if a.talentSpec == b.talentSpec then
					if a.classToken == b.classToken then
						if a.name < b.name then return true end
					elseif a.classToken < b.classToken then return true end
				elseif a.talentSpec < b.talentSpec then return true end
			end
		end

	elseif ButtonSortBy == 2 then -- ROLE / NAME

		sortfunc = function(a, b)
			if a.talentSpec == b.talentSpec then
				if a.name < b.name then return true end
			elseif a.talentSpec < b.talentSpec then return true end
		end

	elseif ButtonSortBy == 3 then -- CLASS / ROLE / NAME

		if ButtonSortDetail == 3 then -- ### 3
			sortfunc = function(a, b)
				if classes_BLIZZ[ a.classToken ] == classes_BLIZZ[ b.classToken ] then
					if a.talentSpec == b.talentSpec then
						if a.name < b.name then return true end
					elseif a.talentSpec < b.talentSpec then return true end
				elseif classes_BLIZZ[ a.classToken ] < classes_BLIZZ[ b.classToken ] then return true end
			end
		elseif ButtonSortDetail == 1 then -- ### 1
			sortfunc = function(a, b)
				if classes_LOCALIZED[ a.classToken ] == classes_LOCALIZED[ b.classToken ] then
					if a.talentSpec == b.talentSpec then
						if a.name < b.name then return true end
					elseif a.talentSpec < b.talentSpec then return true end
				elseif classes_LOCALIZED[ a.classToken ] < classes_LOCALIZED[ b.classToken ] then return true end
			end
		else -- ### 2
			sortfunc = function(a, b)
				if a.classToken == b.classToken then
					if a.talentSpec == b.talentSpec then
						if a.name < b.name then return true end
					elseif a.talentSpec < b.talentSpec then return true end
				elseif a.classToken < b.classToken then return true end
			end
		end

	elseif ButtonSortBy == 4 then -- CLASS / NAME

		if ButtonSortDetail == 3 then -- ### 3
			sortfunc = function(a, b)
				if classes_BLIZZ[ a.classToken ] == classes_BLIZZ[ b.classToken ] then
					if a.name < b.name then return true end
				elseif classes_BLIZZ[ a.classToken ] < classes_BLIZZ[ b.classToken ] then return true end
			end
		elseif ButtonSortDetail == 1 then -- ### 1
			sortfunc = function(a, b)
				if classes_LOCALIZED[ a.classToken ] == classes_LOCALIZED[ b.classToken ] then
					if a.name < b.name then return true end
				elseif classes_LOCALIZED[ a.classToken ] < classes_LOCALIZED[ b.classToken ] then return true end
			end
		else -- ### 2
			sortfunc = function(a, b)
				if a.classToken == b.classToken then
					if a.name < b.name then return true end
				elseif a.classToken < b.classToken then return true end
			end
		end

	else -- NAME
		sortfunc = function(a, b)
			if a.name < b.name then return true end
		end
	end
	table_sort(ENEMY_Data, sortfunc)

	local ButtonShowSpec        = OPT.ButtonShowSpec[currentSize]
	local ButtonClassIcon       = OPT.ButtonClassIcon[currentSize]
	local ButtonShowLeader      = OPT.ButtonShowLeader[currentSize]
	local ButtonHideRealm       = OPT.ButtonHideRealm[currentSize]
	local ButtonShowTargetCount = OPT.ButtonShowTargetCount[currentSize]
	local ButtonShowHealthBar   = OPT.ButtonShowHealthBar[currentSize]
	local ButtonShowHealthText  = OPT.ButtonShowHealthText[currentSize]
	local ButtonShowTarget      = OPT.ButtonShowTarget[currentSize]
	local ButtonShowFocus       = OPT.ButtonShowFocus[currentSize]
	local ButtonShowFlag        = OPT.ButtonShowFlag[currentSize]
	local ButtonShowAssist      = OPT.ButtonShowAssist[currentSize]
	local ButtonRangeCheck      = OPT.ButtonRangeCheck[currentSize]

	for i = 1, currentSize do
		if ENEMY_Data[i] then
			local qname       = ENEMY_Data[i].name
			local qclassToken = ENEMY_Data[i].classToken
			local qspecNum    = ENEMY_Data[i].specNum
			local qtalentSpec = ENEMY_Data[i].talentSpec

			ENEMY_Name2Button[qname] = i
			GVAR.TargetButton[i].buttonNum = i

			local r = classcolors[qclassToken].r
			local g = classcolors[qclassToken].g
			local b = classcolors[qclassToken].b
			GVAR.TargetButton[i].ClassColorBackground:SetTexture(r*0.5, g*0.5, b*0.5, 1)
			GVAR.TargetButton[i].HealthBar:SetTexture(r, g, b, 1)

			GVAR.TargetButton[i].RoleTexture:SetTexCoord(Textures.RoleIcon[qtalentSpec][1], Textures.RoleIcon[qtalentSpec][2], Textures.RoleIcon[qtalentSpec][3], Textures.RoleIcon[qtalentSpec][4])

			local name = qname
			if ButtonHideRealm then
				if string_find(name, "-", 1, true) then
					name = string_match(name, "(.-)%-(.*)$")
				end
			end
			GVAR.TargetButton[i].Name:SetText(name)
			if not inCombat or not InCombatLockdown() then
				GVAR.TargetButton[i]:SetAttribute("macrotext1", "/targetexact "..qname)
				GVAR.TargetButton[i]:SetAttribute("macrotext2", "/targetexact "..qname.."\n/focus\n/targetlasttarget")
			end

			if ButtonRangeCheck then
				GVAR.TargetButton[i].RangeTexture:SetTexture(r, g, b, 1)
			end

			if ButtonShowSpec then
				GVAR.TargetButton[i].SpecTexture:SetTexture(classes[qclassToken].spec[qspecNum].icon)
			end

			if ButtonClassIcon then
				GVAR.TargetButton[i].ClassTexture:SetTexCoord(classes[qclassToken].icon[1], classes[qclassToken].icon[2], classes[qclassToken].icon[3], classes[qclassToken].icon[4])
			end

			if ButtonShowTargetCount then
				if ENEMY_Names[qname] and GVAR.TargetButton[ ENEMY_Name2Button[qname] ] then
					GVAR.TargetButton[ ENEMY_Name2Button[qname] ].TargetCount:SetText(ENEMY_Names[qname])
				end
			end

			if ButtonShowHealthBar or ButtonShowHealthText then
				if ENEMY_Names[qname] and ENEMY_Name2Percent[qname] then
					if ButtonShowHealthBar then
						local width = healthBarWidth * (ENEMY_Name2Percent[qname] / 100)
						width = math_max(0.01, width)
						width = math_min(healthBarWidth, width)
						GVAR.TargetButton[i].HealthBar:SetWidth(width)
					end
					if ButtonShowHealthText then
						GVAR.TargetButton[i].HealthText:SetText(ENEMY_Name2Percent[qname])
					end
				end
			end

			if ButtonShowTarget and targetName then
				if qname == targetName then
					GVAR.TargetButton[i].HighlightT:SetTexture(0.5, 0.5, 0.5, 1)
					GVAR.TargetButton[i].HighlightR:SetTexture(0.5, 0.5, 0.5, 1)
					GVAR.TargetButton[i].HighlightB:SetTexture(0.5, 0.5, 0.5, 1)
					GVAR.TargetButton[i].HighlightL:SetTexture(0.5, 0.5, 0.5, 1)
					GVAR.TargetButton[i].TargetTexture:SetAlpha(1)
				else
					GVAR.TargetButton[i].HighlightT:SetTexture(0, 0, 0, 1)
					GVAR.TargetButton[i].HighlightR:SetTexture(0, 0, 0, 1)
					GVAR.TargetButton[i].HighlightB:SetTexture(0, 0, 0, 1)
					GVAR.TargetButton[i].HighlightL:SetTexture(0, 0, 0, 1)
					GVAR.TargetButton[i].TargetTexture:SetAlpha(0)
				end
			end

			if ButtonShowFocus and focusName then
				if qname == focusName then
					GVAR.TargetButton[i].FocusTexture:SetAlpha(1)
				else
					GVAR.TargetButton[i].FocusTexture:SetAlpha(0)
				end
			end
			
			if ButtonShowFlag and hasFlag then
				if qname == hasFlag then
					GVAR.TargetButton[i].FlagTexture:SetAlpha(1)
				else
					GVAR.TargetButton[i].FlagTexture:SetAlpha(0)
				end
			end

			if ButtonShowAssist and assistTargetName then
				if qname == assistTargetName then
					GVAR.TargetButton[i].AssistTexture:SetAlpha(1)
				else
					GVAR.TargetButton[i].AssistTexture:SetAlpha(0)
				end
			end

			if ButtonShowLeader and isLeader then
				if qname == isLeader then
					GVAR.TargetButton[i].LeaderTexture:SetAlpha(0.75)
				else
					GVAR.TargetButton[i].LeaderTexture:SetAlpha(0)
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
			GVAR.TargetButton[i].FlagTexture:SetAlpha(0)
			GVAR.TargetButton[i].AssistTexture:SetAlpha(0)
			GVAR.TargetButton[i].RangeTexture:SetTexture(0, 0, 0, 0)
			GVAR.TargetButton[i].LeaderTexture:SetAlpha(0)
			if not inCombat or not InCombatLockdown() then
				GVAR.TargetButton[i]:SetAttribute("macrotext1", "")
				GVAR.TargetButton[i]:SetAttribute("macrotext2", "")
			end
		end
	end
	
	if ButtonRangeCheck and not isConfig then
		BattlegroundTargets:UpdateRange(GetTime())
	end
	
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:BattlefieldScoreUpdate(forceUpdate)
	if not forceUpdate then
		local curTime = GetTime()
		if scoreUpdateThrottle + scoreUpdateFrequency > curTime then return end
		scoreUpdateThrottle = curTime
	end

	if WorldStateScoreFrame and WorldStateScoreFrame:IsShown() and WorldStateScoreFrame.selectedTab and WorldStateScoreFrame.selectedTab > 1 then return end -- WorldStateScoreFrameTab_OnClick (WorldStateFrame.lua) | PanelTemplates_SetTab (UIPanelTemplates.lua) | Button WorldStateScoreFrameTab1/2/3 (WorldStateFrame.xml)

	SetBattlefieldScoreFaction()

	table_wipe(ENEMY_Data)
	table_wipe(FRIEND_Names)

	local x = 1
	local numScores = GetNumBattlefieldScores()
	for index = 1, numScores do
		local name, _, _, _, _, faction, _, _, classToken, _, _, _, _, _, _, talentSpec = GetBattlefieldScore(index)
		if name then
			if faction == oppositeFactionBG then

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

			else

				FRIEND_Names[name] = 1

			end
		end
	end

	BattlegroundTargets:UpdateLayout()

	if reSizeCheck < 10 then
		local queueStatus, queueMapName, bgName
		for i=1, GetMaxBattlefieldID() do
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
			for i=1, GetMaxBattlefieldID() do
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
				playerFactionBG   = 0 -- Horde or Alliance
				oppositeFactionBG = 1 -- Alliance or Horde
			elseif faction == 1 then
				playerFactionBG   = 1 -- Alliance or Horde
				oppositeFactionBG = 0 -- Horde or Alliance
			end
		end

		if inCombat or InCombatLockdown() then
			reCheckBG = true
		else
			reCheckBG = false

			if BattlegroundTargets_Options.EnableBracket[currentSize] then

				GVAR.MainFrame:Show() -- HiDE
				GVAR.MainFrame:EnableMouse(false)
				GVAR.MainFrame:SetHeight(0.001)
				GVAR.MainFrame.Movetext:Hide()
				GVAR.TargetButton[1]:SetPoint("TOPLEFT", GVAR.MainFrame, "BOTTOMLEFT", 0, -(20 / OPT.ButtonScale[currentSize]))

				for i = 1, 40 do
					if i < currentSize+1 then
						GVAR.TargetButton[i].TargetCount:SetText("0")
						GVAR.TargetButton[i].HealthText:SetText("")
						GVAR.TargetButton[i].HighlightT:SetTexture(0, 0, 0, 1)
						GVAR.TargetButton[i].HighlightR:SetTexture(0, 0, 0, 1)
						GVAR.TargetButton[i].HighlightB:SetTexture(0, 0, 0, 1)
						GVAR.TargetButton[i].HighlightL:SetTexture(0, 0, 0, 1)
						GVAR.TargetButton[i].TargetTexture:SetAlpha(0)
						GVAR.TargetButton[i].FocusTexture:SetAlpha(0)
						GVAR.TargetButton[i].FlagTexture:SetAlpha(0)
						GVAR.TargetButton[i]:Show()
					else
						GVAR.TargetButton[i]:Hide()
					end
				end

				BattlegroundTargets:BattlefieldScoreUpdate(1)
				BattlegroundTargets:SetupButtonLayout()

				if OPT.ButtonShowFlag[currentSize] then
					if currentSize == 10 or currentSize == 15 then
						if playerFactionBG ~= playerFactionDEF then -- setup_flag_texture
							for i = 1, currentSize do
								GVAR.TargetButton[i].FlagTexture:SetTexture("Interface\\WorldStateFrame\\ColumnIcon-FlagCapture2") -- neutral flag
							end
						end
					end
				end

			else

				GVAR.MainFrame:Hide()
				for i = 1, 40 do
					GVAR.TargetButton[i]:Hide()
				end

			end

		end

		BattlegroundTargets:UnregisterEvent("PLAYER_DEAD")
		BattlegroundTargets:UnregisterEvent("PLAYER_UNGHOST")
		BattlegroundTargets:UnregisterEvent("PLAYER_ALIVE")
		BattlegroundTargets:UnregisterEvent("UNIT_HEALTH_FREQUENT")
		BattlegroundTargets:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
		BattlegroundTargets:UnregisterEvent("UNIT_TARGET")
		BattlegroundTargets:UnregisterEvent("PLAYER_TARGET_CHANGED")
		BattlegroundTargets:UnregisterEvent("PLAYER_FOCUS_CHANGED")
		BattlegroundTargets:UnregisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
		BattlegroundTargets:UnregisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
		BattlegroundTargets:UnregisterEvent("RAID_ROSTER_UPDATE")
		BattlegroundTargets:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		BattlegroundTargets:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE")

		if BattlegroundTargets_Options.EnableBracket[currentSize] then
			BattlegroundTargets:RegisterEvent("PLAYER_DEAD")
			BattlegroundTargets:RegisterEvent("PLAYER_UNGHOST")
			BattlegroundTargets:RegisterEvent("PLAYER_ALIVE")

			if OPT.ButtonShowHealthBar[currentSize] or OPT.ButtonShowHealthText[currentSize] then
				BattlegroundTargets:RegisterEvent("UNIT_TARGET")
				BattlegroundTargets:RegisterEvent("UNIT_HEALTH_FREQUENT")
				BattlegroundTargets:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
			end
			if OPT.ButtonShowTargetCount[currentSize] then
				BattlegroundTargets:RegisterEvent("UNIT_TARGET")
			end
			if OPT.ButtonShowTarget[currentSize] then
				BattlegroundTargets:RegisterEvent("PLAYER_TARGET_CHANGED")
			end
			if OPT.ButtonShowFocus[currentSize] then
				BattlegroundTargets:RegisterEvent("PLAYER_FOCUS_CHANGED")
			end
			if OPT.ButtonShowFlag[currentSize] then
				if currentSize == 10 or currentSize == 15 then
					BattlegroundTargets:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
					BattlegroundTargets:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
				end
			end
			if OPT.ButtonShowAssist[currentSize] then
				BattlegroundTargets:RegisterEvent("RAID_ROSTER_UPDATE")
				BattlegroundTargets:RegisterEvent("UNIT_TARGET")
			end

			if OPT.ButtonShowLeader[currentSize] then
				BattlegroundTargets:RegisterEvent("UNIT_TARGET")
			end

			rangeSpellName = nil
			if OPT.ButtonRangeCheck[currentSize] then
				if OPT.ButtonAvgRangeCheck[currentSize] then
					BattlegroundTargets:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
				elseif OPT.ButtonClassRangeCheck[currentSize] then
					if ranges[playerClassEN] and IsSpellKnown( ranges[playerClassEN] ) then
						rangeSpellName = GetSpellInfo( ranges[playerClassEN] )
					end
					if not rangeSpellName then
						Print(UNKNOWN, "id =", ranges[playerClassEN], rangeSpellName, playerClass, playerClassEN)
					else
						BattlegroundTargets:RegisterEvent("UNIT_HEALTH_FREQUENT")
						BattlegroundTargets:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
						BattlegroundTargets:RegisterEvent("PLAYER_TARGET_CHANGED")
						BattlegroundTargets:RegisterEvent("UNIT_TARGET")
					end
				end
			end
			BattlegroundTargets:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
		end
	else
		inBattleground = false
		reSizeCheck = 0

		BattlegroundTargets:UnregisterEvent("PLAYER_DEAD")
		BattlegroundTargets:UnregisterEvent("PLAYER_UNGHOST")
		BattlegroundTargets:UnregisterEvent("PLAYER_ALIVE")
		BattlegroundTargets:UnregisterEvent("UNIT_HEALTH_FREQUENT")
		BattlegroundTargets:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
		BattlegroundTargets:UnregisterEvent("UNIT_TARGET")
		BattlegroundTargets:UnregisterEvent("PLAYER_TARGET_CHANGED")
		BattlegroundTargets:UnregisterEvent("PLAYER_FOCUS_CHANGED")
		BattlegroundTargets:UnregisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
		BattlegroundTargets:UnregisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
		BattlegroundTargets:UnregisterEvent("RAID_ROSTER_UPDATE")
		BattlegroundTargets:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		BattlegroundTargets:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE")

		if not isConfig then
			table_wipe(ENEMY_Data)
		end
		table_wipe(ENEMY_Names)
		table_wipe(ENEMY_Name2Button)
		table_wipe(ENEMY_Name2Percent)
		table_wipe(ENEMY_Name2Range)
		table_wipe(TARGET_Names)

		if inCombat or InCombatLockdown() then
			reCheckBG = true
		else
			reCheckBG = false

			GVAR.MainFrame:Hide()
			if OPT.ButtonShowFlag[currentSize] then
				if playerFactionDEF == 0 then -- setup_flag_texture
					for i = 1, 40 do
						GVAR.TargetButton[i].FlagTexture:SetTexture("Interface\\WorldStateFrame\\HordeFlag")
						GVAR.TargetButton[i]:Hide()
					end
				else
					for i = 1, 40 do
						GVAR.TargetButton[i].FlagTexture:SetTexture("Interface\\WorldStateFrame\\AllianceFlag")
						GVAR.TargetButton[i]:Hide()
					end
				end
			else
				for i = 1, 40 do
					GVAR.TargetButton[i]:Hide()
				end
			end

		end

	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:CheckPlayerTarget()
	if isConfig then return end

	targetName, targetRealm = UnitName("target")
	if targetRealm and targetRealm ~= "" then
		targetName = targetName.."-"..targetRealm
	end

	for i = 1, currentSize do
		GVAR.TargetButton[i].TargetTexture:SetAlpha(0)
		GVAR.TargetButton[i].HighlightT:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].HighlightR:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].HighlightB:SetTexture(0, 0, 0, 1)
		GVAR.TargetButton[i].HighlightL:SetTexture(0, 0, 0, 1)
	end
	isTarget = 0

	if not targetName then return end
	local targetButton = ENEMY_Name2Button[targetName]
	if not targetButton then return end
	if not GVAR.TargetButton[targetButton] then return end

	-- target
	if OPT.ButtonShowTarget[currentSize] then
		GVAR.TargetButton[targetButton].TargetTexture:SetAlpha(1)
		GVAR.TargetButton[targetButton].HighlightT:SetTexture(0.5, 0.5, 0.5, 1)
		GVAR.TargetButton[targetButton].HighlightR:SetTexture(0.5, 0.5, 0.5, 1)
		GVAR.TargetButton[targetButton].HighlightB:SetTexture(0.5, 0.5, 0.5, 1)
		GVAR.TargetButton[targetButton].HighlightL:SetTexture(0.5, 0.5, 0.5, 1)
		isTarget = targetButton
	end

	-- class_range (Check Player Target)
	if rangeSpellName and OPT.ButtonClassRangeCheck[currentSize] then
		local curTime = GetTime()
		if ENEMY_Name2Range[targetName] then
			if ENEMY_Name2Range[targetName] + classRangeFrequency > curTime then return end
		end
		if IsSpellInRange(rangeSpellName, "target") == 1 then
			ENEMY_Name2Range[targetName] = curTime
			GVAR.TargetButton[targetButton].RangeTexture:SetAlpha(1)
			GVAR.TargetButton[targetButton].HealthBar:SetAlpha(1)
			GVAR.TargetButton[targetButton].RoleTexture:SetAlpha(1)
			GVAR.TargetButton[targetButton].SpecTexture:SetAlpha(1)
			GVAR.TargetButton[targetButton].ClassTexture:SetAlpha(1)
		else
			ENEMY_Name2Range[targetName] = nil
			GVAR.TargetButton[targetButton].RangeTexture:SetAlpha(0) -- RANCLR
			local rangeAlpha = OPT.ButtonRangeAlpha[currentSize]
			GVAR.TargetButton[targetButton].HealthBar:SetAlpha(rangeAlpha)
			GVAR.TargetButton[targetButton].RoleTexture:SetAlpha(rangeAlpha)
			GVAR.TargetButton[targetButton].SpecTexture:SetAlpha(rangeAlpha)
			GVAR.TargetButton[targetButton].ClassTexture:SetAlpha(rangeAlpha)
		end
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:CheckAssist()
	if isConfig then return end

	isAssistUnitId = nil
	isAssistName = nil
	local raid = GetNumRaidMembers()
	for i = 1, raid do
		local name, _, _, _, _, _, _, _, _, role = GetRaidRosterInfo(i)
		if name and role and role == "MAINASSIST" then
			isAssistName = name
			isAssistUnitId = "raid"..i.."target"
			break
		end
	end

	for i = 1, currentSize do
		GVAR.TargetButton[i].AssistTexture:SetAlpha(0)
	end

	if not isAssistName then return end

	assistTargetName, assistTargetRealm = UnitName(isAssistUnitId)
	if assistTargetRealm and assistTargetRealm ~= "" then
		assistTargetName = assistTargetName.."-"..assistTargetRealm
	end

	if not assistTargetName then return end
	local assistButton = ENEMY_Name2Button[assistTargetName]
	if not assistButton then return end
	if not GVAR.TargetButton[assistButton] then return end

	-- assist_
	if OPT.ButtonShowAssist[currentSize] then
		GVAR.TargetButton[assistButton].AssistTexture:SetAlpha(1)
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:CheckPlayerFocus()
	if isConfig then return end

	focusName, focusRealm = UnitName("focus")
	if focusRealm and focusRealm ~= "" then
		focusName = focusName.."-"..focusRealm
	end

	for i = 1, currentSize do
		GVAR.TargetButton[i].FocusTexture:SetAlpha(0)
	end

	if not focusName then return end
	local focusButton = ENEMY_Name2Button[focusName]
	if not focusButton then return end
	if not GVAR.TargetButton[focusButton] then return end

	-- focus
	if OPT.ButtonShowFocus[currentSize] then
		GVAR.TargetButton[focusButton].FocusTexture:SetAlpha(1)
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:CheckUnitTarget(unitID)
	if isConfig then return end

	local friendName, friendRealm, enemyID, enemyName, enemyRealm

	if unitID == "player" then
		enemyID = "target"
		friendName = UnitName("player")
		enemyName, enemyRealm = UnitName(enemyID)
		if enemyRealm and enemyRealm ~= "" then
			enemyName = enemyName.."-"..enemyRealm
		end
	else
		enemyID = unitID.."target"
		friendName, friendRealm = UnitName(unitID)
		if friendRealm and friendRealm ~= "" then
			friendName = friendName.."-"..friendRealm
		end
		enemyName, enemyRealm = UnitName(enemyID)
		if enemyRealm and enemyRealm ~= "" then
			enemyName = enemyName.."-"..enemyRealm
		end
	end

	-- target count
	if OPT.ButtonShowTargetCount[currentSize] then
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
			if eName and ENEMY_Names[eName] then
				ENEMY_Names[eName] = ENEMY_Names[eName] + 1
			end
		end
		for i = 1, currentSize do
			if ENEMY_Data[i] and ENEMY_Names[ ENEMY_Data[i].name ] then
				GVAR.TargetButton[i].TargetCount:SetText( ENEMY_Names[ ENEMY_Data[i].name ] )
			else
				GVAR.TargetButton[i].TargetCount:SetText("")
			end
		end
	end

	-- health
	if OPT.ButtonShowHealthBar[currentSize] or OPT.ButtonShowHealthText[currentSize] then
		if enemyID and enemyName then
			BattlegroundTargets:CheckUnitHealth(enemyID, enemyName)
		end
	end

	-- assist_
	if isAssistName and OPT.ButtonShowAssist[currentSize] then
		local curTime = GetTime()
		if curTime > assistThrottle + assistFrequency then
			assistThrottle = curTime
			assistTargetName, assistTargetRealm = UnitName(isAssistUnitId)
			if assistTargetRealm and assistTargetRealm ~= "" then
				assistTargetName = assistTargetName.."-"..assistTargetRealm
			end
			for i = 1, currentSize do
				GVAR.TargetButton[i].AssistTexture:SetAlpha(0)
			end
			if assistTargetName and ENEMY_Name2Button[assistTargetName] and GVAR.TargetButton[ ENEMY_Name2Button[assistTargetName] ] then
				GVAR.TargetButton[ ENEMY_Name2Button[assistTargetName] ].AssistTexture:SetAlpha(1)
			end
		elseif friendName and isAssistName == friendName then
			for i = 1, currentSize do
				GVAR.TargetButton[i].AssistTexture:SetAlpha(0)
			end
			if enemyName and ENEMY_Name2Button[enemyName] and GVAR.TargetButton[ ENEMY_Name2Button[enemyName] ] then
				assistTargetName = enemyName 
				GVAR.TargetButton[ ENEMY_Name2Button[enemyName] ].AssistTexture:SetAlpha(1)
			end
		end
	end

	-- leader
	if OPT.ButtonShowLeader[currentSize] then
		if enemyName and ENEMY_Name2Button[enemyName] and GVAR.TargetButton[ ENEMY_Name2Button[enemyName] ] then
			if UnitIsPartyLeader(enemyID) then
				isLeader = enemyName
				for i = 1, currentSize do
					GVAR.TargetButton[i].LeaderTexture:SetAlpha(0)
				end
				GVAR.TargetButton[ ENEMY_Name2Button[enemyName] ].LeaderTexture:SetAlpha(0.75)
			else
				GVAR.TargetButton[ ENEMY_Name2Button[enemyName] ].LeaderTexture:SetAlpha(0)
			end
		end
	end

	-- class_range (Check Unit Target)
	if rangeSpellName and OPT.ButtonClassRangeCheck[currentSize] and enemyName then
		local enemyButton = ENEMY_Name2Button[enemyName]
		if enemyButton and GVAR.TargetButton[enemyButton] then
			if raidUnitID[unitID] then -- prevent double event trigger for partyXtarget and player unitIDs (raidXtarget is doing the same)
				local curTime = GetTime()
				if ENEMY_Name2Range[enemyName] then
					if ENEMY_Name2Range[enemyName] + classRangeFrequency > curTime then return end
				end
				if IsSpellInRange(rangeSpellName, enemyID) == 1 then
					ENEMY_Name2Range[enemyName] = curTime
					GVAR.TargetButton[enemyButton].RangeTexture:SetAlpha(1)
					GVAR.TargetButton[enemyButton].HealthBar:SetAlpha(1)
					GVAR.TargetButton[enemyButton].RoleTexture:SetAlpha(1)
					GVAR.TargetButton[enemyButton].SpecTexture:SetAlpha(1)
					GVAR.TargetButton[enemyButton].ClassTexture:SetAlpha(1)
				else
					ENEMY_Name2Range[enemyName] = nil
					GVAR.TargetButton[enemyButton].RangeTexture:SetAlpha(0) -- RANCLR
					local rangeAlpha = OPT.ButtonRangeAlpha[currentSize]
					GVAR.TargetButton[enemyButton].HealthBar:SetAlpha(rangeAlpha)
					GVAR.TargetButton[enemyButton].RoleTexture:SetAlpha(rangeAlpha)
					GVAR.TargetButton[enemyButton].SpecTexture:SetAlpha(rangeAlpha)
					GVAR.TargetButton[enemyButton].ClassTexture:SetAlpha(rangeAlpha)
				end
			end
		end
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:CheckUnitHealth(unitID, unitName)
	if isConfig then return end

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
	local targetButton = ENEMY_Name2Button[targetName]
	if not targetButton then return end
	if not GVAR.TargetButton[targetButton] then return end

	-- health
	local ButtonShowHealthBar  = OPT.ButtonShowHealthBar[currentSize]
	local ButtonShowHealthText = OPT.ButtonShowHealthText[currentSize]
	if ButtonShowHealthBar or ButtonShowHealthText then
		local maxHealth = UnitHealthMax(targetID)
		if maxHealth then
			local health = UnitHealth(targetID)
			if health then
				local width = 0.01
				local percent = 0
				if maxHealth > 0 and health > 0 then
					local hvalue = maxHealth / health
					width = healthBarWidth / hvalue
					width = math_max(0.01, width)
					width = math_min(healthBarWidth, width)
					percent = math_floor( (100/hvalue) + 0.5 )
					percent = math_max(0, percent)
					percent = math_min(100, percent)
				end
				ENEMY_Name2Percent[targetName] = percent
				if ButtonShowHealthBar then
					GVAR.TargetButton[targetButton].HealthBar:SetWidth(width)
				end
				if ButtonShowHealthText then
					GVAR.TargetButton[targetButton].HealthText:SetText(percent)
				end
			end
		end
	end

	-- class_range (Check Unit Health)
	if rangeSpellName and OPT.ButtonClassRangeCheck[currentSize] then
		if raidUnitID[unitID] or playerUnitID[targetID] then
			local curTime = GetTime()
			if ENEMY_Name2Range[targetName] then
				if ENEMY_Name2Range[targetName] + classRangeFrequency > curTime then return end
			end
			if IsSpellInRange(rangeSpellName, targetID) == 1 then
				ENEMY_Name2Range[targetName] = curTime
				GVAR.TargetButton[targetButton].RangeTexture:SetAlpha(1)
				GVAR.TargetButton[targetButton].HealthBar:SetAlpha(1)
				GVAR.TargetButton[targetButton].RoleTexture:SetAlpha(1)
				GVAR.TargetButton[targetButton].SpecTexture:SetAlpha(1)
				GVAR.TargetButton[targetButton].ClassTexture:SetAlpha(1)
			else
				ENEMY_Name2Range[targetName] = nil
				GVAR.TargetButton[targetButton].RangeTexture:SetAlpha(0) -- RANCLR
				local rangeAlpha = OPT.ButtonRangeAlpha[currentSize]
				GVAR.TargetButton[targetButton].HealthBar:SetAlpha(rangeAlpha)
				GVAR.TargetButton[targetButton].RoleTexture:SetAlpha(rangeAlpha)
				GVAR.TargetButton[targetButton].SpecTexture:SetAlpha(rangeAlpha)
				GVAR.TargetButton[targetButton].ClassTexture:SetAlpha(rangeAlpha)
			end
		end
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:FlagCheck(message, messageFaction)
	if messageFaction == playerFactionBG then

		if string_match(message, FL["WSG_TP_MATCH_CAPTURED"]) or -- Warsong Gulch & Twink Peaks: flag was captured
		   message == FL["EOTS_STRING_CAPTURED_BY_ALLIANCE"] or  -- Eye of the Storm           : flag was captured
		   message == FL["EOTS_STRING_CAPTURED_BY_HORDE"]        -- Eye of the Storm           : flag was captured
		then
			for i = 1, currentSize do
				GVAR.TargetButton[i].FlagTexture:SetAlpha(0)
			end
			hasFlag = nil
		elseif string_match(message, FL["WSG_TP_MATCH_DROPPED"]) or -- Warsong Gulch & Twink Peaks: flag was dropped
		       message == FL["EOTS_STRING_DROPPED"]                 -- Eye of the Storm           : flag was dropped
		then
			for i = 1, currentSize do
				GVAR.TargetButton[i].FlagTexture:SetAlpha(0)
			end
			hasFlag = nil
		end

	else

		local efc = string_match(message, FL["WSG_TP_REGEX_PICKED1"]) or -- Warsong Gulch & Twink Peaks: flag was picked
		            string_match(message, FL["WSG_TP_REGEX_PICKED2"]) or -- Warsong Gulch & Twink Peaks: flag was picked
		            string_match(message, FL["EOTS_REGEX_PICKED"])       -- Eye of the Storm           : flag was picked
		if efc then
			for i = 1, currentSize do
				GVAR.TargetButton[i].FlagTexture:SetAlpha(0)
			end
			for name in pairs(ENEMY_Names) do
				if string_match(name, efc) then
					efc = name
					break
				end
			end
			if efc and ENEMY_Names[efc] and GVAR.TargetButton[ ENEMY_Name2Button[efc] ] then
				GVAR.TargetButton[ ENEMY_Name2Button[efc] ].FlagTexture:SetAlpha(1)
				hasFlag = efc
			end
		elseif string_match(message, FL["WSG_TP_MATCH_CAPTURED"]) or -- Warsong Gulch & Twink Peaks: flag was captured
		       message == FL["EOTS_STRING_CAPTURED_BY_ALLIANCE"] or  -- Eye of the Storm           : flag was captured
		       message == FL["EOTS_STRING_CAPTURED_BY_HORDE"]        -- Eye of the Storm           : flag was captured
		then
			for i = 1, currentSize do
				GVAR.TargetButton[i].FlagTexture:SetAlpha(0)
			end
			hasFlag = nil
		end

	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:CombatLogRangeCheck(sourceName, destName, spellId)
	if not SPELL_Range[spellId] then
		local _, _, _, _, _, _, _, _, maxRange = GetSpellInfo(spellId) -- local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellId)
		if not maxRange then return end
		SPELL_Range[spellId] = maxRange
	end
	if SPELL_Range[spellId] > 45 then return end

	-- enemy attack friend
	if ENEMY_Names[sourceName] then
		if destName == playerName then
			ENEMY_Name2Range[sourceName] = GetTime()
			local sourceButton = ENEMY_Name2Button[sourceName]
			if sourceButton and GVAR.TargetButton[sourceButton] then
				GVAR.TargetButton[sourceButton].RangeTexture:SetAlpha(1)
				GVAR.TargetButton[sourceButton].HealthBar:SetAlpha(1)
				GVAR.TargetButton[sourceButton].RoleTexture:SetAlpha(1)
				GVAR.TargetButton[sourceButton].SpecTexture:SetAlpha(1)
				GVAR.TargetButton[sourceButton].ClassTexture:SetAlpha(1)
			end
			return
		elseif FRIEND_Names[destName] then
			local curTime = GetTime()
			if CheckInteractDistance(destName, 1) then -- 1:Inspect=28
				ENEMY_Name2Range[sourceName] = curTime
			end
			if rangeUpdateThrottle + rangeUpdateFrequency > curTime then return end
			rangeUpdateThrottle = curTime
			BattlegroundTargets:UpdateRange(curTime)
			return
		end
	-- friend attack enemy
	elseif ENEMY_Names[destName] then
		if sourceName == playerName then
			ENEMY_Name2Range[destName] = GetTime()
			local destButton = ENEMY_Name2Button[destName]
			if destButton and GVAR.TargetButton[destButton] then
				GVAR.TargetButton[destButton].RangeTexture:SetAlpha(1)
				GVAR.TargetButton[destButton].HealthBar:SetAlpha(1)
				GVAR.TargetButton[destButton].RoleTexture:SetAlpha(1)
				GVAR.TargetButton[destButton].SpecTexture:SetAlpha(1)
				GVAR.TargetButton[destButton].ClassTexture:SetAlpha(1)
			end
			return
		elseif FRIEND_Names[sourceName] then
			local curTime = GetTime()
			if CheckInteractDistance(sourceName, 1) then -- 1:Inspect=28
				ENEMY_Name2Range[destName] = curTime
			end
			if rangeUpdateThrottle + rangeUpdateFrequency > curTime then return end
			rangeUpdateThrottle = curTime
			BattlegroundTargets:UpdateRange(curTime)
			return
		end
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:UpdateRange(curTime)
	if isDead then return end

	local rangeAlpha = OPT.ButtonRangeAlpha[currentSize]
	for i = 1, currentSize do
		GVAR.TargetButton[i].RangeTexture:SetAlpha(0) -- RANCLR
		GVAR.TargetButton[i].HealthBar:SetAlpha(rangeAlpha)
		GVAR.TargetButton[i].RoleTexture:SetAlpha(rangeAlpha)
		GVAR.TargetButton[i].SpecTexture:SetAlpha(rangeAlpha)
		GVAR.TargetButton[i].ClassTexture:SetAlpha(rangeAlpha)
	end

	for name, timeStamp in pairs(ENEMY_Name2Range) do
		if not ENEMY_Name2Button[name] then
			ENEMY_Name2Range[name] = nil
		elseif ENEMY_Name2Percent[name] == 0 then
			ENEMY_Name2Range[name] = nil
		elseif timeStamp + 10 < curTime then
			ENEMY_Name2Range[name] = nil
		elseif GVAR.TargetButton[ ENEMY_Name2Button[ name ] ] then
			GVAR.TargetButton[ ENEMY_Name2Button[ name ] ].RangeTexture:SetAlpha(1)
			GVAR.TargetButton[ ENEMY_Name2Button[ name ] ].HealthBar:SetAlpha(1)
			GVAR.TargetButton[ ENEMY_Name2Button[ name ] ].RoleTexture:SetAlpha(1)
			GVAR.TargetButton[ ENEMY_Name2Button[ name ] ].SpecTexture:SetAlpha(1)
			GVAR.TargetButton[ ENEMY_Name2Button[ name ] ].ClassTexture:SetAlpha(1)
		end
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:ClearRangeData()
	if OPT.ButtonRangeCheck[currentSize] then
		table_wipe(ENEMY_Name2Range)
		local rangeAlpha = OPT.ButtonRangeAlpha[currentSize]
		for i = 1, 40 do
			GVAR.TargetButton[i].RangeTexture:SetAlpha(0) -- RANCLR
			GVAR.TargetButton[i].HealthBar:SetAlpha(rangeAlpha)
			GVAR.TargetButton[i].RoleTexture:SetAlpha(rangeAlpha)
			GVAR.TargetButton[i].SpecTexture:SetAlpha(rangeAlpha)
			GVAR.TargetButton[i].ClassTexture:SetAlpha(rangeAlpha)
		end
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
--[[
function BattlegroundTargets:BruteForceUpdate()
	for name, button in pairs(ENEMY_Name2Button) do
		for tname, tenemy in pairs(TARGET_Names) do
			if name == tenemy then

				print(name, UnitName(tname.."target") )

				local ButtonShowLeader      = OPT.ButtonShowLeader[currentSize]
				local ButtonShowTargetCount = OPT.ButtonShowTargetCount[currentSize]
				local ButtonShowHealthBar   = OPT.ButtonShowHealthBar[currentSize]
				local ButtonShowHealthText  = OPT.ButtonShowHealthText[currentSize]
				local ButtonShowTarget      = OPT.ButtonShowTarget[currentSize]
				local ButtonShowFocus       = OPT.ButtonShowFocus[currentSize]
				local ButtonShowFlag        = OPT.ButtonShowFlag[currentSize]
				local ButtonShowAssist      = OPT.ButtonShowAssist[currentSize]
				local ButtonRangeCheck      = OPT.ButtonRangeCheck[currentSize]

			end
		end
	end
end
--]]
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
local function OnEvent(self, event, ...)
	if event == "PLAYER_REGEN_DISABLED" then
		if not inWorld then return end
		inCombat = true
		if isConfig then
			BattlegroundTargets:DisableInsecureConfigWidges()
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if not inWorld then return end
		inCombat = false
		if reCheckBG then
			BattlegroundTargets:BattlefieldCheck()
		end
		if reSetLayout then
			BattlegroundTargets:SetupButtonLayout()
		end
		if isConfig then
			BattlegroundTargets:EnableInsecureConfigWidges()
			if BattlegroundTargets_Options.EnableBracket[currentSize] then
				BattlegroundTargets:EnableConfigMode()
			else
				BattlegroundTargets:DisableConfigMode()
			end
		end

	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		if isConfig then return end
		if isDead then return end

		combatlogThrottle = combatlogThrottle + 1
		if combatlogThrottle > combatlogFrequency then
			combatlogThrottle = 0
			combatlogFrequency = math_random(1,3)
			return
		end

		local _, _, _, _, sourceName, _, _, _, destName, _, _, spellId = ... -- timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool = ...
		if not sourceName then return end
		if not destName then return end
		if not spellId then return end
		BattlegroundTargets:CombatLogRangeCheck(sourceName, destName, spellId)

	elseif event == "PLAYER_DEAD" then
		if not inBattleground then return end
		isDead = false
	elseif event == "PLAYER_UNGHOST" then
		if not inBattleground then return end
		isDead = false
	elseif event == "PLAYER_ALIVE" then
		if not inBattleground then return end
		if UnitIsGhost("player") then
			isDead = true
			BattlegroundTargets:ClearRangeData()
		else
			isDead = false
		end

	elseif event == "UPDATE_BATTLEFIELD_SCORE" then
		if isConfig then return end
		BattlegroundTargets:BattlefieldScoreUpdate()
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		if not inWorld then return end
		if isConfig then return end
		BattlegroundTargets:BattlefieldCheck()

	elseif event == "UNIT_TARGET" then
		if isDead then return end
		local arg1 = ...
		BattlegroundTargets:CheckUnitTarget(arg1)
	elseif event == "PLAYER_FOCUS_CHANGED" then
		BattlegroundTargets:CheckPlayerFocus()
	elseif event == "PLAYER_TARGET_CHANGED" then
		BattlegroundTargets:CheckPlayerTarget()
	elseif event == "UNIT_HEALTH_FREQUENT" then
		if isDead then return end
		local arg1 = ...
		BattlegroundTargets:CheckUnitHealth(arg1)
	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		if isDead then return end
		BattlegroundTargets:CheckUnitHealth("mouseover")

	elseif event == "RAID_ROSTER_UPDATE" then
		BattlegroundTargets:CheckAssist()

	elseif event == "CHAT_MSG_BG_SYSTEM_HORDE" then
		local arg1 = ...
		BattlegroundTargets:FlagCheck(arg1, 0) -- 'Horde'
	elseif event == "CHAT_MSG_BG_SYSTEM_ALLIANCE" then
		local arg1 = ...
		BattlegroundTargets:FlagCheck(arg1, 1) -- 'Alliance'

	elseif event == "PLAYER_LOGIN" then
		if UnitFactionGroup("player") == "Horde" then
			playerFactionDEF   = 0 -- Horde
			oppositeFactionDEF = 1 -- Alliance
		else
			playerFactionDEF   = 1 -- Alliance
			oppositeFactionDEF = 0 -- Horde
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