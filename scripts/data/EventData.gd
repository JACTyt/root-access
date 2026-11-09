class_name EventData
extends Resource

@export var id := ""
@export var title := ""
@export_multiline var text := ""
@export var choices := PackedStringArray()
## Parallel to choices, e.g. "trace:-10;data:-20". Keys: trace, data, credentials, scans.
@export var outcomes := PackedStringArray()
