class_name EffectData
extends Resource
## One step of a card. Kinds are executed by EffectResolver:
## damage, human_damage, draw, reveal, scan, reduce_noise, half_noise_next,
## distract, double_next, gain_cpu, gain_data, upload, backdoor, credential_if_first.

@export var kind := ""
@export var amount := 0
## human_damage only: damage dealt to machines.
@export var amount_alt := 0
