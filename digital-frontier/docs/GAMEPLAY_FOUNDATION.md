# Gameplay Foundation

## Current architecture

```
Boot → Main shell
         ├─ Autoload managers (EventBus, Inventory, Quest, World, Save, Creature…)
         ├─ Home habitat (companion care)
         └─ Adventure world (player + interactables + POIs)
```

| Layer | Role |
|-------|------|
| **Data (`.tres`)** | Items, quests, loot tables, creatures, regions |
| **ResourceRegistry** | ID lookup — gameplay never hardcodes paths |
| **Managers** | Runtime state + save slices |
| **EventBus** | Decoupled signals (loot, discovery, quests, save) |
| **Scenes / Interactables** | Placeholder visuals; real gameplay hooks |

**Already solid:** player move/camera/interact, buildings, companion, SaveManager file I/O, Item/Quest schemas.

**Were stubs:** loot tables, chest rarity, discovery flags, quest advance/complete, save triggers, inventory remove/stack.

## Build order (why this sequence)

1. **Currency + inventory** — every reward path needs grant/remove/notify  
2. **Loot tables + chest tiers** — exploration rewards become real  
3. **Exploration discovery** — world flags + POI rewards feed quests/save  
4. **Quest runtime** — listens to inventory/discovery/NPC events  
5. **Save foundation** — persist inventory, creatures, discoveries, quests, opened chests  

Player movement/camera/interaction were left intact (already playable).

## Playable loop after this pass

Home → Adventure → discover locations / open chests (bits + items) → talk to Park Guide → quest progress → return Home → progress autosaved.
