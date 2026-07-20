class_name Interactable
extends Area3D
## Reusable interaction target. Prompt text is verb-only; glyphs come from InputManager.

signal interacted(actor: Node)

@export var interaction_id: StringName = &""
@export var prompt_verb: String = "Interact"
@export var prompt_text: String = ""  ## Legacy full string; prefer prompt_verb
@export var enabled: bool = true
@export var once: bool = false
@export var consume_on_interact: bool = false

var _used: bool = false


func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 16  ## interactables
	collision_mask = 0
	add_to_group(&"interactables")
	if interaction_id == &"":
		interaction_id = StringName(name.to_snake_case())
	if prompt_text.is_empty() and not prompt_verb.is_empty():
		pass
	elif prompt_verb == "Interact" and not prompt_text.is_empty():
		## Migrate old "Press E to X" strings into verbs when possible.
		prompt_verb = _strip_legacy_prompt(prompt_text)


func can_interact(_actor: Node) -> bool:
	if not enabled:
		return false
	if once and _used:
		return false
	return true


func get_prompt_text() -> String:
	var verb := prompt_verb
	if verb.is_empty():
		verb = _strip_legacy_prompt(prompt_text) if not prompt_text.is_empty() else "Interact"
	return InputManager.format_prompt(verb, &"interact")


func interact(actor: Node) -> void:
	if not can_interact(actor):
		return
	_used = true
	interacted.emit(actor)
	_on_interact(actor)
	if consume_on_interact:
		enabled = false


func _on_interact(_actor: Node) -> void:
	pass


func _strip_legacy_prompt(text: String) -> String:
	var t := text.strip_edges()
	for prefix in ["Press E to ", "Press A to ", "Press E/A to "]:
		if t.begins_with(prefix):
			var rest := t.substr(prefix.length()).strip_edges()
			if rest.length() > 0:
				return rest.substr(0, 1).to_upper() + rest.substr(1)
	return t
