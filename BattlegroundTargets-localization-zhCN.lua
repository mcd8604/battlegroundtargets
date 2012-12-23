-- -------------------------------------------------------------------------- --
-- BattlegroundTargets zhCN Localization (Thanks ananhaid)                    --
-- Please make sure to save this file as UTF-8. ¶                             --
-- -------------------------------------------------------------------------- --
if GetLocale() ~= "zhCN" then return end
local L, _, prg = {}, ...
if prg.L then L = prg.L else prg.L = L end

L["Open Configuration"] = "打开配置面板"

L["Configuration"] = "配置"
L["10 vs 10"] = "10对10"
L["15 vs 15"] = "15对15"
L["40 vs 40"] = "40对40"
L["Enable"] = ENABLE
L["Independent Positioning"] = "独立定位"
L["Layout"] = "布局"
L["Summary"] = "摘要"
L["Copy this settings to %s"] = "复制此设置到 %s"
L["Role"] = ROLE
L["Specialization"] = SPECIALIZATION
L["Class Icon"] = "职业图标" -- need check - old: ["Show Class Icon"] = "显示职业图标"
L["Realm"] = "服务器" -- need check - old: ["Hide Realm"] = "隐藏服务器"
L["Leader"] = "领袖" -- need check - old: ["Show Leader"] = "显示领袖"
L["Guild Groups"] = "公会组" -- need check - old: ["Show Guild Groups"] = "显示公会组"
L["Target"] = TARGET
L["Focus"] = FOCUS
L["Flag + Orb"] = true
L["Main Assist Target"] = "主助理目标" -- need check - old: ["Show Main Assist Target"] = "显示主助理目标"
L["Target Count"] = "目标计数" -- need check - old: ["Show Target Count"] = "显示目标计数"
L["Health Bar"] = "生命条" -- need check - old: ["Show Health Bar"] = "显示生命条"
L["Percent"] = "百分比" -- need check - old: ["Show Percent"] = "显示百分比"
L["Range"] = "范围" -- need check - old: ["Show Range"] = "显示范围"
 L["This option uses the CombatLog to check range."] = "此选项使用战斗记录检查范围。"
 L["This option uses a pre-defined spell to check range:"] = "此选项使用预定法术范围检查："
 L["Mix"] = "混合"
 L["if you are attacked only"] = "仅自身被攻击"
 L["(class dependent)"] = "（以职业）"
 L["Disable this option if you have CPU/FPS problems in combat."] = "当你 CPU/帧数在战斗中出现问题时禁用此选项。"
L["Sort By"] = "排序"
L["Class"] = CLASS
L["Name"] = NAME
L["Text"] = "文本" -- need check
L["Number"] = "编号" -- need check
L["Scale"] = "缩放"
L["Width"] = "宽度"
L["Height"] = "高度"

L["Options"] = "选项" -- need check
L["General Settings"] = "总体设定"
L["Show Minimap-Button"] = "显示小地图图标"

L["click & move"] = "点击移动"
L["BattlegroundTargets does not update if this Tab is opened."] = "如果此标签打开 BattlegroundTargets 将不会更新。"

L["Close Configuration"] = "关闭配置"