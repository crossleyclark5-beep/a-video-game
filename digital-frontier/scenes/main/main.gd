extends Node
## Main persistent shell — never unloaded during a play session.
##
## Owns:
## - SceneContainer: active gameplay scene (home, world, combat)
## - UI root layers registered with UIManager
## - Transition overlay for SceneManager

@onready var scene_container: Node = $SceneContainer
@onready var transition_overlay: ColorRect = $TransitionOverlay


func _ready() -> void:
	SceneManager.register_main_container(scene_container)
	SceneManager.register_transition_overlay(transition_overlay)
	_register_ui_layers()
	_start_game()


func _register_ui_layers() -> void:
	UIManager.register_layer(&"hud", $UI/HUDLayer)
	UIManager.register_layer(&"menu", $UI/MenuLayer)
	UIManager.register_layer(&"modal", $UI/ModalLayer)
	UIManager.register_layer(&"overlay", $UI/OverlayLayer)


func _start_game() -> void:
	# Phase 1: start at Home so the companion loop is obvious.
	await SceneManager.change_scene(GameConstants.SCENE_HOME, false)
