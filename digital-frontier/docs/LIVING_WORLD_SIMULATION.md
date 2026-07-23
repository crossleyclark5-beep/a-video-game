# Living World Simulation

Digital Frontier should feel like a world that **already exists** — not a stage waiting for the player.

## Pillars

1. **Schedules** — named NPCs wake, work, wander, return home, sleep
2. **Wildlife FSM** — graze, drink, sleep, flee, patrol, hide in weather
3. **Day / night / weather** — spawn mix and actor reactions change
4. **Ambience** — insects, leaves, night motes (cheap MultiMesh / particles)
5. **Memory** — cleared nests stay quiet; NPCs comment

## Systems

| Piece | Role |
| --- | --- |
| `LivingWorldController` | Budgeted spawn bubble + AI LOD + veg prop sway |
| `WorldAmbienceController` | Day insects, leaf drift, night motes |
| `WorldSimMemory` | Cleared-zone TTL via `WorldManager` flags |
| `WorldWind` | Weather → wind strength for ambience / sway |
| `NpcSchedule` | Routines: town, market, patrol, guard, child, merchant road |
| `WorldNpcActor` | Shelter in rain, sleep at night, activity labels |
| `EcosystemCreature` | Patrol routes, `set_ai_detail`, rain hide, wing flap |
| `AquaticActor` | School bias + scatter when approached |
| `WorldEncounterDirector` | Stumble-across vignettes |

## NPC daily life

Schedules expose `activity_label` (opening shop, playing outside, night watch…).

- **Merchants** — open → trade → close → sleep  
- **Guards / rangers** — patrol routes; night watch (no sleep)  
- **Children** — play outside; home before dark  
- **Road carters** — long `merchant_road` leashes between hubs  
- **Rain** — most townsfolk seek porch shelter (`shelter_offset`)

## Creature life

- Hostiles **patrol** territory; may sleep briefly at night  
- Birds peck / take off; wings flap; `rain_hide` removes them from rain spawns  
- Fish school and **scatter** when the player wades close  
- Fog boosts rare encounters; storms raise hostile pressure  

## World memory

`WorldSimMemory.note_hostile_cleared` marks a ~48 m cell empty for ~one day cycle and writes NPC memories (`camp_cleared` / `village_safe`).

## Budget

Living caps remain `AdventureNodeBudget` (14 / 6 / 5 / 10). Ambience is a handful of nodes following the focus — not per-tile actors.

## Smoke

```bash
godot --headless --path digital-frontier --scene res://scenes/devtools/living_world_sim_smoke.tscn
godot --headless --path digital-frontier --scene res://scenes/devtools/living_world_smoke.tscn
godot --headless --path digital-frontier --scene res://scenes/devtools/creature_ecosystem_smoke.tscn
```
