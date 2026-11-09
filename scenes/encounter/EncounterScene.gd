extends Control
## View over a TurnManager: all rules live there, this only displays and forwards input.

const ENEMY_SCENE := preload("res://scenes/ui/Enemy.tscn")
const RESOLVE_DELAY := 0.8
const LOG_LINES := 6
const TUTORIAL: Array[String] = [
	"Cards cost CPU. You get 3 each turn; unplayed cards are discarded when you end the turn.",
	"Every card adds Noise. Defenders add more each turn. Noise 20 means you're Detected: Trace +15 and you're kicked back.",
	"Win by taking every defender's Integrity to 0. Leftover Noise becomes Trace, so stay quiet. Trace 100% ends the run.",
	"Intents show ??? until you play a Recon card. Recon also banks Scans for the map.",
]

var _combat: TurnManager
var _target: DefenderState
var _enemies := []
var _hand: Hand
var _noise_bar: ProgressBar
var _status: Label
var _log: Label
var _log_lines: Array[String] = []
var _end_turn: Button
var _disconnect: Button
var _upload_bar: ProgressBar
var _tutorial: PanelContainer
var _tutorial_step := 0


func _ready() -> void:
	_combat = GameState.combat
	add_child(Backdrop.new("racks", UI.RED if _combat.mode != TurnManager.MODE_EXFIL else UI.GREEN))
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_top = 56.0
	root.offset_left = 16.0
	root.offset_right = -16.0
	root.offset_bottom = -10.0
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	root.add_child(_build_enemies())
	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 16)
	root.add_child(middle)
	_log = UI.wrapped("", 12, UI.DIM)
	_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(_log)
	middle.add_child(_build_status())
	_hand = Hand.new()
	_hand.card_clicked.connect(_on_card_clicked)
	root.add_child(_hand)
	_combat.changed.connect(_refresh)
	_combat.logged.connect(_add_log)
	_combat.finished.connect(_on_finished)
	_target = _combat.alive()[0] if not _combat.alive().is_empty() else null
	_refresh()
	if not SaveManager.tutorial_done():
		_show_tutorial()


func _build_enemies() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	if _combat.mode == TurnManager.MODE_EXFIL:
		var col := VBoxContainer.new()
		col.add_child(UI.label("UPLOADING TARGET DATA", 20, UI.GREEN))
		_upload_bar = UI.bar(TurnManager.UPLOAD_GOAL, UI.GREEN)
		_upload_bar.custom_minimum_size = Vector2(520, 24)
		col.add_child(_upload_bar)
		col.add_child(UI.label("Damage cards count as upload. Trace +%d each turn." % TurnManager.EXFIL_TRACE_PER_TURN, 13))
		row.add_child(col)
	for d in _combat.defenders:
		var view = ENEMY_SCENE.instantiate()
		row.add_child(view)
		view.bind(d)
		view.selected.connect(func():
			if d.is_alive():
				_target = d
				_refresh())
		_enemies.append(view)
	return row


func _build_status() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 300
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	_status = UI.wrapped("", 14)
	col.add_child(_status)
	col.add_child(UI.label("NOISE (cap %d)" % TurnManager.NOISE_CAP, 12, UI.AMBER))
	_noise_bar = UI.bar(TurnManager.NOISE_CAP, UI.AMBER)
	col.add_child(_noise_bar)
	_end_turn = UI.button("End turn", func(): _combat.end_turn())
	col.add_child(_end_turn)
	_disconnect = UI.button("Disconnect (Trace +%d)" % TurnManager.DISCONNECT_TRACE, func(): _combat.disconnect_from_host())
	_disconnect.visible = _combat.mode != TurnManager.MODE_EXFIL
	col.add_child(_disconnect)
	return panel


func _refresh() -> void:
	if _target == null or not _target.is_alive():
		var living := _combat.alive()
		_target = living[0] if not living.is_empty() else null
	for view in _enemies:
		view.refresh(_combat, view.state == _target)
	_noise_bar.value = _combat.noise
	if _upload_bar != null:
		_upload_bar.value = _combat.upload
	var buffs := []
	if _combat.proxy_charges > 0:
		buffs.append("proxy x%d" % _combat.proxy_charges)
	if _combat.double_next:
		buffs.append("next damage x2")
	if _combat.patched_type != "":
		buffs.append("%s PATCHED (half effect)" % _combat.patched_type)
	_status.text = "CPU %d/%d   TURN %d\nNOISE %d   DRAW %d   DISCARD %d\n%s" % [
		_combat.cpu, TurnManager.BASE_CPU, _combat.turn, _combat.noise,
		_combat.draw_pile.size(), _combat.discard.size(), "  ".join(buffs)]
	_hand.show_cards(_combat)
	var over := _combat.result != ""
	_end_turn.disabled = over
	_disconnect.disabled = over
	EventBus.hud_refresh.emit()


func _on_card_clicked(card: DeckCard) -> void:
	var reason := _combat.play_block_reason(card)
	if reason != "":
		EventBus.toast.emit(reason)
		return
	AudioManager.play_sfx("click")
	var id := card.data.id
	if _combat.play(card, _target):
		EventBus.card_played.emit(id)


func _add_log(line: String) -> void:
	_log_lines.append("> " + line)
	if _log_lines.size() > LOG_LINES:
		_log_lines.remove_at(0)
	_log.text = "\n".join(_log_lines)


func _on_finished(result: String) -> void:
	match result:
		TurnManager.WON:
			AudioManager.play_sfx("win")
		TurnManager.DETECTED:
			AudioManager.play_sfx("alarm")
			EventBus.toast.emit("DETECTED! Trace +%d" % TurnManager.DETECTED_TRACE)
		TurnManager.TRACED:
			AudioManager.play_sfx("alarm")
	get_tree().create_timer(RESOLVE_DELAY).timeout.connect(GameState.resolve_combat)


func _show_tutorial() -> void:
	_tutorial = PanelContainer.new()
	_tutorial.custom_minimum_size = Vector2(520, 130)
	_tutorial.position = get_viewport_rect().size / 2.0 - Vector2(260, 160)
	add_child(_tutorial)
	_next_tutorial_step()


func _next_tutorial_step() -> void:
	for child in _tutorial.get_children():
		child.queue_free()
	if _tutorial_step >= TUTORIAL.size():
		_tutorial.queue_free()
		SaveManager.set_tutorial_done()
		return
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.add_child(UI.wrapped(TUTORIAL[_tutorial_step], 15))
	col.add_child(UI.button("Got it", _next_tutorial_step))
	_tutorial.add_child(col)
	_tutorial_step += 1
