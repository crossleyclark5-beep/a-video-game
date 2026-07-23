class_name AquaticActor
extends Node3D
## Fish / water creature — swims inside a registered water volume AABB.

const GROUP := &"aquatic"

var species_id: StringName = &"silverfin"
var display_name: String = "Fish"
var move_speed: float = 2.2
var hostile: bool = false
var max_hp: float = 25.0
var hp: float = 25.0
var damage: int = 5
var reward_bits: int = 10

var _bounds: AABB = AABB()
var _player: Node3D = null
var _target: Vector3 = Vector3.ZERO
var _visual: Node3D = null
var _timer: float = 0.0
var _attack_cd: float = 0.0
var _rng := RandomNumberGenerator.new()
var _indexed: bool = false
var _ai_detail: int = 2
var _scattering: bool = false


func setup(def: Dictionary, player: Node3D, bounds: AABB, origin: Vector3) -> void:
	species_id = def.get("id", &"silverfin")
	display_name = String(def.get("label", "Fish"))
	move_speed = float(def.get("speed", 2.2))
	hostile = bool(def.get("hostile", false))
	max_hp = float(def.get("hp", 25))
	hp = max_hp
	damage = int(def.get("damage", 5))
	reward_bits = int(def.get("bits", 10))
	_player = player
	_bounds = bounds
	global_position = _clamp_in_water(origin)
	_rng.seed = hash(String(species_id)) + int(origin.x * 3.0)
	_build_visual(def)
	_pick_target()
	add_to_group(GROUP)
	add_to_group(GameConstants.GROUP_CREATURES)
	if hostile:
		add_to_group(HostileCreatureActor.GROUP)


func apply_damage(amount: float, _source: Node = null) -> void:
	if not hostile or hp <= 0.0:
		return
	hp -= amount
	EventBus.sfx_play_requested.emit(&"battle_hit", global_position)
	if hp <= 0.0:
		EventBus.hostile_defeated.emit(species_id, global_position)
		InventoryManager.add_bits(reward_bits)
		QuestManager.notify_objective(&"defeat", species_id, 1)
		QuestManager.notify_objective(&"defeat", &"any", 1)
		EventBus.ui_notification_requested.emit("%s defeated · +%d Bits" % [display_name, reward_bits], 2.0)
		queue_free()


func _build_visual(def: Dictionary) -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var scale_v := float(def.get("scale", 0.5))
	var col: Color = def.get("color", Color(0.7, 0.85, 1.0))
	StylizedMesh.add_box(_visual, Vector3(0.15 * scale_v, 0.18 * scale_v, 0.55 * scale_v), col, Vector3.ZERO, "Body")
	StylizedMesh.add_box(_visual, Vector3(0.04, 0.25 * scale_v, 0.18 * scale_v), col.darkened(0.15), Vector3(0, 0, 0.28 * scale_v), "Tail")


func set_ai_detail(level: int) -> void:
	_ai_detail = clampi(level, 0, 2)


func _process(delta: float) -> void:
	if _ai_detail <= 0:
		return
	_timer -= delta
	_attack_cd = maxf(0.0, _attack_cd - delta)
	if _timer <= 0.0:
		_pick_target()
	var spd := move_speed * (1.55 if _scattering else 1.0) * (0.75 if _ai_detail == 1 else 1.0)
	if _player and is_instance_valid(_player):
		var d := global_position.distance_to(_player.global_position)
		if d < 12.0 and not _indexed:
			_indexed = true
			CollectionManager.record_creature_sighting({
				&"id": species_id,
				&"name": display_name,
				&"blurb": "Aquatic life of the Grassland waters.",
				&"rarity": EcosystemCatalog.Rarity.COMMON if not hostile else EcosystemCatalog.Rarity.UNCOMMON,
				&"rarity_label": "Common" if not hostile else "Uncommon",
				&"habitat": "Water",
				&"temperament_label": "Aggressive" if hostile else "Passive",
			}, global_position, true)
		## School scatter when a Field Unit wades close.
		if not hostile and d < 4.5:
			_scattering = true
			var away := global_position - _player.global_position
			away.y = 0.0
			if away.length() < 0.1:
				away = Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1))
			_target = _clamp_in_water(global_position + away.normalized() * 6.0)
			_timer = 0.8
		elif d > 7.0:
			_scattering = false
		if hostile and d < 10.0:
			_target = _player.global_position
			_target.y = clampf(_target.y, _bounds.position.y + 0.2, _bounds.end.y - 0.2)
		if hostile and d < 1.8 and _attack_cd <= 0.0:
			_attack_cd = 1.3
			var health := _player.get_node_or_null("PlayerHealth")
			if health and health.has_method("apply_damage"):
				health.call("apply_damage", damage, self)

	var flat := _target - global_position
	if flat.length() > 0.15:
		var dir := flat.normalized()
		global_position += dir * spd * delta
		global_position = _clamp_in_water(global_position)
		if _visual:
			_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(dir.x, dir.z), clampf(8.0 * delta, 0.0, 1.0))
			_visual.position.y = sin(Time.get_ticks_msec() * 0.008 + global_position.x) * 0.05


func _pick_target() -> void:
	_timer = _rng.randf_range(1.5, 3.5)
	## Soft school bias — fish keep near the volume center more often.
	var center := _bounds.get_center()
	if not hostile and _rng.randf() < 0.45:
		_target = Vector3(
			lerpf(center.x, _rng.randf_range(_bounds.position.x, _bounds.end.x), 0.55),
			_rng.randf_range(_bounds.position.y + 0.15, _bounds.end.y - 0.15),
			lerpf(center.z, _rng.randf_range(_bounds.position.z, _bounds.end.z), 0.55),
		)
		return
	_target = Vector3(
		_rng.randf_range(_bounds.position.x, _bounds.end.x),
		_rng.randf_range(_bounds.position.y + 0.15, _bounds.end.y - 0.15),
		_rng.randf_range(_bounds.position.z, _bounds.end.z),
	)


func _clamp_in_water(p: Vector3) -> Vector3:
	return Vector3(
		clampf(p.x, _bounds.position.x, _bounds.end.x),
		clampf(p.y, _bounds.position.y + 0.1, _bounds.end.y - 0.1),
		clampf(p.z, _bounds.position.z, _bounds.end.z),
	)
