extends Control

const CARD_SCENE := preload("res://scenes/ui/Card.tscn")


func setup(args: Dictionary) -> void:
	var run := GameState.run
	var col := UI.centered_column(self, 700)
	col.add_child(UI.label("HOST COMPROMISED", 28, UI.GREEN))
	col.add_child(UI.label("+%d Data. Choose one card for your deck." % args.get("data", 0), 15))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	for data in run.reward_choices():
		var view = CARD_SCENE.instantiate()
		row.add_child(view)
		var card := DeckCard.new(data)
		view.bind(card)
		view.clicked.connect(func():
			run.deck.append(card)
			GameState.after_node())
	col.add_child(UI.button("Skip", GameState.after_node))
