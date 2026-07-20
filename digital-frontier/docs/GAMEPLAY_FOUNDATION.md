# Gameplay Foundation

## Current architecture

```
Boot → Main shell
         ├─ Autoload managers (EventBus, Inventory, Quest, World, Collection, Save, Creature…)
         ├─ Home habitat (companion care + collection journal)
         └─ Adventure world (player + interactables + device HUD)
```

| Layer | Role |
|-------|------|
| **Data (`.tres`)** | Items, quests, loot, discoverables, achievements, creatures, regions |
| **ResourceRegistry** | ID lookup — gameplay never hardcodes paths |
| **Managers** | Runtime state + save slices |
| **EventBus** | Decoupled signals (loot, discovery, quests, save) |
| **Scenes / Interactables** | Placeholder visuals; real gameplay hooks |

See **`ADVENTURE_FOUNDATION.md`** for the full exploration / collection / ledger / device-HUD pass.

## Playable loop

Home → Adventure → discover locations / open chests (bits + items + creature XP) → quests → Collection log → return Home → progress autosaved (including world position).
