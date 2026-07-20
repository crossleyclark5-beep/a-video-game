# Exploration Map & Living World

## Goals

- Handheld mini map that shows **shape, roads, majors, terrain** without spoiling secrets
- Discovery fog: unvisited places = desaturated mystery icons; visited = full color + name
- Living travel spaces: grass blades, forest belts, hills, climbable mountain paths
- Map silhouette matches the **island coastline**, not a blank rectangle

## Analysis (before)

| Gap | Previous state |
|-----|----------------|
| Map | Text-only Field Unit sheet → later a full green rectangle |
| Discovery fog | Flags existed; no visual map |
| Between POIs | Flat green mega-plane + sparse roadside trees |
| Mountains | Block props only; player Y locked (`velocity.y = 0`) |
| Vegetation | Grass/trees could land on roads and building pads |

## Island map shape

- **`GrasslandLayout.island_coastline()`** — irregular XZ polygon wrapped around POI spread
- **`RegionMiniMap`** draws ocean wash + island fill + beach rim; explored cells clip to the island
- Roads, rivers/water icons, mountains, and POI markers keep world proportions and north-up orientation

## Mini map / discovery

- **`RegionMapCatalog`** — POI + landmark positions, icon kinds, mystery labels
- **`RegionMiniMap`** — corner glance map + full MAP sheet map (buttons: `map_peek` / device cycle)
- Undiscovered majors still draw (grey) so players know *something* is there
- Secrets stay hidden until found
- Explored cells (`WorldManager.mark_explored_at`) brighten map wash as the player travels

## Terrain & vegetation

- **`RegionVegetationBuilder`** — placement rules: hub pad exclusions, road clearance, island bounds
- **`RegionCorridorBuilder`** — shoulder forests sit outside road clearance
- **`RegionTerrainBuilder`** — rolling hills with approach ramps; West Ridge / North Pass / South Bluffs with **switchback trails**
- Houses use dirt foundation pads; lawns stay outside the footprint
- Steep mountain faces are near-vertical collision → player slides / cannot wall-climb
- Player gravity + `floor_max_angle` enables hill/trail walking

## Multi-floor interiors

- **`BuildingFloor`** + **`BuildingInteriorController`** — only the occupied story is visible/collidable
- Roof fade + shell/front-wall cutaway on enter; fill light follows the active floor
- Camera uses a **relative** story lift (does not double-count player height)
- Works for any building height (2-story homes through towers) via floor_index

## Performance (handheld)

- Grass MultiMesh only near hubs + corridor shoulders (not whole continent)
- Forest belts along roads (structured clumps), not random fill
- Material caches via `StylizedMesh`
- Explored-cell list capped (`MAX_EXPLORED_CELLS`)

## Feel test

Travel should feel like gameplay. The map should say “there’s a town that way” before you’ve been there — and celebrate color when you arrive. Indoors, you should always know which floor you are on.
