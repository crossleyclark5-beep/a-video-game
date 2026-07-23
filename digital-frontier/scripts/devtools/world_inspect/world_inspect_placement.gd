class_name WorldInspectPlacement
extends Node3D
## Placement review — find floating, buried, overlapping, odd-scale objects near the camera.


const SCAN_RADIUS := 180.0
const FLOAT_EPS := 0.55
const BURY_EPS := 0.85
const MAX_HIGHLIGHTS := 80

var _highlight_root: Node3D = null
var _last_issues: Array[Dictionary] = []


func clear_highlights() -> void:
	_last_issues.clear()
	if _highlight_root:
		_highlight_root.queue_free()
		_highlight_root = null


func get_issues() -> Array[Dictionary]:
	return _last_issues


func scan(scene_root: Node, cam_pos: Vector3) -> int:
	clear_highlights()
	_highlight_root = Node3D.new()
	_highlight_root.name = "PlacementHighlights"
	add_child(_highlight_root)
	if scene_root == null:
		return 0
	var candidates: Array[Node3D] = []
	_gather(scene_root, cam_pos, candidates)
	var issues: Array[Dictionary] = []
	for node in candidates:
		_check_height(node, issues)
		_check_scale(node, issues)
		_check_rotation(node, issues)
	_check_overlaps(candidates, issues)
	## Cap highlights for readability / perf.
	var shown := 0
	for issue in issues:
		if shown >= MAX_HIGHLIGHTS:
			break
		_spawn_highlight(issue)
		shown += 1
	_last_issues = issues
	print("WORLD_INSPECT_PLACEMENT issues=%d shown=%d" % [issues.size(), shown])
	return issues.size()


func _gather(node: Node, cam_pos: Vector3, out: Array[Node3D]) -> void:
	if node is MultiMeshInstance3D:
		return ## Instanced forests — skip per-instance noise.
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		## Skip inspect overlays + tiny decorative litter.
		if _is_inspect_helper(mi):
			return
		if mi.global_position.distance_to(cam_pos) <= SCAN_RADIUS:
			out.append(mi)
	for child in node.get_children():
		_gather(child, cam_pos, out)


func _is_inspect_helper(n: Node) -> bool:
	var p: Node = n
	while p:
		var nm := String(p.name)
		if nm.begins_with("Inspect") or nm == "PlacementHighlights" or nm == "Overlays":
			return true
		p = p.get_parent()
	return false


func _check_height(node: Node3D, issues: Array[Dictionary]) -> void:
	var gp := node.global_position
	## Use AABB bottom for meshes; origin for others.
	var bottom_y := gp.y
	if node is MeshInstance3D:
		var aabb: AABB = (node as MeshInstance3D).get_aabb() * node.global_transform
		bottom_y = aabb.position.y
	var ground := GrasslandHeightField.height_at(gp.x, gp.z)
	## Skip high authored mountain set-pieces / interiors (large positive intentional).
	if absf(ground) < 0.2 and absf(bottom_y) < 0.15:
		return ## Hub pad — fine.
	var delta := bottom_y - ground
	if delta > FLOAT_EPS and delta < 25.0:
		## Ignore canopy / upper floors (parent may be building).
		if _looks_like_upper_piece(node):
			return
		issues.append({
			"kind": &"floating",
			"node": node,
			"pos": gp,
			"detail": "ΔY +%.2f above ground %.2f" % [delta, ground],
		})
	elif delta < -BURY_EPS and delta > -12.0:
		issues.append({
			"kind": &"buried",
			"node": node,
			"pos": gp,
			"detail": "ΔY %.2f below ground %.2f" % [delta, ground],
		})


func _looks_like_upper_piece(node: Node3D) -> bool:
	var n: Node = node
	while n:
		var nm := String(n.name).to_lower()
		if "roof" in nm or "floor_" in nm or "story" in nm or "canopy" in nm or "c1" == nm or "c2" == nm or "c3" == nm:
			return true
		if "summit" in nm or "shelf" in nm or "trail_" in nm:
			return true
		n = n.get_parent()
	return false


func _check_scale(node: Node3D, issues: Array[Dictionary]) -> void:
	if not (node is MeshInstance3D):
		return
	var aabb: AABB = (node as MeshInstance3D).get_aabb() * node.global_transform
	var s := aabb.size
	## Flag absurd dimensions (likely wrong scale or unit mismatch).
	if s.x > 400.0 or s.z > 400.0 or s.y > 120.0:
		## Terrain chunks are large — ignore.
		if String(node.name) == "Mesh" and node.get_parent() and String(node.get_parent().name).begins_with("TerrainChunk"):
			return
		issues.append({
			"kind": &"scale",
			"node": node,
			"pos": node.global_position,
			"detail": "huge %.0fx%.0fx%.0f" % [s.x, s.y, s.z],
		})
	elif s.x < 0.02 and s.y < 0.02 and s.z < 0.02:
		issues.append({
			"kind": &"scale",
			"node": node,
			"pos": node.global_position,
			"detail": "tiny %.3f" % maxf(s.x, maxf(s.y, s.z)),
		})


func _check_rotation(node: Node3D, issues: Array[Dictionary]) -> void:
	var e := node.global_rotation_degrees
	## Flag objects tipped on their side unexpectedly (not ramps/switchbacks).
	if absf(e.z) > 55.0 or (absf(e.x) > 55.0 and not _looks_like_ramp(node)):
		issues.append({
			"kind": &"rotation",
			"node": node,
			"pos": node.global_position,
			"detail": "euler (%.0f, %.0f, %.0f)" % [e.x, e.y, e.z],
		})


func _looks_like_ramp(node: Node3D) -> bool:
	var n: Node = node
	while n:
		var nm := String(n.name).to_lower()
		if "ramp" in nm or "trail" in nm or "slope" in nm:
			return true
		n = n.get_parent()
	return false


func _check_overlaps(candidates: Array[Node3D], issues: Array[Dictionary]) -> void:
	## Cheap pairwise check on a thinned set (buildings / props, not every grass blade).
	var solids: Array[Node3D] = []
	for n in candidates:
		if not (n is MeshInstance3D):
			continue
		var aabb: AABB = (n as MeshInstance3D).get_aabb() * n.global_transform
		var vol := aabb.size.x * aabb.size.y * aabb.size.z
		if vol < 0.8 or vol > 5000.0:
			continue
		if _looks_like_upper_piece(n):
			continue
		solids.append(n)
	var limit := mini(solids.size(), 60)
	for i in limit:
		var a := solids[i] as MeshInstance3D
		var aa: AABB = a.get_aabb() * a.global_transform
		for j in range(i + 1, limit):
			var b := solids[j] as MeshInstance3D
			## Same parent cluster often intentional (tree trunk+canopy).
			if a.get_parent() == b.get_parent():
				continue
			var bb: AABB = b.get_aabb() * b.global_transform
			if aa.intersects(bb):
				var inter := aa.intersection(bb)
				var iv := inter.size.x * inter.size.y * inter.size.z
				if iv < 0.35:
					continue
				issues.append({
					"kind": &"overlap",
					"node": a,
					"pos": inter.get_center(),
					"detail": "%s ∩ %s" % [String(a.name), String(b.name)],
				})
				break ## One overlap flag per solid is enough.


func _spawn_highlight(issue: Dictionary) -> void:
	var kind: StringName = issue.get("kind", &"?")
	var pos: Vector3 = issue.get("pos", Vector3.ZERO)
	var color := Color(1, 0.3, 0.3, 0.55)
	match kind:
		&"floating":
			color = Color(1.0, 0.45, 0.15, 0.55)
		&"buried":
			color = Color(0.4, 0.3, 1.0, 0.55)
		&"overlap":
			color = Color(1.0, 0.2, 0.55, 0.5)
		&"scale":
			color = Color(1.0, 0.9, 0.2, 0.5)
		&"rotation":
			color = Color(0.2, 0.95, 0.85, 0.5)
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.1
	sphere.height = 2.2
	mi.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mi.material_override = mat
	mi.global_position = pos + Vector3(0, 1.5, 0)
	_highlight_root.add_child(mi)
	var label := Label3D.new()
	label.text = "%s\n%s" % [String(kind), String(issue.get("detail", ""))]
	label.font_size = 28
	label.modulate = color
	label.outline_size = 5
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0, 2.2, 0)
	mi.add_child(label)
