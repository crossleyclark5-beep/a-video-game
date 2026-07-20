extends Node
## Living world smoke — vegetation roots, living controller, health, water tags.


var _frames: int = 0
var _done: bool = false
var _world: Node = null


func _ready() -> void:
	print("LIVING_WORLD_SMOKE_START")
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
	if _frames < 8:
		return
	_done = true
	var ok := true
	var living := _world.find_child("LivingWorld", true, false)
	if living == null:
		push_error("LivingWorld missing")
		ok = false
	else:
		var wildlife := living.get_node_or_null("Wildlife")
		if wildlife == null or wildlife.get_child_count() < 1:
			push_error("no wildlife seeded")
			ok = false
		var hostiles := living.get_node_or_null("Hostiles")
		if hostiles == null or hostiles.get_child_count() < 1:
			push_error("no hostiles seeded")
			ok = false
		var npcs := living.get_node_or_null("WorldNpcs")
		if npcs == null or npcs.get_child_count() < 1:
			push_error("no world npcs seeded")
			ok = false
	var player := _world.find_child("Player", true, false)
	if player == null or player.get_node_or_null("PlayerHealth") == null:
		push_error("PlayerHealth missing")
		ok = false
	var veg := _world.find_child("RegionVegetation", true, false)
	if veg == null:
		push_error("RegionVegetation missing")
		ok = false
	elif veg.get_node_or_null("WildernessFill") == null:
		push_error("WildernessFill missing")
		ok = false
	var waters := get_tree().get_nodes_in_group(&"water_bodies")
	if waters.is_empty():
		push_error("no water_bodies")
		ok = false
	if not ResourceRegistry.has_id(&"quest", &"field_patrol"):
		push_error("field_patrol quest missing")
		ok = false
	print("LIVING_WORLD_SMOKE_OK" if ok else "LIVING_WORLD_SMOKE_FAIL")
	get_tree().quit(0 if ok else 1)
