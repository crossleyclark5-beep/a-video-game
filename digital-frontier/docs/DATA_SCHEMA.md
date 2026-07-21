# Data Schema — Digital Frontier

All content resources extend **`IdentifiableResource`** and require:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | `StringName` | ✓ | Unique lookup key |
| `display_name` | `String` | ✓ | Localizable display name |
| `description` | `String` | | Flavor / UI description |

---

## RegionData

**Path:** `data/regions/*.tres`

| Field | Type | Description |
|-------|------|-------------|
| `hex_width` | `int` | Grid width in hexes |
| `hex_height` | `int` | Grid height in hexes |
| `hex_size` | `float` | World units per hex |
| `hex_orientation` | `StringName` | `"pointy"` or `"flat"` |
| `scene_path` | `String` | Region scene to instantiate |
| `music_track_id` | `StringName` | Audio lookup ID |
| `neighbor_regions` | `PackedStringArray` | Adjacent region IDs |
| `tile_overrides` | `Dictionary` | Hex coord → tile override |
| `creature_spawn_table_id` | `StringName` | Spawn table in `data/tables/` |

---

## HexTileData

**Path:** `data/tables/tiles/` (recommended)

| Field | Type | Description |
|-------|------|-------------|
| `category` | `TileCategory` enum | Terrain classification |
| `is_walkable` | `bool` | Pathfinding passability |
| `movement_cost` | `float` | Pathfinding weight |
| `elevation` | `float` | Height offset for 2.5D |
| `mesh_scene_path` | `String` | 3D tile mesh scene |
| `building_id` | `StringName` | Optional linked building |

---

## BuildingData

**Path:** `data/buildings/*.tres`

| Field | Type | Description |
|-------|------|-------------|
| `building_type` | `BuildingType` enum | RESIDENTIAL, SHOP, QUEST_HUB, etc. |
| `interior_scene_path` | `String` | Additive interior scene |
| `exterior_scene_path` | `String` | Hex-placed exterior |
| `region_id` | `StringName` | Parent region |
| `hex_coords` | `Vector3i` | Cube hex position |
| `required_quest_id` | `StringName` | Gating quest (empty = open) |
| `npc_ids` | `PackedStringArray` | NPCs inside |

---

## CreatureData

**Path:** `data/creatures/*.tres`

| Field | Type | Description |
|-------|------|-------------|
| `rarity` | `Rarity` enum | COMMON → LEGENDARY |
| `base_stats` | `Dictionary` | stat_name → int |
| `growth_rates` | `Dictionary` | stat_name → float |
| `ability_ids` | `PackedStringArray` | Ability data IDs |
| `scene_path` | `String` | Visual scene |
| `capture_rate` | `float` | 0.0 – 1.0 |
| `habitat_region_ids` | `PackedStringArray` | Spawn regions |

**Runtime instance** (in CreatureManager, not in this file):

```gdscript
{
  "instance_id": "pixel_fox_001",
  "creature_id": "pixel_fox",
  "nickname": "",
  "level": 5,
  "current_hp": 40,
}
```

---

## ItemData

**Path:** `data/items/*.tres`

| Field | Type | Description |
|-------|------|-------------|
| `item_type` | `ItemType` enum | CONSUMABLE, MATERIAL, KEY_ITEM, etc. |
| `max_stack` | `int` | Stack limit |
| `sell_value` / `buy_value` | `int` | Economy |
| `icon_path` | `String` | UI icon |
| `use_effect_id` | `StringName` | Effect system hook |

---

## QuestData

**Path:** `data/quests/*.tres`

| Field | Type | Description |
|-------|------|-------------|
| `quest_type` | `QuestType` enum | MAIN, SIDE, DAILY, HIDDEN |
| `prerequisite_quest_ids` | `PackedStringArray` | Required completed quests |
| `stages` | `Array[Dictionary]` | Ordered objectives |
| `reward_item_ids` | `PackedStringArray` | Parallel to reward_quantities |
| `start_npc_id` / `turn_in_npc_id` | `StringName` | Quest giver |

### Stage dictionary schema

```gdscript
{
  "type": "collect",      # collect | talk | defeat | reach | flag
  "target_id": "hex_shard",
  "count": 3,
  "optional_description": "",
}
```

---

## NPCData

**Path:** `data/npcs/*.tres`

| Field | Type | Description |
|-------|------|-------------|
| `role` | `NPCRole` enum | VILLAGER, MERCHANT, QUEST_GIVER, etc. |
| `dialogue_tree_id` | `StringName` | DialogueData ID |
| `schedule_id` | `StringName` | Time/location schedule table |
| `shop_inventory_id` | `StringName` | Shop stock table |
| `region_id` | `StringName` | Default region |
| `default_hex_coords` | `Vector3i` | Default position |

---

## VehicleData

**Path:** `data/vehicles/*.tres`

| Field | Type | Description |
|-------|------|-------------|
| `vehicle_class` | `VehicleClass` enum | GROUND, WATER, AIR, HYBRID |
| `max_speed` | `float` | Top speed |
| `allowed_terrain` | `PackedInt32Array` | HexTileData.TileCategory values |
| `unlock_quest_id` | `StringName` | Unlock gate |

---

## BossData

**Path:** `data/bosses/*.tres`

| Field | Type | Description |
|-------|------|-------------|
| `creature_id` | `StringName` | Base creature template |
| `arena_scene_path` | `String` | Combat arena scene |
| `phase_count` | `int` | Number of phases |
| `phase_thresholds` | `PackedFloat32Array` | HP % triggers |
| `region_id` | `StringName` | World location |

---

## DialogueData

**Path:** `data/localization/dialogue/` or co-located with NPCs

| Field | Type | Description |
|-------|------|-------------|
| `nodes` | `Dictionary` | node_id → node data |
| `entry_node_id` | `StringName` | Starting node |

### Node schema

```gdscript
{
  "speaker": "Elder Mira",
  "text": "Welcome to the frontier, traveler.",
  "choices": [
    { "label": "Tell me more.", "next": "explain", "condition": "" },
    { "label": "Goodbye.", "next": "", "condition": "" }
  ]
}
```

---

## LootTableData

**Path:** `data/tables/loot/*.tres`

| Field | Type | Description |
|-------|------|-------------|
| `entries` | `Array[Dictionary]` | Weighted items |
| `rolls` | `int` | Number of random picks |

### Entry schema

```gdscript
{ "item_id": "hex_shard", "weight": 10.0, "min_qty": 1, "max_qty": 3 }
```

---

## GameState (Save Format)

**Path:** `user://saves/profiles/{profile_id}/slot_N.res` (runtime)  
**Index:** `user://saves/profiles.json` — see `docs/MULTI_PROFILE.md`

| Field | Type | Owner |
|-------|------|-------|
| `schema_version` | `int` | SaveManager (currently 3) |
| `profile_id` | `String` | SaveManager |
| `profile_display_name` | `String` | SaveManager |
| `profile_avatar_id` | `StringName` | SaveManager |
| `playtime_seconds` | `float` | SaveManager |
| `current_region_id` | `StringName` | WorldManager |
| `current_hex_coords` | `Vector3i` | WorldManager |
| `inventory_data` | `Dictionary` | InventoryManager |
| `quest_data` | `Dictionary` | QuestManager |
| `creature_data` | `Dictionary` | CreatureManager |
| `npc_data` | `Dictionary` | NPCManager |
| `vehicle_data` | `Dictionary` | VehicleManager |
| `world_flags` | `Dictionary` | WorldManager |
| `collection_data` | `Dictionary` | CollectionManager |
| `shop_data` | `Dictionary` | ShopManager |
| `settings_data` | `Dictionary` | GameConfig (per-profile volumes) |

---

## Sample Content (included)

| ID | File | Type |
|----|------|------|
| `starter_plains` | `data/regions/starter_plains.tres` | Region |
| `pixel_fox` | `data/creatures/pixel_fox.tres` | Creature |
| `hex_shard` | `data/items/hex_shard.tres` | Item |
| `first_steps` | `data/quests/first_steps.tres` | Quest |
| `village_hall` | `data/buildings/village_hall.tres` | Building |
| `elder_mira` | `data/npcs/elder_mira.tres` | NPC |

---

## Adding New Resource Types

1. Create script in `resources/definitions/my_type_data.gd` extending `IdentifiableResource`
2. Add `@export` fields with doc comments
3. Add scan path in `ResourceRegistry` if new category
4. Add getter: `get_my_type(id: StringName) -> MyTypeData`
5. Document schema in this file
6. Add sample `.tres` in `data/`
