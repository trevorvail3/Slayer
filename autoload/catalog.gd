extends Node

## Catalog — central content definitions for v0.1.
## Placeholder for future .tres resource files; keeping it in code for now makes
## the vertical slice self-contained and avoids hand-authored resource parsing.
## Adding content later = add an entry here (or migrate to .tres, same shape).

var rarities: Array[Rarity] = []
var base_items: Array[ItemData] = []
var default_table: LootTable

## Hub buildings: id -> { name, npc, cost{}, blurb }. Order = display order.
## Costs are tuned so the first rebuild is fast and satisfying.
var buildings := {
	"waypoint": {
		"name": "Waystone", "npc": "Old Marek, the Pathwarden",
		"cost": {"wood": 12, "stone": 6},
		"blurb": "The waystone hums to life. The roads are yours again.",
	},
	"blacksmith": {
		"name": "Blacksmith", "npc": "Bruna Ironhand",
		"cost": {"wood": 25, "stone": 18, "gold": 40},
		"blurb": "Bruna lights the forge. \"Bring me steel and I'll make you deadly.\"",
	},
	"vault": {
		"name": "Vault", "npc": "Keeper Aldous",
		"cost": {"wood": 20, "stone": 14, "gold": 20},
		"blurb": "Aldous dusts off the shelves. Your hoard finally has a home.",
	},
	"tavern": {
		"name": "Tavern", "npc": "Sella of the Ladle",
		"cost": {"wood": 30, "stone": 10, "gold": 60},
		"blurb": "Warmth returns to the hearth. Bounties coming soon...",
	},
}

func _ready() -> void:
	ensure_built()

## Idempotent build so anything can safely depend on the catalog regardless of
## autoload init order.
func ensure_built() -> void:
	if not rarities.is_empty():
		return
	_build_rarities()
	_build_base_items()
	default_table = LootTable.new()
	default_table.rarities = rarities
	default_table.base_items = base_items

func _build_rarities() -> void:
	rarities = [
		Rarity.new("Common",    Color("cfcfcf"), 55.0, 1, 0),
		Rarity.new("Uncommon",  Color("4caf50"), 25.0, 2, 2),
		Rarity.new("Rare",      Color("2196f3"), 13.0, 3, 4),
		Rarity.new("Legendary", Color("9c27b0"),  6.0, 4, 7),
		Rarity.new("Exotic",    Color("ffc107"),  1.0, 5, 11),
	]

func _build_base_items() -> void:
	base_items = [
		_mk("Ironhide Greatsword", ItemData.Slot.WEAPON),
		_mk("Skullcrusher Warhammer", ItemData.Slot.WEAPON),
		_mk("Ravager Battleaxe", ItemData.Slot.WEAPON),
		_mk("Bulwark Tower Shield", ItemData.Slot.WEAPON),
		_mk("Barbarian Helm", ItemData.Slot.HELM),
		_mk("Warplate Chest", ItemData.Slot.CHEST),
		_mk("Bruteforce Gauntlets", ItemData.Slot.ARMS),
		_mk("Ironmarch Greaves", ItemData.Slot.LEGS),
		_mk("Clan Totem", ItemData.Slot.CLASS),
	]

func _mk(item_name: String, slot: ItemData.Slot) -> ItemData:
	var it := ItemData.new()
	it.name = item_name
	it.slot = slot
	return it
