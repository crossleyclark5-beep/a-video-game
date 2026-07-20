# Development Roadmap — Digital Frontier

**Companion to:** [GAME_DESIGN_DOCUMENT.md](GAME_DESIGN_DOCUMENT.md)  
**Engine:** Godot 4.7.1  
**Rule:** No feature implementation without explicit approval of that phase/feature.

---

## Roadmap Philosophy

1. **Design → Approve → Implement → Playtest → Iterate**
2. Build the **smallest complete fun loop** before expanding content volume
3. Prefer vertical slices that touch Home + Adventure together
4. Technical foundation already exists under `digital-frontier/`; this roadmap sequences *gameplay systems*, not folder scaffolding

---

## Phase Overview

| Phase | Name | Goal | Gameplay? |
|-------|------|------|-----------|
| **0** | Design Foundation | GDD, pillars, roadmap, tech mapping | No |
| **1** | Playable Spine | Move, camera, one region shell, home stub | Yes (minimal) |
| **2** | Companion Heart | Mood, hunger, home care loop | Yes |
| **3** | Exploration Delight | Town, interiors roof-fade, chests | Yes |
| **4** | Adventure Stakes | Enemy, combat v1, inventory, currency | Yes |
| **5** | Prototype Capstone | Vehicle, dungeon, boss, quest, save | Yes |
| **6** | Expand | More regions/creatures after fun is proven | Yes |

**Current status:** Phase 0 in progress (this document set). Awaiting approval before Phase 1.

---

## Phase 0 — Design Foundation *(current)*

### Deliverables
- [x] Engineering folder/architecture scaffold (existing)
- [x] Game Design Document
- [x] Gameplay pillars + scoring rubric
- [x] Player experience goals
- [x] Roadmap + build order
- [x] Technical architecture mapping

### Exit criteria
- Creative approval of GDD pillars and prototype scope
- Agreement on Phase 1 first feature to implement

### Does NOT include
- Gameplay coding
- Final art production
- Hardware firmware

---

## Phase 1 — Playable Spine

**Goal:** Feel the 2.5D world and know where Home vs Adventure live.

### Build order
1. Adventure scene boot into **one grasslands hex**
2. Player character movement + camera follow
3. Basic collision / walkable space
4. Stub **Home screen** scene (visual companion placeholder)
5. Transition: Home ↔ Adventure

### Exit criteria
- Player can enter adventure, walk around a blocked-out region, return home
- Runs acceptably on target-ish PC settings (handheld perf pass comes later)

### Approval needed before starting
- Confirm camera angle and movement model (twin-stick / tank / click — recommendation: direct digital stick / WASD analog to handheld d-pad)

---

## Phase 2 — Companion Heart

**Goal:** Bonding loop exists without full combat.

### Build order
1. Companion data: mood, hunger, personality baseline
2. Home care actions: Feed, Soothe/Play, Rest
3. Simple time drain for hunger/mood
4. Visual/audio mood feedback (+ RGB/haptic stubs)
5. Adventure entry gated lightly by critical care (soft gate only)

### Exit criteria
- Care check-in session feels good in 1–5 minutes
- Playtest Q1 (“care about creature”) ≥ 4

### Approval needed
- Mood state list + hunger tuning philosophy
- Whether companion follows in adventure in v0.1 or stays home-linked

---

## Phase 3 — Exploration Delight

**Goal:** Wonderful Exploration pillar lands.

### Build order
1. Blocked-out **town** with roads and POI markers
2. Enterable building pipeline (door trigger → zoom → roof fade → interior)
3. Stairs / second floor in at least one building
4. World chests + hidden chest
5. Basic map / region UI for the single hex

### Exit criteria
- Players voluntarily enter buildings and search for secrets
- Roof-fade reads clearly on small screens

### Approval needed
- Which buildings are enterable in prototype town
- Interior camera rules (zoom amount, roof fade timing)

---

## Phase 4 — Adventure Stakes

**Goal:** Collecting + light tension.

### Build order
1. Inventory + resource nodes
2. Currency pickup + simple shop
3. One enemy type + encounter rules
4. Combat v1 (keep short)
5. Reward hooks into companion care items

### Exit criteria
- A 20-minute outing yields meaningful inventory change
- Combat is understandable and not the whole game

### Approval needed
- Combat model choice (see Technical Architecture + future Combat Brief)

---

## Phase 5 — Prototype Capstone (v0.1 Complete)

**Goal:** Full GDD prototype checklist.

### Build order
1. One **quest** line (talk → collect/explore → turn-in)
2. One **vehicle** + simple gated terrain
3. One **dungeon/secret area**
4. One **boss** encounter + unlock celebration
5. Save/load with companion state integrity
6. Juice pass: haptics/SFX/evolution-ready hooks (even if one evolution only)

### Exit criteria (prototype ship)
- Contains: 1 region, 1 town, 1 creature, 1 enemy, 1 vehicle, 1 dungeon/secret, 1 boss, basic home
- Full care → adventure → upgrade → boss prep loop completable in one sitting
- Team sign-off: “this is fun — expand it”

---

## Phase 6 — Expansion (post-prototype)

Only after Phase 5 fun is proven:

| Track | Examples |
|-------|----------|
| Regions | Forest hex, Beach hex, City expansion |
| Creatures | New discoverable species + collection UI |
| Systems | Skins shop depth, NFC collectibles, gyro vehicle polish |
| Narrative | Multi-boss continent arc |
| Hardware | Device firmware integration beyond stubs |

---

## Recommended System Build Order (summary)

Strict sequence for engineers after Phase 0 approval:

```
1. Player movement + camera          (Spine)
2. Home ↔ Adventure flow             (Spine)
3. Companion mood/hunger/care        (Heart)
4. Region blockout + town            (Explore)
5. Building enter + roof fade        (Explore)
6. Chests + inventory + currency     (Stakes)
7. Enemy + combat v1                 (Stakes)
8. Shop                              (Stakes)
9. Quest v1                          (Capstone)
10. Vehicle v1                       (Capstone)
11. Dungeon/secret                   (Capstone)
12. Boss v1                          (Capstone)
13. Save/load hardening              (Capstone)
14. Device feature stubs → real hooks (parallel, non-blocking)
```

**Parallel-safe (after Spine exists):** art blockouts, audio beds, data authoring for the single region.

**Do not start early:** multi-region streaming, full evolution webs, multiplayer, monetization.

---

## Risk Register

| Risk | Mitigation |
|------|------------|
| Care loop feels like a chore | Fast actions; soft penalties; adventure payoff |
| Combat scope explodes | Lock one enemy + one boss; brief encounters only |
| Interior tech eats schedule | One reusable enterable-building prefab pipeline |
| Hardware unavailable | Simulate sensors in Godot input map / debug panel |
| Over-scoping continent | Hard freeze: one hex until Phase 5 exit criteria met |

---

## Approval Checklist (copy per phase)

```
Phase: __
Feature brief attached: Y/N
Pillar score table complete: Y/N
Prototype scope still respected: Y/N
Creative approval: __________ date: ____
Tech approval: __________ date: ____
```

---

## Next Decision Needed From You

Please approve **Phase 0** (this design set) and choose one:

**A.** Proceed to write a **Phase 1 Feature Brief** (movement + camera + home stub) — still no code until that brief is approved  
**B.** Revise GDD/pillars/roadmap first (tell us what to change)  
**C.** Jump to a different first slice (name it) — we will re-sequence the roadmap  

*No gameplay code until you pick a path.*
