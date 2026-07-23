# Living World System

Digital Frontier’s overworld is a **budgeted living ecosystem**, not an empty map.

For simulation details (schedules, weather reactions, ambience, world memory) see **`LIVING_WORLD_SIMULATION.md`**.

## Pieces

| System | Role |
|--------|------|
| `LivingWorldController` | Distance-budgeted spawn/despawn + AI LOD |
| `EcosystemCreature` | Live wildlife / hostiles (graze, flee, patrol, chase) |
| `LivingWorldCatalog` | NPC + aquatic tables (wildlife tables are legacy) |
| `WorldNpcActor` | Schedule-driven townsfolk, merchants, guards, kids |
| `AquaticActor` + `WaterBody` | Bobbing water, schools, scatter |
| `WorldAmbienceController` | Insects, leaves, night motes |
| `WorldSimMemory` | Cleared camps persist for a while |
| `WorldEncounterDirector` | Ambient vignettes |
| `PlayerHealth` | HP bar, damage, Field Unit reboot |

## Handheld combat

- **Y** (`creature_action`) — strike nearest hostile / start companion battle
- Death → brief reboot → respawn at adventure checkpoint

## Performance

Caps from `AdventureNodeBudget`: **14** wildlife · **6** hostiles · **5** NPCs · **10** aquatics  
Spawn ~90 · Despawn ~125 · AI full ≤55 · AI simple ≤95  

## Quests

- `field_patrol` — defeat 3 hostiles, talk to Field Ranger  
- `wildlife_watch` — discover Meadow Clearing, talk to Meadow Researcher  

## Smoke

```bash
godot --headless --path digital-frontier --scene res://scenes/devtools/living_world_sim_smoke.tscn
godot --headless --path digital-frontier --scene res://scenes/devtools/living_world_smoke.tscn
```
