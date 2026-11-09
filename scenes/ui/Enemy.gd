extends PanelContainer
## Defender view: integrity, intent and targeting.

signal selected

var state: DefenderState
var _bar: ProgressBar
var _intent: Label
var _integrity: Label
var _selected := false


func bind(defender: DefenderState) -> void:
	state = defender
	SaveManager.mark_seen(state.data.id)
	custom_minimum_size = Vector2(220, 120)
	var color := UI.AMBER if state.data.is_human else UI.RED
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	col.add_child(UI.label(state.data.display_name, 17, color))
	_integrity = UI.label("", 12)
	col.add_child(_integrity)
	_bar = UI.bar(state.data.max_integrity, color)
	col.add_child(_bar)
	_intent = UI.wrapped("", 12, UI.AMBER)
	col.add_child(_intent)
	tooltip_text = state.data.description


func refresh(combat: TurnManager, is_target: bool) -> void:
	_selected = is_target
	_bar.value = state.integrity
	_integrity.text = "integrity %d/%d" % [state.integrity, state.data.max_integrity]
	_intent.text = combat.intent_text(state)
	var color := UI.GREEN if is_target and state.is_alive() else (UI.AMBER if state.data.is_human else UI.RED)
	add_theme_stylebox_override("panel", UI.border(color, Color(0.07, 0.05, 0.06, 0.95), 2 if is_target else 1))
	modulate.a = 1.0 if state.is_alive() else 0.35


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected.emit()
