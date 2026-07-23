extends CharacterBody3D
## Adventure player — stick/D-pad move, A interact, L run, Select+B home.

const WALK_SPEED := 6.5
const RUN_SPEED := 10.5
const ACCELERATION := 30.0
const DECELERATION := 36.0
const ROTATION_SPEED := 14.0
const GRAVITY := 32.0
const FOOTSTEP_WALK_INTERVAL := 0.38
const FOOTSTEP_RUN_INTERVAL := 0.26
## Climb porch / curb lips that flush walkable slabs don't cover (foundation, garage).
const STEP_HEIGHT := 0.28
const STEP_FORWARD := 0.22

@onready var _visual_root: Node3D = $VisualRoot
@onready var _character_visual: CharacterVisual = $VisualRoot/CharacterVisual
@onready var _interaction_agent: InteractionAgent = $InteractionAgent
@onready var _footstep_player: AudioStreamPlayer = $FootstepPlayer
@onready var _shadow: MeshInstance3D = $Shadow

var _footstep_timer: float = 0.0
var _run_held: bool = false
var _living_world: LivingWorldController = null
var _health: PlayerHealth = null


func _ready() -> void:
	add_to_group(GameConstants.GROUP_PLAYER)
	floor_max_angle = deg_to_rad(48.0)
	floor_snap_length = 0.4
	floor_stop_on_slope = false
	_setup_footstep_stream()
	_health = PlayerHealth.new()
	_health.name = "PlayerHealth"
	add_child(_health)
	if _interaction_agent and not _interaction_agent.interaction_performed.is_connected(_on_interaction_performed):
		_interaction_agent.interaction_performed.connect(_on_interaction_performed)


func _on_interaction_performed(_interactable: Interactable) -> void:
	if _character_visual and _character_visual.has_method("play_interact"):
		_character_visual.play_interact()


func bind_living_world(world: LivingWorldController) -> void:
	_living_world = world


func apply_damage(amount: float, source: Node = null) -> void:
	if _health:
		_health.apply_damage(amount, source)


func get_player_health() -> PlayerHealth:
	return _health


func get_interaction_agent() -> InteractionAgent:
	return _interaction_agent


func _setup_footstep_stream() -> void:
	if _footstep_player == null or _footstep_player.stream != null:
		return
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.15
	_footstep_player.stream = gen
	_footstep_player.volume_db = -16.0


func _physics_process(delta: float) -> void:
	var ctx := InputManager.get_context()
	var can_move := (
		ctx == InputManager.Context.OVERWORLD
		or ctx == InputManager.Context.BUILDING_INTERIOR
	)
	_run_held = can_move and InputManager.is_action_pressed(&"run")
	var input_v := Vector2.ZERO
	if can_move:
		input_v = InputManager.get_move_vector()

	var direction := Vector3(input_v.x, 0.0, input_v.y)
	var has_input := direction.length_squared() > 0.001
	if has_input:
		direction = direction.normalized()

	var speed := RUN_SPEED if _run_held else WALK_SPEED
	var target_velocity := direction * speed
	var accel := ACCELERATION if has_input else DECELERATION
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)

	## Gravity + floor snap so hills/ramps work; steep mountain faces remain unclimbable.
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	var planar := Vector2(velocity.x, velocity.z).length()
	var speed_ratio := clampf(planar / RUN_SPEED, 0.0, 1.0)
	var running := _run_held and planar > 1.0
	if _character_visual:
		_character_visual.set_move_amount(speed_ratio if can_move else 0.0, running)

	if has_input and _visual_root != null:
		## Meshes face +Z; Basis.looking_at aims −Z and caused moonwalking.
		AssetStandardizer.face_velocity(_visual_root, direction, ROTATION_SPEED, delta)

	move_and_slide()
	if can_move and has_input:
		_try_step_up(direction)
	## Soft slide-back when pushing into a steep mountain face.
	if not is_on_floor() and get_slide_collision_count() > 0 and has_input:
		var col := get_slide_collision(0)
		if col and col.get_normal().y < 0.45:
			velocity.x *= 0.7
			velocity.z *= 0.7
			global_position += col.get_normal() * 0.05
	_update_footsteps(delta, planar, running, can_move)

	## Home: keyboard H, or Select held + B (handheld chord).
	if can_move:
		if InputManager.is_action_just_pressed(&"go_home"):
			_go_home()
		elif InputManager.is_action_pressed(&"pause_menu") and InputManager.is_action_just_pressed(&"ui_cancel"):
			_go_home()
		elif InputManager.is_action_just_pressed(&"creature_action"):
			_creature_action()


func _try_step_up(direction: Vector3) -> void:
	## If blocked by a short vertical face while grounded, hop onto it.
	if not is_on_floor() or get_slide_collision_count() <= 0:
		return
	var col := get_slide_collision(0)
	if col == null:
		return
	var n := col.get_normal()
	if n.y > 0.55:
		return
	if direction.dot(-n) < 0.15:
		return
	var from := global_position + Vector3(0, STEP_HEIGHT + 0.05, 0)
	var to := from + direction * STEP_FORWARD
	var space := get_world_3d().direct_space_state
	if space == null:
		return
	var probe := PhysicsRayQueryParameters3D.create(from, to)
	probe.exclude = [get_rid()]
	probe.collision_mask = collision_mask
	if space.intersect_ray(probe):
		return
	var down := PhysicsRayQueryParameters3D.create(to, to + Vector3(0, -(STEP_HEIGHT + 0.35), 0))
	down.exclude = [get_rid()]
	down.collision_mask = collision_mask
	var hit := space.intersect_ray(down)
	if hit.is_empty():
		return
	global_position = hit["position"] as Vector3 + Vector3(0, 0.02, 0)
	velocity.y = 0.0


func _creature_action() -> void:
	## Y — combat strike if a hostile is in range, else companion notice / bond.
	if _living_world and _living_world.try_combat_strike():
		var companions := get_tree().get_nodes_in_group(&"adventure_companion")
		if not companions.is_empty() and companions[0].has_method("play_combat_assist"):
			companions[0].call("play_combat_assist")
		return
	var companions2 := get_tree().get_nodes_in_group(&"adventure_companion")
	if not companions2.is_empty() and companions2[0].has_method("request_creature_action"):
		companions2[0].call("request_creature_action")
		return
	EventBus.ui_notification_requested.emit(
		"%s is with you." % CreatureManager.get_companion_nickname(),
		2.0,
	)
	DeviceService.pulse_led_for_mood(CreatureManager.get_mood_label())


func _go_home() -> void:
	EventBus.ui_notification_requested.emit("Returning to Home — progress autosaves…", 1.6)
	EventBus.sfx_play_requested.emit(&"ui_confirm", Vector3.ZERO)
	SaveManager.request_autosave()
	SceneManager.change_scene(String(GameConstants.SCENE_HOME), true)


func _update_footsteps(delta: float, planar_speed: float, running: bool, can_move: bool) -> void:
	if not can_move or planar_speed < 1.2:
		_footstep_timer = 0.0
		return
	_footstep_timer -= delta
	if _footstep_timer > 0.0:
		return
	_footstep_timer = FOOTSTEP_RUN_INTERVAL if running else FOOTSTEP_WALK_INTERVAL
	_play_footstep(running)


func _play_footstep(running: bool) -> void:
	if _footstep_player == null:
		return
	if not _footstep_player.playing:
		_footstep_player.play()
	var playback = _footstep_player.get_stream_playback()
	if playback is AudioStreamGeneratorPlayback:
		var gen_playback := playback as AudioStreamGeneratorPlayback
		var frames := 220 if running else 160
		for i in frames:
			var t := float(i) / float(frames)
			var sample := sin(t * 40.0) * exp(-t * 10.0) * (0.2 if running else 0.12)
			gen_playback.push_frame(Vector2(sample, sample))
