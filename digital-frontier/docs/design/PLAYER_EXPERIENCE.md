# Player Experience Goals — Digital Frontier

**Companion to:** [GAME_DESIGN_DOCUMENT.md](GAME_DESIGN_DOCUMENT.md)

---

## North-Star Experience

> “I care about this creature, I’m curious about the next hex, and the device in my hands makes both feel real.”

If a build does not produce that sentence in playtests, something is wrong — polish will not fix a missing pillar.

---

## Experience Pillars → Feelings

| Player feeling | Driven by |
|----------------|-----------|
| Attachment | Moods, hunger recovery, personality, home screen presence |
| Curiosity | Hex biomes, landmarks, roof-fade interiors, secrets |
| Competence | Upgrades, vehicle unlocks, quest completion, boss prep |
| Warm nostalgia | Art, audio, handheld rituals — not IP copying |
| Delight | Chests, NFC, haptics, evolution moments, RGB mood |

---

## Player Fantasy Roles

The player simultaneously inhabits:

1. **Caretaker** — keeps the companion healthy and happy  
2. **Explorer** — maps hexes, buildings, and secrets  
3. **Collector** — gathers monsters, skins, resources  
4. **Adventurer** — faces enemies, dungeons, bosses  

UX and modes should make role-switching obvious: **Home** vs **Adventure**.

---

## Session Design

### Care Check-in (1–5 minutes)

**Entry:** Device wake / home screen  
**Goals:** Read mood at a glance, feed/soothe if needed, feel progress  
**Emotion:** Warmth, responsibility without stress  
**Exit:** Ready for adventure or put device down satisfied  

**UX requirements:**
- Mood readable in <2 seconds (pose + color + light)
- Feed/soothe within 2 button presses from home
- No forced ads, no blocking timers that strand the player

### Adventure Outing (10–30 minutes)

**Entry:** “Adventure” from home  
**Goals:** Explore town/wilds, loot, encounter, quest step  
**Emotion:** Curiosity + light tension  
**Exit:** Return home with inventory gains and story progress  

**UX requirements:**
- Map shows current hex and obvious POIs
- Death/failure returns player safely with partial rewards preferred
- Easy return-to-home flow

### Boss Event (15–40 minutes)

**Entry:** Intentional — player chooses to challenge  
**Goals:** Prep, travel, fight, celebrate unlock  
**Emotion:** Anticipation → triumph  
**Exit:** New region access / rare reward / companion reaction  

---

## Onboarding (First 10 Minutes)

| Minute | Experience |
|--------|------------|
| 0–2 | Meet companion on home screen; name/confirm; first feed |
| 2–5 | Enter starter town; move; talk to one NPC; see a chest |
| 5–8 | Short wilds walk; one enemy encounter; loot |
| 8–10 | Return home; see companion react to adventure; tease next goal |

**Onboarding anti-patterns:** long lore dumps, 12-system tutorials, empty first hex.

---

## Companion Bond Curve

| Stage | Player perception |
|-------|-------------------|
| Day 1 | “Cute helper” |
| Early unlocks | “My partner” |
| Evolution 1 | “We’ve been through something” |
| Boss clear | “We earned this together” |
| Late skins/personality | “This one is uniquely mine” |

Design content gates to support this curve — not only combat power gates.

---

## Accessibility & Comfort Goals

- Color cues never the *only* mood signal (pose/animation/text too)
- Button remapping planned for development builds
- Motion/gyro features optional
- Text sizes readable on handheld resolution
- Reduced flicker/flash for evolution/boss VFX options

---

## Success Metrics (qualitative for early builds)

Playtest questions (score 1–5):

1. Did you care how the creature felt?
2. Did you want to look inside buildings / around corners?
3. Did you feel you grew in a tangible way?
4. Was any system confusing or annoying?
5. Would you open the device again tomorrow?

**Ship prototype only if** median scores on Q1–Q3 are ≥ 4 in internal playtests.

---

## Approval Note

Experience goals guide UI copy, onboarding, and feature priority. Changes require creative approval.
