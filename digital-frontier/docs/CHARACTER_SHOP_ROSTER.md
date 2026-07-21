# Item Shop Character Roster

## Legal / asset gate

| Requested Sketchfab source | Decision |
|----------------------------|----------|
| Fortnite Ice King, Jonesy, Peely, Master Chief, etc. | **Rejected** — Epic (and other) IP. Fan rips on Sketchfab are not redistributable. |

Digital Frontier ships **original retro pixel-toon look-alikes** (`CharacterLookalikeKit`) — inspired silhouettes with DF materials, glow accents, and denser gear kits. Kenney Blocky remains a fallback only.

## Art direction

| Layer | Look |
|-------|------|
| World | Pixel diorama, nostalgic late-90s / early-2000s |
| Shop characters | Higher detail, memorable silhouettes, expressive props |

Each roster slot is a custom build (not a flat tint): color blocking, headgear, armor plates, and soft emission where it fits (ice, neon, void, omega).

## Roster (14)

| ID | Name | Unlock | Look-alike style |
|----|------|--------|------------------|
| `char_jonesy` | Jonesy | **Starter** | Field agent — blue polo, DF cap, pack |
| `char_ice_king` | Ice King | Shop · 800 | Frost monarch — crystal crown + cape |
| `char_indiana` | Indiana Jones | Shop · 750 | Relic runner — fedora, leather, satchel |
| `char_8ball` | 8 Ball | Shop · 600 | Cue-ball — gloss black + 8 medallion |
| `char_prisoner` | Prisoner | Shop · 550 | Breakout — orange stripe jumpsuit |
| `char_black_knight` | Black Knight | Shop · 900 | Onyx plate — crimson plume & cape |
| `char_peely` | Peely | Shop · 700 | Sunny peel — banana-hero silhouette |
| `char_marshmallow` | Marshmallow | Shop · 650 | Soft guard — stacked puff + scarf |
| `char_master_chief` | Master Chief | Shop · 1000 | Chrome sentinel — olive armor + gold visor |
| `char_dj_yonder` | DJ Yonder | Shop · 720 | Neon mixer — headset + speaker pack |
| `char_dark_voyager` | Dark Voyager | Earn · Hollow Challenge | Void voyager — purple visor suit |
| `char_omega` | Omega | Earn · Pine Threat | Apex protocol — orange energy veins |
| `char_raptor` | Raptor | Earn · Wildlife Watch | Ridge scout — camo hood + vest |
| `char_storm_trooper` | Storm Trooper | Earn · Park Explorer | Star patrol — white plates + bucket helm |

## Systems

| Piece | Role |
|-------|------|
| `CharacterLookalikeKit` | Per-outfit retro builds |
| `CharacterOutfitCatalog` | Unlock metadata + style tags |
| `CharacterRosterManager` | Unlock, equip, apply, save |
| `ItemData` (`char_*`) | Field Unit Shop PLAYER category |
| `CharacterKit.attach_outfit` | Lookalike first, Kenney tint fallback |

Open **Field Unit Shop → PLAYER** to buy. Owned pack **A** equips. Completing earn quests unlocks the four quest characters automatically.

## Smoke

```bash
godot --headless --path digital-frontier --import
godot --headless --path digital-frontier --scene res://scenes/devtools/character_lookalike_smoke.tscn
godot --headless --path digital-frontier --scene res://scenes/devtools/character_shop_roster_smoke.tscn
```

Expect `CHARACTER_LOOKALIKE_SMOKE_OK` and `CHARACTER_SHOP_ROSTER_SMOKE_OK`.
