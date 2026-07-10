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
	item.weapon_type = base.weapon_type
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

## Re-roll an existing item's affixes in place (simple full reroll).
func reroll_affixes(item: ItemData) -> void:
	if item.rarity == null:
		return
	item.affixes = _roll_affixes(item.rarity, item.power)

## Reforge for the god-roll chase (v0.9). Rerolls the item's affixes, but:
##   locked_indices — affix slots to preserve verbatim across the reroll.
##   focus_stat     — if set (and not already present on a locked affix),
##                    guarantees one freshly-rolled slot rolls this stat.
## Locking/focusing is the *targeting*: the Forge charges godshard for it.
func reforge(item: ItemData, locked_indices: Array = [], focus_stat: String = "") -> void:
	if item.rarity == null:
		return
	var count: int = item.rarity.affix_count
	var result: Array[Affix] = []
	result.resize(count)
	var focus_present := false
	for i in count:
		if locked_indices.has(i) and i < item.affixes.size():
			result[i] = item.affixes[i]
			if focus_stat != "" and item.affixes[i].stat == focus_stat:
				focus_present = true
	var first_open := -1
	for i in count:
		if result[i] == null and first_open == -1:
			first_open = i
	for i in count:
		if result[i] == null:
			var forced := ""
			if focus_stat != "" and not focus_present and i == first_open:
				forced = focus_stat
				focus_present = true
			result[i] = _roll_one_affix(item.power, forced)
	item.affixes = result

# --- Affix roll math (single source of truth for value bounds + quality) ---

## Lowest possible value for an affix rolled at this power.
func affix_min(source_power: int) -> int:
	return 3 + int(source_power / 4)

## Highest possible value for an affix rolled at this power.
func affix_max(source_power: int) -> int:
	return affix_min(source_power) * 2

## How good a rolled value is, 0.0 (floor) .. 1.0 (max) — drives the star rating.
func affix_quality(value: int, source_power: int) -> float:
	var lo := affix_min(source_power)
	var hi := affix_max(source_power)
	if hi <= lo:
		return 1.0
	return clampf(float(value - lo) / float(hi - lo), 0.0, 1.0)

## A "god roll": a multi-affix item where the affixes average near-max quality.
func is_god_roll(item: ItemData) -> bool:
	if item.affixes.size() < 2:
		return false
	var sum := 0.0
	for a in item.affixes:
		sum += affix_quality(a.value, item.power)
	return (sum / item.affixes.size()) >= 0.8

func _roll_one_affix(source_power: int, forced_stat: String = "") -> Affix:
	var stat := forced_stat
	if stat == "":
		stat = STATS[rng.randi_range(0, STATS.size() - 1)]
	var lo := affix_min(source_power)
	return Affix.new(stat, lo + rng.randi_range(0, lo))

func _roll_affixes(rarity: Rarity, source_power: int) -> Array[Affix]:
	var result: Array[Affix] = []
	for i in rarity.affix_count:
		result.append(_roll_one_affix(source_power))
	return result
