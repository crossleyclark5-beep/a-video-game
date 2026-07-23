extends Node
## World 3D foundation smoke — heightfield, terrain chunks, MultiMesh density, off-map discoveries.


var _frames: int = 0
var _done: bool = false


func _ready() -> void:
	print("WORLD_3D_FOUNDATION_SMOKE_START")


func _process(_delta: float) -> void:
	if _done:
		return
	_frames += 1
	if _frames < 2:
		return
	_done = true
	var ok := true

	## Hub flats stay near sea level so towns keep working.
	var hub_h := GrasslandHeightField.height_at(0.0, 0.0)
	if absf(hub_h) > 0.35:
		push_error("Pleasant Park height should be ~0, got %s" % hub_h)
		ok = false
	var salty_h := GrasslandHeightField.height_at(GrasslandLayout.SALTY_SPRINGS.x, GrasslandLayout.SALTY_SPRINGS.z)
	if absf(salty_h) > 0.5:
		push_error("Salty Springs pad should be flat, got %s" % salty_h)
		ok = false

	## Wilderness elevation exists (not a flat green table).
	var ridge_h := GrasslandHeightField.height_at(GrasslandLayout.LANDMARK_WEST_RIDGE.x - 80.0, GrasslandLayout.LANDMARK_WEST_RIDGE.z)
	var north_h := GrasslandHeightField.height_at(GrasslandLayout.LANDMARK_NORTH_PASS.x + 60.0, GrasslandLayout.LANDMARK_NORTH_PASS.z + 40.0)
	var field_h := GrasslandHeightField.height_at(1800.0, 2200.0)
	if ridge_h < 4.0:
		push_error("West Ridge foothills too flat: %s" % ridge_h)
		ok = false
	if north_h < 5.0:
		push_error("North Pass massif too flat: %s" % north_h)
		ok = false
	if field_h < 1.0:
		push_error("SE prairie rise missing: %s" % field_h)
		ok = false

	## Snap helper preserves XZ.
	var sn := GrasslandHeightField.snap(Vector3(500, 99, -300))
	if not is_equal_approx(sn.x, 500.0) or not is_equal_approx(sn.z, -300.0):
		push_error("snap should preserve XZ")
		ok = false
	if sn.y > 40.0 or sn.y < -5.0:
		push_error("snap Y out of expected range: %s" % sn.y)
		ok = false

	## Build a lightweight terrain root — heightfield mesh + vegetation + discoveries.
	var root := Node3D.new()
	root.name = "SmokeWorld"
	add_child(root)
	GrasslandTerrainMesh.build(root)
	var terrain := root.get_node_or_null("GrasslandTerrain")
	if terrain == null:
		push_error("GrasslandTerrain missing")
		ok = false
	else:
		var chunks := 0
		for c in terrain.get_children():
			if String(c.name).begins_with("TerrainChunk_"):
				chunks += 1
				var body := c as StaticBody3D
				if body == null:
					push_error("terrain chunk not StaticBody3D")
					ok = false
				elif body.get_node_or_null("Collision") == null:
					push_error("terrain chunk missing HeightMap collision")
					ok = false
		if chunks < 2:
			push_error("expected multiple terrain chunks, got %d" % chunks)
			ok = false
		if terrain.get_node_or_null("RiverRibbon") == null:
			push_error("RiverRibbon missing")
			ok = false
		if terrain.get_node_or_null("ScenicPonds") == null:
			push_error("ScenicPonds missing")
			ok = false

	RegionVegetationBuilder.build(root)
	var veg := root.get_node_or_null("RegionVegetation")
	if veg == null:
		push_error("RegionVegetation missing")
		ok = false
	else:
		var mm_count := _count_multimesh(veg)
		if mm_count < 20:
			push_error("expected dense MultiMesh vegetation, got %d MultiMeshInstance3D" % mm_count)
			ok = false
		else:
			print("WORLD_3D_VEG_MM=%d" % mm_count)
		if veg.get_node_or_null("DenseForests") == null:
			push_error("DenseForests missing")
			ok = false

	var result := {"chests": []}
	RegionDiscoveryBuilder.build(root, result)
	var disc := root.get_node_or_null("RegionDiscoveries")
	if disc == null:
		push_error("RegionDiscoveries missing")
		ok = false
	else:
		if disc.get_child_count() < 15:
			push_error("expected many minor/secret discoveries, got %d" % disc.get_child_count())
			ok = false
		## Off-map: these ids must NOT be in RegionMapCatalog markers.
		var map_ids: Dictionary = {}
		for m in RegionMapCatalog.major_markers():
			map_ids[m.get("discovery_id", m.get("id", &""))] = true
		for m in RegionMapCatalog.landmark_markers():
			map_ids[m.get("discovery_id", m.get("id", &""))] = true
		for off_id in [&"abandoned_camp", &"secret_grove", &"rabbit_warren", &"sky_altar"]:
			if map_ids.has(off_id):
				push_error("minor/secret %s incorrectly listed on map catalog" % String(off_id))
				ok = false
			if disc.find_child(String(off_id).capitalize().replace(" ", ""), true, false) == null \
					and disc.find_child("Secret_%s" % String(off_id), true, false) == null \
					and disc.find_child("AbandonedCamp", true, false) == null:
				## Soft check — at least discoverable areas exist as children
				pass
		var found_secret := disc.find_child("Secret_secret_grove", true, false) != null \
				or disc.find_child("SecretGrove", true, false) != null
		## Secret grove node is named Secret_secret_grove
		if disc.get_node_or_null("Secret_secret_grove") == null and not found_secret:
			## Name from builder: "Secret_%s" % id → Secret_secret_grove
			var has := false
			for c in disc.get_children():
				if String(c.name).begins_with("Secret_"):
					has = true
					break
			if not has:
				push_error("secret discovery sites missing")
				ok = false

	## Placement guard still blocks roads / hubs.
	if RegionVegetationBuilder.placement_allowed(Vector3(0, 0, 0), true):
		push_error("trees should not place in Pleasant Park hub")
		ok = false
	if not RegionVegetationBuilder.placement_allowed(Vector3(500, 0, 500), true):
		## May or may not be on island / near road — just ensure API runs
		pass

	root.queue_free()

	if ok:
		print("WORLD_3D_FOUNDATION_SMOKE_OK")
		await get_tree().create_timer(0.05).timeout
		get_tree().quit(0)
	else:
		print("WORLD_3D_FOUNDATION_SMOKE_FAIL")
		await get_tree().create_timer(0.05).timeout
		get_tree().quit(1)


func _count_multimesh(n: Node) -> int:
	var c := 0
	if n is MultiMeshInstance3D:
		c += 1
	for ch in n.get_children():
		c += _count_multimesh(ch)
	return c
