# assets/models/

Drop 3D models here as **`.glb`** (preferred) or `.gltf`. Godot imports them
automatically the next time you open the editor.

## What goes here
- Enemy creatures (wolves, boars, warriors, bosses) — ideally **rigged + animated**.
- Weapon view-models (the sword/axe/bow you see in first person).
- Props (chests, rocks, trees, buildings).

## Where to get free ones (all CC0 unless noted)
- **Quaternius** — quaternius.com — low-poly characters & animals, pre-animated `.glb` ⭐
- **Kenney** — kenney.nl — weapon/prop/nature kits
- **Sketchfab** — filter for Downloadable + CC0/CC-BY (mixed licenses ⚠️)

## Naming the wiring expects (optional — ask Claude to match your files)
Nothing is auto-loaded from here yet; enemy/weapon swaps get wired per-file once
a real model exists, because the code needs the model's actual animation names
(e.g. "Walk", "Attack", "Death"). Drop a file, tell Claude the filename, and it
gets hooked to the matching AI state.

## Gotchas
- Add files while **Godot is CLOSED**, then reopen (it generates the `.import`
  sidecar on first open). Commit BOTH the `.glb` and its `.glb.import` file.
- Keep polys modest (low-poly reads great with the toon outline we already use).
