extends Node
## Boot scene — first scene loaded on game start.
##
## Responsibilities:
## - Verify autoload initialization
## - Optional splash / legal screens
## - Hand off to Main persistent shell

func _ready() -> void:
	call_deferred("_bootstrap")


func _bootstrap() -> void:
	# Autoloads initialize in project.godot order before this _ready().
	EventBus.bootstrap_completed.emit()
	get_tree().change_scene_to_file(GameConstants.SCENE_MAIN)
