# Prototype Asset Expansion

## License gate (required before import)

| Check | Rule |
|-------|------|
| License | CC0 / public domain preferred; CC-BY only with attribution file |
| Download | Must be explicitly downloadable (no ripped / scraped game assets) |
| Creator | Attribution recorded under `assets/models/external/ATTRIBUTION.md` |
| Godot | Prefer GLB/GLTF; rematerialize to DF toon |
| Style | Stylized, colorful, handheld-safe — not photoreal, not IP clones |

**Rejected categories**

- Digimon / Pokémon / Fortnite character rips (copyright + style clash)
- Photoreal PBR packs
- Unclear / “personal use only” Sketchfab downloads without token + license clarity
- Partner replacements (Emberling / Sparkbit / Tidepup stay custom `CompanionVisual`)

---

## Recommendations (this phase)

### Aircraft / travel (approved → integrated)

| Asset | Source | License | Why | Use |
|-------|--------|---------|-----|-----|
| `craft_speeder` | Kenney Space Kit | CC0 | Bright stylized skiff silhouette | Player Field Skiff |
| `craft_racer` / `craft_cargo` | Kenney Space Kit | CC0 | Variant hulls for upgrades later | Hangar accents |
| `hangar_small` | Kenney Space Kit | CC0 | Reads as a real pad | Pleasant Park hangar |
| Sketchfab stylized planes | Sketchfab (queued) | CC-BY | Alternate art direction tests | Needs `SKETCHFAB_API_TOKEN` |

### Gameplay props (approved → integrated)

| Asset | Source | License | Why | Use |
|-------|--------|---------|-----|-----|
| `treasure_chest` | Kenney Platformer Kit | CC0 | Readable chest for loot | `RegionPropKit.build_chest` |
| `supply_crate` / `barrel` | Kenney Platformer Kit | CC0 | Fortnite-like exploration stash vibe without IP | Hub supply clusters |
| `quest_key` / `collectible_coin` | Kenney Platformer Kit | CC0 | Quest / pickup prototypes | Catalog ready |

### Town vehicles (approved → integrated)

| Asset | Source | License | Why | Use |
|-------|--------|---------|-----|-----|
| `park_car` | Kenney Racing Kit | CC0 | Lived-in suburb cars | Pleasant Park streets |
| `adventure_suv` | Kenney Car Kit | CC0 | Soft adventure vehicle read | Alternating parked cars |

### Creatures (prototype policy)

| Approach | Verdict |
|----------|---------|
| Digimon-inspired GLBs from community | **Reject import** — use as mood boards only; partners stay procedural kits |
| Cute low-poly animals (CC0 Quaternius etc.) | Optional later for wildlife silhouettes only — not partners |
| Existing `StylizedCreatureKit` / `CompanionVisual` | **Canonical** |

### Sketchfab queue (token required)

See also `ASSET_INTEGRATION.md`. Priority when token exists:

1. Stylized Treasure Chest `dbeae8db89eb433f832d0ef48f12480e`
2. Enchanted Crystal `6b01945a041d4ed3b80e14274f0e68c9`
3. Stylized Pine `deadcadc915545a7b4701dbe6eb419e8`
4. Low-poly PSX benches `a353342fa01d43d8bce58496eee7272b`

---

## Field Skiff system (prototype)

- Data: `data/vehicles/field_skiff.tres` (`VehicleClass.AIR`)
- Manager: `VehicleManager.unlock` / `enter_vehicle` / `fly_to` (arc hop)
- Pad: `AircraftPadInteractable` — A board → left/right course → A fly / B cancel
- Hero pad: Pleasant Park east of Pass N Fuel
- Satellite pads: every major Grassland hub (return hops)
- Future hooks: intro sequence, ownership upgrades, inter-region loads via `neighbor_regions`

### Smoke

```bash
godot --headless --path digital-frontier --import
godot --headless --path digital-frontier --scene res://scenes/devtools/prototype_assets_smoke.tscn
```
