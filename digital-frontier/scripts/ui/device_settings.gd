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
	_rebuild_entries()


func _rebuild_entries() -> void:
	_entries = [
		{"id": &"volume_up", "label": "Master Volume +", "blurb": "Louder beeps & music"},
		{"id": &"volume_down", "label": "Master Volume −", "blurb": "Quieter device"},
		{"id": &"haptics", "label": "Haptics", "blurb": "Toggle rumble feedback"},
		{"id": &"led", "label": "LED Pulse", "blurb": "Cycle device status light"},
		{"id": &"legend", "label": "Control Legend", "blurb": "Show button map toast"},
	]
	## Developer 3D inspection — visible ON/OFF in Adventure settings (debug builds).
	if GameConfig.enable_cheats:
		_entries.append({
			"id": &"view_3d",
			"label": "3D View",
			"blurb": _view_3d_blurb(),
		})
	_entries.append_array([
		{"id": &"switch_profile", "label": "Switch Profile", "blurb": "Save & choose another user"},
		{"id": &"close", "label": "Close Settings", "blurb": "Return to device"},
	])


func _view_3d_blurb() -> String:
	var on := _inspect_is_active()
	return "Developer camera · now %s · F3 also toggles" % ("ON" if on else "OFF")


func _inspect_is_active() -> bool:
	var nodes := get_tree().get_nodes_in_group(WorldInspectController.GROUP)
	if nodes.is_empty():
		return false
	var c := nodes[0] as WorldInspectController
	return c != null and c.is_active()


func _refresh() -> void:
	## Keep 3D View label current each redraw.
	_rebuild_entries()
	if _index >= _entries.size():
		_index = maxi(0, _entries.size() - 1)
	var lines: PackedStringArray = PackedStringArray()
	lines.append(DFStyle.color_tag(WorldPalette.UI_GOLD, "Volume  %d%%" % int(GameConfig.master_volume * 100.0)))
	if GameConfig.enable_cheats:
		var mode := "ON" if _inspect_is_active() else "OFF"
		lines.append(DFStyle.color_tag(WorldPalette.UI_CYAN, "3D View  %s" % mode))
	lines.append("")
	for i in _entries.size():
		var e: Dictionary = _entries[i]
		var label := String(e["label"])
		if e["id"] == &"view_3d":
			label = "3D View · %s" % ("ON" if _inspect_is_active() else "OFF")
		lines.append(DFStyle.card_bb(label, String(e["blurb"]), i == _index, "◆" if i == _index else ""))
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
			AudioManager.refresh_volumes()
			EventBus.sfx_play_requested.emit(&"ui_confirm", Vector3.ZERO)
		&"volume_down":
			GameConfig.master_volume = clampf(GameConfig.master_volume - 0.1, 0.0, 1.0)
			AudioManager.refresh_volumes()
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
		&"view_3d":
			close()
			var inspects := get_tree().get_nodes_in_group(WorldInspectController.GROUP)
			if inspects.is_empty():
				EventBus.ui_notification_requested.emit("3D View unavailable in this scene.", 2.0)
				return
			var ctrl := inspects[0] as WorldInspectController
			if ctrl:
				ctrl.toggle_from_ui()
			return
		&"switch_profile":
			close()
			var main := get_tree().get_first_node_in_group(&"main_shell")
			if main == null:
				main = get_tree().root.get_node_or_null("Main")
			if main and main.has_method("return_to_profile_select"):
				main.call("return_to_profile_select")
			else:
				EventBus.ui_notification_requested.emit("Restart device to switch profiles", 2.2)
			return
		&"close":
			close()
			return
	_refresh()
