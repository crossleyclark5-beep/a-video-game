# World Polish & Environmental Design

Digital Frontier’s grassland should feel **intentionally designed** — every prop answers “why is this here?”

## Interiors

- **`InteriorPersonality`** — Modest / Wealthy / Rustic / Modern / Garden / Abandoned
- Exterior house styles map to personality (`brick` → Wealthy, `cottage` → Rustic, `modern` → Modern, `garden` → Garden, …)
- **`ModularInteriorBuilder`** zones homes like real rooms:
  - Ground: living (couch, TV, coffee table) · kitchen (counter, fridge, stove) · dining · entry mat
  - Upstairs: bedroom (bed, nightstand, closet) · bath (sink, toilet, tub)
- Shops, offices, warehouses keep role-correct layouts (no beds in shops, no stoves in offices)
- Homes stay `InteriorKinds.HOUSE`; personality carries the story, not a fake office/apartment kind

## Outdoors

- Vegetation uses **clusters**, imperfect clearings, satellite saplings, fallen logs, leaf litter
- Hub pads + road polylines share **`RegionVegetationBuilder.placement_allowed`**
- Corridor shoulder trees use the same guards (no trunks on asphalt / plazas)
- Towns: maintained lawns, benches, landscaped yards
- Wilderness: dense groves, wetland fringe at streams, trail markers, camp nooks, pine ridges

## Performance

- Interiors instantiate on enter, free on exit
- Grass uses MultiMesh; litter / logs are sparse boxed props
- Placement culls before spawn so handheld builds skip wasted nodes

## Smoke

```bash
godot --headless --path digital-frontier --scene scenes/devtools/world_polish_smoke.tscn
```
