class_name DefenderState
extends RefCounted

var data: DefenderData
var integrity := 0
var distracted := 0
## Firewall or boss rule: card type refused this turn.
var blocked_type := ""
var active_rule := ""


func _init(defender_data: DefenderData) -> void:
	data = defender_data
	integrity = defender_data.max_integrity


func is_alive() -> bool:
	return integrity > 0
