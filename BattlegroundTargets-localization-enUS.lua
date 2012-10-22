-- -------------------------------------------------------------------------- --
-- BattlegroundTargets DEFAULT (english) Localization                         --
-- Please make sure to save this file as UTF-8. ¶                             --
-- -------------------------------------------------------------------------- --

BattlegroundTargets_Localization = {
["Open Configuration"] = true,

["Configuration"] = true,
["10 vs 10"] = true,
["15 vs 15"] = true,
["40 vs 40"] = true,
["Enable"] = true,
["Independent Positioning"] = true,
["Layout"] = true,
["Summary"] = true,
["Copy this settings to '%s'"] = true,
["Show Role"] = true,
["Show Specialization"] = true,
["Show Class Icon"] = true,
["Hide Realm"] = true,
["Show Leader"] = true,
["Show Guild Groups"] = true,
["Show Target"] = true,
["Show Focus"] = true,
["Show Flag Carrier"] = true,
["Show Main Assist Target"] = true,
["Show Target Count"] = true,
["Show Health Bar"] = true,
["Show Percent"] = true,
["Show Range"] = true,
 ["This option uses the CombatLog to check range."] = true,
 ["This option uses a pre-defined spell to check range:"] = true,
 ["Mix"] = true,
 ["if you are attacked only"] = true,
 ["(class dependent)"] = true,
 ["Disable this option if you have CPU/FPS problems in combat."] = true,
["Sort By"] = true,
["Font"] = true,
["Text Size"] = true,
["Scale"] = true,
["Width"] = true,
["Height"] = true,

["General Settings"] = true,
["Show Minimap-Button"] = true,

["click & move"] = true,
["BattlegroundTargets does not update if this Tab is opened."] = true,

["Close Configuration"] = true,

-- font test for all languages, do not translate
["TEST_abc_"] = "abc_ABCXYZabcxyz_",
["TEST_Latin1_"] = "Latin1_¡ÆâÜíßñØéùåçÏ_ŒŸ_",
["TEST_Latin2_"] = "Latin2_ĄŁĽŤžŕęďňýţ_",
["TEST_Latin3_"] = "Latin3_ĥĦ˘ËĵŜĊŭŝ_",
["TEST_Latin4_"] = "Latin4_įĸæĨĻĀōÂųũūŊĪ_",
["TEST_Latin5_"] = "Latin5_ĞİŞğışÿö_",
["TEST_koKR_"] = "koKR_발수요있눈봉우렬드_",
["TEST_ruRU_"] = "ruRU_бПдчжмШЭйФ_",
["TEST_zhCN_"] = "zhCN_夺兰古手变命使用_",
["TEST_zhTW_"] = "zhTW_對大顯以記已_",
}

function BattlegroundTargets_Localization:CreateLocaleTable(t)
	for k,v in pairs(t) do
		self[k] = (v == true and k) or v
	end
end

BattlegroundTargets_Localization:CreateLocaleTable(BattlegroundTargets_Localization)