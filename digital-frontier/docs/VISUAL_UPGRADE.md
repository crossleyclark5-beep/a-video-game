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
| Materials | Flat toon + nearest + **64×64** procedural patterns (triplanar world tiling) |
| Lighting | Linear tonemap, parallel-split shadows, soft lamp glow, light weather, day cycle |
| Terrain / roads | Dense grass/dirt/path/asphalt detail, plants, rocks, path wear |
| Trees / bushes | Multi-cluster leaf boxes with leaf textures (still low-poly) |
| Buildings | Brick/wood/roof patterns, framed windows, ridge/eave detail |
| Water | Animated 4-frame pixel water + soft reflection emission |
| UI / camera | Square ink chrome, snappy diorama follow |

## Gameplay safety

Unchanged contracts:
- `player_spawn`, `chests[]`, `enterable_houses[]`
- `DoorInteractable`, `Roof`, `ExteriorExit`, `InteriorEntry`
- Chest loot IDs / rarity tiers
- Player movement / interaction systems

## Time of day

`WorldAtmosphere` auto-cycles morning→afternoon→evening (~7 min) while keeping discrete palette steps.
