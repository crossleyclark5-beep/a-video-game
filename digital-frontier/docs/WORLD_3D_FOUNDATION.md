# World 3D Foundation

Digital Frontier’s camera can stay **2.5D orthographic**. The **world is true 3D**.

## Goal

Turn “empty map with locations” into a living digital landscape that still works when we add:

- Aircraft / flying vehicles
- Free / third-person / aerial cameras
- Mountain and valley traversal

Same geometry on foot and from the sky — no fake depth layers, no flat billboard continents.

## Architecture

| Piece | Role |
| --- | --- |
| `GrasslandHeightField` | Deterministic `height_at(x,z)` — hubs + roads forced near 0 |
| `GrasslandTerrainMesh` | Chunked ArrayMesh + `HeightMapShape3D` collision |
| `RegionTerrainBuilder` | Authored mountains, cliffs, caves, landing flats on top |
| `RegionVegetationBuilder` | MultiMesh forests / bushes / rocks / mushrooms snapped to height |
| `RegionDiscoveryBuilder` | Minor + secret POIs **not** on the mini-map |

Build order (see `GrasslandRegionBuilder`): heightfield → hubs → corridors → terrain overlays → vegetation → discoveries.

## Elevation rules

1. **Hub pads** (Pleasant Park, towns) stay ~flat at Y≈0 so roads, interiors, and vehicles keep working.
2. **Road corridors** soft-flatten so asphalt doesn’t float.
3. **Wilderness** rolls: hills, mountain foothills, river dips, valley channels.
4. Authored peaks (West Ridge, North Pass, South Bluffs) remain climbable set pieces on the massif silhouette.

## Density & discovery hierarchy

| Tier | Mini-map | Examples |
| --- | --- | --- |
| Major | Yes | Towns, farms, cinema, lake |
| Landmark | Yes (secrets hide until found) | Ridges, cave, overlook, pine hollow |
| Minor | **No** | Camps, ponds, wrecks, towers, nests |
| Secret | **No** | Hidden grove, buried cache, sky altar |

Cadence target: something interesting every ~30s of walking; interactive every few minutes; memorable find every 10–15 minutes.

## Vegetation

- **MultiMesh** for trees, bushes, rocks, mushrooms (node budget gate ~11.5k).
- Placement respects hub pads + road clearance (`placement_allowed`).
- Dense forest patches + corridor belts + open-field scatter (not a flat green void).

## Flight prep

- Continuous heightfield readable from altitude (color by elevation).
- Open **landing flats** between hubs.
- River ribbon + scenic ponds as aerial landmarks.
- Cities remain flat pads with believable road layouts.

## Inspection

Use **World Inspection Mode** (F3 in debug builds) to fly the same heightfield from the air. See `WORLD_INSPECT_MODE.md`.

## Smoke

```bash
godot --headless --path digital-frontier --scene res://scenes/devtools/world_3d_foundation_smoke.tscn
godot --headless --path digital-frontier --scene res://scenes/devtools/world_inspect_smoke.tscn
godot --headless --path digital-frontier --scene res://scenes/devtools/adventure_stability_probe.tscn
```

Stability probe must stay **≤ ~11,500** scene nodes.
