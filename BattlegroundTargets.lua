-- -------------------------------------------------------------------------- --
-- BattlegroundTargets by kunda                                               --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- BattlegroundTargets is a simple 'Enemy Unit Frame' for battlegrounds.      --
--                                                                            --
-- Features:                                                                  --
-- - Shows all battleground enemies with role, class and name.                --
-- - Click on button to target an enemy.                                      --
-- - Independent settings for '10 vs 10', '15 vs 15' and '40 vs 40' brackets. --
-- - Target Indicator                                                         --
-- - Target Count                                                             --
-- - It should be impossible to produce an ADDON_ACTION_BLOCKED error message --
--   by tainting the used secure templates. This includes configuration.      --
--                                                                            --
-- - Works with all officially supported languages: (I hope so)               --
--   English (Default), deDE, esES, frFR, koKR, ruRU, zhCN and zhTW           --
--                                                                            --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- Credits:                                                                   --
-- - Talented from Jerry (for a list of all localized talent specs)           --
--                                                                            --
-- -------------------------------------------------------------------------- --

-- ---------------------------------------------------------------------------------------------------------------------
BattlegroundTargets_Options = {}           -- SavedVariable options table
BattlegroundTargets = CreateFrame("Frame") -- event container

local L   = BattlegroundTargets_Localization -- localization table
local T   = BattlegroundTargets_Talents      -- localized talents
local BGN = BattlegroundTargets_BGNames      -- localized battleground names

local GVAR = {}     -- UI Widgets
local TEMPLATE = {} -- Templates

local AddonIcon = "Interface\\AddOns\\BattlegroundTargets\\BattlegroundTargets-texture-button"

local _G                      = _G
local GetTime                 = _G.GetTime
local InCombatLockdown        = _G.InCombatLockdown
local UnitName                = _G.UnitName
local UnitFactionGroup        = _G.UnitFactionGroup
local GetBattlefieldStatus    = _G.GetBattlefieldStatus
local GetNumBattlefieldScores = _G.GetNumBattlefieldScores
local GetBattlefieldScore     = _G.GetBattlefieldScore
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
local reSizeCheck = 0 -- check bgname max. 3 times if we are out of combat and normal bgname check fails (reason: sometimes GetBattlefieldStatus and GetRealZoneText returns nil)
local reSetLayout
local isConfig
local scoreUpdateThrottle = GetTime()
local scoreUpdateFrequency = 1

local playerFaction = ""  -- player Faction  : 'Horde' or 'Alliance' (set after event PLAYER_LOGIN)
local oppositeFaction = 0 -- opposite Faction: 0 = 'Horde' or 1 = 'Alliance' (set after event PLAYER_LOGIN)

local ENEMY_Data = {}     -- numerical | all data
local FRIEND_Names = {}   -- key/value | key = friendName, value = 0
local ENEMY_Names = {}    -- key/value | key = enemyName, value = count
local TARGET_Names = {}   -- key/value | key = friendName, value = enemyName

local testSize = 10
local buttonWidth = 150
local buttonHeight = 20

local sizeOffset     = 5
local sizeBarHeight = 14

local color = { -- e.g.: color.Gold.hex | color.Orange.rgb[1]...[3]
	LightYellow = {hex = "ffff7f", rgb = {1,    1,    0.49 }},
	Orange      = {hex = "ff9900", rgb = {1,    0.6,  0    }},
	Grey        = {hex = "cccccc", rgb = {0.8,  0.8,  0.8  }},
	White       = {hex = "ffffff", rgb = {1,    1,    1    }},
	Gold        = {hex = "ffd100", rgb = {1,    0.82, 0    }},
	Rselect     = {                rgb = {1,    1,    1,   0.35 }}
}

local fonts = {
	[1] = {name = "GameFontBlackTiny"},
	[2] = {name = "GameFontBlackSmall"},
	[3] = {name = "GameFontNormal"},
	[4] = {name = "GameFontBlackMedium"},
	[5] = {name = "GameFontNormalLarge"},
}
for key, value in pairs(fonts) do
	local _, fontHeight = _G[value.name]:GetFont()
	value.height = math_floor(fontHeight+0.5)
	if value.height then
		value.text = value.height.."px"
	else
		value.text = "?px"
	end
end

local currentSize = 10
local rbgSize = 10
local bgSize = {
	["Alterac Valley"] = 40,
	["Warsong Gulch"] = 10,
	["Arathi Basin"] = 15,
	["Eye of the Storm"] = 15,
	["Strand of the Ancients"] = 15,
	["Isle of Conquest"] = 40,
	["Battle for Gilneas"] = 10,
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

local classimg = "Interface\\WorldStateFrame\\Icons-Classes"
local classes = {
	DEATHKNIGHT = {icon = {0.265625, 0.484375, 0.515625, 0.734375}, -- (68/256, 124/256, 132/256, 188/256)
	               roleNum = {[1] = 2,   -- TANK   | Blood
	                          [2] = 3,   -- DAMAGE | Frost
	                          [3] = 3}}, -- DAMAGE | Unholy
	DRUID       = {icon = {0.7578125, 0.9765625, 0.015625, 0.234375}, -- (194/256, 250/256, 4/256, 60/256)
	               roleNum = {[1] = 3,   -- DAMAGE | Balance
	                          [2] = 2,   -- TANK   | FeralCombat --> maybe DAMAGE
	                          [3] = 1}}, -- HEAL   | Restoration
	HUNTER      = {icon = {0.01953125, 0.23828125, 0.265625, 0.484375}, -- (5/256, 61/256, 68/256, 124/256)
	               roleNum = {[1] = 3,   -- DAMAGE | BeastMastery
	                          [2] = 3,   -- DAMAGE | Marksmanship
	                          [3] = 3}}, -- DAMAGE | Survival
	MAGE        = {icon = {0.265625, 0.484375, 0.015625, 0.234375}, -- (68/256, 124/256, 4/256, 60/256)
	               roleNum = {[1] = 3,   -- DAMAGE | Arcane
	                          [2] = 3,   -- DAMAGE | Fire
	                          [3] = 3}}, -- DAMAGE | Frost
	PALADIN     = {icon = {0.01953125, 0.23828125, 0.515625, 0.734375}, -- (5/256, 61/256, 132/256, 188/256)
	               roleNum = {[1] = 1,   -- HEAL   | Holy
	                          [2] = 2,   -- TANK   | Protection
	                          [3] = 3}}, -- DAMAGE | Combat
	PRIEST      = {icon = {0.51171875, 0.73046875, 0.265625, 0.484375}, -- (131/256, 187/256, 68/256, 124/256)
	               roleNum = {[1] = 1,   -- HEAL   | Discipline
	                          [2] = 1,   -- HEAL   | Holy
	                          [3] = 3}}, -- DAMAGE | Shadow
	ROGUE       = {icon = {0.51171875, 0.73046875, 0.015625, 0.234375}, -- (131/256, 187/256, 4/256, 60/256)
	               roleNum = {[1] = 3,   -- DAMAGE | Assassination
	                          [2] = 3,   -- DAMAGE | Combat
	                          [3] = 3}}, -- DAMAGE | Subtlety
	SHAMAN      = {icon = {0.265625, 0.484375, 0.265625, 0.484375}, -- (68/256, 124/256, 68/256, 124/256)
	               roleNum = {[1] = 3,   -- DAMAGE | ElementalCombat
	                          [2] = 3,   -- DAMAGE | Enhancement
	                          [3] = 1}}, -- HEAL   | Restoration
	WARLOCK     = {icon = {0.7578125, 0.9765625, 0.265625, 0.484375}, -- (194/256, 250/256, 68/256, 124/256)
	               roleNum = {[1] = 3,   -- DAMAGE | Curses
	                          [2] = 3,   -- DAMAGE | Summoning
	                          [3] = 3}}, -- DAMAGE | Destruction
	WARRIOR     = {icon = {0.01953125, 0.23828125, 0.015625, 0.234375}, -- (5/256, 61/256, 4/256, 60/256)
	               roleNum = {[1] = 3,   -- DAMAGE | Arms
	                          [2] = 3,   -- DAMAGE | Fury
	                          [3] = 2}}, -- TANK   | Protection
	ZZZFAILURE  = {icon = {0, 0, 0, 0},
	               roleNum = {[1] = 4,
	                          [2] = 4,
	                          [3] = 4}},
}

local roleimg = "Interface\\LFGFrame\\LFGRole"
local roles = {
	[1] = {48/64, 64/64, 0/16, 16/16}, -- HEAL
	[2] = {32/64, 48/64, 0/16, 16/16}, -- TANK
	[3] = {16/64, 32/64, 0/16, 16/16}, -- DAMAGE
	[4] = {0, 0, 0, 0},                -- UNKNWON
}

local function rt(H,E,M,P) return E,P,E,M,H,P,H,M end -- magical 180 degree texture cut center rotation

local Textures = {
	BattlegroundTargetsIcons = {path= "Interface\\Addons\\BattlegroundTargets\\BattlegroundTargets-texture-icons.tga"}, -- Textures.BattlegroundTargetsIcons.path
	SliderKnob       = {coords     =    { 19/64, 36/64,  8/32, 25/32}},
	SliderBG         = {coordsL    =    { 19/64, 24/64,  1/32,  7/32},
	                    coordsM    =    { 27/64, 28/64,  1/32,  7/32},
	                    coordsR    =    { 31/64, 36/64,  1/32,  7/32},
	                    coordsLdis =    {  1/64,  6/64,  1/32,  7/32},
	                    coordsMdis =    {  9/64, 10/64,  1/32,  7/32},
	                    coordsRdis =    { 13/64, 18/64,  1/32,  7/32}},
	Expand           = {coords     =    {  1/64, 18/64,  8/32, 25/32}},
	Collapse         = {coords     = {rt(  1/64, 18/64,  8/32, 25/32)}}, -- 180 degree rota
}
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
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
-- ---------------------------------------------------------------------------------------------------------------------

local function FontPullDownFunc(value)
	BattlegroundTargets_Options.ButtonFontSize[currentSize] = value
	BattlegroundTargets:SetupButtonLayout()
end

local function SortByTitlePullDownFunc(value)
	BattlegroundTargets_Options.ButtonSortBySize[currentSize] = value
	BattlegroundTargets:UpdateLayout()
	BattlegroundTargets:SetupButtonLayout()
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
	button.Border:SetTexture(0.4, 0.4, 0.4, 1)

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

	slider.textMin = slider:CreateFontString(nil, "ARTWORK", "GameFontWhiteSmall")
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
	else
		slider.textMin:SetText(minVal)
	end
	slider.textMax = slider:CreateFontString(nil, "ARTWORK", "GameFontWhiteSmall")
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
	slider.thumb:SetWidth(17)
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

	button.PullDownButtonText = button:CreateFontString(nil, "ARTWORK", "GameFontWhiteSmall")
	button.PullDownButtonText:SetWidth(pulldownWidth-sizeOffset-sizeOffset)
	button.PullDownButtonText:SetHeight(sizeBarHeight)
	button.PullDownButtonText:SetPoint("LEFT", sizeOffset+2, 0)
	button.PullDownButtonText:SetJustifyH("LEFT")
	button.PullDownButtonText:SetText(buttonText)
	--button.PullDownButtonText:SetTextColor(1, 1, 0.5, 1)

	button.PullDownMenu = CreateFrame("Frame", nil, button)
	TEMPLATE.BorderTRBL(button.PullDownMenu)
	button.PullDownMenu:EnableMouse(true)
	button.PullDownMenu:SetToplevel(true)
	button.PullDownMenu:SetWidth(pulldownWidth)
	button.PullDownMenu:SetHeight(sizeOffset+(contentNum*sizeBarHeight)+sizeOffset)
	button.PullDownMenu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, 1)
	button.PullDownMenu:Hide()

	local function OnLeave()
		if not button:IsMouseOver() and not button.PullDownMenu:IsMouseOver() then
			button.PullDownMenu:Hide()
			button.PullDownButtonExpand:SetTexCoord(unpack(Textures.Expand.coords))
		end
	end

	for i = 1, contentNum do
		if not button.PullDownMenu.Button then button.PullDownMenu.Button = {} end
		button.PullDownMenu.Button[i] = CreateFrame("Button", nil, button.PullDownMenu)
		button.PullDownMenu.Button[i]:SetWidth(pulldownWidth-sizeOffset-sizeOffset)
		button.PullDownMenu.Button[i]:SetHeight(sizeBarHeight)
		button.PullDownMenu.Button[i]:SetFrameLevel( button.PullDownMenu:GetFrameLevel() + 5 )
		if i == 1 then
			button.PullDownMenu.Button[i]:SetPoint("TOPLEFT", button.PullDownMenu, "TOPLEFT", sizeOffset, -sizeOffset)
		else
			button.PullDownMenu.Button[i]:SetPoint("TOPLEFT", button.PullDownMenu.Button[(i-1)], "BOTTOMLEFT", 0, 0)
		end

		button.PullDownMenu.Button[i].Text = button.PullDownMenu.Button[i]:CreateFontString(nil, "ARTWORK", "GameFontWhiteSmall")
		button.PullDownMenu.Button[i].Text:SetWidth(pulldownWidth-sizeOffset-sizeOffset)
		button.PullDownMenu.Button[i].Text:SetHeight(sizeBarHeight)
		button.PullDownMenu.Button[i].Text:SetPoint("LEFT", 2, 0)
		button.PullDownMenu.Button[i].Text:SetJustifyH("LEFT")

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

		if contentName == "Font" then
			button.PullDownMenu.Button[i].Text:SetText(fonts[i].text)
			button.PullDownMenu.Button[i].value1 = i
		elseif contentName == "SortBy" then
			button.PullDownMenu.Button[i].Text:SetText(sortBy[i])
			button.PullDownMenu.Button[i].value1 = i
		end
		button.PullDownMenu.Button[i]:Show()	
	end

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
	print("|cff"..color.LightYellow.hex.."BattlegroundTargets:|r", ...)
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

	if BattlegroundTargets_Options.version                   == nil then BattlegroundTargets_Options.version                   = 1     end
	if BattlegroundTargets_Options.MinimapButton             == nil then BattlegroundTargets_Options.MinimapButton             = false end
	if BattlegroundTargets_Options.MinimapButtonPos          == nil then BattlegroundTargets_Options.MinimapButtonPos          = -90   end

	if BattlegroundTargets_Options.ButtonEnableBracket       == nil then BattlegroundTargets_Options.ButtonEnableBracket       = {}    end
	if BattlegroundTargets_Options.ButtonClassIcon           == nil then BattlegroundTargets_Options.ButtonClassIcon           = {}    end
	if BattlegroundTargets_Options.ButtonShowRealm           == nil then BattlegroundTargets_Options.ButtonShowRealm           = {}    end
	if BattlegroundTargets_Options.ButtonShowCrosshairs      == nil then BattlegroundTargets_Options.ButtonShowCrosshairs      = {}    end
	if BattlegroundTargets_Options.ButtonShowTargetCount     == nil then BattlegroundTargets_Options.ButtonShowTargetCount     = {}    end
	if BattlegroundTargets_Options.ButtonSortBySize          == nil then BattlegroundTargets_Options.ButtonSortBySize          = {}    end
	if BattlegroundTargets_Options.ButtonFontSize            == nil then BattlegroundTargets_Options.ButtonFontSize            = {}    end
	if BattlegroundTargets_Options.ButtonScale               == nil then BattlegroundTargets_Options.ButtonScale               = {}    end
	if BattlegroundTargets_Options.ButtonWidth               == nil then BattlegroundTargets_Options.ButtonWidth               = {}    end
	if BattlegroundTargets_Options.ButtonHeight              == nil then BattlegroundTargets_Options.ButtonHeight              = {}    end

	if BattlegroundTargets_Options.ButtonEnableBracket[10]   == nil then BattlegroundTargets_Options.ButtonEnableBracket[10]   = false end
	if BattlegroundTargets_Options.ButtonClassIcon[10]       == nil then BattlegroundTargets_Options.ButtonClassIcon[10]       = false end
	if BattlegroundTargets_Options.ButtonShowRealm[10]       == nil then BattlegroundTargets_Options.ButtonShowRealm[10]       = true  end
	if BattlegroundTargets_Options.ButtonShowCrosshairs[10]  == nil then BattlegroundTargets_Options.ButtonShowCrosshairs[10]  = true  end
	if BattlegroundTargets_Options.ButtonShowTargetCount[10] == nil then BattlegroundTargets_Options.ButtonShowTargetCount[10] = true  end
	if BattlegroundTargets_Options.ButtonSortBySize[10]      == nil then BattlegroundTargets_Options.ButtonSortBySize[10]      = 1     end
	if BattlegroundTargets_Options.ButtonFontSize[10]        == nil then BattlegroundTargets_Options.ButtonFontSize[10]        = 2     end
	if BattlegroundTargets_Options.ButtonScale[10]           == nil then BattlegroundTargets_Options.ButtonScale[10]           = 1     end
	if BattlegroundTargets_Options.ButtonWidth[10]           == nil then BattlegroundTargets_Options.ButtonWidth[10]           = 150   end
	if BattlegroundTargets_Options.ButtonHeight[10]          == nil then BattlegroundTargets_Options.ButtonHeight[10]          = 20    end

	if BattlegroundTargets_Options.ButtonEnableBracket[15]   == nil then BattlegroundTargets_Options.ButtonEnableBracket[15]   = false end
	if BattlegroundTargets_Options.ButtonClassIcon[15]       == nil then BattlegroundTargets_Options.ButtonClassIcon[15]       = false end
	if BattlegroundTargets_Options.ButtonShowRealm[15]       == nil then BattlegroundTargets_Options.ButtonShowRealm[15]       = true  end
	if BattlegroundTargets_Options.ButtonShowCrosshairs[15]  == nil then BattlegroundTargets_Options.ButtonShowCrosshairs[15]  = true  end
	if BattlegroundTargets_Options.ButtonShowTargetCount[15] == nil then BattlegroundTargets_Options.ButtonShowTargetCount[15] = true  end
	if BattlegroundTargets_Options.ButtonSortBySize[15]      == nil then BattlegroundTargets_Options.ButtonSortBySize[15]      = 1     end
	if BattlegroundTargets_Options.ButtonFontSize[15]        == nil then BattlegroundTargets_Options.ButtonFontSize[15]        = 2     end
	if BattlegroundTargets_Options.ButtonScale[15]           == nil then BattlegroundTargets_Options.ButtonScale[15]           = 1     end
	if BattlegroundTargets_Options.ButtonWidth[15]           == nil then BattlegroundTargets_Options.ButtonWidth[15]           = 150   end
	if BattlegroundTargets_Options.ButtonHeight[15]          == nil then BattlegroundTargets_Options.ButtonHeight[15]          = 20    end

	if BattlegroundTargets_Options.ButtonEnableBracket[40]   == nil then BattlegroundTargets_Options.ButtonEnableBracket[40]   = false end
	if BattlegroundTargets_Options.ButtonClassIcon[40]       == nil then BattlegroundTargets_Options.ButtonClassIcon[40]       = false end
	if BattlegroundTargets_Options.ButtonShowRealm[40]       == nil then BattlegroundTargets_Options.ButtonShowRealm[40]       = false end
	if BattlegroundTargets_Options.ButtonShowCrosshairs[40]  == nil then BattlegroundTargets_Options.ButtonShowCrosshairs[40]  = true  end
	if BattlegroundTargets_Options.ButtonShowTargetCount[40] == nil then BattlegroundTargets_Options.ButtonShowTargetCount[40] = false end
	if BattlegroundTargets_Options.ButtonSortBySize[40]      == nil then BattlegroundTargets_Options.ButtonSortBySize[40]      = 1     end
	if BattlegroundTargets_Options.ButtonFontSize[40]        == nil then BattlegroundTargets_Options.ButtonFontSize[40]        = 1     end
	if BattlegroundTargets_Options.ButtonScale[40]           == nil then BattlegroundTargets_Options.ButtonScale[40]           = 0.9   end
	if BattlegroundTargets_Options.ButtonWidth[40]           == nil then BattlegroundTargets_Options.ButtonWidth[40]           = 100   end
	if BattlegroundTargets_Options.ButtonHeight[40]          == nil then BattlegroundTargets_Options.ButtonHeight[40]          = 14    end
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

	GVAR.InterfaceOptions.SlashCommandText = GVAR.InterfaceOptions:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	GVAR.InterfaceOptions.SlashCommandText:SetText("|cff"..color.LightYellow.hex.."/bgt|r - |cff"..color.LightYellow.hex.."/bgtargets|r - |cff"..color.LightYellow.hex.."/battlegroundtargets|r")
	GVAR.InterfaceOptions.SlashCommandText:SetNonSpaceWrap(true)
	GVAR.InterfaceOptions.SlashCommandText:SetPoint("LEFT", GVAR.InterfaceOptions.CONFIG, "RIGHT", 10, 0)

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
		if inCombat or InCombatLockdown() then
			--Print("InCombatLockdown! MainFrame moving is disabled in combat.")
			return
		end
		GVAR.MainFrame:StartMoving()
	end)
	GVAR.MainFrame:SetScript("OnMouseUp", function()
		if inCombat or InCombatLockdown() then
			--Print("InCombatLockdown! MainFrame moving is disabled in combat.")
			return
		end
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
		self.HighlightBackground:SetTexture(0, 0, 0, 1)
	end

	GVAR.TargetButton = {}
	for i = 1, 40 do
		GVAR.TargetButton[i] = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
		GVAR.TargetButton[i]:SetWidth(buttonWidth)
		GVAR.TargetButton[i]:SetHeight(buttonHeight)
		if i == 1 then
			GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.MainFrame, "BOTTOMLEFT", 0, 0)
		--elseif i == 21 then
		--	GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[1], "TOPRIGHT", 0, 0)
		else
			GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[(i-1)], "BOTTOMLEFT", 0, 0)
		end
		GVAR.TargetButton[i]:Hide()

		GVAR.TargetButton[i].HighlightBackground = GVAR.TargetButton[i]:CreateTexture(nil, "BACKGROUND")
		GVAR.TargetButton[i].HighlightBackground:SetWidth(buttonWidth)
		GVAR.TargetButton[i].HighlightBackground:SetHeight(buttonHeight)
		GVAR.TargetButton[i].HighlightBackground:SetPoint("TOPLEFT", 0, 0)
		GVAR.TargetButton[i].HighlightBackground:SetTexture(0, 0, 0, 1)

		GVAR.TargetButton[i].SpecTextureBackground = GVAR.TargetButton[i]:CreateTexture(nil, "BORDER")
		GVAR.TargetButton[i].SpecTextureBackground:SetWidth((buttonHeight-2)*2)
		GVAR.TargetButton[i].SpecTextureBackground:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].SpecTextureBackground:SetPoint("LEFT", GVAR.TargetButton[i], "LEFT", 1, 0)
		GVAR.TargetButton[i].SpecTextureBackground:SetTexture(0, 0, 0, 1)

		GVAR.TargetButton[i].SpecTexture = GVAR.TargetButton[i]:CreateTexture(nil, "ARTWORK")
		GVAR.TargetButton[i].SpecTexture:SetWidth(buttonHeight-2)
		GVAR.TargetButton[i].SpecTexture:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].SpecTexture:SetPoint("LEFT", GVAR.TargetButton[i], "LEFT", 1, 0)
		GVAR.TargetButton[i].SpecTexture:SetTexture(roleimg)

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

		GVAR.TargetButton[i].Name = GVAR.TargetButton[i]:CreateFontString(nil, "ARTWORK", "GameFontBlackSmall")
		GVAR.TargetButton[i].Name:SetWidth((buttonWidth-2) - (buttonHeight-2) - (buttonHeight-2) -2)
		GVAR.TargetButton[i].Name:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].Name:SetPoint("LEFT", GVAR.TargetButton[i].ClassTexture, "RIGHT", 2, 0)
		GVAR.TargetButton[i].Name:SetJustifyH("LEFT")

		GVAR.TargetButton[i].TargetCountBackground = GVAR.TargetButton[i]:CreateTexture(nil, "OVERLAY")
		GVAR.TargetButton[i].TargetCountBackground:SetWidth(20)
		GVAR.TargetButton[i].TargetCountBackground:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].TargetCountBackground:SetPoint("RIGHT", GVAR.TargetButton[i].ClassColorBackground, "RIGHT", 0, 0)
		GVAR.TargetButton[i].TargetCountBackground:SetTexture(0, 0, 0, 0.8)
		GVAR.TargetButton[i].TargetCountBackground:SetAlpha(1)

		GVAR.TargetButton[i].TargetCount = GVAR.TargetButton[i]:CreateFontString(nil, "OVERLAY", "GameFontBlackSmall")
		GVAR.TargetButton[i].TargetCount:SetWidth(20)
		GVAR.TargetButton[i].TargetCount:SetHeight(buttonHeight-4)
		GVAR.TargetButton[i].TargetCount:SetPoint("CENTER", GVAR.TargetButton[i].TargetCountBackground, "CENTER", 0, 0)
		GVAR.TargetButton[i].TargetCount:SetJustifyH("CENTER")

		GVAR.TargetButton[i].TargetTexture = GVAR.TargetButton[i]:CreateTexture(nil, "OVERLAY")
		GVAR.TargetButton[i].TargetTexture:SetWidth(buttonHeight-2)
		GVAR.TargetButton[i].TargetTexture:SetHeight(buttonHeight-2)
		GVAR.TargetButton[i].TargetTexture:SetPoint("RIGHT", GVAR.TargetButton[i].TargetCountBackground, "LEFT", 0, 0)
		GVAR.TargetButton[i].TargetTexture:SetTexture(AddonIcon)
		GVAR.TargetButton[i].TargetTexture:SetAlpha(0)

		GVAR.TargetButton[i]:RegisterForClicks("LeftButtonUp")
		GVAR.TargetButton[i]:SetAttribute("type1", "macro")
		GVAR.TargetButton[i]:SetAttribute("macrotext", "")
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
	local frameHeight = 520
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

	-- Base Frame START
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
	local w1 = ( frameWidth-(3*tabWidth)-(2*3) ) / 2
	
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
		BattlegroundTargets:UpdateLayout()
		BattlegroundTargets:SetupButtonLayout()
	end)

	-- - class icon
	GVAR.OptionsFrame.ClassIcon = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ClassIcon, 16, 4, L["Show Class Icon"])
	GVAR.OptionsFrame.ClassIcon:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ClassIcon:SetPoint("TOP", GVAR.OptionsFrame.EnableBracket, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ClassIcon:SetChecked(BattlegroundTargets_Options.ButtonClassIcon[currentSize])
	GVAR.OptionsFrame.ClassIcon:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonClassIcon[currentSize] = not BattlegroundTargets_Options.ButtonClassIcon[currentSize]
		GVAR.OptionsFrame.ClassIcon:SetChecked(BattlegroundTargets_Options.ButtonClassIcon[currentSize])
		BattlegroundTargets:UpdateLayout()
		BattlegroundTargets:SetupButtonLayout()
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
		BattlegroundTargets:SetupButtonLayout()
	end)

	-- - show crosshairs
	GVAR.OptionsFrame.ShowCrosshairs = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowCrosshairs, 16, 4, L["Show Target Indicator"])
	GVAR.OptionsFrame.ShowCrosshairs:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ShowCrosshairs:SetPoint("TOP", GVAR.OptionsFrame.ShowRealm, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ShowCrosshairs:SetChecked(BattlegroundTargets_Options.ButtonShowCrosshairs[currentSize])
	GVAR.OptionsFrame.ShowCrosshairs:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowCrosshairs[currentSize] = not BattlegroundTargets_Options.ButtonShowCrosshairs[currentSize]
		GVAR.OptionsFrame.ShowCrosshairs:SetChecked(BattlegroundTargets_Options.ButtonShowCrosshairs[currentSize])
		BattlegroundTargets:EnableConfigMode()
		BattlegroundTargets:SetupButtonLayout()
	end)

	-- - show targetcount
	GVAR.OptionsFrame.ShowTargetCount = CreateFrame("CheckButton", nil, GVAR.OptionsFrame)
	TEMPLATE.CheckButton(GVAR.OptionsFrame.ShowTargetCount, 16, 4, L["Show Target Count"])
	GVAR.OptionsFrame.ShowTargetCount:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.ShowTargetCount:SetPoint("TOP", GVAR.OptionsFrame.ShowCrosshairs, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.ShowTargetCount:SetChecked(BattlegroundTargets_Options.ButtonShowTargetCount[currentSize])
	GVAR.OptionsFrame.ShowTargetCount:SetScript("OnClick", function(self)
		BattlegroundTargets_Options.ButtonShowTargetCount[currentSize] = not BattlegroundTargets_Options.ButtonShowTargetCount[currentSize]
		GVAR.OptionsFrame.ShowTargetCount:SetChecked(BattlegroundTargets_Options.ButtonShowTargetCount[currentSize])
		BattlegroundTargets:EnableConfigMode()
		BattlegroundTargets:SetupButtonLayout()
	end)

	-- - sort by
	GVAR.OptionsFrame.SortByTitle = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.SortByTitle:SetHeight(20)
	GVAR.OptionsFrame.SortByTitle:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.SortByTitle:SetPoint("TOP", GVAR.OptionsFrame.ShowTargetCount, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.SortByTitle:SetJustifyH("LEFT")
	GVAR.OptionsFrame.SortByTitle:SetText(L["Sort By"]..":")
	GVAR.OptionsFrame.SortByTitle:SetTextColor(1, 1, 1, 1)

	GVAR.OptionsFrame.SortByTitlePullDown = CreateFrame("Button", nil, GVAR.OptionsFrame)
	TEMPLATE.PullDownMenu(GVAR.OptionsFrame.SortByTitlePullDown, "SortBy", sortBy[ BattlegroundTargets_Options.ButtonSortBySize[currentSize] ], 150, #sortBy, SortByTitlePullDownFunc)
	GVAR.OptionsFrame.SortByTitlePullDown:SetPoint("LEFT", GVAR.OptionsFrame.SortByTitle, "RIGHT", 10, 0)
	GVAR.OptionsFrame.SortByTitlePullDown:SetWidth(150)
	GVAR.OptionsFrame.SortByTitlePullDown:SetHeight(18)
	TEMPLATE.EnablePullDownMenu(GVAR.OptionsFrame.SortByTitlePullDown)

	-- - font
	GVAR.OptionsFrame.FontTitle = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.FontTitle:SetHeight(20)
	GVAR.OptionsFrame.FontTitle:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.FontTitle:SetPoint("TOP", GVAR.OptionsFrame.SortByTitle, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.FontTitle:SetJustifyH("LEFT")
	GVAR.OptionsFrame.FontTitle:SetText(L["Text Size"]..":")
	GVAR.OptionsFrame.FontTitle:SetTextColor(1, 1, 1, 1)

	GVAR.OptionsFrame.FontPullDown = CreateFrame("Button", nil, GVAR.OptionsFrame)
	TEMPLATE.PullDownMenu(GVAR.OptionsFrame.FontPullDown, "Font", fonts[ BattlegroundTargets_Options.ButtonFontSize[currentSize] ].text, 70, #fonts, FontPullDownFunc)
	GVAR.OptionsFrame.FontPullDown:SetPoint("LEFT", GVAR.OptionsFrame.FontTitle, "RIGHT", 10, 0)
	GVAR.OptionsFrame.FontPullDown:SetWidth(70)
	GVAR.OptionsFrame.FontPullDown:SetHeight(18)
	TEMPLATE.EnablePullDownMenu(GVAR.OptionsFrame.FontPullDown)

	-- - scale
	GVAR.OptionsFrame.Scale = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.Scale:SetHeight(20)
	GVAR.OptionsFrame.Scale:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.Scale:SetPoint("TOP", GVAR.OptionsFrame.FontTitle, "BOTTOM", 0, -10)
	GVAR.OptionsFrame.Scale:SetJustifyH("LEFT")
	GVAR.OptionsFrame.Scale:SetText(L["Scale"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonScale[currentSize]*100).."%|r")
	GVAR.OptionsFrame.Scale:SetTextColor(1, 1, 1, 1)

	GVAR.OptionsFrame.ScaleSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	TEMPLATE.Slider(GVAR.OptionsFrame.ScaleSlider, 180, 5, 50, 200, BattlegroundTargets_Options.ButtonScale[currentSize]*100,
	function(self, value)
		BattlegroundTargets_Options.ButtonScale[currentSize] = value/100
		BattlegroundTargets:SetupButtonLayout()
		GVAR.OptionsFrame.Scale:SetText(L["Scale"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonScale[currentSize]*100).."%|r")
	end,
	"%",
	10)
	GVAR.OptionsFrame.ScaleSlider:SetPoint("LEFT", GVAR.OptionsFrame.Scale, "LEFT", 0, 0)
	GVAR.OptionsFrame.ScaleSlider:SetPoint("TOP", GVAR.OptionsFrame.Scale, "BOTTOM", 0, 5)

	-- - width
	GVAR.OptionsFrame.Width = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.Width:SetHeight(20)
	GVAR.OptionsFrame.Width:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.Width:SetPoint("TOP", GVAR.OptionsFrame.ScaleSlider, "BOTTOM", 0, -20)
	GVAR.OptionsFrame.Width:SetJustifyH("LEFT")
	GVAR.OptionsFrame.Width:SetText(L["Width"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonWidth[currentSize]).."|r")
	GVAR.OptionsFrame.Width:SetTextColor(1, 1, 1, 1)

	GVAR.OptionsFrame.WidthSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	TEMPLATE.Slider(GVAR.OptionsFrame.WidthSlider, 180, 5, 50, 250, BattlegroundTargets_Options.ButtonWidth[currentSize],
	function(self, value)
		BattlegroundTargets_Options.ButtonWidth[currentSize] = value
		BattlegroundTargets:SetupButtonLayout()
		GVAR.OptionsFrame.Width:SetText(L["Width"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonWidth[currentSize]).."|r")
	end,
	nil,
	10)
	GVAR.OptionsFrame.WidthSlider:SetPoint("LEFT", GVAR.OptionsFrame.Width, "LEFT", 0, 0)
	GVAR.OptionsFrame.WidthSlider:SetPoint("TOP", GVAR.OptionsFrame.Width, "BOTTOM", 0, 5)

	-- - height
	GVAR.OptionsFrame.Height = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.Height:SetHeight(20)
	GVAR.OptionsFrame.Height:SetPoint("LEFT", GVAR.OptionsFrame.WidthSlider, "RIGHT", 20, 0)
	GVAR.OptionsFrame.Height:SetPoint("TOP", GVAR.OptionsFrame.Width, "TOP", 0, 0)
	GVAR.OptionsFrame.Height:SetJustifyH("LEFT")
	GVAR.OptionsFrame.Height:SetText(L["Height"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonHeight[currentSize]).."|r")
	GVAR.OptionsFrame.Height:SetTextColor(1, 1, 1, 1)

	GVAR.OptionsFrame.HeightSlider = CreateFrame("Slider", nil, GVAR.OptionsFrame)
	TEMPLATE.Slider(GVAR.OptionsFrame.HeightSlider, 180, 1, 12, 25, BattlegroundTargets_Options.ButtonHeight[currentSize],
	function(self, value)
		BattlegroundTargets_Options.ButtonHeight[currentSize] = value
		BattlegroundTargets:SetupButtonLayout()
		GVAR.OptionsFrame.Height:SetText(L["Height"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonHeight[currentSize]).."|r")
	end,
	nil,
	10)
	GVAR.OptionsFrame.HeightSlider:SetPoint("LEFT", GVAR.OptionsFrame.Height, "LEFT", 0, 0)
	GVAR.OptionsFrame.HeightSlider:SetPoint("TOP", GVAR.OptionsFrame.Height, "BOTTOM", 0, 5)



	GVAR.OptionsFrame.Dummy = CreateFrame("Frame", nil, GVAR.OptionsFrame)
	TEMPLATE.BorderTRBL(GVAR.OptionsFrame.Dummy)
	GVAR.OptionsFrame.Dummy:SetWidth(frameWidth)
	GVAR.OptionsFrame.Dummy:SetHeight(1)
	GVAR.OptionsFrame.Dummy:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 0, 0)
	GVAR.OptionsFrame.Dummy:SetPoint("TOP", GVAR.OptionsFrame.HeightSlider, "BOTTOM", 0, -20)

	GVAR.OptionsFrame.General = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	GVAR.OptionsFrame.General:SetHeight(20)
	GVAR.OptionsFrame.General:SetPoint("LEFT", GVAR.OptionsFrame, "LEFT", 10, 0)
	GVAR.OptionsFrame.General:SetPoint("TOP", GVAR.OptionsFrame.HeightSlider, "BOTTOM", 0, -30)
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
	GVAR.OptionsFrame.CloseConfigText = GVAR.OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	GVAR.OptionsFrame.CloseConfigText:SetPoint("BOTTOM", GVAR.OptionsFrame, "BOTTOM", 0, 10)
	GVAR.OptionsFrame.CloseConfigText:SetJustifyH("LEFT")
	GVAR.OptionsFrame.CloseConfigText:SetText(L["'Esc -> Interface -> AddOns -> BattlegroundTargets' to change Options!"])
	GVAR.OptionsFrame.CloseConfigText:SetTextColor(1, 1, 0.5, 1)

	GVAR.OptionsFrame.CloseConfig = CreateFrame("Button", nil, GVAR.OptionsFrame)
	TEMPLATE.TextButton(GVAR.OptionsFrame.CloseConfig, L["Close Configuration (or press 'Esc')"], 1)
	GVAR.OptionsFrame.CloseConfig:SetPoint("BOTTOM", GVAR.OptionsFrame.CloseConfigText, "TOP", 0, 10)
	GVAR.OptionsFrame.CloseConfig:SetWidth(frameWidth-20)
	GVAR.OptionsFrame.CloseConfig:SetHeight(30)
	GVAR.OptionsFrame.CloseConfig:SetScript("OnClick", function()
		GVAR.OptionsFrame:Hide()
	end)



	-- Mover
	GVAR.OptionsFrame.MoverTop = CreateFrame("Frame", nil, GVAR.OptionsFrame)
	TEMPLATE.BorderTRBL(GVAR.OptionsFrame.MoverTop)
	GVAR.OptionsFrame.MoverTop:SetWidth(frameWidth)
	GVAR.OptionsFrame.MoverTop:SetHeight(20)
	GVAR.OptionsFrame.MoverTop:SetPoint("BOTTOM", GVAR.OptionsFrame, "TOP", 0, -1)
	GVAR.OptionsFrame.MoverTop:EnableMouse(true)
	GVAR.OptionsFrame.MoverTop:EnableMouseWheel(true)
	GVAR.OptionsFrame.MoverTop:SetScript("OnMouseWheel", NOOP)
	GVAR.OptionsFrame.MoverTopText = GVAR.OptionsFrame.MoverTop:CreateFontString(nil, "ARTWORK", "GameFontWhiteSmall")
	GVAR.OptionsFrame.MoverTopText:SetPoint("CENTER", GVAR.OptionsFrame.MoverTop, "CENTER", 0, 0)
	GVAR.OptionsFrame.MoverTopText:SetJustifyH("CENTER")
	GVAR.OptionsFrame.MoverTopText:SetTextColor(0.3, 0.3, 0.3, 1)
	GVAR.OptionsFrame.MoverTopText:SetText(L["click & move"])

	GVAR.OptionsFrame.MoverBottom = CreateFrame("Frame", nil, GVAR.OptionsFrame)
	TEMPLATE.BorderTRBL(GVAR.OptionsFrame.MoverBottom)
	GVAR.OptionsFrame.MoverBottom:SetWidth(frameWidth)
	GVAR.OptionsFrame.MoverBottom:SetHeight(20)
	GVAR.OptionsFrame.MoverBottom:SetPoint("TOP", GVAR.OptionsFrame, "BOTTOM", 0, 1)
	GVAR.OptionsFrame.MoverBottom:EnableMouse(true)
	GVAR.OptionsFrame.MoverBottom:EnableMouseWheel(true)
	GVAR.OptionsFrame.MoverBottom:SetScript("OnMouseWheel", NOOP)
	GVAR.OptionsFrame.MoverBottomText = GVAR.OptionsFrame.MoverBottom:CreateFontString(nil, "ARTWORK", "GameFontWhiteSmall")
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
	GVAR.OptionsFrame.ClassIcon:SetChecked(BattlegroundTargets_Options.ButtonClassIcon[currentSize])
	GVAR.OptionsFrame.ShowRealm:SetChecked(BattlegroundTargets_Options.ButtonShowRealm[currentSize])
	GVAR.OptionsFrame.ShowCrosshairs:SetChecked(BattlegroundTargets_Options.ButtonShowCrosshairs[currentSize])
	GVAR.OptionsFrame.ShowTargetCount:SetChecked(BattlegroundTargets_Options.ButtonShowTargetCount[currentSize])

	GVAR.OptionsFrame.FontPullDown.PullDownButtonText:SetText(fonts[ BattlegroundTargets_Options.ButtonFontSize[currentSize] ].text)

	GVAR.OptionsFrame.SortByTitlePullDown.PullDownButtonText:SetText(sortBy[ BattlegroundTargets_Options.ButtonSortBySize[currentSize] ])

	GVAR.OptionsFrame.ScaleSlider:SetValue(BattlegroundTargets_Options.ButtonScale[currentSize]*100)
	GVAR.OptionsFrame.Scale:SetText(L["Scale"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonScale[currentSize]*100).."%|r")

	GVAR.OptionsFrame.WidthSlider:SetValue(BattlegroundTargets_Options.ButtonWidth[currentSize])
	GVAR.OptionsFrame.Width:SetText(L["Width"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonWidth[currentSize]).."|r")

	GVAR.OptionsFrame.HeightSlider:SetValue(BattlegroundTargets_Options.ButtonHeight[currentSize])
	GVAR.OptionsFrame.Height:SetText(L["Height"]..": |cffffff99"..(BattlegroundTargets_Options.ButtonHeight[currentSize]).."|r")
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
		--Print("InCombatLockdown! Configuration is disabled in combat.")
		return
	end
	local scale  = BattlegroundTargets_Options.ButtonScale[currentSize]
	local width  = BattlegroundTargets_Options.ButtonWidth[currentSize]
	local height = BattlegroundTargets_Options.ButtonHeight[currentSize]
	
	local fontHeight = fonts[ BattlegroundTargets_Options.ButtonFontSize[currentSize] ].height
	if height < fontHeight then
		fontHeight = height
	end

	local withIconWidth
	if BattlegroundTargets_Options.ButtonClassIcon[currentSize] then
		withIconWidth = width
	else
		withIconWidth = width + (height-2)
	end

	for i = 1, 40 do
		GVAR.TargetButton[i]:SetScale(scale)
			
		GVAR.TargetButton[i]:SetWidth(width)
		GVAR.TargetButton[i]:SetHeight(height)
		GVAR.TargetButton[i].HighlightBackground:SetWidth(width)
		GVAR.TargetButton[i].HighlightBackground:SetHeight(height)

		if BattlegroundTargets_Options.ButtonClassIcon[currentSize] then
			GVAR.TargetButton[i].SpecTextureBackground:SetWidth((height-2)*2)
			GVAR.TargetButton[i].SpecTextureBackground:SetHeight(height-2)
		else
			GVAR.TargetButton[i].SpecTextureBackground:SetWidth(height-2)
			GVAR.TargetButton[i].SpecTextureBackground:SetHeight(height-2)
		end

		GVAR.TargetButton[i].SpecTexture:SetWidth(height-2)
		GVAR.TargetButton[i].SpecTexture:SetHeight(height-2)
		GVAR.TargetButton[i].ClassTexture:SetWidth(height-2)
		GVAR.TargetButton[i].ClassTexture:SetHeight(height-2)
		GVAR.TargetButton[i].ClassColorBackground:SetWidth((withIconWidth-2) - (height-2) - (height-2))
		GVAR.TargetButton[i].ClassColorBackground:SetHeight(height-2)

		if BattlegroundTargets_Options.ButtonClassIcon[currentSize] then
			GVAR.TargetButton[i].ClassTexture:Show()
			GVAR.TargetButton[i].ClassColorBackground:SetPoint("LEFT", GVAR.TargetButton[i].ClassTexture, "RIGHT", 0, 0)
			GVAR.TargetButton[i].Name:SetPoint("LEFT", GVAR.TargetButton[i].ClassTexture, "RIGHT", 2, 0)
		else
			GVAR.TargetButton[i].ClassTexture:Hide()
			GVAR.TargetButton[i].ClassColorBackground:SetPoint("LEFT", GVAR.TargetButton[i].SpecTexture, "RIGHT", 0, 0)
			GVAR.TargetButton[i].Name:SetPoint("LEFT", GVAR.TargetButton[i].SpecTexture, "RIGHT", 2, 0)
		end
		
		GVAR.TargetButton[i].Name:SetFontObject(fonts[ BattlegroundTargets_Options.ButtonFontSize[currentSize] ].name)
		GVAR.TargetButton[i].Name:SetShadowOffset(0, 0)
		GVAR.TargetButton[i].Name:SetShadowColor(0, 0, 0, 0)
		GVAR.TargetButton[i].Name:SetTextColor(0, 0, 0, 1)
		GVAR.TargetButton[i].Name:SetWidth((withIconWidth-2) - (height-2) - (height-2) -2)
		GVAR.TargetButton[i].Name:SetHeight(fontHeight)
		
		if BattlegroundTargets_Options.ButtonShowTargetCount[currentSize] then
			GVAR.TargetButton[i].TargetCountBackground:SetHeight(height-2)
			GVAR.TargetButton[i].TargetCountBackground:Show()
			GVAR.TargetButton[i].TargetCount:SetFontObject(fonts[ BattlegroundTargets_Options.ButtonFontSize[currentSize] ].name)
			GVAR.TargetButton[i].TargetCount:SetShadowOffset(0, 0)
			GVAR.TargetButton[i].TargetCount:SetShadowColor(0, 0, 0, 0)
			GVAR.TargetButton[i].TargetCount:SetHeight(fontHeight)
			GVAR.TargetButton[i].TargetCount:SetTextColor(1, 1, 1, 1)
			GVAR.TargetButton[i].TargetCount:SetText("0")
			GVAR.TargetButton[i].TargetCount:Show()
		else
			GVAR.TargetButton[i].TargetCountBackground:Hide()
			GVAR.TargetButton[i].TargetCount:Hide()
		end

		if BattlegroundTargets_Options.ButtonShowCrosshairs[currentSize] then
			if BattlegroundTargets_Options.ButtonShowTargetCount[currentSize] then
				GVAR.TargetButton[i].TargetTexture:SetPoint("RIGHT", GVAR.TargetButton[i].TargetCountBackground, "LEFT", 0, 0)
			else
				GVAR.TargetButton[i].TargetTexture:SetPoint("RIGHT", GVAR.TargetButton[i].ClassColorBackground, "RIGHT", 0, 0)
			end
			GVAR.TargetButton[i].TargetTexture:SetWidth(height-2)
			GVAR.TargetButton[i].TargetTexture:SetHeight(height-2)
			GVAR.TargetButton[i].TargetTexture:Show()
		else
			GVAR.TargetButton[i].TargetTexture:Hide()
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
	if BattlegroundTargets_Options.pos and BattlegroundTargets_Options.pos[frameName.."_posX"] then
		_G[frameName]:ClearAllPoints()
		_G[frameName]:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", BattlegroundTargets_Options.pos[frameName.."_posX"], BattlegroundTargets_Options.pos[frameName.."_posY"])
	else
		if frameName == "BattlegroundTargets_MainFrame" then
			_G[frameName]:ClearAllPoints()
			_G[frameName]:SetPoint("TOPRIGHT", GVAR.OptionsFrame, "TOPLEFT", -40, 20)
		elseif frameName == "BattlegroundTargets_OptionsFrame" then
			_G[frameName]:ClearAllPoints()
			_G[frameName]:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
		end
	end
end

function BattlegroundTargets:Frame_SavePosition(frameName)
	if not BattlegroundTargets_Options.pos then BattlegroundTargets_Options.pos = {} end

	BattlegroundTargets_Options.pos[frameName.."_posX"] = _G[frameName]:GetLeft()
	BattlegroundTargets_Options.pos[frameName.."_posY"] = _G[frameName]:GetTop()

	_G[frameName]:ClearAllPoints()
	_G[frameName]:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", BattlegroundTargets_Options.pos[frameName.."_posX"], BattlegroundTargets_Options.pos[frameName.."_posY"])
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:MainFrameShow()
	if inCombat or InCombatLockdown() then
		--Print("InCombatLockdown! MainFrame Show Configuration is disabled in combat.")
		return
	end
	BattlegroundTargets:Frame_SetupPosition("BattlegroundTargets_MainFrame")
	GVAR.MainFrame:StartMoving()
	GVAR.MainFrame:StopMovingOrSizing()
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:OptionsFrameHide()
	PlaySound("igQuestListClose")
	isConfig = false
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
	if inCombat or InCombatLockdown() then
		BattlegroundTargets:DisableInsecureConfigWidges()
	else
		BattlegroundTargets:EnableInsecureConfigWidges()
	end

	if inBattleground then
		testSize = currentSize
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
		--Print("InCombatLockdown! Configuration is disabled in combat.")
		return
	end

	table_wipe(ENEMY_Data)

	-- Test Data START
	ENEMY_Data[1] = {}
	ENEMY_Data[1].name = "Aatest-Alterac Mountains"
	ENEMY_Data[1].classToken = "DRUID"
	ENEMY_Data[1].talentSpec = T.DRUID[3]
	ENEMY_Data[2] = {}
	ENEMY_Data[2].name = "Bbtest-Ragnaros"
	ENEMY_Data[2].classToken = "PRIEST"
	ENEMY_Data[2].talentSpec = T.PRIEST[3]
	ENEMY_Data[3] = {}
	ENEMY_Data[3].name = "Cctest-Blackrock"
	ENEMY_Data[3].classToken = "WARLOCK"
	ENEMY_Data[3].talentSpec = T.WARLOCK[1]
	ENEMY_Data[4] = {}
	ENEMY_Data[4].name = "Ddtest-Wildhammer"
	ENEMY_Data[4].classToken = "HUNTER"
	ENEMY_Data[4].talentSpec = T.HUNTER[3]
	ENEMY_Data[5] = {}
	ENEMY_Data[5].name = "Eetest-Khaz'goroth"
	ENEMY_Data[5].classToken = "WARRIOR"
	ENEMY_Data[5].talentSpec = T.WARRIOR[3]
	ENEMY_Data[6] = {}
	ENEMY_Data[6].name = "Fftest-Xavius"
	ENEMY_Data[6].classToken = "ROGUE"
	ENEMY_Data[6].talentSpec = T.ROGUE[2]
	ENEMY_Data[7] = {}
	ENEMY_Data[7].name = "Ggtest-Area 52"
	ENEMY_Data[7].classToken = "SHAMAN"
	ENEMY_Data[7].talentSpec = T.SHAMAN[3]
	ENEMY_Data[8] = {}
	ENEMY_Data[8].name = "Hhtest-Blackmoore"
	ENEMY_Data[8].classToken = "PALADIN"
	ENEMY_Data[8].talentSpec = T.PALADIN[3]
	ENEMY_Data[9] = {}
	ENEMY_Data[9].name = "Iitest-Scarshield Legion"
	ENEMY_Data[9].classToken = "MAGE"
	ENEMY_Data[9].talentSpec = T.MAGE[3]
	ENEMY_Data[10] = {}
	ENEMY_Data[10].name = "Jjtest-Conseil des Ombres"
	ENEMY_Data[10].classToken = "DEATHKNIGHT"
	ENEMY_Data[10].talentSpec = T.DEATHKNIGHT[2]
	ENEMY_Data[11] = {}
	ENEMY_Data[11].name = "Kktest-Archimonde"
	ENEMY_Data[11].classToken = "DRUID"
	ENEMY_Data[11].talentSpec = T.DRUID[1]
	ENEMY_Data[12] = {}
	ENEMY_Data[12].name = "Lltest-Nefarian"
	ENEMY_Data[12].classToken = "DEATHKNIGHT"
	ENEMY_Data[12].talentSpec = T.DEATHKNIGHT[3]
	ENEMY_Data[13] = {}
	ENEMY_Data[13].name = "Mmtest-Trollbane"
	ENEMY_Data[13].classToken = "PALADIN"
	ENEMY_Data[13].talentSpec = T.PALADIN[3]
	ENEMY_Data[14] = {}
	ENEMY_Data[14].name = "Nntest-Un'Goro"
	ENEMY_Data[14].classToken = "MAGE"
	ENEMY_Data[14].talentSpec = T.MAGE[1]
	ENEMY_Data[15] = {}
	ENEMY_Data[15].name = "Ootest-Teldrassil"
	ENEMY_Data[15].classToken = "SHAMAN"
	ENEMY_Data[15].talentSpec = T.SHAMAN[2]
	ENEMY_Data[16] = {}
	ENEMY_Data[16].name = "Pptest-Rexxar"
	ENEMY_Data[16].classToken = "ROGUE"
	ENEMY_Data[16].talentSpec = T.ROGUE[1]
	ENEMY_Data[17] = {}
	ENEMY_Data[17].name = "Qqtest-Gilneas"
	ENEMY_Data[17].classToken = "WARLOCK"
	ENEMY_Data[17].talentSpec = T.WARLOCK[2]
	ENEMY_Data[18] = {}
	ENEMY_Data[18].name = "Rrtest-Terokkar"
	ENEMY_Data[18].classToken = "PRIEST"
	ENEMY_Data[18].talentSpec = T.PRIEST[3]
	ENEMY_Data[19] = {}
	ENEMY_Data[19].name = "Sstest-Zuluhed"
	ENEMY_Data[19].classToken = "WARRIOR"
	ENEMY_Data[19].talentSpec = T.WARRIOR[1]
	ENEMY_Data[20] = {}
	ENEMY_Data[20].name = "Tttest-Archimonde"
	ENEMY_Data[20].classToken = "DRUID"
	ENEMY_Data[20].talentSpec = T.DRUID[2]
	ENEMY_Data[21] = {}
	ENEMY_Data[21].name = "Uutest-Anub'arak"
	ENEMY_Data[21].classToken = "PRIEST"
	ENEMY_Data[21].talentSpec = T.PRIEST[3]
	ENEMY_Data[22] = {}
	ENEMY_Data[22].name = "Vvtest-Kul Tiras"
	ENEMY_Data[22].classToken = "WARRIOR"
	ENEMY_Data[22].talentSpec = T.WARRIOR[1]
	ENEMY_Data[23] = {}
	ENEMY_Data[23].name = "Wwtest-Garrosh"
	ENEMY_Data[23].classToken = "SHAMAN"
	ENEMY_Data[23].talentSpec = T.SHAMAN[1]
	ENEMY_Data[24] = {}
	ENEMY_Data[24].name = "Xxtest-Durotan"
	ENEMY_Data[24].classToken = "HUNTER"
	ENEMY_Data[24].talentSpec = T.HUNTER[2]
	ENEMY_Data[25] = {}
	ENEMY_Data[25].name = "Yytest-Thrall"
	ENEMY_Data[25].classToken = "SHAMAN"
	ENEMY_Data[25].talentSpec = T.SHAMAN[2]
	ENEMY_Data[26] = {}
	ENEMY_Data[26].name = "Zztest-Frostmourne"
	ENEMY_Data[26].classToken = "WARLOCK"
	ENEMY_Data[26].talentSpec = T.WARLOCK[3]
	ENEMY_Data[27] = {}
	ENEMY_Data[27].name = "Abtest-Stormrage"
	ENEMY_Data[27].classToken = "PRIEST"
	ENEMY_Data[27].talentSpec = T.PRIEST[2]
	ENEMY_Data[28] = {}
	ENEMY_Data[28].name = "Bctest-Les Sentinelles"
	ENEMY_Data[28].classToken = "MAGE"
	ENEMY_Data[28].talentSpec = T.MAGE[2]
	ENEMY_Data[29] = {}
	ENEMY_Data[29].name = "Cdtest-Arthas"
	ENEMY_Data[29].classToken = "ROGUE"
	ENEMY_Data[29].talentSpec = T.ROGUE[3]
	ENEMY_Data[30] = {}
	ENEMY_Data[30].name = "Detest-Bronzebeard"
	ENEMY_Data[30].classToken = "DRUID"
	ENEMY_Data[30].talentSpec = T.DRUID[1]
	ENEMY_Data[31] = {}
	ENEMY_Data[31].name = "Eftest-Forscherliga"
	ENEMY_Data[31].classToken = "HUNTER"
	ENEMY_Data[31].talentSpec = T.HUNTER[3]
	ENEMY_Data[32] = {}
	ENEMY_Data[32].name = "Fgtest-Deephome"
	ENEMY_Data[32].classToken = "WARRIOR"
	ENEMY_Data[32].talentSpec = T.WARRIOR[2]
	ENEMY_Data[33] = {}
	ENEMY_Data[33].name = "Ghtest-Arthas"
	ENEMY_Data[33].classToken = "PALADIN"
	ENEMY_Data[33].talentSpec = T.PALADIN[1]
	ENEMY_Data[34] = {}
	ENEMY_Data[34].name = "Hitest-Blade's Edge"
	ENEMY_Data[34].classToken = "MAGE"
	ENEMY_Data[34].talentSpec = T.MAGE[3]
	ENEMY_Data[35] = {}
	ENEMY_Data[35].name = "Ijtest-Talnivarr"
	ENEMY_Data[35].classToken = "DEATHKNIGHT"
	ENEMY_Data[35].talentSpec =  T.DEATHKNIGHT[3]
	ENEMY_Data[36] = {}
	ENEMY_Data[36].name = "Jktest-Steamwheedle Cartel"
	ENEMY_Data[36].classToken = "MAGE"
	ENEMY_Data[36].talentSpec = T.MAGE[2]
	ENEMY_Data[37] = {}
	ENEMY_Data[37].name = "Kltest-Naxxramas"
	ENEMY_Data[37].classToken = "HUNTER"
	ENEMY_Data[37].talentSpec = T.HUNTER[2]
	ENEMY_Data[38] = {}
	ENEMY_Data[38].name = "Lmtest-Archimonde"
	ENEMY_Data[38].classToken = "WARLOCK"
	ENEMY_Data[38].talentSpec = T.WARLOCK[1]
	ENEMY_Data[39] = {}
	ENEMY_Data[39].name = "Mntest-Nazjatar"
	ENEMY_Data[39].classToken = "WARLOCK"
	ENEMY_Data[39].talentSpec = T.WARLOCK[2]
	ENEMY_Data[40] = {}
	ENEMY_Data[40].name = "Notest-Drak'thul"
	ENEMY_Data[40].classToken = "ROGUE"
	ENEMY_Data[40].talentSpec = T.ROGUE[2]
	-- Test Data END

	for i = 1, 40 do
		local role = 4
		if ENEMY_Data[i].talentSpec and ENEMY_Data[i].classToken and T[ ENEMY_Data[i].classToken ] then
			if ENEMY_Data[i].talentSpec == T[ ENEMY_Data[i].classToken ][1] then
				role = classes[ ENEMY_Data[i].classToken ].roleNum[1]
			elseif ENEMY_Data[i].talentSpec == T[ ENEMY_Data[i].classToken ][2] then
				role = classes[ ENEMY_Data[i].classToken ].roleNum[2]
			elseif ENEMY_Data[i].talentSpec == T[ ENEMY_Data[i].classToken ][3] then
				role = classes[ ENEMY_Data[i].classToken ].roleNum[3]
			end
		end
		ENEMY_Data[i].talentSpec = role
	end

	currentSize = testSize
	BattlegroundTargets:SetOptions()
	
	GVAR.MainFrame:Show()
	GVAR.MainFrame:EnableMouse(true)
	GVAR.MainFrame:SetHeight(20)
	GVAR.MainFrame.Movetext:Show()
	GVAR.TargetButton[1]:SetPoint("TOPLEFT", GVAR.MainFrame, "BOTTOMLEFT", 0, 0)

	for i = 1, 40 do
		if i < currentSize+1 then
			GVAR.TargetButton[i]:Show()
		else
			GVAR.TargetButton[i]:Hide()
		end
	end

	for i = 1, currentSize do
		GVAR.TargetButton[i].TargetTexture:SetAlpha(0)
		GVAR.TargetButton[i].TargetCount:SetText("0")
	end
	GVAR.TargetButton[2].TargetTexture:SetAlpha(1)

	BattlegroundTargets:UpdateLayout()
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
function BattlegroundTargets:DisableConfigMode()
	if inCombat or InCombatLockdown() then
		reCheckBG = true
		reSetLayout = true
		--Print("InCombatLockdown! Configuration is disabled in combat.")
		return
	end

	currentSize = testSize
	BattlegroundTargets:SetOptions()

	BattlegroundTargets:Frame_Toggle(GVAR.MainFrame)
	for i = 1, 40 do
		GVAR.TargetButton[i]:Hide()
		GVAR.TargetButton[i].TargetTexture:SetAlpha(0)
		GVAR.TargetButton[i].TargetCount:SetText("0")
	end
	BattlegroundTargets:BattlefieldCheck()
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

	for i = 1, currentSize do
		if ENEMY_Data[i] then
			GVAR.TargetButton[i].ClassColorBackground:SetTexture(classcolors[ ENEMY_Data[i].classToken ].r, classcolors[ ENEMY_Data[i].classToken ].g, classcolors[ ENEMY_Data[i].classToken ].b, 1)
			
			if BattlegroundTargets_Options.ButtonClassIcon[currentSize] then
				GVAR.TargetButton[i].ClassTexture:SetTexCoord(classes[ ENEMY_Data[i].classToken ].icon[1], classes[ ENEMY_Data[i].classToken ].icon[2], classes[ ENEMY_Data[i].classToken ].icon[3], classes[ ENEMY_Data[i].classToken ].icon[4])
			end

			GVAR.TargetButton[i].SpecTexture:SetTexCoord(roles[ENEMY_Data[i].talentSpec][1], roles[ENEMY_Data[i].talentSpec][2], roles[ENEMY_Data[i].talentSpec][3], roles[ENEMY_Data[i].talentSpec][4])
			local name = ENEMY_Data[i].name
			if not BattlegroundTargets_Options.ButtonShowRealm[currentSize] then
				if string_find(name, "-", 1, true) then
					name = string_match(name, "(.-)%-(.*)$")
				end
			end
			GVAR.TargetButton[i].Name:SetText(name)
			if not inCombat or not InCombatLockdown() then
				GVAR.TargetButton[i]:SetAttribute("macrotext", string_format("/target %s", ENEMY_Data[i].name))
			end
		else
			GVAR.TargetButton[i].ClassColorBackground:SetTexture(0.5, 0.5, 0.5, 0.5)
			GVAR.TargetButton[i].ClassTexture:SetTexCoord(0, 0, 0, 0)
			GVAR.TargetButton[i].SpecTexture:SetTexCoord(0, 0, 0, 0)
			GVAR.TargetButton[i].Name:SetText("")
			if not inCombat or not InCombatLockdown() then
				GVAR.TargetButton[i]:SetAttribute("macrotext", "")
			end
		end
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------------------------
local function BattlefieldUpdateTargets(forceUpdate)
	if not inWorld then return end
	if not inBattleground then return end
	-- function WorldStateScoreFrameTab_OnClick (WorldStateFrame.lua)
	-- function PanelTemplates_SetTab (UIPanelTemplates.lua)
	-- WorldStateScoreFrame.selectedTab can have:
	-- WorldStateScoreFrame.selectedTab = 1 (ALL)               -- Button name="WorldStateScoreFrameTab1" (WorldStateFrame.xml)
	-- WorldStateScoreFrame.selectedTab = 2 (FACTION_ALLIANCE)  -- Button name="WorldStateScoreFrameTab2" (WorldStateFrame.xml)
	-- WorldStateScoreFrame.selectedTab = 3 (FACTION_HORDE)     -- Button name="WorldStateScoreFrameTab3" (WorldStateFrame.xml)
	if WorldStateScoreFrame:IsShown() and WorldStateScoreFrame.selectedTab and WorldStateScoreFrame.selectedTab > 1 then return end

	if not forceUpdate then
		local curTime = GetTime()
		if scoreUpdateThrottle + scoreUpdateFrequency > curTime then return end
		scoreUpdateThrottle = curTime
	end

	SetBattlefieldScoreFaction()
	
	table_wipe(ENEMY_Data)
	table_wipe(FRIEND_Names)

	local x = 1
	--local cleared
	local numScores = GetNumBattlefieldScores()
	for index = 1, numScores do
		--  name, killingBlows, honorableKills, deaths, honorGained, faction, race, class, classToken, damageDone, healingDone, bgRating, ratingChange, preMatchMMR, mmrChange, talentSpec
		local name, _, _, _, _, faction, _, _, classToken, _, _, _, _, _, _, talentSpec = GetBattlefieldScore(index)
		--print(numScores, index, name, faction, classToken, talentSpec)
		if name then
			if faction == oppositeFaction then

				-- workaround to avoid empty enemy table     ---> SetBattlefieldScoreFaction() should fix this. really?
				-- clear table only if at least one opposite player was found
				--if not cleared then
				--		table_wipe(ENEMY_Data)
				--		cleared = true
				--	end

				local role = 4
				local class = "ZZZFAILURE"
				if classToken then
					class = classToken
					if talentSpec then
						if T[classToken] then
							if talentSpec == T[classToken][1] then
								role = classes[classToken].roleNum[1]
							elseif talentSpec == T[classToken][2] then
								role = classes[classToken].roleNum[2]
							elseif talentSpec == T[classToken][3] then
								role = classes[classToken].roleNum[3]
							end
						end
					end
				end

				ENEMY_Data[x] = {}
				ENEMY_Data[x].name = name
				ENEMY_Data[x].classToken = class
				ENEMY_Data[x].talentSpec = role
				x = x + 1

				if not ENEMY_Names[name] then
					ENEMY_Names[name] = 0
				end

			elseif faction == playerFaction then

				FRIEND_Names[name] = 0

			end
		end
	end

	BattlegroundTargets:UpdateLayout()
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
		else
			local queueStatus, queueMapName, bgName
			for i=1, MAX_BATTLEFIELD_QUEUES do
				queueStatus, queueMapName = GetBattlefieldStatus(i)
				--print("GetBattlefieldStatus:", queueStatus, queueMapName)--TEST
				if queueStatus == "active" then
					bgName = queueMapName
					break
				end
			end

			if bgName and BGN[bgName] then
				currentSize = bgSize[ BGN[bgName] ]
				reSizeCheck = 3
			else
				local zone = GetRealZoneText() -- try this once
				--print("GetRealZoneText:", zone)--TEST
				if zone and BGN[zone] then
					currentSize = bgSize[ BGN[zone] ]
					reSizeCheck = 3
				else
					if reSizeCheck == 0 then
						Print("Unknown battleground name:", bgName)
						Print("Another check is done after the next 'out of combat' phase.")
						Print("Set to '10 vs 10' layout.")
					elseif reSizeCheck == 2 then
						Print(bgName, "is not localized! Please contact author. Thanks.")
					end
					currentSize = 10
					reSizeCheck = reSizeCheck + 1
				end
			end
		end

		if inCombat or InCombatLockdown() then
			reCheckBG = true
			--Print("InCombatLockdown! Buttons are shown when you leave combat.")
		else
			reCheckBG = false
			
			if BattlegroundTargets_Options.ButtonEnableBracket[currentSize] then
			
				GVAR.MainFrame:Show()
				GVAR.MainFrame:EnableMouse(false)
				GVAR.MainFrame:SetHeight(0.001)
				GVAR.MainFrame.Movetext:Hide()
				GVAR.TargetButton[1]:SetPoint("TOPLEFT", GVAR.MainFrame, "BOTTOMLEFT", 0, -20)
			
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
			if BattlegroundTargets_Options.ButtonShowTargetCount[currentSize] then
				BattlegroundTargets:RegisterEvent("UNIT_TARGET")
			end
			if BattlegroundTargets_Options.ButtonShowCrosshairs[currentSize] then
				BattlegroundTargets:RegisterEvent("PLAYER_TARGET_CHANGED")
			end
			BattlegroundTargets:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
		end
	else
		inBattleground = false
		reSizeCheck = 0

		BattlegroundTargets:UnregisterEvent("UNIT_TARGET")
		BattlegroundTargets:UnregisterEvent("PLAYER_TARGET_CHANGED")
		BattlegroundTargets:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE")

		table_wipe(ENEMY_Data)
		table_wipe(FRIEND_Names)
		table_wipe(ENEMY_Names)
		table_wipe(TARGET_Names)

		if inCombat or InCombatLockdown() then
			reCheckBG = true
			--Print("InCombatLockdown! Buttons are hidden when you leave combat.")
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

function BattlegroundTargets:CheckForEnabledBracket(bracketSize)
	if BattlegroundTargets_Options.ButtonEnableBracket[bracketSize] then
		if bracketSize == 10 then
			GVAR.OptionsFrame.TestRaidSize10.Text:SetTextColor(0, 0.75, 0, 1)
		elseif bracketSize == 15 then
			GVAR.OptionsFrame.TestRaidSize15.Text:SetTextColor(0, 0.75, 0, 1)
		elseif bracketSize == 40 then
			GVAR.OptionsFrame.TestRaidSize40.Text:SetTextColor(0, 0.75, 0, 1)
		end

		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ClassIcon)
		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowRealm)
		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowCrosshairs)
		TEMPLATE.EnableCheckButton(GVAR.OptionsFrame.ShowTargetCount)
		TEMPLATE.EnablePullDownMenu(GVAR.OptionsFrame.SortByTitlePullDown)
		GVAR.OptionsFrame.SortByTitle:SetTextColor(1, 1, 1, 1)
		TEMPLATE.EnablePullDownMenu(GVAR.OptionsFrame.FontPullDown)
		GVAR.OptionsFrame.FontTitle:SetTextColor(1, 1, 1, 1)
		TEMPLATE.EnableSlider(GVAR.OptionsFrame.ScaleSlider)
		GVAR.OptionsFrame.Scale:SetTextColor(1, 1, 1, 1)
		TEMPLATE.EnableSlider(GVAR.OptionsFrame.WidthSlider)
		GVAR.OptionsFrame.Width:SetTextColor(1, 1, 1, 1)
		TEMPLATE.EnableSlider(GVAR.OptionsFrame.HeightSlider)
		GVAR.OptionsFrame.Height:SetTextColor(1, 1, 1, 1)
	else
		if bracketSize == 10 then
			GVAR.OptionsFrame.TestRaidSize10.Text:SetTextColor(1, 0, 0, 1)
		elseif bracketSize == 15 then
			GVAR.OptionsFrame.TestRaidSize15.Text:SetTextColor(1, 0, 0, 1)
		elseif bracketSize == 40 then
			GVAR.OptionsFrame.TestRaidSize40.Text:SetTextColor(1, 0, 0, 1)
		end

		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ClassIcon)
		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowRealm)
		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowCrosshairs)
		TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowTargetCount)
		TEMPLATE.DisablePullDownMenu(GVAR.OptionsFrame.SortByTitlePullDown)
		GVAR.OptionsFrame.SortByTitle:SetTextColor(0.5, 0.5, 0.5, 1)
		TEMPLATE.DisablePullDownMenu(GVAR.OptionsFrame.FontPullDown)
		GVAR.OptionsFrame.FontTitle:SetTextColor(0.5, 0.5, 0.5, 1)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.ScaleSlider)
		GVAR.OptionsFrame.Scale:SetTextColor(0.5, 0.5, 0.5, 1)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.WidthSlider)
		GVAR.OptionsFrame.Width:SetTextColor(0.5, 0.5, 0.5, 1)
		TEMPLATE.DisableSlider(GVAR.OptionsFrame.HeightSlider)
		GVAR.OptionsFrame.Height:SetTextColor(0.5, 0.5, 0.5, 1)
	end
end

function BattlegroundTargets:DisableInsecureConfigWidges()
	GVAR.OptionsFrame.TitleWarning:SetText(L["In combat: Configuration locked!"])
	GVAR.OptionsFrame.TitleWarning:SetTextColor(0.8, 0.2, 0.2, 1)
	
	TEMPLATE.DisableTabButton(GVAR.OptionsFrame.TestRaidSize10)
	TEMPLATE.DisableTabButton(GVAR.OptionsFrame.TestRaidSize15)
	TEMPLATE.DisableTabButton(GVAR.OptionsFrame.TestRaidSize40)

	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.EnableBracket)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ClassIcon)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowRealm)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowCrosshairs)
	TEMPLATE.DisableCheckButton(GVAR.OptionsFrame.ShowTargetCount)
	TEMPLATE.DisablePullDownMenu(GVAR.OptionsFrame.SortByTitlePullDown)
	GVAR.OptionsFrame.SortByTitle:SetTextColor(0.5, 0.5, 0.5, 1)
	TEMPLATE.DisablePullDownMenu(GVAR.OptionsFrame.FontPullDown)
	GVAR.OptionsFrame.FontTitle:SetTextColor(0.5, 0.5, 0.5, 1)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.ScaleSlider)
	GVAR.OptionsFrame.Scale:SetTextColor(0.5, 0.5, 0.5, 1)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.WidthSlider)
	GVAR.OptionsFrame.Width:SetTextColor(0.5, 0.5, 0.5, 1)
	TEMPLATE.DisableSlider(GVAR.OptionsFrame.HeightSlider)
	GVAR.OptionsFrame.Height:SetTextColor(0.5, 0.5, 0.5, 1)
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
local function OnEvent(self, event, arg1)
	if event == "PLAYER_REGEN_DISABLED" then
		inCombat = true
		if isConfig then
			BattlegroundTargets:DisableInsecureConfigWidges()
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		inCombat = false
		BattlegroundTargets:EnableInsecureConfigWidges()
		if reCheckBG or reSizeCheck < 3 then
			BattlegroundTargets:BattlefieldCheck()
			reSizeCheck = 0
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
		if isConfig then return end
		if not BattlegroundTargets_Options.ButtonShowTargetCount[currentSize] then return end
		if not inWorld then return end
		if not inBattleground then return end

		local friendName, friendRealm
		local enemyName, enemyRealm

		if arg1 == "player" then
			friendName = UnitName("player")
			enemyName, enemyRealm = UnitName("target")
			if enemyRealm and enemyRealm ~= "" then
				enemyName = enemyName.."-"..enemyRealm
			end
		else
			friendName, friendRealm = UnitName(arg1)
			if friendRealm and friendRealm ~= "" then
				friendName = friendName.."-"..friendRealm
			end
			enemyName, enemyRealm = UnitName(arg1.."target")
			if enemyRealm and enemyRealm ~= "" then
				enemyName = enemyName.."-"..enemyRealm
			end
		end

		if friendName then
			if enemyName then
				TARGET_Names[friendName] = enemyName
			else
				TARGET_Names[friendName] = nil
			end
		end

		for enemyName in pairs(ENEMY_Names) do
			ENEMY_Names[enemyName] = 0
		end

		for _, enemyName in pairs(TARGET_Names) do
			if ENEMY_Names[enemyName] then
				ENEMY_Names[enemyName] = ENEMY_Names[enemyName] + 1
			end
		end

		for i = 1, currentSize do
			if ENEMY_Data[i] then
				if ENEMY_Names[ ENEMY_Data[i].name ] then
					GVAR.TargetButton[i].TargetCount:SetText( ENEMY_Names[ ENEMY_Data[i].name ] )
				end
			end
		end

	elseif event == "PLAYER_TARGET_CHANGED" then
		if isConfig then return end
		if not BattlegroundTargets_Options.ButtonShowCrosshairs[currentSize] then return end
		if not inWorld then return end
		if not inBattleground then return end

		local name, realm = UnitName("target")
		if realm and realm ~= "" then
			name = name.."-"..realm
		end
		
		if name then
			for i = 1, currentSize do
				if ENEMY_Data[i] then
					if ENEMY_Data[i].name == name then
						GVAR.TargetButton[i].TargetTexture:SetAlpha(1)
					else
						GVAR.TargetButton[i].TargetTexture:SetAlpha(0)
					end
				end
			end
		else
			for i = 1, currentSize do
				GVAR.TargetButton[i].TargetTexture:SetAlpha(0)
			end
		end

	elseif event == "PLAYER_LOGIN" then
		playerFaction = UnitFactionGroup("player")
		oppositeFaction = 0 -- "Horde"
		if playerFaction == "Horde" then
			oppositeFaction = 1 -- "Alliance"
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