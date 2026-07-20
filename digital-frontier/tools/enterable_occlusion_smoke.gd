extends SceneTree

func _initialize() -> void:
	await process_frame
	await process_frame
	var packed: PackedScene = load("res://scenes/world/game_world.tscn")
	var world: Node = packed.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	await process_frame
	var doors := 0
	var kinds := {}
	for n in get_nodes_in_group(&"interactables"):
		if String(n.name) == "DoorInteractable":
			doors += 1
			var parent = n.get_parent()
			if parent:
				var k = String(parent.get("interior_kind")) if parent.get("interior_kind") != null else "?"
				kinds[k] = int(kinds.get(k, 0)) + 1
	var occ := get_nodes_in_group(&"occludable").size()
	print("DOOR_COUNT=", doors)
	print("KINDS=", kinds)
	print("OCCLUDABLE=", occ)
	var ok := doors >= 30 and occ >= 20
	print("ENTERABLE_OCCLUSION_SMOKE_OK" if ok else "ENTERABLE_OCCLUSION_SMOKE_FAIL")
	quit(0 if ok else 1)
