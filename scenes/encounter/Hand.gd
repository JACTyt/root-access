class_name Hand
extends HBoxContainer
## Renders the current hand and reports which card was clicked.

signal card_clicked(card: DeckCard)

const CARD_SCENE := preload("res://scenes/ui/Card.tscn")


func _init() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 8)


func show_cards(combat: TurnManager) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for card in combat.hand:
		var view = CARD_SCENE.instantiate()
		add_child(view)
		var reason := combat.play_block_reason(card)
		view.bind(card, reason == "", combat.noise_for(card))
		view.tooltip_text = reason
		view.clicked.connect(func(): card_clicked.emit(card))
