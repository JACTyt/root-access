class_name RunState
extends RefCounted
## All state of one breach. Plain object so tests and the simulator need no scene tree.

signal trace_changed(value: int, previous: int)
signal threshold_crossed(threshold: int)

const THRESHOLDS: Array[int] = [25, 50, 75]
const MAX_TRACE := 100
const MOVE_TRACE_AT_75 := 2
const HONEYPOT_TRACE := 20
const SAFEHOUSE_TRACE_RELIEF := 15
const GHOST_DECK: Array[String] = [
	"default_password", "default_password", "default_password", "default_password",
	"living_off_the_land", "living_off_the_land",
	"port_scan", "port_scan",
	"log_wipe", "proxy_chain",
]

var map_seed := 0
var rng := RandomNumberGenerator.new()
var map: MapGraph
var deck: Array[DeckCard] = []
var trace := 0
var data := 0
var credentials := 0
var scans := 2
var backdoor := false
var current_id := -1
var pending_id := -1
var won := false
## Card id -> times played; drives Blue team notes.
var cards_used := {}
var defenders_met := {}


func _init(new_seed: int) -> void:
	map_seed = new_seed
	rng.seed = new_seed
	map = MapGenerator.generate(new_seed)
	for id in GHOST_DECK:
		deck.append(DeckCard.new(Content.cards()[id]))


func add_trace(amount: int) -> void:
	var previous := trace
	trace = clampi(trace + amount, 0, MAX_TRACE)
	if trace == previous:
		return
	trace_changed.emit(trace, previous)
	for t in THRESHOLDS:
		if previous < t and trace >= t:
			threshold_crossed.emit(t)


func is_traced() -> bool:
	return trace >= MAX_TRACE


func tier() -> int:
	var result := 0
	for t in THRESHOLDS:
		if trace >= t:
			result += 1
	return result


func available_moves() -> Array:
	return map.start_ids() if current_id < 0 else map.node(current_id).next


func gate_card(target: int) -> String:
	if current_id < 0:
		return ""
	return map.node(current_id).gates.get(target, "")


func has_card(card_id: String) -> bool:
	for c in deck:
		if c.data.id == card_id:
			return true
	return false


## Open with the gate's card, or spend a Credential.
func can_cross(target: int) -> bool:
	var needed := gate_card(target)
	return needed == "" or has_card(needed) or credentials > 0


## Starts moving; the node only becomes current once completed, so losing a
## fight naturally leaves the player on the previous node.
func begin_move(target: int) -> void:
	var needed := gate_card(target)
	if needed != "" and not has_card(needed):
		credentials -= 1
	if current_id >= 0:
		map.node(current_id).gates.erase(target)
	pending_id = target
	if tier() >= 3:
		add_trace(MOVE_TRACE_AT_75)
	map.node(target).revealed = true


func complete_move() -> void:
	current_id = pending_id
	map.node(current_id).cleared = true
	pending_id = -1


func abort_move() -> void:
	pending_id = -1


func spend_scan(target: int) -> bool:
	if scans <= 0 or map.node(target).revealed:
		return false
	scans -= 1
	map.node(target).revealed = true
	return true


func can_afford_outcome(outcome: String) -> bool:
	for part in _parse_outcome(outcome):
		if part[0] == "data" and data + part[1] < 0:
			return false
		if part[0] == "credentials" and credentials + part[1] < 0:
			return false
	return true


func apply_outcome(outcome: String) -> void:
	for part in _parse_outcome(outcome):
		match part[0]:
			"trace": add_trace(part[1])
			"data": data += part[1]
			"credentials": credentials += part[1]
			"scans": scans += part[1]


func _parse_outcome(outcome: String) -> Array:
	var parts := []
	for piece in outcome.split(";", false):
		var kv: PackedStringArray = piece.split(":")
		parts.append([kv[0], int(kv[1])])
	return parts


func shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = items[i]
		items[i] = items[j]
		items[j] = tmp


func reward_choices(count := 3) -> Array[CardData]:
	var ids := Content.sorted_ids(Content.cards())
	shuffle(ids)
	var result: Array[CardData] = []
	for i in mini(count, ids.size()):
		result.append(Content.cards()[ids[i]])
	return result


func roll_data(type_data: NodeTypeData) -> int:
	return rng.randi_range(type_data.data_min, type_data.data_max)
