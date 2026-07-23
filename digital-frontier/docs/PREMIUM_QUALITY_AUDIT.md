# Premium Quality Audit — Digital Frontier

**Date:** 2026-07-23  
**Method:** Code + scene + smoke inspection (not assumptions)  
**Scope:** Adventure, Home/Digi-Pet, world, characters, UI, combat, audio, controls, performance  

---

## Executive verdict

Digital Frontier has **strong systems scaffolding** and a clear Field Unit identity. Layout polish and asset standardization are underway. The gap to “premium handheld” is not missing features — it is **consistency, feedback, and audio**.

The game already knows what it wants to be (`PIXEL_WORLD_STYLE`, `UI_STYLE_GUIDE`, `HANDHELD_FIRST`). Execution is uneven: intentional town layout next to mixed vegetation languages; rich companion LCD next to silent music; solid combat rules next to auto-dismiss results.

---

## 1. Current strengths

| Area | Evidence |
|------|----------|
| Art direction locked | `WorldPalette`, `StylizedMesh` (64×64 patterns, toon+nearest), `WorldAtmosphere` |
| Handheld input architecture | `InputManager` contexts; modal → MENU; no-touch design |
| Field Unit chrome | `DFStyle`, `DFFormat`, Adventure device HUD, shop pad-complete |
| Asset gate | `AssetStandardizer` rematerialize + height bible; catalog smoke |
| Companion depth | `CreatureManager` care/mood/evolution; Home↔Adventure shared instance |
| Living world budgets | Wildlife/NPC caps; vegetation placement guards; stability probe &lt;11.5k nodes |
| Pleasant Park intent | Arterials, frontage, driveways, pond, enterable garages (layout polish branch) |
| Vehicle arcade feel | Mount/drive/dismount; steering polarity fixed; procedural sedan detail |
| Data-driven content | Quests, items, shops, biomes, discoverables as `.tres` |

---

## 2. Biggest weaknesses

1. **Audio is almost entirely stubs** — no WAV/OGG in repo; music requests only log; vehicle SFX missing from map; bus music/sfx volumes unused.
2. **Dual visual languages** — Kenney GLB humans (bob only) vs procedural `HumanoidVisual` limbs; hub trees vs 3-mesh wilderness trees vs unfitted GLB landmarks.
3. **Height bible incomplete** — `target_height` only on cars/fountain; trees/benches/furniture/characters still magic `scale`.
4. **Home care remapping** — Rest/Play unreachable; buttons relabeled Heal/Train/Status/Battle over Rest/Play/Train/Status nodes.
5. **Combat feedback thin** — HP bars snap; result auto-finishes; battle camera plays `menu_beep`.
6. **Loading** — `SCENE_LOADING` points to missing `loading_screen.tscn`; sync instantiate hitch.
7. **Stale design roadmap** — `docs/design/ROADMAP.md` still “Phase 0 awaiting approval” while Adventure/combat/vehicles ship.

---

## 3. Things that feel unfinished

- Utility truck uses empty `visual_prop_id` → procedural **sedan** mesh  
- Adventure Pack sheet: read-only, no D-pad scroll, no A-to-use  
- Orphaned 3D habitat stack (`HabitatEnvironment`, `CompanionActor`) unused by LCD Home  
- Legacy `home_companion.gd` ColorRect path still present  
- Device NFC / LED / haptics are stubs (acceptable if framed; currently beep-fallback)  
- Expansion gates as world-space `Label3D` chrome  
- Interior rooms mix GLB furniture + box fallbacks in the same floor  

---

## 4. Immersion damage

| Issue | Why it hurts |
|-------|----------------|
| Silent world + beep-only UI | Breaks “premium device” fantasy |
| Camera blocked by unmarked park trees | Fighting the camera in the hero hub |
| Scale mismatches (toy cars / giant fountain historically) | Screenshot fails the DF identity test |
| Auto-closing battle result | No victory beat; feels like a debug skip |
| Remapped Home verbs | Player presses Rest, game Heals — trust break |
| Missing loading overlay | Fade into hitch; feels unfinished |

---

## 5. Highest priority improvements (summary)

See **`PREMIUM_ROADMAP.md`** for ranked P1/P2/P3.

Immediate P1 themes:

1. Audio buses + procedural music beds + missing SFX IDs  
2. Restore digi-pet Rest/Play; Status + Battle without stealing care verbs  
3. Combat: tween HP, A-to-dismiss result, correct battle SFX  
4. Finish catalog `target_height` for trees/benches/furniture  
5. Truck silhouette; park tree occlusion  
6. Minimal loading screen; refresh stale roadmap docs  
7. Style guide as permanent gate for every future asset  

---

## 6. What not to do next

- Do **not** add new regions, creature species, or major systems until P1 quality bar clears.  
- Do **not** chase photorealism.  
- Do **not** import GLBs that skip `AssetStandardizer` + catalog registration.  
