extends Node
## Asset Standardization smoke — facing, rematerialize, scale bands, no white props.


func _ready() -> void:
	print("ASSET_STANDARDIZATION_SMOKE_START")
	await get_tree().process_frame
	var ok := true

	## Facing helper: +Z model front follows +Z travel.
	var probe := Node3D.new()
	add_child(probe)
	AssetStandardizer.face_velocity_instant(probe, Vector3(0, 0, 1))
	if absf(probe.rotation.y) > 0.05:
		push_error("face +Z should be yaw ~0, got %s" % probe.rotation.y)
		ok = false
	AssetStandardizer.face_velocity_instant(probe, Vector3(1, 0, 0))
	if absf(probe.rotation.y - PI * 0.5) > 0.08:
		push_error("face +X yaw wrong %s" % probe.rotation.y)
		ok = false
	probe.queue_free()

	## Character scales ≈ adult height band
	var hero_s := float(CharacterCatalog.character_def(&"hero_a").get("scale", 1.0))
	if hero_s > 0.75 or hero_s < 0.5:
		push_error("hero scale out of band %s" % hero_s)
		ok = false
	var villager_s := float(CharacterCatalog.character_def(&"npc_villager").get("scale", 1.0))
	if villager_s > 0.75 or villager_s < 0.5:
		push_error("villager scale out of band %s" % villager_s)
		ok = false

	## Vehicles larger than toy go-karts
	var car_s := float(ExternalPropCatalog.prop_def(&"park_car").get("scale", 1.0))
	if car_s < 2.5:
		push_error("park_car still tiny scale=%s" % car_s)
		ok = false
	var tree_s := float(ExternalPropCatalog.prop_def(&"tree_oak").get("scale", 1.0))
	if tree_s < 2.5:
		push_error("oak tree too short scale=%s" % tree_s)
		ok = false

	## Spawn rematerialized props — no pure white albedo
	var root := Node3D.new()
	add_child(root)
	for id in [&"park_car", &"bench", &"fountain", &"fridge", &"tree_pine", &"adventure_suv"]:
		var n := ExternalPropKit.spawn(root, id, Vector3.ZERO, 0.0, 1.0, String(id), Color(0.7, 0.25, 0.2))
		if n == null:
			push_error("spawn failed %s" % String(id))
			ok = false
			continue
		if _has_pure_white_material(n):
			push_error("white material remains on %s" % String(id))
			ok = false
		print("ok_prop ", id)

	## Character kit path
	var hero := CharacterKit.spawn(root, &"hero_a", Vector3(4, 0, 0), 0.0, 1.0, "Hero")
	if hero == null:
		push_error("hero spawn failed")
		ok = false

	## Interior fireplace present
	var interior := ModularInteriorBuilder.build(InteriorKinds.CABIN, &"std_cabin", 1, InteriorPersonality.Style.MODEST)
	add_child(interior)
	await get_tree().process_frame
	if interior.find_child("Fireplace", true, false) == null and interior.find_child("MediaHearth", true, false) == null:
		## Modest style should get Fireplace
		push_error("living room missing fireplace")
		ok = false
	else:
		print("interior_fireplace_ok")

	print("ASSET_STANDARDIZATION_SMOKE_" + ("OK" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)


func _has_pure_white_material(node: Node) -> bool:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var count := mi.get_surface_override_material_count() if mi.mesh else 0
		if mi.mesh:
			count = maxi(count, mi.mesh.get_surface_count())
		for si in count:
			var mat: Material = mi.get_active_material(si)
			if mat == null and mi.material_override:
				mat = mi.material_override
			if mat is BaseMaterial3D:
				var c := (mat as BaseMaterial3D).albedo_color
				var has_tex := (mat as BaseMaterial3D).albedo_texture != null
				if not has_tex and c.r > 0.93 and c.g > 0.93 and c.b > 0.93:
					return true
	for ch in node.get_children():
		if _has_pure_white_material(ch):
			return true
	return false
