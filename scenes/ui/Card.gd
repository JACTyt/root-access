extends PanelContainer
## Reusable card view bound to a DeckCard.

signal clicked

const SIZE := Vector2(158, 196)

var card: DeckCard


func bind(deck_card: DeckCard, enabled := true, noise_override := -1) -> void:
	card = deck_card
	SaveManager.mark_seen(card.data.id)
	custom_minimum_size = SIZE
	var color := UI.type_color(card.data.type)
	add_theme_stylebox_override("panel", UI.border(color if enabled else UI.DIM))
	modulate = Color.WHITE if enabled else Color(0.65, 0.65, 0.65)
	var noise := card.noise() if noise_override < 0 else noise_override
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	col.add_child(UI.label("%d CPU   %d NOISE" % [card.cost(), noise], 12, UI.AMBER if noise > card.noise() else UI.DIM))
	col.add_child(UI.wrapped(card.title(), 15, color))
	col.add_child(UI.label(card.data.type.to_upper(), 11, UI.DIM))
	col.add_child(UI.wrapped(card.description(), 12))
	for child in col.get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		child.custom_minimum_size.x = SIZE.x - 18.0
	mouse_entered.connect(func(): position.y -= 8)
	mouse_exited.connect(func(): position.y += 8)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
