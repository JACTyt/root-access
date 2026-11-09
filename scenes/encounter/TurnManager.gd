class_name TurnManager
extends RefCounted
## Combat rules with no UI: the encounter scene, tests and simulator all drive this.

signal changed
signal logged(line: String)
signal finished(result: String)

const MODE_NORMAL := "normal"
const MODE_BOSS := "boss"
const MODE_EXFIL := "exfil"
const WON := "won"
const DETECTED := "detected"
const DISCONNECTED := "disconnected"
const TRACED := "traced"

const BASE_CPU := 3
const HAND_SIZE := 5
const NOISE_CAP := 20
const DETECTED_TRACE := 15
const DISCONNECT_TRACE := 8
const FIZZLE_TRACE := 2
const UPLOAD_GOAL := 40
const EXFIL_TRACE_PER_TURN := 3
const RATE_LIMIT := 2
const BOSS_RULE_TURNS := 2
const BLOCKABLE: Array[String] = ["exploit", "exploit", "stealth", "recon"]
const PATCHABLE: Array[String] = ["recon", "exploit", "stealth"]

var run: RunState
var mode := MODE_NORMAL
var defenders: Array[DefenderState] = []
var draw_pile: Array[DeckCard] = []
var hand: Array[DeckCard] = []
var discard: Array[DeckCard] = []
var cpu := 0
var noise := 0
var turn := 0
var upload := 0
var intents_revealed := false
var proxy_charges := 0
var double_next := false
var cards_played := 0
var cards_this_turn := 0
var last_card_id := ""
var patched_type := ""
var quarantine_pending := 0
var result := ""


func _init(run_state: RunState, defender_ids: PackedStringArray, combat_mode := MODE_NORMAL) -> void:
	run = run_state
	mode = combat_mode
	intents_revealed = mode == MODE_BOSS
	var ids := Array(defender_ids)
	if mode == MODE_NORMAL:
		if run.tier() >= 1:
			ids.append("ids_sensor")
		if run.tier() >= 3:
			ids.append(_random_normal_defender())
	if run.tier() >= 2 and mode != MODE_EXFIL:
		patched_type = PATCHABLE[run.rng.randi() % PATCHABLE.size()]
	for id in ids:
		defenders.append(DefenderState.new(Content.defenders()[id]))
		run.defenders_met[id] = true
	draw_pile.assign(run.deck)
	run.shuffle(draw_pile)
	_begin_turn()


func _random_normal_defender() -> String:
	var pool := []
	for id in Content.sorted_ids(Content.defenders()):
		if not Content.defenders()[id].is_boss:
			pool.append(id)
	return pool[run.rng.randi() % pool.size()]


func alive() -> Array[DefenderState]:
	var living: Array[DefenderState] = []
	for d in defenders:
		if d.is_alive():
			living.append(d)
	return living


func _has_behavior(behavior: String) -> bool:
	for d in alive():
		if d.data.behavior == behavior:
			return true
	return false


func _active_rule() -> String:
	for d in alive():
		if d.active_rule != "":
			return d.active_rule
	return ""


## Noise this card would add right now, with Proxy Chain, IDS and boss rules applied.
func noise_for(card: DeckCard) -> int:
	var value := card.noise()
	if proxy_charges > 0:
		value = ceili(value / 2.0)
	if _active_rule() == "deep_inspection":
		value += 1
	if _has_behavior("double_noise"):
		value *= 2
	return value


## Empty when playable, otherwise the reason it can't be played.
func play_block_reason(card: DeckCard) -> String:
	if result != "":
		return "Encounter over"
	if card.cost() > cpu:
		return "Not enough CPU"
	if _active_rule() == "rate_limit" and cards_this_turn >= RATE_LIMIT:
		return "Rate limited: 2 cards per turn"
	for d in alive():
		if d.blocked_type == card.data.type:
			return "Connection refused by %s" % d.data.display_name
	return ""


func play(card: DeckCard, target: DefenderState = null) -> bool:
	if not card in hand or play_block_reason(card) != "":
		return false
	if target == null or not target.is_alive():
		var living := alive()
		target = living[0] if not living.is_empty() else null
	hand.erase(card)
	cpu -= card.cost()
	run.cards_used[card.data.id] = run.cards_used.get(card.data.id, 0) + 1
	if _has_behavior("learn") and last_card_id == card.data.id:
		logged.emit("%s fizzled: the EDR agent learned that pattern" % card.title())
		discard.append(card)
		run.add_trace(FIZZLE_TRACE)
		_check_end()
		changed.emit()
		return true
	# Noise is priced before effects: killing the IDS with this card doesn't refund it.
	var added := noise_for(card)
	EffectResolver.play(self, card, target)
	if proxy_charges > 0 and card.data.effects[0].kind != "half_noise_next":
		proxy_charges -= 1
	noise += added
	last_card_id = card.data.id
	cards_played += 1
	cards_this_turn += 1
	discard.append(card)
	logged.emit("%s  (+%d noise)" % [card.title(), added])
	_check_end()
	changed.emit()
	return true


func deal_damage(target: DefenderState, amount: int) -> void:
	if double_next:
		amount *= 2
		double_next = false
	if mode == MODE_EXFIL:
		upload += amount
	elif target != null:
		target.integrity = maxi(target.integrity - amount, 0)
		if not target.is_alive():
			logged.emit("%s is down" % target.data.display_name)


func draw_cards(count: int) -> void:
	for i in count:
		if draw_pile.is_empty():
			if discard.is_empty():
				return
			draw_pile.assign(discard)
			discard.clear()
			run.shuffle(draw_pile)
		hand.append(draw_pile.pop_back())


func end_turn() -> void:
	if result != "":
		return
	discard.append_array(hand)
	hand.clear()
	for d in alive():
		_defender_act(d)
	if mode == MODE_EXFIL:
		run.add_trace(EXFIL_TRACE_PER_TURN)
	_check_end()
	if result == "":
		_begin_turn()
	changed.emit()


func disconnect_from_host() -> void:
	if mode != MODE_EXFIL and result == "":
		_finish(DISCONNECTED)
		changed.emit()


func _defender_act(d: DefenderState) -> void:
	if d.distracted > 0:
		d.distracted -= 1
		logged.emit("%s is distracted" % d.data.display_name)
		return
	noise += d.data.attack_noise
	match d.data.behavior:
		"strip_buffs":
			if proxy_charges > 0 or double_next:
				logged.emit("%s patched out your buffs" % d.data.display_name)
			proxy_charges = 0
			double_next = false
		"quarantine":
			# The hand is empty now; the scan lands on the next hand drawn.
			quarantine_pending += 1


func _begin_turn() -> void:
	turn += 1
	cpu = BASE_CPU
	if turn == 1 and run.backdoor:
		cpu += 1
	cards_this_turn = 0
	draw_cards(HAND_SIZE)
	for i in quarantine_pending:
		_quarantine_highest_noise()
	quarantine_pending = 0
	for d in alive():
		_plan_defender(d)


func _plan_defender(d: DefenderState) -> void:
	d.blocked_type = ""
	match d.data.behavior:
		"block_type":
			d.blocked_type = BLOCKABLE[run.rng.randi() % BLOCKABLE.size()]
		"rule_sets":
			var index := int((turn - 1) / BOSS_RULE_TURNS) % d.data.rules.size()
			d.active_rule = d.data.rules[index]
			if d.active_rule == "deny_exploit":
				d.blocked_type = "exploit"


func _quarantine_highest_noise() -> void:
	if hand.is_empty():
		return
	var worst: DeckCard = hand[0]
	for c in hand:
		if c.noise() > worst.noise():
			worst = c
	hand.erase(worst)
	logged.emit("Antivirus quarantined %s for this fight" % worst.title())


func intent_text(d: DefenderState) -> String:
	if not d.is_alive():
		return "offline"
	if not intents_revealed:
		return "???"
	if d.distracted > 0:
		return "Distracted (%d)" % d.distracted
	var line := "+%d noise" % d.data.attack_noise
	match d.data.behavior:
		"block_type": line += ", blocks %s" % d.blocked_type
		"quarantine": line += ", quarantines a card"
		"strip_buffs": line += ", strips buffs"
		"rule_sets": line += ", rule: %s" % d.active_rule.replace("_", " ")
	return line


func _check_end() -> void:
	if result != "":
		return
	if run.is_traced():
		_finish(TRACED)
	elif mode == MODE_EXFIL:
		if upload >= UPLOAD_GOAL:
			_finish(WON)
		elif noise >= NOISE_CAP:
			run.add_trace(DETECTED_TRACE)
			noise = 0
			logged.emit("Detected! Trace +%d" % DETECTED_TRACE)
			if run.is_traced():
				_finish(TRACED)
	elif alive().is_empty():
		_finish(WON)
	elif noise >= NOISE_CAP:
		_finish(DETECTED)


func _finish(outcome: String) -> void:
	match outcome:
		WON:
			if mode != MODE_EXFIL:
				run.add_trace(noise)
		DETECTED:
			run.add_trace(DETECTED_TRACE)
		DISCONNECTED:
			run.add_trace(DISCONNECT_TRACE)
	result = TRACED if run.is_traced() else outcome
	finished.emit(result)
