# Agent notes — Cooper / Digital Frontier

## Canonical local project (user machine)

**All updates must target this folder. Do not tell the user to use any other path.**

```
C:/Users/Martin/Downloads/cooper.cursor/cooper
```

Godot entry (preferred):

```
C:/Users/Martin/Downloads/cooper.cursor/cooper/digital-frontier/project.godot
```

Fallback if the Godot project is the workspace root:

```
C:/Users/Martin/Downloads/cooper.cursor/cooper/project.godot
```

Deprecated / do not use in instructions:

- `C:/Users/Martin/OneDrive/Dokumenty/a-video-game-master/...`
- Branch ZIP extract folders (`a-video-game-cursor-…`)
- Any second Godot Import

## How updates reach that folder

**Always merge finished work to `master` and push.** Do not leave the user on branch ZIPs or ask them to hunt folders.

The user's Cursor project at `C:/Users/Martin/Downloads/cooper.cursor/cooper` should track this GitHub repo. After you push `master`, that folder gets the update via Cursor/git Pull — not via a second Godot Import.

This cloud workspace pushes to GitHub `master`. The user applies updates by overwriting  
`C:/Users/Martin/Downloads/cooper.cursor/cooper` from the master ZIP, or by `git pull` if that folder is a clone.

Always say: update **into** that `cooper` folder — never Import a new Godot project.

## Game project in this repo

Godot project lives under `digital-frontier/` (`project.godot`, Godot 4.7.1).

## Cursor Cloud specific instructions

This repo contains **two independent products**:

1. **Root browser game** (`index.html`, `game.js`, `styles.css`) — a static HTML5 canvas
   game. No build step and no dependencies.
2. **Godot game** `digital-frontier/` — "Cooper Game / Digital Frontier", a GDScript
   Godot **4.7.1** project (no C#/mono).

### Godot engine

- The engine is not a system package. The startup update script installs the Godot 4.7.1
  Linux editor binary to `~/godot/` and symlinks it to `~/godot/godot` (idempotent; it
  only downloads if missing). Invoke it as `~/godot/godot`.
- **First run after a fresh checkout** (or a VM without a `.godot/` import cache) must
  import assets once, from inside `digital-frontier/`:
  `~/godot/godot --headless --import`. `.godot/` is gitignored, so this is a runtime step,
  never committed and not part of the update script.

### Godot tests (smoke scenes = the automated test suite)

- Tests are self-contained scenes under `digital-frontier/scenes/devtools/`. Each prints
  `*_SMOKE_OK` / `*_SMOKE_FAIL` and exits `0`/`1`.
- Run one headless (from `digital-frontier/`):
  `~/godot/godot --headless res://scenes/devtools/combat_smoke.tscn`
- Run all: iterate over `scenes/devtools/*_smoke.tscn` plus `smoke_digipet.tscn` and
  `smoke_shop_map.tscn` (these two use a `smoke_*` prefix, so a `*_smoke` glob misses them).
- A harmless `WARNING: N ObjectDB instances were leaked at exit` line is normal.

### Running the Godot game

- Headless (logic only, no window): `~/godot/godot --headless` from `digital-frontier/`.
  It boots `boot.tscn → main.tscn → Home habitat` through all autoload managers.
- Windowed for GUI testing: a virtual X display is available at `DISPLAY=:1`. Run
  `DISPLAY=:1 ~/godot/godot --rendering-driver opengl3` from `digital-frontier/`.
  Audio has no device here, so it logs ALSA errors and falls back to the dummy driver —
  this is expected and harmless. Handheld-first controls with editor keyboard fallbacks
  are documented in `digital-frontier/START_HERE.md` (WASD move, E/Space = A/confirm,
  C = Y/pet, Tab = Start/Adventure).

### Running the browser game

- Serve statically from the repo root: `python3 -m http.server 8000`, then open
  `http://localhost:8000/index.html`. Arrow keys move; it needs no dependencies.
