extends Control
## Result screen with Blue team notes: which defenses would have stopped this path.


func _ready() -> void:
	var run := GameState.run
	var col := UI.centered_column(self, 820)
	if run.won:
		col.add_child(UI.label("DATA EXFILTRATED", 34, UI.GREEN))
	else:
		col.add_child(UI.label("TRACED", 34, UI.RED))
	col.add_child(UI.label("Final Trace %d%%   Data %d   Seed %d" % [run.trace, run.data, run.map_seed], 15))
	col.add_child(UI.label("BLUE TEAM NOTES: what would have stopped you", 15, UI.AMBER))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 340
	col.add_child(scroll)
	var notes := VBoxContainer.new()
	notes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(notes)
	var used: Array = run.cards_used.keys()
	used.sort_custom(func(a, b): return run.cards_used[a] > run.cards_used[b])
	for id in used:
		var card: CardData = Content.cards()[id]
		notes.add_child(UI.wrapped("%s x%d: %s" % [card.display_name, run.cards_used[id], card.codex_defense], 13))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	row.add_child(UI.button("New breach", func(): GameState.start_run(GameState.random_seed())))
	row.add_child(UI.button("Same seed", func(): GameState.start_run(run.map_seed)))
	row.add_child(UI.button("Main menu", func(): EventBus.goto_screen.emit("menu", {})))
