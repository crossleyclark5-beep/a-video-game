class_name HollowGateInteractable
extends Interactable
## Root Gate at Pine Hollow — opens after Glitch Alpha falls.


var sanctum: PineHollowSanctum = null


func _ready() -> void:
	super._ready()
	prompt_verb = "Inspect"


func _on_interact(_actor: Node) -> void:
	if sanctum == null:
		return
	if sanctum.try_open_gate(true):
		prompt_verb = "Enter"
	EventBus.sfx_play_requested.emit(&"ui_blip", global_position)
