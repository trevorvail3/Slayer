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

## Current milestone: **v0.9 — Crafting & god-rolls**

The loot flood is now a **currency and a craft.** Break down gear you don't want into
materials, then use them at **the Forge** to chase a *god roll* on purpose:

- **Salvage** unwanted backpack items into **Emberdust** (bulk) and **Godshard** (premium,
  Rare+ only) — with a one-click **"Salvage all Common / Uncommon"** for the trash.
- **Reforge** at Bruna's forge: **lock** the affixes you want to keep, **focus** a target
  stat to guarantee it, and re-roll the rest. Locking/focusing spends Godshard; a plain
  re-roll spends Emberdust.
- Every affix now shows a **★ quality rating**, and a **"★ GOD ROLL ★"** banner lights up
  when a piece rolls near-perfect across the board. That's the item you keep forever.

Built on **v0.8 — The Reach:**

The wilds are a **Cosmodrome-scale patrol zone**: five named lore regions, each
with its own terrain, landmarks, danger level, and enemy roster — with a Destiny-style
**discovery banner** as you cross into each:

| Region | Feel | Foes (Power) |
|--------|------|--------------|
| **The Olive Plains** | open fields, camps, a watchtower | levies, peltasts, champions, wolves (8–14) |
| **The Hollow Wood** | dense dark forest | wolves, boars, feral hunters, outlaws (12–18) |
| **The Broken Road** | ruined colonnade & aqueduct | sellswords, mercenaries, war-hounds (14–20) |
| **The Barrowlands** | burial mounds, standing stones | **draugr**, barrow-wights, bone archers (18–26) |
| **The Bonereach Foothills** | plateaus & giant pale ribs | veterans, brutes, cave-lions (24–32) |

Enemies **patrol and wander** their home ground (no more cross-map beelines), come in
**named variants** per region, and can roll as **◆ elites** — bigger, deadlier, and
guaranteed to drop. A new **beast** archetype (quadruped wolves/boars/lions) lunges in
packs. **Warband Assaults** erupt where you're standing; **the Bone-Titan** always
wakes in the Foothills — travel north-west to face it. Keep moving forward and you
**break into a run** (with a subtle FOV kick) to cross the distances.

**Loot is scarce now (by design):** most kills drop *nothing* — a Common is a find,
an Exotic is legend-tier (~0.3% of drops). Elites, bosses, events, and chests are
where the real loot lives. Grind accordingly.

**Polish pass:** enemies are **humanoid figures** that walk, telegraph, and topple over
on death; hits throw **sparks**; the camera **head-bobs**; a filmic, bloom-lit color
grade; **toon outlines** on characters/weapons; and a shared **bronze-parchment UI theme**
on every menu. The world is now **mythic Aldermoor** ("300 in a Destiny game") — a
grounded bronze-age land that is literally the body of a slain god. Full lore in
`docs/lore/` (start at *World Bible (Home)*): the creation myth, the faiths & schism,
the city-state factions, the orders (classes), the **Bone-Titan**, and more.

Built on: v0.6 classes & Supers, v0.5 weapon archetypes, v0.4 hub town + save/load, v0.3 Slice Zone, v0.2 combat feel, v0.1 loot loop.

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
| v0.6 | Classes & Supers: 3 classes, movement/class ability + chargeable Super |
| v0.7 | Living open world: relics, public events, world boss |
| v0.8 | The Reach: Cosmodrome-scale zone, 5 regions, elites, beasts, loot scarcity |
| **v0.9** | **Crafting & god-rolls: salvage → materials, reforge with lock + focus, quality/god-roll readout** ← *you are here* |
| v0.9b | Nemesis war-kings (emergent rivals — second half of v0.9) |
| v0.95 | Progression/meta: char levels, skill trees, faction reputation, transmog |
| v1.0 | Story campaign + first Strike (raids & co-op post-1.0) |
