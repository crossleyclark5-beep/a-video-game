# Grassland Region — First Major Chapter

## Feel

A peaceful but mysterious countryside: neighborhoods, farms, forests, lakes, and hidden places. Large enough to explore, small enough to learn by heart.

Walk speed reference: **6.5 units/sec** (`PlayerController.WALK_SPEED`).

## Map layout (not a grid)

```
                         N (-Z)
                          │
            FATAL FIELDS  │
            (-4200, -2050)│
                  ╲       │
                   ╲ dirt │ meadows / creek
                    ╲     │
                     ╲    │
    SALTY SPRINGS ──── PLEASANT PARK ──── country road ──── RISKY REELS
    (1400, -680)         (0, 0)                              (2400, 3070)
         NE hills          HEART                               SE flats
                          │
                          S (+Z) spawn / welcome
```

| POI | World center (X, Z) | Role |
|-----|---------------------|------|
| **Pleasant Park** | `(0, 0)` | Starting town, heart of the region |
| **Salty Springs** | `(1400, -680)` | Smaller hillside settlement |
| **Risky Reels** | `(2400, 3070)` | Outdoor theater destination |
| **Fatal Fields** | `(-4200, -2050)` | Wide-open farmlands |

## Distances (straight-line → walk time)

| Route | Distance | Walk time | Design target |
|-------|----------|-----------|---------------|
| Park → Salty Springs | ~1556 u | ~4.0 min | 3–5 min |
| Park → Risky Reels | ~3897 u | ~10.0 min | 8–12 min |
| Park → Fatal Fields | ~4673 u | ~12.0 min | 10–15 min |

Winding roads / scenic loops add ~15–25%, so felt travel sits in the upper half of each band without feeling endless.

## Terrain transitions

1. **Park → Salty Springs (NE)** — suburban asphalt → dirt shoulder → pine hills → hillside cottages  
2. **Park → Risky Reels (SE)** — long country asphalt past meadows, a creek bridge, abandoned billboards → theater parking lot  
3. **Park → Fatal Fields (W/NW)** — park fringe → meadow → fenced crop corridors → barn cluster  

Between hubs: sparse props only (road, ground strip, tree clumps, streams, viewpoint / cave / secret shack landmarks). Dense detail stays inside POI radii (~100 u).

## Expansion points

Markers at region edges for future chapters:

- North: highland / mountain approach  
- East beyond Reels: coastal hint  
- West beyond Fields: prairie / storm frontier  

## Contracts preserved

- `player_spawn`, `chests[]`, `enterable_houses[]`
- Existing Pleasant Park discoverable / chest / quest IDs unchanged
- New POIs use unique `location_id` / `chest_id` / `building_id` values
- Region id for adventure load: `grassland` (Pleasant Park remains a discoverable town inside it)
