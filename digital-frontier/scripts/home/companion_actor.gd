class_name CompanionActor
extends CharacterBody3D
## Living companion brain for the home habitat.
##
## Autonomously wanders, sleeps, eats, plays, and reacts to care actions.
## Driven by CreatureManager needs — not hardcoded one-off timers only.

signal behavior_changed(behavior: StringName)
signal arrived_at_station(station_id: StringName)

enum Behavior {
	IDLE,
	WANDER,
	GOTO_STATION,
	SLEEP,
	EAT,
	PLAY,
	TRAIN,
	SAD,
	WAKE_STRETCH,
}

const WALK_SPEED := 1.15
const ARRIVE_DIST := 0.28

var habitat: HabitatEnvironment
var visual: CompanionVisual

var _behavior: Behavior = Behavior.IDLE
var _target: Vector3 = Vector3.ZERO
var _station_id: StringName = &""
var _action_timer: float = 0.0
var _think_timer: float = 1.5
var _busy: bool = false
var _pending_arrive: Behavior = Behavior.IDLE


func setup(env: HabitatEnvironment, vis: CompanionVisual) -> void:
	habitat = env
	visual = vis
	collision_layer = 0
	collision_mask = 1
	position = env.get_station_position(&"idle_center") + Vector3(0, 0, 0)
	_enter(Behavior.WAKE_STRETCH, 2.2)


func request_care(action: StringName) -> void:
	## Player-initiated care — creature walks to the matching station.
	match action:
		&"feed":
			_go_to_station(&"food", Behavior.EAT, 2.8)
		&"rest":
			_go_to_station(&"bed", Behavior.SLEEP, 4.0)
		&"play":
			_go_to_station(&"toy", Behavior.PLAY, 3.2)
		&"train":
			_go_to_station(&"train", Behavior.TRAIN, 3.0)
		_:
			pass


func get_behavior_name() -> StringName:
	match _behavior:
		Behavior.IDLE: return &"idle"
		Behavior.WANDER: return &"wander"
		Behavior.GOTO_STATION: return &"goto"
		Behavior.SLEEP: return &"sleep"
		Behavior.EAT: return &"eat"
		Behavior.PLAY: return &"play"
		Behavior.TRAIN: return &"train"
		Behavior.SAD: return &"sad"
		Behavior.WAKE_STRETCH: return &"stretch"
		_: return &"idle"


func _physics_process(delta: float) -> void:
	if habitat == null or visual == null:
		return

	_action_timer = maxf(0.0, _action_timer - delta)
	_think_timer -= delta

	match _behavior:
		Behavior.WAKE_STRETCH:
			visual.set_anim(CompanionVisual.Anim.STRETCH)
			visual.set_walk_amount(0.0)
			velocity = Vector3.ZERO
			if _action_timer <= 0.0:
				_busy = false
				_decide_next()
		Behavior.IDLE:
			_update_idle_visual()
			velocity = Vector3.ZERO
			if _think_timer <= 0.0:
				_decide_next()
		Behavior.WANDER, Behavior.GOTO_STATION:
			_move_toward_target(delta)
		Behavior.SLEEP:
			visual.set_anim(CompanionVisual.Anim.SLEEP)
			visual.set_walk_amount(0.0)
			velocity = Vector3.ZERO
			if _action_timer <= 0.0:
				_busy = false
				_enter(Behavior.WAKE_STRETCH, 1.8)
		Behavior.EAT:
			visual.set_anim(CompanionVisual.Anim.EAT)
			visual.set_walk_amount(0.0)
			velocity = Vector3.ZERO
			if _action_timer <= 0.0:
				_finish_action()
		Behavior.PLAY, Behavior.TRAIN:
			visual.set_anim(CompanionVisual.Anim.HAPPY)
			visual.set_walk_amount(0.0)
			## Tiny bounce in place
			position.y = absf(sin(Time.get_ticks_msec() * 0.01)) * 0.05
			velocity = Vector3.ZERO
			if _action_timer <= 0.0:
				position.y = 0.0
				_finish_action()
		Behavior.SAD:
			visual.set_anim(CompanionVisual.Anim.SAD)
			visual.set_walk_amount(0.0)
			velocity = Vector3.ZERO
			if _action_timer <= 0.0:
				_busy = false
			if _think_timer <= 0.0 and not _busy:
				_decide_next()

	move_and_slide()
	_face_movement(delta)
	_sync_mood_tint()


func _update_idle_visual() -> void:
	var mood := CreatureManager.get_mood()
	if mood == CreatureManager.Mood.SAD or mood == CreatureManager.Mood.IRRITABLE:
		visual.set_anim(CompanionVisual.Anim.SAD)
	elif mood == CreatureManager.Mood.TIRED:
		visual.set_anim(CompanionVisual.Anim.SLEEP)
	elif mood == CreatureManager.Mood.EXCITED or mood == CreatureManager.Mood.HAPPY:
		visual.set_anim(CompanionVisual.Anim.HAPPY if randf() < 0.02 else CompanionVisual.Anim.IDLE)
	else:
		visual.set_anim(CompanionVisual.Anim.IDLE)
	visual.set_walk_amount(0.0)


func _decide_next() -> void:
	_think_timer = randf_range(1.8, 3.5)
	if _busy:
		return

	var bias := CreatureManager.get_behavior_bias()
	match bias:
		&"sleep":
			_go_to_station(&"bed", Behavior.SLEEP, randf_range(3.5, 6.0))
			return
		&"eat":
			## Autonomously sniff toward bowl when hungry (doesn't auto-feed).
			_go_to_station(&"food", Behavior.SAD, randf_range(2.0, 3.5))
			return
		&"play":
			_go_to_station(&"toy", Behavior.PLAY, randf_range(2.0, 3.0))
			return
		&"playful":
			if randf() < 0.55:
				_pick_wander()
			else:
				_go_to_station(&"toy", Behavior.PLAY, 2.5)
			return
		_:
			pass

	if CreatureManager.get_mood() == CreatureManager.Mood.SAD:
		_enter(Behavior.SAD, 0.0)
		return

	if randf() < 0.65:
		_pick_wander()
	else:
		_enter(Behavior.IDLE, 0.0)


func _pick_wander() -> void:
	var bounds := habitat.get_floor_bounds()
	var local := Vector3(
		randf_range(bounds.position.x + 0.4, bounds.position.x + bounds.size.x - 0.4),
		0.0,
		randf_range(bounds.position.y + 0.4, bounds.position.y + bounds.size.y - 0.4),
	)
	_target = habitat.to_global(local)
	_target.y = global_position.y
	_enter(Behavior.WANDER, 0.0)


func _go_to_station(station_id: StringName, on_arrive: Behavior, duration: float) -> void:
	_station_id = station_id
	_target = habitat.get_station_position(station_id)
	_target.y = global_position.y
	_busy = true
	_action_timer = duration
	_pending_arrive = on_arrive
	_enter(Behavior.GOTO_STATION, duration)


func _move_toward_target(_delta: float) -> void:
	var to := _target - global_position
	to.y = 0.0
	var dist := to.length()
	if dist <= ARRIVE_DIST:
		velocity = Vector3.ZERO
		visual.set_walk_amount(0.0)
		if _behavior == Behavior.GOTO_STATION:
			arrived_at_station.emit(_station_id)
			var next := _pending_arrive
			var dur := _action_timer
			_enter(next, dur)
		else:
			_enter(Behavior.IDLE, 0.0)
		return

	var dir := to.normalized()
	velocity = dir * WALK_SPEED
	visual.set_anim(CompanionVisual.Anim.WALK)
	visual.set_walk_amount(1.0)
	## Keep grounded
	global_position.y = 0.0


func _finish_action() -> void:
	_busy = false
	_enter(Behavior.IDLE, 0.0)


func _enter(next: Behavior, duration: float) -> void:
	_behavior = next
	if duration > 0.0:
		_action_timer = duration
	behavior_changed.emit(get_behavior_name())


func _face_movement(delta: float) -> void:
	if velocity.length() < 0.05:
		return
	var desired := atan2(velocity.x, velocity.z)
	rotation.y = lerp_angle(rotation.y, desired, clampf(delta * 8.0, 0.0, 1.0))


func _sync_mood_tint() -> void:
	visual.set_mood_tint(CreatureManager.get_mood_color())
