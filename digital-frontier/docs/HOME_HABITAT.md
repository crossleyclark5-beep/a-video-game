# Home Habitat System

The Home screen is the emotional center of Digital Frontier — a living creature habitat, not a menu.

## Scene entry

| Path | Role |
|------|------|
| `scenes/home/home_habitat.tscn` | Active home (via `GameConstants.SCENE_HOME`) |
| `scenes/home/home_companion.tscn` | Legacy flat UI (kept for reference) |

Boot / Main still load `SCENE_HOME`, which now points at the 3D habitat.

## Modules

| Module | Path | Purpose |
|--------|------|---------|
| HabitatEnvironment | `scripts/home/habitat_environment.gd` | Builds room, lighting, stations markers, decor hooks |
| HabitatTimeOfDay | `scripts/home/habitat_time_of_day.gd` | Night/day/dawn/dusk + weather id foundation |
| CompanionVisual | `scripts/home/companion_visual.gd` | Procedural mesh + idle/walk/sleep/eat/happy/sad/stretch |
| CompanionActor | `scripts/home/companion_actor.gd` | Needs-driven wander / care AI |
| HomeStation | `scripts/home/home_station.gd` | Clickable bowl / bed / toy / train |
| HomeHud | `scenes/home/ui/home_hud.tscn` | Handheld-device status + care + nav |

## Needs (CreatureManager)

| Need | Meaning | Care influence |
|------|---------|----------------|
| Hunger | Fullness (high = fed) | Feed |
| Happiness | Mood meter | Play / Feed / Train |
| Energy | Tiredness | Rest / spent by Play+Train |
| Friendship | Bond | Play / Train / passive when well-cared |
| Health | Soft neglect meter | Rest / Feed; drops if multiple needs low |

Behavior bias (`get_behavior_bias`) drives autonomous walk-to-bed / bowl / toy.

## Player care loop

1. Open device → nighttime habitat + wake stretch.
2. Care via HUD (Feed / Rest / Play / Train) or click a station.
3. Companion walks to the station and plays the matching animation.
4. Adventure when ready (always available; soft gate messaging).

## Extensibility hooks

- **Multiple creatures** — swap `CompanionVisual` skin / species id from CreatureManager.
- **Different homes** — new `HabitatEnvironment` layout builders or packed room scenes.
- **Decorations** — `decor_hooks` markers; place prop scenes at runtime.
- **Skins / seasonal** — override materials / `HabitatTimeOfDay` palettes.
- **Shop / NFC** — Bits currency in InventoryManager; station ids ready for unlock gates.

## Controls (home)

| Input | Action |
|-------|--------|
| Enter | Adventure |
| Click station | Care at that object |
| HUD buttons | Care / Pack / Shop / Collection / Adventure |
