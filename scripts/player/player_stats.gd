class_name PlayerStats
extends RefCounted

## Derived combat values, computed live from GameState's equipped gear.
## Kept static + stateless so any system can query current stats cheaply.

static func max_health() -> int:
	return 100 + GameState.total_stat("vigor") * 5

static func attack_damage() -> int:
	return 10 + GameState.total_stat("might") * 2 + GameState.gear_score()

## Diminishing-returns damage reduction from Fortitude, capped at 75%.
static func damage_reduction() -> float:
	var f := float(GameState.total_stat("fortitude"))
	return clampf(f / (f + 100.0), 0.0, 0.75)

## Swiftness drives stamina pool and movement speed.
static func max_stamina() -> float:
	return 100.0 + GameState.total_stat("swiftness") * 4.0

static func move_speed() -> float:
	return 6.0 + GameState.total_stat("swiftness") * 0.12

## Ferocity drives crit chance (1% per point, capped) and crit damage.
static func crit_chance() -> float:
	return clampf(GameState.total_stat("ferocity") * 0.01, 0.0, 0.6)

static func crit_multiplier() -> float:
	return 2.0
