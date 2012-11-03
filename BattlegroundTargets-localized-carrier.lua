-- -------------------------------------------------------------------------- --
-- BattlegroundTargets - carrier strings                                      --
-- Please make sure to save this file as UTF-8. ¶                             --
-- -------------------------------------------------------------------------- --

local FLG, _, prg = {}, ...
prg.FLG = FLG

local locale = GetLocale()

if locale == "deDE" then

	-- Warsong Gulch & Twin Peaks: --> deDE: tested with Patch 4.3.0.15050 (LIVE)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "Eure Angriffe verursachen nun schwerere Verletzungen bei Flaggenträgern!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "Eure Angriffe verursachen nun sehr schwere Verletzungen bei Flaggenträgern!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "(.+) hat die Flagge der (%a+) aufgenommen!"
	FLG["WSG_TP_PATTERN_PICKED2"] = "(.+) hat die Flagge der (%a+) aufgenommen!"
	FLG["WSG_TP_MATCH_DROPPED"] = "fallen lassen!"
	FLG["WSG_TP_MATCH_CAPTURED"] = "errungen!"
	-- Eye of the Storm: --> deDE: tested with Patch 4.3.0.15050 (LIVE)
	FLG["EOTS_PATTERN_PICKED"] = "(.+) hat die Flagge aufgenommen."
	FLG["EOTS_STRING_DROPPED"] = "Die Flagge wurde fallengelassen."
	FLG["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "Die Allianz hat die Flagge erobert!"
	FLG["EOTS_STRING_CAPTURED_BY_HORDE"] = "Die Horde hat die Flagge erobert!"
	-- Temple of Kotmogu: --> deDE: tested with Patch 5.1.0.16208 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "(.+) hat die (.+) Kugel genommen!"
	FLG["TOK_PATTERN_RETURNED"] = "Die (.+) Kugel wurde zurückgebracht!"

elseif locale == "esES" then

	-- Warsong Gulch & Twin Peaks: --> esES: tested with Patch 5.1.0.16208 (PTR)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "¡Los portadores de las banderas se han vuelto vulnerables a los ataques!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "¡Los portadores de las banderas se han vuelto más vulnerables a los ataques!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "¡(.+) ha cogido la bandera"
	FLG["WSG_TP_PATTERN_PICKED2"] = "¡(.+) ha cogido la bandera"
	FLG["WSG_TP_MATCH_DROPPED"] = "dejado caer la bandera"
	FLG["WSG_TP_MATCH_CAPTURED"] = "capturado la bandera"
	-- Eye of the Storm: --> esES: tested with Patch 4.3.0.15050 (LIVE)
	FLG["EOTS_PATTERN_PICKED"] = "¡(.+) ha tomado la bandera!"
	FLG["EOTS_STRING_DROPPED"] = "¡Ha caído la bandera!"
	FLG["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "¡La Alianza ha capturado la bandera!"
	FLG["EOTS_STRING_CAPTURED_BY_HORDE"] = "¡La Horda ha capturado la bandera!"
	-- Temple of Kotmogu: --> esES: tested with Patch 5.1.0.16208 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "¡(.+) se ha hecho con el orbe (.+)!"
	FLG["TOK_PATTERN_RETURNED"] = "¡El orbe (.+) ha sido devuelto!"

elseif locale == "esMX" then

	-- Warsong Gulch & Twin Peaks: --> esMX: tested with Patch 5.1.0.16208 (PTR)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "¡Los portadores de las banderas se han vuelto vulnerables a los ataques!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "¡Los portadores de las banderas se han vuelto más vulnerables a los ataques!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "¡(.+) ha tomado la bandera"
	FLG["WSG_TP_PATTERN_PICKED2"] = "¡(.+) ha tomado la bandera"
	FLG["WSG_TP_MATCH_DROPPED"] = "dejado caer la bandera"
	FLG["WSG_TP_MATCH_CAPTURED"] = "capturado la bandera"
	-- Eye of the Storm: --> esMX: tested with Patch 4.2.2.14534 (PTR)
	FLG["EOTS_PATTERN_PICKED"] = "¡(.+) ha tomado la bandera!"
	FLG["EOTS_STRING_DROPPED"] = "¡Ha caído la bandera!"
	FLG["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "¡La Alianza ha capturado la bandera!"
	FLG["EOTS_STRING_CAPTURED_BY_HORDE"] = "¡La Horda ha capturado la bandera!"
	-- Temple of Kotmogu: --> esMX: tested with Patch 5.1.0.16208 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "¡(.+) ha tomado el orbe (.+)!"
	FLG["TOK_PATTERN_RETURNED"] = "¡El orbe (.+) ha sido devuelto!"

elseif locale == "frFR" then

	-- Warsong Gulch & Twin Peaks: --> frFR: tested with Patch 4.3.0.15050 (LIVE)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "Les porteurs de drapeaux sont devenus vulnérables aux attaques !"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "Les porteurs de drapeaux sont devenus encore plus vulnérables aux attaques !"
	FLG["WSG_TP_PATTERN_PICKED1"] = "a été ramassé par (.+) !"
	FLG["WSG_TP_PATTERN_PICKED2"] = "a été ramassé par (.+) !"
	FLG["WSG_TP_MATCH_DROPPED"] = "a été lâché"
	FLG["WSG_TP_MATCH_CAPTURED"] = "a pris le drapeau"
	-- Eye of the Storm: --> frFR: tested with Patch 4.3.0.15050 (LIVE)
	FLG["EOTS_PATTERN_PICKED"] = "(.+) a pris le drapeau !"
	FLG["EOTS_STRING_DROPPED"] = "Le drapeau a été lâché !"
	FLG["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "L'Alliance a pris le drapeau !"
	FLG["EOTS_STRING_CAPTURED_BY_HORDE"] = "La Horde s'est emparée du drapeau !"
	-- Temple of Kotmogu: --> frFR: tested with Patch 5.1.0.16208 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "(.+) a pris l’orbe (.+) !"
	FLG["TOK_PATTERN_RETURNED"] = "L’orbe (.+) a été rendu !"

elseif locale == "itIT" then

	-- Warsong Gulch & Twin Peaks: --> itIT: tested with Patch 5.0.4.16016 (LIVE)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "I portatori di bandiera sono diventati vulnerabili agli attacchi!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "I portatori di bandiera sono diventati più vulnerabili agli attacchi!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "(.+) ha raccolto la bandiera dell'(%a+)!"
	FLG["WSG_TP_PATTERN_PICKED2"] = "(.+) ha raccolto la bandiera dell'(%a+)!"
	FLG["WSG_TP_MATCH_DROPPED"] = "lasciato cadere la bandiera"
	FLG["WSG_TP_MATCH_CAPTURED"] = "conquistato la bandiera"
	-- Eye of the Storm: --> itIT: tested with Patch 5.0.4.16016 (LIVE)
	FLG["EOTS_PATTERN_PICKED"] = "(.+) ha raccolto la bandiera!"
	FLG["EOTS_STRING_DROPPED"] = "La bandiera è a terra!"
	FLG["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "L'Alleanza ha conquistato la bandiera!"
	FLG["EOTS_STRING_CAPTURED_BY_HORDE"] = "L'Orda ha conquistato la bandiera!"
	-- Temple of Kotmogu: --> itIT: tested with Patch 5.1.0.16208 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "(.+) ha preso il globo (.+)!"
	FLG["TOK_PATTERN_RETURNED"] = "Il globo (.+) è stato restituito!"

elseif locale == "koKR" then

	-- Warsong Gulch & Twin Peaks: --> koKR: tested with Patch 4.3.2.15211 (PTR)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "깃발 운반자가 약해져서 쉽게 공격할 수 있습니다!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "깃발 운반자가 점점 약해져서 더욱 쉽게 공격할 수 있습니다!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "([^ ]*)|1이;가; ([^!]*) 깃발을 손에 넣었습니다!"
	FLG["WSG_TP_PATTERN_PICKED2"] = "([^ ]*)|1이;가; ([^!]*) 깃발을 손에 넣었습니다!"
	FLG["WSG_TP_MATCH_DROPPED"] = "깃발을 떨어뜨렸습니다!"
	FLG["WSG_TP_MATCH_CAPTURED"] = "깃발 쟁탈에 성공했습니다!"
	-- Eye of the Storm: --> koKR: tested with Patch 4.3.2.15211 (PTR)
	FLG["EOTS_PATTERN_PICKED"] = "^(.+)|1이;가; 깃발을 차지했습니다!"
	FLG["EOTS_STRING_DROPPED"] = "깃발이 떨어졌습니다!"
	FLG["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "얼라이언스가 깃발을 차지했습니다!"
	FLG["EOTS_STRING_CAPTURED_BY_HORDE"] = "호드가 깃발을 차지했습니다!"
	-- Temple of Kotmogu: --> koKR: tested with Patch 5.1.0.16208 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "(.+)|1이;가; (.+) 공을 차지했습니다!"
	FLG["TOK_PATTERN_RETURNED"] = "(.+) 공이 돌아왔습니다!"

elseif locale == "ptBR" then

	-- Warsong Gulch & Twin Peaks: --> ptBR: tested with Patch 4.3.0.15050 (LIVE)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "Os portadores da bandeira estão vulneráveis!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "Os portadores da bandeira estão ainda mais vulneráveis!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "(.+) pegou a Bandeira da (.+)!"
	FLG["WSG_TP_PATTERN_PICKED2"] = "(.+) pegou a Bandeira da (.+)!"
	FLG["WSG_TP_MATCH_DROPPED"] = "largou a Bandeira"
	FLG["WSG_TP_MATCH_CAPTURED"] = "capturou"
	-- Eye of the Storm: --> ptBR: tested with Patch 4.3.0.15050 (LIVE)
	FLG["EOTS_PATTERN_PICKED"] = "(.+) pegou a bandeira!"
	FLG["EOTS_STRING_DROPPED"] = "A bandeira foi largada!"
	FLG["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "A Aliança capturou a bandeira!"
	FLG["EOTS_STRING_CAPTURED_BY_HORDE"] = "A Horda capturou a bandeira!"
	-- Temple of Kotmogu: --> ptBR: tested with Patch 5.1.0.16208 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "(.+) pegou o orbe (.+)!"
	FLG["TOK_PATTERN_RETURNED"] = "O orbe (.+) foi devolvido!"

elseif locale == "ruRU" then

	-- Warsong Gulch & Twin Peaks: --> ruRU: tested with Patch 4.3.3.15354 (PTR)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "Персонажи, несущие флаг, стали более уязвимы!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "Персонажи, несущие флаг, стали еще более уязвимы!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "(.+) несет флаг Орды!"
	FLG["WSG_TP_PATTERN_PICKED2"] = "Флаг Альянса у |3%-1%((.+)%)!"
	FLG["WSG_TP_MATCH_DROPPED"] = "роняет"
	FLG["WSG_TP_MATCH_CAPTURED"] = "захватывает"
	-- Eye of the Storm: --> ruRU: tested with Patch 4.3.3.15354 (PTR)
	FLG["EOTS_PATTERN_PICKED"] = "(.+) захватывает флаг!"
	FLG["EOTS_STRING_DROPPED"] = "Флаг уронили!"
	FLG["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "Альянс захватил флаг!"
	FLG["EOTS_STRING_CAPTURED_BY_HORDE"] = "Орда захватила флаг!"
	-- Temple of Kotmogu: --> ruRU: tested with Patch 5.1.0.16208 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "(.+) захватывает (.+) сферу!"
	FLG["TOK_PATTERN_RETURNED"] = "(.+) сфера возвращена!"

elseif locale == "zhCN" then

	-- Warsong Gulch & Twin Peaks: --> zhCN: tested with Patch 4.3.2.15211 (PTR)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "旗手变得脆弱了！"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "旗手变得更加脆弱了！"
	FLG["WSG_TP_PATTERN_PICKED1"] = "旗帜被([^%s]+)拔起了！"
	FLG["WSG_TP_PATTERN_PICKED2"] = "旗帜被([^%s]+)拔起了！"
	FLG["WSG_TP_MATCH_DROPPED"] = "丢掉了"
	FLG["WSG_TP_MATCH_CAPTURED"] = "夺取"
	-- Eye of the Storm: --> zhCN: tested with Patch 4.3.2.15211 (PTR)
	FLG["EOTS_PATTERN_PICKED"] = "(.+)夺走了旗帜！"
	FLG["EOTS_STRING_DROPPED"] = "旗帜被扔掉了！"
	FLG["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "联盟夺得了旗帜！"
	FLG["EOTS_STRING_CAPTURED_BY_HORDE"] = "部落夺得了旗帜！"
	-- Temple of Kotmogu: --> zhCN: TODO -no PTR client available-
	FLG["TOK_PATTERN_TAKEN"] = "(.+) has taken the (.+) orb!" -- TODO
	FLG["TOK_PATTERN_RETURNED"] = "The (.+) orb has been returned!" -- TODO

elseif locale == "zhTW" then

	-- Warsong Gulch & Twin Peaks: --> zhTW: tested with Patch 4.3.2.15211 (PTR)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "旗幟持有者變得有機可趁了!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "旗幟持有者變得愈來愈有機可趁!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "被(.+)拔掉了!"
	FLG["WSG_TP_PATTERN_PICKED2"] = "被(.+)拔掉了!"
	FLG["WSG_TP_MATCH_DROPPED"] = "丟掉了"
	FLG["WSG_TP_MATCH_CAPTURED"] = "佔據了"
	-- Eye of the Storm: --> zhTW: tested with Patch 4.3.2.15211 (PTR)
	FLG["EOTS_PATTERN_PICKED"] = "(.+)已經奪走了旗幟!"
	FLG["EOTS_STRING_DROPPED"] = "旗幟已經掉落!"
	FLG["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "聯盟已奪得旗幟!"
	FLG["EOTS_STRING_CAPTURED_BY_HORDE"] = "部落已奪得旗幟!"
	-- Temple of Kotmogu: --> zhTW: tested with Patch 5.1.0.16208 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "(.+)奪走了(.+)寶珠!"
	FLG["TOK_PATTERN_RETURNED"] = "The (.+)異能球已回到初始位置!" -- works on PTR, but needs check ('The ' seems to be wrong)

else--if locale == "enUS" then

	-- Warsong Gulch & Twin Peaks: --> enUS: tested with Patch 4.3.0.15050 (LIVE)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "The flag carriers have become vulnerable to attack!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "The flag carriers have become increasingly vulnerable to attack!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "was picked up by (.+)!"
	FLG["WSG_TP_PATTERN_PICKED2"] = "was picked up by (.+)!"
	FLG["WSG_TP_MATCH_DROPPED"] = "dropped"
	FLG["WSG_TP_MATCH_CAPTURED"] = "captured the"
	-- Eye of the Storm: --> enUS: tested with Patch 4.3.0.15050 (LIVE)
	FLG["EOTS_PATTERN_PICKED"] = "(.+) has taken the flag!"
	FLG["EOTS_STRING_DROPPED"] = "The flag has been dropped!"
	FLG["EOTS_STRING_CAPTURED_BY_ALLIANCE"] = "The Alliance have captured the flag!"
	FLG["EOTS_STRING_CAPTURED_BY_HORDE"] = "The Horde have captured the flag!"
	-- Temple of Kotmogu: --> enUS: tested with Patch 5.1.0.16208 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "(.+) has taken the (.+) orb!"
	FLG["TOK_PATTERN_RETURNED"] = "The (.+) orb has been returned!"

end