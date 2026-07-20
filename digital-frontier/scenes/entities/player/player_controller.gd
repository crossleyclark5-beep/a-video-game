extends CharacterBody3D
## Prototype player controller for Phase 1 playable spine.
## Top-down 2.5D movement on the XZ plane. Jump/combat not included.

const MOVE_SPEED := 8.0
const ACCELERATION := 40.0
const ROTATION_SPEED := 12.0

@onready var _visual: Node3D = $VisualRoot


func _ready() -> void:
	add_to_group(GameConstants.GROUP_PLAYER)


func _physics_process(delta: float) -> void:
	if InputManager.get_context() != InputManager.Context.OVERWORLD:
		velocity.x = move_toward(velocity.x, 0.0, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, 0.0, ACCELERATION * delta)
		move_and_slide()
		return

	var input_v: Vector2 = InputManager.get_move_vector()
	# Camera-relative: forward is -Z in world for our top-down rig.
	var direction := Vector3(input_v.x, 0.0, input_v.y).normalized()

	var target_velocity := direction * MOVE_SPEED
	velocity.x = move_toward(velocity.x, target_velocity.x, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, ACCELERATION * delta)
	velocity.y = 0.0

	if direction.length_squared() > 0.001 and _visual != null:
		var target_basis := Basis.looking_at(direction, Vector3.UP)
		_visual.global_transform.basis = _visual.global_transform.basis.slerp(target_basis, clampf(ROTATION_SPEED * delta, 0.0, 1.0))

	move_and_slide()

	if InputManager.is_action_just_pressed(&"go_home"):
		SceneManager.change_scene(String(GameConstants.SCENE_HOME), true)
