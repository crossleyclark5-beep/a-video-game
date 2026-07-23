# Digital Frontier Style Guide

**Status:** Permanent — every future addition must pass this gate.  
**Companion docs:** `PIXEL_WORLD_STYLE.md`, `UI_STYLE_GUIDE.md`, `HANDHELD_FIRST.md`, `ASSET_STANDARDIZATION.md`, `WORLD_POLISH.md`

---

## Core identity

Digital Frontier is a **premium stylized handheld adventure** — not AAA realism, not a random Kenney dump, not soft clay toy 3D.

Every screenshot must answer: **“Does this belong only to Digital Frontier?”**

If removing the logo would make it look like a stock asset pack demo, it fails.

---

## World style

| Rule | Spec |
|------|------|
| Terrain | Box/diorama pads + triplanar pixel patterns (`StylizedMesh` 64×64). No photoreal terrain shaders. |
| Colors | `WorldPalette` only — quantized; no raw white / random hex. |
| Lighting | `WorldAtmosphere`: linear tonemap, soft lamp glow, parallel-split shadows, gentle fog, slow day cycle. |
| Vegetation density | Hubs denser and more detailed; wilderness uses budget meshes but **same silhouette language** (trunk + clustered canopy). Landmark GLB trees must use `target_height`. |
| Roads | Continuous arterials; frontage for houses; driveways that meet streets; no dead stubs. Layer Y bands to prevent z-fight. |
| Buildings | Open-top enterable shells; roofs fade; personality via `InteriorPersonality`; garages enterable when present. |
| Materials | Toon diffuse, specular off, nearest filter. Patterns for grass/asphalt/brick/wood/leaf/water. |
| Water | Shallow readable ponds (~4m park scale); living water animation OK; fountains ~1.35m — never lake-sized props. |

### Placement

Every prop answers **why is it here?**  
Clusters over scatter. Clearings intentional. No clipping, floating, or duplicate overlapping planes.

---

## Character style

| Role | Height | Notes |
|------|--------|-------|
| Player | 1.70m | Catalog / `fit_to_height` |
| Adult NPC | 1.60m | No hero-scale mul |
| Child NPC | ~1.25m | |
| Companion | Chibi / stage-scaled | Personality silhouette; DF lookalike kits only (no IP meshes) |

- Prefer one animation language per cast class (limb walk or bob — don’t mix unreadably in one shot).  
- Facing: `AssetStandardizer.face_velocity` (+Z model front).  
- Outfit/character library must rematerialize through the pipeline.

---

## Object style

| Kind | Height / size |
|------|----------------|
| Sedan | 1.45m |
| SUV | 1.70m |
| Truck | ~2.05m — **looks like a truck**, not a recolored sedan |
| Bench | 0.55m |
| Furniture | ~0.90m sitting height language |
| Tree small / med / tall | 4.5 / 6.0 / 7.5m |
| Signs / lamps / mailboxes | Human-reachable; readable Label3D sparingly |

Vehicles need windows, tires, lights, door read — never colored bricks.

---

## UI / Field Unit style

- Digi-device chrome via `DFStyle` / `WorldPalette` UI tokens.  
- Large type; square panels; orange CTAs; cyan LCD accents.  
- **Buttons only** — no touchscreen assumptions.  
- A confirms, B backs, Start = Field Unit / Adventure, Select = Settings.  
- Sheets must be D-pad navigable on handheld (scroll is required for long text).

---

## Audio style (until real assets land)

- Every emitted SFX id must exist in `AudioManager` (no silent “no stream”).  
- Music track ids (`home_night`, adventure, combat) must play *something* (procedural bed OK as placeholder).  
- Apply `GameConfig` master / music / sfx bus volumes.  
- Real WAV/OGG replace placeholders without renaming ids.

---

## Asset workflow (mandatory)

```
Import GLB
  → Register in ExternalPropCatalog / CharacterCatalog
  → Texture check (keep albedo/normal when present)
  → AssetStandardizer.rematerialize (never leave white)
  → target_height / fit_to_height
  → Proxy collision (world meters, counter-scaled)
  → Style approval (palette + silhouette)
  → Smoke scene green
  → World placement
```

Nothing enters the shipped world without catalog + smoke.

---

## Performance / handheld

- Adventure world node budget gate ~11.5k (stability probe).  
- Prefer MultiMesh grass; sparse litter; living actor caps.  
- Soft particles (~48). Camera far readable, not cinematic.  
- Loading: fade + loading overlay before heavy instantiate.

---

## Failure examples (do not ship)

- White / missing materials  
- Moonwalking characters  
- Inverted vehicle steer  
- Oversized fountain-as-pond  
- Care button labeled Rest that calls Heal  
- Battle victory that auto-closes before the player reads it  
- GLB parked in world with no rematerialize  
