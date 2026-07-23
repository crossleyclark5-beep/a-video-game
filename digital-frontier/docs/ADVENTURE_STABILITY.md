# Adventure Stability

## Diagnosis (2026-07-23)

Adventure Mode **does launch** in Godot 4.7.1 headless + GL Compatibility, but the world was unstable under load:

| Finding | Evidence |
|---------|----------|
| ~14,700 scene nodes on boot | `node_budget_probe` / stability probe |
| ~10,500 `MeshInstance3D` | Almost all under `HexGridLayer/RegionVegetation/ForestBelts` |
| Pixel trees used **6 meshes each** | `_pixel_tree` Trunk+Branch+C1–C4 |
| Script spam | `WorldEncounterDirector` set `global_position` **before** `add_child` → `!is_inside_tree()` |
| Future-biome leak | Wounded vignette spawned `hex_squirrel` (Forest stub) in Grassland |
| Home → Adventure | `change_scene` not awaited; heavy instantiate during fade |

These combine into hitch/freeze/OOM behavior that feels like a hard crash on weaker hardware.

## Fixes shipped

1. **Vegetation budget** — fewer corridor segments, smaller clumps, simpler trees (3 meshes), distance LOD on canopies, lighter grass strips / wilderness fill.
2. **Encounter director** — add to tree first, then set transform; delay first vignette; Grassland-only wounded critter.
3. **Living world caps** — slightly lower wildlife/hostile/NPC/aquatic caps + slower tick.
4. **Scene transition** — await Adventure load; yield frames so fade paints before/after heavy build.
5. **Companion safety** — auto-select starter if Adventure boots without a partner.
6. **Probe** — `scenes/devtools/adventure_stability_probe.tscn` (`AdventureNodeBudget.AUTHORED_NODE_GATE` ≈ 11.5k, save/reload).
7. **Streaming foundation** — `WorldStreamController` distance bands + living AI LOD + interior hub pin (see `WORLD_STREAMING.md`). Density is preserved; far content sleeps.

## Known remaining / follow-ups

- Pleasant Park interiors are dense when entered (~2k) — still unload on exit.
- Chapter opening still pushes `DeviceDialogue` (MENU context) on first Adventure — intentional, not a crash.
- Audio may fall back to dummy driver in CI (no ALSA card) — harmless.
- Future: pool living actors on despawn; mesh LOD swaps for hero props; aircraft-specific focus provider.

## Smoke

```bash
godot --headless --path digital-frontier --scene res://scenes/devtools/adventure_stability_probe.tscn
godot --headless --path digital-frontier --scene res://scenes/devtools/world_streaming_smoke.tscn
godot --headless --path digital-frontier --scene res://scenes/devtools/living_world_smoke.tscn
godot --headless --path digital-frontier --scene res://scenes/devtools/creature_ecosystem_smoke.tscn
```

Expect `ADVENTURE_STABILITY_PROBE_OK`.
