# Creature Adventure Partner

## What already exists

| Piece | Status |
|-------|--------|
| Same `CreatureInstance` Home ↔ Adventure | Yes |
| Adventure XP (enter / chests / discover / quests) | Yes |
| Home `CompanionActor` + `CompanionVisual` | Habitat only |
| Y / `creature_action` | Toast stub in adventure |
| Field Unit HUD | No creature chrome |

## Integration

```
CreatureData (+ ability_ids)
    ↓
CreatureManager (XP, bond, readiness)
    ↓
EventBus (discover / chest / notice)
    ↓
AdventureCompanionActor + CompanionVisual   ← NEW world partner
    ↓
Field Unit companion strip (handheld)
```

Needs/XP stay in the manager. The adventure actor only **reads** state and **requests** bond/XP through manager APIs.

## Button map (handheld)

| Input | Adventure partner |
|-------|-------------------|
| Auto | Creature follows |
| **Y** | Ask companion (pet / confirm notice) |
| **A** | World interact (unchanged) |
| Notice toast | Y confirms special find |

## Build steps

1. Ability data framework + Sparkbit `sense_secrets`  
2. `AdventureCompanionActor` follow / idle / personality  
3. Sense nearby secrets → notice → Y confirm  
4. Exploration bond + memory rewards  
5. Field Unit companion status strip  
6. Wire `game_world` spawn  

## Design goal

*"I want to see what my creature finds."*
