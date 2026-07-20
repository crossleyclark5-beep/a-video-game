class_name SignInteractable
extends Interactable
## Readable world sign / plaque.

@export_multiline var message: String = "Welcome to Pleasant Park."


func _ready() -> void:
	super._ready()
	prompt_text = "Press E to read"


func _on_interact(_actor: Node) -> void:
	EventBus.ui_notification_requested.emit(message, 3.5)
