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

## What's auto-wired now
- **`Fox.glb`** → the **BEAST** enemy. If present, beasts spawn as the animated
  Fox (auto-scaled to size; clips Survey/Walk/Run driven by AI state) instead of
  the box-rig. Delete the file and beasts fall back to boxes — nothing breaks.

To swap the beast creature, replace `Fox.glb` with another animated quadruped
`.glb` **named `Fox.glb`** (e.g. a Quaternius wolf) — or tell Claude the new
filename and it repoints the one constant. Animation names don't have to match
"Walk/Run" exactly; the loader matches by keyword and you can tell Claude the
real clip names.

Other slots (humanoids, weapon view-models) get wired per-file on request,
because the code needs the model's actual animation names to sync them.

## Gotchas
- Add files while **Godot is CLOSED**, then reopen (it generates the `.import`
  sidecar on first open). Commit BOTH the `.glb` and its `.glb.import` file.
- Keep polys modest (low-poly reads great with the toon outline we already use).
