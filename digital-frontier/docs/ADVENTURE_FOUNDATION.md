# Adventure Foundation

## What already existed

| System | Status before this pass |
|--------|-------------------------|
| Home ↔ Adventure transitions | Working |
| Bits + inventory grant/spend | Working (balance only) |
| Chest tiers + loot tables | Working (no anim / SFX / respawn) |
| Discoverables as scene nodes | Working (not data-driven) |
| Quest runtime + First Steps | Working (one quest) |
| Save aggregation | Working (no player position) |
| Home handheld HUD | Working |
| Adventure HUD | Bits + quest labels only |
| Collection menu | Toast stub |
| Creature adventure XP | +2 on world enter only |

## Goals

Support the full core loop with clean, expandable systems — placeholders OK:

Home → Adventure → explore → discover → secrets → rewards → upgrade creature → return Home → prepare again.

## Architecture

```
Data (.tres)
  DiscoverableData · AchievementData · QuestData · LootTableData · ItemData
        ↓
ResourceRegistry
        ↓
Managers (Inventory · World · Collection · Quest · Creature · Save)
        ↓
EventBus
        ↓
Interactables + AdventureDeviceHUD + Home HUD
```

## Implemented this pass

1. **DiscoverableData** (`data/discoverables/`) — name, description, rewards, quest links, XP, map hints  
2. **Currency ledger** — earned / spent totals + transaction history (shop-ready categories)  
3. **Chests** — lid tween framework, procedural SFX, `respawn_hours`, creature XP on open  
4. **CollectionManager** — locations, creatures, items, rare finds, achievements  
5. **Quests** — Park Explorer, Secret Seeker, Spark Snack (+ First Steps)  
6. **Save** — player checkpoint, collection slice, schema v2  
7. **Adventure device HUD** — Pack / Map / Quests / Log / Bits  
8. **Creature XP** from discoveries, chests, and quest completion  

## How to add content later

| Want | Do |
|------|----|
| New landmark | Add `data/discoverables/*.tres` + place `DiscoverableInteractable` with matching `location_id` |
| New quest | Add `data/quests/*.tres` (stages use discover/chest/collect/talk/chest_rarity) |
| New achievement | Add `data/achievements/*.tres` |
| New chest loot | Edit / add `data/tables/loot/*.tres` |
| Shop spend | Call `InventoryManager.spend_bits(amount, reason, "shop")` |

## Play checklist

1. Home → Collection (journal) → Adventure  
2. Field Unit: Tab pack, M map, J quests, C log, B bits  
3. Discover welcome sign → open chest → talk to Park Guide  
4. Follow-up quests unlock; open rare/legendary for Secret Seeker  
5. H home — position + Bits + discoveries autosaved; Adventure again resumes checkpoint  
