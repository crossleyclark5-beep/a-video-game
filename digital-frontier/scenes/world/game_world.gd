extends Node3D
## Adventure world — Pleasant Park with modular interaction + building systems.
## Visual atmosphere is presentation-only (does not alter gameplay contracts).

@onready var hex_grid_layer: Node3D = $HexGridLayer
@onready var building_layer: Node3D = $BuildingLayer
@onready var entity_layer: Node3D = $EntityLayer
@onready var effects_layer: Node3D = $EffectsLayer
@onready var camera_rig: Node3D = $CameraRig
@onready var hint_label: Label = %HintLabel
@onready var toast_label: Label = %ToastLabel
@onready var quest_label: Label = %QuestLabel
@onready var bits_label: Label = %BitsLabel
@onready var sun: DirectionalLight3D = $Sun

var _region_data: Dictionary = {}
var _player: Node3D = null
var _interior_controller: BuildingInteriorController = null
var _interaction_prompt: Control = null
var _toast_timer: float = 0.0
var _atmosphere: WorldAtmosphere = null
var _hud_refresh: float = 0.0


func _ready() -> void:
	InputManager.set_context(InputManager.Context.OVERWORLD)
	_clear_placeholder_geometry()
	_setup_atmosphere()
	_setup_systems()
	_region_data = PleasantParkBuilder.build(hex_grid_layer)
	EventBus.region_load_requested.emit(&"pleasant_park")
	_spawn_player()
	_bind_prompt()
	_spawn_ambient_fx()
	EventBus.ui_notification_requested.connect(_on_notification)
	EventBus.quest_updated.connect(_on_quest_pulse)
	EventBus.quest_completed.connect(_on_quest_pulse)
	EventBus.inventory_changed.connect(_refresh_hud)
	QuestManager.ensure_starter_quest()
	_refresh_default_hint()
	_refresh_hud()
	## Same CreatureInstance continues from home — tiny outing XP seed.
	CreatureManager.grant_adventure_experience(2)


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and toast_label:
			toast_label.visible = false
	_hud_refresh += delta
	if _hud_refresh >= 0.5:
		_hud_refresh = 0.0
		_refresh_hud()


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

	var prompt_scene: PackedScene = load("res://scenes/ui/components/interaction_prompt.tscn")
	if prompt_scene and has_node("HUD"):
		_interaction_prompt = prompt_scene.instantiate()
		$HUD.add_child(_interaction_prompt)


func _spawn_player() -> void:
	var player_scene: PackedScene = load("res://scenes/entities/player/player.tscn")
	if player_scene == null:
		push_error("GameWorld: missing player.tscn")
		return
	_player = player_scene.instantiate()
	_player.name = "Player"
	entity_layer.add_child(_player)
	var spawn: Vector3 = _region_data.get(&"player_spawn", Vector3(0.0, 0.15, 10.0))
	_player.global_position = spawn
	if camera_rig.has_method("set_target"):
		camera_rig.call("set_target", _player)


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
	## Lightweight pollen / dust — atmosphere only, no collision.
	var dust := GPUParticles3D.new()
	dust.name = "AmbientPollen"
	dust.amount = 36
	dust.lifetime = 8.0
	dust.preprocess = 3.0
	dust.visibility_aabb = AABB(Vector3(-40, 0, -40), Vector3(80, 20, 80))
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(35, 4, 35)
	mat.direction = Vector3(0.2, 0.4, 0.1)
	mat.spread = 40.0
	mat.initial_velocity_min = 0.05
	mat.initial_velocity_max = 0.25
	mat.gravity = Vector3(0, -0.02, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.07
	mat.color = Color(0.95, 0.95, 0.8, 0.35)
	dust.process_material = mat
	var draw := SphereMesh.new()
	draw.radius = 0.04
	draw.height = 0.08
	var draw_mat := StylizedMesh.make_material(Color(0.95, 0.92, 0.7, 0.4), 0.9)
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw.material = draw_mat
	dust.draw_pass_1 = draw
	dust.position = Vector3(0, 3, 0)
	effects_layer.add_child(dust)


func _on_notification(message: String, duration: float) -> void:
	if toast_label == null:
		return
	toast_label.text = message
	toast_label.visible = true
	_toast_timer = duration


func _refresh_default_hint() -> void:
	if hint_label:
		hint_label.text = "WASD move · Shift run · E/A interact · scroll zoom · H home"


func _refresh_hud() -> void:
	if bits_label:
		bits_label.text = "%d Bits" % InventoryManager.get_bits()
	if quest_label:
		quest_label.text = QuestManager.get_quest_status_line()


func _on_quest_pulse(_a = null, _b = null) -> void:
	_refresh_hud()
