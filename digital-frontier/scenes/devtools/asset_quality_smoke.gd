extends Node
## Asset quality smoke — humanoid kit, Tidepup profile, wildlife silhouettes.


func _ready() -> void:
	print("ASSET_QUALITY_SMOKE_START")
	await get_tree().process_frame
	var ok := true

	## HumanoidVisual builds without crash
	var human := HumanoidVisual.new()
	add_child(human)
	human.build(Color(0.3, 0.5, 0.9), Color(0.95, 0.7, 0.2), 3)
	await get_tree().process_frame
	if human.find_child("TorsoMesh", true, false) == null:
		push_error("humanoid missing torso")
		ok = false
	if human.find_child("EyeL", true, false) == null:
		push_error("humanoid missing eyes")
		ok = false
	human.set_move_amount(0.8, false)
	human.play_interact()
	human.queue_free()

	## Tidepup profile rebuilds distinct from emberling
	var cv := CompanionVisual.new()
	add_child(cv)
	await get_tree().process_frame
	var tide := ResourceRegistry.get_creature(&"tidepup")
	if tide == null:
		push_error("tidepup data missing")
		ok = false
	else:
		cv.apply_from_creature(tide, 0)
		await get_tree().process_frame
		if cv.find_child("EarL", true, false) == null:
			push_error("tidepup missing ear flaps")
			ok = false
		if cv.find_child("Snout", true, false) == null:
			push_error("tidepup missing snout")
			ok = false
	cv.queue_free()

	## Emberling still builds
	var cv2 := CompanionVisual.new()
	add_child(cv2)
	await get_tree().process_frame
	var ember := ResourceRegistry.get_creature(&"emberling")
	if ember:
		cv2.apply_from_creature(ember, 1)
		await get_tree().process_frame
		if cv2.find_child("Belly", true, false) == null:
			push_error("emberling missing belly")
			ok = false
	cv2.queue_free()

	## Wildlife silhouette — rabbit ears
	var eco := EcosystemCreature.new()
	add_child(eco)
	eco.setup({
		"id": &"cotton_rabbit",
		"label": "Cotton Rabbit",
		"color": Color(0.92, 0.88, 0.82),
		"scale": 0.55,
		"speed": 3.0,
		"flee": 8.0,
		"rarity": 0,
		"temperament": 0,
	}, null, Vector3.ZERO)
	await get_tree().process_frame
	if eco.find_child("EarL", true, false) == null:
		push_error("rabbit missing ears")
		ok = false
	eco.queue_free()

	## CharacterVisual API
	var cv_script: Script = load("res://scenes/entities/player/character_visual.gd") as Script
	if cv_script == null:
		push_error("character visual missing")
		ok = false
	elif not cv_script.has_script_method("play_interact"):
		## has_script_method may not exist — check source via instance
		var probe := CharacterVisual.new()
		if not probe.has_method("play_interact"):
			push_error("play_interact missing")
			ok = false
		probe.free()

	if ok:
		print("ASSET_QUALITY_SMOKE_OK")
		get_tree().quit(0)
	else:
		print("ASSET_QUALITY_SMOKE_FAIL")
		get_tree().quit(1)
