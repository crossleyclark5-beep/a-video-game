class_name CarVehicle
extends VehicleBase
## Arcade ground car — fun handheld driving, not a sim.


var _speed: float = 0.0
var _steer_visual: float = 0.0


func _drive(delta: float) -> void:
	var d := data
	var max_spd := d.max_speed if d else 18.0
	var accel := d.acceleration if d else 14.0
	var brake := d.brake_force if d else 22.0
	var reverse := d.reverse_speed if d else 7.0
	var turn := d.turn_rate if d else 2.4
	var friction := d.coast_friction if d else 6.0
	var offroad := d.offroad_mul if d else 0.72

	var input_v := InputManager.get_move_vector()
	## Stick Y: forward = accelerate, back = brake / reverse. Stick X = steer.
	var throttle := clampf(-input_v.y, -1.0, 1.0)
	var steer_in := clampf(-input_v.x, -1.0, 1.0)

	var surface_mul := 1.0
	if not _on_roadish():
		surface_mul = offroad

	if throttle > 0.05:
		_speed = move_toward(_speed, max_spd * throttle * surface_mul, accel * delta)
	elif throttle < -0.05:
		if _speed > 0.4:
			_speed = move_toward(_speed, 0.0, brake * delta)
		else:
			_speed = move_toward(_speed, -reverse * absf(throttle) * surface_mul, accel * 0.75 * delta)
	else:
		_speed = move_toward(_speed, 0.0, friction * delta)

	var speed_ratio := clampf(absf(_speed) / maxf(max_spd, 0.01), 0.0, 1.0)
	## Arcade: more turn authority at mid-speed, less at standstill / top speed.
	var turn_auth := 0.15 + speed_ratio * 0.85
	if absf(_speed) < 0.35:
		turn_auth = 0.0
	var yaw := steer_in * turn * turn_auth * signf(_speed if absf(_speed) > 0.01 else 1.0)
	rotation.y += yaw * delta
	_steer_visual = lerpf(_steer_visual, steer_in, clampf(8.0 * delta, 0.0, 1.0))

	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.001:
		forward = forward.normalized()
	velocity.x = forward.x * _speed
	velocity.z = forward.z * _speed

	if not is_on_floor():
		velocity.y -= 32.0 * delta
	elif velocity.y < 0.0:
		## Soft suspension settle.
		velocity.y = lerpf(velocity.y, 0.0, clampf(12.0 * delta, 0.0, 1.0))

	move_and_slide()
	## Keep driver ghost locked to seat.
	if _driver:
		_driver.global_position = global_position + Vector3(0, 0.4, 0)


func _on_roadish() -> bool:
	## Cheap surface read — roads/paths feel faster than grass.
	var space := get_world_3d().direct_space_state
	var from: Vector3 = global_position + Vector3(0, 1.2, 0)
	var to: Vector3 = global_position + Vector3(0, -2.5, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 | 2
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider = hit.get("collider")
	if collider == null:
		return true
	var n := String(collider.name).to_lower()
	var parent_n := ""
	if collider is Node and (collider as Node).get_parent():
		parent_n = String((collider as Node).get_parent().name).to_lower()
	for key in ["road", "path", "asphalt", "sidewalk", "bridge", "lot", "pad"]:
		if key in n or key in parent_n:
			return true
	return false
