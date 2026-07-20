class_name GrasslandLayout
extends RefCounted
## Canonical Grassland Region coordinates and travel paths.
## Hub-and-spoke around Pleasant Park (center) — Fortnite-style landmark spread.
## Distances sized for PlayerController.WALK_SPEED (6.5 u/s).
## Nearby POIs ~5 min · mid ~6–8 · majors ~10–15.

const WALK_SPEED := 6.5

## POI world centers (X, Z) — Y is ground. +Z = south, -Z = north, +X = east.
const PLEASANT_PARK := Vector3(0.0, 0.0, 0.0) ## Central landmark / start
const RISKY_REELS := Vector3(120.0, 0.0, -3900.0) ## North (~10 min)
const MIRROR_MERE := Vector3(1380.0, 0.0, -1380.0) ## Northeast (~5 min)
const MARKET_MILE := Vector3(2700.0, 0.0, 180.0) ## East (~7 min)
const GREASE_GROVE := Vector3(-2100.0, 0.0, 1550.0) ## Southwest (~6.7 min)
const SALTY_SPRINGS := Vector3(320.0, 0.0, 2520.0) ## South (~6.5 min)
const FATAL_FIELDS := Vector3(3350.0, 0.0, 3550.0) ## Southeast (~12.5 min)

## Shared journey landmarks (keep builders + mini-map in sync).
const LANDMARK_WEST_RIDGE := Vector3(-420.0, 0.0, 80.0)
const LANDMARK_NORTH_PASS := Vector3(80.0, 0.0, -1450.0)
const LANDMARK_SOUTH_BLUFFS := Vector3(3400.0, 0.0, 4100.0)
const LANDMARK_CREEK_BRIDGE := Vector3(720.0, 0.0, -720.0)
const LANDMARK_HILLSIDE_CAVE := Vector3(280.0, 0.0, 1180.0)
const LANDMARK_PRAIRIE_OVERLOOK := Vector3(2100.0, 0.0, 2800.0)
const LANDMARK_MOVIE_BILLBOARD := Vector3(90.0, 0.0, -2800.0)
const LANDMARK_SECRET_SHACK := Vector3(-160.0, 0.0, 280.0)
const LANDMARK_PINE_HOLLOW := Vector3(180.0, 0.0, 980.0)
const LANDMARK_MEADOW_CLEARING := Vector3(60.0, 0.0, -2100.0)
const LANDMARK_STREAM_CROSSING := Vector3(620.0, 0.0, -420.0)
const LANDMARK_CREATURE_DEN := Vector3(1100.0, 0.0, 90.0)

## Region bounds for base terrain / camera far plane.
const REGION_MIN := Vector3(-2600.0, 0.0, -4400.0)
const REGION_MAX := Vector3(4200.0, 0.0, 4300.0)

## Expansion hooks for future continents / chapters.
const EXPAND_NORTH := Vector3(100.0, 0.0, -4300.0)
const EXPAND_EAST := Vector3(4100.0, 0.0, 200.0)
const EXPAND_WEST := Vector3(-2500.0, 0.0, 200.0)
const EXPAND_SOUTH := Vector3(3400.0, 0.0, 4200.0)


static func straight_distance(a: Vector3, b: Vector3) -> float:
	return Vector3(a.x, 0.0, a.z).distance_to(Vector3(b.x, 0.0, b.z))


static func walk_minutes(distance: float) -> float:
	return distance / WALK_SPEED / 60.0


## Road polylines (world XZ). Curves + waypoints so travel isn't a ruler line.
static func path_park_to_salty() -> Array[Vector3]:
	return [
		Vector3(20.0, 0.0, 40.0),
		Vector3(120.0, 0.0, 420.0),
		Vector3(260.0, 0.0, 900.0),
		LANDMARK_PINE_HOLLOW,
		Vector3(300.0, 0.0, 1700.0),
		SALTY_SPRINGS,
	]


static func path_park_to_reels() -> Array[Vector3]:
	return [
		Vector3(10.0, 0.0, -40.0),
		Vector3(-40.0, 0.0, -520.0),
		Vector3(40.0, 0.0, -1100.0),
		LANDMARK_NORTH_PASS,
		LANDMARK_MEADOW_CLEARING,
		LANDMARK_MOVIE_BILLBOARD,
		RISKY_REELS,
	]


static func path_park_to_fields() -> Array[Vector3]:
	## Southeast arc — not stacked under Salty.
	return [
		Vector3(40.0, 0.0, 40.0),
		Vector3(480.0, 0.0, 380.0),
		Vector3(1100.0, 0.0, 900.0),
		Vector3(1700.0, 0.0, 1800.0),
		LANDMARK_PRAIRIE_OVERLOOK,
		Vector3(2800.0, 0.0, 3100.0),
		FATAL_FIELDS,
	]


static func path_park_to_mere() -> Array[Vector3]:
	return [
		Vector3(40.0, 0.0, -20.0),
		Vector3(280.0, 0.0, -180.0),
		LANDMARK_STREAM_CROSSING,
		LANDMARK_CREEK_BRIDGE,
		Vector3(1100.0, 0.0, -1100.0),
		MIRROR_MERE,
	]


static func path_park_to_mile() -> Array[Vector3]:
	return [
		Vector3(40.0, 0.0, 20.0),
		Vector3(520.0, 0.0, 60.0),
		LANDMARK_CREATURE_DEN,
		Vector3(1800.0, 0.0, 140.0),
		Vector3(2300.0, 0.0, 200.0),
		MARKET_MILE,
	]


static func path_park_to_grove() -> Array[Vector3]:
	return [
		Vector3(-30.0, 0.0, 20.0),
		LANDMARK_SECRET_SHACK,
		Vector3(-720.0, 0.0, 680.0),
		Vector3(-1400.0, 0.0, 1100.0),
		GREASE_GROVE,
	]


static func path_length(points: Array[Vector3]) -> float:
	var total := 0.0
	for i in range(1, points.size()):
		total += straight_distance(points[i - 1], points[i])
	return total


## Irregular island coastline in XZ (Vector2 = x,z). Clockwise, closed by renderer.
## Shaped around POI spread — not a rectangle.
static func island_coastline() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-400, -4200),   ## north tip near Reels
		Vector2(900, -4300),
		Vector2(2200, -3600),
		Vector2(3400, -1800),
		Vector2(4100, 200),     ## east lobe near Mile
		Vector2(4000, 2200),
		Vector2(3600, 3800),    ## SE toward Fields / Bluffs
		Vector2(2800, 4300),
		Vector2(1200, 4200),
		Vector2(-200, 3400),
		Vector2(-1600, 2600),   ## SW toward Grove
		Vector2(-2500, 1400),
		Vector2(-2400, 200),
		Vector2(-1800, -800),
		Vector2(-900, -2200),
		Vector2(-400, -4200),
	])


static func is_on_island(world: Vector3, margin: float = 0.0) -> bool:
	return Geometry2D.is_point_in_polygon(
		Vector2(world.x, world.z),
		_inflated_coast(margin) if margin != 0.0 else island_coastline()
	)


static func _inflated_coast(margin: float) -> PackedVector2Array:
	## Simple radial inflate from centroid for exclusion checks.
	var poly := island_coastline()
	var c := Vector2.ZERO
	for p in poly:
		c += p
	c /= float(poly.size())
	var out := PackedVector2Array()
	for p in poly:
		var d := p - c
		out.append(c + d.normalized() * (d.length() + margin))
	return out


## Building / pad exclusion radii for vegetation (world XZ).
static func hub_exclusion_zones() -> Array[Dictionary]:
	return [
		{"pos": PLEASANT_PARK, "radius": 95.0},
		{"pos": GREASE_GROVE, "radius": 70.0},
		{"pos": MIRROR_MERE, "radius": 75.0},
		{"pos": MARKET_MILE, "radius": 85.0},
		{"pos": SALTY_SPRINGS, "radius": 70.0},
		{"pos": RISKY_REELS, "radius": 80.0},
		{"pos": FATAL_FIELDS, "radius": 90.0},
	]


static func road_clearance() -> float:
	## Half-width keep-out from road centerline for grass/trees.
	return 9.0
