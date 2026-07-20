class_name HollowSealInteractable
extends Interactable
## Root seal pylon — light two to awaken the Warden arena.


var seal_id: StringName = &""
var seal_name: String = "Root Seal"
var sanctum: PineHollowSanctum = null


func _ready() -> void:
	super._ready()
	prompt_verb = "Activate"


func _on_interact(_actor: Node) -> void:
	if not bool(WorldManager.get_world_flag(&"hollow_root_gate_open", false)):
		EventBus.ui_notification_requested.emit("Open the Root Gate first.", 2.0)
		return
	if sanctum:
		sanctum.on_seal_activated(seal_id)
	## Visual feedback — brighten glow child if present.
	var glow := get_parent().get_node_or_null("Glow")
	if glow is MeshInstance3D:
		pass
	EventBus.ui_notification_requested.emit("%s resonates." % seal_name, 2.0)
