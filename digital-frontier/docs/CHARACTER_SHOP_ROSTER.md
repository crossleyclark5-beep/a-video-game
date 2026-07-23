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

## Roster (14) — healthy unlock progression

Most cosmetics stay buyable in the Field Unit Shop. A few unlock later via Bits lifetime, bosses, or quests.

| ID | Name | Unlock | Look-alike style |
|----|------|--------|------------------|
| `char_jonesy` | Jonesy | **Starter** | Field agent — blue polo, DF cap, pack |
| `char_indiana` | Indiana Jones | Shop · 750 | Relic runner — fedora, leather, satchel |
| `char_8ball` | 8 Ball | Shop · 600 | Cue-ball — gloss black + 8 medallion |
| `char_prisoner` | Prisoner | Shop · 550 | Breakout — orange stripe jumpsuit |
| `char_peely` | Peely | Shop · 700 | Sunny peel — banana-hero silhouette |
| `char_marshmallow` | Marshmallow | Shop · 650 | Soft guard — stacked puff + scarf |
| `char_dj_yonder` | DJ Yonder | Shop · 720 | Neon mixer — headset + speaker pack |
| `char_ice_king` | Ice King | **Gate** · 800 Bits after **600 Bits lifetime** | Frost monarch — crystal crown + cape |
| `char_black_knight` | Black Knight | **Gate** · 900 after **Hollow Warden** | Onyx plate — crimson plume & cape |
| `char_master_chief` | Master Chief | **Gate** · 1000 after **Glitch Alpha** | Chrome sentinel — olive armor + gold visor |
| `char_dark_voyager` | Dark Voyager | Earn · Hollow Challenge | Void voyager — purple visor suit |
| `char_omega` | Omega | Earn · Pine Threat | Apex protocol — orange energy veins |
| `char_raptor` | Raptor | Earn · Wildlife Watch | Ridge scout — camo hood + vest |
| `char_storm_trooper` | Storm Trooper | Earn · Park Explorer | Star patrol — white plates + bucket helm |

## Systems

| Piece | Role |
|-------|------|
| `CharacterLookalikeKit` | Per-outfit retro builds |
| `CharacterOutfitCatalog` | Unlock metadata (`shop` / `earn` / `gate`) + style tags |
| `CharacterRosterManager` | Unlock, equip, apply, gate checks, save |
| `ShopManager` | Refuses gated skins until flags / Bits met |
| `ItemData` (`char_*`) | Field Unit Shop PLAYER category |
| `CharacterKit.attach_outfit` | Lookalike first, Kenney tint fallback |

Open **Field Unit Shop → PLAYER** to buy. Locked gates show a hint. Owned pack **A** equips. Completing earn quests unlocks the four quest characters automatically.

## Smoke

```bash
godot --headless --path digital-frontier --import
godot --headless --path digital-frontier --scene res://scenes/devtools/character_lookalike_smoke.tscn
godot --headless --path digital-frontier --scene res://scenes/devtools/character_shop_roster_smoke.tscn
godot --headless --path digital-frontier --scene res://scenes/devtools/biome_ecosystem_smoke.tscn
```

Expect `CHARACTER_LOOKALIKE_SMOKE_OK`, `CHARACTER_SHOP_ROSTER_SMOKE_OK`, and `BIOME_ECOSYSTEM_SMOKE_OK`.
