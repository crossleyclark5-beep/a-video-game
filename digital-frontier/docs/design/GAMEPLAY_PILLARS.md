# Core Gameplay Pillars — Digital Frontier

**Companion to:** [GAME_DESIGN_DOCUMENT.md](GAME_DESIGN_DOCUMENT.md)  
**Purpose:** Make pillars actionable for design reviews and feature scoring.

---

## Pillar Overview

| # | Pillar | One-line |
|---|--------|----------|
| 1 | Living Companion | Care creates attachment and identity |
| 2 | Wonderful Exploration | Curiosity is constantly rewarded |
| 3 | Collect & Grow | Progress is tangible and showable |
| 4 | Adventure Tension | Stakes make discoveries matter |
| 5 | Device Magic | Hardware deepens immersion without gating fun |

---

## Pillar 1 — Living Companion

### Intent
The creature is the emotional product. Mood, hunger, personality, and growth make it feel alive between adventures.

### Design implications
- Home screen is a first-class mode, not a pause menu
- Care actions must be fast and satisfying
- Evolution and skins are expression of the bond
- RGB/haptics should reflect creature state

### Feature examples that support this
- Mood reactions to feeding
- Personality-flavored companion lines
- Evolution celebration
- NFC plush/tag that “checks in” with the creature

### Feature examples that violate this
- Creature as mute stat stick
- Care timers that feel like mobile energy gates
- Endless maintenance with no adventure payoff

---

## Pillar 2 — Wonderful Exploration

### Intent
The hex world invites detours. Interiors, secrets, and landmarks create “just one more look.”

### Design implications
- Readable POIs from the 2.5D camera
- Roof-fade interiors as signature delight
- Chests and secrets spaced for discovery rhythm
- Region art kits that sell biome identity instantly

### Supports
- Enterable shops/houses/dungeons
- Hidden stairs and rooftop secrets
- Landmarks visible across hexes
- Magnetometer “signal” optional hunts

### Violates
- Empty hex filler
- Identical copy-paste towns
- Exploration that is only combat corridors

---

## Pillar 3 — Collect & Grow

### Intent
Players accumulate creatures, resources, cosmetics, and access. Growth should be felt on both companion and map.

### Design implications
- Clear reward tables (data-driven)
- Currency sinks that feel aspirational (skins, food quality, vehicle fuel/parts)
- Unlock graph that is understandable on the map UI

### Supports
- Chests, monster discovery, shops, skins, region unlocks
- Evolution milestones
- Vehicle unlocks as traversal growth

### Violates
- Opaque grind curves
- Inventory clutter with no use
- Collecting without display/identity payoff

---

## Pillar 4 — Adventure Tension

### Intent
Enemies, quests, and bosses create rhythm and climax without turning the game into a pure fighter.

### Design implications
- Regular encounters are short
- Bosses are ceremonies
- Quests teach and gate without busywork
- Prep (food, gear, evolution) matters before big fights

### Supports
- One strong enemy archetype per area (prototype)
- Dungeon with a readable risk/reward
- Boss that unlocks the next hex link

### Violates
- Mandatory long combat grinds
- Instant-fail unfair traps as default
- Quests that are only “kill 40 rats”

---

## Pillar 5 — Device Magic

### Intent
The handheld’s sensors and lights make Digital Frontier feel like a *thing you own*, not a phone port.

### Design implications
- Map each sensor to a clear verb
- Always ship button/screen fallbacks
- Use RGB + haptics as creature “body language”

### Supports
- Gyro vehicle lean
- NFC collectible scans
- Haptic chest-open / hit confirms
- Mood lighting on the shell

### Violates
- Features that hard-require gyro/NFC
- Sensor minigames that replace the core loop
- Battery-draining always-on tracking

---

## Feature Scoring Rubric

Use this in design reviews. Score 0–2 per pillar (0 = harms / irrelevant, 1 = mild support, 2 = strong support).

| Feature | P1 Companion | P2 Explore | P3 Collect | P4 Tension | P5 Device | Total | Decision |
|---------|--------------|------------|------------|------------|-----------|-------|----------|
| Example: Roof-fade interiors | 0 | 2 | 1 | 0 | 0 | 3 | Build |
| Example: Complex crafting tree | 0 | 0 | 1 | 0 | 0 | 1 | Cut / rethink |

**Rule of thumb:**
- **Total ≥ 3** and at least one pillar scored **2** → candidate for production
- **Total ≤ 2** → cut or redesign
- Any feature that **harms Pillar 1** needs extraordinary justification

---

## Pillar Conflicts (resolve intentionally)

| Conflict | Resolution bias |
|----------|-----------------|
| Deep care sim vs short sessions | Prefer fast care with meaningful states |
| Huge open hex vs readability | Prefer denser smaller regions |
| Hard combat vs kid-friendly tone | Prefer readable challenge, generous recovery |
| Sensor spectacle vs accessibility | Prefer optional enhancement |

---

## Approval Note

Pillars are locked for v0.1 unless creative direction revises this file. All feature briefs must include a pillar score table.
