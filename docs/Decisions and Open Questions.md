---
title: Decisions and Open Questions
tags: [slayer, decisions]
---

# Decisions and Open Questions

← [[Home]] · context: [[Game Design Doc]], [[Roadmap]]

## Locked-in decisions
- **Engine:** Godot 4 · **AI does ~all the code** · **placeholder art first**.
- **Weapons ↔ class: Destiny model** — any class wields any weapon; class defines
  abilities & Super. (Implemented as the weapon-type moveset system, [[Milestone Log]] v0.5.)
- **Elements: flavor only** — burn/chill/shock status effects; *no* enemy-shield
  match-game. Keeps combat grounded.
- **Committed extra pillars:** [[Nemesis Warlords]], crafting & god-rolls, public
  events & world bosses, transmog & fashion. (See [[Roadmap]] for phasing.)
- **Save/load pulled forward** into v0.4 — a town that reset each session would feel awful.

## The differentiator
The **rebuildable hub town** (Destiny × Stardew). Destiny's Tower is static; ours
grows because of the player. Lean into it — each building is a named NPC with a story.

## Open questions (not blocking current work)
- **Class fantasy** — exact names & Supers for the 3 launch classes (settle at v0.6).
  Working names: Warden (tank), Stalker (agile), Runecaster (mystic).
- **Weapon-feel tuning** — damage/pace/reach values live in `data/weapon_defs.gd`;
  balance from playtest.
- **Nemesis generation rules** & the public-event catalog (v0.7–0.8).
- **Co-op networking** — keep systems networking-friendly, but build solo; revisit
  post-1.0. It is the single biggest lift.
- **Art upgrade path** — asset packs vs. AI-generated models, once systems are proven.

> Placeholder note referenced above: create [[Nemesis Warlords]] when that system is designed.
