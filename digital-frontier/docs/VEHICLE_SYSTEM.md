# Vehicle System

## Goal

Driving is another reason to explore Digital Frontier — arcade-fun, handheld-first, and expandable to trucks, boats, aircraft, and story craft.

## Framework

| Piece | Role |
|-------|------|
| `VehicleData` | Shared definition (class, speeds, camera, visual prop, ownership flags) |
| `VehicleBase` | Mount / hide player / exit safety / camera handoff |
| `CarVehicle` | Arcade ground drive (accel, brake, reverse, steer, off-road mul) |
| `VehicleEnterInteractable` | “Enter …” prompt via existing InteractionAgent |
| `VehicleSpawner` | Builder factory for logical world placement |
| `VehicleManager` | Unlock, own/garage foundation, mount, Field Skiff hops |

`VehicleClass`: `GROUND` · `WATER` · `AIR` · `HYBRID`

## Controls (handheld)

| Action | Input |
|--------|--------|
| Accelerate / reverse | Stick Y (forward / back) |
| Steer | Stick X |
| Exit | B (`ui_cancel`) |
| Enter | A on vehicle prompt |

## Camera

`CameraRig.set_vehicle_mode` — higher follow, wider zoom, stronger look-ahead with speed.

## World placement

- **Pleasant Park:** curb / driveway / fuel-lot fleet (`park_cruiser`, `adventure_suv`, `utility_truck`)
- **Salty Springs:** street cars + gas-lot truck
- **Fatal Fields:** farm truck + trail SUV

## Ownership foundation

`VehicleManager.own_vehicle` / `is_owned` / `get_owned_ids` — saved under `vehicle_data.owned` with empty `customization` + `upgrades` slots for later.

## Future

- Boats: subclass `VehicleBase` with water plane drive
- Aircraft: existing Field Skiff hops + future free-fly controller
- Story vehicles: `VehicleData` + unlock quest / rare spawn

## Smoke

```bash
godot --headless --path digital-frontier --scene res://scenes/devtools/vehicle_system_smoke.tscn
```
