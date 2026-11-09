extends SceneTree
## Headless balance check, no autoloads or UI required:
## godot --headless -s res://tools/simulate.gd -- --runs=500
## Plays whole runs with a simple greedy policy and reports outliers.

const MAX_TURNS_PER_FIGHT := 40


func _init() -> void:
	var runs := 200
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="):
			runs = int(arg.trim_prefix("--runs="))
	var wins := 0
	var trace_total := 0
	var fights := 0
	var detections := 0
	var noise_total := 0
	var furthest := {}
	for i in runs:
		var stats := _play_run(i)
		wins += 1 if stats.won else 0
		trace_total += stats.trace
		fights += stats.fights
		detections += stats.detected
		noise_total += stats.noise
		furthest[stats.row] = furthest.get(stats.row, 0) + 1
	print("runs=%d win_rate=%.1f%% avg_final_trace=%.1f avg_fights=%.1f avg_detections=%.2f avg_noise_per_fight=%.1f" % [
		runs, 100.0 * wins / runs, float(trace_total) / runs, float(fights) / runs,
		float(detections) / runs, float(noise_total) / maxi(fights, 1)])
	print("furthest row reached (8 = exfil): ", furthest)
	quit()


func _play_run(run_seed: int) -> Dictionary:
	var run := RunState.new(run_seed)
	var stats := {"won": false, "trace": 0, "fights": 0, "detected": 0, "noise": 0, "row": 0}
	while not run.is_traced() and not run.won:
		var target := _pick_move(run)
		run.begin_move(target)
		stats.row = maxi(stats.row, run.map.node(target).row + 1)
		var type := run.map.node(target).type_data()
		match type.role:
			"encounter", "boss", "exfil":
				var mode := TurnManager.MODE_NORMAL
				if type.role == "boss":
					mode = TurnManager.MODE_BOSS
				elif type.role == "exfil":
					mode = TurnManager.MODE_EXFIL
				var outcome := _fight(run, run.map.node(target).defenders, mode, stats)
				if outcome == TurnManager.WON:
					if mode == TurnManager.MODE_EXFIL:
						run.won = true
					else:
						run.data += run.roll_data(type)
						run.complete_move()
						_take_reward(run)
				else:
					run.abort_move()
			"honeypot":
				run.complete_move()
				run.add_trace(RunState.HONEYPOT_TRACE)
			"safehouse":
				run.add_trace(-RunState.SAFEHOUSE_TRACE_RELIEF)
				run.complete_move()
			_:
				run.complete_move()
	stats.won = run.won
	stats.trace = run.trace
	return stats


func _pick_move(run: RunState) -> int:
	var moves: Array = run.available_moves()
	var best: int = -1
	for id in moves:
		if not run.can_cross(id):
			continue
		if run.map.node(id).type == "honeypot" and run.scans > 0:
			continue
		if best < 0 or run.rng.randf() < 0.5:
			best = id
	return best if best >= 0 else moves[0]


func _take_reward(run: RunState) -> void:
	var choices := run.reward_choices()
	run.deck.append(DeckCard.new(choices[0]))


func _fight(run: RunState, defenders: PackedStringArray, mode: String, stats: Dictionary) -> String:
	var combat := TurnManager.new(run, defenders, mode)
	stats.fights += 1
	for t in MAX_TURNS_PER_FIGHT:
		while combat.result == "":
			var card := _best_card(combat)
			if card == null:
				break
			combat.play(card, null)
		if combat.result != "":
			break
		if combat.noise >= TurnManager.NOISE_CAP - 3 and mode != TurnManager.MODE_EXFIL:
			combat.disconnect_from_host()
			break
		combat.end_turn()
		if combat.result != "":
			break
	if combat.result == "":
		combat.disconnect_from_host()
	if combat.result == TurnManager.DETECTED:
		stats.detected += 1
	stats.noise += combat.noise
	return combat.result


## Greedy: prefer the most damage per noise that fits in remaining CPU.
func _best_card(combat: TurnManager) -> DeckCard:
	var best: DeckCard = null
	var best_score := -INF
	for card in combat.hand:
		if combat.play_block_reason(card) != "":
			continue
		var score := 1.0 - 0.3 * combat.noise_for(card)
		for i in card.data.effects.size():
			var kind: String = card.data.effects[i].kind
			if kind == "damage" or kind == "upload":
				score += card.amount_of(i)
			elif kind == "reduce_noise":
				score += 3.0 if combat.noise >= 6 else -2.0
		if score > best_score:
			best_score = score
			best = card
	return best
