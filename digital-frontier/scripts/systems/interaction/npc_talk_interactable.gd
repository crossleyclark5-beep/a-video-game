class_name NpcTalkInteractable
extends Interactable
## Field Unit dialogue card — quest-aware lines via ChapterCast when available.

@export var npc_id: StringName = &""
@export var npc_display_name: String = "Someone"
@export_multiline var dialogue_lines: PackedStringArray = PackedStringArray(["Hello, traveler."])


func _ready() -> void:
	super._ready()
	if npc_id == &"":
		npc_id = StringName(name.to_snake_case())
	prompt_verb = "Talk"


func _on_interact(_actor: Node) -> void:
	var lines := ChapterCast.lines_for(npc_id)
	if lines.is_empty():
		lines = dialogue_lines
	if lines.is_empty():
		lines = PackedStringArray(["…"])
	var host := get_tree().current_scene if get_tree() else null
	if host == null:
		host = get_tree().root
	DeviceDialogue.present(host, npc_id, npc_display_name, lines)
