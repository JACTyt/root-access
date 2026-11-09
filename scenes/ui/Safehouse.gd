extends Control

var _run: RunState


func _ready() -> void:
	_run = GameState.run
	var col := UI.centered_column(self, 760)
	col.add_child(UI.label("SAFEHOUSE", 28, UI.GREEN))
	col.add_child(UI.label("Lie low or sharpen a tool. You have time for one.", 15))
	col.add_child(UI.button("Lie low: Trace -%d" % RunState.SAFEHOUSE_TRACE_RELIEF, _rest))
	col.add_child(UI.label("Upgrade a card:", 13, UI.DIM))
	var flow := HFlowContainer.new()
	col.add_child(flow)
	for card in _run.deck:
		if not card.upgraded:
			var b := UI.button("%s > %s" % [card.title(), card.data.upgraded_name], _upgrade.bind(card))
			b.tooltip_text = card.data.upgraded_description
			flow.add_child(b)


func _rest() -> void:
	_run.add_trace(-RunState.SAFEHOUSE_TRACE_RELIEF)
	_leave()


func _upgrade(card: DeckCard) -> void:
	card.upgraded = true
	_leave()


func _leave() -> void:
	_run.complete_move()
	GameState.after_node()
