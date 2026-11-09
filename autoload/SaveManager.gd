extends Node
## Settings and codex progress only; runs are short enough not to save mid-run.

const PATH := "user://settings.cfg"

var config := ConfigFile.new()


func _ready() -> void:
	config.load(PATH)


func crt_enabled() -> bool:
	return config.get_value("settings", "crt", true)


func set_crt_enabled(value: bool) -> void:
	_store("settings", "crt", value)
	EventBus.settings_changed.emit()


func volume() -> float:
	return config.get_value("settings", "volume", 0.7)


func set_volume(value: float) -> void:
	_store("settings", "volume", value)
	EventBus.settings_changed.emit()


func tutorial_done() -> bool:
	return config.get_value("progress", "tutorial_done", false)


func set_tutorial_done() -> void:
	_store("progress", "tutorial_done", true)


func is_seen(id: String) -> bool:
	return config.get_value("codex", id, false)


func mark_seen(id: String) -> void:
	if not is_seen(id):
		_store("codex", id, true)


func _store(section: String, key: String, value: Variant) -> void:
	config.set_value(section, key, value)
	config.save(PATH)
