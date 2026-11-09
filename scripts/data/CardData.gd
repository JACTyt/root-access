class_name CardData
extends Resource

@export var id := ""
@export var display_name := ""
## recon, exploit, social, stealth, persistence, escalation, payload
@export var type := ""
@export var cost := 1
@export var noise := 0
@export var effects: Array[EffectData] = []
@export_multiline var description := ""
@export var upgraded_name := ""
## -1 keeps the base value.
@export var upgraded_cost := -1
@export var upgraded_noise := -1
## Added to the first effect's amount.
@export var upgraded_amount_bonus := 0
@export_multiline var upgraded_description := ""
@export_multiline var codex_technique := ""
@export_multiline var codex_defense := ""
