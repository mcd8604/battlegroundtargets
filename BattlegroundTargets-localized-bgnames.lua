-- -------------------------------------------------------------------------- --
-- BattlegroundTargets - localized battleground names                         --
-- Please make sure to save this file as UTF-8. ¶                             --
-- -------------------------------------------------------------------------- --
-- Note:                                                                      --
--  Return value from GetBattlefieldStatus().                                 --
--  This file fixes inconsistent Blizzard translations that exists between    --
--  the functions GetBattlefieldStatus() and GetBattlegroundInfo().           --
-- -------------------------------------------------------------------------- --

local BGN, _, prg = {}, ...
prg.BGN = BGN

local locale = GetLocale()
if locale == "frFR" then --> tested with Patch 5.2.0.16716-frFR (LIVE)
	-- GetBattlegroundInfo() : L'Œil du cyclone
	-- GetBattlefieldStatus(): L’Œil du cyclone
	BGN["L’Œil du cyclone"] = {bgSize = 15, flagBG = 2} -- Eye of the Storm
end