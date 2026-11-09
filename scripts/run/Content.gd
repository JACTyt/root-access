class_name Content
extends RefCounted
## Loads every .tres under data/, so new content needs no code changes.

static var _cards := {}
static var _defenders := {}
static var _node_types := {}
static var _events := {}


static func cards() -> Dictionary:
	if _cards.is_empty():
		_cards = _load_dir("res://data/cards")
	return _cards


static func defenders() -> Dictionary:
	if _defenders.is_empty():
		_defenders = _load_dir("res://data/defenders")
	return _defenders


static func node_types() -> Dictionary:
	if _node_types.is_empty():
		_node_types = _load_dir("res://data/nodes")
	return _node_types


static func events() -> Dictionary:
	if _events.is_empty():
		_events = _load_dir("res://data/events")
	return _events


## Sorted so seeded picks stay reproducible across platforms.
static func sorted_ids(table: Dictionary) -> Array:
	var ids := table.keys()
	ids.sort()
	return ids


static func _load_dir(path: String) -> Dictionary:
	var table := {}
	for file in ResourceLoader.list_directory(path):
		if file.ends_with(".tres") or file.ends_with(".res"):
			var res: Resource = load(path.path_join(file))
			table[res.get("id")] = res
	return table
