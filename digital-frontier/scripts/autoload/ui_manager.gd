extends BaseManager
## UI layer stack, modal management, and HUD visibility.
##
## WHY: Multiple UI systems (HUD, inventory, dialogue, menus) compete for input focus.
## UIManager coordinates z-order, modal stacking, and InputManager context pushes.

enum Layer {
	HUD = 10,
	MENU = 20,
	MODAL = 30,
	OVERLAY = 40,
	DEBUG = 50,
}

var _modal_stack: Array[StringName] = []
var _registered_layers: Dictionary = {}  ## layer_id -> CanvasLayer


func _initialize_manager() -> void:
	_log("UIManager initialized")


func register_layer(layer_id: StringName, layer: CanvasLayer) -> void:
	_registered_layers[layer_id] = layer


func get_layer(layer_id: StringName) -> CanvasLayer:
	return _registered_layers.get(layer_id)


func push_modal(modal_id: StringName) -> void:
	_modal_stack.append(modal_id)
	InputManager.push_context(InputManager.Context.MENU)
	EventBus.ui_modal_opened.emit(modal_id)


func pop_modal() -> void:
	if _modal_stack.is_empty():
		return
	var closed: StringName = _modal_stack.pop_back()
	if _modal_stack.is_empty():
		InputManager.pop_context()
	EventBus.ui_modal_closed.emit(closed)


func has_open_modal() -> bool:
	return not _modal_stack.is_empty()
