-- -------------------------------------------------------------------------- --
-- BattlegroundTargets DEFAULT (english) Localization                         --
-- Please make sure to save this file as UTF-8. ¶                             --
-- -------------------------------------------------------------------------- --

BattlegroundTargets_Localization = {
["Open Configuration"] = true,

["Configuration"] = true,
["Out of combat: Configuration enabled."] = true,
["In combat: Configuration locked!"] = true,
["10 vs 10"] = true,
["15 vs 15"] = true,
["40 vs 40"] = true,
["Enable"] = true,
["Show Class Icon"] = true,
["Show Realm"] = true,
["Show Target Indicator"] = true,
["Show Target Count"] = true,
["Sort By"] = true,
["Text Size"] = true,
["Scale"] = true,
["Width"] = true,
["Height"] = true,

["General Settings"] = true,
["Show Minimap-Button"] = true,

["click & move"] = true,
["BattlegroundTargets does not update if this Tab is opened."] = true,

["'Esc -> Interface -> AddOns -> BattlegroundTargets' to change Options!"] = true,
["Close Configuration (or press 'Esc')"] = true,

["Unknown battleground:"] = true,
["Temporarily used setting: 10 vs 10"] = true,
["is not localized! Please contact addon author. Thanks."] = true,
}

function BattlegroundTargets_Localization:CreateLocaleTable(t)
	for k,v in pairs(t) do
		self[k] = (v == true and k) or v
	end
end

BattlegroundTargets_Localization:CreateLocaleTable(BattlegroundTargets_Localization)