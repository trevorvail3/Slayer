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
