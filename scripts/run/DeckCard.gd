class_name DeckCard
extends RefCounted
## A card instance in the player's deck; upgrades belong to the copy, not the data.

var data: CardData
var upgraded := false


func _init(card_data: CardData, is_upgraded := false) -> void:
	data = card_data
	upgraded = is_upgraded


func title() -> String:
	return data.upgraded_name if upgraded else data.display_name


func cost() -> int:
	return data.upgraded_cost if upgraded and data.upgraded_cost >= 0 else data.cost


func noise() -> int:
	return data.upgraded_noise if upgraded and data.upgraded_noise >= 0 else data.noise


func description() -> String:
	return data.upgraded_description if upgraded else data.description


func amount_of(index: int) -> int:
	var value: int = data.effects[index].amount
	if upgraded and index == 0:
		value += data.upgraded_amount_bonus
	return value
