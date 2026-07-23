# Creature Ecosystem

The world is a living multi-biome creature ecosystem. **Grassland** is the spawn-live chapter 1 teaching region — not the full roster.

## Systems

| Piece | Role |
|-------|------|
| `BiomeDistributionCatalog` | Creature → biome / chapter plan for the whole world |
| `EcosystemCatalog` | Species tables: rarity, temperament, day/night, weather; `grassland_species()` live; `all_species_database()` full index |
| `EcosystemCreature` | Unified wild AI — graze/sleep/play/flee/guard/chase/hunt/pack warn |
| `WorldEncounterDirector` | Vignettes: duels, parent guard, wounded, merchant ambush, rare crossing, bird flush |
| `RegionBossActor` | **Hollow Warden** at Pine Hollow (chapter 1). Future lookalike bosses per biome |
| `MiniBossActor` | **Glitch Alpha** — Grassland mini-boss |
| `CollectionManager` Creature Index | Full-world discovery (`????` until sighted) |
| `WorldAtmosphere` | Morning / Afternoon / Evening / **Night** + Clear / Rain / Fog / Storm |

## Grassland live set

7 wildlife · Glitchmite · 3 beginner lookalike foes · Glitch Alpha · Hollow Warden.

See `docs/CREATURE_DISTRIBUTION.md`.

## Rarity

Common · Uncommon · Rare · Legendary · Mythical

## Behaviors

Passive · Defensive · Aggressive · Pack · Predator

## Handheld

- Field Unit **INDEX** sheet (cycle with X)
- Collection sheet highlights Creature Index cards
- Companion senses wildlife / danger; celebrates rare discoveries

## Performance

Budgeted spawn/despawn via `LivingWorldController` (nearby only). Boss never despawns mid-fight when far.

## Quests

- `index_novice` — log 3 wild species

## Smoke

`res://scenes/devtools/creature_ecosystem_smoke.tscn`  
`res://scenes/devtools/biome_ecosystem_smoke.tscn`
