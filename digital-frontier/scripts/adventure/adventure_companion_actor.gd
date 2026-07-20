class_name AdventureCompanionActor
extends CharacterBody3D
## Overworld creature partner — follows the player, shows personality, senses secrets.
##
## Reads CreatureManager for mood/speed; never owns XP/needs. Handheld: Y asks them.

enum State {
	FOLLOW,
	IDLE,
	NOTICE,
	LEAD,
	REACT,
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


func _ready() -> void:
	add_to_group(&"adventure_companion")
	## Float over the world — do not grind into static props or floors.
	motion_mode = MOTION_MODE_FLOATING
	collision_layer = 8  ## entities
	collision_mask = 0   ## soft follow; snap/teleport if separated
	floor_snap_length = 0.0
	_build_collision()
	_build_visual()
	EventBus.location_discovered.connect(_on_location_discovered)
	EventBus.chest_opened.connect(_on_chest_opened)
	EventBus.building_interior_loaded.connect(_on_building_changed)
	EventBus.building_exited.connect(_on_building_changed)
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
	return InputManager.format_prompt("Ask %s" % CreatureManager.get_companion_nickname(), &"creature_action")


func has_active_notice() -> bool:
	return _state == State.NOTICE and is_instance_valid(_notice_target)


func request_creature_action() -> void:
	## Y button — confirm notice, or affectionate check-in.
	if has_active_notice():
		_confirm_notice()
		return
	_play_react(CompanionVisual.Anim.PET)
	CreatureManager.grant_adventure_bond(1.2, "%s feels closer" % CreatureManager.get_companion_nickname())
	DeviceService.notify_event(&"creature_care")
	EventBus.ui_notification_requested.emit(
		"%s: \"%s\"" % [CreatureManager.get_companion_nickname(), _personality_quip()],
		2.4,
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
	_side_sign = 1.0 if CreatureManager.get_behavior_bias() != &"sleep" else -1.0
	if CreatureManager.get_active_instance():
		_side_sign = 1.0 if CreatureManager.get_active_instance().get_personality("playful") >= 50.0 else -1.0


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	_sense_timer -= delta
	_look_timer -= delta

	match _state:
		State.FOLLOW:
			_tick_follow(delta)
			if _sense_timer <= 0.0:
				_sense_timer = 1.1
				_try_sense()
			if _look_timer <= 0.0:
				_idle_look()
		State.IDLE:
			_tick_idle(delta)
			if _sense_timer <= 0.0:
				_sense_timer = 1.1
				_try_sense()
		State.NOTICE:
			_tick_notice(delta)
		State.LEAD:
			_tick_lead(delta)
		State.REACT:
			_tick_react(delta)

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
	var lag_boost := 1.0 + clampf(_follow_lag, 0.0, 0.8)
	var offset := back * (_follow_distance * lag_boost) + side * 0.55
	var pos := _player.global_position + offset
	pos.y = _player.global_position.y + 0.08
	return pos


func _tick_follow(delta: float) -> void:
	var target := _desired_follow_pos()
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
	## If barely moving while needing to catch up, count stuck frames then snap.
	if dist > 2.0 and before.distance_to(global_position) < 0.02:
		_stuck_frames += 1
		if _stuck_frames >= STUCK_FRAMES_LIMIT:
			global_position = target
			velocity = Vector3.ZERO
			_stuck_frames = 0
	else:
		_stuck_frames = 0


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
		radius *= lerpf(0.9, 1.2, CreatureManager.get_active_instance().get_personality("curious") / 100.0)

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
	## Location memory flag for collection feel.
	WorldManager.set_world_flag(StringName("memory_%s" % String(location_id)), true)


func _on_chest_opened(_chest_id: StringName, rarity: StringName) -> void:
	_play_react(CompanionVisual.Anim.HAPPY)
	var bond := 2.0
	var species := CreatureManager.get_species_data()
	if species:
		bond = species.adventure_bond_on_chest
	if rarity == &"rare" or rarity == &"legendary":
		bond *= 1.4
	CreatureManager.grant_adventure_bond(bond, "")


func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length_squared() < 0.001:
		return
	var target := Basis.looking_at(dir, Vector3.UP)
	global_transform.basis = global_transform.basis.slerp(target, clampf(10.0 * delta, 0.0, 1.0))


func _update_visual_motion() -> void:
	if _visual == null:
		return
	var planar := Vector2(velocity.x, velocity.z).length()
	_visual.set_walk_amount(clampf(planar / BASE_SPEED, 0.0, 1.0))
	if _state == State.FOLLOW and planar > 0.4:
		if planar > 5.5:
			_visual.set_anim(CompanionVisual.Anim.RUN)
		else:
			_visual.set_anim(CompanionVisual.Anim.WALK)


func _personality_quip() -> String:
	var bias := CreatureManager.get_behavior_bias()
	match bias:
		&"playful":
			return "Let's keep going!"
		&"explore":
			return "Something interesting is near…"
		&"sleep":
			return "Just a little longer out here…"
		&"eat":
			return "Adventure snacks later?"
		_:
			return "I'm with you."
