class_name Interactable
extends Area3D
## Reusable interaction target. Attach to doors, chests, signs, NPCs, POIs.
## InteractionAgent on the player discovers nearby Interactables automatically.

signal interacted(actor: Node)

@export var interaction_id: StringName = &""
@export var prompt_text: String = "Press E to interact"
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


func can_interact(_actor: Node) -> bool:
	if not enabled:
		return false
	if once and _used:
		return false
	return true


func get_prompt_text() -> String:
	return prompt_text


func interact(actor: Node) -> void:
	if not can_interact(actor):
		return
	_used = true
	interacted.emit(actor)
	_on_interact(actor)
	if consume_on_interact:
		enabled = false


## Override in subclasses / connect to interacted signal.
func _on_interact(_actor: Node) -> void:
	pass
