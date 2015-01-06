-- -------------------------------------------------------------------------- --
-- BattlegroundTargets - localized talents                                    --
-- Please make sure to save this file as UTF-8. ¶                             --
-- -------------------------------------------------------------------------- --
-- This file fixes inconsistent Blizzard translations:                        --
-- HEALER: GetSpecializationInfoForClassID(): Sagrado                         --
--         GetBattlefieldScore()            : Sagrada                         --
-- -------------------------------------------------------------------------- --

local TLT, _, prg = {}, ...
prg.TLT = TLT

local locale = GetLocale()

local DAMAGER = 3
local HEALER  = 1
local TANK    = 2

if locale == "esES" then
	TLT.DEATHKNIGHT = {spec={}}
	TLT.DEATHKNIGHT.spec[1] = {role = TANK,    specID = 250, specName = "Sangre", icon = [[Interface\Icons\Spell_Deathknight_BloodPresence]]}
	TLT.DEATHKNIGHT.spec[2] = {role = DAMAGER, specID = 251, specName = "Escarcha", icon = [[Interface\Icons\Spell_Deathknight_FrostPresence]]}
	TLT.DEATHKNIGHT.spec[3] = {role = DAMAGER, specID = 252, specName = "Profano", icon = [[Interface\Icons\Spell_Deathknight_UnholyPresence]]}
	TLT.WARRIOR = {spec={}}
	TLT.WARRIOR.spec[1]     = {role = DAMAGER, specID =  71, specName = "Armas", icon = [[Interface\Icons\Ability_Warrior_SavageBlow]]}
	TLT.WARRIOR.spec[2]     = {role = DAMAGER, specID =  72, specName = "Furia", icon = [[Interface\Icons\Ability_Warrior_InnerRage]]}
	TLT.WARRIOR.spec[3]     = {role = TANK,    specID =  73, specName = "Protección", icon = [[Interface\Icons\Ability_Warrior_DefensiveStance]]}
	TLT.ROGUE = {spec={}}
	TLT.ROGUE.spec[1]       = {role = DAMAGER, specID = 259, specName = "Asesinato", icon = [[Interface\Icons\Ability_Rogue_Eviscerate]]}
	TLT.ROGUE.spec[2]       = {role = DAMAGER, specID = 260, specName = "Combate", icon = [[Interface\Icons\Ability_BackStab]]}
	TLT.ROGUE.spec[3]       = {role = DAMAGER, specID = 261, specName = "Sutileza", icon = [[Interface\Icons\Ability_Stealth]]}
	TLT.MAGE = {spec={}}
	TLT.MAGE.spec[1]        = {role = DAMAGER, specID =  62, specName = "Arcano", icon = [[Interface\Icons\Spell_Holy_MagicalSentry]]}
	TLT.MAGE.spec[2]        = {role = DAMAGER, specID =  63, specName = "Fuego", icon = [[Interface\Icons\Spell_Fire_FireBolt02]]}
	TLT.MAGE.spec[3]        = {role = DAMAGER, specID =  64, specName = "Escarcha", icon = [[Interface\Icons\Spell_Frost_FrostBolt02]]}
	TLT.PRIEST = {spec={}}
	TLT.PRIEST.spec[1]      = {role = HEALER,  specID = 256, specName = "Disciplina", icon = [[Interface\Icons\Spell_Holy_PowerWordShield]]}
	TLT.PRIEST.spec[2]      = {role = HEALER,  specID = 257, specName = "Sagrado", icon = [[Interface\Icons\Spell_Holy_GuardianSpirit]]}
	TLT.PRIEST.spec[3]      = {role = DAMAGER, specID = 258, specName = "Sombra", icon = [[Interface\Icons\Spell_Shadow_ShadowWordPain]]}
	TLT.PRIEST.spec[4]      = {role = HEALER,  specID = 257, specName = "Sagrada", icon = [[Interface\Icons\Spell_Holy_GuardianSpirit]]} -- DEL if it's fixed
	TLT.WARLOCK = {spec={}}
	TLT.WARLOCK.spec[1]     = {role = DAMAGER, specID = 265, specName = "Aflicción", icon = [[Interface\Icons\Spell_Shadow_DeathCoil]]}
	TLT.WARLOCK.spec[2]     = {role = DAMAGER, specID = 266, specName = "Demonología", icon = [[Interface\Icons\Spell_Shadow_Metamorphosis]]}
	TLT.WARLOCK.spec[3]     = {role = DAMAGER, specID = 267, specName = "Destrucción", icon = [[Interface\Icons\Spell_Shadow_RainOfFire]]}
	TLT.HUNTER = {spec={}}
	TLT.HUNTER.spec[1]      = {role = DAMAGER, specID = 253, specName = "Bestias", icon = [[INTERFACE\ICONS\ability_hunter_bestialdiscipline]]}
	TLT.HUNTER.spec[2]      = {role = DAMAGER, specID = 254, specName = "Puntería", icon = [[Interface\Icons\Ability_Hunter_FocusedAim]]}
	TLT.HUNTER.spec[3]      = {role = DAMAGER, specID = 255, specName = "Supervivencia", icon = [[INTERFACE\ICONS\ability_hunter_camouflage]]}
	TLT.DRUID = {spec={}}
	TLT.DRUID.spec[1]       = {role = DAMAGER, specID = 102, specName = "Equilibrio", icon = [[Interface\Icons\Spell_Nature_StarFall]]}
	TLT.DRUID.spec[2]       = {role = DAMAGER, specID = 103, specName = "Feral", icon = [[Interface\Icons\Ability_Druid_CatForm]]}
	TLT.DRUID.spec[3]       = {role = TANK,    specID = 104, specName = "Guardián", icon = [[Interface\Icons\Ability_Racial_BearForm]]}
	TLT.DRUID.spec[4]       = {role = HEALER,  specID = 105, specName = "Restauración", icon = [[Interface\Icons\Spell_Nature_HealingTouch]]}
	TLT.SHAMAN = {spec={}}
	TLT.SHAMAN.spec[1]      = {role = DAMAGER, specID = 262, specName = "Elemental", icon = [[Interface\Icons\Spell_Nature_Lightning]]}
	TLT.SHAMAN.spec[2]      = {role = DAMAGER, specID = 263, specName = "Mejora", icon = [[Interface\Icons\Spell_Shaman_ImprovedStormstrike]]}
	TLT.SHAMAN.spec[3]      = {role = HEALER,  specID = 264, specName = "Restauración", icon = [[Interface\Icons\Spell_Nature_MagicImmunity]]}
	TLT.PALADIN = {spec={}}
	TLT.PALADIN.spec[1]     = {role = HEALER,  specID =  65, specName = "Sagrado", icon = [[Interface\Icons\Spell_Holy_HolyBolt]]}
	TLT.PALADIN.spec[2]     = {role = TANK,    specID =  66, specName = "Protección", icon = [[Interface\Icons\Ability_Paladin_ShieldoftheTemplar]]}
	TLT.PALADIN.spec[3]     = {role = DAMAGER, specID =  70, specName = "Reprensión", icon = [[Interface\Icons\Spell_Holy_AuraOfLight]]}
	TLT.PALADIN.spec[4]     = {role = HEALER,  specID =  65, specName = "Sagrada", icon = [[Interface\Icons\Spell_Holy_HolyBolt]]} -- DEL if it's fixed
	TLT.MONK = {spec={}}
	TLT.MONK.spec[1]        = {role = TANK,    specID = 268, specName = "Maestro", icon = [[Interface\Icons\spell_monk_brewmaster_spec]]}
	TLT.MONK.spec[2]        = {role = DAMAGER, specID = 269, specName = "Viajero del viento", icon = [[Interface\Icons\spell_monk_windwalker_spec]]}
	TLT.MONK.spec[3]        = {role = HEALER,  specID = 270, specName = "Tejedor de niebla", icon = [[Interface\Icons\spell_monk_mistweaver_spec]]}
elseif locale == "esMX" then
	TLT.DEATHKNIGHT = {spec={}}
	TLT.DEATHKNIGHT.spec[1] = {role = TANK,    specID = 250, specName = "Sangre", icon = [[Interface\Icons\Spell_Deathknight_BloodPresence]]}
	TLT.DEATHKNIGHT.spec[2] = {role = DAMAGER, specID = 251, specName = "Escarcha", icon = [[Interface\Icons\Spell_Deathknight_FrostPresence]]}
	TLT.DEATHKNIGHT.spec[3] = {role = DAMAGER, specID = 252, specName = "Profano", icon = [[Interface\Icons\Spell_Deathknight_UnholyPresence]]}
	TLT.WARRIOR = {spec={}}
	TLT.WARRIOR.spec[1]     = {role = DAMAGER, specID =  71, specName = "Armas", icon = [[Interface\Icons\Ability_Warrior_SavageBlow]]}
	TLT.WARRIOR.spec[2]     = {role = DAMAGER, specID =  72, specName = "Furia", icon = [[Interface\Icons\Ability_Warrior_InnerRage]]}
	TLT.WARRIOR.spec[3]     = {role = TANK,    specID =  73, specName = "Protección", icon = [[Interface\Icons\Ability_Warrior_DefensiveStance]]}
	TLT.ROGUE = {spec={}}
	TLT.ROGUE.spec[1]       = {role = DAMAGER, specID = 259, specName = "Asesinato", icon = [[Interface\Icons\Ability_Rogue_Eviscerate]]}
	TLT.ROGUE.spec[2]       = {role = DAMAGER, specID = 260, specName = "Combate", icon = [[Interface\Icons\Ability_BackStab]]}
	TLT.ROGUE.spec[3]       = {role = DAMAGER, specID = 261, specName = "Sutileza", icon = [[Interface\Icons\Ability_Stealth]]}
	TLT.MAGE = {spec={}}
	TLT.MAGE.spec[1]        = {role = DAMAGER, specID =  62, specName = "Arcano", icon = [[Interface\Icons\Spell_Holy_MagicalSentry]]}
	TLT.MAGE.spec[2]        = {role = DAMAGER, specID =  63, specName = "Fuego", icon = [[Interface\Icons\Spell_Fire_FireBolt02]]}
	TLT.MAGE.spec[3]        = {role = DAMAGER, specID =  64, specName = "Escarcha", icon = [[Interface\Icons\Spell_Frost_FrostBolt02]]}
	TLT.PRIEST = {spec={}}
	TLT.PRIEST.spec[1]      = {role = HEALER,  specID = 256, specName = "Disciplina", icon = [[Interface\Icons\Spell_Holy_PowerWordShield]]}
	TLT.PRIEST.spec[2]      = {role = HEALER,  specID = 257, specName = "Sagrado", icon = [[Interface\Icons\Spell_Holy_GuardianSpirit]]}
	TLT.PRIEST.spec[3]      = {role = DAMAGER, specID = 258, specName = "Sombra", icon = [[Interface\Icons\Spell_Shadow_ShadowWordPain]]}
	TLT.PRIEST.spec[4]      = {role = HEALER,  specID = 257, specName = "Sagrada", icon = [[Interface\Icons\Spell_Holy_GuardianSpirit]]} -- DEL if it's fixed
	TLT.WARLOCK = {spec={}}
	TLT.WARLOCK.spec[1]     = {role = DAMAGER, specID = 265, specName = "Aflicción", icon = [[Interface\Icons\Spell_Shadow_DeathCoil]]}
	TLT.WARLOCK.spec[2]     = {role = DAMAGER, specID = 266, specName = "Demonología", icon = [[Interface\Icons\Spell_Shadow_Metamorphosis]]}
	TLT.WARLOCK.spec[3]     = {role = DAMAGER, specID = 267, specName = "Destrucción", icon = [[Interface\Icons\Spell_Shadow_RainOfFire]]}
	TLT.HUNTER = {spec={}}
	TLT.HUNTER.spec[1]      = {role = DAMAGER, specID = 253, specName = "Bestias", icon = [[INTERFACE\ICONS\ability_hunter_bestialdiscipline]]}
	TLT.HUNTER.spec[2]      = {role = DAMAGER, specID = 254, specName = "Puntería", icon = [[Interface\Icons\Ability_Hunter_FocusedAim]]}
	TLT.HUNTER.spec[3]      = {role = DAMAGER, specID = 255, specName = "Supervivencia", icon = [[INTERFACE\ICONS\ability_hunter_camouflage]]}
	TLT.DRUID = {spec={}}
	TLT.DRUID.spec[1]       = {role = DAMAGER, specID = 102, specName = "Equilibrio", icon = [[Interface\Icons\Spell_Nature_StarFall]]}
	TLT.DRUID.spec[2]       = {role = DAMAGER, specID = 103, specName = "Feral", icon = [[Interface\Icons\Ability_Druid_CatForm]]}
	TLT.DRUID.spec[3]       = {role = TANK,    specID = 104, specName = "Guardián", icon = [[Interface\Icons\Ability_Racial_BearForm]]}
	TLT.DRUID.spec[4]       = {role = HEALER,  specID = 105, specName = "Restauración", icon = [[Interface\Icons\Spell_Nature_HealingTouch]]}
	TLT.SHAMAN = {spec={}}
	TLT.SHAMAN.spec[1]      = {role = DAMAGER, specID = 262, specName = "Elemental", icon = [[Interface\Icons\Spell_Nature_Lightning]]}
	TLT.SHAMAN.spec[2]      = {role = DAMAGER, specID = 263, specName = "Mejora", icon = [[Interface\Icons\Spell_Shaman_ImprovedStormstrike]]}
	TLT.SHAMAN.spec[3]      = {role = HEALER,  specID = 264, specName = "Restauración", icon = [[Interface\Icons\Spell_Nature_MagicImmunity]]}
	TLT.PALADIN = {spec={}}
	TLT.PALADIN.spec[1]     = {role = HEALER,  specID =  65, specName = "Sagrado", icon = [[Interface\Icons\Spell_Holy_HolyBolt]]}
	TLT.PALADIN.spec[2]     = {role = TANK,    specID =  66, specName = "Protección", icon = [[Interface\Icons\Ability_Paladin_ShieldoftheTemplar]]}
	TLT.PALADIN.spec[3]     = {role = DAMAGER, specID =  70, specName = "Reprensión", icon = [[Interface\Icons\Spell_Holy_AuraOfLight]]}
	TLT.PALADIN.spec[4]     = {role = HEALER,  specID =  65, specName = "Sagrada", icon = [[Interface\Icons\Spell_Holy_HolyBolt]]} -- DEL if it's fixed
	TLT.MONK = {spec={}}
	TLT.MONK.spec[1]        = {role = TANK,    specID = 268, specName = "Maestro", icon = [[Interface\Icons\spell_monk_brewmaster_spec]]}
	TLT.MONK.spec[2]        = {role = DAMAGER, specID = 269, specName = "Viajero del viento", icon = [[Interface\Icons\spell_monk_windwalker_spec]]}
	TLT.MONK.spec[3]        = {role = HEALER,  specID = 270, specName = "Tejedor de niebla", icon = [[Interface\Icons\spell_monk_mistweaver_spec]]}
end