class_name DefenderData
extends Resource

@export var id := ""
@export var display_name := ""
@export var max_integrity := 10
@export var attack_noise := 2
@export var is_human := false
@export var is_boss := false
## block_type, quarantine, double_noise, strip_buffs, learn, rule_sets
@export var behavior := ""
## rule_sets only: deny_exploit, rate_limit, deep_inspection. Rotates every 2 turns.
@export var rules := PackedStringArray()
@export_multiline var description := ""
@export_multiline var codex_defense := ""
