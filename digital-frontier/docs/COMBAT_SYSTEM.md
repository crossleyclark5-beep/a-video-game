# Combat System

In-world companion battles for Digital Frontier — Digimon-style partner fights with handheld buttons, not a menu-heavy RPG screen.

## Feel

- Partner is the main fighter; the player coaches with five face-button commands.
- Camera tightens around the fight; the world stays visible.
- Wins feed the same `CreatureInstance` used on Digi-Pet Home (XP, bond, memories, vitals).

## Activation

| Path | Trigger |
|---|---|
| Engage | Y / creature action near a hostile |
| Ambush | Hostile / mini-boss / boss melee contact → `EventBus.battle_encounter_requested` |
| Story | Call `BattleDirector.try_start_from_target(enemy, true)` |

## Loop

Encounter → intro → choose → resolve → result → rewards → autosave

## Commands (physical buttons only)

| Command | Input |
|---|---|
| Cycle | D-pad / stick left-right |
| Confirm | A |
| Escape | B |
| Ability | Y |
| Item | X |

Options: **Attack · Dodge · Ability · Item · Escape**

## Systems

| Piece | Role |
|---|---|
| `BattleDirector` | Session state machine |
| `CombatantState` | Ally / enemy runtime stats |
| `CombatCatalog` | Moves, rewards, NFC-ready records |
| `CombatTypes` | Ember / Tide / Volt / Nature / Hex affinities |
| `CombatHud` | Bottom sheet HP + commands |

## Enemy tiers

`wild` · `elite` · `mini_boss` · `boss`

Bosses use unique moves (`Root Slam`, `Pine Ward`, …), phase-ready actors, and `BossData` spoils — not scaled trash mobs.

## Progression

- Personality battle style gates moves (aggressive / tank / swift…).
- Level 6+ and 10 unlock stronger partner specials.
- Victory grants XP, Bits, bond, battle memory, and evolution progress via existing companion growth.

## Digi-Pet bridge

Adventure battles update companion health/energy, battle history, and memories. Home and Field share one partner.

## NFC-ready records

`CombatCatalog.make_battle_record()` stores offline schemas (`won`, companion id/level/stage, enemy, turns). No network required — reserved for future device-to-device exchange.

## Smoke

`res://scenes/devtools/combat_smoke.tscn`
