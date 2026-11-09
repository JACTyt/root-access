extends Node
## Holds the current run and routes between screens as nodes resolve.

var run: RunState
var combat: TurnManager


func start_run(new_seed: int) -> void:
	run = RunState.new(new_seed)
	run.trace_changed.connect(func(value: int, previous: int): EventBus.trace_changed.emit(value, previous))
	run.threshold_crossed.connect(func(t: int): EventBus.threshold_crossed.emit(t))
	EventBus.trace_changed.emit(0, 0)
	EventBus.goto_screen.emit("map", {})


func random_seed() -> int:
	return randi() % 1000000


func choose_node(id: int) -> void:
	run.begin_move(id)
	EventBus.node_entered.emit(id)
	EventBus.hud_refresh.emit()
	if run.is_traced():
		end_run()
		return
	var node := run.map.node(id)
	match node.type_data().role:
		"encounter":
			_start_combat(node.defenders, TurnManager.MODE_NORMAL)
		"boss":
			_start_combat(node.defenders, TurnManager.MODE_BOSS)
		"exfil":
			_start_combat(PackedStringArray(), TurnManager.MODE_EXFIL)
		"honeypot":
			run.complete_move()
			run.add_trace(RunState.HONEYPOT_TRACE)
			EventBus.toast.emit("HONEYPOT! Trace +%d" % RunState.HONEYPOT_TRACE)
			after_node()
		"shop":
			EventBus.goto_screen.emit("shop", {})
		"safehouse":
			EventBus.goto_screen.emit("safehouse", {})
		"event":
			EventBus.goto_screen.emit("event", {})


func _start_combat(defenders: PackedStringArray, mode: String) -> void:
	combat = TurnManager.new(run, defenders, mode)
	EventBus.goto_screen.emit("encounter", {})


## Called by the encounter screen when a fight is over.
func resolve_combat() -> void:
	var result := combat.result
	var mode := combat.mode
	combat = null
	EventBus.hud_refresh.emit()
	match result:
		TurnManager.TRACED:
			end_run()
		TurnManager.WON:
			if mode == TurnManager.MODE_EXFIL:
				run.won = true
				end_run()
				return
			var node := run.map.node(run.pending_id)
			var loot := run.roll_data(node.type_data())
			run.complete_move()
			run.data += loot
			EventBus.goto_screen.emit("reward", {"data": loot})
		_:
			run.abort_move()
			EventBus.toast.emit("Kicked back. Trace is higher, the host has reset.")
			EventBus.goto_screen.emit("map", {})


## Back to the map after a non-combat node or reward screen.
func after_node() -> void:
	EventBus.hud_refresh.emit()
	if run.is_traced():
		end_run()
	else:
		EventBus.goto_screen.emit("map", {})


func end_run() -> void:
	EventBus.goto_screen.emit("end", {})
