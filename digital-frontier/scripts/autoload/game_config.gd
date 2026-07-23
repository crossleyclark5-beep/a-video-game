extends BaseManager
## Runtime configuration, feature flags, and quality settings.
##
## WHY: Keeps tuning values out of gameplay code and enables build-time toggles
## (debug overlays, verbose logging, fast travel in dev builds).

@export var debug_logging: bool = OS.is_debug_build()
@export var show_debug_overlay: bool = OS.is_debug_build()
## Enables World Inspection Mode (F3 free-cam) and other temporary dev tools.
@export var enable_cheats: bool = OS.is_debug_build()

## Master audio levels (0.0 – 1.0). Persisted via SaveManager settings section.
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0

## Target frame budget for performance-sensitive systems (ms).
var target_frame_budget_ms: float = 16.6


func _initialize_manager() -> void:
	_log("GameConfig initialized (debug=%s)" % debug_logging)
