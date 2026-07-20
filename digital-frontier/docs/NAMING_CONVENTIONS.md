# Naming Conventions — Digital Frontier

Consistent naming reduces cognitive load across a multi-year project. Follow these rules unless a section documents an exception.

---

## Files & Directories

| Type | Convention | Example |
|------|------------|---------|
| Folders | `snake_case`, plural for collections | `creatures/`, `hex_tiles/` |
| GDScript | `snake_case.gd` | `hex_grid_loader.gd` |
| Scenes | `snake_case.tscn` | `village_hall_interior.tscn` |
| Resources (data) | `snake_case.tres` matching `id` | `pixel_fox.tres` → id `pixel_fox` |
| Shaders | `snake_case.gdshader` | `hex_outline.gdshader` |
| Assets | `snake_case` with type suffix | `pixel_fox_idle.png`, `starter_plains.ogg` |

---

## Code Identifiers

| Type | Convention | Example |
|------|------------|---------|
| Classes (`class_name`) | `PascalCase` | `CreatureData`, `HexUtils` |
| Functions | `snake_case` | `get_active_region_id()` |
| Variables | `snake_case` | `hex_size`, `_active_region_id` (private prefix `_`) |
| Constants | `SCREAMING_SNAKE_CASE` | `DEFAULT_HEX_SIZE` |
| Enums | `PascalCase` type, `SCREAMING_SNAKE` members | `ItemData.ItemType.KEY_ITEM` |
| Signals | `snake_case`, `{domain}_{past_participle}` or `{domain}_{verb}` | `region_loaded`, `item_added` |
| StringName IDs | `snake_case` | `&"starter_plains"`, `&"elder_mira"` |

---

## Autoload Singletons

- **Autoload name**: `PascalCase` (matches class usage in code)
- **Script file**: `snake_case.gd` in `scripts/autoload/`

```
EventBus      → scripts/autoload/event_bus.gd
WorldManager  → scripts/autoload/world_manager.gd
```

Reference in code as globals: `WorldManager.get_active_region_id()`

---

## Scene Node Names

| Rule | Example |
|------|---------|
| `PascalCase` for key functional nodes | `HexGridLayer`, `CameraRig`, `InteractionArea` |
| Descriptive, stable across instances | `EntranceMarker`, `SpawnPoint`, `VisualRoot` |
| Avoid generic names at scene root | ✓ `GameWorld` ✗ `Node3D` |

---

## Groups

Lowercase plural, registered in `GameConstants` or locally:

```
"player", "creatures", "npcs", "interactables", "vehicles", "saveable"
```

Usage: `add_to_group(GameConstants.GROUP_INTERACTABLES)`

---

## Data IDs

Content IDs are **`snake_case`** strings stored as `StringName`:

- Must start with a lowercase letter
- Only `a-z`, `0-9`, `_`
- Must be **globally unique within their category**
- File name should match ID: `data/creatures/pixel_fox.tres` → `id = &"pixel_fox"`

Validate with `IdValidator.is_valid_id()`.

---

## Cross-References in Data

Reference other content by **ID**, never by file path:

```gdscript
# ✓ Good
habitat_region_ids = PackedStringArray("starter_plains")
start_npc_id = &"elder_mira"

# ✗ Bad — breaks if files move
start_npc_path = "res://data/npcs/elder_mira.tres"
```

Scene paths (`scene_path`, `interior_scene_path`) are allowed because they point to Godot scenes, not content records.

---

## Script Placement Rules

| Script type | Location |
|-------------|----------|
| Autoload managers | `scripts/autoload/` |
| Resource definitions | `resources/definitions/` |
| Scene-attached logic | Same folder as scene OR `scripts/{domain}/` if shared |
| Shared entity behavior | `scripts/entities/` |
| One-off scene logic | Co-located: `scenes/world/game_world.gd` |

---

## Git & Branches

Feature branches: `cursor/<descriptive-name>-<suffix>`

Commits: imperative mood, complete sentence
- `Add RegionData schema and starter_plains sample`
- `Define EventBus signals for quest system`

---

## Prefixes (optional, for large teams)

When the project grows, optional prefixes clarify domain:

| Prefix | Domain |
|--------|--------|
| `ui_` | UI scenes/scripts |
| `vfx_` | Particle/effect scenes |
| `dbg_` | Debug-only tools |
| `tpl_` | Template scenes in `_templates/` |

Not required at project start — adopt when search noise increases.
