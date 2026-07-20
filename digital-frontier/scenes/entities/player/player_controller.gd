extends CharacterBody3D
## Player controller — free 2.5D top-down movement with polished feel.
## Visuals live under VisualRoot/CharacterVisual (idle/walk, animation-ready).

const MOVE_SPEED := 7.5
const ACCELERATION := 28.0
const DECELERATION := 34.0
const ROTATION_SPEED := 14.0

@onready var _visual_root: Node3D = $VisualRoot
@onready var _character_visual: CharacterVisual = $VisualRoot/CharacterVisual


func _ready() -> void:
	add_to_group(GameConstants.GROUP_PLAYER)


func _physics_process(delta: float) -> void:
	var ctx := InputManager.get_context()
	var can_move := (
		ctx == InputManager.Context.OVERWORLD
		or ctx == InputManager.Context.BUILDING_INTERIOR
	)

	var input_v := Vector2.ZERO
	if can_move:
		input_v = InputManager.get_move_vector()

	var direction := Vector3(input_v.x, 0.0, input_v.y)
	var has_input := direction.length_squared() > 0.001
	if has_input:
		direction = direction.normalized()

	var target_velocity := direction * MOVE_SPEED
	var accel := ACCELERATION if has_input else DECELERATION
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)
	velocity.y = 0.0

	var speed_ratio := clampf(Vector2(velocity.x, velocity.z).length() / MOVE_SPEED, 0.0, 1.0)
	if _character_visual:
		_character_visual.set_move_amount(speed_ratio if can_move else 0.0)

	if has_input and _visual_root != null:
		var target_basis := Basis.looking_at(direction, Vector3.UP)
		_visual_root.global_transform.basis = _visual_root.global_transform.basis.slerp(
			target_basis, clampf(ROTATION_SPEED * delta, 0.0, 1.0)
		)

	move_and_slide()

	if InputManager.is_action_just_pressed(&"go_home"):
		SceneManager.change_scene(String(GameConstants.SCENE_HOME), true)
