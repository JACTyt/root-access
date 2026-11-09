class_name Backdrop
extends Control
## Cheap 2.5D: rack and monitor layers drawn in code that drift with the mouse.

const LAYERS := 3
const RACKS_PER_LAYER := 9

## "racks" for the encounter, "desk" for the main menu.
var style := "racks"
var tint := UI.GREEN


func _init(backdrop_style := "racks", backdrop_tint := UI.GREEN) -> void:
	style = backdrop_style
	tint = backdrop_tint
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var view := get_viewport_rect().size
	var drift := (get_viewport().get_mouse_position() - view / 2.0) / view
	if style == "desk":
		_draw_desk(view, drift)
	else:
		_draw_racks(view, drift)


func _draw_racks(view: Vector2, drift: Vector2) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for layer in LAYERS:
		var depth := float(layer + 1) / LAYERS
		var width := view.x / RACKS_PER_LAYER * (0.5 + depth * 0.4)
		var height := view.y * (0.45 + depth * 0.45)
		var top := (view.y - height) / 2.0 - drift.y * 24.0 * depth
		for i in RACKS_PER_LAYER + 2:
			var x := (i - 1) * view.x / RACKS_PER_LAYER - drift.x * 60.0 * depth
			draw_rect(Rect2(x, top, width, height), Color(0.04, 0.07, 0.08, 0.35 + 0.25 * depth))
			for led in 12:
				var lit := sin(t * (1.0 + layer) + float(i * 7 + led * 3)) > 0.5
				if lit:
					var led_pos := Vector2(x + 8.0, top + 12.0 + led * height / 13.0)
					draw_rect(Rect2(led_pos, Vector2(4, 2)), Color(tint, 0.2 + 0.3 * depth))


func _draw_desk(view: Vector2, drift: Vector2) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var desk_y := view.y * 0.78 - drift.y * 10.0
	draw_rect(Rect2(-40, desk_y, view.x + 80, view.y), Color(0.02, 0.03, 0.03))
	var screens := [
		Rect2(view.x * 0.05, view.y * 0.2, view.x * 0.24, view.y * 0.34),
		Rect2(view.x * 0.71, view.y * 0.14, view.x * 0.25, view.y * 0.4),
	]
	for i in screens.size():
		var rect: Rect2 = screens[i]
		rect.position -= drift * (20.0 + i * 16.0)
		draw_rect(rect.grow(6), Color(0.07, 0.09, 0.1))
		draw_rect(rect, Color(0.02, 0.08, 0.06))
		var lines := int(rect.size.y / 12.0)
		for line in lines:
			var length := fmod(sin(float(line * 13 + i)) * 43.0 + t * 0.3 * float(line % 3), 1.0)
			var y := rect.position.y + 6.0 + line * 12.0
			var w := absf(length) * (rect.size.x - 16.0)
			draw_rect(Rect2(rect.position.x + 8.0, y, w, 4.0), Color(tint, 0.35))
