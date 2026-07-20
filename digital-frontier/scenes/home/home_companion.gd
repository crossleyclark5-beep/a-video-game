extends Control
## Basic home screen — care for your companion, then go on an adventure.
## Phase 1 stub: mood/hunger are display-only placeholders.

@onready var _mood_label: Label = %MoodLabel
@onready var _hunger_label: Label = %HungerLabel
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	InputManager.set_context(InputManager.Context.HOME)
	_refresh_status()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"go_adventure"):
		_on_adventure_pressed()


func _refresh_status() -> void:
	# Real mood/hunger systems come in Phase 2. Friendly placeholders for now.
	_mood_label.text = "Mood: Happy"
	_hunger_label.text = "Hunger: Okay"
	_status_label.text = "Your companion is ready for an adventure."


func _on_adventure_pressed() -> void:
	SceneManager.change_scene(String(GameConstants.SCENE_GAME_WORLD), true)


func _on_feed_pressed() -> void:
	_status_label.text = "You shared a snack. (Full hunger system coming soon!)"
	_hunger_label.text = "Hunger: Full"


func _on_soothe_pressed() -> void:
	_status_label.text = "You played together. (Full mood system coming soon!)"
	_mood_label.text = "Mood: Excited"
