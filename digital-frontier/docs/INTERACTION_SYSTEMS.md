# Interaction & Building Systems

Added on top of the Pleasant Park prototype (no full rebuild).

## Interaction

| Class | Path | Role |
|-------|------|------|
| `Interactable` | `scripts/systems/interaction/interactable.gd` | Base Area3D for any interact target |
| `InteractionAgent` | `.../interaction_agent.gd` | On player — finds nearest target, handles E/A |
| `ChestInteractable` | `.../chest_interactable.gd` | Loot chests |
| `SignInteractable` | `.../sign_interactable.gd` | Readable signs |
| `InteractionPrompt` | `scenes/ui/components/interaction_prompt.tscn` | On-screen prompt |

**Add a new interactable:** instance/extend `Interactable`, set `prompt_text`, implement `_on_interact` or connect `interacted`.

## Buildings

| Class | Role |
|-------|------|
| `BuildingVolume` | Enterable building shell + door + roof fade list |
| `BuildingInteriorController` | Enter/exit, zoom, load interior scene |
| `BuildingFloor` | Floor index (0 ground, 1+ up, -1 basement) |
| `FloorTransition` | Stairs interactable between floors |

**Test interior:** `scenes/world/buildings/interiors/test_house_interior.tscn` (Brick House) — ground + upstairs + hidden chest.

## Player

- Idle / walk / run (Shift)
- Shadow decal mesh
- Procedural footsteps
- `InteractionAgent` child
