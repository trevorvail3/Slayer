---
title: Art Pipeline
tags: [slayer, art, assets, how-to]
---

# Art Pipeline — getting real art into the game, cheap

← [[Home]] · code side: [[Systems and Architecture]]

How we upgrade Slayer's visuals from procedural primitives to real 3D art **for
$0**, with a division of labour that fits how we work: **you download & drop
files in, Claude writes the code.** You never open a 3D modelling program.

> Reality check: Slayer is **first-person 3D**, so the thing that makes it look
> real is **3D models + textures + a real sky**, not 2D sprites (a sprite in a
> 3D world is a flat cutout that always faces you — 1993 Doom). The sources
> below are all 3D and all free.

## Glossary (ELI5)
- **Model / mesh** — the 3D shape (a sword, a wolf). The digital statue.
- **Texture** — the picture painted on the statue (rust, fur). Just a PNG.
- **Material** — the recipe: "use this texture, make it metal/rough."
- **Rig / skeleton** — invisible puppet bones inside a character so it can bend.
- **Animation** — a recorded dance for the skeleton (walk / attack / die).
- **HDRI / skybox** — a 360° photo of a sky wrapped around the world.
- **`.glb`** — the "MP3 of 3D": one file holding mesh + textures + rig +
  animations. **Godot opens it by dragging it in.** This is the format we want.

## Free sources (CC0 = do anything, no credit needed)
| Source | What | License | Best for |
|--------|------|---------|----------|
| **Quaternius** (quaternius.com) | low-poly characters/animals, pre-animated `.glb` | CC0 | ⭐ enemies |
| **Kenney** (kenney.nl) | weapon/prop/nature kits | CC0 | ⭐ weapons, props |
| **Poly Haven** (polyhaven.com) | PBR textures + HDRI skies | CC0 | ⭐ ground + sky |
| **ambientCG** (ambientcg.com) | PBR textures | CC0 | ground variety |
| **Mixamo** (mixamo.com) | rigged humans + animation library | Free (Adobe login) | human bosses (needs a Blender `.fbx`→`.glb` step) |
| **Sketchfab / itch.io** | everything | ⚠️ mixed — filter CC0/CC-BY | one-off hero pieces |

**Start with Quaternius + Kenney + Poly Haven** — all CC0, all `.glb`/`.png`, no
extra tools, no legal strings.

## Priority order (spend effort where it shows in first person)
1. **HDRI sky + ground textures** — a few files, transforms the mood. Cheapest win.
2. **Enemy models** (Quaternius, pre-animated) — replaces the capsule-people.
3. **Weapon view-models** (Kenney) — what you stare at all game.
4. **Props** (Kenney) — chests, rocks, buildings.

## The turnkey folders (drop-in, auto-loaded)
`AssetLoader` (`scripts/fx/asset_loader.gd`) is a safe optional-asset loader:
every hook is a **no-op that keeps the game running on primitives until a real
file appears.** Drop the file (Godot CLOSED → reopen so it imports) and it shows
up. See each folder's README for exact filenames.

- **`assets/skies/`** — `zone.hdr` (wilds) / `hub.hdr` (town). ⭐ Do this first.
- **`assets/textures/`** — `ground_town.png`, `ground_plains.png`, `ground_wood.png`,
  `ground_road.png`, `ground_barrow.png`, `ground_foothills.png`.
- **`assets/models/`** — `.glb` meshes. **Not auto-wired** (see below).

Models aren't auto-loaded because the code needs the model's real **animation
names** (e.g. "Walk", "Attack", "Death") to sync them to enemy AI. So: drop the
`.glb`, tell Claude the filename, and it wires the swap per-model.
`AssetLoader.instance_model / find_anim_player / play_anim` are ready for that.

## The step-by-step loop
**You (≈5 min, no skills):**
1. Download a free asset (e.g. Poly Haven → an HDRI, 1–2K).
2. Rename it to the auto-loaded filename (e.g. `zone.hdr`) and put it in the
   right `assets/` folder.
3. **With Godot closed**, then reopen so it generates the `.import` sidecar.
4. Commit the asset **and** its `.import` file, and push.

**Claude:** wires anything that isn't auto-loaded (model swaps, animation state
mapping, normal/roughness maps), tunes tiling, and keeps the fallbacks intact.

**The update ritual still applies:** close Godot → `git checkout -- .` →
`git pull` → reopen. Do file-dropping while Godot is closed.

## Git notes
- Commit binary assets **and** their `*.import` sidecars (they carry import
  settings). `.godot/` (the import cache) stays git-ignored — it regenerates.
- Keep files reasonably small: 1–2K textures/HDRIs, low-poly models. They read
  great with the toon outline we already apply.

## Status
- ✅ Scaffolding in: `AssetLoader`, `assets/` folders + READMEs, auto-loaded sky
  (hub + zone) and ground textures (town + 5 regions).
- ⬜ First real assets (you): a `zone.hdr`, two ground textures, one animated
  Quaternius creature — then Claude wires the creature.
- ⬜ Later: weapon view-models, normal/roughness maps, Mixamo humanoid bosses.
