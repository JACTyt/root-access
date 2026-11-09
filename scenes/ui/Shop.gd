extends Control
## Dark web market. Stock is fixed on entry; the screen is rebuilt after each purchase.

const CARD_SCENE := preload("res://scenes/ui/Card.tscn")
const CARD_PRICE := 40
const REMOVE_PRICE := 50
const CREDENTIAL_PRICE := 30
const MIN_DECK := 5

var _run: RunState
var _stock: Array[CardData] = []
var _root: Control


func _ready() -> void:
	_run = GameState.run
	_stock = _run.reward_choices()
	_build()


func _build() -> void:
	if _root != null:
		_root.queue_free()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var col := UI.centered_column(_root, 800)
	col.add_child(UI.label("DARK WEB MARKET", 28, UI.GREEN))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	for data in _stock:
		var view = CARD_SCENE.instantiate()
		row.add_child(view)
		var card := DeckCard.new(data)
		view.bind(card, _run.data >= CARD_PRICE)
		view.clicked.connect(_buy_card.bind(data))
	col.add_child(UI.label("Cards cost %d Data" % CARD_PRICE, 13, UI.DIM))
	var cred := UI.button("Buy Credential (%d Data)" % CREDENTIAL_PRICE, _buy_credential)
	cred.disabled = _run.data < CREDENTIAL_PRICE
	col.add_child(cred)
	col.add_child(UI.label("Remove a card (%d Data):" % REMOVE_PRICE, 13, UI.DIM))
	var removal := HFlowContainer.new()
	col.add_child(removal)
	for card in _run.deck:
		var b := UI.button(card.title(), _remove.bind(card))
		b.disabled = _run.data < REMOVE_PRICE or _run.deck.size() <= MIN_DECK
		removal.add_child(b)
	col.add_child(UI.button("Leave", _leave))


func _buy_card(data: CardData) -> void:
	if _run.data >= CARD_PRICE:
		_run.data -= CARD_PRICE
		_run.deck.append(DeckCard.new(data))
		_stock.erase(data)
		_changed()


func _buy_credential() -> void:
	_run.data -= CREDENTIAL_PRICE
	_run.credentials += 1
	_changed()


func _remove(card: DeckCard) -> void:
	_run.data -= REMOVE_PRICE
	_run.deck.erase(card)
	_changed()


func _changed() -> void:
	EventBus.hud_refresh.emit()
	_build.call_deferred()


func _leave() -> void:
	_run.complete_move()
	GameState.after_node()
