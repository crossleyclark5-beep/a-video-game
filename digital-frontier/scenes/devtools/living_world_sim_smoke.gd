extends Node
## Living World Simulation smoke — schedules, memory, ambience, weather filter.


var _frames: int = 0
var _done: bool = false


func _ready() -> void:
	print("LIVING_WORLD_SIM_SMOKE_START")


func _process(_delta: float) -> void:
	if _done:
		return
	_frames += 1
	if _frames < 2:
		return
	_done = true
	var ok := true

	## Schedules expose believable activities.
	for sid in [&"town_loop", &"market_beat", &"guard_patrol", &"child_play", &"merchant_road"]:
		var label := NpcSchedule.activity_label(sid, NpcSchedule.Slot.MORNING)
		if label.is_empty():
			push_error("empty activity for %s" % String(sid))
			ok = false
		var pts := NpcSchedule.waypoints(sid, NpcSchedule.Slot.AFTERNOON)
		if pts.is_empty():
			push_error("no waypoints for %s" % String(sid))
			ok = false
	if not NpcSchedule.sleeps_at_night(&"town_loop"):
		push_error("townsfolk should sleep")
		ok = false
	if NpcSchedule.sleeps_at_night(&"guard_patrol"):
		push_error("guards should night-watch")
		ok = false
	if not NpcSchedule.seeks_shelter_in_rain(&"town_loop"):
		push_error("villagers should shelter")
		ok = false

	## Weather filter: rain_hide must exclude deer/birds.
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var rain_pool := 0
	for _i in 40:
		var d := EcosystemCatalog.pick_for_conditions(
			EcosystemCatalog.grassland_species(),
			WorldAtmosphere.Phase.MORNING,
			&"rain",
			rng,
			false,
		)
		if d.is_empty():
			continue
		rain_pool += 1
		var tags: Array = d.get("tags", [])
		if tags.has(&"rain_hide"):
			push_error("rain_hide species spawned in rain: %s" % String(d.get("id", "?")))
			ok = false
	print("LIVING_WORLD_SIM_RAIN_PICKS=%d" % rain_pool)

	## World memory TTL
	var zid := WorldSimMemory.zone_id_for_position(Vector3(100, 0, 100))
	WorldSimMemory.mark_cleared_zone(zid, 60.0)
	if not WorldSimMemory.is_zone_cleared(zid):
		push_error("cleared zone not remembered")
		ok = false

	## NPC catalog extras
	if LivingWorldCatalog.find_npc(&"park_kid").is_empty():
		push_error("park_kid missing")
		ok = false
	if LivingWorldCatalog.find_npc(&"park_guard").is_empty():
		push_error("park_guard missing")
		ok = false

	## Ambience + living controller wiring (lightweight — no full game world)
	var root := Node3D.new()
	add_child(root)
	var player := Node3D.new()
	player.name = "Player"
	player.position = Vector3(0, 0.15, 0)
	root.add_child(player)
	var living := LivingWorldController.new()
	living.name = "LivingWorld"
	root.add_child(living)
	living.setup(player)
	await get_tree().process_frame
	await get_tree().process_frame

	var amb := living.get_node_or_null("WorldAmbience")
	if amb == null:
		push_error("WorldAmbience missing")
		ok = false
	else:
		print("LIVING_WORLD_SIM_AMBIENCE_OK")

	var snap: Dictionary = living.population_snapshot()
	if int(snap.get(&"wildlife", 0)) < 1:
		push_error("expected seeded wildlife")
		ok = false
	if int(snap.get(&"npcs", 0)) < 2:
		push_error("expected ranger+kid/guard seeds")
		ok = false
	print("LIVING_WORLD_SIM_POP=%s" % str(snap))

	## NPC actor shelter / sleep API
	var npc := WorldNpcActor.new()
	root.add_child(npc)
	npc.setup(LivingWorldCatalog.find_npc(&"park_villager"), player, Vector3(4, 0.15, 4))
	if not npc.has_method("current_activity") or not npc.has_method("set_ai_detail"):
		push_error("WorldNpcActor missing sim APIs")
		ok = false
	else:
		npc.set_ai_detail(2)
		var act := String(npc.current_activity())
		if act.is_empty():
			push_error("empty current_activity")
			ok = false
		else:
			print("LIVING_WORLD_SIM_NPC_ACT=%s" % act)

	## Creature AI detail + patrol
	var eco := EcosystemCreature.new()
	root.add_child(eco)
	eco.setup(EcosystemCatalog.find_species(&"glitchmite"), player, Vector3(20, 0.15, 20))
	if not eco.has_method("set_ai_detail"):
		push_error("EcosystemCreature missing set_ai_detail")
		ok = false
	else:
		eco.set_ai_detail(1)

	## Wind helper
	if WorldWind.strength() < 0.0:
		push_error("wind strength invalid")
		ok = false

	root.queue_free()

	if ok:
		print("LIVING_WORLD_SIM_SMOKE_OK")
		await get_tree().create_timer(0.05).timeout
		get_tree().quit(0)
	else:
		print("LIVING_WORLD_SIM_SMOKE_FAIL")
		await get_tree().create_timer(0.05).timeout
		get_tree().quit(1)
