# Digital Frontier

A commercial-quality **2.5D top-down hex-world adventure** built with **Godot 4.7.1**.

> **Status:** Foundation scaffold only — no gameplay implemented yet.

## Quick Start

1. Install [Godot 4.7.1](https://godotengine.org/)
2. Open this folder (`digital-frontier/`) as a project in the Godot editor
3. Press **F5** to run — boots through `boot.tscn` → `main.tscn` → `game_world.tscn`

## Documentation

| Document | Description |
|----------|-------------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Folder structure, managers, design principles |
| [docs/SCENE_ARCHITECTURE.md](docs/SCENE_ARCHITECTURE.md) | Scene trees, boot flow, layer conventions |
| [docs/DATA_SCHEMA.md](docs/DATA_SCHEMA.md) | Resource field reference |
| [docs/NAMING_CONVENTIONS.md](docs/NAMING_CONVENTIONS.md) | Files, code, IDs, signals |

## Project Layout (summary)

```
assets/     → raw art & audio
data/       → game content (.tres) — regions, creatures, items, quests…
resources/  → Resource class definitions (*Data.gd)
scenes/     → .tscn files organized by domain
scripts/    → autoload managers, core, utils
docs/       → architecture documentation
```

## Core Systems (stubs)

- **14 autoload managers** — EventBus, WorldManager, SaveManager, etc.
- **11 data resource types** — RegionData, CreatureData, ItemData, etc.
- **Sample content** — starter region, creature, item, quest, building, NPC
- **Scene templates** — entity, hex tile, building exterior

## Planned Features

Hex world · Regions · Building interiors · Creature collecting · Inventory · Quests · Vehicles · NPCs · Boss fights · Save/load · Home companion

Implement these by extending the foundation — see the expansion guide in `docs/ARCHITECTURE.md`.
