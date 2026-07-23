# World Polish & Environmental Design

Digital Frontier’s grassland should feel **intentionally designed** — every prop answers “why is this here?”

## Scale bible (meters)

Apply via `AssetStandardizer` height targets + catalog `target_height` where needed:

| Thing | Height |
| --- | --- |
| Player | 1.70 |
| NPC adult | 1.60 |
| Sedan | 1.45 |
| SUV | 1.70 |
| Fountain | 1.35 |
| Park pond | ~4m across, ~0.18 deep |

Do not fix props one-off — change the rule, then re-fit.

## Pleasant Park layout

- **Arterials** N–S / E–W through the square
- **Park curb loop** around the lawn
- **Frontage streets** in front of houses; driveways meet them
- **Side streets** between house pairs (no dead stubs)
- Houses face the park; garages are enterable (`InteriorKinds.GARAGE`)

## Layering (anti z-fight)

Stacked surfaces use distinct Y bands: grass → lawn → path → road → walk → markings.

## Interiors

- **`InteriorPersonality`** — Modest / Wealthy / Rustic / Modern / Garden / Abandoned
- Exterior house styles map to personality (`brick` → Wealthy, `cottage` → Rustic, `modern` → Modern, `garden` → Garden, …)
- **`ModularInteriorBuilder`** zones homes like real rooms:
  - Ground: living (couch, TV, coffee table) · kitchen (counter, fridge, stove) · dining · entry mat
  - Upstairs: bedroom (bed, nightstand, closet) · bath (sink, toilet, tub)
- Garages: shelves, workbench, tools, storage
- Shops, offices, warehouses keep role-correct layouts (no beds in shops, no stoves in offices)
- Homes stay `InteriorKinds.HOUSE`; personality carries the story, not a fake office/apartment kind

## Outdoors

- Vegetation uses **clusters**, imperfect clearings, satellite saplings, fallen logs, leaf litter
- Hub pads + road polylines share **`RegionVegetationBuilder.placement_allowed`**
- Corridor shoulder trees use the same guards (no trunks on asphalt / plazas)
- Towns: maintained lawns, benches, landscaped yards, mailboxes, street signs, hydrants
- Wilderness: dense groves, wetland fringe at streams, trail markers, camp nooks, pine ridges

## Performance

- Interiors instantiate on enter, free on exit
- Grass uses MultiMesh; litter / logs are sparse boxed props
- Placement culls before spawn so handheld builds skip wasted nodes

## Smoke

```bash
godot --headless --path digital-frontier --scene scenes/devtools/world_polish_smoke.tscn
godot --headless --path digital-frontier --scene scenes/devtools/vehicle_system_smoke.tscn
godot --headless --path digital-frontier --scene scenes/devtools/asset_standardization_smoke.tscn
```
