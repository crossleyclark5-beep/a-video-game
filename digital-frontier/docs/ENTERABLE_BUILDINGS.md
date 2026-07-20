# Enterable Buildings & Camera Occlusion

## Rule

**If the player can see it, they can explore it.** The player should never disappear behind world geometry.

## Enterable buildings

- **`BuildingVolume`** — door contract, roof fade, shell cutaway, `interior_kind`, `interior_personality`
- **`InteriorPersonality`** — Modest / Wealthy / Rustic / Modern / Garden / Abandoned home stories
- **`ModularInteriorBuilder`** — runtime furnished interiors by kind; homes use room zones (living / kitchen / dining / bedroom / bath)
- **`RegionPropKit.make_enterable_building`** — universal open-top shell + modular interior
- Handcrafted `PackedScene` still overrides via `interior_scene` (e.g. `test_house_interior.tscn`)

Every grassland POI building (houses, shops, barns, booths, sheds, gas shops) uses this path. Interiors include furniture, chests, and lore notes. Pleasant Park exterior styles drive personality so neighboring homes don’t feel identical.

## Multi-floor

`BuildingFloor` + `FloorTransition` still drive story visibility. Towers/apartments spawn multiple floors from `InteriorKinds.stories_for`.

## Camera occlusion fade

- **`CameraOcclusionFader`** on the camera rig
- Meshes in group `occludable` (via `OcclusionUtil`) soft-fade when they block camera→player LOS
- Alpha floors around ~0.32 — translucent, not invisible
- Disabled while indoors (building cutaway owns that case)
- Tagged: roofs, gazebo, fuel canopies, tree canopies

## Performance

- Occlusion checks every other frame; distance cull; max fading set
- Interiors instantiate on enter and free on exit
- Reusable modular recipes instead of unique scenes per building
