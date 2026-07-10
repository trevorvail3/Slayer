class_name LootTable
extends Resource

## A pool of base item templates plus the rarity tiers that can roll from it.
## LootManager picks a base item and a rarity from these arrays.

@export var base_items: Array[ItemData] = []
@export var rarities: Array[Rarity] = []
