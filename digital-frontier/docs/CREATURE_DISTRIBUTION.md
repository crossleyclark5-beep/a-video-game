# Creature Distribution Plan

Digital Frontier is a multi-biome world. **Grassland is chapter 1 only** — a teaching region with a small early ecosystem. Every planned creature exists in data now; only biome-assigned species spawn live.

Source of truth: `BiomeDistributionCatalog` (`scripts/world/biome_distribution_catalog.gd`).

## Design rules

1. Do **not** dump the full lookalike roster into Grassland.
2. Entering a new biome should feel like discovering creatures the player has never seen.
3. Bosses are assigned per biome and grow stronger with chapter.
4. The Creature Index lists the full world as `????` until sighted — discovery spans adventure length.

## Grassland (Chapter 1) — live now

| Role | Creatures |
|------|-----------|
| Wildlife | Cotton Rabbit, Meadow Bird, Park Deer, Glow Kit, Pack Pup, Lunamoth, Phantom Hare |
| Enemies | Glitchmite + Koromon / Chuumon / Gazimon look-alikes |
| Mini-boss | Glitch Alpha |
| Major boss | Hollow Warden (Pine Hollow) |
| Partners | Agumon, Gabumon, Biyomon, Tentomon, Gomamon, Gatomon look-alikes |

## Future biomes (database-ready)

| Biome | Wildlife / enemies (examples) | Boss |
|-------|-------------------------------|------|
| Forest | Hex Squirrel, Timber Moose, Thorn Boar, Pumpkinmon | Snimon |
| Swamp | Mire Wisp, Numemon, Bakemon | — (later) |
| Mountains | Ridge Goat, Byte Bat, Scrub Wolf, Gotsumon | Orgemon |
| Snow | Frost Puff, Frigimon, Icemon | — |
| Desert | Sand Skitter, Junkmon | — |
| Volcanic Region | — | Meramon |
| Ancient Ruins | Byte Bat, Hagurumon, Datamon, Gotsumon | Andromon (shared) |
| Digital City | Junkmon, Hagurumon, Datamon, Digitamamon · Sparkbit companion | Andromon |
| Sky Islands | Biyomon habitat echo | — |
| Ocean | Tide Drifter · Tidepup companion | Whamon |
| Dark Lands | Impmon, Bakemon, Monzaemon | Devimon |
| Endgame | Monzaemon, Digitamamon | — |

## Discovery

`CollectionManager` indexes `EcosystemCatalog.all_species_database()` plus `all_planned_bosses()`. Grassland living spawns still use `grassland_species()` only.

## Smoke

```bash
godot --headless --path digital-frontier --scene res://scenes/devtools/biome_ecosystem_smoke.tscn
```

Expect `BIOME_ECOSYSTEM_SMOKE_OK`.
