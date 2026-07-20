# Home Habitat System

The Home screen is a **2D pixel digital companion device** — the nostalgic Field Unit LCD — not a 3D room and not a smartphone UI.

Adventure mode remains the **2.5D living world**. Same `CreatureManager` instance bridges both.

## Contrast

| Mode | Feel |
|------|------|
| **Home** | Late-90s digital pet device — blocky pixels, limited palette, meters, button care |
| **Adventure** | Modern handheld 2.5D world — your companion walks beside you |

## Scene entry

| Path | Role |
|------|------|
| `scenes/home/home_habitat.tscn` | Active home (`GameConstants.SCENE_HOME`) — **Control / 2D** |
| `scenes/home/home_companion.tscn` | Legacy flat UI (reference only) |

## Modules

| Module | Path | Purpose |
|--------|------|---------|
| HomeHabitat | `scenes/home/home_habitat.gd` | Device bezel + LCD + HUD wiring + adventure transition |
| PixelHabitatLcd | `scripts/home/pixel_habitat_lcd.gd` | 160×120 nearest LCD room, stations, AI wander |
| PixelCreatureSprite | `scripts/home/pixel_creature_sprite.gd` | Procedural pixel frames (idle/walk/sleep/eat/happy/sad) |
| HomeAdventureTransition | `scripts/home/home_adventure_transition.gd` | Pixel-gate wipe before loading adventure |
| HomeHud | `scenes/home/ui/home_hud.tscn` | Care buttons + need meters (buttons only) |
| CreatureManager | autoload | Shared needs / XP / friendship across Home ↔ Adventure |

Legacy 3D modules (`HabitatEnvironment`, `CompanionActor`, `HomeStation`) remain in the repo for reference / adventure visuals reuse (`CompanionVisual` still powers the 3D adventure follower).

## Needs (CreatureManager)

| Need | Care |
|------|------|
| Hunger | Feed |
| Happiness | Play / Feed / Train / Pet |
| Energy | Rest |
| Friendship | Play / Train / Pet |
| Health | Rest / Feed |

## Adventure transition

1. Player focuses Adventure (Start / A on Adventure).
2. Pixel creature walks off the LCD (“BYE!”).
3. `HomeAdventureTransition` scanline + pixel scramble.
4. `SceneManager.change_scene(SCENE_GAME_WORLD)` loads 2.5D world with the **same** companion instance.

## Controls (home)

| Input | Action |
|-------|--------|
| D-pad | Focus care / nav buttons |
| A | Activate focused button |
| Y | Quick pet |
| Start | Adventure |
| B | Close pack / journal |

No touchscreen required.
