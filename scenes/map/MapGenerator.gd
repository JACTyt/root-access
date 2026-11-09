class_name MapGenerator
extends RefCounted
## Layered graph with constraints: a safe ungated path always reaches the boss,
## at least one Shop and Safehouse, honeypots never on the only path.

const HOST_ROWS := 6
const GATE_CHANCE := 0.25
const GATE_CARDS: Array[String] = ["sql_injection", "buffer_overflow"]


static func generate(map_seed: int) -> MapGraph:
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed
	var graph := MapGraph.new()
	for r in HOST_ROWS:
		_add_row(graph, rng.randi_range(2, 4))
	_add_row(graph, 1)
	_add_row(graph, 1)
	for r in graph.rows.size() - 1:
		_link_rows(graph, graph.rows[r], graph.rows[r + 1])
	_assign_types(graph, rng)
	_remove_unsafe_honeypots(graph)
	_add_gates(graph, rng)
	_assign_defenders(graph, rng)
	return graph


static func _add_row(graph: MapGraph, count: int) -> void:
	var ids := []
	for c in count:
		var n := MapNode.new()
		n.id = graph.nodes.size()
		n.row = graph.rows.size()
		n.col = c
		graph.nodes.append(n)
		ids.append(n.id)
	graph.rows.append(ids)


## Merge walk: every node gets an in and an out edge and edges never cross.
static func _link_rows(graph: MapGraph, upper: Array, lower: Array) -> void:
	var i := 0
	var j := 0
	graph.node(upper[i]).next.append(lower[j])
	while i < upper.size() - 1 or j < lower.size() - 1:
		var upper_pos := float(i + 1) / upper.size()
		var lower_pos := float(j + 1) / lower.size()
		if j == lower.size() - 1 or (i < upper.size() - 1 and upper_pos <= lower_pos):
			i += 1
		else:
			j += 1
		graph.node(upper[i]).next.append(lower[j])


static func _assign_types(graph: MapGraph, rng: RandomNumberGenerator) -> void:
	var table := Content.node_types()
	var pool := []
	var total := 0
	for id in Content.sorted_ids(table):
		if table[id].weight > 0:
			pool.append(id)
			total += table[id].weight
	for r in HOST_ROWS:
		for id in graph.rows[r]:
			graph.node(id).type = _weighted_pick(pool, total, rng)
	# Row 0 is always a host so the first move is a fight, never a trap or a freebie.
	for id in graph.rows[0]:
		graph.node(id).type = "server" if rng.randf() < 0.6 else "workstation"
	var shop_row: Array = graph.rows[rng.randi_range(2, 3)]
	graph.node(shop_row[rng.randi() % shop_row.size()]).type = "shop"
	var safe_row: Array = graph.rows[rng.randi_range(4, 5)]
	graph.node(safe_row[rng.randi() % safe_row.size()]).type = "safehouse"
	graph.node(graph.rows[HOST_ROWS][0]).type = "boss"
	graph.node(graph.rows[HOST_ROWS + 1][0]).type = "exfil"
	graph.node(graph.rows[HOST_ROWS][0]).revealed = true
	graph.node(graph.rows[HOST_ROWS + 1][0]).revealed = true


static func _weighted_pick(pool: Array, total: int, rng: RandomNumberGenerator) -> String:
	var roll := rng.randi_range(1, total)
	var table := Content.node_types()
	for id in pool:
		roll -= table[id].weight
		if roll <= 0:
			return id
	return pool[0]


## A honeypot stays only if every way into it has a non-honeypot alternative.
static func _remove_unsafe_honeypots(graph: MapGraph) -> void:
	for n in graph.nodes:
		if n.type != "honeypot":
			continue
		for pred in graph.predecessors(n.id):
			if _safe_exits(graph, pred).is_empty():
				n.type = "server"
				break


static func _safe_exits(graph: MapGraph, n: MapNode) -> Array:
	var safe := []
	for target in n.next:
		if graph.node(target).type != "honeypot" and not n.gates.has(target):
			safe.append(target)
	return safe


## Gates only ever close a spare edge, so a run can't soft-lock.
static func _add_gates(graph: MapGraph, rng: RandomNumberGenerator) -> void:
	for n in graph.nodes:
		if n.row >= HOST_ROWS - 1 or n.next.size() < 2 or rng.randf() >= GATE_CHANCE:
			continue
		var target: int = n.next[rng.randi() % n.next.size()]
		if graph.node(target).type == "honeypot":
			continue
		n.gates[target] = GATE_CARDS[rng.randi() % GATE_CARDS.size()]
		if _safe_exits(graph, n).is_empty():
			n.gates.erase(target)


static func _assign_defenders(graph: MapGraph, rng: RandomNumberGenerator) -> void:
	for n in graph.nodes:
		var groups: PackedStringArray = n.type_data().defender_groups
		if not groups.is_empty():
			n.defenders = groups[rng.randi() % groups.size()].split("+")
