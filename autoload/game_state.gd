extends Node

## GameState — the player's persistent gear, inventory, resources and town.
## Signal-driven: everything that cares about stats/resources/town listens and
## recomputes. Autoload, so it survives Hub<->Zone scene changes; SaveManager
## serializes it to disk for cross-session persistence.

signal equipment_changed
signal backpack_changed
signal loot_acquired(item: ItemData)
signal resources_changed
signal town_changed
signal class_changed
signal relic_found(total: int)

var equipped: Dictionary = {}       # Slot (int) -> ItemData
var backpack: Array[ItemData] = []
var stash: Array[ItemData] = []

## wood/stone/iron are gathered in the world; emberdust/godshard are crafting
## materials recovered by salvaging loot (v0.9). All spend via can_afford/spend.
var resources := {"wood": 0, "stone": 0, "iron": 0, "emberdust": 0, "godshard": 0}
var gold := 0
var town := {}                      # building_id (String) -> built (bool)
var player_class := ClassDefs.Kind.WARDEN
var relics_found := 0

func _ready() -> void:
	_equip_starter_gear()

## Rusty Common gear in every slot so Power starts low and climbs fast.
## (Game autoload overrides this with a loaded save if one exists.)
func _equip_starter_gear() -> void:
	Catalog.ensure_built()
	for slot in ItemData.Slot.values():
		var it := ItemData.new()
		it.name = "Rusty " + String(ItemData.Slot.keys()[slot]).capitalize()
		it.slot = slot
		if slot == ItemData.Slot.WEAPON:
			it.weapon_type = ItemData.WeaponType.SWORD
		it.rarity = Catalog.rarities[0]
		it.power = 5
		equipped[slot] = it
	equipment_changed.emit()

# --- Inventory ---

func add_to_backpack(item: ItemData) -> void:
	backpack.append(item)
	loot_acquired.emit(item)
	backpack_changed.emit()

func equip(item: ItemData) -> void:
	equipped[item.slot] = item
	backpack.erase(item)
	equipment_changed.emit()
	backpack_changed.emit()

func move_to_stash(item: ItemData) -> void:
	if backpack.has(item):
		backpack.erase(item)
		stash.append(item)
		backpack_changed.emit()

func move_from_stash(item: ItemData) -> void:
	if stash.has(item):
		stash.erase(item)
		backpack.append(item)
		backpack_changed.emit()

# --- Stats ---

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

# --- Resources / currency ---

func add_resource(type: String, amount: int) -> void:
	resources[type] = int(resources.get(type, 0)) + amount
	resources_changed.emit()

func add_gold(amount: int) -> void:
	gold += amount
	resources_changed.emit()

func add_relic() -> void:
	relics_found += 1
	relic_found.emit(relics_found)
	resources_changed.emit()

# --- Crafting: salvage loot into materials (v0.9) ---

## Materials an item yields when broken down. Pure/deterministic so tests and the
## UI preview agree. Rarity index is derived from affix_count (Common=1..Exotic=5)
## so this needs no Catalog lookup. godshard (premium) only from Rare+.
func salvage_yield(item: ItemData) -> Dictionary:
	if item == null or item.rarity == null:
		return {"emberdust": 0, "godshard": 0}
	var ri: int = maxi(0, item.rarity.affix_count - 1)
	var ember: int = 2 + ri * 3 + int(item.power / 8.0)
	var shard: int = 0
	if ri >= 2:
		shard = ri - 1   # Rare 1 · Legendary 2 · Exotic 3
	return {"emberdust": ember, "godshard": shard}

## Break a backpack item down into materials. Only unequipped gear is salvageable.
func salvage(item: ItemData) -> Dictionary:
	if not backpack.has(item):
		return {"emberdust": 0, "godshard": 0}
	var y := salvage_yield(item)
	backpack.erase(item)
	for k in y:
		if int(y[k]) > 0:
			resources[k] = int(resources.get(k, 0)) + int(y[k])
	backpack_changed.emit()
	resources_changed.emit()
	return y

## Salvage every Common/Uncommon in the backpack at once (dismantle-the-blues QoL).
func salvage_all_trash() -> Dictionary:
	var total := {"emberdust": 0, "godshard": 0}
	var doomed: Array[ItemData] = []
	for it in backpack:
		if it.rarity != null and it.rarity.affix_count <= 2:
			doomed.append(it)
	for it in doomed:
		var y := salvage(it)
		for k in y:
			total[k] = int(total.get(k, 0)) + int(y[k])
	return total

func can_afford(cost: Dictionary) -> bool:
	for k in cost:
		if k == "gold":
			if gold < int(cost[k]):
				return false
		elif int(resources.get(k, 0)) < int(cost[k]):
			return false
	return true

func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for k in cost:
		if k == "gold":
			gold -= int(cost[k])
		else:
			resources[k] = int(resources.get(k, 0)) - int(cost[k])
	resources_changed.emit()
	return true

# --- Town ---

func set_class(k: int) -> void:
	player_class = k
	class_changed.emit()

func set_town_built(id: String) -> void:
	town[id] = true
	town_changed.emit()

func is_built(id: String) -> bool:
	return bool(town.get(id, false))

func town_tier() -> int:
	var n := 0
	for id in town:
		if town[id]:
			n += 1
	return n

# --- Serialization (SaveManager) ---

func to_dict() -> Dictionary:
	var eq := {}
	for slot in equipped:
		eq[str(slot)] = _item_to_dict(equipped[slot])
	var bp := []
	for it in backpack:
		bp.append(_item_to_dict(it))
	var st := []
	for it in stash:
		st.append(_item_to_dict(it))
	return {
		"equipped": eq,
		"backpack": bp,
		"stash": st,
		"resources": resources,
		"gold": gold,
		"town": town,
		"player_class": int(player_class),
		"relics_found": relics_found,
	}

func from_dict(d: Dictionary) -> void:
	Catalog.ensure_built()
	equipped.clear()
	var eq: Dictionary = d.get("equipped", {})
	for k in eq:
		equipped[int(k)] = _item_from_dict(eq[k])
	backpack.clear()
	for e in d.get("backpack", []):
		backpack.append(_item_from_dict(e))
	stash.clear()
	for e in d.get("stash", []):
		stash.append(_item_from_dict(e))
	# Merge saved resources over the defaults so new material types (added in
	# later versions) default to 0 for old saves instead of vanishing.
	var r: Dictionary = d.get("resources", {})
	resources = {"wood": 0, "stone": 0, "iron": 0, "emberdust": 0, "godshard": 0}
	for k in r:
		resources[k] = int(r[k])
	gold = int(d.get("gold", 0))
	town = d.get("town", {})
	player_class = int(d.get("player_class", ClassDefs.Kind.WARDEN))
	relics_found = int(d.get("relics_found", 0))
	equipment_changed.emit()
	backpack_changed.emit()
	resources_changed.emit()
	town_changed.emit()
	class_changed.emit()

func _item_to_dict(item: ItemData) -> Dictionary:
	var affs := []
	for a in item.affixes:
		affs.append({"stat": a.stat, "value": a.value})
	return {
		"name": item.name,
		"slot": int(item.slot),
		"weapon_type": int(item.weapon_type),
		"rarity": Catalog.rarities.find(item.rarity),
		"power": item.power,
		"affixes": affs,
	}

func _item_from_dict(d: Dictionary) -> ItemData:
	var it := ItemData.new()
	it.name = d.get("name", "Unknown")
	it.slot = int(d.get("slot", 0))
	it.weapon_type = int(d.get("weapon_type", 0))
	var ri := int(d.get("rarity", 0))
	it.rarity = Catalog.rarities[clampi(ri, 0, Catalog.rarities.size() - 1)]
	it.power = int(d.get("power", 1))
	var affs: Array[Affix] = []
	for ad in d.get("affixes", []):
		affs.append(Affix.new(ad.get("stat", ""), int(ad.get("value", 0))))
	it.affixes = affs
	return it
