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
| Adult NPC | 1.60m |
| Child NPC | 1.25m |
| Sedan | 1.45m |
| SUV | 1.70m |
| Truck | ~2.05m |
| Tree (small / med / tall) | 4.5 / 6.0 / 7.5m |
| Bench | 0.55m |
| Fountain | 1.35m |
| Furniture | ~0.90m |

Catalog entries should declare `target_height` when mesh raw size varies. Runtime uses `AssetStandardizer.fit_to_height`.

See also: `DIGITAL_FRONTIER_STYLE_GUIDE.md`.

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
