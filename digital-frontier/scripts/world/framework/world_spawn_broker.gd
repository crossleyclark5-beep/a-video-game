class_name WorldSpawnBroker
extends RefCounted
## Unified spawning facade — NPCs, creatures, wildlife, collectibles, events.
## Location-aware; delegates live population to LivingWorldController.


enum Channel {
	WILDLIFE,
	HOSTILE,
	NPC,
	AQUATIC,
	COLLECTIBLE,
	EVENT,
	RESOURCE,
}


var _living: LivingWorldController = null
var _root: Node3D = null
var _rng := RandomNumberGenerator.new()


func bind(living: LivingWorldController, root: Node3D = null) -> void:
	_living = living
	_root = root if root else (living as Node3D)
	_rng.randomize()


func is_bound() -> bool:
	return _living != null and is_instance_valid(_living)


func spawn(channel: int, def: Dictionary, pos: Vector3) -> Node:
	if not GrasslandLayout.is_on_island(pos, -40.0):
		return null
	match channel:
		Channel.WILDLIFE, Channel.HOSTILE:
			return _spawn_eco(def, pos, channel == Channel.HOSTILE)
		Channel.NPC:
			return _spawn_npc(def, pos)
		Channel.AQUATIC:
			return null  ## Requires water AABB — use LivingWorld.register_water_aabb path.
		Channel.COLLECTIBLE:
			return _spawn_collectible(def, pos)
		Channel.EVENT:
			return _spawn_event_marker(def, pos)
		Channel.RESOURCE:
			return _spawn_resource_node(def, pos)
		_:
			return null


func spawn_wildlife_near(focus: Vector3, radius: float = 18.0) -> Node:
	if not is_bound():
		return null
	var phase := WorldAtmosphere.current_phase_index()
	var weather := WorldAtmosphere.current_weather_id()
	var def := EcosystemCatalog.pick_for_conditions(
		EcosystemCatalog.grassland_species(), phase, weather, _rng, false
	)
	if def.is_empty():
		return null
	var ang := _rng.randf() * TAU
	var p := focus + Vector3(cos(ang) * radius, 0.15, sin(ang) * radius)
	return spawn(Channel.WILDLIFE, def, p)


func spawn_hostile_near(focus: Vector3, radius: float = 28.0) -> Node:
	if not is_bound():
		return null
	var phase := WorldAtmosphere.current_phase_index()
	var weather := WorldAtmosphere.current_weather_id()
	var def := EcosystemCatalog.pick_for_conditions(
		EcosystemCatalog.grassland_species(), phase, weather, _rng, true
	)
	if def.is_empty():
		return null
	var ang := _rng.randf() * TAU
	var p := focus + Vector3(cos(ang) * radius, 0.15, sin(ang) * radius)
	return spawn(Channel.HOSTILE, def, p)


func spawn_npc_def(def: Dictionary, pos: Vector3) -> Node:
	return spawn(Channel.NPC, def, pos)


func population_snapshot() -> Dictionary:
	if is_bound() and _living.has_method("population_snapshot"):
		return _living.population_snapshot()
	return {}


func _spawn_eco(def: Dictionary, pos: Vector3, hostile: bool) -> Node:
	if not is_bound() or def.is_empty():
		return null
	## Prefer LivingWorld private paths via public-safe recreation.
	var actor := EcosystemCreature.new()
	actor.name = "Eco_%s" % String(def.get("id", "x"))
	var parent: Node3D = _living.get_node_or_null("Hostiles" if hostile else "Wildlife") as Node3D
	if parent == null:
		parent = _living
	parent.add_child(actor)
	var player := _living.get("_player") as Node3D
	actor.setup(def, player, pos)
	return actor


func _spawn_npc(def: Dictionary, pos: Vector3) -> Node:
	if not is_bound() or def.is_empty():
		return null
	var actor := WorldNpcActor.new()
	actor.name = "Npc_%s" % String(def.get("id", "x"))
	var parent: Node3D = _living.get_node_or_null("WorldNpcs") as Node3D
	if parent == null:
		parent = _living
	parent.add_child(actor)
	var player := _living.get("_player") as Node3D
	actor.setup(def, player, pos)
	return actor


func _spawn_collectible(def: Dictionary, pos: Vector3) -> Node:
	if _root == null:
		return null
	var holder := Node3D.new()
	holder.name = String(def.get(&"name", def.get("name", "Collectible")))
	_root.add_child(holder)
	holder.global_position = pos
	var bits := int(def.get(&"bits", def.get("bits", 5)))
	RegionPropKit.add_discoverable(
		holder,
		StringName(str(def.get(&"id", def.get("id", "collectible")))),
		String(def.get(&"label", def.get("label", "Find"))),
		Vector3(0, 0.4, 0),
		bits,
		String(def.get(&"msg", def.get("msg", "A small find."))),
	)
	return holder


func _spawn_event_marker(def: Dictionary, pos: Vector3) -> Node:
	if _root == null:
		return null
	var holder := Node3D.new()
	holder.name = "Event_%s" % String(def.get(&"id", def.get("id", "evt")))
	_root.add_child(holder)
	holder.global_position = pos
	StylizedMesh.add_box(holder, Vector3(0.6, 0.6, 0.6), WorldPalette.UI_CYAN, Vector3(0, 0.3, 0), "Mark", false, 1.0, &"flat")
	return holder


func _spawn_resource_node(def: Dictionary, pos: Vector3) -> Node:
	if _root == null:
		return null
	var holder := Node3D.new()
	holder.name = "Resource_%s" % String(def.get(&"id", def.get("id", "node")))
	_root.add_child(holder)
	holder.global_position = pos
	StylizedMesh.add_box(holder, Vector3(0.8, 0.5, 0.8), WorldPalette.ROCK, Vector3(0, 0.25, 0), "Node", true, 1.0, &"dirt")
	RegionPropKit.add_supply_stash(holder, Vector3(0.8, 0, 0.5), 0.0, "NodeStash")
	return holder
