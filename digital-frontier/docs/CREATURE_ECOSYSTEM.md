# Creature Ecosystem

The Grassland is a living creature ecosystem — not just the player's partner.

## Systems

| Piece | Role |
|-------|------|
| `EcosystemCatalog` | Species tables: rarity, temperament, day/night phases, weather tags, biome |
| `EcosystemCreature` | Unified wild AI — graze/sleep/play/flee/guard/chase/hunt/pack warn |
| `WorldEncounterDirector` | Vignettes: duels, parent guard, wounded, merchant ambush, rare crossing, bird flush |
| `RegionBossActor` | **Hollow Warden** at Pine Hollow — unique silhouette, 3 phases |
| `CollectionManager` Creature Index | First sighting unlock, counts, battle W/L, habitat, rarity |
| `WorldAtmosphere` | Morning / Afternoon / Evening / **Night** + Clear / Rain / Fog / Storm |

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
