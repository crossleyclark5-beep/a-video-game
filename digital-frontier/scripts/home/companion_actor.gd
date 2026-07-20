class_name CompanionActor
extends CharacterBody3D
## Living companion brain for the home habitat.
##
## Personality + needs from CreatureInstance drive wander, sleep, play, and
## reactions. Modular so adventure followers can reuse the same behavior hooks.

signal behavior_changed(behavior: StringName)
signal arrived_at_station(station_id: StringName)
signal interacted(action: StringName)

enum Behavior {
	IDLE,
	WANDER,
	GOTO_STATION,
	SLEEP,
	EAT,
	PLAY,
	TRAIN,
	SAD,
	HUNGRY,
	WAKE_STRETCH,
	PET,
	REACT_PLAYER,
}

const BASE_WALK_SPEED := 1.15
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
var _click_area: Area3D


func setup(env: HabitatEnvironment, vis: CompanionVisual) -> void:
	habitat = env
	visual = vis
	collision_layer = 0
	collision_mask = 1
	position = env.get_station_position(&"idle_center")
	_setup_click_area()
	_apply_species_look()
	_enter(Behavior.WAKE_STRETCH, 2.2)


func request_care(action: StringName) -> void:
	match action:
		&"feed":
			_go_to_station(&"food", Behavior.EAT, 2.8)
		&"rest":
			_go_to_station(&"bed", Behavior.SLEEP, 4.0)
		&"play":
			_go_to_station(&"toy", Behavior.PLAY, 3.2)
		&"train":
			_go_to_station(&"train", Behavior.TRAIN, 3.0)
		&"pet":
			_start_pet()
		_:
			pass


func request_status_check() -> void:
	## Creature acknowledges being looked at.
	_busy = true
	_enter(Behavior.REACT_PLAYER, 1.6)
	interacted.emit(&"status")


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
		Behavior.HUNGRY: return &"hungry"
		Behavior.WAKE_STRETCH: return &"stretch"
		Behavior.PET: return &"pet"
		Behavior.REACT_PLAYER: return &"react"
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
		Behavior.HUNGRY:
			visual.set_anim(CompanionVisual.Anim.HUNGRY)
			visual.set_walk_amount(0.0)
			velocity = Vector3.ZERO
			if _action_timer <= 0.0:
				_busy = false
			if _think_timer <= 0.0 and not _busy:
				_decide_next()
		Behavior.PET:
			visual.set_anim(CompanionVisual.Anim.PET)
			visual.set_walk_amount(0.0)
			velocity = Vector3.ZERO
			if _action_timer <= 0.0:
				_finish_action()
		Behavior.REACT_PLAYER:
			visual.set_anim(CompanionVisual.Anim.HAPPY if CreatureManager.get_happiness() > 40.0 else CompanionVisual.Anim.IDLE)
			visual.set_walk_amount(0.0)
			velocity = Vector3.ZERO
			## Face camera-ish (toward +Z home view).
			rotation.y = lerp_angle(rotation.y, 0.0, delta * 4.0)
			if _action_timer <= 0.0:
				_finish_action()

	move_and_slide()
	_face_movement(delta)
	_sync_mood_tint()


func _setup_click_area() -> void:
	_click_area = Area3D.new()
	_click_area.name = "PetArea"
	_click_area.collision_layer = 16
	_click_area.collision_mask = 0
	_click_area.input_ray_pickable = true
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.55
	col.shape = shape
	col.position = Vector3(0, 0.4, 0)
	_click_area.add_child(col)
	add_child(_click_area)
	_click_area.input_event.connect(_on_click_area_input)


func _on_click_area_input(_camera: Camera3D, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_do_pet_from_player()


func _do_pet_from_player() -> void:
	var msg := CreatureManager.pet()
	EventBus.ui_notification_requested.emit(msg, 2.2)
	_start_pet()
	interacted.emit(&"pet")


func _start_pet() -> void:
	_busy = true
	_enter(Behavior.PET, 2.0)
	if visual:
		visual.play_feedback_burst(&"pet")


func _apply_species_look() -> void:
	var inst := CreatureManager.get_active_instance()
	if inst == null or visual == null:
		return
	visual.apply_species_colors(inst.get_species())


func _update_idle_visual() -> void:
	var mood := CreatureManager.get_mood()
	if mood == CreatureManager.Mood.SAD or mood == CreatureManager.Mood.IRRITABLE:
		visual.set_anim(CompanionVisual.Anim.SAD)
	elif mood == CreatureManager.Mood.TIRED:
		visual.set_anim(CompanionVisual.Anim.SLEEP)
	elif CreatureManager.get_hunger() < 40.0:
		visual.set_anim(CompanionVisual.Anim.HUNGRY)
	elif mood == CreatureManager.Mood.EXCITED or mood == CreatureManager.Mood.HAPPY:
		visual.set_anim(CompanionVisual.Anim.HAPPY if randf() < 0.03 else CompanionVisual.Anim.IDLE)
	else:
		visual.set_anim(CompanionVisual.Anim.IDLE)
	visual.set_walk_amount(0.0)


func _decide_next() -> void:
	var playful := 50.0
	var lazy := 35.0
	var inst := CreatureManager.get_active_instance()
	if inst:
		playful = inst.get_personality("playful")
		lazy = inst.get_personality("lazy")

	_think_timer = randf_range(1.6, 3.2)
	## Happier / playful creatures rethink sooner and explore more.
	if CreatureManager.get_happiness() > 70.0:
		_think_timer *= 0.75
	if lazy > 60.0:
		_think_timer *= 1.25

	if _busy:
		return

	var bias := CreatureManager.get_behavior_bias()
	match bias:
		&"sleep":
			_go_to_station(&"bed", Behavior.SLEEP, randf_range(3.5, 6.5))
			return
		&"eat":
			_go_to_station(&"food", Behavior.HUNGRY, randf_range(2.2, 3.8))
			return
		&"play":
			_go_to_station(&"toy", Behavior.PLAY, randf_range(2.0, 3.2))
			return
		&"playful":
			if randf() < 0.45 + playful * 0.004:
				_go_to_station(&"toy", Behavior.PLAY, 2.6)
			else:
				_pick_wander()
			return
		&"explore":
			_pick_wander()
			return
		_:
			pass

	if CreatureManager.get_mood() == CreatureManager.Mood.SAD:
		_enter(Behavior.SAD, 2.0)
		_busy = true
		return

	## Low happiness → prefer resting / lingering.
	if CreatureManager.get_happiness() < 40.0:
		if randf() < 0.55:
			_go_to_station(&"bed", Behavior.SLEEP, randf_range(3.0, 5.0))
		else:
			_enter(Behavior.SAD, 2.5)
			_busy = true
		return

	## High happiness → explore / play.
	var wander_chance := 0.55 + (CreatureManager.get_happiness() - 50.0) * 0.004
	wander_chance += playful * 0.002
	wander_chance -= lazy * 0.003
	if randf() < clampf(wander_chance, 0.25, 0.85):
		_pick_wander()
	else:
		_enter(Behavior.IDLE, 0.0)


func _pick_wander() -> void:
	var bounds := habitat.get_floor_bounds()
	## Prefer different zones: near bed / toy / train / center.
	var spots: Array[Vector3] = [
		habitat.get_station_position(&"idle_center"),
		habitat.get_station_position(&"toy"),
		habitat.get_station_position(&"train"),
		habitat.to_global(Vector3(
			randf_range(bounds.position.x + 0.5, bounds.position.x + bounds.size.x - 0.5),
			0.0,
			randf_range(bounds.position.y + 0.5, bounds.position.y + bounds.size.y - 0.5),
		)),
	]
	_target = spots[randi() % spots.size()]
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

	var speed := BASE_WALK_SPEED * CreatureManager.get_walk_speed_multiplier()
	velocity = to.normalized() * speed
	visual.set_anim(CompanionVisual.Anim.WALK)
	visual.set_walk_amount(1.0)
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
