extends CanvasLayer
## Home Field Unit — buttons-only navigation (D-pad + A/B/Start/Y).
## Mouse clicks still work as a secondary fallback for PC editor testing.

signal adventure_pressed
signal shop_pressed
signal collection_pressed
signal battle_pressed
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
@onready var _inventory_label: RichTextLabel = %InventoryLabel
var _inventory_mode: StringName = &"pack"

var _refresh_timer: float = 0.0
var _inventory_open: bool = false
var _focus_index: int = 0
var _focus_entries: Array[Dictionary] = []  ## {id, button, callable}
var _hint_label: Label = null
var _focus_style: StyleBoxFlat = null
var _normal_btn_style: StyleBoxFlat = null


func _ready() -> void:
	_inventory_panel.visible = false
	## Digi-pet: status meters live behind Status sheet, not a permanent RPG sidebar.
	var needs := get_node_or_null("NeedsPanel") as Control
	if needs:
		needs.visible = false
	_apply_device_chrome()
	_relabel_digipet_buttons()
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


func _relabel_digipet_buttons() -> void:
	## Core digi-pet loop labels (classic companion device feel).
	var map := {
		"BottomBar/BottomMargin/BottomCol/CareRow/PetButton": "Interact",
		"BottomBar/BottomMargin/BottomCol/CareRow/FeedButton": "Feed",
		"BottomBar/BottomMargin/BottomCol/CareRow/RestButton": "Heal",
		"BottomBar/BottomMargin/BottomCol/CareRow/PlayButton": "Train",
		"BottomBar/BottomMargin/BottomCol/CareRow/TrainButton": "Status",
		"BottomBar/BottomMargin/BottomCol/CareRow/StatusButton": "Battle",
		"BottomBar/BottomMargin/BottomCol/NavRow/InventoryButton": "Pack",
		"BottomBar/BottomMargin/BottomCol/NavRow/CollectionButton": "Journal",
		"BottomBar/BottomMargin/BottomCol/NavRow/ShopButton": "Shop",
		"BottomBar/BottomMargin/BottomCol/NavRow/AdventureButton": "Adventure",
	}
	for path in map.keys():
		var btn := get_node_or_null(path) as Button
		if btn:
			btn.text = map[path]


func _unhandled_input(_event: InputEvent) -> void:
	## Start / Enter → Adventure
	if InputManager.is_action_just_pressed(&"go_adventure") or InputManager.is_action_just_pressed(&"device_menu"):
		adventure_pressed.emit()
		get_viewport().set_input_as_handled()
		return
	## Select → Settings
	if InputManager.is_action_just_pressed(&"pause_menu"):
		DeviceSettings.present(self)
		get_viewport().set_input_as_handled()
		return
	## Y → quick interact
	if InputManager.is_action_just_pressed(&"creature_action"):
		care_requested.emit(&"interact")
		DeviceService.notify_event(&"creature_care")
		get_viewport().set_input_as_handled()
		return
	## B closes pack/collection sheet
	if InputManager.is_action_just_pressed(&"ui_cancel"):
		if _inventory_open:
			_inventory_open = false
			_inventory_mode = &"pack"
			_inventory_panel.visible = false
			_status_label.text = "Ready."
			EventBus.sfx_play_requested.emit(&"ui_cancel", Vector3.ZERO)
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
	## Care strip + device destinations — Adventure is the gateway out.
	var order: Array[StringName] = [
		&"interact", &"feed", &"heal", &"train", &"status", &"battle",
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
	for i in _focus_entries.size():
		if _focus_entries[i][&"id"] == &"adventure":
			_focus_index = i
			break


func _find_button_for(id: StringName) -> Button:
	## Remap digi-pet ids onto existing button nodes.
	var path_map := {
		&"interact": "BottomBar/BottomMargin/BottomCol/CareRow/PetButton",
		&"feed": "BottomBar/BottomMargin/BottomCol/CareRow/FeedButton",
		&"heal": "BottomBar/BottomMargin/BottomCol/CareRow/RestButton",
		&"train": "BottomBar/BottomMargin/BottomCol/CareRow/PlayButton",
		&"status": "BottomBar/BottomMargin/BottomCol/CareRow/TrainButton",
		&"battle": "BottomBar/BottomMargin/BottomCol/CareRow/StatusButton",
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
		&"interact":
			return _on_pet_pressed
		&"feed":
			return _on_feed_pressed
		&"heal":
			return _on_heal_pressed
		&"train":
			return _on_care_train_pressed
		&"status":
			return _on_show_status_pressed
		&"battle":
			return _on_battle_pressed
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
	_hint_label.text = "D-pad  ·  %s %s  ·  %s back  ·  %s Adventure  ·  Select settings" % [
		InputManager.get_action_glyph(&"ui_confirm"),
		focused,
		InputManager.get_action_glyph(&"ui_cancel"),
		InputManager.get_action_glyph(&"device_menu"),
	]
	DFStyle.apply_label_cyan(_hint_label, DFStyle.FONT_HINT)


func _apply_device_chrome() -> void:
	## Digital Frontier Field Unit chrome — shared with Adventure / Shop.
	for path in ["TopBar", "NeedsPanel", "BottomBar", "InventoryPanel"]:
		var node := get_node_or_null(path) as PanelContainer
		if node:
			if path == "InventoryPanel":
				DFStyle.apply_sheet(node)
			elif path == "BottomBar":
				DFStyle.apply_panel(node, true)
			else:
				DFStyle.apply_panel(node, false)

	_normal_btn_style = DFStyle.button_normal()
	_focus_style = DFStyle.button_focus()
	var btn_hover := DFStyle.button_hover()

	for button in _find_buttons(self):
		DFStyle.apply_button(button, false)
		button.add_theme_stylebox_override("hover", btn_hover.duplicate())

	DFStyle.apply_button(_adventure_btn, true)
	_adventure_btn.add_theme_font_size_override("font_size", 18)

	DFStyle.apply_label_ink(_name_label, DFStyle.FONT_TITLE)
	DFStyle.apply_label_cyan(_mood_label, DFStyle.FONT_BODY)
	DFStyle.apply_label_ink(_level_label, DFStyle.FONT_BODY)
	DFStyle.apply_label_ink(_status_label, DFStyle.FONT_HINT)
	DFStyle.apply_label_accent(_bits_label, DFStyle.FONT_SHEET)
	DFStyle.apply_label_ink(_time_label, DFStyle.FONT_HINT)
	DFStyle.apply_progress(_bar_xp, WorldPalette.UI_GOLD)
	DFStyle.apply_progress(_bar_hunger, WorldPalette.UI_ACCENT)
	DFStyle.apply_progress(_bar_happy, WorldPalette.UI_CYAN)
	DFStyle.apply_progress(_bar_energy, WorldPalette.UI_LIME)
	DFStyle.apply_progress(_bar_friend, WorldPalette.UI_PURPLE)
	DFStyle.apply_progress(_bar_health, WorldPalette.UI_DANGER)
	if _inventory_label:
		DFStyle.apply_rich_sheet(_inventory_label)


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
	var stage := CreatureManager.get_stage_display_name()
	var nick := CreatureManager.get_companion_nickname()
	if stage != nick and not stage.is_empty():
		_name_label.text = "%s  ·  %s" % [nick, stage]
	else:
		_name_label.text = nick
	_mood_label.text = "%s · %s" % [CreatureManager.get_mood_label(), CreatureManager.get_primary_trait_label()]
	_level_label.text = "Lv.%d  ·  XP %d%%" % [
		CreatureManager.get_level(),
		int(CreatureManager.get_xp_progress() * 100.0),
	]
	if CreatureManager.can_evolve():
		_level_label.text += "  ·  Ready to grow!"
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
	if not _inventory_open:
		return
	if _inventory_mode == &"journal":
		_inventory_label.text = DFFormat.collection_sheet()
	else:
		_inventory_label.text = DFFormat.pack_sheet()


func _on_notification(message: String, _duration: float) -> void:
	_status_label.text = message


func _on_adventure_pressed() -> void:
	adventure_pressed.emit()


func _on_shop_pressed() -> void:
	shop_pressed.emit()
	_status_label.text = "Opening Field Unit Shop…"


func _on_collection_pressed() -> void:
	collection_pressed.emit()


func show_collection_journal() -> void:
	_inventory_open = true
	_inventory_mode = &"journal"
	_inventory_panel.visible = true
	_refresh_inventory_text()
	_status_label.text = CollectionManager.get_summary_line()
	DFStyle.slide_in(_inventory_panel, 12.0, 0.18)
	EventBus.sfx_play_requested.emit(&"menu_beep", Vector3.ZERO)


func _on_inventory_pressed() -> void:
	if _inventory_open and _inventory_mode == &"pack":
		_inventory_open = false
		_inventory_panel.visible = false
		EventBus.sfx_play_requested.emit(&"ui_cancel", Vector3.ZERO)
		return
	_inventory_open = true
	_inventory_mode = &"pack"
	_inventory_panel.visible = true
	_refresh_inventory_text()
	DFStyle.slide_in(_inventory_panel, 12.0, 0.18)
	EventBus.sfx_play_requested.emit(&"menu_beep", Vector3.ZERO)


func _on_pet_pressed() -> void:
	care_requested.emit(&"interact")
	DeviceService.notify_event(&"creature_care")


func _on_feed_pressed() -> void:
	care_requested.emit(&"feed")
	DeviceService.notify_event(&"creature_care")


func _on_rest_pressed() -> void:
	## Scene connection: RestButton remapped to Heal.
	_on_heal_pressed()


func _on_play_pressed() -> void:
	## Scene connection: PlayButton remapped to Train.
	_on_care_train_pressed()


func _on_train_pressed() -> void:
	## Scene connection: TrainButton remapped to Status.
	_on_show_status_pressed()


func _on_status_pressed() -> void:
	## Scene connection: StatusButton remapped to Battle.
	_on_battle_pressed()


func _on_heal_pressed() -> void:
	care_requested.emit(&"heal")
	DeviceService.notify_event(&"creature_care")


func _on_care_train_pressed() -> void:
	care_requested.emit(&"train")
	DeviceService.notify_event(&"creature_care")


func _on_show_status_pressed() -> void:
	care_requested.emit(&"status")
	var needs := get_node_or_null("NeedsPanel") as Control
	if needs:
		needs.visible = not needs.visible
	_status_label.text = CreatureManager.get_detailed_status()


func _on_battle_pressed() -> void:
	battle_pressed.emit()
	_status_label.text = "Linking for battle…"
