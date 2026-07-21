extends Node
## Main persistent shell — never unloaded during a play session.
##
## Owns:
## - SceneContainer: active gameplay scene (home, world, combat)
## - UI root layers registered with UIManager
## - Transition overlay for SceneManager
## Boot: logo → profile select → partner select (new profile) → Digi-Pet Home.

@onready var scene_container: Node = $SceneContainer
@onready var transition_overlay: ColorRect = $TransitionOverlay


func _ready() -> void:
	add_to_group(&"main_shell")
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
	var boot := DeviceBootSequence.present(self)
	await boot.finished
	## Every power-on: choose who is playing (local profiles).
	var profiles := ProfileSelect.present(self)
	await profiles.profile_ready
	if not CreatureManager.has_chosen_partner():
		var select := PartnerSelect.present(self)
		await select.partner_chosen
		SaveManager.request_autosave()
	await SceneManager.change_scene(String(GameConstants.SCENE_HOME), false)


## Called from Settings — save current adventure, return to profile gate.
func return_to_profile_select() -> void:
	call_deferred("_profile_gate_from_settings")


func _profile_gate_from_settings() -> void:
	SaveManager.clear_active_profile(true)
	UIManager.clear_modals()
	## Unload gameplay scene so Digi-Pet reloads for the next user.
	if scene_container.get_child_count() > 0:
		for c in scene_container.get_children():
			c.queue_free()
	await get_tree().process_frame
	var profiles := ProfileSelect.present(self)
	await profiles.profile_ready
	if not CreatureManager.has_chosen_partner():
		var select := PartnerSelect.present(self)
		await select.partner_chosen
		SaveManager.request_autosave()
	await SceneManager.change_scene(String(GameConstants.SCENE_HOME), false)
