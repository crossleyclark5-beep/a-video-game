# Exploration Map & Living World

## Goals

- Handheld mini map that shows **shape, roads, majors, terrain** without spoiling secrets
- Discovery fog: unvisited places = desaturated mystery icons; visited = full color + name
- Living travel spaces: grass blades, forest belts, hills, climbable mountain paths

## Analysis (before)

| Gap | Previous state |
|-----|----------------|
| Map | Text-only Field Unit sheet |
| Discovery fog | Flags existed; no visual map |
| Between POIs | Flat green mega-plane + sparse roadside trees |
| Mountains | Block props only; player Y locked (`velocity.y = 0`) |

## Mini map / discovery

- **`RegionMapCatalog`** — POI + landmark positions, icon kinds, mystery labels
- **`RegionMiniMap`** — corner glance map + full MAP sheet map (buttons: `map_peek` / device cycle)
- Undiscovered majors still draw (grey) so players know *something* is there
- Secrets stay hidden until found
- Explored cells (`WorldManager.mark_explored_at`) brighten map wash as the player travels

## Terrain & vegetation

- **`RegionVegetationBuilder`** — MultiMesh grass strips, structured forest belts, clearings (Pine Hollow, Meadow Clearing)
- **`RegionTerrainBuilder`** — rolling hills with approach ramps; West Ridge / North Pass / South Bluffs with **switchback trails**
- Steep mountain faces are near-vertical collision → player slides / cannot wall-climb
- Player gravity + `floor_max_angle` enables hill/trail walking

## Performance (handheld)

- Grass MultiMesh only near hubs + corridor shoulders (not whole continent)
- Forest belts along roads (structured clumps), not random fill
- Material caches via `StylizedMesh`
- Explored-cell list capped (`MAX_EXPLORED_CELLS`)

## Feel test

Travel should feel like gameplay. The map should say “there’s a town that way” before you’ve been there — and celebrate color when you arrive.
