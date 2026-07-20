# Technical Architecture — Digital Frontier (Godot 4.7.1)

**Companion to:** [GAME_DESIGN_DOCUMENT.md](GAME_DESIGN_DOCUMENT.md)  
**Status:** Proposed mapping from design → engine systems  
**Related engineering docs:** [../ARCHITECTURE.md](../ARCHITECTURE.md), [../SCENE_ARCHITECTURE.md](../SCENE_ARCHITECTURE.md), [../DATA_SCHEMA.md](../DATA_SCHEMA.md)

This document explains **how** the design should live in Godot. It does not implement features.

---

## 1. Engine & Platform Assumptions

| Item | Choice | Why |
|------|--------|-----|
| Engine | Godot **4.7.1** (4.3+ compatible project settings today) | 2.5D-friendly, lightweight exports, strong 3D + UI |
| World representation | `Node3D` scenes + orthographic/angled `Camera3D` | True 2.5D with free movement |
| UI | `CanvasLayer` stack in persistent `main.tscn` | Survives region swaps |
| Content | `.tres` resources under `data/` | Years of expansion without code forks |
| Code language | GDScript (typed) | Speed of iteration; C# optional later for hotspots |
| Target runtime | Custom handheld (+ PC dev) | Feature-detect sensors; stub when missing |

---

## 2. Architectural Principles (design-aligned)

1. **Home and Adventure are modes**, not the same UI root  
2. **Companion state is authoritative** in a manager + save snapshot  
3. **World content is data-driven** (regions, buildings, creatures, quests)  
4. **Systems talk through EventBus** to avoid spaghetti  
5. **Performance by construction**: chunked hexes, pooled SFX, simple materials  
6. **Device services behind an interface** so PC and handheld share game code  

---

## 3. High-Level Runtime Diagram

```
┌──────────────────────────────────────────────────────────┐
│                     Autoload Managers                     │
│ EventBus · GameConfig · ResourceRegistry · SceneManager   │
│ SaveManager · AudioManager · InputManager · UIManager     │
│ WorldManager · CreatureManager · InventoryManager · …     │
│ DeviceService (NEW proposal)                              │
└───────────────────────────┬──────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────┐
│ main.tscn (persistent shell)                              │
│  ├─ SceneContainer  → Home OR Adventure world             │
│  ├─ TransitionOverlay                                     │
│  └─ UI Layers (HUD / Menu / Modal / Overlay)              │
└──────────────────────────────────────────────────────────┘
```

### Mode scenes

| Mode | Scene (proposed) | Owns |
|------|------------------|------|
| Boot | `scenes/bootstrap/boot.tscn` | Autoload sanity → main |
| Home | `scenes/ui/menus/home_companion.tscn` (or `scenes/home/`) | Care UI + companion presentation |
| Adventure | `scenes/world/game_world.tscn` | Hex region, entities, interiors |
| Boss/Dungeon | Additive or swap under SceneManager | Set-piece spaces |

---

## 4. Mapping Design Systems → Tech Systems

| Design system | Primary owner | Data | Notes |
|---------------|---------------|------|-------|
| Living companion | `CreatureManager` | `CreatureData` + runtime instance | Mood/hunger runtime fields |
| Moods | `CreatureManager` + Home UI | Enum/state machine | Emits events for RGB/UI |
| Hunger | `CreatureManager` | Tunables in GameConfig/data | Time-based drain |
| Evolution | `CreatureManager` | Evolution tables in data | Celebration via EventBus |
| Exploration / hex world | `WorldManager` + hex scripts | `RegionData`, `HexTileData` | Chunk streaming later |
| Building interiors | World + building controller | `BuildingData` | Roof fade = mesh/material alpha or hide roof node |
| Combat | Future `CombatManager` or arena scene | Enemy data, `BossData` | Keep v1 local to encounter scene if possible |
| Inventory / chests | `InventoryManager` | `ItemData`, loot tables | Chests are interactables |
| Currency / shop | Inventory + shop UI | Item/currency ids | Shop inventory as data |
| Skins | CreatureManager / cosmetics table | Skin resources | Purely cosmetic flags |
| Vehicles | `VehicleManager` | `VehicleData` | Input context switch |
| Quests | `QuestManager` | `QuestData` | Stage dictionaries |
| Boss fights | Combat + `BossData` | Arena scenes | SceneManager transition |
| Region unlocking | `WorldManager` flags | Region links in data | Save-backed flags |
| Save/load | `SaveManager` + `GameState` | `user://saves/` | Companion fields mandatory |
| Device features | **`DeviceService`** (proposed) | Capability flags | Gyro/NFC/haptics/RGB |

Existing foundation already stubs most managers — see engineering `ARCHITECTURE.md`. New work is primarily **behavior + content**, plus a clean `DeviceService`.

---

## 5. Proposed New / Extended Modules

### 5.1 DeviceService (autoload)

```
DeviceService
├── has_gyro() / get_gyro()
├── has_nfc() / poll_nfc()
├── play_haptic(pattern_id)
├── set_rgb(color, mode)
└── fallback behavior when hardware missing
```

**Why:** Keeps hardware out of gameplay scripts. Home mood lights call `DeviceService`, not platform code.

### 5.2 CompanionRuntime (resource or inner state)

Separate **template** (`CreatureData`) from **instance**:

```
instance_id, creature_id, nickname,
mood, hunger, personality_seed,
xp/growth, evolution_stage, skin_id,
care_history_flags
```

Stored via `CreatureManager.export_state()` → `GameState.creature_data`.

### 5.3 BuildingInteriorController (scene component)

Handles:
- Enter trigger
- Camera zoom tween
- Roof fade
- Interior activation
- Exit restore

Reusable across houses/shops/dungeons.

### 5.4 HexRegionStreamer (phase 6+, stub interfaces in phase 1)

Even with one region in v0.1, keep APIs assuming multiple hexes later (`region_load_requested` already on EventBus).

---

## 6. Scene Architecture for Design Pillars

### Home (Pillar 1)

```
HomeCompanion
├── CreatureStage (Node3D or animated presentation)
├── CarePromptUI
├── MoodMeter / HungerMeter
└── AdventureButton
```

### Adventure (Pillars 2–4)

```
GameWorld
├── HexGridLayer
├── BuildingLayer
├── EntityLayer (Player, Enemy, NPC, Vehicle)
├── EffectsLayer
├── InteriorContainer      ← additive interiors
└── CameraRig
```

### UI layers (always)

- HUD: minimal in adventure (care warnings, currency)
- Modal: inventory, shop, dialogue
- Overlay: save icon, device debug

---

## 7. Data-Driven Content Pipeline

```
Designer creates data/creatures/foo.tres
        ↓
ResourceRegistry indexes id → resource at boot
        ↓
Managers / spawners request by id
        ↓
Scenes receive data at instantiate time
```

**Rule:** No hardcoded creature stats, quest text IDs, or region sizes in gameplay scripts.

Prototype content pack (design names TBD on approval):

- 1 `RegionData` (Grasslands)
- 1 town building set
- 1 companion `CreatureData`
- 1 enemy definition
- 1 `VehicleData`
- 1 dungeon `BuildingData` / region sub-scene
- 1 `BossData`
- Starter items + food for hunger

---

## 8. Performance Strategy (handheld-first)

| Concern | Approach |
|---------|----------|
| Draw calls | Low-poly + atlases; share materials per biome |
| Region size | Dense small hex > huge empty hex |
| Interiors | Load additive; unload on exit |
| AI/enemies | Few active; sleep outside radius |
| Shadows/VFX | Soft budget; quality tiers in GameConfig |
| Save I/O | Snapshot dictionaries; avoid node serialization |
| Sensors | Event-driven or low-rate polling |

Target: stable frame pacing on device-class hardware; exact FPS budget set during Phase 1 profiling.

---

## 9. Input & Control Model (recommendation)

| Context | Input |
|---------|-------|
| Home | Face buttons for care; simple navigation |
| Adventure on foot | Move + interact + menu |
| Vehicle | Move + optional gyro assist |
| UI modal | Navigate + confirm/cancel |
| Combat | Context-specific; keep few actions |

`InputManager` context stack already matches this design.

---

## 10. Combat Architecture Options (decide in Phase 4 brief)

| Option | Pros | Cons |
|--------|------|------|
| **A. Lightweight real-time** | Fits free movement exploration | Balancing + animation cost |
| **B. Short arena bouts** | Readable telegraphs; boss-friendly | Transition friction |
| **C. Hybrid** | Field bump → short resolve | Two systems to maintain |

**Recommendation for v0.1:** Option A with very simple enemy, *or* B if boss readability is prioritized. **Do not implement until Phase 4 approval.**

---

## 11. Save Model (design-critical)

Must persist at minimum:

- Companion runtime (mood, hunger, growth, skin)
- Inventory + currency
- Quest stages
- Region unlock flags + player position
- World flags (chests opened, boss defeated)
- Settings

`GameState` resource + per-manager `export_state()` / `import_state()` is the intended pattern (already stubbed).

**Autosave triggers (proposed):** leaving adventure → home; after boss clear; after evolution; on clean quit.

---

## 12. Folder Alignment

Existing scaffold is sufficient. Design adds documentation under `docs/design/`. Future code likely extends:

```
scripts/autoload/device_service.gd     (proposed)
scripts/systems/companion/             (mood FSM, care actions)
scripts/systems/buildings/             (interior controller)
scripts/systems/combat/                (when approved)
scenes/home/                           (home mode)
data/                                  (prototype content pack)
```

No need to rebuild the project structure for Phase 1.

---

## 13. Testing Strategy (lightweight)

| Layer | Approach |
|-------|----------|
| Data | Validate IDs with `IdValidator`; missing refs fail loudly |
| Managers | Unit tests for hunger drain / inventory ops (GUT later) |
| Device | Debug panel simulating NFC tag IDs / gyro |
| Playtests | Experience questionnaire from PLAYER_EXPERIENCE.md |

---

## 14. What Exists vs What Is Proposed

| Already scaffolded | Proposed when implementing |
|--------------------|----------------------------|
| Autoload managers | Real logic inside stubs |
| Resource schemas | Fill `.tres` content pack |
| `game_world.tscn` shell | Player, town blockout, hex meshes |
| EventBus signals | Wire UI/gameplay emitters |
| SaveManager skeleton | Companion fields + autosave points |
| — | `DeviceService` |
| — | Home companion scene |
| — | BuildingInteriorController |

---

## 15. Approval Note

This architecture is a **blueprint**. It should be revised if combat model, companion-in-adventure presence, or device constraints change.

**No code for gameplay systems until Phase 0 design approval and a Phase feature brief are signed off.**
