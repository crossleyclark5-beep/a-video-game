extends CanvasLayer
## Handheld-device style HUD overlay for the creature home habitat.
## Feels like a dedicated game device — not a phone app chrome.

signal adventure_pressed
signal shop_pressed
signal collection_pressed
signal care_requested(action: StringName)

@onready var _name_label: Label = %CreatureName
@onready var _mood_label: Label = %MoodLabel
@onready var _level_label: Label = %LevelLabel
@onready var _status_label: Label = %StatusLabel
@onready var _bits_label: Label = %BitsLabel
@onready var _time_label: Label = %TimeLabel
@onready var _bar_xp: ProgressBar = %BarXP
@onready var _bar_hunger: ProgressBar = %BarHunger
@onready var _bar_happy: ProgressBar = %BarHappy
@onready var _bar_energy: ProgressBar = %BarEnergy
@onready var _bar_friend: ProgressBar = %BarFriend
@onready var _bar_health: ProgressBar = %BarHealth
@onready var _adventure_btn: Button = %AdventureButton
@onready var _inventory_panel: Control = %InventoryPanel
@onready var _inventory_label: Label = %InventoryLabel

var _refresh_timer: float = 0.0
var _inventory_open: bool = false


func _ready() -> void:
	_inventory_panel.visible = false
	_apply_device_chrome()
	if not EventBus.companion_state_changed.is_connected(_refresh):
		EventBus.companion_state_changed.connect(_refresh)
	if not EventBus.inventory_changed.is_connected(_refresh):
		EventBus.inventory_changed.connect(_refresh)
	if not EventBus.ui_notification_requested.is_connected(_on_notification):
		EventBus.ui_notification_requested.connect(_on_notification)
	_refresh()


func _apply_device_chrome() -> void:
	## Soft inset panels — dedicated device bezel language, not phone chrome.
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.1, 0.16, 0.82)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 4
	panel_style.content_margin_right = 4
	panel_style.content_margin_top = 4
	panel_style.content_margin_bottom = 4
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.35, 0.55, 0.75, 0.45)

	for path in ["TopBar", "NeedsPanel", "BottomBar", "InventoryPanel"]:
		var node := get_node_or_null(path) as PanelContainer
		if node:
			node.add_theme_stylebox_override("panel", panel_style.duplicate())

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.16, 0.22, 0.34, 0.95)
	btn_style.set_corner_radius_all(6)
	btn_style.content_margin_left = 10
	btn_style.content_margin_right = 10
	btn_style.content_margin_top = 6
	btn_style.content_margin_bottom = 6
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.4, 0.7, 0.85, 0.5)

	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = Color(0.22, 0.32, 0.48, 0.98)

	for button in _find_buttons(self):
		button.add_theme_stylebox_override("normal", btn_style.duplicate())
		button.add_theme_stylebox_override("hover", btn_hover.duplicate())
		button.add_theme_stylebox_override("pressed", btn_hover.duplicate())
		button.add_theme_color_override("font_color", Color(0.88, 0.93, 1.0))

	## Adventure is the primary action.
	var adv := StyleBoxFlat.new()
	adv.bg_color = Color(0.2, 0.55, 0.55, 0.98)
	adv.set_corner_radius_all(6)
	adv.content_margin_left = 12
	adv.content_margin_right = 12
	adv.content_margin_top = 6
	adv.content_margin_bottom = 6
	adv.border_width_bottom = 2
	adv.border_color = Color(0.45, 0.95, 0.85, 0.65)
	_adventure_btn.add_theme_stylebox_override("normal", adv)


func _find_buttons(node: Node) -> Array[Button]:
	var result: Array[Button] = []
	if node is Button:
		result.append(node as Button)
	for child in node.get_children():
		result.append_array(_find_buttons(child))
	return result


func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= 0.4:
		_refresh_timer = 0.0
		_refresh()


func set_time_label(text: String) -> void:
	_time_label.text = text


func show_status_message(text: String) -> void:
	_status_label.text = text


func _refresh() -> void:
	_name_label.text = CreatureManager.get_companion_nickname()
	_mood_label.text = CreatureManager.get_mood_label()
	_level_label.text = "Lv.%d  ·  XP %d%%" % [
		CreatureManager.get_level(),
		int(CreatureManager.get_xp_progress() * 100.0),
	]
	_status_label.text = CreatureManager.get_status_line()
	_bits_label.text = "%d Bits" % InventoryManager.get_bits()

	_bar_xp.value = CreatureManager.get_xp_progress() * 100.0
	_bar_hunger.value = CreatureManager.get_hunger()
	_bar_happy.value = CreatureManager.get_happiness()
	_bar_energy.value = CreatureManager.get_energy()
	_bar_friend.value = CreatureManager.get_friendship()
	_bar_health.value = CreatureManager.get_health()

	if CreatureManager.is_adventure_ready():
		_adventure_btn.text = "Adventure"
		_adventure_btn.modulate = Color.WHITE
	else:
		_adventure_btn.text = "Adventure*"
		_adventure_btn.modulate = Color(1.0, 0.88, 0.72)

	_refresh_inventory_text()


func _refresh_inventory_text() -> void:
	var state := InventoryManager.export_state()
	var items: Dictionary = state.get(&"items", state.get("items", {}))
	if items.is_empty():
		_inventory_label.text = "Pack empty\nBits: %d" % InventoryManager.get_bits()
	else:
		var lines: PackedStringArray = PackedStringArray()
		lines.append("Bits: %d" % InventoryManager.get_bits())
		for key in items.keys():
			lines.append("%s × %s" % [str(key), str(items[key])])
		_inventory_label.text = "\n".join(lines)


func _on_notification(message: String, _duration: float) -> void:
	_status_label.text = message


func _on_adventure_pressed() -> void:
	adventure_pressed.emit()


func _on_shop_pressed() -> void:
	shop_pressed.emit()
	_status_label.text = "Shop opens soon — earn Bits on adventures."


func _on_collection_pressed() -> void:
	collection_pressed.emit()


func show_collection_journal() -> void:
	_inventory_open = true
	_inventory_panel.visible = true
	_inventory_label.text = CollectionManager.get_journal_text()
	_status_label.text = CollectionManager.get_summary_line()


func _on_inventory_pressed() -> void:
	_inventory_open = not _inventory_open
	_inventory_panel.visible = _inventory_open
	_refresh_inventory_text()


func _on_feed_pressed() -> void:
	care_requested.emit(&"feed")


func _on_rest_pressed() -> void:
	care_requested.emit(&"rest")


func _on_play_pressed() -> void:
	care_requested.emit(&"play")


func _on_train_pressed() -> void:
	care_requested.emit(&"train")


func _on_pet_pressed() -> void:
	care_requested.emit(&"pet")


func _on_status_pressed() -> void:
	care_requested.emit(&"status")
	_status_label.text = CreatureManager.get_detailed_status()
