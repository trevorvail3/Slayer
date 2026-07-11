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

## v0.7 — Living Open World
The zone (`zone.gd`) becomes a living patrol driven by an **activity director**:
- **Relics** (`scripts/world/relic.gd`) — collectibles that grant gold/iron and a
  **persisted** relic count (`GameState.relics_found`, saved).
- **Blood Surge** (public event) — a toughened horde with a **kill quota under a
  timer**; success drops a Legendary+ reward chest.
- **The Colossus** (world boss) — `Enemy.world_boss` flag: huge HP/scale, deep-red;
  drops 5 Legendary+ rolls, big gold, and a bonus relic.
- Director cycles ambient → event → (every 3rd) world boss; the HUD banner tracks the
  current activity and event countdown. HUD resource readout shows Relics.

## Polish Pass (visual) + World Bible
A step-back polish round to make it read as a real game, plus the lore foundation.
- **Humanoid enemy rigs** — capsules replaced by code-built bodies (torso/head/arms/
  legs + a held prop) sized per archetype and the Colossus; shared material for flashes.
- **Procedural animation** — face-the-player, walk cycle, wind-up arm raise, idle sway,
  and a **death topple** (fall + sink) with corpse collision disabled.
- **VFX** — reusable `scripts/fx/hit_burst.gd` (`GPUParticles3D`) via `Combat.spawn_hit`;
  hit sparks on damage + a death puff.
- **Player juice** — camera head-bob while moving + a landing dip.
- **Lighting/grade** — filmic tonemap, glow/bloom, saturation/contrast, tuned sky & fog
  (moody wilds, warm town).
- **World Bible** — `docs/lore/`: setting, the enemy roster, the town & returning NPCs,
  the three orders (classes), bosses, timeline, tone/naming, glossary. *(Revised — see below.)*
- *Deferred (riskier):* custom toon/outline shader; modeled-character asset packs.

## Lore v2 — Mythic Aldermoor ("300 in a Destiny game")
Major setting pivot (docs only, no code): dropped the "Blight/corruption"; adopted a
grounded **bronze-age / mythic-Greek** world of feuding **city-states**.
- **Creation myth:** the god **Vael** slew the god **Aldmar**; his body *became* the
  world (Aldermoor). *Why* she did it is **contested** — the schism that split mankind
  into rival **faiths** (the Gift / Betrayal / Mourning / Deniers).
- **You:** a **Slayer** bearing **Vael's Mark** — a mortal who fights like a demigod.
- **Phase 1 enemies:** men, the risen dead (raised by the **Ossuary Cult**), and beasts.
  **Mythic monsters** (centaurs, minotaurs, cyclopes, Bone-Titans) are the escalation.
- **Bosses reframed:** the Warlord → a mortal tyrant **war-king** (Nemesis basis); the
  Colossus → a **Bone-Titan**, an animate fragment of the dead god.
- Rewrote all `docs/lore/` notes + added Creation Myth, Faiths & Schism, Factions,
  Regions & City-States, Bestiary, and The Dead & the Ossuary Cult.

## Polish finish (lore-integrated)
Completed the deferred polish and pushed the lore into the game's surfaces:
- **Toon outlines** — `scripts/fx/toon.gd` inverted-hull `next_pass` material (no custom
  shader) on enemy rigs, held props, and the player's weapon.
- **UI theme** — `scripts/ui/ui_theme.gd`, a shared bronze-parchment `Theme` applied to
  every menu (inventory, blacksmith, vault, class select).
- **Lore reflavor** — enemy tints → bronze-age (levy/champion/skirmisher, bronze war-king,
  pale **Bone-Titan**); world-boss banner → "The Bone-Titan wakes"; public event →
  "Warband Assault"; class blurbs tied to the orders (Bulwark/Veiled/Ember-Marked).

## v0.8 — The Reach (Cosmodrome-scale zone + loot scarcity)
The wilds became a real patrol destination, mapped to [[Regions and City-States]]:
- **Five named regions** tiling a ~4× larger map, each with its own ground, landmarks
  (camps with firelight, a watchtower, a broken colonnade & aqueduct, burial mounds
  and standing stones, plateaus and giant pale ribs), power band (8→32), and a
  **weighted roster of named enemy variants** (Levy Spearman → Draugr → Cave-Lion...).
- **Region discovery banners** (Destiny-style fade) on crossing a border.
- **Wander/aggro AI** — enemies patrol near their spawn, aggro at range or on damage,
  and leash back; no more cross-map beelines. New **BEAST** archetype: fast quadruped
  (wolves/boars/lions) with a crouch-lunge.
- **◆ Elites** — per-region chance; bigger/tougher, name label, guaranteed Uncommon+ drop.
- **Activities placed in the world** — Warband Assaults erupt in your region; the
  **Bone-Titan always wakes in the Foothills** (travel to it). Chests/relics/resource
  nodes distributed across all five regions.
- **Loot scarcity** — trash drop chance ~12% (was 100%); rarity weights now
  79/15/4.5/1.2/**0.3** (Exotic). Elites/bosses/chests pay via min-rarity floors.
  New headless test locks the floor behavior.
- **Traversal** — auto-run after ~1s of forward movement (+35% speed, FOV widens).

## v0.9 — Crafting & god-rolls
The bottomless loot-chase pillar: turn the flood of drops into a currency and give the
Forge real *targeting* so a great item is something you can build toward, not just pray for.
- **Salvage** — break down unwanted gear (backpack only) into crafting materials.
  Per-item **Salvage** buttons + a **"Salvage all Common / Uncommon"** one-click for the
  trash. Yields scale with rarity & power; rarity index is derived from `affix_count`, so
  the math needs no Catalog lookup and stays testable.
- **Two materials** — **Emberdust** (bulk, from every salvage) and **Godshard** (premium,
  only from Rare+). Both live in `GameState.resources`; `from_dict` now *merges* saved
  resources over the defaults, so materials added in future versions default to 0 on old
  saves instead of vanishing.
- **Reforge, upgraded (`LootManager.reforge`)** — instead of a blind full re-roll you can
  **lock** the affixes you want to keep (preserved verbatim) and **focus** a stat
  (guarantees one fresh affix rolls it). Locking/focusing is the targeting, so it spends
  **Godshard**; a plain re-roll spends **Emberdust**.
- **God-roll readout** — a single roll-value formula in `LootManager` (`affix_min/max`)
  now also drives **`affix_quality` (0→1)**. The Forge shows per-affix **★ ratings** and a
  **"★ GOD ROLL ★"** banner when a multi-affix item averages near-max quality.
- **UI/economy plumbing** — materials shown on the HUD readout, the inventory stats panel,
  and the Forge cost line. Four new headless tests cover salvage yields, lock preservation,
  focus guarantee, and quality bounds.
- *Deferred:* **Nemesis war-kings** (the emergent-rival half of v0.9) → tracked as v0.9b.

## Art pipeline + UI overhaul (in progress)
Groundwork to make it read like a real game (see [[Art Pipeline]]).
- **Optional-asset pipeline** — `AssetLoader` (auto-loaded HDRI skies + ground
  textures, auto-fitted models with safe fallbacks). First CC0 art shipped:
  Kiara Dawn sky (town + wilds) and an animated Fox wired to the BEAST enemy.
- **UI overhaul — Phase 1 (start menu + intro):**
  - New **dark-glass + bronze** `UITheme` (palette constants + styleboxes) — the
    whole menu set re-skins from this one file.
  - **Typography** (marketable identity): **Cinzel** (Roman inscriptional caps) on
    every title/header + discovery banner; **Alegreya Sans** as the global UI font.
    Both OFL, in `assets/fonts/`; wired via `UITheme.display_font()` / `body_font()`
    / `style_title()`.
  - **Main menu** is now the boot scene (`scenes/main_menu.tscn`): New Game /
    Continue / Quit. Class selection moved to a Destiny-style **character
    creation** screen (`character_create.gd`); the in-town Shrine stays as respec.
  - **Story intro** (`story_intro.gd`) — the creation myth as a fading opening
    after New Game, then into the world.
  - `Game.new_game(kind)` / `continue_game()` + `GameState.reset_new_game()`.
- **UI overhaul — Phase 2 (HUD):** rebuilt the flat absolute-positioned HUD into
  anchored, glass-paneled clusters — vitals bottom-left (class · POWER, health
  with numeric overlay, stamina), a super meter + **ability chips** (Move/Ability/
  Super with keybind + live cooldowns, dim when charging) bottom-center, a
  currencies panel top-right, and objective + Cinzel region-banner top-center.
  Dark text outlines keep it legible over the bright sky. Same public API
  (`notify`/`set_objective`/`show_region`), so hub/zone are unchanged.
  - *Next phases:* in-menu polish pass, in-world guided-steps tutorial.

