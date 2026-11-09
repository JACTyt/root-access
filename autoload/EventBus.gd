extends Node

signal trace_changed(value: int, previous: int)
signal threshold_crossed(threshold: int)
signal card_played(card_id: String)
signal node_entered(node_id: int)
signal goto_screen(screen: String, args: Dictionary)
signal toast(text: String)
signal hud_refresh
signal settings_changed
