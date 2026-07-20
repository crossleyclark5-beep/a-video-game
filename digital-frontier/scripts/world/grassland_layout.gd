class_name GrasslandLayout
extends RefCounted
## Canonical Grassland Region coordinates and travel paths.
## Distances sized for PlayerController.WALK_SPEED (6.5 u/s).

const WALK_SPEED := 6.5

## POI world centers (X, Z) — Y is ground.
const PLEASANT_PARK := Vector3(0.0, 0.0, 0.0)
const SALTY_SPRINGS := Vector3(1400.0, 0.0, -680.0)
const RISKY_REELS := Vector3(2400.0, 0.0, 3070.0)
const FATAL_FIELDS := Vector3(-4200.0, 0.0, -2050.0)

## Region bounds for base terrain / camera far plane.
const REGION_MIN := Vector3(-4800.0, 0.0, -2800.0)
const REGION_MAX := Vector3(3000.0, 0.0, 3600.0)

## Expansion hooks for future continents / chapters.
const EXPAND_NORTH := Vector3(-400.0, 0.0, -2700.0)
const EXPAND_EAST := Vector3(2900.0, 0.0, 3070.0)
const EXPAND_WEST := Vector3(-4700.0, 0.0, -2050.0)
const EXPAND_SOUTH := Vector3(0.0, 0.0, 800.0)


static func straight_distance(a: Vector3, b: Vector3) -> float:
	return Vector3(a.x, 0.0, a.z).distance_to(Vector3(b.x, 0.0, b.z))


static func walk_minutes(distance: float) -> float:
	return distance / WALK_SPEED / 60.0


## Road polylines (world XZ). Slightly longer than straight-line for scenic feel.
static func path_park_to_salty() -> Array[Vector3]:
	return [
		Vector3(40.0, 0.0, -10.0),
		Vector3(280.0, 0.0, -60.0),
		Vector3(520.0, 0.0, 40.0),
		Vector3(780.0, 0.0, -180.0),
		Vector3(1080.0, 0.0, -420.0),
		SALTY_SPRINGS,
	]


static func path_park_to_reels() -> Array[Vector3]:
	return [
		Vector3(50.0, 0.0, 40.0),
		Vector3(320.0, 0.0, 280.0),
		Vector3(620.0, 0.0, 720.0),
		Vector3(980.0, 0.0, 1180.0),
		Vector3(1400.0, 0.0, 1680.0),
		Vector3(1850.0, 0.0, 2280.0),
		RISKY_REELS,
	]


static func path_park_to_fields() -> Array[Vector3]:
	return [
		Vector3(-50.0, 0.0, -20.0),
		Vector3(-380.0, 0.0, -80.0),
		Vector3(-820.0, 0.0, 120.0),
		Vector3(-1400.0, 0.0, -200.0),
		Vector3(-2100.0, 0.0, -620.0),
		Vector3(-2900.0, 0.0, -1200.0),
		Vector3(-3600.0, 0.0, -1700.0),
		FATAL_FIELDS,
	]


static func path_length(points: Array[Vector3]) -> float:
	var total := 0.0
	for i in range(1, points.size()):
		total += straight_distance(points[i - 1], points[i])
	return total
