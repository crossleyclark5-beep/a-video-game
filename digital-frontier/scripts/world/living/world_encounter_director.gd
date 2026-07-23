class_name WorldEncounterDirector
extends Node
## Ambient world vignettes — creatures fighting, rare crossings, merchant ambush, etc.
## Spawns must enter the tree before writing global_position (Node3D transform rule).

const TICK := 9.0
const FIRST_DELAY := 12.0

var _player: Node3D = null
var _root: Node3D = null
var _living: LivingWorldController = null
var _timer: float = FIRST_DELAY
var _rng := RandomNumberGenerator.new()
var _active: Node3D = null


func setup(player: Node3D, living: LivingWorldController, root: Node3D) -> void:
	_player = player
	_living = living
	_root = root
	_rng.randomize()


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _root == null or not is_instance_valid(_root) or not _root.is_inside_tree():
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = TICK + _rng.randf_range(0.0, 5.0)
	if _active != null and is_instance_valid(_active):
		if _player.global_position.distance_to(_active.global_position) > 140.0:
			_active.queue_free()
			_active = null
		return
	_try_spawn_encounter()


func _try_spawn_encounter() -> void:
	## Weighted ambient events — keep one active so the world feels alive, not noisy.
	var roll := _rng.randf()
	var offset := Vector3(_rng.randf_range(22, 45) * (1.0 if _rng.randf() > 0.5 else -1.0), 0.15, _rng.randf_range(18, 40) * (1.0 if _rng.randf() > 0.5 else -1.0))
	var pos: Vector3 = _player.global_position + offset
	if not GrasslandLayout.is_on_island(pos, -40.0):
		return
	if _near_hub(pos, 50.0):
		return
	if roll < 0.20:
		_spawn_duel(pos)
	elif roll < 0.32:
		_spawn_parent_guard(pos)
	elif roll < 0.42:
		_spawn_wounded(pos)
	elif roll < 0.52:
		_spawn_merchant_ambush(pos)
	elif roll < 0.62:
		_spawn_resting_merchant(pos)
	elif roll < 0.72:
		_spawn_lost_traveler(pos)
	elif roll < 0.84:
		_spawn_rare_crossing(pos)
	elif roll < 0.93:
		_spawn_bird_flush(pos)
	else:
		_spawn_meteor_glint(pos)


func _make_holder(holder_name: String, pos: Vector3) -> Node3D:
	## CRITICAL: add_child before global_position — otherwise Godot errors and returns identity.
	var holder := Node3D.new()
	holder.name = holder_name
	_root.add_child(holder)
	holder.global_position = pos
	_active = holder
	return holder


func _spawn_duel(pos: Vector3) -> void:
	var holder := _make_holder("EncounterDuel", pos)
	var a_def := EcosystemCatalog.pick_for_conditions(EcosystemCatalog.grassland_species(), _phase(), _weather(), _rng, true)
	var b_def := EcosystemCatalog.pick_for_conditions(EcosystemCatalog.grassland_species(), _phase(), _weather(), _rng, false)
	if a_def.is_empty():
		a_def = EcosystemCatalog.find_species(&"glitchmite")
	if b_def.is_empty():
		b_def = EcosystemCatalog.find_species(&"cotton_rabbit")
	_spawn_eco(holder, a_def, pos + Vector3(-2, 0, 0))
	_spawn_eco(holder, b_def, pos + Vector3(2, 0, 0))
	EventBus.ui_notification_requested.emit("Nearby: creatures sparring in the grass!", 2.2)


func _spawn_parent_guard(pos: Vector3) -> void:
	var holder := _make_holder("EncounterGuard", pos)
	var adult := EcosystemCatalog.find_species(&"park_deer")
	var young := EcosystemCatalog.find_species(&"cotton_rabbit")
	_spawn_eco(holder, adult, pos)
	_spawn_eco(holder, young, pos + Vector3(1.5, 0, 1.0))
	EventBus.ui_notification_requested.emit("A creature shields its young…", 2.0)


func _spawn_wounded(pos: Vector3) -> void:
	var holder := _make_holder("EncounterWounded", pos)
	## Grassland-only — never pull future-biome stubs into chapter 1 vignettes.
	var def := EcosystemCatalog.find_species(&"glow_kit")
	if def.is_empty():
		def = EcosystemCatalog.find_species(&"pack_pup")
	var actor := _spawn_eco(holder, def, pos)
	if actor:
		actor._activity = EcosystemCreature.Activity.SLEEP
		actor._activity_timer = 12.0
	EventBus.ui_notification_requested.emit("A wounded critter rests by the path.", 2.0)


func _spawn_merchant_ambush(pos: Vector3) -> void:
	var holder := _make_holder("EncounterAmbush", pos)
	var npc_def := LivingWorldCatalog.grassland_npcs()[2]
	var npc := WorldNpcActor.new()
	npc.name = "AmbushedMerchant"
	holder.add_child(npc)
	npc.setup(npc_def, _player, pos)
	var foe := EcosystemCatalog.find_species(&"glitchmite")
	_spawn_eco(holder, foe, pos + Vector3(3, 0, 0))
	_spawn_eco(holder, foe, pos + Vector3(-2, 0, 2))
	EventBus.ui_notification_requested.emit("Merchant under attack!", 2.4)


func _spawn_rare_crossing(pos: Vector3) -> void:
	var holder := _make_holder("EncounterRare", pos)
	var rare := EcosystemCatalog.find_species(&"phantom_hare")
	if rare.is_empty():
		rare = EcosystemCatalog.find_species(&"glow_kit")
	_spawn_eco(holder, rare, pos)
	EventBus.ui_notification_requested.emit("Something rare crosses the road…!", 2.5)


func _spawn_bird_flush(pos: Vector3) -> void:
	var holder := _make_holder("EncounterFlush", pos)
	var bird := EcosystemCatalog.find_species(&"meadow_bird")
	for i in 4:
		var a := _spawn_eco(holder, bird, pos + Vector3(float(i) - 1.5, 0, float(i % 2)))
		if a:
			a._activity = EcosystemCreature.Activity.FLEE
			a._activity_timer = 3.0
	EventBus.sfx_play_requested.emit(&"ui_blip", pos)
	EventBus.ui_notification_requested.emit("A flock erupts from the grass!", 1.8)


func _spawn_resting_merchant(pos: Vector3) -> void:
	var holder := _make_holder("EncounterRestMerchant", pos)
	var npc_def := LivingWorldCatalog.grassland_npcs()[2]
	var npc := WorldNpcActor.new()
	npc.name = "RestingMerchant"
	holder.add_child(npc)
	npc.setup(npc_def, _player, pos)
	## Bedroll prop — environmental beat without a quest marker.
	StylizedMesh.add_box(holder, Vector3(1.2, 0.12, 0.7), Color(0.55, 0.4, 0.28), Vector3(1.2, 0.08, 0.4), "Bedroll", false, 1.0, &"wood")
	EventBus.ui_notification_requested.emit("A merchant rests beside the trail.", 2.0)


func _spawn_lost_traveler(pos: Vector3) -> void:
	var holder := _make_holder("EncounterTraveler", pos)
	var npc_def := LivingWorldCatalog.grassland_npcs()[0]
	var npc := WorldNpcActor.new()
	npc.name = "LostTraveler"
	holder.add_child(npc)
	npc.setup(npc_def, _player, pos)
	StylizedMesh.add_box(holder, Vector3(0.45, 0.4, 0.35), Color(0.35, 0.4, 0.3), Vector3(-1.0, 0.22, 0.3), "DroppedPack", false, 1.0, &"wood")
	EventBus.ui_notification_requested.emit("A traveler looks lost — maybe they need a hand.", 2.2)


func _spawn_meteor_glint(pos: Vector3) -> void:
	## Rare flash event — seeds curiosity toward meteor-scar micro-stories.
	var holder := _make_holder("EncounterMeteor", pos)
	StylizedMesh.add_box(holder, Vector3(3.5, 0.05, 3.5), Color(0.12, 0.1, 0.1), Vector3(0, 0.03, 0), "Scar", false, 1.0, &"dirt")
	StylizedMesh.add_box(holder, Vector3(0.45, 0.4, 0.4), Color(0.55, 0.35, 0.9), Vector3(0, 0.28, 0), "Shard", false, 1.0, &"flat")
	EventBus.ui_notification_requested.emit("A streak lights the sky — something landed nearby!", 2.6)
	EventBus.sfx_play_requested.emit(&"ui_blip", pos)


func _spawn_eco(parent: Node3D, def: Dictionary, pos: Vector3) -> EcosystemCreature:
	if def.is_empty() or parent == null or not parent.is_inside_tree():
		return null
	var actor := EcosystemCreature.new()
	actor.name = "Eco_%s" % String(def.get("id", "x"))
	parent.add_child(actor)
	actor.setup(def, _player, pos)
	return actor


func _phase() -> int:
	return WorldAtmosphere.current_phase_index()


func _weather() -> StringName:
	return WorldAtmosphere.current_weather_id()


func _near_hub(pos: Vector3, radius: float) -> bool:
	for zone in GrasslandLayout.hub_exclusion_zones():
		var hub: Vector3 = zone["pos"]
		if Vector3(pos.x, 0, pos.z).distance_to(Vector3(hub.x, 0, hub.z)) < radius:
			return true
	return false
