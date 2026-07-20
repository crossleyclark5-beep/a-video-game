class_name EcosystemCreature
extends CharacterBody3D
## Wild Digital Frontier creature — behaviors, rarity, discovery, combat when hostile.

const GROUP := &"ecosystem_creatures"

enum Activity {
	WANDER,
	GRAZE,
	SLEEP,
	PLAY,
	DRINK,
	HIDE,
	FLEE,
	GUARD,
	CHASE,
	HUNT,
	WARN,
}

signal defeated(species_id: StringName)

var species_id: StringName = &"cotton_rabbit"
var display_name: String = "Creature"
var blurb: String = ""
var rarity: int = EcosystemCatalog.Rarity.COMMON
var temperament: int = EcosystemCatalog.Temperament.PASSIVE
var habitat: String = "Grassland"
var move_speed: float = 3.5
var flee_radius: float = 9.0
var aggro_radius: float = 12.0
var flying: bool = false
var max_hp: float = 30.0
var hp: float = 30.0
var damage: int = 6
var reward_bits: int = 8
var is_hostile: bool = false

var _player: Node3D = null
var _home: Vector3 = Vector3.ZERO
var _target: Vector3 = Vector3.ZERO
var _visual: Node3D = null
var _activity: Activity = Activity.WANDER
var _activity_timer: float = 0.0
var _attack_cd: float = 0.0
var _hit_flash: float = 0.0
var _seen: bool = false
var _pack_mates: Array[Node] = []
var _rng := RandomNumberGenerator.new()
var _gravity: float = 28.0
var _bob: float = 0.0


func setup(def: Dictionary, player: Node3D, origin: Vector3) -> void:
	species_id = def.get("id", &"cotton_rabbit")
	display_name = String(def.get("label", "Creature"))
	blurb = String(def.get("blurb", ""))
	rarity = int(def.get("rarity", EcosystemCatalog.Rarity.COMMON))
	temperament = int(def.get("temperament", EcosystemCatalog.Temperament.PASSIVE))
	habitat = String(def.get("habitat", "Grassland"))
	move_speed = float(def.get("speed", 3.5))
	flee_radius = float(def.get("flee", 9.0))
	aggro_radius = flee_radius + 3.0
	flying = bool(def.get("flying", false))
	max_hp = float(def.get("hp", 30))
	hp = maxf(max_hp, 1.0)
	damage = int(def.get("damage", 6))
	reward_bits = int(def.get("bits", 8))
	is_hostile = (
		temperament == EcosystemCatalog.Temperament.AGGRESSIVE
		or temperament == EcosystemCatalog.Temperament.PREDATOR
	)
	_player = player
	_home = origin
	global_position = origin
	_rng.seed = hash(String(species_id)) + int(origin.x * 11.0) + int(origin.z * 5.0)
	_bob = _rng.randf() * TAU
	collision_layer = 8
	collision_mask = 1
	floor_snap_length = 0.3
	_build_collision()
	_build_visual(def)
	_pick_activity(true)
	add_to_group(GROUP)
	add_to_group(GameConstants.GROUP_CREATURES)
	if is_hostile:
		add_to_group(HostileCreatureActor.GROUP)
	else:
		add_to_group(WildlifeActor.GROUP)


func is_alive() -> bool:
	return hp > 0.0


func get_index_payload() -> Dictionary:
	return {
		&"id": species_id,
		&"name": display_name,
		&"blurb": blurb,
		&"rarity": rarity,
		&"rarity_label": EcosystemCatalog.rarity_label(rarity),
		&"temperament": temperament,
		&"temperament_label": EcosystemCatalog.temperament_label(temperament),
		&"habitat": habitat,
	}


func apply_damage(amount: float, source: Node = null) -> void:
	if not is_hostile or not is_alive():
		return
	hp = maxf(0.0, hp - amount)
	_hit_flash = 0.18
	_activity = Activity.CHASE
	EventBus.sfx_play_requested.emit(&"battle_hit", global_position)
	if source:
		EventBus.combat_hit.emit(source, self, amount)
	CollectionManager.record_creature_battle(species_id, false)
	if hp <= 0.0:
		_die()


func _die() -> void:
	defeated.emit(species_id)
	EventBus.hostile_defeated.emit(species_id, global_position)
	CollectionManager.record_creature_battle(species_id, true)
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
	shape.radius = 0.32
	shape.height = 0.85
	col.shape = shape
	col.position = Vector3(0, 0.48, 0)
	add_child(col)


func _build_visual(def: Dictionary) -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var scale_v := float(def.get("scale", 0.7))
	var col: Color = def.get("color", Color(0.8, 0.7, 0.6))
	## Soft rarity tint ring (legendary/mythical glow).
	if rarity >= EcosystemCatalog.Rarity.RARE:
		StylizedMesh.add_sphere(_visual, 0.08 * scale_v, WorldPalette.UI_GOLD if rarity < EcosystemCatalog.Rarity.MYTHICAL else WorldPalette.UI_CYAN, Vector3(0, 1.1 * scale_v, 0), "RareMark")
	match String(species_id):
		"meadow_bird", "lunamoth", "byte_bat":
			StylizedMesh.add_sphere(_visual, 0.18 * scale_v, col, Vector3(0, 0.55, 0), "Body")
			StylizedMesh.add_box(_visual, Vector3(0.55 * scale_v, 0.06, 0.18 * scale_v), col.darkened(0.15), Vector3(0, 0.55, 0), "Wing")
		"park_deer", "timber_moose", "ridge_goat":
			var body_h := 0.55 if species_id != &"timber_moose" else 0.7
			StylizedMesh.add_box(_visual, Vector3(0.55 * scale_v, body_h * scale_v, 1.1 * scale_v), col, Vector3(0, body_h * 0.55 * scale_v, 0), "Body")
			StylizedMesh.add_sphere(_visual, 0.2 * scale_v, col.lightened(0.08), Vector3(0, body_h * scale_v + 0.15, -0.45 * scale_v), "Head")
		_:
			StylizedMesh.add_box(_visual, Vector3(0.4 * scale_v, 0.35 * scale_v, 0.55 * scale_v), col, Vector3(0, 0.28 * scale_v, 0), "Body")
			StylizedMesh.add_sphere(_visual, 0.16 * scale_v, col.lightened(0.1), Vector3(0, 0.42 * scale_v, -0.22 * scale_v), "Head")
			if is_hostile:
				StylizedMesh.add_box(_visual, Vector3(0.1, 0.1, 0.1), WorldPalette.UI_ACCENT, Vector3(0.1 * scale_v, 0.48 * scale_v, -0.3 * scale_v), "Eye")


func _physics_process(delta: float) -> void:
	if not is_alive() or _player == null or not is_instance_valid(_player):
		return
	_bob += delta * (5.0 if flying else 2.5)
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_hit_flash = maxf(0.0, _hit_flash - delta)
	_activity_timer -= delta
	if _visual:
		_visual.scale = Vector3.ONE * (1.1 if _hit_flash > 0.0 else 1.0)

	_try_discover()
	_update_ai(delta)

	var dest := _target
	if flying:
		dest.y = _home.y + 0.7 + sin(_bob) * 0.2
	var flat := Vector3(dest.x - global_position.x, 0.0, dest.z - global_position.z)
	var dir := Vector3.ZERO
	var moving := flat.length() > 0.25 and _activity != Activity.SLEEP and _activity != Activity.GRAZE and _activity != Activity.HIDE
	if moving:
		dir = flat.normalized()
		if _visual:
			_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(dir.x, dir.z), clampf(10.0 * delta, 0.0, 1.0))
	var spd := move_speed
	match _activity:
		Activity.FLEE, Activity.CHASE, Activity.HUNT:
			spd *= 1.35
		Activity.PLAY:
			spd *= 1.15
		Activity.SLEEP, Activity.GRAZE, Activity.HIDE:
			spd = 0.0
		_:
			pass
	velocity.x = dir.x * spd
	velocity.z = dir.z * spd
	if not flying:
		if not is_on_floor():
			velocity.y -= _gravity * delta
		elif velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y = sin(_bob) * 0.35
	move_and_slide()

	var home_d := Vector3(_home.x - global_position.x, 0.0, _home.z - global_position.z)
	if home_d.length() > 32.0 and _activity != Activity.CHASE and _activity != Activity.FLEE:
		_target = _home


func _try_discover() -> void:
	if _seen or _player == null:
		return
	var dist := global_position.distance_to(_player.global_position)
	var sight := 14.0 if rarity >= EcosystemCatalog.Rarity.RARE else 11.0
	if dist <= sight:
		_seen = true
		CollectionManager.record_creature_sighting(get_index_payload(), global_position)


func _update_ai(_delta: float) -> void:
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()

	match temperament:
		EcosystemCatalog.Temperament.PASSIVE:
			if dist < flee_radius:
				_activity = Activity.FLEE
				_target = global_position - to_player.normalized() * 10.0
				_activity_timer = 0.9
			elif _activity_timer <= 0.0:
				_pick_activity(false)
		EcosystemCatalog.Temperament.DEFENSIVE:
			if dist < flee_radius * 0.7:
				_activity = Activity.HIDE if _rng.randf() < 0.45 else Activity.FLEE
				_target = global_position - to_player.normalized() * 8.0
				_activity_timer = 1.2
			elif _activity_timer <= 0.0:
				_pick_activity(false)
		EcosystemCatalog.Temperament.PACK:
			if dist < flee_radius:
				_activity = Activity.WARN
				_warn_pack()
				_activity = Activity.FLEE
				_target = global_position - to_player.normalized() * 9.0
				_activity_timer = 1.0
			elif _activity_timer <= 0.0:
				_pick_activity(false)
		EcosystemCatalog.Temperament.AGGRESSIVE, EcosystemCatalog.Temperament.PREDATOR:
			if dist < aggro_radius:
				_activity = Activity.CHASE if temperament == EcosystemCatalog.Temperament.AGGRESSIVE else Activity.HUNT
				_target = _player.global_position
				if dist < 1.7 and _attack_cd <= 0.0:
					_attack_cd = 1.15
					_strike_player()
			elif _activity_timer <= 0.0:
				_activity = Activity.GUARD
				_pick_wander_target()
				_activity_timer = _rng.randf_range(2.0, 4.0)
		_:
			if _activity_timer <= 0.0:
				_pick_activity(false)


func _strike_player() -> void:
	## Ambush → companion battle mode (world stays visible).
	EventBus.battle_encounter_requested.emit(self, &"ambush")
	EventBus.sfx_play_requested.emit(&"battle_start", global_position)
	EventBus.ui_notification_requested.emit("%s hits!" % display_name, 1.1)


func _warn_pack() -> void:
	for node in get_tree().get_nodes_in_group(GROUP):
		if node == self or not is_instance_valid(node):
			continue
		if node is EcosystemCreature and (node as EcosystemCreature).species_id == species_id:
			var mate := node as EcosystemCreature
			if global_position.distance_to(mate.global_position) < 18.0:
				mate._activity = Activity.FLEE
				mate._activity_timer = 1.4


func _pick_activity(initial: bool) -> void:
	_activity_timer = _rng.randf_range(2.2, 5.5)
	if is_hostile:
		_activity = Activity.GUARD if _rng.randf() < 0.5 else Activity.WANDER
		_pick_wander_target()
		return
	var roll := _rng.randf()
	if initial:
		roll = 0.2
	if roll < 0.22:
		_activity = Activity.GRAZE
		_target = global_position
	elif roll < 0.32:
		_activity = Activity.SLEEP
		_target = global_position
	elif roll < 0.45:
		_activity = Activity.PLAY
		_pick_wander_target()
	elif roll < 0.55:
		_activity = Activity.DRINK
		_target = _home + Vector3(_rng.randf_range(-3, 3), 0, _rng.randf_range(-3, 3))
	else:
		_activity = Activity.WANDER
		_pick_wander_target()


func _pick_wander_target() -> void:
	var ang := _rng.randf() * TAU
	var r := _rng.randf_range(2.0, 9.0)
	_target = _home + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
