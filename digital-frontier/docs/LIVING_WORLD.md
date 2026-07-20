# Living World System

Digital Frontier’s overworld is a **budgeted living ecosystem**, not an empty map.

## Pieces

| System | Role |
|--------|------|
| `LivingWorldController` | Distance-budgeted spawn/despawn of wildlife, hostiles, NPCs, aquatics |
| `LivingWorldCatalog` | Grassland species tables (biome stubs for desert/jungle/ocean later) |
| `WildlifeActor` | Friendly roamers (rabbit, bird, squirrel, deer, moose) — wander + flee |
| `HostileCreatureActor` | Glitchmites, bats, wolves, boars — aggro, melee, Bits loot |
| `WorldNpcActor` | Villagers / explorers / merchants with dialogue + quest offers |
| `AquaticActor` + `WaterBody` | Bobbing water, shore ripples, fish / hostile eels |
| `PlayerHealth` | HP bar, damage, Field Unit reboot respawn to checkpoint |

## Handheld combat

- **Y** (`creature_action`) — strike nearest hostile in melee range + companion assist
- If no hostile nearby — companion notice / bond (unchanged)
- Death → brief reboot → respawn at adventure checkpoint

## Performance

Caps (approx): 18 wildlife · 8 hostiles · 6 NPCs · 14 aquatics  
Spawn radius ~95 · Despawn ~130 · Tick ~0.55s  

## Vegetation

`RegionVegetationBuilder` denser corridor forests, bushes, rocks, wilderness fill between hubs, pine ridges on mountain landmarks.

## Quests

- `field_patrol` — defeat 3 hostiles, talk to Field Ranger  
- `wildlife_watch` — discover Meadow Clearing, talk to Meadow Researcher  

## Smoke

`res://scenes/devtools/living_world_smoke.tscn`
