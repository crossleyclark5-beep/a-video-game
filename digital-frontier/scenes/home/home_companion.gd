extends Control
## Home screen — care for your living companion, then go on an adventure.

@onready var _creature_visual: ColorRect = %CreaturePlaceholder
@onready var _creature_name: Label = %CreatureName
@onready var _mood_label: Label = %MoodLabel
@onready var _hunger_label: Label = %HungerLabel
@onready var _status_label: Label = %StatusLabel
@onready var _adventure_button: Button = %AdventureButton

var _refresh_timer: float = 0.0


func _ready() -> void:
	InputManager.set_context(InputManager.Context.HOME)
	if not EventBus.companion_state_changed.is_connected(_refresh_status):
		EventBus.companion_state_changed.connect(_refresh_status)
	_refresh_status()


func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= 0.5:
		_refresh_timer = 0.0
		_refresh_status()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"go_adventure"):
		_on_adventure_pressed()


func _refresh_status() -> void:
	_creature_name.text = CreatureManager.get_companion_nickname()
	_mood_label.text = "Mood: %s" % CreatureManager.get_mood_label()
	_hunger_label.text = "Hunger: %s (%d%%)" % [
		CreatureManager.get_hunger_label(),
		int(CreatureManager.get_hunger()),
	]
	_status_label.text = CreatureManager.get_status_line()
	_creature_visual.color = CreatureManager.get_mood_color()

	if CreatureManager.is_adventure_ready():
		_adventure_button.text = "Go on Adventure (Enter)"
		_adventure_button.modulate = Color.WHITE
	else:
		_adventure_button.text = "Adventure anyway (Enter) — companion needs care"
		_adventure_button.modulate = Color(1.0, 0.85, 0.7)


func _on_adventure_pressed() -> void:
	SceneManager.change_scene(String(GameConstants.SCENE_GAME_WORLD), true)


func _on_feed_pressed() -> void:
	_status_label.text = CreatureManager.feed()
	_refresh_status()


func _on_soothe_pressed() -> void:
	_status_label.text = CreatureManager.play()
	_refresh_status()


func _on_rest_pressed() -> void:
	_status_label.text = CreatureManager.rest()
	_refresh_status()
