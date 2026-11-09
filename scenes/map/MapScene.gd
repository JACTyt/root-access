extends Control
## Top-down node graph. Row 0 sits at the bottom; the Exfil node at the top.

const NODE_SIZE := Vector2(52, 52)
const TOP_MARGIN := 70.0
const BOTTOM_MARGIN := 34.0
const SIDE_PANEL := 320.0
const PACKET_SPEED := 0.35

var _run: RunState
var _positions := {}
var _scan_mode := false
var _scan_button: Button
var _info: Label


func _ready() -> void:
	_run = GameState.run
	var fog := ShaderMaterial.new()
	fog.shader = load("res://shaders/fog.gdshader")
	var view := get_viewport_rect().size
	_layout(view)
	for n in _run.map.nodes:
		_add_node_button(n, fog)
	_build_panel(view)


func _layout(view: Vector2) -> void:
	var rows := _run.map.rows
	var usable_w := view.x - SIDE_PANEL
	var usable_h := view.y - TOP_MARGIN - BOTTOM_MARGIN
	for r in rows.size():
		var y := view.y - BOTTOM_MARGIN - usable_h * r / (rows.size() - 1)
		for c in rows[r].size():
			var x: float = usable_w * (c + 1) / (rows[r].size() + 1)
			_positions[rows[r][c]] = Vector2(x, y)


func _add_node_button(n: MapNode, fog: ShaderMaterial) -> void:
	var b := Button.new()
	var shown := n.revealed or n.cleared
	var color: Color = n.type_data().color if shown else UI.DIM
	b.text = n.type_data().glyph if shown else "?"
	b.size = NODE_SIZE
	b.position = _positions[n.id] - NODE_SIZE / 2.0
	var available: bool = n.id in _run.available_moves()
	var border_color: Color = UI.GREEN if available else color
	b.add_theme_stylebox_override("normal", UI.border(border_color, Color(0.04, 0.06, 0.07), 3 if available else 1))
	b.add_theme_stylebox_override("hover", UI.border(Color.WHITE, Color(0.08, 0.14, 0.13), 2))
	b.add_theme_stylebox_override("disabled", UI.border(color * Color(1, 1, 1, 0.5), Color(0.03, 0.04, 0.05)))
	b.add_theme_color_override("font_color", color)
	b.add_theme_color_override("font_disabled_color", color * Color(1, 1, 1, 0.6))
	b.disabled = n.cleared or n.id == _run.current_id
	b.pressed.connect(_on_node_pressed.bind(n.id))
	b.mouse_entered.connect(_show_info.bind(n.id))
	add_child(b)
	if not shown:
		var cloud := ColorRect.new()
		cloud.material = fog
		cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cloud.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.add_child(cloud)


func _build_panel(view: Vector2) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(view.x - SIDE_PANEL + 10.0, TOP_MARGIN)
	panel.custom_minimum_size = Vector2(SIDE_PANEL - 24.0, view.y - TOP_MARGIN - 20.0)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	col.add_child(UI.label("HALCYON MERIDIAN / DMZ", 13, UI.DIM))
	_scan_button = UI.button("", _toggle_scan)
	col.add_child(_scan_button)
	_refresh_scan_label()
	_info = UI.wrapped("Hover a node. Green outlines are reachable.", 13)
	_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_info)
	col.add_child(UI.button("Codex", func(): EventBus.goto_screen.emit("codex", {"from": "map"})))


func _toggle_scan() -> void:
	_scan_mode = not _scan_mode and _run.scans > 0
	_refresh_scan_label()


func _refresh_scan_label() -> void:
	_scan_button.text = "Scan: click a node (%d)" % _run.scans if _scan_mode else "Use Scan (%d)" % _run.scans


func _on_node_pressed(id: int) -> void:
	if _scan_mode:
		if _run.spend_scan(id):
			AudioManager.play_sfx("chirp")
			EventBus.goto_screen.emit("map", {})
		return
	if not id in _run.available_moves():
		EventBus.toast.emit("No route to that host")
	elif not _run.can_cross(id):
		EventBus.toast.emit("Firewalled: need %s or a Credential" % _gate_name(id))
	else:
		GameState.choose_node(id)


func _gate_name(id: int) -> String:
	return Content.cards()[_run.gate_card(id)].display_name


func _show_info(id: int) -> void:
	var n := _run.map.node(id)
	var lines := []
	if n.revealed or n.cleared:
		lines.append(n.type_data().display_name)
		for d in n.defenders:
			lines.append("  defender: %s" % Content.defenders()[d].display_name)
		if n.type_data().data_max > 0:
			lines.append("  loot: %d-%d Data" % [n.type_data().data_min, n.type_data().data_max])
		if n.type == "honeypot":
			lines.append("  TRAP: Trace +%d" % RunState.HONEYPOT_TRACE)
	else:
		lines.append("Unknown host. Scan to reveal it.")
	if id in _run.available_moves() and _run.gate_card(id) != "":
		lines.append("Firewalled edge: needs %s in your deck, or 1 Credential." % _gate_name(id))
	_info.text = "\n".join(lines)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for n in _run.map.nodes:
		for target in n.next:
			var from: Vector2 = _positions[n.id]
			var to: Vector2 = _positions[target]
			var active: bool = n.id == _run.current_id
			var gated: bool = n.gates.has(target)
			var color := UI.AMBER if gated else (UI.GREEN if active else UI.DIM * Color(1, 1, 1, 0.45))
			draw_line(from, to, color, 2.0 if active else 1.0, true)
			if active:
				var f := fmod(t * PACKET_SPEED + target * 0.27, 1.0)
				draw_circle(from.lerp(to, f), 3.0, UI.GREEN)
	if _run.current_id < 0:
		for id in _run.map.start_ids():
			var at: Vector2 = _positions[id]
			var pulse := fmod(t * PACKET_SPEED, 1.0)
			draw_circle(at + Vector2(0, 26.0 + 8.0 * (1.0 - pulse)), 3.0, UI.GREEN)
