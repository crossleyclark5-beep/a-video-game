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
var _ai_detail: int = 2
var _tags: Array = []
var _patrol: Array[Vector3] = []
var _patrol_i: int = 0
var _wing: Node3D = null


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
	_tags = def.get("tags", [])
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
	if is_hostile:
		_build_patrol_route()
	_pick_activity(true)
	add_to_group(GROUP)
	add_to_group(GameConstants.GROUP_CREATURES)
	if is_hostile:
		add_to_group(HostileCreatureActor.GROUP)
	else:
		add_to_group(WildlifeActor.GROUP)
	if not EventBus.weather_changed.is_connected(_on_weather_changed):
		EventBus.weather_changed.connect(_on_weather_changed)


func set_ai_detail(level: int) -> void:
	## 2 full FSM · 1 slow wander · 0 paused by LivingWorldController.
	_ai_detail = clampi(level, 0, 2)


func _on_weather_changed(weather: StringName) -> void:
	if is_hostile:
		return
	if (weather == &"rain" or weather == &"storm") and _tags.has(&"rain_hide"):
		_activity = Activity.HIDE
		_target = _home
		_activity_timer = 6.0
	elif weather == &"fog" and rarity >= EcosystemCatalog.Rarity.RARE:
		## Rare mist encounters feel braver in fog.
		_activity_timer = mini(_activity_timer, 1.0)


func _build_patrol_route() -> void:
	_patrol.clear()
	for i in 4:
		var ang := float(i) * TAU * 0.25 + _rng.randf() * 0.4
		var r := 5.0 + _rng.randf() * 6.0
		_patrol.append(_home + Vector3(cos(ang) * r, 0.0, sin(ang) * r))


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
	if is_hostile:
		WorldSimMemory.note_hostile_cleared(global_position, species_id)
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
	var col: Color = WorldPalette.quantize(def.get("color", Color(0.8, 0.7, 0.6)) as Color)
	## Soft rarity tint ring (legendary/mythical glow).
	if rarity >= EcosystemCatalog.Rarity.RARE:
		StylizedMesh.add_sphere(_visual, 0.08 * scale_v, WorldPalette.UI_GOLD if rarity < EcosystemCatalog.Rarity.MYTHICAL else WorldPalette.UI_CYAN, Vector3(0, 1.1 * scale_v, 0), "RareMark")
	## Digimon-inspired DF look-alike enemies.
	if bool(def.get("lookalike", false)) or CreatureLookalikeCatalog.has_creature(species_id):
		var kit := CreatureLookalikeKit.attach_for_species(_visual, species_id, 1.0)
		if kit:
			return
	match String(species_id):
		"meadow_bird":
			_viz_bird(col, scale_v, false)
		"lunamoth":
			_viz_bird(col, scale_v, true)
		"byte_bat":
			_viz_bat(col, scale_v)
		"park_deer", "timber_moose", "ridge_goat":
			_viz_ungulate(col, scale_v, species_id == &"timber_moose", species_id == &"ridge_goat")
		"cotton_rabbit", "phantom_hare":
			_viz_rabbit(col, scale_v, species_id == &"phantom_hare")
		"hex_squirrel":
			_viz_squirrel(col, scale_v)
		"glow_kit", "pack_pup", "scrub_wolf":
			_viz_canid(col, scale_v, species_id)
		"thorn_boar":
			_viz_boar(col, scale_v)
		"glitchmite":
			_viz_mite(col, scale_v)
		_:
			StylizedMesh.add_box(_visual, Vector3(0.4 * scale_v, 0.35 * scale_v, 0.55 * scale_v), col, Vector3(0, 0.28 * scale_v, 0), "Body")
			StylizedMesh.add_sphere(_visual, 0.16 * scale_v, col.lightened(0.1), Vector3(0, 0.42 * scale_v, -0.22 * scale_v), "Head")
			if is_hostile:
				StylizedMesh.add_box(_visual, Vector3(0.1, 0.1, 0.1), WorldPalette.UI_ACCENT, Vector3(0.1 * scale_v, 0.48 * scale_v, -0.3 * scale_v), "Eye")


func _viz_bird(col: Color, s: float, moth: bool) -> void:
	StylizedMesh.add_sphere(_visual, 0.16 * s, col, Vector3(0, 0.5 * s, 0), "Body")
	var wing_c := col.lightened(0.15) if moth else col.darkened(0.1)
	var w := StylizedMesh.add_box(_visual, Vector3((0.7 if moth else 0.55) * s, 0.05 * s, 0.2 * s), wing_c, Vector3(0, 0.52 * s, 0), "Wing")
	if moth:
		w.material_override = StylizedMesh.make_material(wing_c, 1.0, 0.0, 0.25, &"flat")
	_wing = w
	StylizedMesh.add_box(_visual, Vector3(0.06 * s, 0.06 * s, 0.18 * s), col.darkened(0.2), Vector3(0, 0.48 * s, -0.2 * s), "Tail")
	StylizedCreatureKit.eye_pair(_visual, Vector3(0, 0.55 * s, 0.12 * s), 0.05 * s, 0.025 * s)


func _viz_bat(col: Color, s: float) -> void:
	StylizedMesh.add_sphere(_visual, 0.15 * s, col, Vector3(0, 0.48 * s, 0), "Body")
	StylizedMesh.add_box(_visual, Vector3(0.75 * s, 0.04 * s, 0.22 * s), col.darkened(0.15), Vector3(0, 0.5 * s, 0), "Wing")
	StylizedCreatureKit.ear_pair(_visual, 0.62 * s, 0.1 * s, Vector3(0.06 * s, 0.12 * s, 0.04 * s), col.lightened(0.05))
	StylizedCreatureKit.eye_pair(_visual, Vector3(0, 0.5 * s, 0.12 * s), 0.05 * s, 0.03 * s, WorldPalette.UI_ACCENT)


func _viz_ungulate(col: Color, s: float, moose: bool, goat: bool) -> void:
	var body_h := 0.7 if moose else 0.55
	StylizedMesh.add_box(_visual, Vector3(0.5 * s, body_h * s, 1.05 * s), col, Vector3(0, body_h * 0.55 * s, 0), "Body")
	StylizedMesh.add_sphere(_visual, 0.18 * s, col.lightened(0.08), Vector3(0, body_h * s + 0.12 * s, -0.48 * s), "Head")
	StylizedCreatureKit.quadruped_legs(_visual, body_h * 0.35 * s, s, col)
	if moose:
		StylizedMesh.add_box(_visual, Vector3(0.45 * s, 0.08 * s, 0.2 * s), col.darkened(0.1), Vector3(-0.15 * s, body_h * s + 0.35 * s, -0.45 * s), "AntlerL")
		StylizedMesh.add_box(_visual, Vector3(0.45 * s, 0.08 * s, 0.2 * s), col.darkened(0.1), Vector3(0.15 * s, body_h * s + 0.35 * s, -0.45 * s), "AntlerR")
	elif goat:
		StylizedMesh.add_box(_visual, Vector3(0.04 * s, 0.16 * s, 0.04 * s), Color(0.9, 0.88, 0.8), Vector3(-0.06 * s, body_h * s + 0.28 * s, -0.42 * s), "HornL")
		StylizedMesh.add_box(_visual, Vector3(0.04 * s, 0.16 * s, 0.04 * s), Color(0.9, 0.88, 0.8), Vector3(0.06 * s, body_h * s + 0.28 * s, -0.42 * s), "HornR")
	else:
		StylizedCreatureKit.ear_pair(_visual, body_h * s + 0.22 * s, 0.12 * s, Vector3(0.05 * s, 0.1 * s, 0.04 * s), col)
	StylizedCreatureKit.tail(_visual, Vector3(0, body_h * 0.6 * s, 0.5 * s), 0.25 * s, 0.06 * s, col.darkened(0.1))


func _viz_rabbit(col: Color, s: float, phantom: bool) -> void:
	StylizedMesh.add_sphere(_visual, 0.18 * s, col, Vector3(0, 0.28 * s, 0), "Body")
	StylizedMesh.add_sphere(_visual, 0.14 * s, col.lightened(0.08), Vector3(0, 0.42 * s, -0.12 * s), "Head")
	StylizedCreatureKit.ear_pair(_visual, 0.58 * s, 0.08 * s, Vector3(0.05 * s, 0.2 * s, 0.04 * s), col)
	StylizedCreatureKit.tail(_visual, Vector3(0, 0.28 * s, 0.18 * s), 0.12 * s, 0.1 * s, Color(0.95, 0.95, 0.92), true)
	if phantom:
		StylizedMesh.add_sphere(_visual, 0.08 * s, WorldPalette.UI_CYAN, Vector3(0, 0.55 * s, 0), "GhostGlow")


func _viz_squirrel(col: Color, s: float) -> void:
	StylizedMesh.add_sphere(_visual, 0.14 * s, col, Vector3(0, 0.28 * s, 0), "Body")
	StylizedMesh.add_sphere(_visual, 0.11 * s, col.lightened(0.08), Vector3(0, 0.4 * s, -0.1 * s), "Head")
	StylizedCreatureKit.ear_pair(_visual, 0.5 * s, 0.07 * s, Vector3(0.04 * s, 0.08 * s, 0.03 * s), col)
	StylizedCreatureKit.tail(_visual, Vector3(0, 0.35 * s, 0.2 * s), 0.35 * s, 0.12 * s, col.lightened(0.05), true)
	StylizedCreatureKit.eye_pair(_visual, Vector3(0, 0.42 * s, -0.02 * s), 0.04 * s, 0.022 * s)


func _viz_canid(col: Color, s: float, sid: StringName) -> void:
	StylizedMesh.add_box(_visual, Vector3(0.35 * s, 0.32 * s, 0.6 * s), col, Vector3(0, 0.32 * s, 0), "Body")
	StylizedMesh.add_sphere(_visual, 0.14 * s, col.lightened(0.06), Vector3(0, 0.4 * s, -0.32 * s), "Head")
	StylizedCreatureKit.snout(_visual, Vector3(0, 0.36 * s, -0.45 * s), Vector3(0.1 * s, 0.08 * s, 0.14 * s), col.darkened(0.05))
	StylizedCreatureKit.ear_pair(_visual, 0.52 * s, 0.1 * s, Vector3(0.06 * s, 0.12 * s, 0.04 * s), col)
	StylizedCreatureKit.quadruped_legs(_visual, 0.22 * s, s * 0.85, col)
	var bushy := sid == &"glow_kit"
	var tip_c := WorldPalette.UI_CYAN if sid == &"glow_kit" else col.darkened(0.1)
	var tip := StylizedCreatureKit.tail(_visual, Vector3(0, 0.35 * s, 0.32 * s), 0.35 * s, 0.08 * s, tip_c, bushy)
	if sid == &"glow_kit":
		tip.material_override = StylizedMesh.make_material(tip_c, 1.0, 0.0, 0.35, &"flat")
	if sid == &"scrub_wolf":
		StylizedMesh.add_box(_visual, Vector3(0.08 * s, 0.08 * s, 0.08 * s), WorldPalette.UI_ACCENT, Vector3(0.06 * s, 0.42 * s, -0.48 * s), "Eye")


func _viz_boar(col: Color, s: float) -> void:
	StylizedMesh.add_box(_visual, Vector3(0.5 * s, 0.4 * s, 0.75 * s), col, Vector3(0, 0.35 * s, 0), "Body")
	StylizedMesh.add_sphere(_visual, 0.18 * s, col.darkened(0.05), Vector3(0, 0.38 * s, -0.42 * s), "Head")
	StylizedMesh.add_box(_visual, Vector3(0.04 * s, 0.04 * s, 0.14 * s), Color(0.9, 0.88, 0.8), Vector3(-0.08 * s, 0.32 * s, -0.55 * s), "TuskL")
	StylizedMesh.add_box(_visual, Vector3(0.04 * s, 0.04 * s, 0.14 * s), Color(0.9, 0.88, 0.8), Vector3(0.08 * s, 0.32 * s, -0.55 * s), "TuskR")
	StylizedCreatureKit.quadruped_legs(_visual, 0.22 * s, s, col)
	StylizedMesh.add_box(_visual, Vector3(0.12 * s, 0.1 * s, 0.08 * s), col.darkened(0.15), Vector3(0, 0.55 * s, -0.1 * s), "Ridge")


func _viz_mite(col: Color, s: float) -> void:
	## Optional digital-creature library accent (Digimon-inspired silhouette language).
	if CharacterKit.is_available() and CharacterCatalog.has_character(&"digital_mite") and s >= 0.55:
		var mite := CharacterKit.attach_under(_visual, &"digital_mite", clampf(s * 0.9, 0.55, 1.35), "LibraryMite")
		if mite:
			mite.position = Vector3(0, 0.05, 0)
			return
	StylizedMesh.add_box(_visual, Vector3(0.35 * s, 0.28 * s, 0.4 * s), col, Vector3(0, 0.28 * s, 0), "Body")
	StylizedMesh.add_sphere(_visual, 0.12 * s, col.lightened(0.1), Vector3(0, 0.4 * s, -0.18 * s), "Head")
	StylizedMesh.add_box(_visual, Vector3(0.08 * s, 0.08 * s, 0.08 * s), WorldPalette.UI_ACCENT, Vector3(0.08 * s, 0.45 * s, -0.28 * s), "Eye")
	## Glitchy antennae
	StylizedMesh.add_box(_visual, Vector3(0.03 * s, 0.18 * s, 0.03 * s), WorldPalette.UI_CYAN, Vector3(-0.08 * s, 0.55 * s, -0.15 * s), "AntL")
	StylizedMesh.add_box(_visual, Vector3(0.03 * s, 0.18 * s, 0.03 * s), WorldPalette.UI_CYAN, Vector3(0.08 * s, 0.55 * s, -0.15 * s), "AntR")


func _physics_process(delta: float) -> void:
	if not is_alive() or _player == null or not is_instance_valid(_player):
		return
	if _ai_detail <= 0:
		return
	_bob += delta * (5.0 if flying else 2.5)
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_hit_flash = maxf(0.0, _hit_flash - delta)
	_activity_timer -= delta
	if _visual:
		_visual.scale = Vector3.ONE * (1.1 if _hit_flash > 0.0 else 1.0)
	if _wing and is_instance_valid(_wing):
		_wing.rotation.z = sin(_bob * (2.2 if _activity == Activity.FLEE else 1.2)) * 0.45

	_try_discover()
	if _ai_detail >= 2 or _activity == Activity.FLEE or _activity == Activity.CHASE or _activity == Activity.HUNT:
		_update_ai(delta)
	elif _activity_timer <= 0.0:
		## Simple LOD — wander only.
		_activity = Activity.WANDER
		_pick_wander_target()
		_activity_timer = _rng.randf_range(3.0, 6.0)

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
				## Patrol territory when not threatened — never idle forever.
				_activity = Activity.GUARD if _rng.randf() < 0.4 else Activity.WANDER
				_advance_patrol()
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
	var weather := WorldAtmosphere.current_weather_id()
	if not is_hostile and (weather == &"rain" or weather == &"storm") and _tags.has(&"rain_hide"):
		_activity = Activity.HIDE
		_target = _home
		_activity_timer = 5.0
		return
	if is_hostile:
		var night := WorldAtmosphere.current_phase_index() == WorldAtmosphere.Phase.NIGHT
		if night and _rng.randf() < 0.25:
			_activity = Activity.SLEEP
			_target = global_position
			return
		_activity = Activity.GUARD if _rng.randf() < 0.5 else Activity.WANDER
		_advance_patrol()
		return
	## Birds land / peck / take off.
	if flying and species_id == &"meadow_bird":
		var bird_roll := _rng.randf()
		if bird_roll < 0.35:
			_activity = Activity.GRAZE  ## Peck on ground.
			_target = global_position
			return
		if bird_roll < 0.55:
			_activity = Activity.PLAY
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
		## Prefer a downhill / stream-ish offset from home.
		_target = _home + Vector3(_rng.randf_range(-4, 4), 0, _rng.randf_range(2, 8))
	else:
		_activity = Activity.WANDER
		_pick_wander_target()


func _advance_patrol() -> void:
	if _patrol.is_empty():
		_pick_wander_target()
		return
	_patrol_i = (_patrol_i + 1) % _patrol.size()
	_target = _patrol[_patrol_i]


func _pick_wander_target() -> void:
	var ang := _rng.randf() * TAU
	var r := _rng.randf_range(2.0, 9.0)
	_target = _home + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
