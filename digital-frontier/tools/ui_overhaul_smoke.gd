extends SceneTree
## Thin launcher — prefer res://scenes/devtools/ui_overhaul_smoke.tscn instead.
## Kept for docs; -s can fail to compile DFFormat before autoloads exist.


func _initialize() -> void:
	print("Prefer: godot --path . res://scenes/devtools/ui_overhaul_smoke.tscn")
	quit(0)
