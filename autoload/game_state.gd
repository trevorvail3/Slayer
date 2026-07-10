extends Node

## GameState — the player's persistent gear and inventory.
## Everything that cares about stats listens to `equipment_changed` and recomputes;
## this signal-driven pattern is inherited by every later milestone.

signal equipment_changed
signal backpack_changed
signal loot_acquired(item: ItemData)

var equipped: Dictionary = {}       # Slot (int) -> ItemData
var backpack: Array[ItemData] = []

func _ready() -> void:
	_equip_starter_gear()

## Rusty Common gear in every slot so Power starts low and climbs fast.
func _equip_starter_gear() -> void:
	Catalog.ensure_built()
	for slot in ItemData.Slot.values():
		var it := ItemData.new()
		it.name = "Rusty " + String(ItemData.Slot.keys()[slot]).capitalize()
		it.slot = slot
		it.rarity = Catalog.rarities[0]
		it.power = 5
		equipped[slot] = it
	equipment_changed.emit()

func add_to_backpack(item: ItemData) -> void:
	backpack.append(item)
	loot_acquired.emit(item)
	backpack_changed.emit()

func equip(item: ItemData) -> void:
	equipped[item.slot] = item
	backpack.erase(item)
	equipment_changed.emit()
	backpack_changed.emit()

## Power Level = average power across equipped slots (Destiny-style).
func gear_score() -> int:
	if equipped.is_empty():
		return 0
	var total := 0
	for slot in equipped:
		total += (equipped[slot] as ItemData).power
	return int(round(float(total) / equipped.size()))

## Sum of one stat across all equipped gear's affixes.
func total_stat(stat: String) -> int:
	var sum := 0
	for slot in equipped:
		sum += (equipped[slot] as ItemData).total_stat(stat)
	return sum
