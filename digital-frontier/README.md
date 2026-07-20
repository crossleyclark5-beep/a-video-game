# Digital Frontier

A commercial-quality **2.5D top-down hex-world creature adventure** built with **Godot 4.7.1**, designed for a dedicated handheld device.

> **Status:** Design blueprint + engineering scaffold — **no gameplay implemented yet.**  
> Read `docs/design/` first. Implementation requires approval per phase.

## Quick Start

1. Install [Godot 4.x](https://godotengine.org/) (target: 4.7.1; 4.3+ compatible)
2. Open this folder (`digital-frontier/`) as a project in the Godot editor
3. Press **F5** to run — boots through `boot.tscn` → `main.tscn` → `game_world.tscn` (empty shell)

## Documentation

### Design (vision & roadmap)

| Document | Description |
|----------|-------------|
| [docs/design/GAME_DESIGN_DOCUMENT.md](docs/design/GAME_DESIGN_DOCUMENT.md) | Full Game Design Document |
| [docs/design/GAMEPLAY_PILLARS.md](docs/design/GAMEPLAY_PILLARS.md) | Core pillars & feature scoring |
| [docs/design/PLAYER_EXPERIENCE.md](docs/design/PLAYER_EXPERIENCE.md) | Experience goals & sessions |
| [docs/design/ROADMAP.md](docs/design/ROADMAP.md) | Phased roadmap & build order |
| [docs/design/TECHNICAL_ARCHITECTURE.md](docs/design/TECHNICAL_ARCHITECTURE.md) | Design → Godot architecture map |

### Engineering

| Document | Description |
|----------|-------------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Folder structure, managers, principles |
| [docs/SCENE_ARCHITECTURE.md](docs/SCENE_ARCHITECTURE.md) | Scene trees and boot flow |
| [docs/DATA_SCHEMA.md](docs/DATA_SCHEMA.md) | Resource field reference |
| [docs/NAMING_CONVENTIONS.md](docs/NAMING_CONVENTIONS.md) | Files, code, IDs, signals |

## Project Layout (summary)

```
assets/     → raw art & audio
data/       → game content (.tres) — regions, creatures, items, quests…
resources/  → Resource class definitions (*Data.gd)
scenes/     → .tscn files organized by domain
scripts/    → autoload managers, core, utils
docs/       → design + architecture documentation
```

## Process

Design → Approve → Implement → Playtest → Iterate.

No gameplay feature is built until its phase/brief is approved. See `docs/design/ROADMAP.md`.
