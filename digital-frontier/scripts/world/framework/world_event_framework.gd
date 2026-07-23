class_name WorldEventFramework
extends Node
## Reusable world-event scheduler — location-aware + time-aware.
## Wraps EncounterDirector for ambient vignettes; plugins register more.


signal event_triggered(event_id: StringName, pos: Vector3)

const GROUP := &"world_event_framework"

var _player: Node3D = null
var _living: LivingWorldController = null
var _encounters: WorldEncounterDirector = null
var _catalog: Array[Dictionary] = []
var _timer: float = 14.0
var _rng := RandomNumberGenerator.new()
var _last_event: StringName = &""


func setup(player: Node3D, living: LivingWorldController) -> void:
	_player = player
	_living = living
	_rng.randomize()
	add_to_group(GROUP)
	name = "WorldEventFramework"
	if living:
		_encounters = living.get_node_or_null("EncounterDirector") as WorldEncounterDirector
	_register_builtin_events()


func register_event(def: Dictionary) -> void:
	## Expected keys: id, weight, phases[], weather[], min_dist, max_dist, kind
	if def.is_empty() or not def.has(&"id"):
		return
	_catalog.append(def)


func trigger(event_id: StringName, pos: Vector3 = Vector3.ZERO) -> bool:
	if _player == null:
		return false
	if pos == Vector3.ZERO:
		pos = _player.global_position + Vector3(_rng.randf_range(16, 32), 0.15, _rng.randf_range(12, 28))
	var def := _find(event_id)
	if def.is_empty():
		return false
	_fire(def, pos)
	return true


func list_event_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for e in _catalog:
		out.append(StringName(str(e.get(&"id", e.get("id", &"")))))
	return out


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = 16.0 + _rng.randf_range(0.0, 10.0)
	## EncounterDirector already owns frequent vignettes — this layer rolls rarer scheduled events.
	if _rng.randf() > 0.35:
		return
	var pick := _pick_eligible()
	if pick.is_empty():
		return
	var offset := Vector3(
		_rng.randf_range(18, 40) * (1.0 if _rng.randf() > 0.5 else -1.0),
		0.15,
		_rng.randf_range(16, 36) * (1.0 if _rng.randf() > 0.5 else -1.0),
	)
	_fire(pick, _player.global_position + offset)


func _register_builtin_events() -> void:
	register_event({
		&"id": &"rare_sighting",
		&"weight": 2,
		&"phases": [WorldAtmosphere.Phase.EVENING, WorldAtmosphere.Phase.NIGHT],
		&"weather": [&"fog", &"clear"],
		&"kind": &"notify",
		&"msg": "Something rare stirs in the mist…",
	})
	register_event({
		&"id": &"merchant_arrival",
		&"weight": 2,
		&"phases": [WorldAtmosphere.Phase.MORNING, WorldAtmosphere.Phase.AFTERNOON],
		&"weather": [&"clear", &"fog"],
		&"kind": &"merchant",
		&"msg": "A merchant wagon creaks onto the road.",
	})
	register_event({
		&"id": &"storm_warning",
		&"weight": 1,
		&"phases": [],
		&"weather": [&"storm"],
		&"kind": &"notify",
		&"msg": "The sky cracks — creatures grow restless.",
	})
	register_event({
		&"id": &"festival_bells",
		&"weight": 1,
		&"phases": [WorldAtmosphere.Phase.AFTERNOON],
		&"weather": [&"clear"],
		&"kind": &"notify",
		&"msg": "Distant festival bells — a town is celebrating.",
	})
	register_event({
		&"id": &"meteor_window",
		&"weight": 1,
		&"phases": [WorldAtmosphere.Phase.NIGHT],
		&"weather": [&"clear", &"fog"],
		&"kind": &"meteor",
		&"msg": "A streak cuts the night sky!",
	})
	register_event({
		&"id": &"creature_invasion",
		&"weight": 1,
		&"phases": [WorldAtmosphere.Phase.NIGHT],
		&"weather": [&"storm", &"clear"],
		&"kind": &"invasion",
		&"msg": "Glitchmites surge from the brush!",
	})


func _find(event_id: StringName) -> Dictionary:
	for e in _catalog:
		if StringName(str(e.get(&"id", e.get("id", &"")))) == event_id:
			return e
	return {}


func _pick_eligible() -> Dictionary:
	var phase := WorldAtmosphere.current_phase_index()
	var weather := WorldAtmosphere.current_weather_id()
	var pool: Array[Dictionary] = []
	for e in _catalog:
		var phases: Array = e.get(&"phases", e.get("phases", []))
		if phases is Array and not phases.is_empty() and not phases.has(phase):
			continue
		var weathers: Array = e.get(&"weather", e.get("weather", []))
		if weathers is Array and not weathers.is_empty() and not weathers.has(weather):
			continue
		var eid: StringName = e.get(&"id", &"")
		if eid == _last_event:
			continue
		var w := int(e.get(&"weight", e.get("weight", 1)))
		for _i in maxi(1, w):
			pool.append(e)
	if pool.is_empty():
		return {}
	return pool[_rng.randi_range(0, pool.size() - 1)]


func _fire(def: Dictionary, pos: Vector3) -> void:
	var eid: StringName = def.get(&"id", &"")
	_last_event = eid
	var kind: StringName = def.get(&"kind", &"notify")
	var msg := String(def.get(&"msg", def.get("msg", "Something happens nearby.")))
	EventBus.ui_notification_requested.emit(msg, 2.4)
	event_triggered.emit(eid, pos)
	WorldSimMemory.remember_event(eid, true)
	match kind:
		&"merchant":
			if _encounters and _encounters.has_method("_spawn_resting_merchant"):
				_encounters.call("_spawn_resting_merchant", pos)
		&"meteor":
			if _encounters and _encounters.has_method("_spawn_meteor_glint"):
				_encounters.call("_spawn_meteor_glint", pos)
		&"invasion":
			if _living:
				var broker := WorldSpawnBroker.new()
				broker.bind(_living, _living)
				for i in 3:
					broker.spawn_hostile_near(pos, 6.0 + float(i) * 2.0)
		_:
			pass
