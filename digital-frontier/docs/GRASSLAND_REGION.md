# Grassland Region — First Major Chapter

## Feel

A peaceful but mysterious countryside: neighborhoods, farms, forests, lakes, shops, and hidden places. Large enough to explore, small enough to learn by heart.

Walk speed reference: **6.5 units/sec** (`PlayerController.WALK_SPEED`).

Layouts are **OG Athena–inspired structure** with **original Digital Frontier art** (not franchise IP).

## Map layout

```
        N (-Z)
         │
   Grease Grove (−550,350)    Mirror Mere (1150,−350) ──── Risky Reels (2800,−2700)
          \                    /                              [NE drive-in]
           \                  /
            Pleasant Park (0,0) ──────── Market Mile (1900,450)
            [NW heart / start]              [east retail strip]
                   │
                   ▼
            Salty Springs (900,1270)
            [south-central hill town]
                   │
                   ▼
            Fatal Fields (500,4600)
            [further south farm]
```

| POI | World center (X, Z) | Familiar role (original DF art) |
|-----|---------------------|----------------------------------|
| **Pleasant Park** | `(0, 0)` | Suburban park neighborhood |
| **Grease Grove** | `(-550, 350)` | Fast-food plaza + bungalows (GigaBite) |
| **Mirror Mere** | `(1150, -350)` | Central lake + island cabin |
| **Market Mile** | `(1900, 450)` | Long shopping street + Anchor store |
| **Risky Reels** | `(2800, -2700)` | Drive-in cinema |
| **Salty Springs** | `(900, 1270)` | Hillside houses + gas |
| **Fatal Fields** | `(500, 4600)` | Farmhouse, barn, corn, creek |

See also [NEW_POIS.md](NEW_POIS.md) for adaptation notes.

## Distances (straight-line → walk time)

| Route | Distance | Walk time | Design target |
|-------|----------|-----------|---------------|
| Park → Grease Grove | ~650 u | ~1.7 min | short side trip |
| Park → Mirror Mere | ~1200 u | ~3.1 min | 2–4 min |
| Park → Salty Springs | ~1556 u | ~4.0 min | 3–5 min |
| Park → Market Mile | ~1950 u | ~5.0 min | 4–6 min |
| Park → Risky Reels | ~3897 u | ~10.0 min | 8–12 min |
| Park → Fatal Fields | ~4627 u | ~11.9 min | 10–15 min |

## Terrain transitions

1. **Park → Grease Grove (W)** — suburban asphalt → plaza neon + burger statue  
2. **Park → Mirror Mere (ENE)** — country road → lake shore → island cabin  
3. **Park → Market Mile (E)** — commercial approach → Mile arch → shop row  
4. **Park → Salty / Fields / Reels** — unchanged chapter corridors  

## Expansion points

Markers at region edges for future chapters (N/E/S/W).

## Contracts preserved

- `player_spawn`, `chests[]`, `enterable_houses[]`
- Existing Pleasant Park discoverable / chest / quest IDs unchanged
- New POIs use unique `location_id` / `chest_id` / `building_id` values
- Region id for adventure load: `grassland`
