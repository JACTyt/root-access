extends Control
## Terminal-style reference. Entries unlock when first seen in a run.

var _from := "menu"


func setup(args: Dictionary) -> void:
	_from = args.get("from", "menu")
	var col := UI.centered_column(self, 900)
	col.add_child(UI.label("CODEX", 28, UI.GREEN))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 560
	col.add_child(scroll)
	var entries := VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override("separation", 8)
	scroll.add_child(entries)
	entries.add_child(UI.label("TECHNIQUES", 16, UI.AMBER))
	var cards := Content.cards()
	for id in Content.sorted_ids(cards):
		var card: CardData = cards[id]
		if SaveManager.is_seen(id):
			entries.add_child(UI.wrapped("%s [%s]\n  %s\n  Defense: %s" % [card.display_name, card.type, card.codex_technique, card.codex_defense], 13))
		else:
			entries.add_child(UI.label("???", 13, UI.DIM))
	entries.add_child(UI.label("DEFENDERS", 16, UI.RED))
	var defenders := Content.defenders()
	for id in Content.sorted_ids(defenders):
		var defender: DefenderData = defenders[id]
		if SaveManager.is_seen(id):
			entries.add_child(UI.wrapped("%s\n  %s\n  %s" % [defender.display_name, defender.description, defender.codex_defense], 13))
		else:
			entries.add_child(UI.label("???", 13, UI.DIM))
	col.add_child(UI.button("Back", func(): EventBus.goto_screen.emit(_from, {})))
