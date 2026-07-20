# Pixel World Style — Digital Frontier

## Goal

A modern pixel-art inspired **2.5D adventure diorama** — like a modern handheld game inspired by 90s pixel art.

Not AAA realism. Not soft clay toy 3D. Not a low-res remake limited by old hardware.

## Why pixels previously felt too large

| Cause | Effect |
|-------|--------|
| 16×16 procedural patterns | Very few texels per surface |
| UV scale ~2 on BoxMesh faces | A 110-unit lawn had ~3.4-unit “pixels” |
| No world-space tiling | Huge meshes magnified the same tiny atlas |
| Sparse canopy / prop meshes | Silhouettes read as big flat blocks |

## Density upgrade (current)

1. **64×64 procedural patterns** — grass, asphalt, brick, wood, dirt, water, leaf, roof, path  
2. **Triplanar world tiling** — stable ~0.1-unit pixels on huge ground and tiny props alike  
3. **Richer pattern generators** — blades, grit, mortar, grain, shingles, leaf clusters  
4. **Animated water** — 4-frame nearest AnimatedTexture + soft emission sparkle  
5. **Framed windows** — sill, mullion, glass (not a bare pane)  
6. **Denser environment props** — plants, rocks, path wear, multi-cluster trees, roof ridges  

## Art direction (kept)

1. **`WorldPalette`** — limited handcrafted palette + quantization  
2. **`StylizedMesh`** — flat toon, specular off, nearest filter, high-res pixel patterns  
3. **`WorldAtmosphere`** — linear tonemap, soft lamp glow (not cinematic bloom), parallel-split shadows with light blur, fog, pollen weather, slow morning→afternoon→evening cycle  
4. **Region builders** — Pleasant Park + grassland POIs share the same density language  
5. **Camera / UI** — snappy follow, stepped zoom, square ink/paper Field Unit chrome  

## Handheld notes

- Material + texture caches → few unique GPU variants  
- Box-first props; low mesh segments (≤8)  
- Soft particle counts (~48 cube motes)  
- Orthographic diorama camera for small-screen readability  
- Glow is thresholded and mild so it reads as lamp/water sparkle on a handheld LCD  

## Gameplay contracts (unchanged)

- `player_spawn`, `chests[]`, `enterable_houses[]`
- `DoorInteractable`, `Roof`, `ExteriorExit`, `InteriorEntry`
- Chest / quest / companion systems

## Feel test

If you squint at Adventure, it should read as a **colorful high-res handheld town** — more pixels and detail than a chunky remake, still proudly pixel-art.
