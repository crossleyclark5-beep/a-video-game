extends BaseManager
## Input context switching and action abstraction.
##
## WHY: Overworld, menus, dialogue, vehicles, and combat need different input maps.
## InputManager tracks the active context and exposes a single API to gameplay code.

enum Context {
	OVERWORLD,
	MENU,
	DIALOGUE,
	VEHICLE,
	COMBAT,
	BUILDING_INTERIOR,
}

var _active_context: Context = Context.OVERWORLD
var _context_stack: Array[Context] = []


func _initialize_manager() -> void:
	_log("InputManager initialized (context=%s)" % Context.keys()[_active_context])


func get_context() -> Context:
	return _active_context


func push_context(context: Context) -> void:
	_context_stack.append(_active_context)
	_set_context(context)


func pop_context() -> void:
	if _context_stack.is_empty():
		return
	_set_context(_context_stack.pop_back())


func _set_context(context: Context) -> void:
	_active_context = context
	_log("Input context -> %s" % Context.keys()[context])


func is_action_pressed(action: StringName) -> bool:
	## Future: filter by active context before checking InputMap.
	return Input.is_action_pressed(action)


func is_action_just_pressed(action: StringName) -> bool:
	return Input.is_action_just_pressed(action)
