# Grassland Region — First Major Chapter

## Feel

A peaceful but mysterious countryside: neighborhoods, farms, forests, lakes, shops, and hidden places. Large enough to explore, small enough to learn by heart.

Walk speed reference: **6.5 units/sec** (`PlayerController.WALK_SPEED`).

Layouts use a **hub-and-spoke** around Pleasant Park (Fortnite-style landmark spread) with **original Digital Frontier art**.

## Map layout (hub-and-spoke)

```
                    N (-Z)
                     │
              Risky Reels (~10 min)
                     │
              Meadow · Billboard
                     │
        Mirror Mere (~5)     Stream · Bridge
              ╲               ╱
               ╲             ╱
                Pleasant Park ★
               ╱      │      ╲
              ╱       │       ╲
     Grease Grove   Salty    Market Mile (~7)
       (~6.7 SW)   (~6.5 S)      │
                          Creature Den
                     │
              Prairie Overlook
                     │
              Fatal Fields (~12.5 SE)
```

| POI | World center (X, Z) | Walk from Park | Role |
|-----|---------------------|----------------|------|
| **Pleasant Park** | `(0, 0)` | — | Central hub / start |
| **Risky Reels** | `(120, -3900)` | ~10 min N | Drive-in cinema |
| **Mirror Mere** | `(1380, -1380)` | ~5 min NE | Lake + island |
| **Market Mile** | `(2700, 180)` | ~7 min E | Retail strip + shop |
| **Grease Grove** | `(-2100, 1550)` | ~6.7 min SW | Fast-food plaza |
| **Salty Springs** | `(320, 2520)` | ~6.5 min S | Hill town |
| **Fatal Fields** | `(3350, 3550)` | ~12.5 min SE | Farm |

## Between POIs

Travel corridors include forests, hills, streams, caves, overlooks, creature dens, and wayside chests. Mini-map markers stay **mystery B&W** until discovered, then full color.

## Creature ecosystem (chapter 1 only)

Grassland introduces a **small** early set — not the full world roster. Beginner wildlife, three lookalike pests, **Glitch Alpha** (mini-boss), and **Hollow Warden** (major boss). Partner pick: six Digimon-inspired DF look-alikes. Full biome plan: `docs/CREATURE_DISTRIBUTION.md`.

## Shop

- **Home** Field Unit Shop button → full catalog
- **Market Mile** Bit Grocer counter → adventure + creature + player stock (no home furniture)

See `SHOP_AND_MAP.md`.
