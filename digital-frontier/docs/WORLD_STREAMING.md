# World Streaming & Optimization Foundation

Digital Frontier keeps a **large, dense 3D world**. Performance comes from intelligent activation — not from deleting forests or shrinking the map.

## Principle

| Do | Don't |
| --- | --- |
| Stream-activate by distance | Thin trees to hit FPS |
| MultiMesh + LOD ranges | One Node3D per blade of grass |
| Pause far AI | Run every creature every frame |
| Load interiors on enter | Keep every building interior alive |
| Air rings for flight/inspect | Pop forests out when the camera rises |

## Adventure Node Budget

`AdventureNodeBudget` (`scripts/world/streaming/adventure_node_budget.gd`)

| Constant | Role |
| --- | --- |
| `AUTHORED_NODE_GATE` (11500) | Stability probe hard gate |
| `ACTIVE_NODE_WARN` / `CRITICAL` | Perf HUD warnings |
| Living caps | Wildlife / hostiles / NPCs / aquatics |
| `GROUND_*` / `AIR_*` rings | Stream hysteresis distances |
| `LOD_*` | Vegetation visibility ends (+ air multiplier) |

## Distance bands

| Band | Behavior |
| --- | --- |
| **NEAR** | Full detail — process, collision, interactables |
| **MEDIUM** | Visible + collision; normal process (cheap shells) |
| **FAR** | Visual only — process off, collision off; hubs/terrain/veg stay visible |
| **VERY_FAR** | Sleep — hidden (terrain stays as silhouette) |

Implemented by `WorldStreamController` after `GrasslandRegionBuilder.build`.

## Systems

| System | Path |
| --- | --- |
| Stream controller | `world_stream_controller.gd` |
| Stream unit | `world_stream_unit.gd` |
| LOD policy | `world_lod_policy.gd` |
| Object pool | `world_object_pool.gd` |
| Perf monitor | `scripts/devtools/perf/world_perf_monitor.gd` |
| Living AI LOD | `LivingWorldController` (`AI_FULL` / `AI_SIMPLE` / pause) |
| Interiors | `BuildingInteriorController` (unchanged enter/exit) + hub pin while inside |

## Aircraft / inspect

- Focus above ~35m or World Inspect cam → **airborne** mode
- Larger rings + `LOD_AIR_MULT` so cities and forests remain readable from altitude
- Same authored world — no separate “sky map”

## Developer tools

World Inspect (**F3**) → **7** toggles Perf overlay:

- FPS / frame ms / draw calls
- World node count vs authored gate
- Stream band counts (N/M/F/VF)
- Living population
- Warnings when over budget / low FPS

## Smoke

```bash
godot --headless --path digital-frontier --scene res://scenes/devtools/world_streaming_smoke.tscn
godot --headless --path digital-frontier --scene res://scenes/devtools/adventure_stability_probe.tscn
```
