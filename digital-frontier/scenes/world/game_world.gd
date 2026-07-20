extends Node3D
## Adventure world — Grassland Region (Pleasant Park + surrounding POIs).
## Visual atmosphere is presentation-only (does not alter gameplay contracts).

@onready var hex_grid_layer: Node3D = $HexGridLayer
@onready var building_layer: Node3D = $BuildingLayer
@onready var entity_layer: Node3D = $EntityLayer
@onready var effects_layer: Node3D = $EffectsLayer
@onready var camera_rig: Node3D = $CameraRig
@onready var sun: DirectionalLight3D = $Sun

var _region_data: Dictionary = {}
var _player: Node3D = null
var _companion: AdventureCompanionActor = null
var _interior_controller: BuildingInteriorController = null
var _interaction_prompt: Control = null
var _device_hud: CanvasLayer = null
var _atmosphere: WorldAtmosphere = null
var _living_world: LivingWorldController = null
var _chapter: ChapterDirector = null
var _battle: BattleDirector = null
var _checkpoint_timer: float = 0.0


func _ready() -> void:
	InputManager.set_context(InputManager.Context.OVERWORLD)
	_clear_placeholder_geometry()
	_setup_atmosphere()
	_setup_systems()
	_region_data = GrasslandRegionBuilder.build(hex_grid_layer)
	EventBus.region_load_requested.emit(&"grassland")
	_spawn_player()
	_spawn_companion()
	_spawn_living_world()
	_spawn_chapter_director()
	_spawn_battle_director()
	_bind_prompt()
	_spawn_ambient_fx()
	QuestManager.ensure_starter_quest()
	## Same CreatureInstance continues from home — tiny outing XP seed.
	CreatureManager.grant_adventure_experience(2)
	if not EventBus.save_completed.is_connected(_on_save_completed):
		EventBus.save_completed.connect(_on_save_completed)
	if not EventBus.battle_encounter_requested.is_connected(_on_battle_requested):
		EventBus.battle_encounter_requested.connect(_on_battle_requested)


func _process(delta: float) -> void:
	_checkpoint_timer += delta
	if _checkpoint_timer >= 2.0:
		_checkpoint_timer = 0.0
		_save_checkpoint()


func _exit_tree() -> void:
	_save_checkpoint()


func _clear_placeholder_geometry() -> void:
	for child in hex_grid_layer.get_children():
		child.queue_free()


func _setup_atmosphere() -> void:
	_atmosphere = WorldAtmosphere.new()
	_atmosphere.name = "WorldAtmosphere"
	add_child(_atmosphere)
	_atmosphere.setup(sun)
	_atmosphere.apply_phase(WorldAtmosphere.Phase.AFTERNOON)


func _setup_systems() -> void:
	var interior_root := Node3D.new()
	interior_root.name = "InteriorContainer"
	building_layer.add_child(interior_root)
	_interior_controller = BuildingInteriorController.new()
	_interior_controller.name = "BuildingInteriorController"
	add_child(_interior_controller)
	_interior_controller.setup(camera_rig, interior_root)

	## Replace legacy label HUD with handheld adventure device.
	if has_node("HUD"):
		$HUD.queue_free()
	var hud_scene: PackedScene = load("res://scenes/ui/adventure/adventure_device_hud.tscn")
	if hud_scene:
		var hud_instance := hud_scene.instantiate()
		if hud_instance.get_script() == null:
			push_error("GameWorld: Adventure Device HUD script failed to load")
			hud_instance.queue_free()
		else:
			_device_hud = hud_instance
			_device_hud.name = "AdventureDeviceHud"
			add_child(_device_hud)
	else:
		push_error("GameWorld: missing adventure_device_hud.tscn")

	var prompt_scene: PackedScene = load("res://scenes/ui/components/interaction_prompt.tscn")
	if prompt_scene:
		_interaction_prompt = prompt_scene.instantiate()
		## Keep prompt above world; parent to device or a dedicated layer.
		var prompt_layer := CanvasLayer.new()
		prompt_layer.layer = 15
		prompt_layer.name = "PromptLayer"
		add_child(prompt_layer)
		prompt_layer.add_child(_interaction_prompt)


func _spawn_player() -> void:
	var player_scene: PackedScene = load("res://scenes/entities/player/player.tscn")
	if player_scene == null:
		push_error("GameWorld: missing player.tscn")
		return
	_player = player_scene.instantiate()
	_player.name = "Player"
	entity_layer.add_child(_player)
	var spawn: Vector3 = _region_data.get(&"player_spawn", Vector3(0.0, 0.15, 10.0))
	if WorldManager.has_player_checkpoint() and WorldManager.get_active_region_id() in [&"grassland", &"pleasant_park"]:
		spawn = WorldManager.get_player_checkpoint()
	elif WorldManager.has_player_checkpoint():
		## Returning to adventure mid-save — prefer checkpoint when set.
		spawn = WorldManager.get_player_checkpoint()
	_player.global_position = spawn
	if camera_rig.has_method("set_target"):
		camera_rig.call("set_target", _player)
	if _device_hud and _device_hud.has_method("bind_player"):
		_device_hud.call("bind_player", _player)
	WorldManager.mark_explored_at(spawn)


func _spawn_companion() -> void:
	if _player == null:
		return
	_companion = AdventureCompanionActor.new()
	_companion.name = "AdventureCompanion"
	entity_layer.add_child(_companion)
	_companion.setup(_player)
	if _device_hud and _device_hud.has_method("bind_companion"):
		_device_hud.call("bind_companion", _companion)


func _spawn_living_world() -> void:
	if _player == null:
		return
	_living_world = LivingWorldController.new()
	_living_world.name = "LivingWorld"
	entity_layer.add_child(_living_world)
	_living_world.setup(_player)
	## Player strike path for Y / creature_action combat.
	if _player.has_method("bind_living_world"):
		_player.call("bind_living_world", _living_world)
	if _device_hud and _device_hud.has_method("bind_player_health"):
		var health := _player.get_node_or_null("PlayerHealth")
		if health:
			_device_hud.call("bind_player_health", health)


func _spawn_chapter_director() -> void:
	if _player == null or _living_world == null:
		return
	_chapter = ChapterDirector.new()
	_chapter.name = "ChapterDirector"
	add_child(_chapter)
	_chapter.setup(_player, _living_world, _device_hud)


func _spawn_battle_director() -> void:
	if _player == null:
		return
	_battle = BattleDirector.new()
	_battle.name = "BattleDirector"
	add_child(_battle)
	_battle.setup(_player, _companion, camera_rig)
	if _living_world and _living_world.has_method("bind_battle_director"):
		_living_world.call("bind_battle_director", _battle)
	if _player.has_method("bind_battle_director"):
		_player.call("bind_battle_director", _battle)


func _on_battle_requested(enemy: Node3D, _reason: StringName = &"") -> void:
	if _battle:
		_battle.try_start_from_target(enemy)


func _on_save_completed(_slot: int, success: bool) -> void:
	if success:
		EventBus.ui_notification_requested.emit("Field Unit saved.", 1.4)
		EventBus.sfx_play_requested.emit(&"ui_confirm", Vector3.ZERO)


func _save_checkpoint() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if not _player.is_inside_tree():
		return
	WorldManager.set_player_checkpoint(_player.global_position)
	WorldManager.mark_explored_at(_player.global_position)


func _bind_prompt() -> void:
	if _player == null or _interaction_prompt == null:
		return
	if _player.has_method("get_interaction_agent"):
		var agent: InteractionAgent = _player.call("get_interaction_agent")
		if agent and _interaction_prompt.has_method("bind_agent"):
			_interaction_prompt.call("bind_agent", agent)


func _spawn_ambient_fx() -> void:
	if effects_layer == null:
		return
	var dust := GPUParticles3D.new()
	dust.name = "AmbientPollen"
	dust.amount = 16
	dust.lifetime = 8.0
	dust.preprocess = 2.0
	dust.visibility_aabb = AABB(Vector3(-40, 0, -40), Vector3(80, 20, 80))
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(35, 4, 35)
	mat.direction = Vector3(0.2, 0.4, 0.1)
	mat.spread = 40.0
	mat.initial_velocity_min = 0.05
	mat.initial_velocity_max = 0.2
	mat.gravity = Vector3(0, -0.02, 0)
	mat.scale_min = 0.04
	mat.scale_max = 0.06
	mat.color = Color(0.95, 0.95, 0.8, 0.28)
	dust.process_material = mat
	var draw := BoxMesh.new()
	draw.size = Vector3(0.06, 0.06, 0.06)
	var draw_mat := StylizedMesh.make_material(Color(0.95, 0.92, 0.7, 0.35), 1.0)
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw.material = draw_mat
	dust.draw_pass_1 = draw
	dust.position = Vector3(0, 3, 0)
	effects_layer.add_child(dust)
