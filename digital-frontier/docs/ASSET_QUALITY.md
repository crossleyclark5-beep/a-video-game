# Asset Quality & Visual Consistency

Digital Frontier art is a **modern handheld 2.5D pixel diorama** — nostalgic late-90s / early-2000s Digivice energy, stylized (not realistic), readable on a small LCD.

## Audit (phase start)

| Layer | Was | Weakness |
|-------|-----|----------|
| Environment | Strong (`WorldPalette` + `StylizedMesh`) | Wilderness trees thinner than town |
| Player | Capsule kit, unquantized mats | No face/gear; interact lacked motion |
| NPCs | Box + hat | Same silhouette; no walk cycle |
| Companion | Emberling rich; Sparkbit ok | Tidepup reused Emberling mesh |
| Wildlife | Color/scale variants | Nearly identical box+sphere |

**No GLTF packs** — procedural kits stay handheld-friendly (material cache, low poly).

## Art direction (locked)

1. Quantized `WorldPalette` colors  
2. Flat toon + nearest filter via `StylizedMesh`  
3. Box/sphere/capsule silhouettes with personality accents  
4. Orthographic diorama readability over AAA detail  

See also `PIXEL_WORLD_STYLE.md`, `MASCOT_EMBERLING.md`, `UI_STYLE_GUIDE.md`.

## Upgrade plan (priority)

1. **Player** — stylized materials, face, pack, shoes; idle / walk / run / interact  
2. **Companion** — Tidepup unique 3D silhouette (ears + soft snout)  
3. **NPCs** — shared `HumanoidVisual` + role hats + walk bob  
4. **Wildlife** — species silhouettes (rabbit, squirrel, canid, ungulate, bird, bat, boar, mite)  
5. **Environment** — denser wilderness canopy matching town trees  

## Systems added

| Type | Path |
|------|------|
| `StylizedCreatureKit` | `scripts/world/stylized_creature_kit.gd` |
| `HumanoidVisual` | `scripts/world/humanoid_visual.gd` |

Gameplay contracts unchanged: movement, interaction, companion AI, ecosystem spawn/combat.

## Smoke

```bash
godot --headless --path digital-frontier --scene res://scenes/devtools/asset_quality_smoke.tscn
```
