class_name GrasslandLayout
extends RefCounted
## Canonical Grassland Region coordinates and travel paths.
## Relative placement mirrors OG Athena geography (original art, not franchise IP):
##   Pleasant Park = NW heart / start
##   Risky Reels   = NE drive-in
##   Salty Springs = south-central hill town (between Park and Fields)
##   Fatal Fields  = further south farm
## Distances sized for PlayerController.WALK_SPEED (6.5 u/s).

const WALK_SPEED := 6.5

## POI world centers (X, Z) — Y is ground. +Z = south, -Z = north, +X = east.
const PLEASANT_PARK := Vector3(0.0, 0.0, 0.0)
const RISKY_REELS := Vector3(2800.0, 0.0, -2700.0) ## NE of Park (~10 min)
const SALTY_SPRINGS := Vector3(900.0, 0.0, 1270.0) ## SSE of Park (~4 min)
const FATAL_FIELDS := Vector3(500.0, 0.0, 4600.0) ## South of Salty (~12 min from Park)

## Region bounds for base terrain / camera far plane.
const REGION_MIN := Vector3(-800.0, 0.0, -3400.0)
const REGION_MAX := Vector3(3400.0, 0.0, 5200.0)

## Expansion hooks for future continents / chapters.
const EXPAND_NORTH := Vector3(200.0, 0.0, -3300.0)
const EXPAND_EAST := Vector3(3300.0, 0.0, -2700.0)
const EXPAND_WEST := Vector3(-700.0, 0.0, 200.0)
const EXPAND_SOUTH := Vector3(500.0, 0.0, 5100.0)


static func straight_distance(a: Vector3, b: Vector3) -> float:
	return Vector3(a.x, 0.0, a.z).distance_to(Vector3(b.x, 0.0, b.z))


static func walk_minutes(distance: float) -> float:
	return distance / WALK_SPEED / 60.0


## Road polylines (world XZ). Slightly longer than straight-line for scenic feel.
static func path_park_to_salty() -> Array[Vector3]:
	return [
		Vector3(20.0, 0.0, 40.0),
		Vector3(180.0, 0.0, 280.0),
		Vector3(420.0, 0.0, 520.0),
		Vector3(650.0, 0.0, 820.0),
		Vector3(820.0, 0.0, 1080.0),
		SALTY_SPRINGS,
	]


static func path_park_to_reels() -> Array[Vector3]:
	return [
		Vector3(40.0, 0.0, -30.0),
		Vector3(380.0, 0.0, -320.0),
		Vector3(780.0, 0.0, -720.0),
		Vector3(1280.0, 0.0, -1200.0),
		Vector3(1780.0, 0.0, -1680.0),
		Vector3(2280.0, 0.0, -2200.0),
		RISKY_REELS,
	]


static func path_park_to_fields() -> Array[Vector3]:
	## Via Salty Springs approach, then south into the farm — OG “south of Salty” feel.
	return [
		Vector3(20.0, 0.0, 40.0),
		Vector3(280.0, 0.0, 400.0),
		Vector3(700.0, 0.0, 900.0),
		Vector3(900.0, 0.0, 1400.0),
		Vector3(820.0, 0.0, 2200.0),
		Vector3(680.0, 0.0, 3100.0),
		Vector3(560.0, 0.0, 3900.0),
		FATAL_FIELDS,
	]


static func path_length(points: Array[Vector3]) -> float:
	var total := 0.0
	for i in range(1, points.size()):
		total += straight_distance(points[i - 1], points[i])
	return total
