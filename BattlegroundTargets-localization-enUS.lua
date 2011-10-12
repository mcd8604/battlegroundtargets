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
["Independent Positioning"] = true,
["Copy this settings to '%s'"] = true,
["Show Specialization"] = true,
["Show Class Icon"] = true,
["Hide Realm"] = true,
["Show Leader"] = true,
["Show Target"] = true,
["Show Focus"] = true,
["Show Flag Carrier"] = true,
["Show Main Assist Target"] = true,
["Show Target Count"] = true,
["Show Health Bar"] = true,
["Show Percent"] = true,
["Show Range"] = true,
 ["This option uses CombatLog scanning."] = true,
 ["This option uses a pre-defined spell to check range:"] = true,
 ["Disable this option if you have CPU/FPS problems in combat."] = true,
["Sort By"] = true,
["Text Size"] = true,
["Scale"] = true,
["Width"] = true,
["Height"] = true,

["General Settings"] = true,
["Show Minimap-Button"] = true,

["click & move"] = true,
["BattlegroundTargets does not update if this Tab is opened."] = true,

["Close Configuration"] = true,

["is not localized! Please contact addon author. Thanks."] = true,
}

function BattlegroundTargets_Localization:CreateLocaleTable(t)
	for k,v in pairs(t) do
		self[k] = (v == true and k) or v
	end
end

BattlegroundTargets_Localization:CreateLocaleTable(BattlegroundTargets_Localization)