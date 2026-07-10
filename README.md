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

## Current milestone: **v0.6 — Classes & Supers**

Pick a **class** at the **Shrine of Paths** in town. Each has a movement ability, a
class ability, and a chargeable **Super** (fill the meter by dealing damage — Ferocity
charges it faster):

- **Warden** (tank) — Shoulder Dash · **Barricade** wall · **Ground Slam** super
- **Stalker** (agile) — Dodge Roll (i-frames) · **Caltrops** · **Blade Storm** super
- **Runecaster** (mystic) — Blink · **Runic Rift** (heal zone) · **Meteor Storm** super

Abilities: **Shift** = movement, **Q** = class ability, **F** = Super (when full).
Your class is saved with your character.

Built on: v0.5 weapon archetypes, v0.4 hub town + save/load, v0.3 Slice Zone, v0.2 combat feel, v0.1 loot loop.

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
| **Left click** | Melee swing (costs stamina) — also **gathers** from trees/rocks in town |
| **Right click (hold)** | Raise shield / block — tap it right as a hit lands to **parry** |
| **E** | Interact — build/use town plots, vendors, the class shrine |
| **Shift** | Movement ability (dash / dodge / blink) |
| **Q** | Class ability (barricade / caltrops / rift) |
| **F** | Super (when the meter is full) |
| **Tab** / **I** | Toggle inventory (equip gear) |
| **Esc** | Close a vendor/menu |

Start in **town**: gather at the trees/rocks, press **E** at a ruined plot to build
it, then walk onto the **north gate pad** to enter the wilds. In the wilds, the
**pad to the north** returns you to town (progress autosaves on travel).

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
autoload/    # singletons: Catalog, LootManager, GameState, Combat, SaveManager, Game (travel/input)
data/        # Resource classes: ItemData, Rarity, Affix, LootTable
scripts/     # hub.gd, zone.gd + player, enemies, world (nodes/build sites/pads), ui, fx
scenes/      # hub.tscn (start) + zone.tscn (thin entry points; scenes built in code)
test/        # headless logic tests
```

Design conventions: content is data-driven (add gear/buildings = add a Catalog entry),
stats/resources recompute via `GameState` signals, loot RNG is seedable for tests,
and progress persists via `SaveManager` (`user://slayer_save.json`).

---

## Roadmap

| Ver | Milestone |
|-----|-----------|
| v0.1 | Loot Loop: kill → rarity loot → equip → Power climbs |
| v0.2 | Combat feel: sword swings, block/parry, hit-stop, damage numbers, stamina |
| v0.3 | The Slice Zone: enemy variety, health bars, chests, Warlord mini-boss |
| v0.4 | The Hub Town: gather, rebuild town, Blacksmith/Vault vendors, save/load |
| v0.5 | Weapon archetypes: sword/greatsword/axe/spear/bow/crossbow, distinct feel |
| **v0.6** | **Classes & Supers: 3 classes, movement/class ability + chargeable Super** ← *you are here* |
| v0.7 | Living open world: collectibles, public events, world bosses |
| v0.8 | Crafting & god-rolls + Nemesis Warlords |
| v0.9 | Progression/meta: char levels, skill trees, reputations, transmog |
| v1.0 | Story campaign + first Strike (raids & co-op post-1.0) |
