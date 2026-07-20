class_name WildlifeActor
extends Node3D
## Friendly roaming animal — wanders, flees the player, cheap (no CharacterBody).

const GROUP := &"wildlife"

var species_id: StringName = &"rabbit"
var display_name: String = "Wildlife"
var move_speed: float = 3.5
var flee_radius: float = 9.0
var flying: bool = false

var _player: Node3D = null
var _home: Vector3 = Vector3.ZERO
var _target: Vector3 = Vector3.ZERO
var _visual: Node3D = null
var _bob: float = 0.0
var _alive: bool = true
var _state: StringName = &"wander"
var _state_timer: float = 0.0
var _rng := RandomNumberGenerator.new()


func setup(def: Dictionary, player: Node3D, origin: Vector3) -> void:
	species_id = def.get("id", &"rabbit")
	display_name = String(def.get("label", "Wildlife"))
	move_speed = float(def.get("speed", 3.5))
	flee_radius = float(def.get("flee", 9.0))
	flying = bool(def.get("flying", false))
	_player = player
	_home = origin
	global_position = origin
	_rng.seed = hash(String(species_id)) + int(origin.x * 10.0) + int(origin.z * 7.0)
	_bob = _rng.randf() * TAU
	_build_visual(def)
	_pick_wander_target()
	add_to_group(GROUP)
	add_to_group(GameConstants.GROUP_CREATURES)


func _build_visual(def: Dictionary) -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var scale_v := float(def.get("scale", 0.7))
	var col: Color = def.get("color", Color(0.8, 0.7, 0.6))
	match String(species_id):
		"bird":
			StylizedMesh.add_sphere(_visual, 0.18 * scale_v, col, Vector3(0, 0.5, 0), "Body")
			StylizedMesh.add_box(_visual, Vector3(0.55 * scale_v, 0.06, 0.18 * scale_v), col.darkened(0.15), Vector3(0, 0.5, 0), "Wing")
		"deer", "moose":
			var body_h := 0.55 if species_id == &"deer" else 0.7
			StylizedMesh.add_box(_visual, Vector3(0.55 * scale_v, body_h * scale_v, 1.1 * scale_v), col, Vector3(0, body_h * 0.55 * scale_v, 0), "Body")
			StylizedMesh.add_sphere(_visual, 0.2 * scale_v, col.lightened(0.08), Vector3(0, body_h * scale_v + 0.15, -0.45 * scale_v), "Head")
			if species_id == &"moose":
				StylizedMesh.add_box(_visual, Vector3(0.55 * scale_v, 0.08, 0.12), col.darkened(0.2), Vector3(0, body_h * scale_v + 0.35, -0.4 * scale_v), "Antler")
		_:
			StylizedMesh.add_box(_visual, Vector3(0.35 * scale_v, 0.28 * scale_v, 0.5 * scale_v), col, Vector3(0, 0.2 * scale_v, 0), "Body")
			StylizedMesh.add_sphere(_visual, 0.14 * scale_v, col.lightened(0.1), Vector3(0, 0.32 * scale_v, -0.22 * scale_v), "Head")


func _process(delta: float) -> void:
	if not _alive or _player == null or not is_instance_valid(_player):
		return
	_bob += delta * (5.0 if flying else 3.0)
	_state_timer -= delta
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	if dist < flee_radius:
		_state = &"flee"
		_target = global_position - to_player.normalized() * 8.0
		_state_timer = 0.8
	elif _state == &"flee" and dist > flee_radius + 4.0:
		_state = &"wander"
		_pick_wander_target()
	elif _state_timer <= 0.0:
		_pick_wander_target()

	var dest := _target
	dest.y = _home.y + (0.9 + sin(_bob) * 0.25 if flying else 0.0)
	var flat := Vector3(dest.x - global_position.x, 0.0, dest.z - global_position.z)
	if flat.length() > 0.15:
		var dir := flat.normalized()
		var spd := move_speed * (1.35 if _state == &"flee" else 1.0)
		global_position += dir * spd * delta
		if _visual:
			_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(dir.x, dir.z), clampf(10.0 * delta, 0.0, 1.0))
	if flying and _visual:
		_visual.position.y = sin(_bob) * 0.15
	## Soft leash back toward home so packs stay regional.
	var home_flat := Vector3(_home.x - global_position.x, 0.0, _home.z - global_position.z)
	if home_flat.length() > 28.0:
		_target = _home
		_state = &"return"


func _pick_wander_target() -> void:
	_state = &"wander"
	_state_timer = _rng.randf_range(2.5, 5.5)
	var ang := _rng.randf() * TAU
	var r := _rng.randf_range(2.0, 9.0)
	_target = _home + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
