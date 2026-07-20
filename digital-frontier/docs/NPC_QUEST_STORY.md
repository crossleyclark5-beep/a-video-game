# NPC, Quest & Story Progression

Living people, memorable quests, and a Frontier mystery that unfolds one beat at a time.

## Feel

The player should feel: *“I’m on an adventure, and my choices shape this world.”*

Handheld rules: short dialogue, A/B (+ D-pad choices), role badges instead of heavy portraits, no wall-of-text menus.

## NPC System

| Piece | Role |
|---|---|
| `NPCManager` | Disposition, memories, talk counts, day-phase schedules |
| `NpcMemory` | Capped per-NPC memory entries |
| `NpcCatalog` | Roles: Villager · Merchant · Researcher · Explorer · Story |
| `NpcSchedule` | Morning/afternoon/evening/night waypoints |
| `WorldNpcActor` | Roams on schedule, talk interactable, quest offers |
| `DeviceDialogue` | Bottom sheet + role badge + optional A/B choices |

### Memory examples

NPCs remember when you help them, clear a boss, finish their quest, or discover Pine Hollow — and their lines change.

## Quest Framework

`QuestData` types: **Main · Side · Daily · Hidden · Exploration · Creature**

| Quest | Kind | Hook |
|---|---|---|
| Spine (first_steps → hollow_challenge) | Main | Chapter One |
| Injured Signal | Creature | Help a wounded creature-signal |
| Lost Trail | Explore | Find the lost scout |
| Strange Static | Explore | Investigate + clear hostiles |
| Village Shield | Side | Protect Pleasant Park |

Objectives still flow through `QuestManager.notify_objective`.

## Quest UI

Field Unit Quests sheet (`DFFormat.quest_sheet`):

- Active sorted by Story / Exploration / Creature / Side
- Objective + short blurb + reward summary
- Named completed list (capped)

## Story Progression

`StoryDirector` + `StoryCatalog` play cryptic **story beats** (2–3 lines):

- Frontier Whisper → Alpha Shadow → Warden Dream → Chapter Echo
- Side beats for Injured Signal / Lost Scout

Beats set world flags, stamp companion + NPC memory, never dump the full plot.

`ChapterDirector` still owns Grassland spine title cards and cast pinning.

## Smoke

`res://scenes/devtools/story_quest_smoke.tscn`
