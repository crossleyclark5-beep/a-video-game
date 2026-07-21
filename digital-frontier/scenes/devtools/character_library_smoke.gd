extends Node
## Character library smoke — catalog, kit spawn, NPC/player hooks, partners untouched.


func _ready() -> void:
	print("CHARACTER_LIBRARY_SMOKE_START")
	await get_tree().process_frame
	var ok := true

	if not CharacterKit.is_available():
		push_error("CharacterKit unavailable")
		ok = false
	else:
		print("character_kit_available")

	for id in [&"hero_a", &"npc_merchant", &"digital_mite", &"field_ranger"]:
		if not CharacterCatalog.has_character(id):
			push_error("catalog missing %s" % String(id))
			ok = false
		elif not ResourceLoader.exists(CharacterCatalog.character_path(id)):
			push_error("glb missing %s" % String(id))
			ok = false

	var root := Node3D.new()
	add_child(root)
	var hero := CharacterKit.spawn(root, &"hero_a", Vector3.ZERO, 0.0, 1.0, "Hero")
	var npc := CharacterLibraryVisual.new()
	root.add_child(npc)
	npc.build(&"npc_explorer", 1.0)
	await get_tree().process_frame
	if hero == null or npc.find_child("LibraryMesh", true, false) == null:
		push_error("spawn/build failed")
		ok = false
	else:
		print("spawn_ok")
	npc.set_move_amount(0.8, true)
	npc.play_interact()

	## Player CharacterVisual library mode
	var cv := CharacterVisual.new()
	cv.use_character_library = true
	cv.library_character_id = &"hero_b"
	root.add_child(cv)
	await get_tree().process_frame
	if cv.find_child("LibraryVisual", true, false) == null:
		push_error("player library visual missing")
		ok = false
	else:
		print("player_library_ok")

	## NPC actor prefers library
	var actor := WorldNpcActor.new()
	root.add_child(actor)
	actor.setup({
		"id": &"smoke_merchant",
		"label": "Smoke Merchant",
		"role": "merchant",
		"color": Color(0.8, 0.5, 0.2),
		"lines": PackedStringArray(["Hi"]),
	}, null, Vector3(2, 0, 0))
	await get_tree().process_frame
	if actor.find_child("LibraryMesh", true, false) == null and actor.find_child("TorsoMesh", true, false) == null:
		push_error("npc visual missing")
		ok = false
	else:
		print("npc_library_ok")

	## Partners must remain CompanionVisual — never swapped for library creatures
	var companion := CompanionVisual.new()
	root.add_child(companion)
	await get_tree().process_frame
	var ember := ResourceRegistry.get_creature(&"emberling")
	if ember:
		companion.apply_from_creature(ember, 0)
		await get_tree().process_frame
		if companion.find_child("Belly", true, false) == null:
			push_error("emberling kit broken")
			ok = false
		else:
			print("partner_kit_ok")

	if ResourceLoader.exists("res://assets/models/external/characters/partners/"):
		push_error("partners folder must not exist in character library")
		ok = false

	root.queue_free()

	if ok:
		print("CHARACTER_LIBRARY_SMOKE_OK")
		get_tree().quit(0)
	else:
		print("CHARACTER_LIBRARY_SMOKE_FAIL")
		get_tree().quit(1)
