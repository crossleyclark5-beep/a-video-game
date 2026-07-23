class_name AdventureCompanionActor
extends CharacterBody3D
## Overworld creature partner — follows the player, shows personality, senses secrets.
##
## Reads CreatureManager for mood/speed; never owns XP/needs. Handheld: Y asks them.
## Same CreatureInstance as Digi-Pet Home — one partner, two presentations.

enum State {
	FOLLOW,
	IDLE,
	NOTICE,
	LEAD,
	REACT,
	CAUTION,
}

const BASE_SPEED := 7.2
const ACCEL := 28.0
const STUCK_TELEPORT_DIST := 6.5
const LEAD_TIMEOUT := 6.0
const STUCK_FRAMES_LIMIT := 18

var _player: Node3D = null
var _visual: CompanionVisual = null
var _state: State = State.FOLLOW
var _idle_timer: float = 0.0
var _look_timer: float = 1.2
var _sense_timer: float = 1.5
var _world_react_timer: float = 2.5
var _cooldown: float = 0.0
var _notice_target: Node3D = null
var _notice_kind: StringName = &""
var _notice_id: StringName = &""
var _lead_timer: float = 0.0
var _react_timer: float = 0.0
var _follow_distance: float = 1.85
var _follow_lag: float = 0.32
var _side_sign: float = 1.0
var _stuck_frames: int = 0
var _orbit_phase: float = 0.0
var _last_weather: StringName = &""


func _ready() -> void:
	add_to_group(&"adventure_companion")
	## Float over the world — soft follow with personality orbit; snap if separated.
	motion_mode = MOTION_MODE_FLOATING
	collision_layer = 8  ## entities
	collision_mask = 0
	floor_snap_length = 0.0
	_build_collision()
	_build_visual()
	EventBus.location_discovered.connect(_on_location_discovered)
	EventBus.chest_opened.connect(_on_chest_opened)
	EventBus.building_interior_loaded.connect(_on_building_changed)
	EventBus.building_exited.connect(_on_building_changed)
	EventBus.creature_discovered.connect(_on_creature_discovered)
	EventBus.hostile_defeated.connect(_on_hostile_defeated_react)
	EventBus.npc_dialogue_ended.connect(_on_npc_talked)
	_apply_species_tuning()


func setup(player: Node3D) -> void:
	_player = player
	if _player:
		warp_near_player(_player)


func warp_near_player(player: Node3D = null) -> void:
	## Used on spawn and after house enter/exit so the partner stays with you.
	if player:
		_player = player
	if _player == null or not is_instance_valid(_player):
		return
	global_position = _desired_follow_pos()
	velocity = Vector3.ZERO
	_stuck_frames = 0
	_state = State.FOLLOW
	_clear_notice()


func get_notice_prompt() -> String:
	if _state != State.NOTICE or _notice_target == null:
		return ""
	match _notice_kind:
		&"danger":
			return InputManager.format_prompt("%s warns of danger!" % CreatureManager.get_companion_nickname(), &"creature_action")
		&"creature":
			return InputManager.format_prompt("%s spotted wildlife!" % CreatureManager.get_companion_nickname(), &"creature_action")
		&"boss":
			return InputManager.format_prompt("%s is wary…" % CreatureManager.get_companion_nickname(), &"creature_action")
		_:
			return InputManager.format_prompt("Ask %s" % CreatureManager.get_companion_nickname(), &"creature_action")


func has_active_notice() -> bool:
	return _state == State.NOTICE and is_instance_valid(_notice_target)


func request_creature_action() -> void:
	## Y button — confirm notice, celebrate, comfort, or talk.
	if has_active_notice():
		_confirm_notice()
		return
	if CreatureManager.consume_celebrate_pending():
		_play_react(CompanionVisual.Anim.HAPPY)
		var msg := CreatureManager.celebrate()
		EventBus.ui_notification_requested.emit(msg, 2.6)
		return
	var mood := CreatureManager.get_mood()
	if mood == CreatureManager.Mood.TIRED or mood == CreatureManager.Mood.SAD or CreatureManager.get_happiness() < 35.0:
		_play_react(CompanionVisual.Anim.PET)
		var comfort := CreatureManager.comfort()
		EventBus.ui_notification_requested.emit(comfort, 2.6)
		DeviceService.notify_event(&"creature_care")
		return
	_play_react(CompanionVisual.Anim.PET)
	var talk := CreatureManager.talk()
	DeviceService.notify_event(&"creature_care")
	EventBus.ui_notification_requested.emit(talk, 2.6)


func play_combat_assist() -> void:
	_play_react(CompanionVisual.Anim.HAPPY)
	var quip := CreatureManager.get_partner_quip(&"victory")
	EventBus.ui_notification_requested.emit(
		"%s strikes! \"%s\"" % [CreatureManager.get_companion_nickname(), quip],
		1.3,
	)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.32
	col.shape = shape
	col.position = Vector3(0, 0.32, 0)
	add_child(col)


func _build_visual() -> void:
	_visual = CompanionVisual.new()
	_visual.name = "Visual"
	add_child(_visual)
	var species := CreatureManager.get_species_data()
	if species:
		_visual.apply_from_creature(species, CreatureManager.get_evolution_stage())
	_visual.set_anim(CompanionVisual.Anim.IDLE)
	if not EventBus.companion_state_changed.is_connected(_on_companion_changed):
		EventBus.companion_state_changed.connect(_on_companion_changed)


func _on_companion_changed() -> void:
	if _visual:
		_visual.refresh_from_manager()


func _apply_species_tuning() -> void:
	var species := CreatureManager.get_species_data()
	if species:
		_follow_distance = species.follow_distance
		_follow_lag = species.follow_lag
	var inst := CreatureManager.get_active_instance()
	if inst:
		_side_sign = CompanionPersonality.follow_side_bias(inst.personality)
	else:
		_side_sign = 1.0


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	_sense_timer -= delta
	_look_timer -= delta
	_world_react_timer -= delta
	_orbit_phase += delta

	match _state:
		State.FOLLOW:
			_tick_follow(delta)
			if _sense_timer <= 0.0:
				_sense_timer = 1.1
				_try_sense()
			if _look_timer <= 0.0:
				_idle_look()
			if _world_react_timer <= 0.0:
				_world_react_timer = 2.8
				_tick_world_awareness()
		State.IDLE:
			_tick_idle(delta)
			if _sense_timer <= 0.0:
				_sense_timer = 1.1
				_try_sense()
			if _world_react_timer <= 0.0:
				_world_react_timer = 2.8
				_tick_world_awareness()
		State.NOTICE:
			_tick_notice(delta)
		State.LEAD:
			_tick_lead(delta)
		State.REACT:
			_tick_react(delta)
		State.CAUTION:
			_tick_caution(delta)

	_update_visual_motion()


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group(GameConstants.GROUP_PLAYER)
	if not players.is_empty():
		_player = players[0] as Node3D


func _desired_follow_pos() -> Vector3:
	var back := -_player.global_transform.basis.z
	back.y = 0.0
	if back.length_squared() < 0.01:
		back = Vector3(0, 0, 1)
	back = back.normalized()
	var side := _player.global_transform.basis.x
	side.y = 0.0
	side = side.normalized() * _side_sign
	## Soft personality orbit — playful partners weave a little; calm ones hold steady.
	var weave := 0.0
	var inst := CreatureManager.get_active_instance()
	if inst:
		var playful := inst.get_personality("playful")
		var calm := inst.get_personality("calm")
		weave = sin(_orbit_phase * lerpf(1.2, 2.4, playful / 100.0)) * lerpf(0.08, 0.42, playful / 100.0)
		weave *= lerpf(1.0, 0.35, calm / 100.0)
	var lag_boost := 1.0 + clampf(_follow_lag, 0.0, 0.8)
	## Protective partners stay slightly closer.
	var dist := _follow_distance
	if inst and inst.get_primary_trait() == &"protective":
		dist *= 0.88
	elif inst and inst.get_primary_trait() == &"curious":
		dist *= 1.06
	var offset := back * (dist * lag_boost) + side * (0.55 + weave)
	var pos := _player.global_position + offset
	pos.y = _player.global_position.y + 0.08
	return pos


func _tick_follow(delta: float) -> void:
	var target := _desired_follow_pos()
	## Soft obstacle sidestep: if a static body sits between companion and target, bias sideways.
	target = _soft_avoid(target)
	var to_target := target - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	if dist > STUCK_TELEPORT_DIST:
		global_position = target
		velocity = Vector3.ZERO
		_stuck_frames = 0
		return
	if dist < 0.55:
		velocity = velocity.move_toward(Vector3.ZERO, ACCEL * delta)
		_idle_timer += delta
		_stuck_frames = 0
		## Face the player when close — feels like a companion, not a shadow.
		var to_player := _player.global_position - global_position
		to_player.y = 0.0
		if to_player.length_squared() > 0.01:
			_face_direction(to_player.normalized(), delta)
		if _idle_timer > 1.4:
			_state = State.IDLE
			_idle_timer = 0.0
			if _visual:
				_visual.set_anim(CompanionVisual.Anim.IDLE)
		move_and_slide()
		return
	_idle_timer = 0.0
	var player_speed := 0.0
	if _player is CharacterBody3D:
		var pv := (_player as CharacterBody3D).velocity
		player_speed = Vector2(pv.x, pv.z).length()
	var speed := maxf(BASE_SPEED, player_speed * 1.05) * CreatureManager.get_walk_speed_multiplier()
	speed = maxf(speed, 4.5)
	## Catch up when far.
	if dist > 3.2:
		speed *= 1.45
	var dir := to_target.normalized()
	velocity.x = move_toward(velocity.x, dir.x * speed, ACCEL * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, ACCEL * delta)
	velocity.y = 0.0
	_face_direction(dir, delta)
	var before := global_position
	move_and_slide()
	## Keep companion locked to player elevation on hills / trails.
	global_position.y = move_toward(global_position.y, target.y, 12.0 * delta)
	if dist > 2.0 and before.distance_to(global_position) < 0.02:
		_stuck_frames += 1
		if _stuck_frames >= STUCK_FRAMES_LIMIT:
			global_position = target
			velocity = Vector3.ZERO
			_stuck_frames = 0
	else:
		_stuck_frames = 0


func _soft_avoid(target: Vector3) -> Vector3:
	## Cheap handheld-friendly avoidance using a short ray toward the follow slot.
	var space := get_world_3d().direct_space_state
	if space == null:
		return target
	var from := global_position + Vector3(0, 0.4, 0)
	var to := target + Vector3(0, 0.4, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1  ## world static
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return target
	var normal: Vector3 = hit.get("normal", Vector3.UP)
	normal.y = 0.0
	if normal.length_squared() < 0.01:
		normal = _player.global_transform.basis.x
		normal.y = 0.0
	normal = normal.normalized()
	return target + normal * 0.85 * _side_sign


func _tick_world_awareness() -> void:
	## React to bosses, weather, and nearby danger without spamming.
	if _state == State.NOTICE or _state == State.LEAD or _state == State.REACT:
		return
	## Boss proximity → caution.
	for node in get_tree().get_nodes_in_group(RegionBossActor.GROUP):
		if node is Node3D and is_instance_valid(node):
			if global_position.distance_to((node as Node3D).global_position) < 22.0:
				_enter_caution(node as Node3D, &"boss")
				return
	for node2 in get_tree().get_nodes_in_group(MiniBossActor.GROUP):
		if node2 is Node3D and is_instance_valid(node2):
			if global_position.distance_to((node2 as Node3D).global_position) < 18.0:
				_enter_caution(node2 as Node3D, &"boss")
				return
	## Weather shift bark.
	var weather := WorldAtmosphere.current_weather_id()
	if weather != _last_weather and _last_weather != &"":
		_react_weather(weather)
	_last_weather = weather


func _enter_caution(target: Node3D, kind: StringName) -> void:
	_notice_target = target
	_notice_kind = kind
	_notice_id = &"caution"
	_state = State.CAUTION
	_react_timer = 2.2
	if _visual:
		_visual.set_anim(CompanionVisual.Anim.CURIOUS)
	var quip := CreatureManager.get_partner_quip(&"danger")
	EventBus.ui_notification_requested.emit(
		"%s: \"%s\"" % [CreatureManager.get_companion_nickname(), quip],
		2.4,
	)
	EventBus.sfx_play_requested.emit(&"creature_status", global_position)


func _tick_caution(delta: float) -> void:
	## Hang closer to the player, facing the threat.
	var soft := _desired_follow_pos()
	## Pull tighter when protective.
	if CreatureManager.get_primary_trait() == &"protective":
		soft = soft.lerp(_player.global_position, 0.35)
	var to_soft := soft - global_position
	to_soft.y = 0.0
	if to_soft.length() > 0.4:
		var dir := to_soft.normalized()
		velocity.x = move_toward(velocity.x, dir.x * 3.0, ACCEL * delta)
		velocity.z = move_toward(velocity.z, dir.z * 3.0, ACCEL * delta)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, ACCEL * delta)
	velocity.y = 0.0
	move_and_slide()
	if is_instance_valid(_notice_target):
		var look := _notice_target.global_position - global_position
		look.y = 0.0
		if look.length_squared() > 0.01:
			_face_direction(look.normalized(), delta)
	_react_timer -= delta
	if _react_timer <= 0.0 or not is_instance_valid(_notice_target):
		_clear_notice()
		_state = State.FOLLOW


func _react_weather(weather: StringName) -> void:
	var line := ""
	match weather:
		&"rain", &"storm":
			line = "Rain… stay close."
			if _visual:
				_visual.set_anim(CompanionVisual.Anim.CURIOUS)
		&"clear", &"sunny":
			line = "Nice light!"
			if _visual:
				_visual.set_anim(CompanionVisual.Anim.HAPPY)
		_:
			return
	EventBus.ui_notification_requested.emit(
		"%s: \"%s\"" % [CreatureManager.get_companion_nickname(), line],
		1.8,
	)


func _on_building_changed(_building_id: StringName = &"") -> void:
	if _player:
		warp_near_player(_player)


func _tick_idle(delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, ACCEL * delta)
	move_and_slide()
	var dist := global_position.distance_to(_desired_follow_pos())
	if dist > 1.4:
		_state = State.FOLLOW
		return
	_idle_timer += delta
	if _look_timer <= 0.0:
		_idle_look()
	## Curious creatures resume following sooner.
	var curious := 50.0
	if CreatureManager.get_active_instance():
		curious = CreatureManager.get_active_instance().get_personality("curious")
	if _idle_timer > lerpf(2.8, 1.4, curious / 100.0):
		_state = State.FOLLOW
		_idle_timer = 0.0


func _tick_notice(delta: float) -> void:
	## Soft orbit toward player while noticing — don't freeze into a statue.
	var soft := _desired_follow_pos()
	var to_soft := soft - global_position
	to_soft.y = 0.0
	if to_soft.length() > 1.8:
		var dir_soft := to_soft.normalized()
		velocity.x = move_toward(velocity.x, dir_soft.x * 2.2, ACCEL * delta)
		velocity.z = move_toward(velocity.z, dir_soft.z * 2.2, ACCEL * delta)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, ACCEL * delta)
	velocity.y = 0.0
	move_and_slide()
	if not is_instance_valid(_notice_target):
		_clear_notice()
		_state = State.FOLLOW
		return
	var dir := _notice_target.global_position - global_position
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		_face_direction(dir.normalized(), delta)
	if global_position.distance_to(_player.global_position) > 10.0:
		_clear_notice()
		_state = State.FOLLOW


func _play_react(anim: CompanionVisual.Anim) -> void:
	_state = State.REACT
	_react_timer = 0.55
	if _visual:
		_visual.set_anim(anim)
		_visual.play_feedback_burst(&"heart")


func _tick_lead(delta: float) -> void:
	_lead_timer -= delta
	if not is_instance_valid(_notice_target) or _lead_timer <= 0.0:
		_clear_notice()
		_state = State.FOLLOW
		return
	var dest := _notice_target.global_position
	dest.y = global_position.y
	var to := dest - global_position
	to.y = 0.0
	var dist := to.length()
	if dist < 1.2:
		_play_react(CompanionVisual.Anim.HAPPY)
		_state = State.REACT
		_react_timer = 1.2
		return
	var speed := BASE_SPEED * 0.95 * CreatureManager.get_walk_speed_multiplier()
	var dir := to.normalized()
	velocity.x = move_toward(velocity.x, dir.x * speed, ACCEL * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, ACCEL * delta)
	velocity.y = 0.0
	_face_direction(dir, delta)
	move_and_slide()


func _tick_react(delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, ACCEL * delta)
	move_and_slide()
	_react_timer -= delta
	if _react_timer <= 0.0:
		_clear_notice()
		_state = State.FOLLOW


func _idle_look() -> void:
	_look_timer = randf_range(1.6, 3.2)
	if _visual == null:
		return
	## Soft look / stretch based on personality.
	var bias := CreatureManager.get_behavior_bias()
	match bias:
		&"playful":
			_visual.set_anim(CompanionVisual.Anim.HAPPY)
		&"sleep":
			_visual.set_anim(CompanionVisual.Anim.SLEEP)
		&"explore":
			_visual.set_anim(CompanionVisual.Anim.CURIOUS)
		_:
			_visual.set_anim(CompanionVisual.Anim.IDLE)
	rotate_y(randf_range(-0.6, 0.6))


func _try_sense() -> void:
	if _cooldown > 0.0 or _state == State.NOTICE or _state == State.LEAD:
		return
	var ability := _best_sense_ability()
	if ability == null:
		return
	var radius := ability.sense_radius
	var species := CreatureManager.get_species_data()
	if species:
		radius += species.sense_radius_bonus
	## Curious creatures sense a little farther.
	if CreatureManager.get_active_instance():
		radius *= CompanionPersonality.sense_radius_mult(CreatureManager.get_active_instance().personality)

	var best: Node3D = null
	var best_dist := radius
	var best_kind: StringName = &""
	var best_id: StringName = &""

	for node in get_tree().get_nodes_in_group(&"interactables"):
		if not (node is Node3D):
			continue
		var n3 := node as Node3D
		var d := global_position.distance_to(n3.global_position)
		if d > best_dist:
			continue
		if node is ChestInteractable:
			var chest := node as ChestInteractable
			if WorldManager.is_chest_opened(chest.chest_id):
				continue
			if ability.kind == CreatureAbilityData.Kind.SENSE_SECRETS:
				if chest.rarity == ChestInteractable.Rarity.NORMAL and d > radius * 0.45:
					continue  ## Prefer rare/legendary unless very close
				best = n3
				best_dist = d
				best_kind = &"chest"
				best_id = chest.chest_id
		elif node is DiscoverableInteractable:
			var disc := node as DiscoverableInteractable
			if WorldManager.is_location_discovered(disc.location_id):
				continue
			best = n3
			best_dist = d
			best_kind = &"discoverable"
			best_id = disc.location_id

	## Sense nearby wild ecosystem creatures (nature ability prefers rare).
	for node2 in get_tree().get_nodes_in_group(EcosystemCreature.GROUP):
		if not (node2 is EcosystemCreature):
			continue
		var eco := node2 as EcosystemCreature
		var d2 := global_position.distance_to(eco.global_position)
		if d2 > best_dist:
			continue
		if ability.kind == CreatureAbilityData.Kind.SENSE_NATURE or eco.rarity >= EcosystemCatalog.Rarity.RARE or eco.is_hostile:
			best = eco
			best_dist = d2
			best_kind = &"creature" if not eco.is_hostile else &"danger"
			best_id = eco.species_id

	if best == null:
		return
	_raise_notice(best, best_kind, best_id, ability)


func _best_sense_ability() -> CreatureAbilityData:
	var best: CreatureAbilityData = null
	for aid in CreatureManager.get_active_ability_ids():
		var ab: CreatureAbilityData = ResourceRegistry.get_ability(StringName(aid))
		if ab == null:
			continue
		if ab.kind == CreatureAbilityData.Kind.SENSE_SECRETS or ab.kind == CreatureAbilityData.Kind.SENSE_NATURE:
			best = ab
			break
	return best


func _raise_notice(target: Node3D, kind: StringName, id: StringName, ability: CreatureAbilityData) -> void:
	_notice_target = target
	_notice_kind = kind
	_notice_id = id
	_state = State.NOTICE
	_cooldown = ability.cooldown_seconds
	if _visual:
		_visual.set_anim(CompanionVisual.Anim.DISCOVERY)
		_visual.play_feedback_burst(&"heart")
	EventBus.companion_noticed.emit(id, kind)
	DeviceService.play_haptic(&"discover", 0.35)
	DeviceService.set_led(Color(0.55, 0.9, 1.0), &"pulse")
	var hint := ability.hint_prefix
	EventBus.ui_notification_requested.emit(
		"%s %s!  %s" % [CreatureManager.get_companion_nickname(), hint, get_notice_prompt()],
		3.2,
	)


func _confirm_notice() -> void:
	if not is_instance_valid(_notice_target):
		_clear_notice()
		return
	var ability := _best_sense_ability()
	var bond := 3.0
	var xp := 4
	if ability:
		bond = ability.bond_reward
		xp = ability.xp_reward
	CreatureManager.grant_adventure_bond(bond, "%s helped explore" % CreatureManager.get_companion_nickname())
	CreatureManager.grant_adventure_experience(xp)
	EventBus.companion_helped.emit(_notice_id, _notice_kind)
	DeviceService.notify_event(&"creature_care")
	## Lead player toward the find briefly.
	_state = State.LEAD
	_lead_timer = LEAD_TIMEOUT
	if _visual:
		_visual.set_anim(CompanionVisual.Anim.WALK)
	var label := "secret"
	if _notice_kind == &"chest":
		label = "stash"
	elif _notice_kind == &"discoverable":
		label = "landmark"
	EventBus.ui_notification_requested.emit(
		"%s bounds ahead — follow them to the %s!" % [CreatureManager.get_companion_nickname(), label],
		2.8,
	)


func _clear_notice() -> void:
	_notice_target = null
	_notice_kind = &""
	_notice_id = &""


func _on_location_discovered(location_id: StringName) -> void:
	_play_react(CompanionVisual.Anim.HAPPY)
	var bond := 1.5
	var species := CreatureManager.get_species_data()
	if species:
		bond = species.adventure_bond_on_discover
	CreatureManager.grant_adventure_bond(bond, "")
	WorldManager.set_world_flag(StringName("memory_%s" % String(location_id)), true)
	CreatureManager.record_memory(
		StringName("loc_%s" % String(location_id)),
		CompanionMemory.Kind.DISCOVERY,
		"Discovered %s together" % String(location_id).replace("_", " ").capitalize(),
		PackedStringArray(["discovery", String(location_id)]),
	)
	EventBus.ui_notification_requested.emit(
		"%s: \"%s\"" % [CreatureManager.get_companion_nickname(), CreatureManager.get_partner_quip(&"discover")],
		2.0,
	)


func _on_creature_discovered(species_id: StringName, rarity: int) -> void:
	_play_react(CompanionVisual.Anim.DISCOVERY if rarity >= EcosystemCatalog.Rarity.RARE else CompanionVisual.Anim.CURIOUS)
	var msg := "%s is excited!" % CreatureManager.get_companion_nickname()
	if rarity >= EcosystemCatalog.Rarity.RARE:
		msg = "%s leaps — a rare signal!" % CreatureManager.get_companion_nickname()
		CreatureManager.record_memory(
			StringName("rare_%s" % String(species_id)),
			CompanionMemory.Kind.DISCOVERY,
			"Saw rare %s together" % String(species_id).replace("_", " "),
			PackedStringArray(["rare", String(species_id)]),
		)
	EventBus.ui_notification_requested.emit(msg, 2.0)
	CreatureManager.grant_adventure_bond(0.8 if rarity < EcosystemCatalog.Rarity.RARE else 2.0, "")


func _on_hostile_defeated_react(species_id: StringName = &"", _pos: Vector3 = Vector3.ZERO) -> void:
	_play_react(CompanionVisual.Anim.HAPPY)
	var is_boss := species_id == &"hollow_warden" or species_id == &"glitch_alpha"
	CreatureManager.record_companion_battle(true, species_id, is_boss)
	if is_boss:
		EventBus.ui_notification_requested.emit(
			"%s: \"%s\"" % [CreatureManager.get_companion_nickname(), CreatureManager.get_partner_quip(&"victory")],
			2.4,
		)


func _on_chest_opened(_chest_id: StringName, rarity: StringName) -> void:
	_play_react(CompanionVisual.Anim.HAPPY)
	var bond := 2.0
	var species := CreatureManager.get_species_data()
	if species:
		bond = species.adventure_bond_on_chest
	if rarity == &"rare" or rarity == &"legendary":
		bond *= 1.4
		CreatureManager.record_memory(
			StringName("chest_%s" % String(_chest_id)),
			CompanionMemory.Kind.DISCOVERY,
			"Opened a %s chest together" % String(rarity),
			PackedStringArray(["chest", String(rarity)]),
		)
	CreatureManager.grant_adventure_bond(bond, "")


func _on_npc_talked(npc_id: StringName) -> void:
	## Soft social reaction — protective/curious partners chirp after talks.
	if CreatureManager.get_primary_trait() == &"curious" or CreatureManager.get_friendship() > 40.0:
		if _visual and (_state == State.FOLLOW or _state == State.IDLE):
			_play_react(CompanionVisual.Anim.CURIOUS)
		CreatureManager.grant_adventure_bond(0.3, "")
		var inst := CreatureManager.get_active_instance()
		if npc_id == &"field_ranger" and inst and not inst.has_memory(&"met_ranger"):
			CreatureManager.record_memory(&"met_ranger", CompanionMemory.Kind.STORY, "Met the Field Ranger together", PackedStringArray(["story", "npc"]))


func _face_direction(dir: Vector3, delta: float) -> void:
	## +Z model front — match player / NPC facing convention.
	AssetStandardizer.face_velocity(self, dir, 10.0, delta)


func _update_visual_motion() -> void:
	if _visual == null:
		return
	var planar := Vector2(velocity.x, velocity.z).length()
	_visual.set_walk_amount(clampf(planar / BASE_SPEED, 0.0, 1.0))
	if _state == State.FOLLOW and planar > 0.4:
		if CreatureManager.get_mood() == CreatureManager.Mood.TIRED:
			_visual.set_anim(CompanionVisual.Anim.WALK)
		elif planar > 5.5:
			_visual.set_anim(CompanionVisual.Anim.RUN)
		else:
			_visual.set_anim(CompanionVisual.Anim.WALK)
	elif _state == State.IDLE and CreatureManager.get_mood() == CreatureManager.Mood.TIRED:
		_visual.set_anim(CompanionVisual.Anim.SLEEP)
