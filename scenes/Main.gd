extends Control
## Root: swaps screens, owns the HUD, toasts and post-processing overlays.

const SCREENS := {
	"menu": "res://scenes/ui/MainMenu.tscn",
	"map": "res://scenes/map/MapScene.tscn",
	"encounter": "res://scenes/encounter/EncounterScene.tscn",
	"reward": "res://scenes/ui/Reward.tscn",
	"shop": "res://scenes/ui/Shop.tscn",
	"safehouse": "res://scenes/ui/Safehouse.tscn",
	"event": "res://scenes/ui/Event.tscn",
	"end": "res://scenes/ui/RunEnd.tscn",
	"codex": "res://scenes/ui/Codex.tscn",
}
const HUD_HEIGHT := 48.0
const SHAKE_PIXELS := 10.0

var _content: Control
var _hud: Control
var _toast: Label
var _glitch: ShaderMaterial
var _crt_layer: CanvasLayer
var _shake := 0.0
var _flash := 0.0


func _ready() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = UI.BG
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_content)
	_hud = load("res://scenes/ui/TraceMeter.tscn").instantiate()
	_hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	add_child(_hud)
	_toast = UI.label("", 22, UI.RED)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.position.y = 60
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_toast)
	_build_overlays()
	EventBus.goto_screen.connect(_goto)
	EventBus.toast.connect(_show_toast)
	EventBus.trace_changed.connect(_on_trace)
	EventBus.threshold_crossed.connect(_on_threshold)
	EventBus.settings_changed.connect(_apply_settings)
	_apply_settings()
	_goto("menu", {})


func _build_overlays() -> void:
	var glitch_layer := CanvasLayer.new()
	glitch_layer.layer = 90
	add_child(glitch_layer)
	_glitch = ShaderMaterial.new()
	_glitch.shader = load("res://shaders/glitch.gdshader")
	glitch_layer.add_child(_overlay_rect(_glitch))
	_crt_layer = CanvasLayer.new()
	_crt_layer.layer = 91
	add_child(_crt_layer)
	var copy := BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	_crt_layer.add_child(copy)
	var crt := ShaderMaterial.new()
	crt.shader = load("res://shaders/crt.gdshader")
	_crt_layer.add_child(_overlay_rect(crt))


func _overlay_rect(material_to_use: ShaderMaterial) -> ColorRect:
	var rect := ColorRect.new()
	rect.material = material_to_use
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	return rect


func _process(delta: float) -> void:
	_shake = move_toward(_shake, 0.0, delta * 2.5)
	_flash = move_toward(_flash, 0.0, delta * 1.5)
	var offset := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * SHAKE_PIXELS
	_content.position = offset
	_glitch.set_shader_parameter("flash", _flash)


func _goto(screen: String, args: Dictionary) -> void:
	for child in _content.get_children():
		child.queue_free()
	var view: Node = load(SCREENS[screen]).instantiate()
	_content.add_child(view)
	if view.has_method("setup"):
		view.call("setup", args)
	var in_run := GameState.run != null and screen in ["map", "encounter", "reward", "shop", "safehouse", "event"]
	_hud.visible = in_run
	_content.offset_top = 0.0
	if in_run:
		EventBus.hud_refresh.emit()


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func _on_trace(value: int, _previous: int) -> void:
	_glitch.set_shader_parameter("intensity", value / 100.0)
	EventBus.hud_refresh.emit()


func _on_threshold(threshold: int) -> void:
	_shake = 1.0
	_flash = 1.0
	_show_toast("TRACE %d%%" % threshold)


func _apply_settings() -> void:
	_crt_layer.visible = SaveManager.crt_enabled()
