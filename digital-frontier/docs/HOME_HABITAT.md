# Digi-Pet Home (Field Unit)

Home is a **classic digital companion device** — not a miniature Adventure world, not a 3D habitat room.

When you power on, you should feel: **“This is my creature.”**

## Modes

| Mode | Role |
|------|------|
| **Home / Digi-Pet** | LCD companion care, status, battle link, shop, journal |
| **Adventure** | Full 2.5D Digital Frontier world — same partner carries over |

## Boot sequence

1. Digital Frontier logo + LCD scan splash (`DeviceBootSequence`)
2. **Profile select** (`ProfileSelect`) — local multi-user gate
3. Partner select if this profile has no companion saved (`PartnerSelect`)
4. Digi-Pet Home LCD (loads the active profile’s creature)

See `docs/MULTI_PROFILE.md`.

## Partner choice

Starters (meaningful differences):

| Partner | Feel | Path | Strength |
|---------|------|------|----------|
| **Emberling** | Warm, brave explorer | Emberling → Emberaptor → Emberion | Balanced attack / curiosity |
| **Sparkbit** | Quick code-spirit | Sparkbit → Sparkbolt → Sparkion | Speed / playfulness |
| **Tidepup** | Calm guardian | Tidepup → Tidemaul → Tidalking | Defense / affection |

## LCD

- Creature fills the glass — **no house / room / furniture**
- Green-tinted pixel plate, scanlines, status pips
- Idle / care / leave-for-adventure anims

## Device loop

Check status → Care (Feed / Train / Heal / Interact) → Battle → Adventure → Journal / Shop → continue

| Button | Action |
|--------|--------|
| Interact | Bond (pet) |
| Feed | Hunger |
| Train | Friendship / XP |
| Heal | Health |
| Status | Details + meters sheet |
| Battle | NFC-stub device fight |
| Adventure | Enter world (progress carries) |
| Journal | Discoveries, creatures, items, memories, achievements |
| Shop | Spend Bits from Adventure |

## Battle

Fast digi-pet duel (`DeviceBattle`): link stub → A attack / X special / B flee → XP + Bits on win. Not a full RPG battle system.

## Files

| Module | Path |
|--------|------|
| Home shell | `scenes/home/home_habitat.gd` |
| Boot | `scripts/home/device_boot_sequence.gd` |
| Partner select | `scripts/home/partner_select.gd` |
| LCD | `scripts/home/pixel_habitat_lcd.gd` |
| Sprite | `scripts/home/pixel_creature_sprite.gd` |
| Battle | `scripts/home/device_battle.gd` |
| HUD | `scenes/home/ui/home_hud.*` |
| Companion state | `CreatureManager` autoload |

Controls: D-pad focus · A confirm · B back · Y interact · Start Adventure. No touchscreen.
