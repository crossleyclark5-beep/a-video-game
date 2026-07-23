extends Node
## Core World Framework smoke — coordinator, plugins, facades, schema.


var _frames: int = 0
var _done: bool = false


func _ready() -> void:
	print("CORE_WORLD_FRAMEWORK_SMOKE_START")


func _process(_delta: float) -> void:
	if _done:
		return
	_frames += 1
	if _frames < 2:
		return
	_done = true
	var ok := true

	## Biome + region plugin contracts
	var biome := BiomeProfile.grassland()
	if biome.id != &"grassland":
		push_error("grassland biome id wrong")
		ok = false
	if biome.wildlife_defs().is_empty():
		push_error("biome wildlife table empty")
		ok = false
	var mod := GrasslandRegionModule.new()
	if mod.get_id() != &"grassland":
		push_error("module id")
		ok = false
	if mod.get_biome() == null:
		push_error("module missing biome")
		ok = false

	## Interaction / collectible catalogs
	if InteractionKinds.id_of(InteractionKinds.Kind.TALK) != &"talk":
		push_error("interaction id")
		ok = false
	if InteractionKinds.all_kinds().size() < 10:
		push_error("interaction kinds incomplete")
		ok = false
	## Just ensure grant path does not crash.
	CollectibleKinds.grant(CollectibleKinds.Kind.BITS, {&"amount": 1})

	## Discovery facade
	var snap := DiscoveryFramework.completion_snapshot()
	if not snap.has(&"locations_total"):
		push_error("discovery snapshot missing")
		ok = false
	print("CORE_WORLD_DISCOVERY=%s" % str(snap))

	## Save schema
	var desc := WorldSaveSchema.describe()
	if int(desc.get(&"version", 0)) < 4:
		push_error("schema version expected >= 4")
		ok = false
	var gs := GameState.new()
	gs.schema_version = 3
	WorldSaveSchema.migrate(gs)
	if gs.schema_version != WorldSaveSchema.CURRENT_VERSION:
		push_error("migrate failed")
		ok = false

	## Coordinator boot (no full GameWorld — lightweight)
	var root := Node3D.new()
	root.name = "FrameworkRoot"
	add_child(root)
	var coord := WorldCoordinator.new()
	root.add_child(coord)
	await get_tree().process_frame
	if not coord.list_region_ids().has(&"grassland"):
		push_error("grassland not registered")
		ok = false
	## Build region through plugin
	var built := coord.load_region(&"grassland", root)
	await get_tree().process_frame
	if built.is_empty() or not built.has(&"player_spawn"):
		push_error("region build contract broken")
		ok = false
	else:
		print("CORE_WORLD_REGION_SPAWN=%s" % str(built.get(&"player_spawn")))
	if coord.active_region_id != &"grassland":
		push_error("active region not set")
		ok = false
	if coord.active_biome() == null or coord.active_biome().id != &"grassland":
		push_error("active biome wrong")
		ok = false

	## Events framework
	var player := Node3D.new()
	player.name = "Player"
	root.add_child(player)
	player.global_position = Vector3(0, 0.15, 0)
	var living := LivingWorldController.new()
	root.add_child(living)
	living.setup(player)
	coord.bind_player(player)
	coord.bind_living(living)
	await get_tree().process_frame
	if coord.events == null:
		push_error("events missing")
		ok = false
	elif coord.events.list_event_ids().is_empty():
		push_error("no builtin events")
		ok = false
	else:
		print("CORE_WORLD_EVENTS=%s" % ", ".join(coord.events.list_event_ids()))
		var fired := coord.trigger_event(&"festival_bells", player.global_position + Vector3(10, 0, 0))
		if not fired:
			push_error("trigger_event failed")
			ok = false

	## Spawn broker
	if not coord.spawn_broker.is_bound():
		push_error("spawn broker unbound")
		ok = false
	else:
		var wild := coord.spawn_broker.spawn_wildlife_near(player.global_position, 12.0)
		print("CORE_WORLD_SPAWN_WILD=%s" % (wild.name if wild else "null"))

	## Interaction kind mapping
	var talk := NpcTalkInteractable.new()
	root.add_child(talk)
	if coord.interaction_kind_for(talk) != InteractionKinds.Kind.TALK:
		push_error("talk kind map failed")
		ok = false

	## Export / import
	var exported := coord.export_state()
	if int(exported.get(&"schema", 0)) < 4:
		push_error("export schema")
		ok = false
	coord.import_state(exported)

	## Find helper
	if WorldCoordinator.find_in_tree(get_tree()) != coord:
		push_error("find_in_tree failed")
		ok = false

	print("CORE_WORLD_SNAPSHOT_KEYS=%s" % str(coord.snapshot().keys()))

	root.queue_free()

	if ok:
		print("CORE_WORLD_FRAMEWORK_SMOKE_OK")
		await get_tree().create_timer(0.05).timeout
		get_tree().quit(0)
	else:
		print("CORE_WORLD_FRAMEWORK_SMOKE_FAIL")
		await get_tree().create_timer(0.05).timeout
		get_tree().quit(1)
