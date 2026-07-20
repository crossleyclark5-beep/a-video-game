# Digital Frontier — Architecture

Godot **4.7.1** | 2.5D top-down hex-world adventure

This document defines the foundational architecture. **No gameplay is implemented yet** — this is the scaffold that all future systems plug into.

---

## Design Principles

| Principle | Implementation |
|-----------|----------------|
| **Data-driven content** | All creatures, items, quests, regions, etc. are `.tres` resources in `data/`, indexed by `ResourceRegistry` |
| **Decoupled systems** | Managers communicate via `EventBus` signals, not direct calls |
| **Persistent shell** | `main.tscn` stays loaded; gameplay scenes swap inside `SceneContainer` |
| **Separation of static vs runtime** | `*Data` resources = templates; Managers = runtime state; `GameState` = save snapshot |
| **Performance-first** | Layer-based scene tree, chunk-ready hex grid, object pooling hooks in managers |
| **Expandability** | New content = new `.tres` file + optional scene; no code changes required |

---

## Folder Structure

```
digital-frontier/
├── project.godot              # Engine config, autoloads, input, physics layers
├── icon.svg
│
├── addons/                    # Third-party plugins (GUT, dialogic, etc.)
│
├── assets/                    # RAW imported art/audio (Godot .import sidecars)
│   ├── audio/music/
│   ├── audio/sfx/
│   ├── fonts/
│   ├── models/                # 3D meshes for 2.5D world
│   ├── sprites/               # 2D sprites (UI, billboards, creatures)
│   ├── textures/
│   └── ui/
│
├── data/                      # ★ GAME CONTENT — edit here, not in code
│   ├── regions/               # RegionData .tres
│   ├── creatures/
│   ├── items/
│   ├── quests/
│   ├── buildings/
│   ├── npcs/
│   ├── vehicles/
│   ├── bosses/
│   ├── localization/          # .csv translation files
│   └── tables/                # LootTableData, spawn tables, schedules
│
├── resources/
│   ├── definitions/           # Resource class scripts (*Data.gd)
│   └── instances/             # Shared non-content resources (rare)
│
├── scenes/
│   ├── _templates/            # Reusable scene blueprints
│   ├── bootstrap/             # boot.tscn, loading_screen.tscn
│   ├── main/                  # Persistent main.tscn shell
│   ├── world/                 # Overworld, regions, buildings, hex
│   ├── entities/              # Player, creatures, NPCs, vehicles
│   ├── combat/                # Boss arenas, battle scenes
│   ├── ui/                    # HUD, menus, components
│   └── debug/                 # Dev tools, overlays
│
├── scripts/
│   ├── autoload/              # Singleton manager implementations
│   ├── core/                  # Base classes, constants, GameState
│   ├── world/                 # Hex grid, region loader, streaming
│   ├── entities/              # Entity behavior scripts
│   ├── systems/               # Focused subsystems (dialogue runner, etc.)
│   └── utils/                 # Pure utility functions
│
├── shaders/
├── tests/                     # Unit + integration tests (GUT recommended)
└── docs/                      # Architecture documentation
```

### Why each top-level folder exists

- **`assets/`** — Source art/audio only. Never reference gameplay IDs here; use `data/` for content metadata.
- **`data/`** — Designers and programmers add content without touching autoloads. `ResourceRegistry` auto-indexes on boot.
- **`resources/definitions/`** — Schema (the *shape* of data). Changing a field here updates the editor inspector for all `.tres` files.
- **`scenes/`** — Visual/interactive structure. Organized by domain, not by file type.
- **`scripts/`** — Logic not tied to a single scene. Autoloads live in `scripts/autoload/`.
- **`scenes/_templates/`** — Copy these when creating new entities/buildings/tiles for consistent node hierarchies.

---

## Singleton Managers (Autoloads)

Registered in `project.godot` in **initialization order**:

| # | Autoload | Purpose |
|---|----------|---------|
| 1 | `EventBus` | Global signals — decouples all systems |
| 2 | `GameConfig` | Feature flags, volumes, debug settings |
| 3 | `ResourceRegistry` | Loads & indexes all `data/**/*.tres` by ID |
| 4 | `SceneManager` | Scene transitions with fade overlay |
| 5 | `SaveManager` | Aggregates `GameState`, file I/O |
| 6 | `AudioManager` | Music/SFX buses, pooling |
| 7 | `InputManager` | Context stack (overworld/menu/dialogue/vehicle/combat) |
| 8 | `WorldManager` | Active region, hex coords, world flags |
| 9 | `InventoryManager` | Item quantities |
| 10 | `QuestManager` | Quest stages & completion |
| 11 | `CreatureManager` | Party, collection, home companion |
| 12 | `NPCManager` | Per-NPC runtime state |
| 13 | `VehicleManager` | Unlocked vehicles, active mount |
| 14 | `UIManager` | CanvasLayer registry, modal stack |

### Why managers instead of static classes?

Godot autoloads are `Node`-based singletons. They can:
- Connect to `EventBus` in `_ready()`
- Use `await`, tweens, and timers
- Participate in the scene tree lifecycle

### Communication pattern

```
Gameplay Node  →  EventBus.signal  →  Manager listener
Manager        →  EventBus.signal  →  UI / other Manager
Manager        →  export_state()   →  SaveManager (on save)
```

**Never** call `InventoryManager.add_item()` from `QuestManager` directly — emit a signal or use a shared orchestrator when cross-system workflows are needed.

---

## Resources & Data Files

See [DATA_SCHEMA.md](DATA_SCHEMA.md) for field-level documentation.

| Resource Class | File Location | Purpose |
|----------------|---------------|---------|
| `RegionData` | `data/regions/` | Hex grid size, scene, neighbors, spawns |
| `HexTileData` | `data/tables/` or embedded | Terrain type, walkability, mesh |
| `BuildingData` | `data/buildings/` | Interior/exterior scenes, hex placement |
| `CreatureData` | `data/creatures/` | Species stats, capture rate, habitat |
| `ItemData` | `data/items/` | Stack size, type, icon, effects |
| `QuestData` | `data/quests/` | Staged objectives, rewards |
| `NPCData` | `data/npcs/` | Role, dialogue, schedule |
| `VehicleData` | `data/vehicles/` | Speed, terrain, unlock conditions |
| `BossData` | `data/bosses/` | Arena, phases, rewards |
| `DialogueData` | `data/localization/` or `data/npcs/` | Branching dialogue trees |
| `LootTableData` | `data/tables/` | Weighted drop tables |
| `GameState` | runtime / save files | Full save snapshot |

All content resources extend `IdentifiableResource` and must have a unique `id: StringName`.

---

## Scene Flow

```
boot.tscn
  └─► main.tscn (persistent)
        ├─ SceneContainer ← game_world.tscn, menus, combat
        ├─ UI layers (HUD, Menu, Modal, Overlay)
        └─ TransitionOverlay
              └─► game_world.tscn
                    ├─ HexGridLayer
                    ├─ BuildingLayer
                    ├─ EntityLayer
                    ├─ EffectsLayer
                    └─ CameraRig
```

See [SCENE_ARCHITECTURE.md](SCENE_ARCHITECTURE.md) for detailed scene tree conventions.

---

## Naming Conventions

See [NAMING_CONVENTIONS.md](NAMING_CONVENTIONS.md).

---

## Expansion Guide (multi-year roadmap)

### Adding a new region
1. Create `data/regions/my_region.tres` (RegionData)
2. Create `scenes/world/regions/my_region.tscn`
3. Add hex tile overrides or a tilemap pipeline
4. Link neighbor regions in RegionData
5. **No autoload changes required** — ResourceRegistry picks it up automatically

### Adding a new creature
1. Create `data/creatures/my_creature.tres`
2. Create `scenes/entities/creatures/my_creature.tscn` (from `_templates/entity_template.tscn`)
3. Add to spawn table in `data/tables/`

### Adding a building with interior
1. Create `data/buildings/my_building.tres`
2. Create exterior + interior scenes under `scenes/world/buildings/`
3. Reference paths in BuildingData
4. WorldManager loads interior additively on `building_enter_requested`

### Adding a new manager
1. Create `scripts/autoload/my_manager.gd` extending `BaseManager`
2. Register in `project.godot` **after** dependencies (usually after EventBus)
3. Add `export_state()` / `import_state()` if save-relevant
4. Add signals to `EventBus`
5. Wire into `SaveManager._collect_state_from_managers()`

### Performance considerations (built into architecture)
- Hex chunks stream in/out per region (WorldManager + HexGridLayer)
- Entity scenes use `CharacterBody3D` templates with shared materials
- AudioManager SFX pool avoids per-play node allocation
- ResourceRegistry loads once at boot; lookups are O(1) dictionary access
- Physics layers pre-defined in `project.godot` for selective collision

---

## Getting Started

1. Open `digital-frontier/` in **Godot 4.7.1**
2. Press F5 — boots into `main.tscn` → `game_world.tscn` (empty shell)
3. Read `docs/` before implementing gameplay
4. Add content in `data/` first, scenes second, manager logic last
