---
title: Systems and Architecture
tags: [slayer, architecture, code]
---

# Systems and Architecture

← [[Home]] · design side: [[Game Design Doc]] · history: [[Milestone Log]]

A map of the codebase so the vault documents the code, not just the vision.

## Engine & conventions
- **Godot 4.x**, Forward+ renderer, **GDScript**.
- **Thin `.tscn` + procedural build**: scene files are near-empty (a root node + a
  script); the script builds the whole scene tree in code. Robust for AI authoring,
  clean git diffs.
- **Data-as-Resources**: items/rarities/loot tables are `Resource` classes.
- **Signal-driven**: state changes emit signals; UI and systems react (never poll).
- **Seedable RNG** in `LootManager` for reproducible tests.
- **Persistence**: JSON at `user://slayer_save.json` via `SaveManager`.

## Autoloads (singletons)
- `Catalog` — content definitions (rarities, base items incl. weapon types, building defs).
- `LootManager` — `roll_item(power, table, min_rarity_index)`, `reroll_affixes(item)`.
- `GameState` — equipped/backpack/stash, resources, gold, town; `gear_score()`,
  `total_stat()`, `can_afford()`/`spend()`; `to_dict()`/`from_dict()`; emits
  `equipment_changed`, `backpack_changed`, `resources_changed`, `town_changed`.
- `Combat` — hit-stop (unscaled) + floating damage numbers.
- `SaveManager` — save/load/has_save/delete.
- `Game` — shared input map, **Hub↔Zone travel** (`goto_hub`/`goto_zone`), `menu_open`,
  loads the save on boot.

## Data resources (`data/`)
- `ItemData` — slot enum, **`weapon_type`** (SWORD…CROSSBOW), rarity, power, affixes.
- `Rarity`, `Affix`, `LootTable`.
- `WeaponDefs` — static per-archetype table: ranged/charge/sweep/bleed flags, damage
  mult, cooldown, windup, reach, stamina, anim, view color, hold/swing poses.

## Gameplay scripts (`scripts/`)
- `hub.gd` / `zone.gd` — the two world builders (Hub = safe town; Zone = combat).
- `player/player.gd` — FP controller; rebuilds view model + moveset from the equipped
  weapon; melee (slash/overhead/chop/thrust), ranged fire, greatsword sweep, axe
  bleed, shield block/parry, stamina, camera juice.
- `player/player_stats.gd` — derived stats (max health/stamina, attack damage, crit,
  move speed) from equipped gear.
- `player/arrow.gd` — player projectile (bow/crossbow).
- `enemies/enemy.gd` — Grunt/Brute/Archer + boss; wind-up/stagger/knockback, bleed
  DoT, health bar, loot + gold on death.
- `enemies/projectile.gd` — enemy projectile.
- `world/resource_node.gd` — gatherable tree/rock/ore (mined by hitting it).
- `world/build_site.gd` — rebuildable plot (press E).
- `world/travel_pad.gd` — Hub↔Zone pad.
- `world/chest.gd` — world loot chest.
- `fx/health_bar_3d.gd`, `fx/damage_number.gd`.
- `ui/hud.gd`, `ui/inventory_ui.gd`, `ui/blacksmith_ui.gd`, `ui/vault_ui.gd`.

## Scenes (`scenes/`)
- `hub.tscn` — **main scene** (game starts in town).
- `zone.tscn` — the combat zone.

## Key flows
- **Loot:** `Enemy.die()` / `Chest` → `LootManager.roll_item()` → `LootDrop` →
  pickup → `GameState.add_to_backpack` → equip → `equipment_changed` recomputes stats.
- **Weapon feel:** equipped `ItemData.weapon_type` → `WeaponDefs.get_def()` → player
  rebuilds view model and branches attack behavior.
- **Save:** travel/quit → `SaveManager.save_game()` → `GameState.to_dict()` → JSON;
  boot → `Game._ready` → `SaveManager.load_game()` → `GameState.from_dict()`.

## Tests
Headless logic suite: `test/run_tests.gd`
`godot --headless --path . -s res://test/run_tests.gd`
Covers rarity distribution, power scaling, affix counts, gear-score math,
economy (`can_afford`/`spend`), upgrades, and save round-trip.
