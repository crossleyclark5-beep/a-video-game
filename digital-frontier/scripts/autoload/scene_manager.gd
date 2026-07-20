extends BaseManager
## Scene loading, unloading, and transition orchestration.
##
## WHY: Scene changes involve fade overlays, async loading, and state preservation.
## SceneManager owns the transition pipeline so individual systems request loads via EventBus.

const TRANSITION_FADE_DURATION := 0.35

var _current_scene: Node = null
var _main_container: Node = null
var _transition_overlay: CanvasItem = null
var _is_transitioning: bool = false


func _initialize_manager() -> void:
	EventBus.scene_transition_started.connect(_on_transition_started)
	_log("SceneManager initialized")


func register_main_container(container: Node) -> void:
	_main_container = container


func register_transition_overlay(overlay: CanvasItem) -> void:
	_transition_overlay = overlay


func get_current_scene() -> Node:
	return _current_scene


func is_transitioning() -> bool:
	return _is_transitioning


## Replace the active game scene inside the main container.
func change_scene(scene_path: String, fade: bool = true) -> void:
	if _is_transitioning:
		return
	if _main_container == null:
		push_error("SceneManager: main container not registered")
		return

	var from_name := StringName("")
	if _current_scene != null:
		from_name = _current_scene.scene_file_path.get_file().get_basename()

	EventBus.scene_transition_started.emit(from_name, StringName(scene_path.get_file().get_basename()))
	_is_transitioning = true
	## Drop Field Unit / menu modals so input context cannot stick across Home ↔ Adventure.
	UIManager.clear_modals()

	if fade and _transition_overlay != null:
		var tween := create_tween()
		tween.tween_property(_transition_overlay, "modulate:a", 1.0, TRANSITION_FADE_DURATION)
		await tween.finished

	await _swap_scene(scene_path)

	if fade and _transition_overlay != null:
		var tween_out := create_tween()
		tween_out.tween_property(_transition_overlay, "modulate:a", 0.0, TRANSITION_FADE_DURATION)
		await tween_out.finished

	_is_transitioning = false
	EventBus.scene_transition_finished.emit(StringName(scene_path.get_file().get_basename()))


func _swap_scene(scene_path: String) -> void:
	if _current_scene != null:
		_current_scene.queue_free()
		await _current_scene.tree_exited
		_current_scene = null

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("SceneManager: failed to load %s" % scene_path)
		return

	_current_scene = packed.instantiate()
	_main_container.add_child(_current_scene)


func _on_transition_started(_from: StringName, _to: StringName) -> void:
	_log("Transition: %s -> %s" % [_from, _to])
