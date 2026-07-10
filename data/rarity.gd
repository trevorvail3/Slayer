class_name Rarity
extends Resource

## A loot rarity tier. Drives drop odds, affix count, power bonus and color.
## Tiers: Common < Uncommon < Rare < Legendary < Exotic.

@export var name: String = "Common"
@export var color: Color = Color.WHITE
@export var drop_weight: float = 55.0
@export var affix_count: int = 1
@export var power_bonus: int = 0

func _init(
		p_name: String = "Common",
		p_color: Color = Color.WHITE,
		p_weight: float = 55.0,
		p_affixes: int = 1,
		p_power: int = 0) -> void:
	name = p_name
	color = p_color
	drop_weight = p_weight
	affix_count = p_affixes
	power_bonus = p_power
