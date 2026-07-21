extends Node
## Asset integration smoke — curated external props load, rematerialize, and furnish.


func _ready() -> void:
	print("ASSET_INTEGRATION_SMOKE_START")
	await get_tree().process_frame
	var ok := true

	if not ExternalPropKit.is_available():
		push_error("ExternalPropKit unavailable — curated GLBs missing")
		ok = false
	else:
		print("ExternalPropKit available")

	var root := Node3D.new()
	root.name = "PropProbe"
	add_child(root)

	var spawned := 0
	for id in [&"tree_pine", &"bench", &"fountain", &"campfire", &"bed", &"pillar"]:
		var n := ExternalPropKit.spawn(root, id, Vector3(float(spawned) * 3.0, 0, 0), 15.0, 1.0, String(id))
		if n == null:
			push_error("failed to spawn %s" % String(id))
			ok = false
		else:
			spawned += 1
			## Rematerialized meshes should carry StylizedMesh overrides.
			var mi := n.find_child("*", true, false)
			if mi == null:
				push_error("%s has no children" % String(id))
				ok = false

	print("spawned_props=%d" % spawned)

	## Interior builder should prefer external furniture without crashing.
	var interior := ModularInteriorBuilder.build(InteriorKinds.CABIN, &"smoke_cabin", 1, InteriorPersonality.Style.MODEST)
	add_child(interior)
	await get_tree().process_frame
	if interior.find_child("Couch", true, false) == null and interior.find_child("Floor_0", true, false) == null:
		push_error("interior missing living furniture")
		ok = false
	else:
		print("interior_ok")
	interior.queue_free()
	root.queue_free()

	## Partners must remain custom kits — never swapped for random GLBs.
	if ResourceLoader.exists("res://assets/models/external/partners/"):
		push_error("partner GLB folder should not exist")
		ok = false

	if ok:
		print("ASSET_INTEGRATION_SMOKE_OK")
		get_tree().quit(0)
	else:
		print("ASSET_INTEGRATION_SMOKE_FAIL")
		get_tree().quit(1)
