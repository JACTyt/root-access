class_name MapGraph
extends RefCounted

var nodes: Array[MapNode] = []
## Node ids per row, top to bottom of the layer.
var rows: Array = []


func node(id: int) -> MapNode:
	return nodes[id]


func start_ids() -> Array:
	return rows[0]


func predecessors(id: int) -> Array[MapNode]:
	var result: Array[MapNode] = []
	for n in nodes:
		if id in n.next:
			result.append(n)
	return result
