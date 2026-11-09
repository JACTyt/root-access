class_name MapNode
extends RefCounted

var id := 0
var row := 0
var col := 0
var type := "server"
var next: Array[int] = []
## Target node id -> card id that opens the edge (or spend 1 Credential).
var gates := {}
var revealed := false
var cleared := false
var defenders := PackedStringArray()


func type_data() -> NodeTypeData:
	return Content.node_types()[type]
