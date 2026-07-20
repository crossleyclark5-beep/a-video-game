class_name HexUtils
extends RefCounted
## Hex grid coordinate math (axial/cube). No gameplay — pure utilities.
##
## Uses cube coordinates (x, y, z) where x + y + z = 0.
## See: https://www.redblobgames.com/grids/hexagons/

static func cube_to_world(cube: Vector3i, hex_size: float, orientation: StringName = &"pointy") -> Vector3:
	var x := float(cube.x)
	var z := float(cube.z)
	if orientation == &"pointy":
		var wx := hex_size * (sqrt(3.0) * x + sqrt(3.0) / 2.0 * z)
		var wz := hex_size * (3.0 / 2.0 * z)
		return Vector3(wx, 0.0, wz)
	else:
		var wx := hex_size * (3.0 / 2.0 * x)
		var wz := hex_size * (sqrt(3.0) / 2.0 * x + sqrt(3.0) * z)
		return Vector3(wx, 0.0, wz)


static func world_to_cube(world: Vector3, hex_size: float, orientation: StringName = &"pointy") -> Vector3i:
	## Fractional cube rounding — implement when hex picking is needed.
	return Vector3i.ZERO


static func cube_distance(a: Vector3i, b: Vector3i) -> int:
	return maxi(maxi(abs(a.x - b.x), abs(a.y - b.y)), abs(a.z - b.z))


static func cube_neighbors(cube: Vector3i) -> Array[Vector3i]:
	const DIRECTIONS: Array[Vector3i] = [
		Vector3i(1, -1, 0), Vector3i(1, 0, -1), Vector3i(0, 1, -1),
		Vector3i(-1, 1, 0), Vector3i(-1, 0, 1), Vector3i(0, -1, 1),
	]
	var result: Array[Vector3i] = []
	for dir in DIRECTIONS:
		result.append(cube + dir)
	return result
