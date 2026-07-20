# Visual Upgrade — Pleasant Park

## Why it looked like a prototype

| Issue | Cause |
|-------|--------|
| Flat chalky surfaces | One albedo color per mesh, no material variety |
| Empty sky / void | No `WorldEnvironment` |
| No depth | Shadows off, no fog, flat lighting |
| Copy-paste props | Identical trees/houses/lamps |
| Sparse “empty lot” feel | Few props, no cars/signs/utility detail |
| Toy camera | High equal Y/Z orbit, large ortho size |

## Upgrade plan (implemented)

1. **Materials** (`stylized_mesh.gd`) — cached materials, roughness/metal variance, glass panes, wood/asphalt helpers  
2. **Atmosphere** (`world_atmosphere.gd`) — sky color, ambient, filmic tonemap, soft fog, sun + fill, morning/afternoon/evening phases  
3. **Terrain / roads** — grass tone patches, dirt wear, curbs, real dashed lines, crosswalks, driveways  
4. **Vegetation** — oak / pine / round trees, bushes, rocks, fallen leaves, flower beds  
5. **Houses** — unique style kits (brick, cottage, colonial, garden, modern, bungalow, ranch, victorian), gutters, glass windows, driveways, yard props  
6. **Lived-in town** — street lamps with lights, parked cars, benches, bins, utility poles, street signs, playground  
7. **Camera** — steeper miniature angle, tighter default zoom, smoother settle + look-ahead  

## Gameplay safety

Unchanged contracts:
- `player_spawn`, `chests[]`, `enterable_houses[]`
- `DoorInteractable`, `Roof`, `ExteriorExit`, `InteriorEntry`
- Chest positions / loot IDs
- Player movement / interaction systems

## Handheld notes

- Material cache reduces unique shader variants  
- Street lamp omnis capped (6 lit)  
- Soft directional shadows, no per-prop shadows on lamps  
- Orthographic camera kept (interior zoom API intact)  
- Ambient pollen particles are lightweight GPU particles  

## Time of day

`WorldAtmosphere.apply_phase(MORNING | AFTERNOON | EVENING)` is ready for a future clock / settings toggle. Default: Afternoon.
