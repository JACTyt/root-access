extends GutTest


func _combat(defenders: PackedStringArray, cards: Array, mode := TurnManager.MODE_NORMAL, trace := 0) -> TurnManager:
	var run := RunState.new(7)
	run.trace = trace
	var combat := TurnManager.new(run, defenders, mode)
	combat.hand.clear()
	combat.draw_pile.clear()
	combat.discard.clear()
	combat.cpu = 10
	combat.patched_type = ""
	for id in cards:
		combat.hand.append(DeckCard.new(Content.cards()[id]))
	return combat


func test_content_loads() -> void:
	assert_eq(Content.cards().size(), 15)
	assert_eq(Content.defenders().size(), 6)
	assert_eq(RunState.GHOST_DECK.size(), 10)


func test_damage_noise_and_cpu() -> void:
	var c := _combat(["firewall"], ["default_password"])
	c.defenders[0].blocked_type = ""
	c.play(c.hand[0])
	assert_eq(c.defenders[0].integrity, 24)
	assert_eq(c.noise, 1)
	assert_eq(c.cpu, 9)


func test_win_converts_leftover_noise_to_trace() -> void:
	var c := _combat(["ids_sensor"], ["buffer_overflow"])
	c.play(c.hand[0])
	assert_eq(c.result, TurnManager.WON)
	assert_eq(c.noise, 14, "IDS doubled the noise of the card that killed it")
	assert_eq(c.run.trace, 14)


func test_detected_at_cap_adds_penalty() -> void:
	var c := _combat(["firewall"], ["default_password"])
	c.defenders[0].blocked_type = ""
	c.noise = 19
	c.play(c.hand[0])
	assert_eq(c.result, TurnManager.DETECTED)
	assert_eq(c.run.trace, TurnManager.DETECTED_TRACE)


func test_disconnect_costs_trace() -> void:
	var c := _combat(["firewall"], [])
	c.disconnect_from_host()
	assert_eq(c.result, TurnManager.DISCONNECTED)
	assert_eq(c.run.trace, TurnManager.DISCONNECT_TRACE)


func test_trace_100_overrides_win() -> void:
	var c := _combat(["ids_sensor"], ["buffer_overflow"], TurnManager.MODE_NORMAL, 0)
	c.run.trace = 95
	c.play(c.hand[0])
	assert_eq(c.result, TurnManager.TRACED)


func test_proxy_chain_halves_next_three() -> void:
	var c := _combat(["firewall"], ["proxy_chain", "sql_injection"])
	c.defenders[0].blocked_type = ""
	c.play(c.hand[0])
	assert_eq(c.proxy_charges, 3)
	c.play(c.hand[0])
	assert_eq(c.noise, 2)
	assert_eq(c.proxy_charges, 2)


func test_privilege_escalation_doubles_next_damage() -> void:
	var c := _combat(["firewall"], ["privilege_escalation", "default_password"])
	c.defenders[0].blocked_type = ""
	c.play(c.hand[0])
	c.play(c.hand[0])
	assert_eq(c.defenders[0].integrity, 30 - 12)
	assert_false(c.double_next)


func test_firewall_blocks_type() -> void:
	var c := _combat(["firewall"], ["default_password"])
	c.defenders[0].blocked_type = "exploit"
	assert_false(c.play(c.hand[0]))
	assert_eq(c.hand.size(), 1)
	assert_eq(c.cpu, 10)


func test_edr_fizzles_repeat_and_adds_trace() -> void:
	var c := _combat(["edr_agent"], ["default_password", "default_password"])
	c.play(c.hand[0])
	c.play(c.hand[0])
	assert_eq(c.defenders[0].integrity, 12, "second copy did nothing")
	assert_eq(c.run.trace, TurnManager.FIZZLE_TRACE)
	assert_eq(c.cpu, 8, "CPU still spent")


func test_sysadmin_strips_buffs_and_phishing_distracts() -> void:
	var c := _combat(["sysadmin"], ["proxy_chain"])
	c.play(c.hand[0])
	c.end_turn()
	assert_eq(c.proxy_charges, 0)
	var d := _combat(["sysadmin"], ["phishing_email"])
	d.play(d.hand[0])
	assert_eq(d.defenders[0].integrity, 12)
	d.end_turn()
	assert_eq(d.noise, 1, "distracted sysadmin added no noise")


func test_phishing_is_weak_against_machines() -> void:
	var c := _combat(["antivirus"], ["phishing_email"])
	c.play(c.hand[0])
	assert_eq(c.defenders[0].integrity, 14)


func test_antivirus_quarantines_on_next_hand() -> void:
	var c := _combat(["antivirus"], [])
	var loud := DeckCard.new(Content.cards()["buffer_overflow"])
	var quiet := DeckCard.new(Content.cards()["log_wipe"])
	c.discard.assign([loud, quiet])
	c.end_turn()
	assert_false(loud in c.hand, "highest-noise card quarantined")
	assert_false(loud in c.discard)
	assert_true(quiet in c.hand)


func test_boss_rules_rotate_every_two_turns() -> void:
	var c := _combat(["perimeter_firewall"], [])
	assert_eq(c.defenders[0].active_rule, "deny_exploit")
	c.end_turn()
	assert_eq(c.defenders[0].active_rule, "deny_exploit")
	c.end_turn()
	assert_eq(c.defenders[0].active_rule, "rate_limit")
	c.end_turn()
	c.end_turn()
	assert_eq(c.defenders[0].active_rule, "deep_inspection")


func test_rate_limit_stops_third_card() -> void:
	var c := _combat(["perimeter_firewall"], ["log_wipe", "log_wipe", "log_wipe"])
	c.defenders[0].active_rule = "rate_limit"
	c.defenders[0].blocked_type = ""
	assert_true(c.play(c.hand[0]))
	assert_true(c.play(c.hand[0]))
	assert_false(c.play(c.hand[0]))


func test_exfil_upload_trace_and_cap() -> void:
	var c := _combat(PackedStringArray(), ["data_exfil", "data_exfil"], TurnManager.MODE_EXFIL)
	c.play(c.hand[0])
	assert_eq(c.upload, 20)
	assert_eq(c.run.data, 15)
	c.noise = 19
	c.play(c.hand[0])
	assert_eq(c.result, TurnManager.WON, "upload finishes before the cap matters")
	var d := _combat(PackedStringArray(), [], TurnManager.MODE_EXFIL)
	d.end_turn()
	assert_eq(d.run.trace, TurnManager.EXFIL_TRACE_PER_TURN)
	var e := _combat(PackedStringArray(), ["default_password"], TurnManager.MODE_EXFIL)
	e.noise = 19
	e.play(e.hand[0])
	assert_eq(e.upload, 6)
	assert_eq(e.noise, 0)
	assert_eq(e.run.trace, TurnManager.DETECTED_TRACE)
	assert_eq(e.result, "")


func test_thresholds_escalate_fights() -> void:
	var run := RunState.new(3)
	run.trace = 30
	assert_eq(TurnManager.new(run, ["firewall"]).defenders.size(), 2)
	run.trace = 55
	assert_ne(TurnManager.new(run, ["firewall"]).patched_type, "")
	run.trace = 80
	assert_eq(TurnManager.new(run, ["firewall"]).defenders.size(), 3)


func test_backdoor_grants_cpu_on_first_turn_only() -> void:
	var run := RunState.new(3)
	run.backdoor = true
	var c := TurnManager.new(run, ["firewall"])
	assert_eq(c.cpu, 4)
	c.end_turn()
	assert_eq(c.cpu, 3)


func test_upgrades_change_numbers() -> void:
	var card := DeckCard.new(Content.cards()["port_scan"], true)
	assert_eq(card.title(), "Stealth Scan")
	assert_eq(card.noise(), 0)
	var dp := DeckCard.new(Content.cards()["default_password"], true)
	assert_eq(dp.amount_of(0), 9)
