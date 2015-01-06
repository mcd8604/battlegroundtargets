-- -------------------------------------------------------------------------- --
-- BattlegroundTargets - carrier strings                                      --
-- Please make sure to save this file as UTF-8. ¶                             --
-- -------------------------------------------------------------------------- --

local FLG, _, prg = {}, ...
prg.FLG = FLG

local locale = GetLocale()

if locale == "deDE" then

	-- Warsong Gulch & Twin Peaks: --> deDE: tested with Patch 5.3.0.17128 (LIVE)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "Eure Angriffe verursachen nun schwerere Verletzungen bei Flaggenträgern!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "Eure Angriffe verursachen nun sehr schwere Verletzungen bei Flaggenträgern!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "(.+) hat die Flagge der (.+) aufgenommen!"
	FLG["WSG_TP_PATTERN_PICKED2"] = "(.+) hat die Flagge der (.+) aufgenommen!" -- ruRU special
	FLG["WSG_TP_MATCH_DROPPED"] = "fallenlassen!"
	FLG["WSG_TP_MATCH_CAPTURED"] = "errungen!"
	-- Eye of the Storm: --> deDE: tested with Patch 6.0.3.19342 (LIVE)
	FLG["EOTS_PATTERN_PICKED"] = "(.+) hat die Flagge aufgenommen."
	FLG["EOTS_PATTERN_CAPTURED"] = "(.+) hat die Flagge erobert!"
	FLG["EOTS_STRING_DROPPED"] = "Die Flagge wurde fallengelassen."
	-- Temple of Kotmogu: --> deDE: tested with Patch 5.1.0.16208 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "(.+) hat die (.+) Kugel genommen!"
	FLG["TOK_PATTERN_RETURNED"] = "Die (.+) Kugel wurde zurückgebracht!"
	-- Deepwind Gorge: --> deDE: tested with Patch 6.0.3.19342 (LIVE)
	FLG["DG_PATTERN_PICKED"] = "(.+) hat die Flagge der .+ aufgenommen!"
	FLG["DG_PATTERN_DROPPED"] = ".+ hat die Flagge der .+ fallenlassen!"
	FLG["DG_PATTERN_CAPTURED"] = ".+ hat die Flagge der .+ errungen!"

elseif locale == "esES" then

	-- Warsong Gulch & Twin Peaks: --> esES: tested with Patch 6.0.3.19342 (LIVE)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "¡Los portadores de las banderas se han vuelto vulnerables a los ataques!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "¡Los portadores de las banderas se han vuelto más vulnerables a los ataques!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "¡(.+) ha cogido la bandera"
	FLG["WSG_TP_PATTERN_PICKED2"] = "¡(.+) ha cogido la bandera" -- ruRU special
	FLG["WSG_TP_MATCH_DROPPED"] = "dejado caer la bandera"
	FLG["WSG_TP_MATCH_CAPTURED"] = "capturado la bandera"
	-- Eye of the Storm: --> esES: tested with Patch 6.0.3.19342 (LIVE)
	FLG["EOTS_PATTERN_PICKED"] = "¡(.+) ha tomado la bandera!"
	FLG["EOTS_PATTERN_CAPTURED"] = "¡(.+) ha capturado la bandera!"
	FLG["EOTS_STRING_DROPPED"] = "¡Ha caído la bandera!"
	-- Temple of Kotmogu: --> esES: tested with Patch 5.4.0.17093 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "¡(.+) se ha hecho con el orbe (.+)!"
	FLG["TOK_PATTERN_RETURNED"] = "¡El orbe (.+) ha sido devuelto!"
	-- Deepwind Gorge: --> esES: tested with Patch 6.0.3.19342 (LIVE)
	FLG["DG_PATTERN_PICKED"] = "¡(.+) ha cogido la bandera"
	FLG["DG_PATTERN_DROPPED"] = "dejado caer la bandera"
	FLG["DG_PATTERN_CAPTURED"] = "capturado la bandera"

elseif locale == "esMX" then

	-- Warsong Gulch & Twin Peaks: --> esMX: tested with Patch 5.1.0.16208 (PTR)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "¡Los portadores de las banderas se han vuelto vulnerables a los ataques!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "¡Los portadores de las banderas se han vuelto más vulnerables a los ataques!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "¡(.+) ha tomado la bandera"
	FLG["WSG_TP_PATTERN_PICKED2"] = "¡(.+) ha tomado la bandera" -- ruRU special
	FLG["WSG_TP_MATCH_DROPPED"] = "dejado caer la bandera"
	FLG["WSG_TP_MATCH_CAPTURED"] = "capturado la bandera"
	-- Eye of the Storm: --> esMX: TODO need check
	FLG["EOTS_PATTERN_PICKED"] = "¡(.+) ha tomado la bandera!"
	FLG["EOTS_PATTERN_CAPTURED"] = "¡(.+) ha capturado la bandera!"
	FLG["EOTS_STRING_DROPPED"] = "¡Ha caído la bandera!"
	-- Temple of Kotmogu: --> esMX: tested with Patch 5.4.0.17093 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "¡(.+) ha tomado el orbe (.+)!"
	FLG["TOK_PATTERN_RETURNED"] = "¡El orbe (.+) ha sido devuelto!"
	-- Deepwind Gorge: --> esMX: TODO need check
	FLG["DG_PATTERN_PICKED"] = "¡(.+) ha tomado la bandera"
	FLG["DG_PATTERN_DROPPED"] = "dejado caer la bandera"
	FLG["DG_PATTERN_CAPTURED"] = "capturado la bandera"

elseif locale == "frFR" then

	-- Warsong Gulch & Twin Peaks: --> frFR: tested with Patch 6.0.3.19342 (LIVE)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "Les porteurs de drapeaux sont devenus vulnérables aux attaques !"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "Les porteurs de drapeaux sont devenus encore plus vulnérables aux attaques !"
	FLG["WSG_TP_PATTERN_PICKED1"] = "a été ramassé par (.+) !"
	FLG["WSG_TP_PATTERN_PICKED2"] = "a été ramassé par (.+) !" -- ruRU special
	FLG["WSG_TP_MATCH_DROPPED"] = "a été lâché"
	FLG["WSG_TP_MATCH_CAPTURED"] = "a pris le drapeau"
	-- Eye of the Storm: --> frFR: tested with Patch 6.0.3.19342 (LIVE)
	FLG["EOTS_PATTERN_PICKED"] = "(.+) a pris le drapeau !"
	FLG["EOTS_PATTERN_CAPTURED"] = "(.+) a capturé le drapeau !"
	FLG["EOTS_STRING_DROPPED"] = "Le drapeau a été lâché !"
	-- Temple of Kotmogu: --> frFR: tested with Patch 5.1.0.16208 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "(.+) a pris l’orbe (.+) !"
	FLG["TOK_PATTERN_RETURNED"] = "L’orbe (.+) a été rendu !"
	-- Deepwind Gorge: --> frFR: tested with Patch 6.0.3.19342 (LIVE)
	FLG["DG_PATTERN_PICKED"] = "Le drapeau de .+ a été ramassé par (.+) !"
	FLG["DG_PATTERN_DROPPED"] = "Le drapeau de .+ a été lâché par .+ !"
	FLG["DG_PATTERN_CAPTURED"] = "a pris le drapeau"

elseif locale == "itIT" then

	-- Warsong Gulch & Twin Peaks: --> itIT: tested with Patch 6.0.3.19342 (LIVE)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "I portatori di bandiera sono diventati vulnerabili agli attacchi!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "I portatori di bandiera sono diventati più vulnerabili agli attacchi!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "(.+) ha raccolto la bandiera dell'(.+)!"
	FLG["WSG_TP_PATTERN_PICKED2"] = "(.+) ha raccolto la bandiera dell'(.+)!" -- ruRU special
	FLG["WSG_TP_MATCH_DROPPED"] = "lasciato cadere la bandiera"
	FLG["WSG_TP_MATCH_CAPTURED"] = "conquistato la bandiera"
	-- Eye of the Storm: --> itIT: tested with Patch 6.0.3.19342 (LIVE)
	FLG["EOTS_PATTERN_PICKED"] = "(.+) ha raccolto la bandiera!"
	FLG["EOTS_PATTERN_CAPTURED"] = "(.+) ha catturato la bandiera!"
	FLG["EOTS_STRING_DROPPED"] = "La bandiera è a terra!"
	-- Temple of Kotmogu: --> itIT: tested with Patch 5.1.0.16208 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "(.+) ha preso il globo (.+)!"
	FLG["TOK_PATTERN_RETURNED"] = "Il globo (.+) è stato restituito!"
	-- Deepwind Gorge: --> itIT: tested with Patch 6.0.3.19342 (LIVE)
	FLG["DG_PATTERN_PICKED"] = "(.+) ha raccolto la bandiera"
	FLG["DG_PATTERN_DROPPED"] = "lasciato cadere la bandiera"
	FLG["DG_PATTERN_CAPTURED"] = "conquistato la bandiera"

elseif locale == "koKR" then

	-- Warsong Gulch & Twin Peaks: --> koKR: tested with Patch 4.3.2.15211 (PTR)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "깃발 운반자가 약해져서 쉽게 공격할 수 있습니다!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "깃발 운반자가 점점 약해져서 더욱 쉽게 공격할 수 있습니다!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "(.+)|1이;가; (.+) 깃발을 손에 넣었습니다!"
	FLG["WSG_TP_PATTERN_PICKED2"] = "(.+)|1이;가; (.+) 깃발을 손에 넣었습니다!" -- ruRU special
	FLG["WSG_TP_MATCH_DROPPED"] = "깃발을 떨어뜨렸습니다!"
	FLG["WSG_TP_MATCH_CAPTURED"] = "깃발 쟁탈에 성공했습니다!"
	-- Eye of the Storm: --> koKR: TODO
	FLG["EOTS_PATTERN_PICKED"] = "TODO" -- "^(.+)|1이;가; 깃발을 차지했습니다!"
	FLG["EOTS_PATTERN_CAPTURED"] = "TODO"
	FLG["EOTS_STRING_DROPPED"] = "TODO" -- "깃발이 떨어졌습니다!"
	-- Temple of Kotmogu: --> koKR: tested with Patch 5.4.0.17093 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "(.+)|1이;가; (.+) 공을 차지했습니다!"
	FLG["TOK_PATTERN_RETURNED"] = "(.+) 공이 돌아왔습니다!"
	-- Deepwind Gorge: --> koKR: TODO
	FLG["DG_PATTERN_PICKED"] = "The .+ was picked up by (.+)!"
	FLG["DG_PATTERN_DROPPED"] = "The .+ was dropped by .+!"
	FLG["DG_PATTERN_CAPTURED"] = ".+ captured the .+!"

elseif locale == "ptBR" then

	-- Warsong Gulch & Twin Peaks: --> ptBR: tested with Patch 6.0.3.19342 (LIVE)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "Os portadores da bandeira estão vulneráveis!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "Os portadores da bandeira estão ainda mais vulneráveis!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "(.+) pegou a Bandeira da (.+)!"
	FLG["WSG_TP_PATTERN_PICKED2"] = "(.+) pegou a Bandeira da (.+)!" -- ruRU special
	FLG["WSG_TP_MATCH_DROPPED"] = "largou a Bandeira"
	FLG["WSG_TP_MATCH_CAPTURED"] = "capturou a Bandeira"
	-- Eye of the Storm: --> ptBR: tested with Patch 6.0.3.19342 (LIVE)
	FLG["EOTS_PATTERN_PICKED"] = "(.+) pegou a bandeira!"
	FLG["EOTS_PATTERN_CAPTURED"] = "(.+) capturou a bandeira!"
	FLG["EOTS_STRING_DROPPED"] = "A bandeira foi largada!"
	-- Temple of Kotmogu: --> ptBR: tested with Patch 5.4.0.17093 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "(.+) pegou o orbe (.+)!"
	FLG["TOK_PATTERN_RETURNED"] = "O orbe (.+) foi devolvido!"
	-- Deepwind Gorge: --> ptBR: tested with Patch 6.0.3.19342 (LIVE)
	FLG["DG_PATTERN_PICKED"] = "(.+) pegou a Bandeira da .+!"
	FLG["DG_PATTERN_DROPPED"] = "largou a Bandeira"
	FLG["DG_PATTERN_CAPTURED"] = "capturou a Bandeira"

elseif locale == "ruRU" then

	-- Warsong Gulch & Twin Peaks: --> ruRU: tested with Patch 4.3.3.15354 (PTR)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "Персонажи, несущие флаг, стали более уязвимы!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "Персонажи, несущие флаг, стали еще более уязвимы!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "(.+) несет флаг Орды!"
	FLG["WSG_TP_PATTERN_PICKED2"] = "Флаг Альянса у |3%-1%((.+)%)!" -- ruRU special
	FLG["WSG_TP_MATCH_DROPPED"] = "роняет"
	FLG["WSG_TP_MATCH_CAPTURED"] = "захватывает"
	-- Eye of the Storm: --> ruRU: TODO
	FLG["EOTS_PATTERN_PICKED"] = "TODO" -- "(.+) захватывает флаг!"
	FLG["EOTS_PATTERN_CAPTURED"] = "TODO"
	FLG["EOTS_STRING_DROPPED"] = "TODO" -- "Флаг уронили!"
	-- Temple of Kotmogu: --> ruRU: tested with Patch 5.4.0.17093 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "(.+) захватывает (.+) сферу!"
	FLG["TOK_PATTERN_RETURNED"] = "(.+) сфера возвращена!"
	-- Deepwind Gorge: --> ruRU: TODO
	FLG["DG_PATTERN_PICKED"] = "The .+ was picked up by (.+)!"
	FLG["DG_PATTERN_DROPPED"] = "The .+ was dropped by .+!"
	FLG["DG_PATTERN_CAPTURED"] = ".+ captured the .+!"

elseif locale == "zhCN" then

	-- Warsong Gulch & Twin Peaks: --> zhCN: tested with Patch 5.1.0.16135
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "旗手变得脆弱了！"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "旗手变得更加脆弱了！"
	FLG["WSG_TP_PATTERN_PICKED1"] = "旗帜被([^%s]+)拔起了！"
	FLG["WSG_TP_PATTERN_PICKED2"] = "旗帜被([^%s]+)拔起了！" -- ruRU special
	FLG["WSG_TP_MATCH_DROPPED"] = "丢掉了"
	FLG["WSG_TP_MATCH_CAPTURED"] = "夺取"
	-- Eye of the Storm: --> zhCN: TODO
	FLG["EOTS_PATTERN_PICKED"] = "TODO" -- "(.+)夺走了旗帜！"
	FLG["EOTS_PATTERN_CAPTURED"] = "TODO"
	FLG["EOTS_STRING_DROPPED"] = "TODO" -- "旗帜被扔掉了！"
	-- Temple of Kotmogu: --> zhCN: tested with Patch 5.1.0.16135
	FLG["TOK_PATTERN_TAKEN"] = "(.+)取走了(.+)的球！"
	FLG["TOK_PATTERN_RETURNED"] = "(.+)宝珠被放回了！"
	-- Deepwind Gorge: --> zhCN: TODO
	FLG["DG_PATTERN_PICKED"] = "The .+ was picked up by (.+)!"
	FLG["DG_PATTERN_DROPPED"] = "The .+ was dropped by .+!"
	FLG["DG_PATTERN_CAPTURED"] = ".+ captured the .+!"

elseif locale == "zhTW" then

	-- Warsong Gulch & Twin Peaks: --> zhTW: tested with Patch 4.3.2.15211 (PTR)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "旗幟持有者變得有機可趁了!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "旗幟持有者變得愈來愈有機可趁!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "被(.+)拔掉了!"
	FLG["WSG_TP_PATTERN_PICKED2"] = "被(.+)拔掉了!" -- ruRU special
	FLG["WSG_TP_MATCH_DROPPED"] = "丟掉了"
	FLG["WSG_TP_MATCH_CAPTURED"] = "佔據了"
	-- Eye of the Storm: --> zhTW: TODO
	FLG["EOTS_PATTERN_PICKED"] =  "TODO" -- "(.+)已經奪走了旗幟!"
	FLG["EOTS_PATTERN_CAPTURED"] = "TODO"
	FLG["EOTS_STRING_DROPPED"] =  "TODO" -- "旗幟已經掉落!"
	-- Temple of Kotmogu: --> zhTW: tested with Patch 5.4.0.17093 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "(.+)奪走了(.+)異能球!"
	FLG["TOK_PATTERN_RETURNED"] = "(.+)異能球已回到初始位置!"
	-- Deepwind Gorge: --> zhTW: TODO
	FLG["DG_PATTERN_PICKED"] = "The .+ was picked up by (.+)!"
	FLG["DG_PATTERN_DROPPED"] = "The .+ was dropped by .+!"
	FLG["DG_PATTERN_CAPTURED"] = ".+ captured the .+!"

else--if locale == "enUS" then

	-- Warsong Gulch & Twin Peaks: --> enUS: tested with Patch 4.3.0.15050 (LIVE)
	FLG["WSG_TP_STRING_FLAG_DEBUFF1"] = "The flag carriers have become vulnerable to attack!"
	FLG["WSG_TP_STRING_FLAG_DEBUFF2"] = "The flag carriers have become increasingly vulnerable to attack!"
	FLG["WSG_TP_PATTERN_PICKED1"] = "was picked up by (.+)!"
	FLG["WSG_TP_PATTERN_PICKED2"] = "was picked up by (.+)!" -- ruRU special
	FLG["WSG_TP_MATCH_DROPPED"] = "was dropped"
	FLG["WSG_TP_MATCH_CAPTURED"] = "captured the"
	-- Eye of the Storm: --> enUS: tested with Patch 6.0.3.19342 (LIVE)
	FLG["EOTS_PATTERN_PICKED"] = "(.+) has taken the flag!"
	FLG["EOTS_PATTERN_CAPTURED"] = "(.+) has captured the flag!"
	FLG["EOTS_STRING_DROPPED"] = "The flag has been dropped!"
	-- Temple of Kotmogu: --> enUS: tested with Patch 5.1.0.16208 (PTR)
	FLG["TOK_PATTERN_TAKEN"] = "(.+) has taken the (.+) orb!"
	FLG["TOK_PATTERN_RETURNED"] = "The (.+) orb has been returned!"
	-- Deepwind Gorge: --> enUS: tested with Patch 6.0.3.19342 (LIVE)
	FLG["DG_PATTERN_PICKED"] = "The .+ was picked up by (.+)!"
	FLG["DG_PATTERN_DROPPED"] = "The .+ was dropped by .+!"
	FLG["DG_PATTERN_CAPTURED"] = ".+ captured the .+!"

end