class_name HostileCreatureActor
extends CharacterBody3D
## Overworld threat — wanders, aggro-chases, melee hits, drops Bits.

const GROUP := &"hostile_creatures"

signal defeated(species_id: StringName)

var species_id: StringName = &"glitchmite"
var display_name: String = "Hostile"
var move_speed: float = 3.5
var aggro_radius: float = 12.0
var max_hp: float = 30.0
var hp: float = 30.0
var damage: int = 6
var reward_bits: int = 8
var flying: bool = false

var _player: Node3D = null
var _home: Vector3 = Vector3.ZERO
var _target: Vector3 = Vector3.ZERO
var _visual: Node3D = null
var _state: StringName = &"wander"
var _attack_cd: float = 0.0
var _hit_flash: float = 0.0
var _state_timer: float = 0.0
var _rng := RandomNumberGenerator.new()
var _gravity: float = 28.0


func setup(def: Dictionary, player: Node3D, origin: Vector3) -> void:
	species_id = def.get("id", &"glitchmite")
	display_name = String(def.get("label", "Hostile"))
	move_speed = float(def.get("speed", 3.5))
	aggro_radius = float(def.get("aggro", 12.0))
	max_hp = float(def.get("hp", 30))
	hp = max_hp
	damage = int(def.get("damage", 6))
	reward_bits = int(def.get("bits", 8))
	flying = bool(def.get("flying", false))
	_player = player
	_home = origin
	global_position = origin
	_rng.seed = hash(String(species_id)) + int(origin.x * 13.0)
	collision_layer = 8  ## entities
	collision_mask = 1   ## world static
	floor_snap_length = 0.3
	_build_collision()
	_build_visual(def)
	_pick_wander()
	add_to_group(GROUP)
	add_to_group(GameConstants.GROUP_CREATURES)


func is_alive() -> bool:
	return hp > 0.0


func apply_damage(amount: float, source: Node = null) -> void:
	if not is_alive():
		return
	hp = maxf(0.0, hp - amount)
	_hit_flash = 0.18
	_state = &"chase"
	EventBus.sfx_play_requested.emit(&"battle_hit", global_position)
	if source:
		EventBus.combat_hit.emit(source, self, amount)
	if hp <= 0.0:
		_die()


func _die() -> void:
	defeated.emit(species_id)
	EventBus.hostile_defeated.emit(species_id, global_position)
	if reward_bits > 0:
		InventoryManager.add_bits(reward_bits)
	CreatureManager.grant_adventure_experience(6)
	QuestManager.notify_objective(&"defeat", species_id, 1)
	QuestManager.notify_objective(&"defeat", &"any", 1)
	EventBus.ui_notification_requested.emit("%s defeated · +%d Bits" % [display_name, reward_bits], 2.0)
	EventBus.sfx_play_requested.emit(&"battle_win", global_position)
	queue_free()


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 0.9
	col.shape = shape
	col.position = Vector3(0, 0.5, 0)
	add_child(col)


func _build_visual(def: Dictionary) -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var scale_v := float(def.get("scale", 0.8))
	var col: Color = def.get("color", Color(0.8, 0.2, 0.4))
	StylizedMesh.add_box(_visual, Vector3(0.55 * scale_v, 0.45 * scale_v, 0.7 * scale_v), col, Vector3(0, 0.35 * scale_v, 0), "Body")
	StylizedMesh.add_sphere(_visual, 0.22 * scale_v, col.lightened(0.1), Vector3(0, 0.7 * scale_v, -0.2 * scale_v), "Head")
	StylizedMesh.add_box(_visual, Vector3(0.12, 0.12, 0.12), WorldPalette.UI_ACCENT, Vector3(0.12 * scale_v, 0.75 * scale_v, -0.32 * scale_v), "Eye")
	if flying:
		StylizedMesh.add_box(_visual, Vector3(0.7 * scale_v, 0.05, 0.25 * scale_v), col.darkened(0.2), Vector3(0, 0.55 * scale_v, 0), "Wing")


func _physics_process(delta: float) -> void:
	if not is_alive() or _player == null or not is_instance_valid(_player):
		return
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_hit_flash = maxf(0.0, _hit_flash - delta)
	if _visual:
		_visual.scale = Vector3.ONE * (1.12 if _hit_flash > 0.0 else 1.0)

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	if dist < aggro_radius:
		_state = &"chase"
		_target = _player.global_position
	elif _state == &"chase" and dist > aggro_radius + 6.0:
		_state = &"wander"
		_pick_wander()

	_state_timer -= delta
	if _state == &"wander" and _state_timer <= 0.0:
		_pick_wander()

	var dest := _target
	var flat := Vector3(dest.x - global_position.x, 0.0, dest.z - global_position.z)
	var dir := Vector3.ZERO
	if flat.length() > 0.4:
		dir = flat.normalized()
		if _visual:
			_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(dir.x, dir.z), clampf(12.0 * delta, 0.0, 1.0))

	var spd := move_speed * (1.15 if _state == &"chase" else 0.75)
	velocity.x = dir.x * spd
	velocity.z = dir.z * spd
	if not flying:
		if not is_on_floor():
			velocity.y -= _gravity * delta
		elif velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y = sin(Time.get_ticks_msec() * 0.004) * 0.4
	move_and_slide()

	## Soft leash
	var home_d := Vector3(_home.x - global_position.x, 0.0, _home.z - global_position.z)
	if home_d.length() > 40.0 and _state != &"chase":
		_target = _home

	if _state == &"chase" and dist < 1.6 and _attack_cd <= 0.0:
		_attack_cd = 1.15
		_strike_player()


func _strike_player() -> void:
	if _player and _player.has_method("apply_damage"):
		_player.call("apply_damage", damage, self)
	elif _player:
		var health := _player.get_node_or_null("PlayerHealth")
		if health and health.has_method("apply_damage"):
			health.call("apply_damage", damage, self)
	EventBus.sfx_play_requested.emit(&"battle_hit", global_position)
	EventBus.ui_notification_requested.emit("%s hits!" % display_name, 1.2)


func _pick_wander() -> void:
	_state = &"wander"
	_state_timer = _rng.randf_range(2.0, 4.5)
	var ang := _rng.randf() * TAU
	var r := _rng.randf_range(2.0, 8.0)
	_target = _home + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
