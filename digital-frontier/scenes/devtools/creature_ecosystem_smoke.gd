extends Node
## Creature ecosystem smoke — catalog, index, living spawn, boss, night/weather APIs.


var _frames: int = 0
var _done: bool = false
var _world: Node = null


func _ready() -> void:
	print("CREATURE_ECOSYSTEM_SMOKE_START")
	var packed: PackedScene = load("res://scenes/world/game_world.tscn") as PackedScene
	if packed == null:
		push_error("missing game_world")
		get_tree().quit(1)
		return
	_world = packed.instantiate()
	add_child(_world)


func _process(_delta: float) -> void:
	if _done:
		return
	_frames += 1
	if _frames < 10:
		return
	_done = true
	var ok := true
	if EcosystemCatalog.grassland_species().size() < 8:
		push_error("ecosystem catalog thin")
		ok = false
	var living := _world.find_child("LivingWorld", true, false)
	if living == null:
		push_error("LivingWorld missing")
		ok = false
	else:
		var wildlife := living.get_node_or_null("Wildlife")
		if wildlife == null or wildlife.get_child_count() < 1:
			push_error("no ecosystem wildlife")
			ok = false
		else:
			var child0 = wildlife.get_child(0)
			if not (child0 is EcosystemCreature):
				push_error("wildlife is not EcosystemCreature")
				ok = false
		var hostiles := living.get_node_or_null("Hostiles")
		if hostiles == null or hostiles.get_node_or_null("HollowWarden") == null:
			push_error("Hollow Warden boss missing")
			ok = false
		if living.get_node_or_null("EncounterDirector") == null:
			push_error("EncounterDirector missing")
			ok = false
	## Index record API
	var first := CollectionManager.record_creature_sighting({
		&"id": &"cotton_rabbit",
		&"name": "Cotton Rabbit",
		&"blurb": "test",
		&"rarity": 0,
		&"rarity_label": "Common",
		&"habitat": "Grassland",
		&"temperament_label": "Passive",
	}, Vector3.ZERO, false)
	if not first and CollectionManager.get_creature_index_progress().x < 1:
		push_error("creature index failed")
		ok = false
	var sheet := DFFormat.creature_index_sheet()
	if not sheet.contains("CREATURE INDEX"):
		push_error("index sheet broken")
		ok = false
	## Atmosphere night + weather APIs
	if WorldAtmosphere.current_phase_index() < 0:
		push_error("phase api broken")
		ok = false
	var _w := WorldAtmosphere.current_weather_id()
	if not ResourceRegistry.has_id(&"boss", &"hollow_warden"):
		push_error("boss data missing")
		ok = false
	if not ResourceRegistry.has_id(&"quest", &"index_novice"):
		push_error("index_novice quest missing")
		ok = false
	print("CREATURE_ECOSYSTEM_SMOKE_OK" if ok else "CREATURE_ECOSYSTEM_SMOKE_FAIL")
	get_tree().quit(0 if ok else 1)
