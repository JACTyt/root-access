extends PanelContainer
## Always-visible HUD: Trace with thresholds, plus run resources.

var _bar: ProgressBar
var _fill: StyleBoxFlat
var _value: Label
var _stats: Label


func _ready() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	add_child(row)
	row.add_child(UI.label("TRACE", 15, UI.RED))
	_bar = UI.bar(RunState.MAX_TRACE, UI.AMBER)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.custom_minimum_size.y = 20
	_fill = _bar.get_theme_stylebox("fill") as StyleBoxFlat
	row.add_child(_bar)
	_value = UI.label("0%", 15, UI.RED)
	row.add_child(_value)
	_stats = UI.label("", 13)
	row.add_child(_stats)
	EventBus.hud_refresh.connect(_refresh)


func _refresh() -> void:
	var run := GameState.run
	if run == null:
		return
	_bar.value = run.trace
	_value.text = "%d%%" % run.trace
	_fill.bg_color = [UI.GREEN, UI.AMBER, UI.AMBER, UI.RED][run.tier()]
	_stats.text = "DATA %d   CREDS %d   SCANS %d   DECK %d   SEED %d" % [run.data, run.credentials, run.scans, run.deck.size(), run.map_seed]
