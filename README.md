# Slayer

A fully 3D, **first-person fantasy looter** — "Destiny 2 with swords and shields."
Hyper-masculine power fantasy: jacked barbarian-knights slaying fantasy monsters.
The core drive is the **loot & gear-score grind** — kill bigger things, get bigger
loot, raise your **Power**, repeat.

Built in **Godot 4** (GDScript). This repo is a long-term project built milestone
by milestone; each milestone is independently playable.

> Full design + roadmap lives in the planning doc referenced by the team. Short
> version of the roadmap is at the bottom of this file.

---

## Current milestone: **v0.3 — The Slice Zone**

Combat now has a place to live and a reason to fight. A larger zone with cover,
rocks and ramps; **three enemy archetypes** (Grunt, heavy **Brute**, ranged
**Archer** that lobs projectiles); **health bars** over enemies; **loot chests**
you pop for guaranteed Rare+ gear; and an activity loop — **cull the horde**, then
**slay the Warlord** mini-boss for guaranteed Legendary+ loot.

Built on: v0.2 combat feel (sword swings, block/parry, hit-stop, damage numbers,
stamina) and v0.1 the loot loop (kill → rarity loot → equip → Power climbs).

### Run it

1. Install [Godot 4.3+](https://godotengine.org/download) (standard, not .NET).
2. Open this folder as a project in the Godot editor (it detects `project.godot`).
3. Press **F5** (Play).

### Controls

| Input | Action |
|-------|--------|
| **WASD** | Move |
| **Mouse** | Look |
| **Space** | Jump |
| **Left click** | Melee swing (costs stamina) |
| **Right click (hold)** | Raise shield / block — tap it right as a hit lands to **parry** |
| **Tab** / **I** | Toggle inventory (equip gear) |

### The loop to try

1. Left-click the red capsule monsters until they die — they drop a **glowing,
   rarity-colored cube**.
2. Walk over the cube → a loot toast pops and the item enters your backpack.
3. Press **Tab** → click a backpack item to **equip** it → watch **POWER** (top-left)
   and your stats climb. Tougher monsters drop higher-Power gear.

Rarities: `Common` · `Uncommon` · `Rare` · `Legendary` · `Exotic` (rarest & strongest).
Stats: `Might` · `Vigor` · `Fortitude` · `Swiftness` · `Ferocity`.

### Run the tests (headless)

Pure-logic systems (loot rolls, gear-score math) have a headless test suite:

```bash
godot --headless --path . -s res://test/run_tests.gd
```

Exits `0` if all pass, prints `PASS/FAIL` per test.

---

## Project layout

```
autoload/    # singletons: Catalog (content), LootManager (rolls), GameState (gear), SaveManager
data/        # Resource classes: ItemData, Rarity, Affix, LootTable
scripts/     # player, enemies, loot pickups, UI (HUD + inventory), main scene builder
scenes/      # main.tscn (thin entry point; scenes are built in code for now)
test/        # headless logic tests
```

Design conventions: content is data-driven (add gear = add a Catalog/`.tres` entry),
stats recompute via the `GameState.equipment_changed` signal, and loot RNG is
seedable for reproducible tests.

---

## Roadmap

| Ver | Milestone |
|-----|-----------|
| v0.1 | Loot Loop: kill → rarity loot → equip → Power climbs |
| v0.2 | Combat feel: sword swings, block/parry, hit-stop, damage numbers, stamina |
| **v0.3** | **The Slice Zone: bigger zone, enemy variety, health bars, chests, Warlord mini-boss** ← *you are here* |
| v0.4 | Abilities & builds: classes, dash/ground-slam/ultimate, gear mods |
| v0.5 | Progression & meta: levels, vendors, infusion, save/load |
| v0.6 | Campaign: missions, hub space, bosses |
| v0.7 | Endgame: strikes + a multi-encounter raid, Exotic/pinnacle rewards |
| v0.8+ | Co-op fireteams (stretch — the big lift) |
| v1.0 | Polish: art upgrade, audio, VFX, balance |
