extends CharacterBody3D
## Adventure player — walk/run, interaction agent, shadow, footsteps.

const WALK_SPEED := 6.5
const RUN_SPEED := 10.5
const ACCELERATION := 30.0
const DECELERATION := 36.0
const ROTATION_SPEED := 14.0
const FOOTSTEP_WALK_INTERVAL := 0.38
const FOOTSTEP_RUN_INTERVAL := 0.26

@onready var _visual_root: Node3D = $VisualRoot
@onready var _character_visual: CharacterVisual = $VisualRoot/CharacterVisual
@onready var _interaction_agent: InteractionAgent = $InteractionAgent
@onready var _footstep_player: AudioStreamPlayer = $FootstepPlayer
@onready var _shadow: MeshInstance3D = $Shadow

var _footstep_timer: float = 0.0
var _run_held: bool = false


func _ready() -> void:
	add_to_group(GameConstants.GROUP_PLAYER)
	_ensure_run_action()
	_setup_footstep_stream()


func get_interaction_agent() -> InteractionAgent:
	return _interaction_agent


func _ensure_run_action() -> void:
	if not InputMap.has_action(&"run"):
		InputMap.add_action(&"run")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_SHIFT
		InputMap.action_add_event(&"run", ev)


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
	_run_held = can_move and Input.is_action_pressed(&"run")
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
	velocity.y = 0.0

	var planar := Vector2(velocity.x, velocity.z).length()
	var speed_ratio := clampf(planar / RUN_SPEED, 0.0, 1.0)
	var running := _run_held and planar > 1.0
	if _character_visual:
		_character_visual.set_move_amount(speed_ratio if can_move else 0.0, running)

	if has_input and _visual_root != null:
		var target_basis := Basis.looking_at(direction, Vector3.UP)
		_visual_root.global_transform.basis = _visual_root.global_transform.basis.slerp(
			target_basis, clampf(ROTATION_SPEED * delta, 0.0, 1.0)
		)

	move_and_slide()
	_update_footsteps(delta, planar, running, can_move)

	if InputManager.is_action_just_pressed(&"go_home"):
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
