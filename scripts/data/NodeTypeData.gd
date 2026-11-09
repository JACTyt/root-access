class_name NodeTypeData
extends Resource

@export var id := ""
@export var display_name := ""
@export var glyph := "?"
@export var color := Color.WHITE
## encounter, boss, exfil, honeypot, shop, safehouse, event
@export var role := "encounter"
## Random-pick weight on the map; 0 means placed only by explicit rules.
@export var weight := 0
## Each entry is one possible lineup, defender ids joined with "+".
@export var defender_groups := PackedStringArray()
@export var data_min := 0
@export var data_max := 0
