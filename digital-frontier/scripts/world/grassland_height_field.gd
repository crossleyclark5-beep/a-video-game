class_name GrasslandHeightField
extends RefCounted
## Deterministic world-space height sampler for the Grassland Region.
## True 3D terrain foundation — camera may stay 2.5D ortho; the ground is not flat.
##
## Contract:
##   height_at(x, z) → meters above hub sea-level (Pleasant Park pad ≈ 0)
##   Hub pads + road corridors are forced near 0 so existing towns/roads keep working.
##   Mountain landmarks, rolling hills, valleys, and river dips live outside those flats.


const HUB_FLAT_BLEND := 1.15 ## Multiply exclusion radius for soft flatten
const ROAD_FLAT_HALF := 22.0 ## Meters from road centerline fully flattened
const ROAD_FLAT_FALLOFF := 48.0 ## Soft blend beyond road flat

## Authored peak / valley influencers (world XZ + peak height + radius).
const PEAKS: Array[Dictionary] = [
	{"pos": Vector3(-420, 0, 80), "h": 28.0, "r": 220.0}, ## West Ridge foothills
	{"pos": Vector3(80, 0, -1450), "h": 32.0, "r": 280.0}, ## North Pass massif
	{"pos": Vector3(3400, 0, 4100), "h": 36.0, "r": 320.0}, ## South Bluffs
	{"pos": Vector3(-900, 0, -800), "h": 14.0, "r": 180.0}, ## NW rolling range
	{"pos": Vector3(2400, 0, -900), "h": 12.0, "r": 200.0}, ## NE foothills
	{"pos": Vector3(1800, 0, 2200), "h": 10.0, "r": 160.0}, ## SE prairie rise
	{"pos": Vector3(-1400, 0, 900), "h": 11.0, "r": 170.0}, ## Grove approach hills
	{"pos": Vector3(600, 0, 1600), "h": 8.0, "r": 140.0}, ## Salty approach
]

const VALLEYS: Array[Dictionary] = [
	{"pos": Vector3(620, 0, -420), "h": -2.2, "r": 90.0}, ## Stream Crossing
	{"pos": Vector3(720, 0, -720), "h": -2.0, "r": 100.0}, ## Creek Bridge
	{"pos": Vector3(1380, 0, -1380), "h": -1.4, "r": 120.0}, ## Mirror Mere bowl
	{"pos": Vector3(400, 0, 400), "h": -1.0, "r": 110.0}, ## Park SE draw
	{"pos": Vector3(2000, 0, 1200), "h": -1.2, "r": 130.0}, ## Fields approach
]

static var _noise: FastNoiseLite
static var _noise_detail: FastNoiseLite
static var _road_cache: Array = []


static func height_at(x: float, z: float) -> float:
	_ensure_noise()
	var raw := _raw_height(x, z)
	var flat := _flatten_weight(x, z)
	## Preserve a little micro-relief even on corridors so the world never reads as a table.
	var micro := _noise_detail.get_noise_2d(x, z) * 0.12 * (1.0 - flat * 0.85)
	return lerpf(raw, 0.0, flat) + micro


static func height_at_v(pos: Vector3) -> float:
	return height_at(pos.x, pos.z)


static func snap(pos: Vector3) -> Vector3:
	return Vector3(pos.x, height_at(pos.x, pos.z), pos.z)


static func snap_y(pos: Vector3, y_offset: float = 0.0) -> Vector3:
	return Vector3(pos.x, height_at(pos.x, pos.z) + y_offset, pos.z)


static func slope_approx(x: float, z: float, eps: float = 2.0) -> Vector3:
	## Approximate surface normal from finite differences (for prop tilt / flight prep).
	var h_l := height_at(x - eps, z)
	var h_r := height_at(x + eps, z)
	var h_d := height_at(x, z - eps)
	var h_u := height_at(x, z + eps)
	var n := Vector3(h_l - h_r, 2.0 * eps, h_d - h_u).normalized()
	return n


static func _ensure_noise() -> void:
	if _noise != null:
		return
	_noise = FastNoiseLite.new()
	_noise.seed = 0xDF01
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.00055
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.fractal_lacunarity = 2.1
	_noise.fractal_gain = 0.48
	_noise_detail = FastNoiseLite.new()
	_noise_detail.seed = 0xDF02
	_noise_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise_detail.frequency = 0.012
	_noise_detail.fractal_octaves = 2
	_road_cache = RegionMapCatalog.road_polylines()


static func _raw_height(x: float, z: float) -> float:
	## Broad rolling countryside (meters).
	var n := _noise.get_noise_2d(x, z)
	var n2 := _noise.get_noise_2d(x * 0.37 + 400.0, z * 0.37 - 200.0)
	var rolling := n * 7.5 + n2 * 3.2
	## Gentle continent tilt — south-east rises toward Fatal Fields / Bluffs.
	var tilt := clampf((z + 2000.0) / 8000.0, 0.0, 1.0) * 2.5
	tilt += clampf((x + 500.0) / 7000.0, 0.0, 1.0) * 1.8
	var h := rolling + tilt
	for peak in PEAKS:
		var p: Vector3 = peak["pos"]
		var ph: float = float(peak["h"])
		var pr: float = float(peak["r"])
		var d := Vector2(x - p.x, z - p.z).length()
		if d < pr:
			var t := 1.0 - (d / pr)
			## Smooth peak falloff — looks like real foothills from the air.
			h += ph * t * t * (3.0 - 2.0 * t)
	for valley in VALLEYS:
		var vp: Vector3 = valley["pos"]
		var vh: float = float(valley["h"])
		var vr: float = float(valley["r"])
		var vd := Vector2(x - vp.x, z - vp.z).length()
		if vd < vr:
			var vt := 1.0 - (vd / vr)
			h += vh * vt * vt
	## River ribbon along Mere corridor — continuous dip between stream landmarks.
	h += _river_dip(x, z)
	return h


static func _river_dip(x: float, z: float) -> float:
	## Soft channel Park → Stream → Creek → Mere for aerial / ground silhouette.
	var path: Array[Vector3] = [
		Vector3(280, 0, -180),
		GrasslandLayout.LANDMARK_STREAM_CROSSING,
		GrasslandLayout.LANDMARK_CREEK_BRIDGE,
		Vector3(1100, 0, -1100),
		GrasslandLayout.MIRROR_MERE,
	]
	var best := 1.0e9
	for i in range(1, path.size()):
		best = mini(best, _dist_xz_segment(x, z, path[i - 1], path[i]))
	if best > 55.0:
		return 0.0
	var t := 1.0 - (best / 55.0)
	return -1.8 * t * t


static func _flatten_weight(x: float, z: float) -> float:
	var w := 0.0
	for zone in GrasslandLayout.hub_exclusion_zones():
		var hub: Vector3 = zone["pos"]
		var r: float = float(zone["radius"]) * HUB_FLAT_BLEND
		var d := Vector2(x - hub.x, z - hub.z).length()
		if d < r:
			var t := 1.0 - (d / r)
			w = maxf(w, t * t * (3.0 - 2.0 * t))
	for path in _road_cache:
		for i in range(1, path.size()):
			var d2 := _dist_xz_segment(x, z, path[i - 1], path[i])
			if d2 <= ROAD_FLAT_HALF:
				w = maxf(w, 1.0)
			elif d2 < ROAD_FLAT_FALLOFF:
				var t2 := 1.0 - ((d2 - ROAD_FLAT_HALF) / (ROAD_FLAT_FALLOFF - ROAD_FLAT_HALF))
				w = maxf(w, t2 * t2)
	## Authored water set pieces stay near 0 so existing planes line up.
	for landmark in [
		GrasslandLayout.LANDMARK_STREAM_CROSSING,
		GrasslandLayout.LANDMARK_CREEK_BRIDGE,
		GrasslandLayout.MIRROR_MERE,
	]:
		var ld := Vector2(x - landmark.x, z - landmark.z).length()
		if ld < 55.0:
			var lt := 1.0 - (ld / 55.0)
			w = maxf(w, lt * 0.92)
	return clampf(w, 0.0, 1.0)


static func _dist_xz_segment(x: float, z: float, a: Vector3, b: Vector3) -> float:
	var ap := Vector2(x - a.x, z - a.z)
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var ab_len2 := ab.length_squared()
	if ab_len2 < 0.0001:
		return ap.length()
	var t := clampf(ap.dot(ab) / ab_len2, 0.0, 1.0)
	var closest := Vector2(a.x, a.z) + ab * t
	return Vector2(x, z).distance_to(closest)
