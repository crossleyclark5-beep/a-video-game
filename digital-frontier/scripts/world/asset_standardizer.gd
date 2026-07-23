class_name AssetStandardizer
extends RefCounted
## Digital Frontier Asset Standardization Pipeline.
## Every imported GLB should pass through here before world placement.
##
## Guarantees:
##   - No pure-white / missing materials (textures kept or DF palette applied)
##   - Toon + nearest filtering (pixel-inspired, not photoreal)
##   - Consistent facing helper for +Z model fronts
##   - Target-height scale helpers for catalog normalization


## World height targets (meters) — consistent scale bible for Grassland / hubs.
## Humans ≈ 1.6–1.7; sedan ≈ 1.45; SUV ≈ 1.70; fountain basin ≈ 1.35 (not a pond).
const HEIGHT_PLAYER := 1.70
const HEIGHT_NPC_ADULT := 1.60
const HEIGHT_NPC_CHILD := 1.25
const HEIGHT_CAR := 1.45
const HEIGHT_SUV := 1.70
const HEIGHT_TRUCK := 2.05
const HEIGHT_TREE_SMALL := 4.5
const HEIGHT_TREE_MED := 6.0
const HEIGHT_TREE_TALL := 7.5
const HEIGHT_BUSH := 0.85
const HEIGHT_BENCH := 0.55
const HEIGHT_FOUNTAIN := 1.35
const HEIGHT_POND_DEPTH := 0.18
const HEIGHT_FURNITURE := 0.90

## Kenney / DF meshes face +Z. Godot looking_at points −Z — use this instead.
static func face_velocity(node: Node3D, direction: Vector3, rot_speed: float, delta: float) -> void:
	if node == null:
		return
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return
	flat = flat.normalized()
	var target_yaw := atan2(flat.x, flat.z)
	node.rotation.y = lerp_angle(node.rotation.y, target_yaw, clampf(rot_speed * delta, 0.0, 1.0))


static func face_velocity_instant(node: Node3D, direction: Vector3) -> void:
	if node == null:
		return
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return
	flat = flat.normalized()
	node.rotation.y = atan2(flat.x, flat.z)


## Fit a raw mesh height into a target world height.
static func scale_for_height(raw_height: float, target_height: float) -> float:
	if raw_height < 0.05:
		return 1.0
	return target_height / raw_height


## Rematerialize an imported mesh tree into DF style.
## mode: &"prop" (world) | &"character" (keep textures, higher detail) | &"vehicle"
static func rematerialize(node: Node, mode: StringName = &"prop", accent: Color = Color.WHITE) -> void:
	if node is MeshInstance3D:
		_rematerialize_mesh(node as MeshInstance3D, mode, accent)
	for child in node.get_children():
		rematerialize(child, mode, accent)


static func _rematerialize_mesh(mi: MeshInstance3D, mode: StringName, accent: Color) -> void:
	var surface_count := 0
	if mi.mesh:
		surface_count = mi.mesh.get_surface_count()
	if surface_count <= 0:
		return
	## Prefer per-surface materials so multi-color Kenney kits keep identity.
	for si in surface_count:
		var src: Material = mi.get_active_material(si)
		if src == null:
			src = mi.mesh.surface_get_material(si)
		var mat := _build_df_material(src, mi.name, mode, accent)
		mi.set_surface_override_material(si, mat)
	## Clear blanket override so surface overrides win.
	mi.material_override = null


static func _build_df_material(src: Material, mesh_name: StringName, mode: StringName, accent: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.roughness = 1.0
	mat.metallic = 0.0

	var base := Color(0.62, 0.62, 0.65)
	var has_tex := false
	if src is BaseMaterial3D:
		var b := src as BaseMaterial3D
		base = b.albedo_color
		if b.albedo_texture:
			mat.albedo_texture = b.albedo_texture
			has_tex = true
		if b is StandardMaterial3D:
			var s := b as StandardMaterial3D
			if s.normal_texture:
				mat.normal_enabled = true
				mat.normal_texture = s.normal_texture
			if s.emission_enabled and s.emission_texture:
				mat.emission_enabled = true
				mat.emission_texture = s.emission_texture
				mat.emission_energy_multiplier = minf(s.emission_energy_multiplier, 0.55)
			elif s.emission_enabled and s.emission.v > 0.05:
				mat.emission_enabled = true
				mat.emission = WorldPalette.quantize(s.emission)
				mat.emission_energy_multiplier = minf(s.emission_energy_multiplier, 0.45)

	## White / missing → stylized DF palette (never leave blank white).
	if not has_tex and _is_placeholder_white(base):
		base = _palette_for(String(mesh_name), mode, accent)
	elif accent != Color.WHITE and mode == &"vehicle":
		## Soft multiply toward vehicle body color when catalog provides one.
		base = base.lerp(accent, 0.55 if _is_placeholder_white(base) else 0.25)

	mat.albedo_color = WorldPalette.quantize(base)

	## World props get subtle pattern when textureless for pixel diorama read.
	if mode == &"prop" and not has_tex:
		var pattern := _guess_pattern(String(mesh_name), base)
		if pattern != &"flat":
			return StylizedMesh.make_material(base, 1.0, 0.0, 0.0, pattern)
	return mat


static func _is_placeholder_white(c: Color) -> bool:
	## Near-white or fully desaturated mid-greys that read as untextured.
	if c.r > 0.92 and c.g > 0.92 and c.b > 0.92:
		return true
	if absf(c.r - c.g) < 0.03 and absf(c.g - c.b) < 0.03 and c.v > 0.88:
		return true
	return false


static func _palette_for(mesh_name: String, mode: StringName, accent: Color) -> Color:
	var n := mesh_name.to_lower()
	if mode == &"vehicle":
		if accent != Color.WHITE:
			return accent
		return WorldPalette.UI_ACCENT
	if "leaf" in n or "foliage" in n or "canopy" in n or "bush" in n:
		return WorldPalette.LEAF
	if "wood" in n or "trunk" in n or "log" in n or "plank" in n or "fence" in n:
		return WorldPalette.WOOD
	if "rock" in n or "stone" in n or "cliff" in n:
		return WorldPalette.ROCK
	if "grass" in n:
		return WorldPalette.GRASS
	if "metal" in n or "chrome" in n:
		return Color(0.55, 0.6, 0.68)
	if "glass" in n or "window" in n:
		return Color(0.45, 0.7, 0.85, 0.9)
	if "water" in n:
		return WorldPalette.WATER
	if "roof" in n:
		return WorldPalette.ROOF
	match mode:
		&"character":
			return Color(0.85, 0.7, 0.55)
		&"vehicle":
			return Color(0.78, 0.28, 0.22)
		_:
			## Soft pastel fill — readable, never white.
			return Color(0.55, 0.72, 0.55)


static func _guess_pattern(mesh_name: String, color: Color) -> StringName:
	var n := mesh_name.to_lower()
	if "leaf" in n or "foliage" in n or "canopy" in n or (color.g > color.r + 0.08 and color.g > 0.35):
		return &"leaf"
	if "wood" in n or "trunk" in n or "log" in n or "plank" in n:
		return &"wood"
	if "rock" in n or "stone" in n or "cliff" in n:
		return &"dirt"
	if "grass" in n:
		return &"grass"
	return &"flat"


## Fit an instantiated mesh tree to a world height target (meters).
static func fit_to_height(node: Node3D, target_height: float, scale_mul: float = 1.0) -> float:
	if node == null or target_height < 0.05:
		return 1.0
	var aabb := combined_aabb(node)
	var fit := scale_for_height(aabb.size.y, target_height) * scale_mul
	node.scale = Vector3(fit, fit, fit)
	## Ground after scale — AABB is local; world bottom = y + aabb.position.y * scale.
	node.position.y -= aabb.position.y * fit
	return fit


## Ground an instance so its AABB bottom sits on y=0 in local space.
static func ground_to_origin(node: Node3D) -> void:
	if node == null:
		return
	var aabb := combined_aabb(node)
	if aabb.size.y < 0.001:
		return
	var sy := node.scale.y if node.scale.y > 0.001 else 1.0
	node.position.y -= aabb.position.y * sy


static func combined_aabb(node: Node) -> AABB:
	return _combined_aabb(node)


static func _combined_aabb(node: Node) -> AABB:
	var result := AABB()
	var first := true
	if node is VisualInstance3D:
		var vi := node as VisualInstance3D
		var local := vi.get_aabb()
		var xf := (node as Node3D).transform
		var worldish := xf * local
		result = worldish
		first = false
	for child in node.get_children():
		var child_aabb := _combined_aabb(child)
		if child_aabb.size.length() < 0.0001:
			continue
		if first:
			result = child_aabb
			first = false
		else:
			result = result.merge(child_aabb)
	return result
