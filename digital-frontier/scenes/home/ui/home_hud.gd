extends CanvasLayer
## Home Field Unit — buttons-only navigation (D-pad + A/B/Start/Y).
## Mouse clicks still work as a secondary fallback for PC editor testing.

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
var _focus_index: int = 0
var _focus_entries: Array[Dictionary] = []  ## {id, button, callable}
var _hint_label: Label = null
var _focus_style: StyleBoxFlat = null
var _normal_btn_style: StyleBoxFlat = null


func _ready() -> void:
	_inventory_panel.visible = false
	_apply_device_chrome()
	_build_focus_strip()
	_ensure_hint_label()
	if not EventBus.companion_state_changed.is_connected(_refresh):
		EventBus.companion_state_changed.connect(_refresh)
	if not EventBus.inventory_changed.is_connected(_refresh):
		EventBus.inventory_changed.connect(_refresh)
	if not EventBus.ui_notification_requested.is_connected(_on_notification):
		EventBus.ui_notification_requested.connect(_on_notification)
	_refresh()
	_apply_focus_visual()


func _unhandled_input(_event: InputEvent) -> void:
	## Start / Enter → Adventure
	if InputManager.is_action_just_pressed(&"go_adventure") or InputManager.is_action_just_pressed(&"device_menu"):
		adventure_pressed.emit()
		get_viewport().set_input_as_handled()
		return
	## Y → quick pet
	if InputManager.is_action_just_pressed(&"creature_action"):
		care_requested.emit(&"pet")
		DeviceService.notify_event(&"creature_care")
		get_viewport().set_input_as_handled()
		return
	## B closes pack/collection sheet
	if InputManager.is_action_just_pressed(&"ui_cancel"):
		if _inventory_open:
			_inventory_open = false
			_inventory_panel.visible = false
			_status_label.text = "Ready."
			get_viewport().set_input_as_handled()
		return
	## D-pad / stick UI move focus
	var ui := InputManager.get_ui_vector_just()
	if ui.x != 0 or ui.y != 0:
		var delta := ui.x + ui.y  ## right/down = +1
		if delta != 0:
			_move_focus(delta)
			get_viewport().set_input_as_handled()
		return
	## A confirms focused item
	if InputManager.is_action_just_pressed(&"ui_confirm") or InputManager.is_action_just_pressed(&"interact"):
		_activate_focus()
		get_viewport().set_input_as_handled()


func _build_focus_strip() -> void:
	_focus_entries.clear()
	var order: Array[StringName] = [
		&"pet", &"feed", &"rest", &"play", &"train", &"status",
		&"pack", &"collection", &"shop", &"adventure",
	]
	for id in order:
		var btn := _find_button_for(id)
		if btn == null:
			continue
		_focus_entries.append({
			&"id": id,
			&"button": btn,
			&"callable": _callable_for(id),
		})
	## Prefer Adventure as default focus so Start isn't the only path.
	for i in _focus_entries.size():
		if _focus_entries[i][&"id"] == &"adventure":
			_focus_index = i
			break


func _find_button_for(id: StringName) -> Button:
	var path_map := {
		&"pet": "BottomBar/BottomMargin/BottomCol/CareRow/PetButton",
		&"feed": "BottomBar/BottomMargin/BottomCol/CareRow/FeedButton",
		&"rest": "BottomBar/BottomMargin/BottomCol/CareRow/RestButton",
		&"play": "BottomBar/BottomMargin/BottomCol/CareRow/PlayButton",
		&"train": "BottomBar/BottomMargin/BottomCol/CareRow/TrainButton",
		&"status": "BottomBar/BottomMargin/BottomCol/CareRow/StatusButton",
		&"pack": "BottomBar/BottomMargin/BottomCol/NavRow/InventoryButton",
		&"collection": "BottomBar/BottomMargin/BottomCol/NavRow/CollectionButton",
		&"shop": "BottomBar/BottomMargin/BottomCol/NavRow/ShopButton",
		&"adventure": "BottomBar/BottomMargin/BottomCol/NavRow/AdventureButton",
	}
	if path_map.has(id):
		return get_node_or_null(path_map[id]) as Button
	if id == &"adventure":
		return _adventure_btn
	return null


func _callable_for(id: StringName) -> Callable:
	match id:
		&"pet":
			return _on_pet_pressed
		&"feed":
			return _on_feed_pressed
		&"rest":
			return _on_rest_pressed
		&"play":
			return _on_play_pressed
		&"train":
			return _on_train_pressed
		&"status":
			return _on_status_pressed
		&"pack":
			return _on_inventory_pressed
		&"collection":
			return _on_collection_pressed
		&"shop":
			return _on_shop_pressed
		&"adventure":
			return _on_adventure_pressed
		_:
			return Callable()


func _move_focus(delta: int) -> void:
	if _focus_entries.is_empty():
		return
	_focus_index = (_focus_index + delta) % _focus_entries.size()
	if _focus_index < 0:
		_focus_index += _focus_entries.size()
	_apply_focus_visual()
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)


func _activate_focus() -> void:
	if _focus_entries.is_empty():
		return
	var entry: Dictionary = _focus_entries[_focus_index]
	var cb: Callable = entry[&"callable"]
	if cb.is_valid():
		cb.call()
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)


func _apply_focus_visual() -> void:
	for i in _focus_entries.size():
		var btn: Button = _focus_entries[i][&"button"]
		if btn == null:
			continue
		if i == _focus_index:
			if _focus_style:
				btn.add_theme_stylebox_override("normal", _focus_style)
			btn.modulate = Color(1.15, 1.2, 1.05)
			btn.grab_focus()
		else:
			if _normal_btn_style:
				btn.add_theme_stylebox_override("normal", _normal_btn_style.duplicate())
			btn.modulate = Color.WHITE
	_update_hint()


func _ensure_hint_label() -> void:
	_hint_label = Label.new()
	_hint_label.name = "ControlHint"
	_hint_label.anchor_left = 0.0
	_hint_label.anchor_right = 1.0
	_hint_label.anchor_top = 1.0
	_hint_label.anchor_bottom = 1.0
	_hint_label.offset_left = 16
	_hint_label.offset_right = -16
	_hint_label.offset_top = -36
	_hint_label.offset_bottom = -8
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 14)
	add_child(_hint_label)
	_update_hint()


func _update_hint() -> void:
	if _hint_label == null:
		return
	var focused := ""
	if not _focus_entries.is_empty():
		focused = String(_focus_entries[_focus_index][&"id"]).capitalize()
	_hint_label.text = "D-pad move  ·  %s %s  ·  %s back  ·  %s Adventure  ·  %s Pet" % [
		InputManager.get_action_glyph(&"ui_confirm"),
		focused,
		InputManager.get_action_glyph(&"ui_cancel"),
		InputManager.get_action_glyph(&"device_menu"),
		InputManager.get_action_glyph(&"creature_action"),
	]


func _apply_device_chrome() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.1, 0.16, 0.88)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 4
	panel_style.content_margin_right = 4
	panel_style.content_margin_top = 4
	panel_style.content_margin_bottom = 4
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.35, 0.7, 0.65, 0.55)

	for path in ["TopBar", "NeedsPanel", "BottomBar", "InventoryPanel"]:
		var node := get_node_or_null(path) as PanelContainer
		if node:
			node.add_theme_stylebox_override("panel", panel_style.duplicate())

	_normal_btn_style = StyleBoxFlat.new()
	_normal_btn_style.bg_color = Color(0.16, 0.22, 0.34, 0.95)
	_normal_btn_style.set_corner_radius_all(6)
	_normal_btn_style.content_margin_left = 10
	_normal_btn_style.content_margin_right = 10
	_normal_btn_style.content_margin_top = 8
	_normal_btn_style.content_margin_bottom = 8
	_normal_btn_style.border_width_bottom = 2
	_normal_btn_style.border_color = Color(0.4, 0.7, 0.85, 0.5)

	_focus_style = _normal_btn_style.duplicate()
	_focus_style.bg_color = Color(0.28, 0.45, 0.42, 0.98)
	_focus_style.border_color = Color(0.55, 0.95, 0.85, 0.95)
	_focus_style.border_width_left = 2
	_focus_style.border_width_right = 2
	_focus_style.border_width_top = 2
	_focus_style.border_width_bottom = 2

	var btn_hover := _normal_btn_style.duplicate()
	btn_hover.bg_color = Color(0.22, 0.32, 0.48, 0.98)

	for button in _find_buttons(self):
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_stylebox_override("normal", _normal_btn_style.duplicate())
		button.add_theme_stylebox_override("hover", btn_hover.duplicate())
		button.add_theme_stylebox_override("pressed", btn_hover.duplicate())
		button.add_theme_stylebox_override("focus", _focus_style.duplicate())
		button.add_theme_color_override("font_color", Color(0.88, 0.93, 1.0))
		button.add_theme_font_size_override("font_size", 16)

	var adv := _focus_style.duplicate()
	adv.bg_color = Color(0.2, 0.55, 0.55, 0.98)
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
	if not _status_label.text.begins_with("Shop") and not _status_label.text.begins_with("Collection"):
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
	if _inventory_open and _inventory_label.text.begins_with("==="):
		return  ## collection journal open
	_inventory_label.text = InventoryManager.get_pack_text()


func _on_notification(message: String, _duration: float) -> void:
	_status_label.text = message


func _on_adventure_pressed() -> void:
	adventure_pressed.emit()


func _on_shop_pressed() -> void:
	shop_pressed.emit()
	_status_label.text = "Shop soon — Bits ledger is ready."


func _on_collection_pressed() -> void:
	collection_pressed.emit()


func show_collection_journal() -> void:
	_inventory_open = true
	_inventory_panel.visible = true
	_inventory_label.add_theme_font_size_override("font_size", 15)
	_inventory_label.text = CollectionManager.get_journal_text()
	_status_label.text = CollectionManager.get_summary_line()


func _on_inventory_pressed() -> void:
	_inventory_open = not _inventory_open
	_inventory_panel.visible = _inventory_open
	if _inventory_open:
		_refresh_inventory_text()


func _on_feed_pressed() -> void:
	care_requested.emit(&"feed")
	DeviceService.notify_event(&"creature_care")


func _on_rest_pressed() -> void:
	care_requested.emit(&"rest")
	DeviceService.notify_event(&"creature_care")


func _on_play_pressed() -> void:
	care_requested.emit(&"play")
	DeviceService.notify_event(&"creature_care")


func _on_train_pressed() -> void:
	care_requested.emit(&"train")
	DeviceService.notify_event(&"creature_care")


func _on_pet_pressed() -> void:
	care_requested.emit(&"pet")
	DeviceService.notify_event(&"creature_care")


func _on_status_pressed() -> void:
	care_requested.emit(&"status")
	_status_label.text = CreatureManager.get_detailed_status()
