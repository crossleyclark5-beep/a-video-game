class_name WaterBody
extends Node3D
## Living water volume — bobbing surface, ripple pulse, registers for aquatics.

signal registered(water: WaterBody)

var water_bounds: AABB = AABB()
var _mesh: MeshInstance3D = null
var _base_y: float = 0.0
var _phase: float = 0.0
var _ripple: float = 0.0


static func attach_to_mesh(mesh: MeshInstance3D, size: Vector3) -> WaterBody:
	var body := WaterBody.new()
	body.name = "WaterBody"
	mesh.add_child(body)
	body.setup(mesh, size)
	return body


func setup(mesh: MeshInstance3D, size: Vector3) -> void:
	_mesh = mesh
	_base_y = mesh.position.y
	_phase = randf() * TAU
	var half := size * 0.5
	var origin := mesh.global_position if mesh.is_inside_tree() else mesh.position
	## Local-space relative to parent mesh; convert after tree entry.
	call_deferred("_finalize_bounds", size, half)


func _finalize_bounds(size: Vector3, _half: Vector3) -> void:
	if _mesh == null or not is_instance_valid(_mesh):
		return
	var center := _mesh.global_position
	water_bounds = AABB(
		center - Vector3(size.x * 0.45, 0.35, size.z * 0.45),
		Vector3(size.x * 0.9, 0.7, size.z * 0.9)
	)
	add_to_group(&"water_bodies")
	registered.emit(self)
	## Soft shore trigger for splash feedback.
	var area := Area3D.new()
	area.name = "ShoreTrigger"
	area.collision_layer = 0
	area.collision_mask = 4  ## player
	area.monitoring = true
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(water_bounds.size.x, 1.2, water_bounds.size.z)
	shape.shape = box
	shape.position = Vector3(0, 0.2, 0)
	area.add_child(shape)
	## Reparent area at world-ish offset under this node (child of mesh).
	add_child(area)
	area.body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_phase += delta * 1.6
	_ripple = maxf(0.0, _ripple - delta)
	if _mesh:
		_mesh.position.y = _base_y + sin(_phase) * 0.04 + (_ripple * 0.06)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(GameConstants.GROUP_PLAYER):
		_ripple = 1.0
		EventBus.sfx_play_requested.emit(&"ui_blip", global_position)
