# assets/skies/

Drop a 360° **HDRI** sky here and the whole world's sky + lighting mood changes.
Picked up **automatically** — this is the single biggest bang-for-buck upgrade.

## Auto-loaded filenames
| File (first match wins) | Applies to |
|-------------------------|------------|
| `hub.hdr` / `hub.exr` / `hub.png` / `hub.jpg` | the Hub town sky |
| `zone.hdr` / `zone.exr` / `zone.png` / `zone.jpg` | the open-world (wilds) sky |

Missing files fall back to the current procedural sky — safe to add just one.

## Where to get free ones (CC0)
- **Poly Haven** — polyhaven.com/hdris ⭐
  Pick a mood (a warm morning for the town, something moody/overcast for the
  wilds), download the **`.hdr`** at **1K or 2K** (bigger = slower, no need).

## What "HDRI" means here
It's one equirectangular photo of a full sky wrapped around the world. The game
also samples it for ambient light, so a good sky quietly upgrades how everything
is lit, not just the backdrop.

## Gotchas
- Add files while **Godot is CLOSED**, then reopen. Commit the image **and** its
  `.import` sidecar.
- If a `.hdr` imports oddly, a 2K `.jpg`/`.png` panorama works too (named
  `zone.jpg` etc.).
