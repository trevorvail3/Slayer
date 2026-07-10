extends Node

## LootManager — rolls items. The heart of the grind.
## Seedable RNG so the loot distribution is reproducible in tests.

const STATS := ["might", "vigor", "fortitude", "swiftness", "ferocity"]

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func set_seed(s: int) -> void:
	rng.seed = s

## Roll a fresh item scaled to the source's power level.
## Higher source_power -> higher item power and bigger affix values.
## min_rarity_index (0..N) floors the rarity tier — used for chests and bosses.
func roll_item(source_power: int, table: LootTable = null, min_rarity_index: int = 0) -> ItemData:
	if table == null:
		Catalog.ensure_built()
		table = Catalog.default_table

	var base: ItemData = table.base_items[rng.randi_range(0, table.base_items.size() - 1)]
	var rarity: Rarity = _roll_rarity(table.rarities)
	if min_rarity_index > 0:
		var idx := table.rarities.find(rarity)
		if idx < min_rarity_index:
			rarity = table.rarities[mini(min_rarity_index, table.rarities.size() - 1)]

	var item := ItemData.new()
	item.name = base.name
	item.slot = base.slot
	item.rarity = rarity
	item.power = maxi(1, source_power + rarity.power_bonus + rng.randi_range(-2, 2))
	item.affixes = _roll_affixes(rarity, source_power)
	return item

func _roll_rarity(rarities: Array[Rarity]) -> Rarity:
	var total := 0.0
	for r in rarities:
		total += r.drop_weight
	var pick := rng.randf() * total
	var acc := 0.0
	for r in rarities:
		acc += r.drop_weight
		if pick <= acc:
			return r
	return rarities[0]

## Re-roll an existing item's affixes in place (Blacksmith reforge → god-roll chase).
func reroll_affixes(item: ItemData) -> void:
	if item.rarity == null:
		return
	item.affixes = _roll_affixes(item.rarity, item.power)

func _roll_affixes(rarity: Rarity, source_power: int) -> Array[Affix]:
	var result: Array[Affix] = []
	var base_val := 3 + int(source_power / 4)
	for i in rarity.affix_count:
		var stat: String = STATS[rng.randi_range(0, STATS.size() - 1)]
		var value := base_val + rng.randi_range(0, base_val)
		result.append(Affix.new(stat, value))
	return result
