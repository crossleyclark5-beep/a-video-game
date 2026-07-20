class_name NpcTalkInteractable
extends Interactable
## Placeholder NPC talk target for quests / tutorial dialogue.

@export var npc_id: StringName = &""
@export var npc_display_name: String = "Someone"
@export_multiline var dialogue_lines: PackedStringArray = PackedStringArray(["Hello, traveler."])


func _ready() -> void:
	super._ready()
	if npc_id == &"":
		npc_id = StringName(name.to_snake_case())
	prompt_verb = "Talk"


func _on_interact(_actor: Node) -> void:
	EventBus.npc_dialogue_started.emit(npc_id)
	var line := dialogue_lines[0] if dialogue_lines.size() > 0 else "..."
	## Cycle a simple line index via world flag so repeats feel alive.
	var idx := int(WorldManager.get_world_flag(StringName("npc_line_%s" % String(npc_id)), 0))
	if dialogue_lines.size() > 0:
		idx = idx % dialogue_lines.size()
		line = dialogue_lines[idx]
		WorldManager.set_world_flag(StringName("npc_line_%s" % String(npc_id)), idx + 1)
	EventBus.ui_notification_requested.emit("%s: %s" % [npc_display_name, line], 3.5)
	EventBus.npc_dialogue_ended.emit(npc_id)
