# Character Library

## Art direction

Digital Frontier keeps a deliberate contrast:

| Layer | Look |
|-------|------|
| World | Pixel-inspired, nostalgic late-90s / early-2000s diorama |
| Characters | Higher detail, expressive, memorable silhouettes |

## License gate

| Allowed | Rejected |
|---------|----------|
| CC0 Kenney blocky / space characters | Fortnite skin rips / ripped game models |
| Sketchfab CC-BY with token + attribution | Digimon / Pokémon / franchise creature GLBs |
| Original stylized “inspired by” aesthetics | Photoreal / high-poly AAA characters |

**Partners (Emberling, Sparkbit, Tidepup) stay custom `CompanionVisual` kits.** Digimon-style influence is silhouette language only — never IP meshes.

**Expanded look-alike roster:** see `docs/CREATURE_LOOKALIKES.md` — 6 companion / 15 enemy / 6 boss Digimon-inspired DF kits (`CreatureLookalikeKit`).

## Curated roster (`assets/models/external/characters/`)

### Humans (Kenney Blocky Characters — CC0)

| ID | Use |
|----|-----|
| `hero_a`–`hero_alt` | Player character options |
| `npc_villager` / `merchant` / `explorer` / `researcher` / `story` / `guard` | Role-mapped NPCs |

### Creatures (Kenney Space Kit — CC0)

| ID | Use |
|----|-----|
| `digital_mite` | Wildlife / enemy accent (digital monster vibe) |
| `field_ranger` / `_b` | Special NPC / ranger prototypes |

## Runtime

| Type | Role |
|------|------|
| `CharacterCatalog` | Paths + role mapping |
| `CharacterKit` | Load GLB → toon + nearest (keeps albedo textures) |
| `CharacterLibraryVisual` | Drop-in bob locomotion API |

Wired into:

- `CharacterVisual` — optional library hero (`use_character_library`)
- `WorldNpcActor` — role → library mesh when available
- `EcosystemCreature` mites — `digital_mite` accent

## Sketchfab queue (token required)

Search for **original** stylized adventurers / cute digital monsters with download + CC-BY. Do not import Fortnite/Digimon named rips.

**Item Shop roster:** requested Fortnite Sketchfab characters are **not** imported (Epic IP). See `CHARACTER_SHOP_ROSTER.md` — Digital Frontier ships original retro look-alikes (`CharacterLookalikeKit`) with Jonesy starter + buy/earn unlocks.

Suggested search terms (style, not IP):

- “stylized adventurer low poly downloadable”
- “cute digital monster low poly”
- “cartoon battle character low poly”

Use `tools/fetch_sketchfab.py` when `SKETCHFAB_API_TOKEN` is set.

## Boss concepts

Prototype direction: scaled `digital_mite` / custom kit variants — not franchise bosses. Hollow Warden remains procedural.

## Smoke

```bash
godot --headless --path digital-frontier --import
godot --headless --path digital-frontier --scene res://scenes/devtools/character_library_smoke.tscn
```
