class_name UI
extends RefCounted
## Palette and small builders shared by the code-built screens.

const GREEN := Color(0.24, 1, 0.62)
const RED := Color(1, 0.27, 0.3)
const AMBER := Color(1, 0.75, 0.25)
const DIM := Color(0.45, 0.58, 0.55)
const BG := Color(0.03, 0.05, 0.06)


static func label(text: String, size := 15, color := Color(0.78, 0.92, 0.85)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func wrapped(text: String, size := 15, color := Color(0.78, 0.92, 0.85)) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 200
	return l


static func button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(func():
		AudioManager.play_sfx("click")
		action.call())
	return b


static func border(color: Color, fill := Color(0.05, 0.08, 0.09, 0.96), width := 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = color
	s.set_border_width_all(width)
	s.set_content_margin_all(8)
	return s


static func bar(max_value: float, color: Color) -> ProgressBar:
	var p := ProgressBar.new()
	p.max_value = max_value
	p.show_percentage = false
	p.custom_minimum_size = Vector2(120, 14)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	p.add_theme_stylebox_override("fill", fill)
	return p


## A centered column on a full-screen backdrop; screens add their contents to it.
static func centered_column(parent: Control, width := 760) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = width
	col.add_theme_constant_override("separation", 12)
	center.add_child(col)
	return col


static func type_color(type: String) -> Color:
	return AMBER if type == "social" else GREEN
