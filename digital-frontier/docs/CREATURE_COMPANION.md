# Creature Companion System

The partner is one living `CreatureInstance` shared across Digi-Pet Home and Adventure.

## Identity

| Field | Notes |
|---|---|
| Name | Nickname (rename via `CreatureManager.rename_companion`) |
| Personality | Axes + primary trait (Brave, Playful, Curious, Calm, Energetic, Stubborn, Protective) |
| Level / XP | Shared growth |
| Health / Energy / Happiness / Friendship | Care needs |
| Evolution stage + path | Branching `EvolutionPathData` |
| Battle history | Wins / losses / strikes / bosses |
| Memories | Capped list of shared moments |

## Personality → behavior

`CompanionPersonality` drives:

- Dialogue / Y-button talk lines
- Follow side, weave, distance
- Sense radius
- Adventure speed when tired/happy
- Device battle style (aggressive, tank, swift, …)

## Interactions

Home **Interact** (and Adventure **Y**):

- Talk — personality line + bond
- Comfort — when sad/tired
- Celebrate — after victories
- Feed / Train / Heal — classic care

## Evolution branches

Data in `res://data/evolutions/`. Example Emberling stage 0→1:

- **Guardian** — care + protective
- **Striker** — battles + brave
- **Scout** — explore + curious
- **Classic** — level/friendship fallback

Auto-picks highest priority qualifying path on growth.

## Follower

`AdventureCompanionActor`: soft orbit follow, obstacle sidestep, face player when close, caution near bosses, weather barks, discovery/battle memories.

## Smoke

`res://scenes/devtools/creature_companion_smoke.tscn`
