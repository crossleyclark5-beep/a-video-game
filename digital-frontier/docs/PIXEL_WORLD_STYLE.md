# Pixel World Style — Digital Frontier

## Goal

A modern pixel-art inspired **2.5D adventure diorama** — like a lost 1990s/early-2000s handheld classic rebuilt with modern tech.

Not AAA realism. Not soft clay toy 3D.

## Why it previously felt generic 3D

| Cause | Effect |
|-------|--------|
| Soft GGX / plastic roughness | Plastic clay surfaces |
| Filmic tonemap + glow bloom | Cinematic AAA “polish” |
| High-segment spheres / cylinders | Smooth modern meshes |
| Soft multi-sphere tree canopies | Blob vegetation |
| Teal glass UI with rounded corners | Modern app chrome |
| Soft camera look-ahead + settle | Floaty modern follow cam |
| Per-prop pastel colors | No shared limited palette |

## Art direction (applied)

1. **`WorldPalette`** — one limited handcrafted palette + color quantization  
2. **`StylizedMesh`** — flat toon materials, specular off, nearest textures, 16×16 pixel patterns (grass / asphalt / brick / wood / water / dirt)  
3. **`WorldAtmosphere`** — linear tonemap, no glow, hard orthogonal sun shadows, discrete morning/afternoon/evening skies  
4. **Pleasant Park** — pixel grass/roads, chunky box trees, brick/wood patterns on buildings, stylized flat water  
5. **Camera** — snappier follow, less look-ahead, stepped zoom  
6. **UI** — square ink/paper/accent Field Unit chrome  
7. **Player / companion / habitat** — nearest flat materials, dim aura, no habitat bloom  

## Handheld notes

- Material cache + shared palette → fewer unique variants  
- Low mesh segments (≤8) and box-first props  
- Soft particle counts reduced; cube pollen motes  
- Orthographic diorama camera kept for small-screen readability  

## Gameplay contracts (unchanged)

- `player_spawn`, `chests[]`, `enterable_houses[]`
- `DoorInteractable`, `Roof`, `ExteriorExit`, `InteriorEntry`
- Chest / quest / companion systems

## Feel test

If you squint at the first frame of Adventure, it should read as a **colorful miniature handheld town**, not a soft modern 3D tech demo.
