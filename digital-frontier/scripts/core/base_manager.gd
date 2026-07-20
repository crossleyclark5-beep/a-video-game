class_name BaseManager
extends Node
## Base class for autoload managers.
##
## Provides a consistent initialization lifecycle and debug logging hook.
## Subclasses override _initialize_manager() instead of _ready() when possible.

var _is_initialized: bool = false


func _ready() -> void:
	if not _is_initialized:
		_initialize_manager()
		_is_initialized = true


## Override in subclasses. Called once on first _ready().
func _initialize_manager() -> void:
	pass


func is_initialized() -> bool:
	return _is_initialized


func _log(message: String) -> void:
	if GameConfig.debug_logging:
		print("[%s] %s" % [name, message])
