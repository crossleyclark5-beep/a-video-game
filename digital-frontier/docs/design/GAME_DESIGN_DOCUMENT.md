# Digital Frontier — Game Design Document

**Version:** 0.1.0 (Foundation)  
**Status:** Design blueprint — awaiting approval before implementation  
**Engine:** Godot 4.7.1  
**Platform target:** Dedicated handheld device (+ PC for development)  
**Document owner:** Creative Direction / Lead Design  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [High Concept](#2-high-concept)
3. [Design Philosophy](#3-design-philosophy)
4. [Core Gameplay Pillars](#4-core-gameplay-pillars)
5. [Player Experience Goals](#5-player-experience-goals)
6. [Target Audience & Tone](#6-target-audience--tone)
7. [Visual Style](#7-visual-style)
8. [World Design](#8-world-design)
9. [Core Gameplay Loop](#9-core-gameplay-loop)
10. [Feature Systems](#10-feature-systems)
11. [Device Integration](#11-device-integration)
12. [Prototype Scope (v0.1)](#12-prototype-scope-v01)
13. [Content Expansion Philosophy](#13-content-expansion-philosophy)
14. [Related Documents](#14-related-documents)

---

## 1. Executive Summary

**Digital Frontier** is a creature adventure game built for a dedicated handheld device. The player cares for a living digital companion, then ventures into a connected hex-based continent to explore, collect, quest, and grow stronger for boss encounters.

The fantasy is: *your creature lives with you* — moods, hunger, personality, and growth — then *you adventure together* through a nostalgic, colorful 2.5D world.

The product is designed to feel like an early-2000s creature handheld reborn with modern polish: physical buttons, sensors, NFC, haptics, and RGB lighting that make the companion feel real.

**This document is the creative and design source of truth.** Implementation must not begin on a feature until that feature is approved against this GDD.

---

## 2. High Concept

| Field | Statement |
|-------|-----------|
| **Genre** | Creature companion + exploration adventure |
| **Perspective** | 2.5D top-down (3D world, isometric/top-down camera) |
| **Core fantasy** | Bond with a living digital creature and explore a hex continent together |
| **Platform** | Dedicated handheld (primary); PC for tools & development |
| **Session length** | Short care sessions (1–5 min) + medium adventures (10–30 min) |
| **Tone** | Warm, nostalgic, curious, lightly mysterious — never grimdark |
| **Comparable feeling** | Digimon / Tamagotchi bond + Pokémon exploration energy + Bloons Monkey City presentation language |

**One-sentence pitch:**  
*Raise a living digital companion on a handheld, then explore a colorful hex world of secrets, monsters, and bosses together.*

**Elevator pitch (30 seconds):**  
Digital Frontier puts a living creature in your pocket. Feed it, soothe its moods, and watch it grow — then dive into Adventure Mode across a connected continent of grasslands, cities, dungeons, and bosses. Open chests, unlock regions, collect monsters, and use the device’s gyro, NFC, and haptics so the world and companion feel physical. Built in Godot for a custom handheld, it aims for early-2000s nostalgia with modern clarity and commercial polish.

---

## 3. Design Philosophy

### The Fun Filter

**Every feature must answer yes to at least one:**

1. Does this make **exploration** more exciting?
2. Does this make **collecting** more exciting?
3. Does this make **bonding with the creature** more exciting?

If a feature fails all three, cut or redesign it.

### Guiding Rules

| Rule | Meaning |
|------|---------|
| **Fun over complexity** | Prefer one clear delightful mechanic over three overlapping systems |
| **Bond first** | The companion is the emotional center; systems should serve the relationship |
| **Readable world** | Players should understand where to go and what to try within seconds |
| **Handheld-native** | Design for buttons, short sessions, and physical sensors — not PC mouse habits |
| **Data-driven content** | Regions, creatures, items, quests live as data so the world can grow for years |
| **Prototype small, expand forever** | Ship a tiny complete loop first; expand outward from a proven core |
| **Approval gates** | Design → approve → implement → playtest → iterate. Do not skip gates |

### Anti-Goals

- Not a hardcore simulation that punishes neglect without recovery paths
- Not an open-world checklist MMO density on day one
- Not photorealistic or high-fidelity 3D
- Not combat-only or care-only — the magic is the **bridge** between home and adventure

---

## 4. Core Gameplay Pillars

These five pillars are non-negotiable. Features that fight a pillar must be redesigned.

### Pillar 1 — Living Companion

The creature is not inventory. It has mood, hunger, personality, and growth. The player should feel responsible *and* rewarded for care.

**Success looks like:** Checking on the creature between adventures feels natural, not like a chore checklist.

### Pillar 2 — Wonderful Exploration

The hex continent rewards curiosity: landmarks, interiors, roofs that fade away, hidden chests, secret stairs, and “what’s over that ridge?” moments.

**Success looks like:** Players deviate from the main path because the world looks inviting.

### Pillar 3 — Collect & Grow

Resources, currency, monsters, skins, and evolutions create tangible progress. Growth should be visible on the creature and in the world (new regions, vehicles, access).

**Success looks like:** After a 20-minute session, the player has something new to show, use, or unlock.

### Pillar 4 — Adventure Tension

Quests, enemies, dungeons, and bosses provide stakes. Combat and danger exist to make discoveries and bonds meaningful — not to punish casually.

**Success looks like:** Bosses feel like events; regular encounters feel fair and brief.

### Pillar 5 — Device Magic

Hardware is not a gimmick list. Gyro, NFC, haptics, and lights deepen immersion when they map cleanly to gameplay verbs.

**Success looks like:** Players say “cool” when the device responds — and can still play if a sensor is unavailable (graceful fallback).

---

## 5. Player Experience Goals

### Emotional Goals

| Goal | Player should feel… |
|------|---------------------|
| Attachment | Protective and proud of their companion |
| Curiosity | Eager to peek into buildings and hexes |
| Mastery | Competent as they unlock vehicles, regions, and evolutions |
| Nostalgia | Warm recognition of early-2000s handheld vibes without pastiche parody |
| Delight | Surprised by secrets, NFC finds, haptic “discoveries” |

### Session Goals

| Session type | Duration | Outcome |
|--------------|----------|---------|
| **Care check-in** | 1–5 min | Feed / soothe / check mood / maybe evolve prep |
| **Adventure outing** | 10–30 min | Explore, loot, quest progress, return home richer |
| **Boss event** | 15–40 min | Prepare, travel, defeat, unlock |

### Usability Goals

- First-time player understands care + adventure within **10 minutes**
- Critical actions reachable without deep menu diving
- Low-poly colorful art remains readable on a small handheld screen
- Performance stays smooth on target handheld hardware

### Long-Term Goals

- Companion identity feels unique (personality + skins + evolution path)
- World feels like one continent with many chapters, not disconnected levels
- Players look forward to “what region unlocks next?”

---

## 6. Target Audience & Tone

| Attribute | Direction |
|-----------|-----------|
| **Primary audience** | Ages ~10–25; nostalgia buyers 25–40 |
| **Skill floor** | Accessible; optional depth in builds/routes |
| **Violence** | Soft / stylized; no gore |
| **Language** | Friendly, clear, lightly witty |
| **Art tone** | Bright, stylized, optimistic with mystery pockets |

**Tone keywords:** curious · warm · playful · adventurous · slightly magical-digital  

**Tone to avoid:** cynical · ultra-gritty · meme-heavy · tutorial-lecturing  

---

## 7. Visual Style

### Presentation

- **2.5D:** 3D meshes for characters, props, buildings, terrain
- **Camera:** Top-down / soft isometric; player has free movement (not grid-locked walking)
- **Reference feeling:** Bloons Monkey City’s readable elevated view — but with free character movement
- **Art direction:** Stylized low-poly, colorful, nostalgic early 2000s
- **Performance:** Designed to run well on handheld (modest polycounts, atlas-friendly materials, chunk streaming)

### Visual Rules

| Do | Don’t |
|----|-------|
| Strong silhouettes for creatures & POIs | Dense muddy brown environments |
| Readable hex biome color coding | Photoreal materials |
| Clear building footprints | Over-detailed interiors that kill framerate |
| Soft lighting with cheerful palettes | Horror lighting as default |

### Audio Direction (high level)

- Chiptune-adjacent melodies with modern clean production
- Distinct “home” vs “adventure” music beds
- Creature vocalizations that telegraph mood
- Haptic + SFX paired for discoveries and hits

---

## 8. World Design

### Macro Structure

- **One connected continent**
- Continent subdivided into **hexagonal regions**
- Each hex ≈ a biome/area with its own mood, encounters, and POIs
- Regions unlock over time (story, quests, boss gates, or exploration keys)

### Biome Palette (planned)

| Biome | Fantasy | Typical content |
|-------|---------|-----------------|
| Grasslands | Safe starter wilds | Tutorial POIs, light encounters |
| Forest | Dense mystery | Hidden paths, ambush creatures |
| Desert | Heat & scarcity | Sparse resources, mirages/secrets |
| Snow | Isolation & clarity | Slippery traversal, hardy monsters |
| Jungle | Overgrowth | Vertical secrets, dense audio |
| Beach / Water | Shoreline & shallows | Water vehicle gates |
| Mountains | Vertical challenge | Climb routes, rare chests |
| City | Social & shops | Interiors, NPC quests, hubs |

### Region Contents (every region should aim for)

- 1–3 **major POIs** (town, dungeon entrance, landmark)
- Several **smaller landmarks**
- **Hidden areas**
- **Chests**
- **Wild monsters**
- **Quests**
- At least one **secret** worth telling a friend about

### Inspiration Rule

Locations may be *inspired by* nostalgic adventure tropes (harbor towns, forest shrines, desert ruins) but must be **original Digital Frontier places** with original names, lore, and layouts — never 1:1 copies of existing IPs.

### Building & Interior Fantasy

Not every building is enterable. Enterable buildings are special.

**When entering an enterable building:**

1. Camera zooms in
2. Roof fades / disappears
3. Interior becomes visible
4. Player explores rooms
5. Stairs enable vertical exploration
6. Hidden items reward thoroughness

**Priority enterable types:** houses, shops, bases, secret locations, dungeons.

---

## 9. Core Gameplay Loop

### Primary Loop (session)

```
┌─────────────────────────────────────────────┐
│ 1. HOME: Care for creature (mood/hunger)    │
│ 2. ENTER Adventure Mode                     │
│ 3. EXPLORE hex / town / interiors           │
│ 4. FIND resources, currency, chests         │
│ 5. DISCOVER / encounter monsters            │
│ 6. PROGRESS quests                          │
│ 7. RETURN / upgrade creature                │
│ 8. UNLOCK new region access                 │
│ 9. PREPARE for major bosses                 │
└─────────────────────────────────────────────┘
         ▲_________________________│
```

### Meta Loop (days / weeks of play)

Care consistency → stronger bond / evolution readiness → harder regions → better loot → customization (skins, vehicles) → boss clears → new hexes → repeat.

### Failure & Recovery

- Neglect affects mood/hunger and may reduce adventure effectiveness — **never soft-locks the game**
- Always provide a recovery path (feed, rest, easy local quests)

---

## 10. Feature Systems

High-level system intents. Detailed specs live in linked design briefs (to be written per feature after approval).

### 10.1 Living Creature Companion

- Persistent companion with **mood**, **hunger**, **personality**, **growth**
- Visible on **home screen** and present in adventure (as follower / partner — TBD in companion brief)
- Care actions: feed, play/soothe, rest, customize

### 10.2 Moods

- Discrete mood states (e.g., Happy, Content, Bored, Hungry-linked irritability, Excited)
- Mood influences: dialogue flavor, minor gameplay bonuses/penalties, RGB / haptics on device
- Mood changes from care, adventure outcomes, and time

### 10.3 Hunger

- Drains over real/play time (tuned for handheld sessions — not abusive)
- Feeding uses inventory food items
- Critical hunger blocks peak performance, not the entire game

### 10.4 Evolution

- Growth milestones unlock evolution branches (data-driven)
- Evolution is a **celebration moment** (VFX, haptics, lights)
- Personality + care history may influence branch eligibility (keep rules readable)

### 10.5 Exploration

- Free movement on 2.5D hex regions
- Landmarks, secrets, roofs-off interiors, vertical stairs
- Region borders gate travel until unlocked

### 10.6 Combat

- Encounter model TBD in combat brief (options: lightweight action, short arena bouts, or hybrid)
- Must stay **brief, readable, handheld-friendly**
- Boss fights are set-piece exceptions with clearer telegraphs

### 10.7 Inventory & Chests

- Inventory for resources, food, keys, quest items
- Chests as exploration rewards (some locked, some hidden)
- Weight/complexity kept low — prefer stacks and clear categories

### 10.8 Currency & Shop

- At least one primary currency for shops
- Shops sell food, basics, cosmetics hooks, maybe map hints
- Economy tuned so exploration feels rewarding without grinding walls

### 10.9 Skins

- Cosmetic customization for companion (and maybe player avatar later)
- Unlock via quests, shops, NFC, or milestones
- Never pay-to-win if monetization appears later

### 10.10 Vehicles

- Unlockable traversal tools (land / water / etc.)
- Used to reach gated hex features
- Gyro-assisted control as an optional delight layer

### 10.11 Quests

- Short readable objectives tied to NPCs and landmarks
- Types: talk, collect, explore, defeat, deliver
- Quests teach systems and gate some unlocks

### 10.12 Boss Fights

- Major region climaxes
- Require preparation (gear, food, evolution stage, vehicle access)
- Victory unlocks region links, story beats, rare rewards

### 10.13 Region Unlocking

- Soft gates: story, boss, key item, vehicle requirement
- Map UI shows locked vs available hexes clearly

### 10.14 Save System

- Reliable save/load on device
- Autosave at home transitions + manual save slots
- Companion state is sacred — never lose care progress casually

---

## 11. Device Integration

### Hardware Targets (eventual device)

| Hardware | Gameplay use |
|----------|--------------|
| Screen | Primary display |
| Physical buttons | Movement, confirm, care shortcuts |
| Gyroscope | Vehicles, balance puzzles, aiming minigames |
| Accelerometer | Shake-to-play care, discovery gestures |
| Magnetometer | “Signal” hunting / secret direction hints |
| NFC reader | Physical collectibles, tags, event unlocks |
| Haptics | Hits, discoveries, creature heartbeat/mood |
| Speaker | Music, SFX, creature vocals |
| RGB lighting | Mood, low hunger warnings, evolution moments |
| Battery + USB-C | Session-friendly charging; low-power home mode |

### Integration Principles

1. **Enhance, don’t require** — core loop playable with buttons + screen alone
2. **One clear verb per sensor** where possible
3. **Spectacle moments** for NFC / evolution / boss clear
4. **Battery respect** — avoid always-on high sensor polling

---

## 12. Prototype Scope (v0.1)

The first playable version must be **small and complete**, not a vertical slice of unfinished systems.

### Must Include

| Element | Prototype target |
|---------|------------------|
| Regions | **One** hex region (Grasslands starter) |
| Town | **One** town with a few enterable buildings |
| Companion | **One** starter creature with mood + hunger |
| Enemy | **One** enemy type |
| Vehicle | **One** simple vehicle |
| Dungeon / secret | **One** secret area or mini-dungeon |
| Boss | **One** boss |
| Home | **Basic home screen** for care |
| Loop | Care → adventure → loot/quest → upgrade → boss prep |

### Explicitly Out of Scope for v0.1

- Full continent
- Large creature roster
- Complex multi-branch evolution webs
- Full shop economy depth
- All biomes
- Online features
- Final industrial hardware firmware (use PC + simulated device inputs)

### Prototype Success Criteria

- A new player can complete the loop in one sitting (~30–60 min)
- Companion care feels meaningful
- Exploration of the single region feels denser than it is wide
- Team agrees: “this is fun — expand it”

---

## 13. Content Expansion Philosophy

After the prototype is fun:

1. Add regions one hex at a time (biome kits)
2. Add creatures in small batches with clear roles
3. Add vehicles when they unlock new verbs / terrain
4. Add quests as connective tissue, not filler
5. Keep data-driven pipelines so content does not require engine rewrites

**Years-long expansion** depends on: stable pillars, strict fun filter, and content pipelines — not on rewriting architecture each season.

---

## 14. Related Documents

| Document | Purpose |
|----------|---------|
| [GAMEPLAY_PILLARS.md](GAMEPLAY_PILLARS.md) | Pillar deep-dive & feature scoring rubric |
| [PLAYER_EXPERIENCE.md](PLAYER_EXPERIENCE.md) | Experience goals, sessions, onboarding |
| [ROADMAP.md](ROADMAP.md) | Phased roadmap & recommended build order |
| [TECHNICAL_ARCHITECTURE.md](TECHNICAL_ARCHITECTURE.md) | Godot 4.7.1 architecture mapping |
| [../ARCHITECTURE.md](../ARCHITECTURE.md) | Existing engineering foundation notes |
| [../SCENE_ARCHITECTURE.md](../SCENE_ARCHITECTURE.md) | Scene tree conventions |
| [../DATA_SCHEMA.md](../DATA_SCHEMA.md) | Resource schema reference |
| [../NAMING_CONVENTIONS.md](../NAMING_CONVENTIONS.md) | Naming standards |

---

## Approval Gate

**Status of this GDD:** Draft 0.1.0 — ready for creative review.

**Next step:** Approve or revise this document.  
**Only after approval:** Select the first implementation slice from `ROADMAP.md` and write a feature brief before coding.

*Do not implement gameplay until an explicit approval is given for that feature.*
