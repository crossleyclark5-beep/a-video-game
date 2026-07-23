# Asset Discovery & Integration

## Art director verdict

Digital Frontier stays a **pixel-toon handheld diorama**. External meshes are allowed only when they:

1. Are stylized / low-poly (not photoreal)  
2. Stay under ~5k triangles for props, ~20k for hero props  
3. Can be rematerialized into `WorldPalette` + toon/nearest  
4. Fill a real world gap (town life, wilderness camps, interior realism)  
5. Never replace partner creatures (Emberling / Sparkbit / Tidepup)

---

## Sketchfab recommendations (CC-BY downloadable)

> Downloads require a Sketchfab API token (`SKETCHFAB_API_TOKEN`).  
> Use `tools/fetch_sketchfab.py` once the token is available.

| Priority | Model | UID | Faces | Why it fits | Where | Perf |
|----------|-------|-----|------|-------------|-------|------|
| Env | Stylized Pine Tree | `deadcadc915545a7b4701dbe6eb419e8` | 939 | Hand-painted stylized pine | Pine ridges / hollow | Excellent |
| Env | Free Pack - Rocks Stylized | `7c60b4d1b8ab4187965f30c5e0212fc0` | 3.1k | Soft stylized rock set | Wilderness / streams | Excellent |
| Env | Cartoon fallen tree | `85be5e12759d460cb5f1f0d7a4c109b6` | 7k | Storytelling logs | Forest belts | Good |
| Env | Low poly Stylized Nature Pack | `9c773e846c6e4448b26b2cdecb2b91bf` | 21k | Broad nature kit | Wilderness fill | OK if culled |
| Town | Low-Poly PSX Style Park Benches | `a353342fa01d43d8bce58496eee7272b` | 6.7k | Nostalgic PSX read | Pleasant Park plaza | Good |
| Adventure | Stylized Treasure Chest | `dbeae8db89eb433f832d0ef48f12480e` | 4k | Readable chest silhouette | Chests / ruins | Excellent |
| Adventure | Enchanted Crystal | `6b01945a041d4ed3b80e14274f0e68c9` | 336 | Tiny mystery prop | Sanctum / secrets | Excellent |
| Adventure | Ancient Ruins | `105c85f4668245208fe71cac4861cf8c` | 2.1k | Ruin storytelling | Pine Hollow / trails | Excellent |
| Adventure | Stylized Wooden Sign | `7556d3e7237749eda5ee876736e5c601` | 1.9k | Trail markers | Corridor landmarks | Excellent |
| Reject | Lowpoly birds (106k) | `42866166…` | 106k | Too heavy; style OK | — | Fail handheld |
| Reject | Photoreal / PBR packs | various | high | Breaks pixel-toon | — | Fail style |
| Reject | Character packs replacing partners | various | — | Partners stay custom | — | Fail design |

### Sketchfab fetch

```bash
export SKETCHFAB_API_TOKEN=...
python3 digital-frontier/tools/fetch_sketchfab.py deadcadc915545a7b4701dbe6eb419e8 --out digital-frontier/assets/models/external/sketchfab/
```

---

## Integrated now (Kenney CC0 — style-matched)

Sketchfab auth is unavailable in this environment. **Kenney Nature / Fantasy Town / Furniture / Castle kits** match the same late-90s–handheld stylized language, are CC0, and are already rematerialized to DF toon.

Curated paths under `assets/models/external/`:

| Folder | Contents | Used for |
|--------|----------|----------|
| `nature/` | pine/oak trees, bush, flowers, rocks, log, mushroom, campfire, tent | Wilderness + camps |
| `town/` | lantern, fence, bench, stall, cart, fountain, banner | Pleasant Park life |
| `interior/` | bed, sofa, table, chair, desk, fridge, stove, TV… | Modular interiors |
| `adventure/` | pillar, ruins, flag, **treasure chest, crates, barrels, key, coin** | Landmarks + loot/supply |
| `transport/` | **Field Skiff crafts, hangar, park cars, SUV** | Aircraft travel + town vehicles |

Runtime: `ExternalPropCatalog` + `ExternalPropKit` → **`AssetStandardizer`** (see `docs/ASSET_STANDARDIZATION.md`).

See also `docs/ASSET_PROTOTYPE.md` for the Field Skiff system and license gate.

**Partner creatures are not replaced.**

### Smoke

```bash
godot --headless --path digital-frontier --import
godot --headless --path digital-frontier --scene res://scenes/devtools/asset_integration_smoke.tscn
```

---

## Performance rules

- Prefer instances under ~5k tris  
- Rematerialize to shared `StylizedMesh` cache (few GPU variants)  
- Cap external hero props per hub (~12–20)  
- Keep procedural MultiMesh grass as the density backbone  
- LODs: far wilderness still uses procedural `_pixel_tree`; external trees for landmarks / camps / plaza accents
