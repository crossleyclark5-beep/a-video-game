class_name WorldInspectOverlays
extends Node3D
## Toggleable developer overlays for World Inspection Mode.


var _grid_root: Node3D = null
var _height_root: Node3D = null
var _pick_label: Label3D = null
var _pick_box: MeshInstance3D = null
var _scale_label: Label3D = null
var _grid_cell: float = 50.0
var _grid_extent: int = 8
var _height_last_origin := Vector3(1e9, 0, 1e9)


func clear_all() -> void:
	enable_grid(false)
	enable_height(false)
	clear_pick()


func enable_grid(on: bool) -> void:
	if on:
		if _grid_root == null:
			_grid_root = Node3D.new()
			_grid_root.name = "InspectGrid"
			add_child(_grid_root)
		_rebuild_grid(Vector3.ZERO)
	elif _grid_root:
		_grid_root.queue_free()
		_grid_root = null


func enable_height(on: bool) -> void:
	if on:
		if _height_root == null:
			_height_root = Node3D.new()
			_height_root.name = "InspectHeight"
			add_child(_height_root)
		_height_last_origin = Vector3(1e9, 0, 1e9)
	elif _height_root:
		_height_root.queue_free()
		_height_root = null


func update_grid(cam_pos: Vector3) -> void:
	if _grid_root == null:
		return
	var snapped := Vector3(snappedf(cam_pos.x, _grid_cell), 0.0, snappedf(cam_pos.z, _grid_cell))
	if _grid_root.global_position.distance_to(snapped) > _grid_cell * 0.5:
		_rebuild_grid(snapped)


func update_height_field(cam_pos: Vector3) -> void:
	if _height_root == null:
		return
	var origin := Vector3(snappedf(cam_pos.x, 40.0), 0.0, snappedf(cam_pos.z, 40.0))
	if origin.distance_to(_height_last_origin) < 20.0:
		return
	_height_last_origin = origin
	for c in _height_root.get_children():
		c.queue_free()
	## Colored pillars sample GrasslandHeightField — elevation read from the air.
	var step := 40.0
	var radius := 8
	for iz in range(-radius, radius + 1):
		for ix in range(-radius, radius + 1):
			var x := origin.x + float(ix) * step
			var z := origin.z + float(iz) * step
			var h := GrasslandHeightField.height_at(x, z)
			var pillar := MeshInstance3D.new()
			var box := BoxMesh.new()
			var tall := maxf(0.35, absf(h) + 0.35)
			box.size = Vector3(3.5, tall, 3.5)
			pillar.mesh = box
			pillar.position = Vector3(x, h * 0.5, z)
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = _height_color(h)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.55
			pillar.material_override = mat
			_height_root.add_child(pillar)


func update_pick(camera: Camera3D, show_info: bool, show_scale: bool) -> void:
	if camera == null:
		return
	var hit := _ray_pick(camera)
	if hit.is_empty():
		clear_pick()
		return
	var node: Node = hit.get("collider")
	var pos: Vector3 = hit.get("position", camera.global_position + -camera.global_transform.basis.z * 10.0)
	var target := _resolve_display_node(node)
	var aabb := _world_aabb(target)
	if show_info:
		_ensure_pick_label()
		_pick_label.visible = true
		_pick_label.global_position = pos + Vector3(0, 1.2, 0)
		_pick_label.text = _format_info(target, pos)
	elif _pick_label:
		_pick_label.visible = false
	if show_scale:
		_ensure_pick_box()
		_ensure_scale_label()
		_pick_box.visible = true
		_scale_label.visible = true
		_fit_box_to_aabb(_pick_box, aabb)
		_scale_label.global_position = aabb.get_center() + Vector3(0, aabb.size.y * 0.5 + 0.8, 0)
		_scale_label.text = "size %.1f × %.1f × %.1f" % [aabb.size.x, aabb.size.y, aabb.size.z]
	else:
		if _pick_box:
			_pick_box.visible = false
		if _scale_label:
			_scale_label.visible = false


func clear_pick() -> void:
	if _pick_label:
		_pick_label.visible = false
	if _pick_box:
		_pick_box.visible = false
	if _scale_label:
		_scale_label.visible = false


func _rebuild_grid(center: Vector3) -> void:
	if _grid_root == null:
		return
	for c in _grid_root.get_children():
		c.queue_free()
	_grid_root.global_position = Vector3(center.x, 0.05, center.z)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.2, 0.85, 0.95, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var half := float(_grid_extent) * _grid_cell
	for i in range(-_grid_extent, _grid_extent + 1):
		var o := float(i) * _grid_cell
		_add_line(Vector3(-half, 0, o), Vector3(half, 0, o), mat)
		_add_line(Vector3(o, 0, -half), Vector3(o, 0, half), mat)
	## Origin cross in warmer color.
	var origin_mat := mat.duplicate() as StandardMaterial3D
	origin_mat.albedo_color = Color(1.0, 0.75, 0.2, 0.85)
	_add_line(Vector3(-_grid_cell, 0.02, 0), Vector3(_grid_cell, 0.02, 0), origin_mat)
	_add_line(Vector3(0, 0.02, -_grid_cell), Vector3(0, 0.02, _grid_cell), origin_mat)


func _add_line(a: Vector3, b: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	mesh.surface_add_vertex(a)
	mesh.surface_add_vertex(b)
	mesh.surface_end()
	mi.mesh = mesh
	_grid_root.add_child(mi)


func _ray_pick(camera: Camera3D) -> Dictionary:
	var from := camera.global_position
	var to := from + -camera.global_transform.basis.z * 400.0
	var space := camera.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 0xFFFFFFFF
	q.collide_with_areas = true
	q.collide_with_bodies = true
	return space.intersect_ray(q)


func _resolve_display_node(node: Node) -> Node:
	if node == null:
		return null
	var n: Node = node
	## Prefer named gameplay parents over CollisionShape leaves.
	while n.get_parent() != null:
		var nm := String(n.name)
		var leaf := n is CollisionShape3D or nm == "Collision" or nm.begins_with("@")
		if not leaf:
			break
		n = n.get_parent()
	return n


func _format_info(node: Node, hit_pos: Vector3) -> String:
	if node == null:
		return "—"
	var type_name := node.get_class()
	if node.get_script():
		var scr: Script = node.get_script()
		if scr and scr.get_global_name() != &"":
			type_name = String(scr.get_global_name())
	var gp := hit_pos
	if node is Node3D:
		gp = (node as Node3D).global_position
	var ground := GrasslandHeightField.height_at(gp.x, gp.z)
	return "%s\n%s\n(%.1f, %.1f, %.1f)\nground Y %.2f  Δ %.2f" % [
		String(node.name),
		type_name,
		gp.x, gp.y, gp.z,
		ground,
		gp.y - ground,
	]


func _world_aabb(node: Node) -> AABB:
	if node is Node3D:
		var n3 := node as Node3D
		if node is VisualInstance3D:
			return (node as VisualInstance3D).get_aabb() * n3.global_transform
		## Merge child mesh aabbs.
		var merged := AABB()
		var has := false
		for mi in n3.find_children("*", "MeshInstance3D", true, false):
			var aabb: AABB = (mi as MeshInstance3D).get_aabb() * (mi as MeshInstance3D).global_transform
			if not has:
				merged = aabb
				has = true
			else:
				merged = merged.merge(aabb)
		if has:
			return merged
		return AABB(n3.global_position - Vector3(0.5, 0.5, 0.5), Vector3.ONE)
	return AABB(Vector3.ZERO, Vector3.ONE)


func _ensure_pick_label() -> void:
	if _pick_label:
		return
	_pick_label = Label3D.new()
	_pick_label.name = "PickLabel"
	_pick_label.font_size = 42
	_pick_label.modulate = Color(0.95, 0.98, 1.0)
	_pick_label.outline_modulate = Color(0, 0, 0, 0.85)
	_pick_label.outline_size = 8
	_pick_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_pick_label.no_depth_test = true
	add_child(_pick_label)


func _ensure_scale_label() -> void:
	if _scale_label:
		return
	_scale_label = Label3D.new()
	_scale_label.name = "ScaleLabel"
	_scale_label.font_size = 36
	_scale_label.modulate = Color(1.0, 0.85, 0.35)
	_scale_label.outline_modulate = Color(0, 0, 0, 0.85)
	_scale_label.outline_size = 6
	_scale_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_scale_label.no_depth_test = true
	add_child(_scale_label)


func _ensure_pick_box() -> void:
	if _pick_box:
		return
	_pick_box = MeshInstance3D.new()
	_pick_box.name = "ScaleBox"
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	_pick_box.mesh = box
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.8, 0.2, 0.25)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true
	_pick_box.material_override = mat
	add_child(_pick_box)


func _fit_box_to_aabb(mi: MeshInstance3D, aabb: AABB) -> void:
	mi.global_position = aabb.get_center()
	mi.scale = aabb.size
	mi.global_rotation = Vector3.ZERO


func _height_color(h: float) -> Color:
	if h < -0.5:
		return Color(0.2, 0.35, 0.85)
	if h < 2.0:
		return Color(0.35, 0.75, 0.35)
	if h < 8.0:
		return Color(0.75, 0.7, 0.25)
	if h < 18.0:
		return Color(0.75, 0.4, 0.2)
	return Color(0.9, 0.9, 0.95)
