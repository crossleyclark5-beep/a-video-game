# Asset Standardization Pipeline

Digital Frontier no longer rematerializes imports ad-hoc. Every curated GLB goes through **`AssetStandardizer`** before world placement.

## Goals

| Problem | Pipeline rule |
|---------|----------------|
| White / missing materials | Keep albedo (+ normal/emissive when present); else apply DF palette — **never leave white** |
| Photoreal PBR look | Force toon + nearest + quantized `WorldPalette` |
| Wild scales | Catalog scales fit **height targets** (adult ≈ 1.7m) |
| Moonwalk / backwards drive | +Z model front via `face_velocity`; vehicle `mesh_yaw` aligns nose |
| Future imports | Must register in catalog + pass smoke before placement |

## Height targets

| Kind | Height |
|------|--------|
| Player | 1.70m |
| Adult NPC | 1.60–1.70m |
| Child NPC | 1.25–1.35m |
| Car | ~1.55m |
| Truck | ~2.10m |
| Tree (med/tall) | 4.5–7.5m |
| Bench / furniture | believable interior proportions |

## Runtime path

```
ExternalPropCatalog / CharacterCatalog
        │
        ▼
ExternalPropKit.spawn / CharacterKit.spawn
        │
        ▼
AssetStandardizer.rematerialize(mode, accent)
        │
        ├── character → keep textures, toon, nearest
        ├── prop → texture or stylized pattern fill
        └── vehicle → body tint + mesh_yaw
```

Facing: `AssetStandardizer.face_velocity` (player + companion). Do **not** use `Basis.looking_at` on +Z Kenney meshes.

## Adding a new import

1. Drop GLB under `assets/models/external/<category>/`
2. Prefer embedding textures **or** ship `Textures/colormap.png` beside the model
3. Add catalog entry with measured `scale` (and `mesh_yaw` / `tint` if needed)
4. Spawn only via `ExternalPropKit` / `CharacterKit`
5. Run smokes:

```bash
godot --headless --path digital-frontier --scene res://scenes/devtools/asset_standardization_smoke.tscn
godot --headless --path digital-frontier --scene res://scenes/devtools/asset_integration_smoke.tscn
```

## Legal

Kenney CC0 only for these kits. No Fortnite / Digimon franchise meshes. Partners stay DF look-alike kits.

See also: `ASSET_INTEGRATION.md`, `ASSET_QUALITY.md`, `ADVENTURE_STABILITY.md`.
