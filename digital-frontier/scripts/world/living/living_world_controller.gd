class_name LivingWorldController
extends Node3D
## Budgeted living world — wildlife, hostiles, NPCs, aquatics around the player.
## Spawns/despawns by distance so the handheld stays performant.

const WILDLIFE_CAP := 18
const HOSTILE_CAP := 8
const NPC_CAP := 6
const AQUATIC_CAP := 14
const SPAWN_RADIUS := 95.0
const DESPAWN_RADIUS := 130.0
const TICK := 0.55

var _player: Node3D = null
var _root_wildlife: Node3D
var _root_hostiles: Node3D
var _root_npcs: Node3D
var _root_aquatic: Node3D
var _tick: float = 0.0
var _rng := RandomNumberGenerator.new()
var _water_volumes: Array[AABB] = []
var _spawn_slots: Array[Dictionary] = []  ## precomputed wilderness points
var _encounters: WorldEncounterDirector = null
var _boss: RegionBossActor = null
var _root_encounters: Node3D = null


func setup(player: Node3D) -> void:
	_player = player
	_rng.randomize()
	_root_wildlife = Node3D.new()
	_root_wildlife.name = "Wildlife"
	add_child(_root_wildlife)
	_root_hostiles = Node3D.new()
	_root_hostiles.name = "Hostiles"
	add_child(_root_hostiles)
	_root_npcs = Node3D.new()
	_root_npcs.name = "WorldNpcs"
	add_child(_root_npcs)
	_root_aquatic = Node3D.new()
	_root_aquatic.name = "Aquatics"
	add_child(_root_aquatic)
	_root_encounters = Node3D.new()
	_root_encounters.name = "Encounters"
	add_child(_root_encounters)
	_build_spawn_slots()
	_seed_near_hubs()
	_spawn_region_boss()
	_encounters = WorldEncounterDirector.new()
	_encounters.name = "EncounterDirector"
	add_child(_encounters)
	_encounters.setup(_player, self, _root_encounters)
	call_deferred("_collect_water_volumes")


func register_water_aabb(bounds: AABB) -> void:
	if bounds.size.length() < 1.0:
		return
	_water_volumes.append(bounds)


func try_combat_strike() -> bool:
	## Y / creature action — strike nearest hostile in melee range + companion pulse.
	if _player == null:
		return false
	var best: Node3D = null
	var best_d := 3.2
	for node in get_tree().get_nodes_in_group(HostileCreatureActor.GROUP):
		if not is_instance_valid(node):
			continue
		var d: float = _player.global_position.distance_to((node as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = node as Node3D
	if best == null:
		return false
	var atk := CreatureManager.get_strike_power()
	if best.has_method("apply_damage"):
		best.call("apply_damage", atk, _player)
	EventBus.sfx_play_requested.emit(&"battle_hit", best.global_position)
	EventBus.combat_strike.emit(_player, best)
	## Companion bond tick for fighting together.
	CreatureManager.record_companion_strike()
	CreatureManager.grant_adventure_bond(0.4, "")
	return true


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_tick += delta
	if _tick < TICK:
		return
	_tick = 0.0
	_maintain_population()


func _build_spawn_slots() -> void:
	## Wilderness points between POIs — avoid hub pads and roads.
	var hubs: Array[Vector3] = [
		GrasslandLayout.PLEASANT_PARK,
		GrasslandLayout.SALTY_SPRINGS,
		GrasslandLayout.RISKY_REELS,
		GrasslandLayout.FATAL_FIELDS,
		GrasslandLayout.MIRROR_MERE,
		GrasslandLayout.MARKET_MILE,
		GrasslandLayout.GREASE_GROVE,
	]
	for i in 48:
		var a: Vector3 = hubs[i % hubs.size()]
		var b: Vector3 = hubs[(i * 3 + 1) % hubs.size()]
		var t := 0.25 + float((i * 7) % 5) * 0.12
		var mid: Vector3 = a.lerp(b, t)
		var ang := float(i) * 1.7
		var p: Vector3 = mid + Vector3(cos(ang) * (18.0 + float(i % 5) * 6.0), 0.15, sin(ang) * (18.0 + float(i % 4) * 5.0))
		if not GrasslandLayout.is_on_island(p, -50.0):
			continue
		if _near_hub(p, 55.0):
			continue
		_spawn_slots.append({"pos": p, "kind": &"wild" if i % 3 != 0 else &"hostile"})
	## NPC slots near hub edges.
	for hub in hubs:
		for j in 2:
			var ang2 := float(j) * PI + float(hash(hub)) * 0.01
			var np: Vector3 = hub + Vector3(cos(ang2) * 28.0, 0.15, sin(ang2) * 28.0)
			_spawn_slots.append({"pos": np, "kind": &"npc"})


func _seed_near_hubs() -> void:
	## Immediate ecosystem life so the world never boots empty near spawn.
	if _player == null:
		return
	var phase := WorldAtmosphere.current_phase_index()
	var weather := WorldAtmosphere.current_weather_id()
	_spawn_eco_at(_player.global_position + Vector3(12, 0, -8), EcosystemCatalog.pick_for_conditions(EcosystemCatalog.grassland_species(), phase, weather, _rng, false), false)
	_spawn_eco_at(_player.global_position + Vector3(-10, 0, 14), EcosystemCatalog.pick_for_conditions(EcosystemCatalog.grassland_species(), phase, weather, _rng, false), false)
	_spawn_eco_at(_player.global_position + Vector3(18, 0, 10), EcosystemCatalog.pick_for_conditions(EcosystemCatalog.grassland_species(), phase, weather, _rng, false), false)
	## Pack pups travel together.
	var pack := EcosystemCatalog.find_species(&"pack_pup")
	_spawn_eco_at(_player.global_position + Vector3(22, 0, -16), pack, false)
	_spawn_eco_at(_player.global_position + Vector3(24, 0, -14), pack, false)
	## Hostiles farther from park center.
	_spawn_eco_at(GrasslandLayout.PLEASANT_PARK + Vector3(70, 0.15, 40), EcosystemCatalog.pick_for_conditions(EcosystemCatalog.grassland_species(), phase, weather, _rng, true), true)
	_spawn_eco_at(GrasslandLayout.PLEASANT_PARK + Vector3(-55, 0.15, 65), EcosystemCatalog.pick_for_conditions(EcosystemCatalog.grassland_species(), phase, weather, _rng, true), true)
	var ranger := LivingWorldCatalog.grassland_npcs()[0]
	_spawn_npc_at(GrasslandLayout.PLEASANT_PARK + Vector3(16, 0.15, 22), ranger)


func _spawn_region_boss() -> void:
	if bool(WorldManager.get_world_flag(&"boss_hollow_warden_down", false)):
		return
	var def := EcosystemCatalog.grassland_boss()
	_boss = RegionBossActor.new()
	_boss.name = "HollowWarden"
	_root_hostiles.add_child(_boss)
	_boss.setup(def, _player, GrasslandLayout.LANDMARK_PINE_HOLLOW + Vector3(4, 0.15, -3))


func _maintain_population() -> void:
	_despawn_far(_root_wildlife, DESPAWN_RADIUS)
	_despawn_far(_root_hostiles, DESPAWN_RADIUS)
	_despawn_far(_root_npcs, DESPAWN_RADIUS + 40.0)
	_despawn_far(_root_aquatic, DESPAWN_RADIUS)

	var wildlife_n := _root_wildlife.get_child_count()
	var hostile_n := _count_non_boss_hostiles()
	var npc_n := _root_npcs.get_child_count()
	var aquatic_n := _root_aquatic.get_child_count()
	var phase := WorldAtmosphere.current_phase_index()
	var weather := WorldAtmosphere.current_weather_id()

	## Night / storm: slightly higher hostile pressure.
	var hostile_cap := HOSTILE_CAP + (2 if phase == WorldAtmosphere.Phase.NIGHT or weather == &"storm" else 0)

	var nearby: Array[Dictionary] = []
	for slot in _spawn_slots:
		var pos: Vector3 = slot["pos"]
		var d := _player.global_position.distance_to(pos)
		if d < SPAWN_RADIUS and d > 14.0:
			nearby.append(slot)
	if nearby.is_empty():
		if aquatic_n < AQUATIC_CAP:
			_fill_aquatics(aquatic_n)
		return
	nearby.shuffle()

	for slot in nearby:
		if wildlife_n >= WILDLIFE_CAP and hostile_n >= hostile_cap and npc_n >= NPC_CAP:
			break
		var kind: StringName = slot["kind"]
		var pos2: Vector3 = slot["pos"]
		if kind == &"wild" and wildlife_n < WILDLIFE_CAP:
			if weather == &"rain" and _rng.randf() < 0.35:
				continue  ## Some hide in rain.
			if _too_close_to_existing(_root_wildlife, pos2, 10.0):
				continue
			var def := EcosystemCatalog.pick_for_conditions(EcosystemCatalog.grassland_species(), phase, weather, _rng, false)
			if not def.is_empty():
				_spawn_eco_at(pos2, def, false)
				wildlife_n += 1
		elif kind == &"hostile" and hostile_n < hostile_cap:
			if _near_hub(pos2, 48.0):
				continue
			if _too_close_to_existing(_root_hostiles, pos2, 16.0):
				continue
			var hdef := EcosystemCatalog.pick_for_conditions(EcosystemCatalog.grassland_species(), phase, weather, _rng, true)
			if not hdef.is_empty():
				_spawn_eco_at(pos2, hdef, true)
				hostile_n += 1
		elif kind == &"npc" and npc_n < NPC_CAP:
			if _too_close_to_existing(_root_npcs, pos2, 22.0):
				continue
			var ndef := LivingWorldCatalog.pick_weighted(LivingWorldCatalog.grassland_npcs(), _rng)
			if not ndef.is_empty():
				_spawn_npc_at(pos2, ndef)
				npc_n += 1

	if aquatic_n < AQUATIC_CAP:
		_fill_aquatics(aquatic_n)


func _count_non_boss_hostiles() -> int:
	var n := 0
	for child in _root_hostiles.get_children():
		if child is RegionBossActor or child is MiniBossActor:
			continue
		n += 1
	return n


func _fill_aquatics(current: int) -> void:
	if _water_volumes.is_empty():
		return
	var need := mini(AQUATIC_CAP - current, 3)
	for _i in need:
		var bounds: AABB = _water_volumes[_rng.randi_range(0, _water_volumes.size() - 1)]
		var center := bounds.get_center()
		if _player.global_position.distance_to(center) > SPAWN_RADIUS + 20.0:
			continue
		var def := LivingWorldCatalog.pick_weighted(LivingWorldCatalog.grassland_aquatics(), _rng)
		if def.is_empty():
			continue
		var origin := Vector3(
			_rng.randf_range(bounds.position.x, bounds.end.x),
			center.y,
			_rng.randf_range(bounds.position.z, bounds.end.z),
		)
		_spawn_aquatic_at(origin, bounds, def)


func _spawn_eco_at(pos: Vector3, def: Dictionary, as_hostile: bool) -> void:
	if def.is_empty():
		return
	var actor := EcosystemCreature.new()
	actor.name = "Eco_%s" % String(def.get("id", "x"))
	if as_hostile:
		_root_hostiles.add_child(actor)
	else:
		_root_wildlife.add_child(actor)
	actor.setup(def, _player, pos)


func _spawn_wildlife_at(pos: Vector3, def: Dictionary) -> void:
	## Legacy path — route through ecosystem.
	_spawn_eco_at(pos, def if def.has("temperament") else EcosystemCatalog.find_species(def.get("id", &"cotton_rabbit")), false)


func _spawn_hostile_at(pos: Vector3, def: Dictionary) -> void:
	_spawn_eco_at(pos, def if def.has("temperament") else EcosystemCatalog.find_species(def.get("id", &"glitchmite")), true)


func _spawn_npc_at(pos: Vector3, def: Dictionary) -> void:
	if def.is_empty():
		return
	var actor := WorldNpcActor.new()
	actor.name = "Npc_%s" % String(def.get("id", "x"))
	_root_npcs.add_child(actor)
	actor.setup(def, _player, pos)


func _spawn_aquatic_at(pos: Vector3, bounds: AABB, def: Dictionary) -> void:
	var actor := AquaticActor.new()
	actor.name = "Aquatic_%s" % String(def.get("id", "x"))
	_root_aquatic.add_child(actor)
	actor.setup(def, _player, bounds, pos)


func _collect_water_volumes() -> void:
	for node in get_tree().get_nodes_in_group(&"water_bodies"):
		if node is WaterBody:
			register_water_aabb((node as WaterBody).water_bounds)
	## Fallback known water landmarks if builders haven't tagged yet.
	if _water_volumes.is_empty():
		_water_volumes.append(AABB(GrasslandLayout.MIRROR_MERE + Vector3(-40, -0.5, -30), Vector3(80, 1.2, 60)))
		_water_volumes.append(AABB(GrasslandLayout.FATAL_FIELDS + Vector3(-20, -0.4, 10), Vector3(40, 1.0, 16)))


func _despawn_far(root: Node3D, radius: float) -> void:
	if _player == null:
		return
	for child in root.get_children():
		if child is RegionBossActor or child is MiniBossActor:
			continue
		if child is Node3D:
			if _player.global_position.distance_to((child as Node3D).global_position) > radius:
				child.queue_free()


func _too_close_to_existing(root: Node3D, pos: Vector3, min_d: float) -> bool:
	for child in root.get_children():
		if child is Node3D and (child as Node3D).global_position.distance_to(pos) < min_d:
			return true
	return false


func _near_hub(pos: Vector3, radius: float) -> bool:
	for zone in GrasslandLayout.hub_exclusion_zones():
		var hub: Vector3 = zone["pos"]
		if Vector3(pos.x, 0, pos.z).distance_to(Vector3(hub.x, 0, hub.z)) < radius:
			return true
	return false
