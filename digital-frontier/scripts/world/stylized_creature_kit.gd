class_name StylizedCreatureKit
extends RefCounted
## Shared pixel-toon creature / humanoid mesh helpers.
## Keeps wildlife, NPCs, and companions on one art language (no GLTF packs).


static func eye_pair(parent: Node3D, origin: Vector3, spacing: float, radius: float, iris: Color = Color(0.12, 0.14, 0.18)) -> void:
	StylizedMesh.add_sphere(parent, radius, iris, origin + Vector3(-spacing, 0, 0), "EyeL")
	StylizedMesh.add_sphere(parent, radius, iris, origin + Vector3(spacing, 0, 0), "EyeR")
	StylizedMesh.add_sphere(parent, radius * 0.35, Color(1, 1, 1), origin + Vector3(-spacing + radius * 0.25, radius * 0.2, radius * 0.55), "HiliteL")
	StylizedMesh.add_sphere(parent, radius * 0.35, Color(1, 1, 1), origin + Vector3(spacing + radius * 0.25, radius * 0.2, radius * 0.55), "HiliteR")


static func snout(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	return StylizedMesh.add_box(parent, size, color, pos, "Snout")


static func ear_pair(parent: Node3D, head_y: float, spacing: float, size: Vector3, color: Color, upright: bool = true) -> void:
	var tilt := 12.0 if upright else -25.0
	var l := StylizedMesh.add_box(parent, size, color, Vector3(-spacing, head_y, -0.02), "EarL")
	var r := StylizedMesh.add_box(parent, size, color, Vector3(spacing, head_y, -0.02), "EarR")
	l.rotation_degrees.z = tilt
	r.rotation_degrees.z = -tilt


static func tail(parent: Node3D, pos: Vector3, length: float, thickness: float, color: Color, bushy: bool = false) -> MeshInstance3D:
	var t := StylizedMesh.add_box(parent, Vector3(thickness, thickness, length), color, pos, "Tail")
	if bushy:
		StylizedMesh.add_sphere(parent, thickness * 1.4, color.lightened(0.08), pos + Vector3(0, 0, -length * 0.45), "TailFluff")
	return t


static func quadruped_legs(parent: Node3D, body_y: float, scale_v: float, color: Color) -> void:
	var s := scale_v
	var leg_c := color.darkened(0.12)
	for xz in [Vector2(-0.14, 0.22), Vector2(0.14, 0.22), Vector2(-0.14, -0.22), Vector2(0.14, -0.22)]:
		StylizedMesh.add_box(parent, Vector3(0.08 * s, 0.28 * s, 0.08 * s), leg_c, Vector3(xz.x * s, body_y - 0.2 * s, xz.y * s), "Leg")


static func apply_toon_override(mesh: MeshInstance3D, color: Color, pattern: StringName = &"flat") -> void:
	if mesh == null:
		return
	mesh.material_override = StylizedMesh.make_material(color, 1.0, 0.0, 0.0, pattern)
