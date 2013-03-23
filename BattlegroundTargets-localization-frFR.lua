-- -------------------------------------------------------------------------- --
-- BattlegroundTargets frFR Localization                                      --
-- Please make sure to save this file as UTF-8. ¶                             --
-- -------------------------------------------------------------------------- --
if GetLocale() ~= "frFR" then return end
local L, _, prg = {}, ...
if prg.L then L = prg.L else prg.L = L end

L["Open Configuration"] = true
L["Close Configuration"] = true

L["Configuration"] = true
L["10 vs 10"] = true
L["15 vs 15"] = true
L["40 vs 40"] = true
L["Independent Positioning"] = true
L["Layout"] = true
L["Summary"] = true
L["Copy this settings to %s"] = true
L["Class Icon"] = true
L["Realm"] = true
L["Leader"] = true
L["Flag + Orb"] = true
L["Main Assist Target"] = true
L["Target Count"] = true
L["Health Bar"] = "Barre de vie" -- need check
L["Percent"] = true
L["Range"] = "Portée" -- need check
 L["This option uses the CombatLog to check range."] = true
 L["This option uses a pre-defined spell to check range:"] = true
 L["Mix"] = true
 L["if you are attacked only"] = true
 L["(class dependent)"] = true
 L["Disable this option if you have CPU/FPS problems in combat."] = true
L["Sort By"] = true
L["Text"] = "Texte" -- need check
L["Number"] = "Nombre" -- need check
L["Scale"] = "Échelle" -- need check
L["Width"] = "Largeur" -- need check
L["Height"] = "Hauteur" -- need check

L["Options"] = "Options" -- need check
L["General Settings"] = true
L["Show Minimap-Button"] = true

L["click & move"] = true
L["BattlegroundTargets does not update if this Tab is opened."] = true
