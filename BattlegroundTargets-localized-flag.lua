-- -------------------------------------------------------------------------- --
-- BattlegroundTargets Localized Flag picked/dropped/captured                 --
-- Please make sure to save this file as UTF-8. ¶                             --
-- -------------------------------------------------------------------------- --

BattlegroundTargets_Flag = {}

function BattlegroundTargets_Flag:CreateLocaleTable(t)
	for k,v in pairs(t) do
		self[k] = (v == true and k) or v
	end
end

BattlegroundTargets_Flag:CreateLocaleTable({
	-- ### enUS: last TESTED with Patch 4.2.0.14480 (LIVE) ###
	-- # Warsong Gulch & Twink Peaks:
	["WSG_TP_REGEX_PICKED1"] = "was picked up by (.+)!",
	["WSG_TP_REGEX_PICKED2"] = "was picked up by (.+)!",
	["WSG_TP_MATCH_DROPPED"] = "dropped",
	["WSG_TP_MATCH_CAPTURED"] = "captured the",
	-- # Eye of the Storm:
	["EOTS_REGEX_PICKED"] = "(.+) has taken the flag!",
	["EOTS_STRING_DROPPED"] = "The flag has been dropped!",
	["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "The Alliance have captured the flag!",
	["EOTS_STRING_CAPTURED_BY_HORDE"] = "The Horde have captured the flag!",
})

local locale = GetLocale()
if locale == "deDE" then
BattlegroundTargets_Flag:CreateLocaleTable({
	-- ### deDE: last TESTED with Patch 4.2.0.14480 (LIVE) ###
	-- # Warsong Gulch & Twink Peaks:
	["WSG_TP_REGEX_PICKED1"] = "(.+) hat die Flagge der (%a+) aufgenommen!",
	["WSG_TP_REGEX_PICKED2"] = "(.+) hat die Flagge der (%a+) aufgenommen!", -- ...not needed...
	["WSG_TP_MATCH_DROPPED"] = "fallen lassen!",
	["WSG_TP_MATCH_CAPTURED"] = "errungen!",
	-- # Eye of the Storm:
	["EOTS_REGEX_PICKED"] = "(.+) hat die Flagge aufgenommen.",
	["EOTS_STRING_DROPPED"] = "Die Flagge wurde fallengelassen.",
	["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "Die Allianz hat die Flagge erobert!",
	["EOTS_STRING_CAPTURED_BY_HORDE"] = "Die Horde hat die Flagge erobert!",
})
elseif locale == "esES" then
BattlegroundTargets_Flag:CreateLocaleTable({
	-- ### esES: last TESTED with Patch 4.2.0.14480 (LIVE) ###
	-- # Warsong Gulch & Twink Peaks:
	["WSG_TP_REGEX_PICKED1"] = "¡(.+) ha cogido la bandera",
	["WSG_TP_REGEX_PICKED2"] = "¡(.+) ha cogido la bandera", -- ...not needed...
	["WSG_TP_MATCH_DROPPED"] = "dejado caer la bandera",
	["WSG_TP_MATCH_CAPTURED"] = "capturado la bandera",
	-- # Eye of the Storm:
	["EOTS_REGEX_PICKED"] = "¡(.+) ha tomado la bandera!",
	["EOTS_STRING_DROPPED"] = "¡Ha caído la bandera!",
	["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "¡La Alianza ha capturado la bandera!",
	["EOTS_STRING_CAPTURED_BY_HORDE"] = "¡La Horda ha capturado la bandera!",
})
elseif locale == "esMX" then
BattlegroundTargets_Flag:CreateLocaleTable({
	--- ### esMX: last TESTED with Patch 4.2.2.14534 (PTR) ###
	-- # Warsong Gulch & Twink Peaks:
	["WSG_TP_REGEX_PICKED1"] = "¡(.+) ha tomado la bandera",
	["WSG_TP_REGEX_PICKED2"] = "¡(.+) ha tomado la bandera", -- ...not needed...
	["WSG_TP_MATCH_DROPPED"] = "dejado caer la bandera",
	["WSG_TP_MATCH_CAPTURED"] = "capturado la bandera",
	-- # Eye of the Storm:
	["EOTS_REGEX_PICKED"] = "¡(.+) ha tomado la bandera!",
	["EOTS_STRING_DROPPED"] = "¡Ha caído la bandera!",
	["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "¡La Alianza ha capturado la bandera!",
	["EOTS_STRING_CAPTURED_BY_HORDE"] = "¡La Horda ha capturado la bandera!",
})
elseif locale == "frFR" then
BattlegroundTargets_Flag:CreateLocaleTable({
	-- ### frFR: last TESTED with Patch 4.2.0.14480 (LIVE) ###
	-- # Warsong Gulch & Twink Peaks:
	["WSG_TP_REGEX_PICKED1"] = "a été ramassé par (.+) !",
	["WSG_TP_REGEX_PICKED2"] = "a été ramassé par (.+) !", -- ...not needed...
	["WSG_TP_MATCH_DROPPED"] = "a été lâché",
	["WSG_TP_MATCH_CAPTURED"] = "a pris le drapeau",
	-- # Eye of the Storm:
	["EOTS_REGEX_PICKED"] = "(.+) a pris le drapeau !",
	["EOTS_STRING_DROPPED"] = "Le drapeau a été lâché !",
	["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "L'Alliance a pris le drapeau !",
	["EOTS_STRING_CAPTURED_BY_HORDE"] = "La Horde s'est emparée du drapeau !",
})
elseif locale == "koKR" then
BattlegroundTargets_Flag:CreateLocaleTable({
	-- ### koKR: last TESTED with Patch 4.2.2.14534 (PTR) ###
	-- # Warsong Gulch & Twink Peaks:
	["WSG_TP_REGEX_PICKED1"] = "([^ ]*)|1이;가; ([^!]*) 깃발을 손에 넣었습니다!",
	["WSG_TP_REGEX_PICKED2"] = "([^ ]*)|1이;가; ([^!]*) 깃발을 손에 넣었습니다!", -- ...not needed...
	["WSG_TP_MATCH_DROPPED"] = "깃발을 떨어뜨렸습니다!",
	["WSG_TP_MATCH_CAPTURED"] = "깃발 쟁탈에 성공했습니다!",
	-- # Eye of the Storm:
	["EOTS_REGEX_PICKED"] = "^(.+)|1이;가; 깃발을 차지했습니다!",
	["EOTS_STRING_DROPPED"] = "깃발이 떨어졌습니다!",
	["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "얼라이언스가 깃발을 차지했습니다!",
	["EOTS_STRING_CAPTURED_BY_HORDE"] = "호드가 깃발을 차지했습니다!",
})
elseif locale == "ruRU" then
BattlegroundTargets_Flag:CreateLocaleTable({
	-- ### ruRU: last TESTED with Patch 4.2.2.14534 (PTR) ###
	-- # Warsong Gulch & Twink Peaks:
	["WSG_TP_REGEX_PICKED1"] = "(.+) несет флаг Орды!",
	["WSG_TP_REGEX_PICKED2"] = "Флаг Альянса у |3%-1%((.+)%)!",
	["WSG_TP_MATCH_DROPPED"] = "роняет",
	["WSG_TP_MATCH_CAPTURED"] = "захватывает",
	-- # Eye of the Storm:
	["EOTS_REGEX_PICKED"] = "(.+) захватывает флаг!",
	["EOTS_STRING_DROPPED"] = "Флаг уронили!",
	["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "Альянс захватил флаг!",
	["EOTS_STRING_CAPTURED_BY_HORDE"] = "Орда захватила флаг!",
})
elseif locale == "zhCN" then
BattlegroundTargets_Flag:CreateLocaleTable({
	-- ### zhCN: NOT TESTED ###
	-- # Warsong Gulch & Twink Peaks:
	["WSG_TP_REGEX_PICKED1"] = "旗帜被([^%s]+)拔起了！", -----TODO-----
	["WSG_TP_REGEX_PICKED2"] = "旗帜被([^%s]+)拔起了！", -- ...not needed... -----TODO-----
	["WSG_TP_MATCH_DROPPED"] = "丢掉了", -----TODO-----
	["WSG_TP_MATCH_CAPTURED"] = "夺取", -----TODO-----
	-- # Eye of the Storm:
	["EOTS_REGEX_PICKED"] = "(.+)夺走了旗帜！", -----TODO-----
	["EOTS_STRING_DROPPED"] = true, -----TODO-----
	["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = true, -----TODO-----
	["EOTS_STRING_CAPTURED_BY_HORDE"] = true, -----TODO-----
})
elseif locale == "zhTW" then
BattlegroundTargets_Flag:CreateLocaleTable({
	-- ### zhTW: last TESTED with Patch 4.2.2.14534 (PTR) ###
	-- # Warsong Gulch & Twink Peaks:
	["WSG_TP_REGEX_PICKED1"] = "被(.+)拔掉了!",
	["WSG_TP_REGEX_PICKED2"] = "被(.+)拔掉了!", -- ...not needed...
	["WSG_TP_MATCH_DROPPED"] = "丟掉了",
	["WSG_TP_MATCH_CAPTURED"] = "佔據了",
	-- # Eye of the Storm:
	["EOTS_REGEX_PICKED"] = "(.+)已經奪走了旗幟!",
	["EOTS_STRING_DROPPED"] = "旗幟已經掉落!",
	["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "聯盟已奪得旗幟!",
	["EOTS_STRING_CAPTURED_BY_HORDE"] = "部落已奪得旗幟!",
})
end