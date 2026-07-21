# Creature Look-alike Roster

## Legal / asset gate

| Requested source | Decision |
|------------------|----------|
| Digimon Tentomon, Agumon, … (Sketchfab / game rips) | **Rejected** — Bandai / Toei IP |

Digital Frontier ships **original retro pixel-toon look-alikes** (`CreatureLookalikeKit`). Display names mirror the requested fantasy; meshes and silhouettes are DF kits.

**Roster size: 27** (6 companions · 15 enemies · 6 bosses).

## Art direction

| Layer | Look |
|-------|------|
| World | Pixel diorama |
| Creatures | Higher detail, memorable silhouettes, soft glow accents |

Partners stay custom companion kits (never franchise GLBs). Enemies and bosses use the same lookalike language in the field.

## Companions (good) — 6

Selectable at partner pick alongside Emberling / Sparkbit / Tidepup.

| ID | Display | Style |
|----|---------|-------|
| `companion_tentomon` | Tentomon | Ladybug shell + wings |
| `companion_agumon` | Agumon | Orange hatchling dino |
| `companion_gatomon` | Gatomon | White cat + holy ring |
| `companion_gabumon` | Gabumon | Blue pelt-pup |
| `companion_biyomon` | Biyomon | Rose songbird |
| `companion_gomamon` | Gomamon | Surf seal |

## Enemies (bad) — 15

Spawn in Grassland hostile pool via `EcosystemCatalog.lookalike_enemies()`.

Junkmon, Gazimon, Impmon, Koromon, Chuumon, Hagurumon, Numemon, Datamon, Bakemon, Frigimon, Monzaemon, Gotsumon, Icemon, Pumpkinmon, Digitamamon.

## Bosses (bad) — 6

Dens across POIs (plus Hollow Warden remains the chapter pine boss).

| ID | Display | Den |
|----|---------|-----|
| `boss_andromon` | Andromon | Market Mile |
| `boss_devimon` | Devimon | Pine Hollow |
| `boss_orgemon` | Orgemon | Fatal Fields |
| `boss_snimon` | Snimon | Risky Reels |
| `boss_meramon` | Meramon | Grease Grove |
| `boss_whamon` | Whamon | Mirror Mere |

## Systems

| Piece | Role |
|-------|------|
| `CreatureLookalikeCatalog` | IDs, roles, palettes |
| `CreatureLookalikeKit` | Per-creature builds |
| `CompanionVisual` | Partner lookalike profiles |
| `EcosystemCreature` | Enemy lookalike visuals |
| `RegionBossActor` | Boss lookalike visuals |
| `LivingWorldController` | Spawns lookalike bosses |

## Smoke

```bash
godot --headless --path digital-frontier --import
godot --headless --path digital-frontier --scene res://scenes/devtools/creature_lookalike_smoke.tscn
```

Expect `CREATURE_LOOKALIKE_SMOKE_OK`.
