extends BaseManager
## Input context switching and default action registration.
##
## WHY: Overworld, menus, dialogue, vehicles, and combat need different input maps.
## InputManager tracks the active context and ensures move/care actions exist at boot.

enum Context {
	OVERWORLD,
	MENU,
	DIALOGUE,
	VEHICLE,
	COMBAT,
	BUILDING_INTERIOR,
	HOME,
}

var _active_context: Context = Context.HOME
var _context_stack: Array[Context] = []


func _initialize_manager() -> void:
	_register_default_actions()
	_log("InputManager initialized (context=%s)" % Context.keys()[_active_context])


func _register_default_actions() -> void:
	_add_key_action(&"move_left", [KEY_A, KEY_LEFT])
	_add_key_action(&"move_right", [KEY_D, KEY_RIGHT])
	_add_key_action(&"move_forward", [KEY_W, KEY_UP])
	_add_key_action(&"move_back", [KEY_S, KEY_DOWN])
	_add_key_action(&"interact", [KEY_E, KEY_SPACE])
	_add_key_action(&"go_home", [KEY_H])
	_add_key_action(&"go_adventure", [KEY_ENTER])
	_add_key_action(&"pause_menu", [KEY_ESCAPE])


func _add_key_action(action: StringName, keycodes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keycodes:
		var ev := InputEventKey.new()
		ev.physical_keycode = keycode
		if not InputMap.action_has_event(action, ev):
			InputMap.action_add_event(action, ev)


func get_context() -> Context:
	return _active_context


func push_context(context: Context) -> void:
	_context_stack.append(_active_context)
	_set_context(context)


func pop_context() -> void:
	if _context_stack.is_empty():
		return
	_set_context(_context_stack.pop_back())


func set_context(context: Context) -> void:
	_context_stack.clear()
	_set_context(context)


func _set_context(context: Context) -> void:
	_active_context = context
	_log("Input context -> %s" % Context.keys()[context])


func get_move_vector() -> Vector2:
	if _active_context == Context.MENU or _active_context == Context.DIALOGUE:
		return Vector2.ZERO
	return Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")


func is_action_pressed(action: StringName) -> bool:
	return Input.is_action_pressed(action)


func is_action_just_pressed(action: StringName) -> bool:
	return Input.is_action_just_pressed(action)
