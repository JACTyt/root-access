extends GutTest

const SEEDS := 300


func test_constraints_hold_across_seeds() -> void:
	for s in SEEDS:
		var map := MapGenerator.generate(s)
		assert_true(_has_type(map, "shop"), "shop, seed %d" % s)
		assert_true(_has_type(map, "safehouse"), "safehouse, seed %d" % s)
		assert_true(_safe_path_exists(map), "safe path, seed %d" % s)
		for n in map.nodes:
			if n.type != "exfil":
				assert_false(n.next.is_empty(), "dead end, seed %d" % s)


func test_same_seed_same_map() -> void:
	var a := MapGenerator.generate(42)
	var b := MapGenerator.generate(42)
	assert_eq(a.nodes.size(), b.nodes.size())
	for i in a.nodes.size():
		assert_eq(a.nodes[i].type, b.nodes[i].type)
		assert_eq(a.nodes[i].next, b.nodes[i].next)
		assert_eq(a.nodes[i].defenders, b.nodes[i].defenders)


func _has_type(map: MapGraph, type: String) -> bool:
	for n in map.nodes:
		if n.type == type:
			return true
	return false


## From every start, walks only ungated, non-honeypot edges to Exfil.
func _safe_path_exists(map: MapGraph) -> bool:
	var frontier: Array = []
	for id in map.start_ids():
		if map.node(id).type != "honeypot":
			frontier.append(id)
	var seen := {}
	while not frontier.is_empty():
		var id: int = frontier.pop_back()
		var n := map.node(id)
		if n.type == "exfil":
			return true
		if seen.has(id):
			continue
		seen[id] = true
		for target in n.next:
			if not n.gates.has(target) and map.node(target).type != "honeypot":
				frontier.append(target)
	return false
