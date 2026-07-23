extends Node
## World dressing / environmental storytelling smoke.


var _frames: int = 0
var _done: bool = false


func _ready() -> void:
	print("WORLD_DRESSING_SMOKE_START")


func _process(_delta: float) -> void:
	if _done:
		return
	_frames += 1
	if _frames < 2:
		return
	_done = true
	var ok := true

	var rules := BiomeDressingRules.grassland()
	if int(rules.get(&"micro_story_cap", 0)) < 10:
		push_error("grassland micro_story_cap too low")
		ok = false
	var stories := MicroStoryCatalog.grassland_stories()
	if stories.size() < 12:
		push_error("expected a rich micro-story catalog")
		ok = false
	## Every story must declare a design reason (believability rule).
	for s in stories:
		if String(s.get("reason", "")).is_empty():
			push_error("story %s missing reason" % String(s.get("id", "?")))
			ok = false

	var root := Node3D.new()
	root.name = "SmokeRoot"
	add_child(root)
	var result := {"chests": []}
	WorldDressingBuilder.build(root, result)
	await get_tree().process_frame

	var dress := root.get_node_or_null("WorldDressing")
	if dress == null:
		push_error("WorldDressing missing")
		ok = false
	else:
		for need in ["MeadowDressing", "ForestUnderstory", "AnimalTrails", "MicroStories", "NaturalLandmarks", "ScenicViewpoints", "PathGuidance"]:
			if dress.get_node_or_null(need) == null:
				push_error("%s missing" % need)
				ok = false
		var stories_root := dress.get_node_or_null("MicroStories")
		if stories_root and stories_root.get_child_count() < 8:
			push_error("too few micro-stories placed (%d)" % stories_root.get_child_count())
			ok = false
		## Meadow MultiMesh density
		var meadow := dress.get_node_or_null("MeadowDressing")
		var mm := 0
		if meadow:
			mm = _count_mm(meadow)
		if mm < 2:
			push_error("meadow MultiMesh dressing missing")
			ok = false
		else:
			print("WORLD_DRESSING_MEADOW_MM=%d" % mm)

	## Off-map: story ids must not be major/landmark catalog entries.
	var map_ids: Dictionary = {}
	for m in RegionMapCatalog.major_markers():
		map_ids[m.get("discovery_id", m.get("id", &""))] = true
	for m in RegionMapCatalog.landmark_markers():
		map_ids[m.get("discovery_id", m.get("id", &""))] = true
	for s in stories:
		var sid: StringName = s.get("id", &"")
		if map_ids.has(sid):
			push_error("micro-story %s incorrectly on map catalog" % String(sid))
			ok = false

	if (result[&"chests"] as Array).is_empty():
		push_error("expected some story/landmark reward chests")
		ok = false
	else:
		print("WORLD_DRESSING_CHESTS=%d" % (result[&"chests"] as Array).size())

	## Dress kit kinds smoke
	var kit_root := Node3D.new()
	add_child(kit_root)
	for kind in [&"camp", &"wreck", &"crystal", &"waterfall", &"meteor", &"viewpoint"]:
		var n := Node3D.new()
		n.name = String(kind)
		kit_root.add_child(n)
		WorldDressKit.dress(n, kind, 1)
		if n.get_child_count() < 1:
			push_error("dress kit empty for %s" % String(kind))
			ok = false

	## Encounter director exposes new event spawns
	var enc := WorldEncounterDirector.new()
	if not enc.has_method("_spawn_lost_traveler") or not enc.has_method("_spawn_meteor_glint"):
		push_error("encounter director missing new event methods")
		ok = false

	root.queue_free()
	kit_root.queue_free()

	if ok:
		print("WORLD_DRESSING_SMOKE_OK")
		await get_tree().create_timer(0.05).timeout
		get_tree().quit(0)
	else:
		print("WORLD_DRESSING_SMOKE_FAIL")
		await get_tree().create_timer(0.05).timeout
		get_tree().quit(1)


func _count_mm(n: Node) -> int:
	var c := 0
	if n is MultiMeshInstance3D:
		c += 1
	for ch in n.get_children():
		c += _count_mm(ch)
	return c
