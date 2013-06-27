-- -------------------------------------------------------------------------- --
-- BattlegroundTargets zhTW Localization                                      --
-- Please make sure to save this file as UTF-8. ¶                             --
-- -------------------------------------------------------------------------- --
if GetLocale() ~= "zhTW" then return end
local L, _, prg = {}, ...
if prg.L then L = prg.L else prg.L = L end

L["Open Configuration"] = "打開設置面板"
L["Close Configuration"] = "關閉設置"

L["Configuration"] = "設置"
L["10 vs 10"] = "10對10"
L["15 vs 15"] = "15對15"
L["40 vs 40"] = "40對40"
L["Independent Positioning"] = "獨立定位"
L["Layout"] = "佈局"
L["Summary"] = "摘要"
L["Copy this settings to %s"] = "複製此設定到 %s"
L["Class Icon"] = "職業圖標" -- need check - old: ["Show Class Icon"] = "顯示職業圖標",
L["Realm"] = "伺服器" -- need check - old: ["Hide Realm"] = "隱藏伺服器",
L["Leader"] = "領袖" -- need check - old: ["Show Leader"] = "顯示領袖",
L["Flag"] = true
L["Main Assist Target"] = "主助理目標" -- need check - old: ["Show Main Assist Target"] = "顯示主助理目標",
L["Target Count"] = "目標計數" -- need check - old: ["Show Target Count"] = "顯示目標計數",
L["Health Bar"] = "生命條" -- need check - old: ["Show Health Bar"] = "顯示生命條",
L["Percent"] = "百分比" -- need check - old: ["Show Percent"] = "顯示百分比",
L["Range"] = "距離" -- need check
 L["This option uses the CombatLog to check range."] = "此選項使用戰鬥記錄檢查範圍。"
 L["This option uses a pre-defined spell to check range:"] = "此選項使用預定法術範圍檢查："
 L["Mix"] = "混合"
 L["if you are attacked only"] = "僅自身被攻擊"
 L["(class dependent)"] = "（以職業）"
 L["Disable this option if you have CPU/FPS problems in combat."] = "當你 CPU/幀數在戰鬥中出現問題時禁用此選項。"
L["Sort By"] = "排序"
L["Text"] = "文字" -- need check
L["Number"] = "編號" -- need check
L["Scale"] = "縮放"
L["Width"] = "寬度"
L["Height"] = "高度"

L["Options"] = "選項" -- need check
L["General Settings"] = "總體設定"
L["Show Minimap-Button"] = "顯示小地圖圖示"

L["click & move"] = "點擊移動"
L["BattlegroundTargets does not update if this Tab is opened."] = "如果此框體打開戰場目標將不會更新。"
