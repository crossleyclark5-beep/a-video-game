# Grassland Region — First Major Chapter

## Feel

A peaceful but mysterious countryside: neighborhoods, farms, forests, lakes, and hidden places. Large enough to explore, small enough to learn by heart.

Walk speed reference: **6.5 units/sec** (`PlayerController.WALK_SPEED`).

Layouts are **OG Athena–inspired structure** with **original Digital Frontier art** (not franchise IP).

## Map layout (OG-relative)

```
        N (-Z)
         │
   Pleasant Park (0,0) ──────── Risky Reels (2800, -2700)
   [NW heart / start]                 [NE drive-in]
         │
         │ country roads
         ▼
   Salty Springs (900, 1270)
   [south-central hill town]
         │
         ▼
   Fatal Fields (500, 4600)
   [further south farm]
```

| POI | World center (X, Z) | OG structure mirrored |
|-----|---------------------|------------------------|
| **Pleasant Park** | `(0, 0)` | 8 houses around park + gazebo, soccer north, gas east, bus stop |
| **Risky Reels** | `(2800, -2700)` | Fenced drive-in, giant screen, dense car rows, ticket + snack + booth |
| **Salty Springs** | `(900, 1270)` | 5 hillside houses + gas station in a steep hollow |
| **Fatal Fields** | `(500, 4600)` | White farmhouse center, red barn, stables, silos, corn, creek |

## Distances (straight-line → walk time)

| Route | Distance | Walk time | Design target |
|-------|----------|-----------|---------------|
| Park → Salty Springs | ~1556 u | ~4.0 min | 3–5 min |
| Park → Risky Reels | ~3897 u | ~10.0 min | 8–12 min |
| Park → Fatal Fields | ~4627 u | ~11.9 min | 10–15 min |

## Terrain transitions

1. **Park → Salty Springs (SSE)** — suburban asphalt → dirt hills → hillside cottages + gas  
2. **Park → Risky Reels (NE)** — long country asphalt, creek bridge, movie billboard → drive-in lot  
3. **Park → Fatal Fields (S via Salty)** — hills → prairie overlook → corn lanes into the farm  

## Expansion points

Markers at region edges for future chapters (N/E/S/W).

## Contracts preserved

- `player_spawn`, `chests[]`, `enterable_houses[]`
- Existing Pleasant Park discoverable / chest / quest IDs unchanged
- New POIs use unique `location_id` / `chest_id` / `building_id` values
- Region id for adventure load: `grassland`
