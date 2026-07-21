# Multi-User Profiles (Field Unit)

Digital Frontier is a **shared handheld**. Each person gets their own offline adventure.

## Flow

1. Power-on logo (`DeviceBootSequence`)
2. **Profile select** (`ProfileSelect`) — choose / create / erase
3. Partner select if this profile has no companion yet
4. Digi-Pet Home loads **that user’s** creature

Settings → **Switch Profile** saves the current adventure and returns to the gate.

## Storage (local only)

| Path | Role |
|------|------|
| `user://saves/profiles.json` | Index: names, avatars, summaries |
| `user://saves/profiles/{id}/slot_0.res` | Per-user `GameState` |

- Max **8** profiles (`ProfileCatalog.MAX_PROFILES`)
- No internet, cloud, or online login
- Legacy `user://saves/slot_0.sav` / `slot_0.res` migrates into a “Traveler” profile once

## Per-profile data

Isolated via manager `reset_state()` + `import_state()`:

- Player: inventory, bits, settings volumes, playtime, checkpoint
- Creature: partner, evolution, care, memories, battle history
- World: discoveries, quests, NPCs, collections, shop, vehicles

## UI

Field Unit chrome (`DFStyle`): avatar glyph, partner blurb, playtime, completion %.

- **A** — continue / confirm create / confirm erase  
- **Start** — erase selected (confirmation required)  
- **B** — back from create / cancel erase  
- Create: name presets + avatar carousel (pad-friendly, no keyboard)

## NFC (future)

`DeviceService.exchange_profile_snapshot()` returns profile id + creature payload for device-to-device battles / trades — still offline.

## Smoke

```bash
godot --headless --path digital-frontier --scene res://scenes/devtools/profile_smoke.tscn
```
