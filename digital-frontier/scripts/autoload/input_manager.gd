extends BaseManager
## Handheld-first input: contexts, pad+keyboard fallbacks, prompt glyphs, remap hooks.
##
## Design target = custom handheld (physical buttons only). Keyboard bindings exist
## so the Godot editor on PC can simulate the device.

enum Context {
	OVERWORLD,
	MENU,
	DIALOGUE,
	VEHICLE,
	COMBAT,
	BUILDING_INTERIOR,
	HOME,
}

## Last device used for glyph hints (keyboard still works as fallback).
enum DeviceKind {
	GAMEPAD,
	KEYBOARD,
}

var _active_context: Context = Context.HOME
var _context_stack: Array[Context] = []
var _last_device: DeviceKind = DeviceKind.GAMEPAD
var _custom_binds: Dictionary = {}  ## action -> Array of InputEvent (remap API)


func _initialize_manager() -> void:
	_register_default_actions()
	_log("InputManager initialized (handheld-first, context=%s)" % Context.keys()[_active_context])


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_last_device = DeviceKind.GAMEPAD
	elif event is InputEventKey and event.pressed:
		_last_device = DeviceKind.KEYBOARD


func _register_default_actions() -> void:
	## Movement — keyboard + stick + D-pad
	_add_key_action(&"move_left", [KEY_A, KEY_LEFT])
	_add_key_action(&"move_right", [KEY_D, KEY_RIGHT])
	_add_key_action(&"move_forward", [KEY_W, KEY_UP])
	_add_key_action(&"move_back", [KEY_S, KEY_DOWN])
	_add_joy_axis(&"move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis(&"move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis(&"move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis(&"move_back", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_button(&"move_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy_button(&"move_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joy_button(&"move_forward", JOY_BUTTON_DPAD_UP)
	_add_joy_button(&"move_back", JOY_BUTTON_DPAD_DOWN)

	## A — interact / confirm
	_add_key_action(&"interact", [KEY_E, KEY_SPACE])
	_add_joy_button(&"interact", JOY_BUTTON_A)
	_add_key_action(&"ui_confirm", [KEY_E, KEY_SPACE, KEY_ENTER])
	_add_joy_button(&"ui_confirm", JOY_BUTTON_A)

	## B — cancel / back
	_add_key_action(&"ui_cancel", [KEY_ESCAPE, KEY_BACKSPACE])
	_add_joy_button(&"ui_cancel", JOY_BUTTON_B)

	## UI focus (menus) — share D-pad / arrows
	_add_key_action(&"ui_left", [KEY_LEFT, KEY_A])
	_add_key_action(&"ui_right", [KEY_RIGHT, KEY_D])
	_add_key_action(&"ui_up", [KEY_UP, KEY_W])
	_add_key_action(&"ui_down", [KEY_DOWN, KEY_S])
	_add_joy_button(&"ui_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy_button(&"ui_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joy_button(&"ui_up", JOY_BUTTON_DPAD_UP)
	_add_joy_button(&"ui_down", JOY_BUTTON_DPAD_DOWN)

	## Shoulders / face extras
	_add_key_action(&"run", [KEY_SHIFT])
	_add_joy_button(&"run", JOY_BUTTON_LEFT_SHOULDER)
	_add_key_action(&"device_menu", [KEY_TAB])
	_add_joy_button(&"device_menu", JOY_BUTTON_START)
	_add_key_action(&"device_cycle", [KEY_Q])
	_add_joy_button(&"device_cycle", JOY_BUTTON_X)
	_add_key_action(&"creature_action", [KEY_C])
	_add_joy_button(&"creature_action", JOY_BUTTON_Y)
	_add_key_action(&"map_peek", [KEY_M])
	_add_joy_button(&"map_peek", JOY_BUTTON_RIGHT_SHOULDER)
	_add_key_action(&"pause_menu", [KEY_F1])
	_add_joy_button(&"pause_menu", JOY_BUTTON_BACK)

	## Scene shortcuts — Start is context-sensitive in scenes (Home=Adventure, Field=menu).
	_add_key_action(&"go_home", [KEY_H])
	_add_key_action(&"go_adventure", [KEY_ENTER])
	## Select+B handled in player for pad home; Start opens device / starts adventure by scene.


func _add_key_action(action: StringName, keycodes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keycodes:
		var ev := InputEventKey.new()
		ev.physical_keycode = keycode
		if not InputMap.action_has_event(action, ev):
			InputMap.action_add_event(action, ev)


func _add_joy_button(action: StringName, button_index: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button_index
	if not InputMap.action_has_event(action, ev):
		InputMap.action_add_event(action, ev)


func _add_joy_axis(action: StringName, axis: int, axis_value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = axis_value
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
	if _active_context == Context.MENU or _active_context == Context.DIALOGUE or _active_context == Context.HOME:
		return Vector2.ZERO
	return Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")


func get_ui_vector_just() -> Vector2i:
	## One-step D-pad style for menu focus.
	var x := 0
	var y := 0
	if is_action_just_pressed(&"ui_left") or is_action_just_pressed(&"move_left"):
		x -= 1
	if is_action_just_pressed(&"ui_right") or is_action_just_pressed(&"move_right"):
		x += 1
	if is_action_just_pressed(&"ui_up") or is_action_just_pressed(&"move_forward"):
		y -= 1
	if is_action_just_pressed(&"ui_down") or is_action_just_pressed(&"move_back"):
		y += 1
	return Vector2i(x, y)


func is_action_pressed(action: StringName) -> bool:
	return Input.is_action_pressed(action)


func is_action_just_pressed(action: StringName) -> bool:
	return Input.is_action_just_pressed(action)


func get_last_device() -> DeviceKind:
	return _last_device


## Face-button glyph for prompts (prefer pad labels — this is a handheld game).
func get_action_glyph(action: StringName) -> String:
	match action:
		&"interact", &"ui_confirm":
			return "A" if _last_device == DeviceKind.GAMEPAD else "A/E"
		&"ui_cancel":
			return "B" if _last_device == DeviceKind.GAMEPAD else "B/Esc"
		&"device_menu":
			return "Start" if _last_device == DeviceKind.GAMEPAD else "Start/Tab"
		&"device_cycle":
			return "X" if _last_device == DeviceKind.GAMEPAD else "X/Q"
		&"creature_action":
			return "Y" if _last_device == DeviceKind.GAMEPAD else "Y/C"
		&"map_peek":
			return "R" if _last_device == DeviceKind.GAMEPAD else "R/M"
		&"run":
			return "L" if _last_device == DeviceKind.GAMEPAD else "L/Shift"
		&"go_home":
			return "Select" if _last_device == DeviceKind.GAMEPAD else "Select/H"
		&"go_adventure":
			return "Start" if _last_device == DeviceKind.GAMEPAD else "Start/Enter"
		&"pause_menu":
			return "Select"
		_:
			return "A"


func format_prompt(verb: String, action: StringName = &"interact") -> String:
	return "%s — %s" % [get_action_glyph(action), verb]


## Remap API — replace all events for an action (settings screen later).
func rebind_action(action: StringName, events: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	for ev in events:
		if ev is InputEvent:
			InputMap.action_add_event(action, ev)
	_custom_binds[action] = events.duplicate()


func get_control_legend() -> String:
	return "Move  ·  %s interact  ·  %s menu  ·  %s cycle  ·  %s map  ·  %s run  ·  %s home" % [
		get_action_glyph(&"interact"),
		get_action_glyph(&"device_menu"),
		get_action_glyph(&"device_cycle"),
		get_action_glyph(&"map_peek"),
		get_action_glyph(&"run"),
		get_action_glyph(&"go_home"),
	]
