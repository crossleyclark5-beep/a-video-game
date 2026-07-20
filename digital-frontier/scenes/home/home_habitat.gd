extends Node3D
## Creature Home Habitat — emotional center of Digital Frontier.
##
## Living 3D room + companion AI + handheld HUD. Modular for multiple
## creatures, home skins, decorations, and seasonal packs later.

const HUD_SCENE := preload("res://scenes/home/ui/home_hud.tscn")

var _habitat: HabitatEnvironment
var _companion: CompanionActor
var _visual: CompanionVisual
var _hud: CanvasLayer
var _camera: Camera3D
var _stations: Dictionary = {}  ## station_id -> HomeStation


func _ready() -> void:
	InputManager.set_context(InputManager.Context.HOME)
	get_viewport().physics_object_picking = true
	_build_world()
	_build_companion()
	_build_stations()
	_build_hud()
	_build_camera()
	QuestManager.ensure_starter_quest()
	EventBus.music_change_requested.emit(&"home_night")
	EventBus.sfx_play_requested.emit(&"home_ambient", Vector3.ZERO)


func _unhandled_input(event: InputEvent) -> void:
	## Enter still works if focus is elsewhere; Start is handled by HomeHud.
	if event.is_action_pressed(&"go_adventure"):
		_on_adventure()


func _process(_delta: float) -> void:
	if _hud and _habitat:
		_hud.set_time_label(_habitat.time_of_day.get_label())


func _build_world() -> void:
	_habitat = HabitatEnvironment.new()
	_habitat.name = "Habitat"
	add_child(_habitat)
	_habitat.build()
	_habitat.set_phase(HabitatTimeOfDay.Phase.NIGHT)


func _build_companion() -> void:
	_companion = CompanionActor.new()
	_companion.name = "Companion"
	add_child(_companion)

	_visual = CompanionVisual.new()
	_visual.name = "Visual"
	_companion.add_child(_visual)

	## Collision so companion rests on floor collision from habitat.
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.28
	col.shape = shape
	col.position = Vector3(0, 0.28, 0)
	_companion.add_child(col)

	_companion.setup(_habitat, _visual)


func _build_stations() -> void:
	_add_station(&"food", &"feed", "Feed", _habitat.get_station_position(&"food"))
	_add_station(&"bed", &"rest", "Rest", _habitat.get_station_position(&"bed"))
	_add_station(&"toy", &"play", "Play", _habitat.get_station_position(&"toy"))
	_add_station(&"train", &"train", "Train", _habitat.get_station_position(&"train"))


func _add_station(id: StringName, action: StringName, prompt: String, pos: Vector3) -> void:
	var station := HomeStation.new()
	station.name = "Station_%s" % String(id)
	station.station_id = id
	station.care_action = action
	station.prompt_text = prompt
	station.position = pos
	add_child(station)
	station.station_activated.connect(_on_station_activated)
	_stations[id] = station


func _build_hud() -> void:
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	_hud.adventure_pressed.connect(_on_adventure)
	_hud.care_requested.connect(_on_care_requested)
	_hud.shop_pressed.connect(func() -> void:
		_hud.show_status_message("Shop soon — Bits ready for skins, homes, and gear.")
	)
	_hud.collection_pressed.connect(_on_collection)


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "HabitatCamera"
	_camera.position = Vector3(0.4, 2.8, 4.6)
	_camera.rotation_degrees = Vector3(-28, 0, 0)
	_camera.current = true
	_camera.fov = 42.0
	add_child(_camera)

	## Gentle idle sway — presence without noise.
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(_camera, "position:x", 0.55, 4.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_camera, "position:x", 0.25, 4.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _on_care_requested(action: StringName) -> void:
	var message := ""
	match action:
		&"feed":
			message = CreatureManager.feed()
		&"rest":
			message = CreatureManager.rest()
		&"play":
			message = CreatureManager.play()
		&"train":
			message = CreatureManager.train()
		&"pet":
			message = CreatureManager.pet()
		&"status":
			message = CreatureManager.get_detailed_status()
			if _companion:
				_companion.request_status_check()
			if _hud:
				_hud.show_status_message(message)
			EventBus.sfx_play_requested.emit(&"creature_status", Vector3.ZERO)
			return
	if _hud:
		_hud.show_status_message(message)
	if _companion:
		_companion.request_care(action)
	EventBus.sfx_play_requested.emit(StringName("creature_%s" % String(action)), Vector3.ZERO)


func _on_station_activated(_station_id: StringName, care_action: StringName) -> void:
	if _companion:
		_companion.request_care(care_action)


func _on_adventure() -> void:
	SceneManager.change_scene(String(GameConstants.SCENE_GAME_WORLD), true)


func _on_collection() -> void:
	if _hud and _hud.has_method("show_collection_journal"):
		_hud.call("show_collection_journal")
	elif _hud:
		_hud.show_status_message(CollectionManager.get_summary_line())
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
