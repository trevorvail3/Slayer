---
title: Run and Update
tags: [slayer, howto]
---

# Run and Update

← [[Home]] · code map: [[Systems and Architecture]]

## Run the game
1. Install **Godot 4.3+** (standard build, not .NET) — <https://godotengine.org/download>
2. Open this folder as a project in Godot (it detects `project.godot`).
3. Press **F5**. You start in the **town** ([[Milestone Log]] v0.4).

## Controls
| Input | Action |
|-------|--------|
| WASD | Move |
| Mouse | Look |
| Space | Jump |
| Left click | Attack — melee swing / bow draw (hold) / bolt. Also **gathers** trees & rocks in town |
| Right click (hold) | Shield block — tap on impact to **parry** |
| E | Interact — build/use town plots & vendors |
| Tab / I | Inventory (equip gear) |
| Esc | Close a vendor/menu |

## Update to the latest (the ritual)
Godot rewrites `project.godot` while open, which fights `git pull`. So **always
close Godot first**:
```powershell
# from the Slayer repo folder
git checkout -- .   # discard Godot's local auto-edits
git pull
```
Then reopen Godot. (Doing git ops while Godot is open can strip newly-added
autoloads and cause "identifier not declared" errors.)

## Tests (headless)
```bash
godot --headless --path . -s res://test/run_tests.gd
```
Exits `0` if all pass; prints PASS/FAIL per test.

## Save data
Progress persists to Godot's user data dir as `slayer_save.json`:
- Windows: `%APPDATA%\Godot\app_userdata\Slayer\`
- macOS: `~/Library/Application Support/Godot/app_userdata/Slayer/`
- Linux: `~/.local/share/godot/app_userdata/Slayer/`
Delete that file to reset to a fresh game.

## Using this vault in Obsidian
This `docs/` folder is a self-contained set of linked notes. Two ways to use it:
- **Open the repo as a vault:** Obsidian → *Open folder as vault* → pick the `Slayer`
  folder. Notes render with working `[[links]]`; code files are ignored. Notes stay
  versioned in git with the project.
- **Copy into an existing vault:** copy the `docs/` folder into your vault. (You lose
  automatic git sync; the repo remains the source of truth.)

Start at [[Home]].
