extends Control

var _run: RunState


func _ready() -> void:
	_run = GameState.run
	var ids := Content.sorted_ids(Content.events())
	var event: EventData = Content.events()[ids[_run.rng.randi() % ids.size()]]
	var col := UI.centered_column(self, 640)
	col.add_child(UI.label(event.title.to_upper(), 26, UI.AMBER))
	col.add_child(UI.wrapped(event.text, 15))
	for i in event.choices.size():
		var outcome: String = event.outcomes[i]
		var b := UI.button(event.choices[i], _choose.bind(outcome))
		b.disabled = not _run.can_afford_outcome(outcome)
		col.add_child(b)


func _choose(outcome: String) -> void:
	_run.apply_outcome(outcome)
	_run.complete_move()
	GameState.after_node()
