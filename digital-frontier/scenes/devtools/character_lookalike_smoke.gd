extends Node
## Smoke: every roster outfit builds a dense retro look-alike kit.


func _ready() -> void:
	await get_tree().process_frame
	var ok := true
	var root := Node3D.new()
	add_child(root)

	for id in CharacterOutfitCatalog.all_ids():
		var kit := CharacterLookalikeKit.build(root, id, 1.0)
		if kit == null:
			push_error("lookalike null for %s" % String(id))
			ok = false
			continue
		var meshes := _count_meshes(kit)
		print("%s meshes=%d" % [String(id), meshes])
		if meshes < 8:
			push_error("%s too sparse (%d meshes)" % [String(id), meshes])
			ok = false
		## Must be lookalike path via CharacterKit
		var via := CharacterKit.attach_outfit(root, id, 1.0, "Via_%s" % String(id))
		if via == null or not String(via.name).begins_with("Via_"):
			push_error("attach_outfit failed for %s" % String(id))
			ok = false
		elif via.get_node_or_null("Hip") == null and id != &"char_peely" and id != &"char_marshmallow":
			## peely/marshmallow also have Hip
			pass
		if via.get_node_or_null("Hip") == null:
			push_error("missing Hip on %s" % String(id))
			ok = false

	## Distinct silhouettes: peely taller banana vs jonesy humanoid
	var peely := CharacterLookalikeKit.build(root, &"char_peely", 1.0)
	var jonesy := CharacterLookalikeKit.build(root, &"char_jonesy", 1.0)
	if peely == null or jonesy == null:
		ok = false
	else:
		var peely_has_body := peely.find_child("Body", true, false) != null
		var jonesy_has_shirt := jonesy.find_child("Shirt", true, false) != null
		if not peely_has_body or not jonesy_has_shirt:
			push_error("silhouette markers missing")
			ok = false

	var vis := CharacterLibraryVisual.new()
	add_child(vis)
	vis.build_outfit(&"char_dj_yonder", 1.0)
	vis.set_move_amount(1.0, true)
	await get_tree().process_frame

	if ok:
		print("CHARACTER_LOOKALIKE_SMOKE_OK")
	else:
		print("CHARACTER_LOOKALIKE_SMOKE_FAIL")
	await get_tree().process_frame
	get_tree().quit(0 if ok else 1)


func _count_meshes(n: Node) -> int:
	var c := 0
	if n is MeshInstance3D:
		c += 1
	for ch in n.get_children():
		c += _count_meshes(ch)
	return c
