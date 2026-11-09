extends Control

var _seed_input: LineEdit


func _ready() -> void:
	add_child(Backdrop.new("desk"))
	var col := UI.centered_column(self, 420)
	col.add_child(UI.label("ROOT ACCESS", 46, UI.GREEN))
	col.add_child(UI.wrapped("Breach the network, grab the data, get out before the trace hits 100%.", 14))
	col.add_child(UI.button("New breach", _start))
	_seed_input = LineEdit.new()
	_seed_input.placeholder_text = "Seed (blank = random)"
	col.add_child(_seed_input)
	col.add_child(UI.button("Codex", func(): EventBus.goto_screen.emit("codex", {"from": "menu"})))
	var crt := CheckBox.new()
	crt.text = "CRT effect"
	crt.button_pressed = SaveManager.crt_enabled()
	crt.toggled.connect(SaveManager.set_crt_enabled)
	col.add_child(crt)
	col.add_child(UI.label("Volume", 13, UI.DIM))
	var volume := HSlider.new()
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = SaveManager.volume()
	volume.value_changed.connect(SaveManager.set_volume)
	col.add_child(volume)


func _start() -> void:
	var text := _seed_input.text.strip_edges()
	GameState.start_run(int(text) if text.is_valid_int() else GameState.random_seed())
