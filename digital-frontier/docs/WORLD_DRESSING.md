# Environmental Storytelling & World Dressing

The grassland should feel **intentionally designed** — curiosity over quest markers.

Philosophy (BotW-inspired): every few seconds of walking, something asks “what’s that?” Most finds stay **off the mini-map**.

## System

| Piece | Role |
| --- | --- |
| `BiomeDressingRules` | Density / spacing rules per biome |
| `MicroStoryCatalog` | Authored vignettes with a design `reason` |
| `WorldDressKit` | Prop dressing by kind (camp, wreck, shrine…) |
| `WorldDressingBuilder` | Builds meadows, forest understory, trails, stories, landmarks, viewpoints |
| `WorldEncounterDirector` | Runtime events (traveler, resting merchant, meteor glint, flock…) |

Hook order in `GrasslandRegionBuilder`: vegetation → **dressing** → discoveries.

## What gets placed

**Meadows** — tall grass MultiMesh, flowers, bushes, rocks, lone trees, dirt patches (no empty green voids).

**Forest understory** — clearings, fallen logs, mushrooms, moss rocks, animal trail dirt.

**Animal trails / path guidance** — dirt ribbons + roadside cairns that invite off-road exploration.

**Micro-stories** — camps, wagons, bones, packs, monuments, crystals, cabins, meteor scars… each with a discoverable message. Some grant chests / supply stashes.

**Natural landmarks** — arches, seeps, ponds, caves, shrines — **not** on the mini-map.

**Viewpoints** — scenic benches; reward is often the view (one rare cache).

## Discovery hierarchy (reminder)

| Tier | Mini-map |
| --- | --- |
| Major / Landmark | Yes (secrets hide until found) |
| Dressing micro-stories & natural landmarks | **No** |
| Secrets | **No** |

## Runtime events

`WorldEncounterDirector` rolls ambient beats near the player (one at a time):

- Creature sparring / parent guard / wounded critter
- Merchant ambush or resting merchant
- Lost traveler
- Rare crossing
- Bird flush
- Meteor glint (curiosity seed)

## Budget

Dressing uses **MultiMesh** for volume and sparse Node3D vignettes for meaning. Far dressing sleeps via `WorldStreamController`. Authored gate remains `AdventureNodeBudget.AUTHORED_NODE_GATE`.

## Smoke

```bash
godot --headless --path digital-frontier --scene res://scenes/devtools/world_dressing_smoke.tscn
godot --headless --path digital-frontier --scene res://scenes/devtools/adventure_stability_probe.tscn
```
