---
title: Milestone Log
tags: [slayer, changelog]
---

# Milestone Log

← [[Home]] · plan side: [[Roadmap]] · code side: [[Systems and Architecture]]

What actually shipped, per version. (Git branch: `claude/fantasy-looter-game-planning-3hrz5x`.)

## v0.1 — The Loot Loop
The addictive core. First-person controller; one enemy; kill → **rarity-rolled loot
drops** (Common→Exotic) with stat affixes → walk over to collect → **equip** →
**Power Level** (average power of equipped gear) climbs. Data-driven items
(`ItemData`/`Rarity`/`Affix`/`LootTable`), seedable `LootManager`, inventory UI,
headless logic tests. Placeholder primitives.

## v0.2 — Combat Feel
Made it feel like *slaying*. Visible first-person **sword with a real swing arc**,
**hit-stop** + camera kick + enemy knockback, floating **damage numbers** with
**crits** (Ferocity), **shield block (right-click) + parry window** that staggers
enemies, enemy **wind-up tells**, and a **stamina** economy. Also fixed a
forward-drift movement bug.

## v0.3 — The Slice Zone
Gave combat somewhere to live. Bigger zone with cover/ramps; **three enemy
archetypes** (Grunt, heavy knockback-resistant **Brute**, ranged **Archer** with
projectiles); **health bars**; **loot chests** (guaranteed Rare+); and an activity
loop — cull the horde → **slay the Warlord** mini-boss for guaranteed Legendary+.

## v0.4 — The Hub Town
The meta-progression spine. Start in a **safe town you rebuild.** Travel pad ↔
combat zone (enemies drop **Gold**). **Gather** Wood/Stone/Iron by hitting trees &
rocks with your weapon. Press **E** at ruined plots to **rebuild buildings** — each
a returning NPC: **Blacksmith** (Bruna: upgrade Power / reforge affixes), **Vault**
(Aldous: stash), **Waystone**, **Tavern**. **Save/load** so everything persists
(`user://slayer_save.json`).

### v0.4.1 — UI hotfix
World signs (building/travel labels) were `fixed_size` + `no_depth_test`, so distant
labels ballooned and piled into an unreadable center mess — fixed to scale with
distance and respect depth. HUD top bar re-laid-out so objective ↔ resources no
longer collide.

## v0.5 — Weapon Archetypes
The equipped weapon's **type drives the whole moveset** (Destiny model). Six
families, each with its own view model, animation, damage/pace/reach, and trait:
- **Sword** — fast balanced slashes
- **Greatsword** — slow overhead that **sweeps all enemies in front**
- **Battleaxe** — chops that apply a **bleed** DoT
- **Spear** — quick **long-reach** thrusts
- **Bow** — **hold to draw / release to fire**; full charge = more damage + crit
- **Crossbow** — fast bolts on a reload cadence

Central table in `data/weapon_defs.gd`; loot rolls across all six; inventory shows
each weapon's type.

## v0.6 — Classes & Supers
Pick a **class** at the **Shrine of Paths** in town (saved with your character).
Three classes, each with a movement ability, a class ability, and a chargeable
**Super** (fills from dealing damage; **Ferocity** charges it faster):
- **Warden** (tank) — Shoulder Dash · Barricade (temp wall) · **Ground Slam** (AoE)
- **Stalker** (agile) — Dodge Roll (i-frames) · Caltrops (ground DoT) · **Blade Storm** (rapid AoE)
- **Runecaster** (mystic) — Blink · Runic Rift (heal zone) · **Meteor Storm** (rain of AoE)

Inputs: **Shift** movement · **Q** class ability · **F** Super. HUD gains a class
label, Super meter, and ability-cooldown readout. Class defs in `data/class_defs.gd`;
ability objects in `scripts/abilities/`.
