# Item Shop Character Roster

## Legal / asset gate

| Requested Sketchfab source | Decision |
|----------------------------|----------|
| Fortnite Ice King, Jonesy, Peely, Master Chief, etc. | **Rejected** — Epic (and other) IP. Fan rips on Sketchfab are not redistributable. |

Digital Frontier ships **Kenney Blocky Characters (CC0)** meshes with per-outfit tints and accent props instead. Shop display names match the requested roster fantasy so the Item Shop still reads as a character unlock board.

## Roster (14)

| ID | Name | Unlock |
|----|------|--------|
| `char_jonesy` | Jonesy | **Starter** (equipped at profile start) |
| `char_ice_king` | Ice King | Shop · 800 Bits |
| `char_indiana` | Indiana Jones | Shop · 750 Bits |
| `char_8ball` | 8 Ball | Shop · 600 Bits |
| `char_prisoner` | Prisoner | Shop · 550 Bits |
| `char_black_knight` | Black Knight | Shop · 900 Bits |
| `char_peely` | Peely | Shop · 700 Bits |
| `char_marshmallow` | Marshmallow | Shop · 650 Bits |
| `char_master_chief` | Master Chief | Shop · 1000 Bits |
| `char_dj_yonder` | DJ Yonder | Shop · 720 Bits |
| `char_dark_voyager` | Dark Voyager | Earn · Hollow Challenge |
| `char_omega` | Omega | Earn · Pine Threat |
| `char_raptor` | Raptor | Earn · Wildlife Watch |
| `char_storm_trooper` | Storm Trooper | Earn · Park Explorer |

## Systems

| Piece | Role |
|-------|------|
| `CharacterOutfitCatalog` | Mesh / tint / prop / unlock metadata |
| `CharacterRosterManager` | Unlock, equip, apply to player, save |
| `ItemData` (`char_*`) | Field Unit Shop PLAYER category |
| `CharacterKit.attach_outfit` | GLB + tint + prop |

Open **Field Unit Shop → PLAYER** to buy. Owned pack **A** equips. Completing earn quests unlocks the four quest characters automatically.

## Smoke

```bash
godot --headless --path digital-frontier --import
godot --headless --path digital-frontier --scene res://scenes/devtools/character_shop_roster_smoke.tscn
```

Expect `CHARACTER_SHOP_ROSTER_SMOKE_OK`.
