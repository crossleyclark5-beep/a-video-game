# Visual Upgrade — Pleasant Park

Superseded in spirit by **[PIXEL_WORLD_STYLE.md](PIXEL_WORLD_STYLE.md)** (global pixel-art 2.5D direction).

## OG-inspired layout

`pleasant_park_builder.gd` mirrors classic Pleasant Park **structure** (original art, no franchise IP):

| Landmark | Placement |
|----------|-----------|
| Central park + gazebo + picnic tables | Square lawn at origin, trees framing the ring |
| 8 houses | N/E/S/W sides of the ring, doors facing the park |
| Soccer field | North of the house ring |
| Fuel stop (yellow/red) | East periphery |
| Welcome sign / spawn | South approach |

## Pixel-art conversion (current)

| Layer | Change |
|-------|--------|
| Materials | Flat toon + nearest + procedural pixel patterns |
| Lighting | Linear tonemap, hard shadows, no bloom |
| Terrain / roads | Grass/dirt/asphalt patterns, painted lines |
| Trees / bushes | Chunky stacked boxes (not soft spheres) |
| Buildings | Brick/wood patterns, strong silhouettes |
| Water | Flat pixel water material |
| UI / camera | Square ink chrome, snappy diorama follow |

## Gameplay safety

Unchanged contracts:
- `player_spawn`, `chests[]`, `enterable_houses[]`
- `DoorInteractable`, `Roof`, `ExteriorExit`, `InteriorEntry`
- Chest loot IDs / rarity tiers
- Player movement / interaction systems

## Time of day

`WorldAtmosphere.apply_phase(MORNING | AFTERNOON | EVENING)` — default Afternoon.
