# Core World Framework

Scalable architecture for years of Digital Frontier expansion.

**Philosophy:** wrap and coordinate existing systems — do not rewrite LivingWorld, vegetation, or hub builders.

## Hub

`WorldCoordinator` (group `world_coordinator`) is the simulation brain.

- Future features should ask the coordinator (or its facades), not peer managers directly.
- Persistence flags remain in the `WorldManager` autoload.

Boot order in `game_world.gd`:

1. WorldCoordinator  
2. Atmosphere  
3. `coordinator.load_region("grassland")` → `GrasslandRegionModule` → `GrasslandRegionBuilder`  
4. Player / LivingWorld / Stream  
5. Bind living + stream + dev tools  

## Plugins

| Contract | Role | Reference |
| --- | --- | --- |
| `RegionModule` | Terrain, biome, music, discoveries | `GrasslandRegionModule` |
| `BiomeProfile` | Colors, dressing rules, species tables | `BiomeProfile.grassland()` |
| `WorldSpawnBroker` | Unified wildlife / NPC / collectible / resource spawn | Bound to LivingWorld |
| `InteractionKinds` | One vocabulary for talk/open/scan/ride/… | Maps Interactable subclasses |
| `DiscoveryFramework` | Locations, creatures, journal snapshot | WorldManager + CollectionManager |
| `CollectibleKinds` | Bits, materials, lore, keys, cosmetics… | Inventory / flags |
| `WorldEventFramework` | Time/location-aware events | Extends EncounterDirector |
| `WorldSaveSchema` | Versioned save sections (v4 + `framework_data`) | GameState |
| `WorldDevConsole` | F6 cheats: time, weather, spawn, tp, events | `GameConfig.enable_cheats` |

## Adding a future region

1. Create `MyRegionModule extends RegionModule`  
2. Implement `build(root)` (or call a dedicated builder)  
3. Supply a `BiomeProfile`  
4. `WorldCoordinator.register_region(MyRegionModule.new())`  
5. `load_region(&"my_region", root)`  

No rewrite of the grassland path required.

## Dev tools (debug builds)

Toggle **F6**:

- `time morning|day|evening|night`
- `weather clear|rain|fog|storm`
- `spawn wildlife|hostile|npc`
- `event <id>` / `events`
- `tp park|mere|fields|reels|mile`
- `save` · `discover` · `pop` · `regions` · `biome`

## Smoke

```bash
godot --headless --path digital-frontier --scene res://scenes/devtools/core_world_framework_smoke.tscn
godot --headless --path digital-frontier --scene res://scenes/devtools/adventure_stability_probe.tscn
```
