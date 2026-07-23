extends Node
## World streaming foundation smoke — budget, bands, LOD policy, AI pause, pool.


var _frames: int = 0
var _done: bool = false


func _ready() -> void:
	print("WORLD_STREAMING_SMOKE_START")


func _process(_delta: float) -> void:
	if _done:
		return
	_frames += 1
	if _frames < 2:
		return
	_done = true
	var ok := true

	if AdventureNodeBudget.AUTHORED_NODE_GATE < 10000:
		push_error("authored gate unexpectedly low")
		ok = false
	if AdventureNodeBudget.guideline(&"vegetation").is_empty():
		push_error("guidelines missing")
		ok = false

	## Minimal region-like tree
	var root := Node3D.new()
	root.name = "HexGridLayer"
	add_child(root)
	var terrain := Node3D.new()
	terrain.name = "GrasslandTerrain"
	root.add_child(terrain)
	for i in 3:
		var chunk := StaticBody3D.new()
		chunk.name = "TerrainChunk_%d" % i
		chunk.position = Vector3(float(i) * 400.0, 0, 0)
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(10, 1, 10)
		col.shape = shape
		chunk.add_child(col)
		terrain.add_child(chunk)
	var hub := Node3D.new()
	hub.name = "PleasantPark"
	hub.position = Vector3.ZERO
	root.add_child(hub)
	var far_hub := Node3D.new()
	far_hub.name = "FatalFields"
	far_hub.position = Vector3(3000, 0, 3000)
	root.add_child(far_hub)
	var veg := Node3D.new()
	veg.name = "RegionVegetation"
	root.add_child(veg)
	var forests := Node3D.new()
	forests.name = "DenseForests"
	veg.add_child(forests)
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Forest_0"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var box := BoxMesh.new()
	box.size = Vector3(1, 2, 1)
	mm.mesh = box
	mm.instance_count = 1
	mm.set_instance_transform(0, Transform3D.IDENTITY)
	mmi.multimesh = mm
	forests.add_child(mmi)

	var player := Node3D.new()
	player.name = "Player"
	player.position = Vector3(0, 0.15, 0)
	add_child(player)

	var stream := WorldStreamController.new()
	add_child(stream)
	stream.setup(root, player)
	await get_tree().process_frame
	stream.force_refresh()
	await get_tree().process_frame

	var stats: Dictionary = stream.get_stats()
	print("WORLD_STREAM_STATS=", stats)
	if int(stats.get(&"units", 0)) < 4:
		push_error("expected several stream units, got %s" % stats.get(&"units", 0))
		ok = false
	## Park should be NEAR; Fatal Fields should not be NEAR at origin focus.
	var park_near := false
	var fields_far := false
	for u in stream.get_units():
		if u.id == &"PleasantPark":
			park_near = u.band == AdventureNodeBudget.Band.NEAR or u.band == AdventureNodeBudget.Band.MEDIUM
		if u.id == &"FatalFields":
			fields_far = u.band == AdventureNodeBudget.Band.FAR or u.band == AdventureNodeBudget.Band.VERY_FAR
	if not park_near:
		push_error("PleasantPark should be NEAR/MEDIUM at spawn")
		ok = false
	if not fields_far:
		push_error("FatalFields should be FAR/VERY_FAR from spawn")
		ok = false

	## Airborne expands rings / LOD
	stream.set_airborne(true)
	WorldLodPolicy.apply_to_vegetation_root(veg, true)
	if mmi.visibility_range_end < AdventureNodeBudget.LOD_TREE_END:
		push_error("air LOD should not shrink tree range")
		ok = false
	if mmi.visibility_range_end < AdventureNodeBudget.LOD_TREE_END * 2.0:
		push_error("air LOD multiplier not applied")
		ok = false

	## Object pool
	var pool := WorldObjectPool.new()
	pool.setup_factory(root, func() -> Node:
		var n := Node3D.new()
		n.name = "Pooled"
		return n
	, 4)
	var a := pool.acquire()
	var b := pool.acquire()
	if a == null or b == null:
		push_error("pool acquire failed")
		ok = false
	pool.release(a)
	if pool.free_count() < 1:
		push_error("pool release failed")
		ok = false
	var c := pool.acquire()
	if c != a:
		## May be same instance reused
		pass
	pool.release(b)
	pool.release(c)

	## Perf monitor snapshot
	var perf := WorldPerfMonitor.new()
	add_child(perf)
	var snap := perf.snapshot(root)
	if not snap.has(&"fps") or not snap.has(&"stream"):
		push_error("perf snapshot incomplete")
		ok = false
	print("WORLD_STREAM_PERF_NODES=", snap.get(&"world_nodes", -1))

	## Living AI LOD helpers exist
	var living := LivingWorldController.new()
	add_child(living)
	living.setup(player)
	await get_tree().process_frame
	var pop: Dictionary = living.population_snapshot()
	if not pop.has(&"wildlife"):
		push_error("population_snapshot missing")
		ok = false
	living.set_focus_override(player)

	root.queue_free()
	if ok:
		print("WORLD_STREAMING_SMOKE_OK")
		await get_tree().create_timer(0.05).timeout
		get_tree().quit(0)
	else:
		print("WORLD_STREAMING_SMOKE_FAIL")
		await get_tree().create_timer(0.05).timeout
		get_tree().quit(1)
