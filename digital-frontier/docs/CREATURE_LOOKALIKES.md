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

Partners stay custom companion kits (never franchise GLBs). Enemies and bosses use the same lookalike language when their biome is live.

## Companions (good) — 6

Grassland partner select (chapter 1):

| ID | Display | Style |
|----|---------|-------|
| `companion_tentomon` | Tentomon | Ladybug shell + wings |
| `companion_agumon` | Agumon | Orange hatchling dino |
| `companion_gatomon` | Gatomon | White cat + holy ring |
| `companion_gabumon` | Gabumon | Blue pelt-pup |
| `companion_biyomon` | Biyomon | Rose songbird |
| `companion_gomamon` | Gomamon | Surf seal |

## Enemies (bad) — 15

**Grassland live (beginner only):** Koromon, Chuumon, Gazimon.

**Later biomes (database, `spawn_live: false` until those regions ship):** Junkmon, Impmon, Hagurumon, Numemon, Datamon, Bakemon, Frigimon, Monzaemon, Gotsumon, Icemon, Pumpkinmon, Digitamamon.

See `docs/CREATURE_DISTRIBUTION.md`.

## Bosses (bad) — 6

Assigned by biome — **not** spawned in Grassland. Chapter 1 major boss remains **Hollow Warden**; mini-boss is **Glitch Alpha**.

| ID | Display | Biome |
|----|---------|-------|
| `boss_snimon` | Snimon | Forest |
| `boss_orgemon` | Orgemon | Mountains |
| `boss_whamon` | Whamon | Ocean |
| `boss_meramon` | Meramon | Volcanic Region |
| `boss_andromon` | Andromon | Digital City / Ancient Ruins |
| `boss_devimon` | Devimon | Dark Lands |

## Systems

| Piece | Role |
|-------|------|
| `CreatureLookalikeCatalog` | IDs, roles, palettes |
| `CreatureLookalikeKit` | Per-creature builds |
| `BiomeDistributionCatalog` | Biome / chapter assignment |
| `CompanionVisual` | Partner lookalike profiles |
| `EcosystemCreature` | Enemy lookalike visuals |
| `RegionBossActor` | Boss lookalike visuals when biome live |
| `LivingWorldController` | Spawns Grassland Hollow Warden only |

## Smoke

```bash
godot --headless --path digital-frontier --import
godot --headless --path digital-frontier --scene res://scenes/devtools/creature_lookalike_smoke.tscn
godot --headless --path digital-frontier --scene res://scenes/devtools/biome_ecosystem_smoke.tscn
```

Expect `CREATURE_LOOKALIKE_SMOKE_OK` and `BIOME_ECOSYSTEM_SMOKE_OK`.
