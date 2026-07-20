class_name DeviceSettings
extends CanvasLayer
## Handheld settings sheet — Field Unit chrome, pad-only.
## D-pad move · A toggle · B close.

signal closed

var _open: bool = false
var _index: int = 0
var _root: PanelContainer
var _list: RichTextLabel
var _hint: Label
var _entries: Array[Dictionary] = []


static func present(parent: Node) -> DeviceSettings:
	var existing := parent.get_node_or_null("DeviceSettings") as DeviceSettings
	if existing:
		existing.open()
		return existing
	var s := DeviceSettings.new()
	s.name = "DeviceSettings"
	parent.add_child(s)
	s.open()
	return s


func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	set_process_input(false)


func open() -> void:
	_open = true
	visible = true
	set_process_input(true)
	_index = 0
	UIManager.push_modal(&"settings")
	_refresh()
	DFStyle.slide_in(_root, 18.0, 0.2)
	EventBus.sfx_play_requested.emit(&"menu_beep", Vector3.ZERO)


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	set_process_input(false)
	UIManager.pop_modal()
	closed.emit()
	EventBus.sfx_play_requested.emit(&"ui_cancel", Vector3.ZERO)


func _input(_event: InputEvent) -> void:
	if not _open:
		return
	if InputManager.is_action_just_pressed(&"ui_cancel") or InputManager.is_action_just_pressed(&"pause_menu"):
		close()
		get_viewport().set_input_as_handled()
		return
	var ui := InputManager.get_ui_vector_just()
	if ui.y != 0:
		_index = (_index + int(ui.y)) % _entries.size()
		if _index < 0:
			_index += _entries.size()
		_refresh()
		EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
		get_viewport().set_input_as_handled()
		return
	if InputManager.is_action_just_pressed(&"ui_confirm") or InputManager.is_action_just_pressed(&"interact"):
		_activate()
		get_viewport().set_input_as_handled()


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 36)
	add_child(margin)
	_root = PanelContainer.new()
	DFStyle.apply_sheet(_root)
	margin.add_child(_root)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_root.add_child(vbox)
	var title := Label.new()
	title.text = "◆ DEVICE SETTINGS"
	DFStyle.apply_label_cyan(title, DFStyle.FONT_TITLE)
	vbox.add_child(title)
	var sub := Label.new()
	sub.text = "DIGITAL FRONTIER  ·  FIELD UNIT OS"
	DFStyle.apply_label_paper(sub, DFStyle.FONT_HINT)
	sub.add_theme_color_override("font_color", WorldPalette.UI_MUTED)
	vbox.add_child(sub)
	_list = RichTextLabel.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.custom_minimum_size = Vector2(0, 220)
	DFStyle.apply_rich_sheet(_list)
	vbox.add_child(_list)
	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	DFStyle.apply_label_paper(_hint, DFStyle.FONT_HINT)
	_hint.add_theme_color_override("font_color", WorldPalette.UI_MUTED)
	vbox.add_child(_hint)
	_entries = [
		{"id": &"volume_up", "label": "Master Volume +", "blurb": "Louder beeps & music"},
		{"id": &"volume_down", "label": "Master Volume −", "blurb": "Quieter device"},
		{"id": &"haptics", "label": "Haptics", "blurb": "Toggle rumble feedback"},
		{"id": &"led", "label": "LED Pulse", "blurb": "Cycle device status light"},
		{"id": &"legend", "label": "Control Legend", "blurb": "Show button map toast"},
		{"id": &"close", "label": "Close Settings", "blurb": "Return to device"},
	]


func _refresh() -> void:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(DFStyle.color_tag(WorldPalette.UI_GOLD, "Volume  %d%%" % int(GameConfig.master_volume * 100.0)))
	lines.append("")
	for i in _entries.size():
		var e: Dictionary = _entries[i]
		lines.append(DFStyle.card_bb(String(e["label"]), String(e["blurb"]), i == _index, "◆" if i == _index else ""))
	_list.text = "\n".join(lines)
	_hint.text = "↑↓ select  ·  %s confirm  ·  %s back" % [
		InputManager.get_action_glyph(&"ui_confirm"),
		InputManager.get_action_glyph(&"ui_cancel"),
	]


func _activate() -> void:
	var e: Dictionary = _entries[_index]
	match e["id"]:
		&"volume_up":
			GameConfig.master_volume = clampf(GameConfig.master_volume + 0.1, 0.0, 1.0)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"), linear_to_db(GameConfig.master_volume))
			EventBus.sfx_play_requested.emit(&"ui_confirm", Vector3.ZERO)
		&"volume_down":
			GameConfig.master_volume = clampf(GameConfig.master_volume - 0.1, 0.0, 1.0)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"), linear_to_db(GameConfig.master_volume))
			EventBus.sfx_play_requested.emit(&"ui_confirm", Vector3.ZERO)
		&"haptics":
			DeviceService.notify_event(&"ui")
			EventBus.ui_notification_requested.emit("Haptics pulsed", 1.2)
			EventBus.sfx_play_requested.emit(&"ui_confirm", Vector3.ZERO)
		&"led":
			DeviceService.set_led(WorldPalette.UI_CYAN if randf() > 0.5 else WorldPalette.UI_ACCENT, &"pulse")
			EventBus.sfx_play_requested.emit(&"ui_confirm", Vector3.ZERO)
		&"legend":
			EventBus.ui_notification_requested.emit(InputManager.get_control_legend(), 3.0)
			EventBus.sfx_play_requested.emit(&"menu_beep", Vector3.ZERO)
		&"close":
			close()
			return
	_refresh()
