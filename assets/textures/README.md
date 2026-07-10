# assets/textures/

Drop ground/surface textures here as **`.png`** or `.jpg`. These are picked up
**automatically** — no code change needed.

## Auto-loaded filenames (this is the turnkey part)
Drop a file with one of these exact names and it tiles onto that ground the next
time you play:

| File | Applies to |
|------|------------|
| `ground_town.png` | the Hub town ground |
| `ground_plains.png` | The Olive Plains |
| `ground_wood.png` | The Hollow Wood |
| `ground_road.png` | The Broken Road |
| `ground_barrow.png` | The Barrowlands |
| `ground_foothills.png` | The Bonereach Foothills |

Missing files just fall back to the flat colour that's there now — safe to add
one at a time.

## Where to get free ones (all CC0)
- **Poly Haven** — polyhaven.com/textures — download the **Diffuse / Color** map, 1K is plenty ⭐
- **ambientCG** — ambientcg.com

Use the plain colour/albedo image. (Normal/roughness maps are a nice later
upgrade — ask Claude to wire them when you want them.)

## Gotchas
- Add files while **Godot is CLOSED**, then reopen. Commit the image **and** its
  `.png.import` sidecar.
- Tiling scale is preset per ground; if it looks too big/small on screen, tell
  Claude and it'll adjust one number.
