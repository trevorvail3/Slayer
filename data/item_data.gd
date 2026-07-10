class_name ItemData
extends Resource

## A concrete piece of gear (weapon or armor). Rolled by LootManager, held in
## GameState.backpack, and equipped into GameState.equipped.

enum Slot { WEAPON, HELM, CHEST, ARMS, LEGS, CLASS }
enum WeaponType { NONE, SWORD, GREATSWORD, BATTLEAXE, SPEAR, BOW, CROSSBOW }

@export var name: String = "Unknown"
@export var slot: Slot = Slot.WEAPON
@export var weapon_type: WeaponType = WeaponType.NONE
@export var rarity: Rarity
@export var power: int = 0
@export var affixes: Array[Affix] = []

func slot_name() -> String:
	return String(Slot.keys()[slot]).capitalize()

func weapon_type_name() -> String:
	return String(WeaponType.keys()[weapon_type]).capitalize()

## Sum of a given stat across this item's affixes.
func total_stat(stat: String) -> int:
	var sum := 0
	for a in affixes:
		if a.stat == stat:
			sum += a.value
	return sum

func display_color() -> Color:
	return rarity.color if rarity else Color.WHITE
