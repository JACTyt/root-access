class_name EffectResolver
extends RefCounted
## Executes a card's effects in order against a TurnManager.


static func play(combat: TurnManager, card: DeckCard, target: DefenderState) -> void:
	var patched: bool = combat.patched_type == card.data.type
	for i in card.data.effects.size():
		var effect: EffectData = card.data.effects[i]
		var amount := card.amount_of(i)
		if patched:
			amount = ceili(amount / 2.0)
		_apply(combat, effect, amount, target)


static func _apply(combat: TurnManager, effect: EffectData, amount: int, target: DefenderState) -> void:
	match effect.kind:
		"damage":
			combat.deal_damage(target, amount)
		"human_damage":
			var human: bool = target != null and target.data.is_human
			combat.deal_damage(target, amount if human else effect.amount_alt)
		"draw":
			combat.draw_cards(amount)
		"reveal":
			combat.intents_revealed = true
		"scan":
			combat.run.scans += amount
		"reduce_noise":
			combat.noise = maxi(combat.noise - amount, 0)
		"half_noise_next":
			combat.proxy_charges += amount
		"distract":
			if target != null and target.data.is_human:
				target.distracted += amount
		"double_next":
			combat.double_next = true
		"gain_cpu":
			combat.cpu += amount
		"gain_data":
			combat.run.data += amount
		"upload":
			if combat.mode == TurnManager.MODE_EXFIL:
				combat.upload += amount
		"backdoor":
			combat.run.backdoor = true
		"credential_if_first":
			if combat.cards_played == 0:
				combat.run.credentials += amount
		_:
			push_error("Unknown effect kind: %s" % effect.kind)
