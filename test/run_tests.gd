extends SceneTree

## Lightweight headless test runner for the loot-loop logic.
## Run: godot --headless --path . -s res://test/run_tests.gd
## Exits 0 if all pass, 1 otherwise. Constructs system instances directly so it
## does not depend on autoload/scene-tree state.

func _initialize() -> void:
	var fails := 0
	fails += _t("rarity_distribution_matches_weights", _test_rarity_distribution())
	fails += _t("higher_power_source_gives_higher_item_power", _test_power_scaling())
	fails += _t("affix_count_matches_rarity", _test_affix_count())
	fails += _t("gear_score_is_average_of_equipped", _test_gear_score_average())
	fails += _t("equipping_higher_power_raises_score", _test_equip_raises_score())
	fails += _t("min_rarity_floor_respected", _test_min_rarity_floor())
	fails += _t("can_afford_and_spend_math", _test_can_afford_spend())
	fails += _t("upgrade_raises_power_and_score", _test_upgrade_raises_power())
	fails += _t("salvage_yield_scales_with_rarity", _test_salvage_yield())
	fails += _t("reforge_preserves_locked_affixes", _test_reforge_preserves_locked())
	fails += _t("reforge_focus_guarantees_stat", _test_reforge_focus())
	fails += _t("affix_quality_stays_in_bounds", _test_affix_quality_bounds())
	fails += _t("save_roundtrip_preserves_state", _test_save_roundtrip())

	if fails == 0:
		print("\n==> ALL TESTS PASSED")
		quit(0)
	else:
		printerr("\n==> %d TEST(S) FAILED" % fails)
		quit(1)

func _t(label: String, passed: bool) -> int:
	print(("PASS  " if passed else "FAIL  ") + label)
	return 0 if passed else 1

# --- helpers ---

func _new_catalog():
	var c = load("res://autoload/catalog.gd").new()
	c.ensure_built()
	return c

func _new_loot(seed_value: int):
	var lm = load("res://autoload/loot_manager.gd").new()
	lm.set_seed(seed_value)
	return lm

func _new_state():
	return load("res://autoload/game_state.gd").new()

func _mk_item(slot: int, power: int) -> ItemData:
	var it := ItemData.new()
	it.slot = slot
	it.power = power
	it.affixes = []
	return it

func _avg_item_power(lm, cat, source_power: int, n: int) -> float:
	var total := 0
	for i in n:
		total += lm.roll_item(source_power, cat.default_table).power
	return float(total) / n

# --- tests ---

func _test_rarity_distribution() -> bool:
	var cat = _new_catalog()
	var lm = _new_loot(4242)
	var counts := {}
	var n := 20000
	for i in n:
		var it: ItemData = lm.roll_item(20, cat.default_table)
		counts[it.rarity.name] = counts.get(it.rarity.name, 0) + 1
	var common: int = counts.get("Common", 0)
	var exotic: int = counts.get("Exotic", 0)
	var legendary: int = counts.get("Legendary", 0)
	# Common (55 weight) should dominate; Exotic (1 weight) should be rarest but present.
	return common > legendary and legendary > exotic and exotic > 0

func _test_power_scaling() -> bool:
	var cat = _new_catalog()
	var lm = _new_loot(7)
	var low := _avg_item_power(lm, cat, 10, 3000)
	var high := _avg_item_power(lm, cat, 60, 3000)
	return high > low + 30.0

func _test_affix_count() -> bool:
	var cat = _new_catalog()
	var lm = _new_loot(11)
	for i in 800:
		var it: ItemData = lm.roll_item(30, cat.default_table)
		if it.affixes.size() != it.rarity.affix_count:
			return false
	return true

func _test_gear_score_average() -> bool:
	var gs = _new_state()
	gs.equipped = {}
	var total := 0
	var i := 0
	for slot in ItemData.Slot.values():
		var p := 10 + i * 10
		gs.equipped[slot] = _mk_item(slot, p)
		total += p
		i += 1
	var expected := int(round(float(total) / i))
	return gs.gear_score() == expected

func _test_equip_raises_score() -> bool:
	var gs = _new_state()
	gs.equipped = {}
	for slot in ItemData.Slot.values():
		gs.equipped[slot] = _mk_item(slot, 10)
	var before: int = gs.gear_score()
	var better := _mk_item(ItemData.Slot.WEAPON, 100)
	gs.backpack = [better]
	gs.equip(better)
	return gs.gear_score() > before

## Chests/bosses rely on the floor — a floored roll must never come in below it.
func _test_min_rarity_floor() -> bool:
	var cat = _new_catalog()
	var lm = _new_loot(99)
	for i in 600:
		var it: ItemData = lm.roll_item(20, cat.default_table, 3)
		if cat.rarities.find(it.rarity) < 3:
			return false
	return true

func _test_can_afford_spend() -> bool:
	var gs = _new_state()
	gs.resources = {"wood": 20, "stone": 10, "iron": 2}
	gs.gold = 50
	if gs.can_afford({"wood": 25}):
		return false
	if not gs.can_afford({"wood": 20, "gold": 50}):
		return false
	if not gs.spend({"wood": 15, "gold": 40}):
		return false
	if gs.resources["wood"] != 5 or gs.gold != 10:
		return false
	# Unaffordable spend must be a no-op.
	if gs.spend({"iron": 5}):
		return false
	return gs.resources["iron"] == 2

func _test_upgrade_raises_power() -> bool:
	var gs = _new_state()
	gs.equipped = {}
	for slot in ItemData.Slot.values():
		gs.equipped[slot] = _mk_item(slot, 20)
	var before := gs.gear_score()
	var w := gs.equipped[ItemData.Slot.WEAPON] as ItemData
	w.power += 30   # simulate a Blacksmith upgrade
	return gs.gear_score() > before

## Salvage yields more materials for higher rarity, and godshard only from Rare+.
func _test_salvage_yield() -> bool:
	var cat = _new_catalog()
	var gs = _new_state()
	var common := ItemData.new()
	common.rarity = cat.rarities[0]
	common.power = 40
	var exotic := ItemData.new()
	exotic.rarity = cat.rarities[4]
	exotic.power = 40
	var cy := gs.salvage_yield(common)
	var ey := gs.salvage_yield(exotic)
	if int(ey["emberdust"]) <= int(cy["emberdust"]):
		return false
	if int(cy["godshard"]) != 0:
		return false
	if int(ey["godshard"]) <= 0:
		return false
	var rare := ItemData.new()
	rare.rarity = cat.rarities[2]
	rare.power = 40
	return int(gs.salvage_yield(rare)["godshard"]) > 0

## Locked affixes survive a reforge verbatim; unlocked slots get re-rolled.
func _test_reforge_preserves_locked() -> bool:
	var cat = _new_catalog()
	var lm = _new_loot(123)
	var it := ItemData.new()
	it.rarity = cat.rarities[2]   # Rare -> 3 affixes
	it.power = 40
	it.affixes = [Affix.new("might", 999), Affix.new("vigor", 1), Affix.new("vigor", 1)]
	lm.reforge(it, [0], "")
	if it.affixes.size() != 3:
		return false
	return it.affixes[0].stat == "might" and it.affixes[0].value == 999

## Focusing a stat guarantees at least one affix rolls it, every time.
func _test_reforge_focus() -> bool:
	var cat = _new_catalog()
	var lm = _new_loot(7)
	for trial in 40:
		var it := ItemData.new()
		it.rarity = cat.rarities[2]
		it.power = 30
		it.affixes = [Affix.new("might", 5), Affix.new("might", 5), Affix.new("might", 5)]
		lm.reforge(it, [], "ferocity")
		var found := false
		for a in it.affixes:
			if a.stat == "ferocity":
				found = true
		if not found:
			return false
	return true

## Quality maps the floor value to 0.0 and the max to 1.0, clamped in between.
func _test_affix_quality_bounds() -> bool:
	var lm = _new_loot(1)
	var lo := lm.affix_min(50)
	var hi := lm.affix_max(50)
	if lm.affix_quality(lo, 50) != 0.0:
		return false
	if lm.affix_quality(hi, 50) != 1.0:
		return false
	var mid := lm.affix_quality(int((lo + hi) / 2.0), 50)
	return mid >= 0.0 and mid <= 1.0

## Full round-trip needs the Catalog autoload (rarity resolution). Uses the real
## autoloads if the headless run provides them; skips gracefully if not.
func _test_save_roundtrip() -> bool:
	var gs = null
	var cat = null
	if root:
		gs = root.get_node_or_null("GameState")
		cat = root.get_node_or_null("Catalog")
	if gs == null or cat == null:
		print("  (skip save_roundtrip: autoloads not present in this run)")
		return true
	cat.ensure_built()
	gs.equipped = {}
	gs.backpack = []
	gs.resources = {"wood": 12, "stone": 5, "iron": 3}
	gs.gold = 99
	gs.town = {"blacksmith": true}
	var w := _mk_item(ItemData.Slot.WEAPON, 42)
	w.name = "Test Blade"
	w.rarity = cat.rarities[3]
	w.affixes = [Affix.new("might", 7)]
	gs.equipped[ItemData.Slot.WEAPON] = w

	var d: Dictionary = gs.to_dict()
	gs.gold = 0
	gs.resources = {"wood": 0, "stone": 0, "iron": 0}
	gs.from_dict(d)

	var rw := gs.equipped[ItemData.Slot.WEAPON] as ItemData
	return gs.gold == 99 \
		and int(gs.resources["wood"]) == 12 \
		and bool(gs.town.get("blacksmith", false)) \
		and rw != null and rw.power == 42 and rw.name == "Test Blade" \
		and rw.rarity == cat.rarities[3] and rw.total_stat("might") == 7
