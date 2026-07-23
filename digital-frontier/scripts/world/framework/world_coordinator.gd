class_name WorldCoordinator
extends Node
## Global world coordination hub — future systems talk here, not peer-to-peer.
## Wraps atmosphere, living sim, regions, spawn, events, discovery, save meta.
## Persistence flags remain in WorldManager autoload; this is the simulation brain.


const GROUP := &"world_coordinator"

var active_region_id: StringName = &""
var region_result: Dictionary = {}
var spawn_broker: WorldSpawnBroker = WorldSpawnBroker.new()
var events: WorldEventFramework = null

var _modules: Dictionary = {}  ## region_id -> RegionModule
var _active_module: RegionModule = null
var _player: Node3D = null
var _living: LivingWorldController = null
var _atmosphere: WorldAtmosphere = null
var _stream: WorldStreamController = null
var _dev_console: WorldDevConsole = null
var _framework_state: Dictionary = {}


func _ready() -> void:
	add_to_group(GROUP)
	name = "WorldCoordinator"
	## Built-in region plugins — future continents register() the same way.
	register_region(GrasslandRegionModule.new())


func register_region(module: RegionModule) -> void:
	if module == null or module.get_id() == &"":
		return
	_modules[module.get_id()] = module


func list_region_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for k in _modules.keys():
		out.append(StringName(str(k)))
	return out


func get_region_module(region_id: StringName) -> RegionModule:
	return _modules.get(region_id, null) as RegionModule


func active_module() -> RegionModule:
	return _active_module


func active_biome() -> BiomeProfile:
	if _active_module:
		return _active_module.get_biome()
	return BiomeProfile.grassland()


func bind_atmosphere(atmosphere: WorldAtmosphere) -> void:
	_atmosphere = atmosphere


func bind_player(player: Node3D) -> void:
	_player = player


func bind_living(living: LivingWorldController) -> void:
	_living = living
	spawn_broker.bind(living, living)
	if events == null:
		events = WorldEventFramework.new()
		add_child(events)
	events.setup(_player, living)


func bind_stream(stream: WorldStreamController) -> void:
	_stream = stream


## Build a registered region under root and become the active region.
func load_region(region_id: StringName, root: Node3D) -> Dictionary:
	var mod: RegionModule = get_region_module(region_id)
	if mod == null:
		push_error("WorldCoordinator: unknown region %s" % String(region_id))
		return {}
	_active_module = mod
	active_region_id = region_id
	region_result = mod.build(root)
	EventBus.region_load_requested.emit(region_id)
	EventBus.region_loaded.emit(region_id)
	_framework_state[&"active_region"] = String(region_id)
	_framework_state[&"biome_id"] = String(active_biome().id)
	_framework_state[&"loaded_unix"] = int(Time.get_unix_time_from_system())
	## Music / ambient hooks — soft request through EventBus.
	if mod.music_track_id != &"":
		EventBus.music_change_requested.emit(mod.music_track_id)
	return region_result


func setup_dev_tools() -> void:
	if not GameConfig.enable_cheats:
		return
	if _dev_console != null:
		return
	_dev_console = WorldDevConsole.new()
	add_child(_dev_console)
	_dev_console.setup(self, _player, _atmosphere)


## --- Service facades (prefer these over cross-manager calls) ----------------------

func set_time_phase(phase: int) -> void:
	if _atmosphere:
		_atmosphere.apply_phase(phase as WorldAtmosphere.Phase)


func set_weather(weather: int) -> void:
	if _atmosphere:
		_atmosphere.apply_weather(weather as WorldAtmosphere.Weather)


func current_phase() -> int:
	return WorldAtmosphere.current_phase_index()


func current_weather() -> StringName:
	return WorldAtmosphere.current_weather_id()


func discover(location_id: StringName, display_name: String = "") -> bool:
	return DiscoveryFramework.register_location(location_id, display_name)


func grant_collectible(kind: int, payload: Dictionary) -> void:
	CollectibleKinds.grant(kind, payload)


func trigger_event(event_id: StringName, pos: Vector3 = Vector3.ZERO) -> bool:
	if events:
		return events.trigger(event_id, pos)
	return false


func interaction_kind_for(node: Node) -> int:
	if node == null:
		return InteractionKinds.Kind.CUSTOM
	## Prefer typed checks — get_class() returns native bases for GDScript nodes.
	if node is NpcTalkInteractable:
		return InteractionKinds.Kind.TALK
	if node is ChestInteractable:
		return InteractionKinds.Kind.OPEN
	if node is DiscoverableInteractable:
		return InteractionKinds.Kind.SCAN
	if node is ShopInteractable:
		return InteractionKinds.Kind.SHOP
	if node is SignInteractable:
		return InteractionKinds.Kind.READ
	if node is VehicleEnterInteractable:
		return InteractionKinds.Kind.RIDE
	if node is AircraftPadInteractable:
		return InteractionKinds.Kind.BOARD
	return InteractionKinds.kind_for_class(node.get_class())


func snapshot() -> Dictionary:
	return {
		&"region": active_region_id,
		&"biome": active_biome().to_dict() if active_biome() else {},
		&"phase": current_phase(),
		&"weather": current_weather(),
		&"population": spawn_broker.population_snapshot(),
		&"discovery": DiscoveryFramework.completion_snapshot(),
		&"schema": WorldSaveSchema.describe(),
		&"framework": _framework_state.duplicate(true),
	}


func export_state() -> Dictionary:
	return {
		&"schema": WorldSaveSchema.CURRENT_VERSION,
		&"active_region": String(active_region_id),
		&"framework": _framework_state.duplicate(true),
		&"discovery_blurb": DiscoveryFramework.journal_blurb(),
	}


func import_state(data: Dictionary) -> void:
	if data.is_empty():
		return
	_framework_state = data.get(&"framework", data.get("framework", {})).duplicate(true)
	var rid := StringName(str(data.get(&"active_region", data.get("active_region", ""))))
	if rid != &"":
		active_region_id = rid


static func find_in_tree(tree: SceneTree) -> WorldCoordinator:
	if tree == null:
		return null
	var nodes := tree.get_nodes_in_group(GROUP)
	if nodes.is_empty():
		return null
	return nodes[0] as WorldCoordinator
