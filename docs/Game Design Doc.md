---
title: Game Design Doc
tags: [slayer, design, gdd]
---

# Game Design Doc

← [[Home]] · related: [[Roadmap]], [[Systems and Architecture]], [[Decisions and Open Questions]]

## What we're building
A fully 3D, first-person fantasy looter-slasher — "Destiny 2 with swords and
shields." The core drive is the **loot & Power grind**, delivered through open-world
zones, a rebuildable hub town, a campaign, and endgame raids. Not a 1:1 Destiny
clone — a vertical slice expanded milestone by milestone. Solo-first; co-op is a
late stretch.

## Design pillars
1. **Weight & power** — every swing/stomp feels heavy and testosterone-fueled.
2. **The grind is the game** — an always-climbing **Power Level**; numbers go up.
3. **Loot chase** — rarities, stat rolls, Exotics, **god-rolls** via crafting.
4. **The town is yours** — *the differentiator.* A run-down town **you** rebuild from
   gathered resources; each building is a returning **named NPC** who unlocks a
   system. Destiny's Tower is static — ours grows because of you. (Destiny × Stardew.)
5. **Living open world** — collectibles, **public events**, roaming **world bosses**,
   and **Nemesis Warlords** that generate emergent stories.
6. **Endgame that respects mastery** — strikes & raids with mechanics; fashion/transmog
   for the long tail.

## Stats
`Might` (melee dmg) · `Vigor` (health) · `Fortitude` (block / damage reduction) ·
`Swiftness` (stamina & move speed) · `Ferocity` (crit / ability charge).

## Rarities
Common · Uncommon · Rare · Legendary · **Exotic** (gold, build-defining chase items).

## Core systems (the full vision)
- **Weapon archetypes** (Destiny model, all-class): sword, greatsword, battleaxe,
  spear, bow, crossbow — each a *distinct feel*, not a skin. See [[Milestone Log]] (v0.5).
- **Classes & Supers** (3 to start, e.g. Warden / Stalker / Runecaster): movement
  ability, class ability, grenade-equivalent, melee, and a chargeable **Super**
  (Ferocity-fed). Martial-with-mystic tone.
- **Elements as flavor** — burn / chill / shock status effects; *no* shield match-game.
- **Hub town (rebuildable)** — gather → rebuild buildings → each activates a vendor/
  system + returning NPC. Town tier rises visibly. See [[Milestone Log]] (v0.4).
- **Open-world zones** — biomes, waypoints, collectibles, **public events**,
  **world bosses**, **Nemesis Warlords**.
- **Crafting & god-rolls** — random perks + patterns to craft & re-roll toward a god roll.
- **Nemesis Warlords** — procedurally-named rivals that grow stronger and taunt you
  if they escape; hunt for unique loot.
- **Transmog & fashion** — appearance slots + dyes, looks decoupled from stats.
- **Progression & meta** — Character Level (abilities/skill tree) + Power Level (gear
  gate); save/load; vendor reputations; infusion/upgrade; bounties.
- **Story & endgame** — campaign missions, strikes (mini-dungeons), **raids**
  (multi-encounter mechanics), seasonal loot refresh. **Co-op** = the big late stretch.

## Constraints & working style
- Engine **Godot 4**, GDScript, placeholder-primitive art first.
- **AI (Claude Code) writes ~all the code**; the human playtests and directs.
- Fully text-based toolchain so the whole project is authorable as code.
- **Every milestone ends in a runnable, playable build.**
