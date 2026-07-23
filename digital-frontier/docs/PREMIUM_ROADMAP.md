# Premium Quality Roadmap

**Philosophy:** No new major features until existing systems meet the style guide.  
**Full audit:** `PREMIUM_QUALITY_AUDIT.md`  
**Rules:** `DIGITAL_FRONTIER_STYLE_GUIDE.md`

---

## Priority 1 — Critical (blocks premium feel)

| ID | Item | Impact | Status |
|----|------|--------|--------|
| P1.1 | Wire music/sfx bus volumes; procedural music beds for home/adventure/combat; add missing SFX (`vehicle_launch`/`land`) | Audio immersion | Done |
| P1.2 | Restore Home Rest + Play; keep Status + Battle without stealing care verbs | Digi-Pet trust | Done |
| P1.3 | Combat: tween HP bars; A/B dismiss result; battle camera uses `battle_start` | Feedback | Done |
| P1.4 | Catalog `target_height` for trees, benches, key furniture | Scale consistency | Done |
| P1.5 | Utility truck procedural body (not sedan); park tree occlusion marks | World read | Done |
| P1.6 | Minimal loading screen + SceneManager hook | Transition polish | Done |
| P1.7 | Refresh stale `design/ROADMAP.md`; align asset height docs | Direction clarity | Done |

---

## Priority 2 — Major polish

| ID | Item |
|----|------|
| P2.1 | Unify vegetation language (hub vs wilderness mesh richness within budget) |
| P2.2 | CharacterKit `fit_to_height` for all humans; reduce bob-only vs limb split |
| P2.3 | Adventure Pack A-to-use + D-pad sheet scroll |
| P2.4 | Combat camera micro-shake / hit punch; LED pulse on hit |
| P2.5 | Adventure→Home reverse transition parity |
| P2.6 | Replace procedural audio with authored WAV/OGG (keep ids) |
| P2.7 | Interior furniture: prefer GLB consistently; fewer box fallbacks |
| P2.8 | MultiMesh forest belts for density without node explosion | Done (world 3D foundation) |

---

## Priority 3 — Nice-to-have

| ID | Item |
|----|------|
| P3.1 | Custom DF font (not ThemeDB fallback only) |
| P3.2 | Glyph button art instead of ASCII “A”/“Start” |
| P3.3 | Wind / vegetation sway shaders |
| P3.4 | Richer NPC schedules / idle props |
| P3.5 | Retire orphaned 3D habitat path or revive as optional skin |
| P3.6 | Soft shadow contact / AO-lite for diorama depth |

## World foundation (parallel track)

See `WORLD_3D_FOUNDATION.md` — heightfield terrain, MultiMesh density, off-map discoveries, flight-ready elevation.

---

## Definition of done (premium bar)

A build is “premium-ready for content expansion” when:

1. A random Pleasant Park screenshot passes the brand test.  
2. Home care verbs match labels; companion meters are glanceable.  
3. Battle has a readable victory/defeat beat.  
4. Music beds play; no “SFX requested (no stream)” for shipped ids.  
5. Catalog props use height targets; no white materials in smoke.  
6. Adventure load shows a loading state; stability probe stays under budget.  

Until then: **polish over features.**
