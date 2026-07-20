extends CanvasLayer
## Handheld adventure device HUD — Pack, Map, Quests, Collection, Bits.
## Placeholder chrome that feels like a dedicated explorer device.

enum Panel {
	NONE,
	PACK,
	MAP,
	QUESTS,
	LOG,
	BITS,
}

var _panel: Panel = Panel.NONE
var _root: PanelContainer
var _title: Label
var _bits: Label
var _quest_line: Label
var _body: RichTextLabel
var _toast: Label
var _hint: Label
var _toast_timer: float = 0.0
var _refresh_timer: float = 0.0


func _ready() -> void:
	layer = 12
	_build_ui()
	EventBus.ui_notification_requested.connect(_on_notification)
	EventBus.inventory_changed.connect(_refresh)
	EventBus.quest_updated.connect(_on_quest_pulse)
	EventBus.quest_completed.connect(_on_quest_pulse)
	EventBus.bits_changed.connect(_on_bits)
	EventBus.location_discovered.connect(_on_world_pulse)
	_refresh()


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_toast.visible = false
	_refresh_timer += delta
	if _refresh_timer >= 0.5:
		_refresh_timer = 0.0
		_refresh_chrome()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_TAB, KEY_I:
				_toggle(Panel.PACK)
				get_viewport().set_input_as_handled()
			KEY_M:
				_toggle(Panel.MAP)
				get_viewport().set_input_as_handled()
			KEY_J, KEY_Q:
				_toggle(Panel.QUESTS)
				get_viewport().set_input_as_handled()
			KEY_C, KEY_L:
				_toggle(Panel.LOG)
				get_viewport().set_input_as_handled()
			KEY_B:
				_toggle(Panel.BITS)
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				if _panel != Panel.NONE:
					_close_panel()
					get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(vbox)

	## Top device bar
	var top := PanelContainer.new()
	top.name = "TopBar"
	vbox.add_child(top)
	var top_row := HBoxContainer.new()
	top.add_child(top_row)
	_title = Label.new()
	_title.text = "DIGITAL FRONTIER  ·  FIELD UNIT"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(_title)
	_bits = Label.new()
	_bits.text = "0 Bits"
	top_row.add_child(_bits)

	_quest_line = Label.new()
	_quest_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_line.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_quest_line)

	## Nav row
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(nav)
	_add_nav_button(nav, "Pack [Tab]", Panel.PACK)
	_add_nav_button(nav, "Map [M]", Panel.MAP)
	_add_nav_button(nav, "Quests [J]", Panel.QUESTS)
	_add_nav_button(nav, "Log [C]", Panel.LOG)
	_add_nav_button(nav, "Bits [B]", Panel.BITS)

	## Expandable panel body
	_root = PanelContainer.new()
	_root.visible = false
	_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.custom_minimum_size = Vector2(0, 280)
	vbox.add_child(_root)
	var body_margin := MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 10)
	body_margin.add_theme_constant_override("margin_right", 10)
	body_margin.add_theme_constant_override("margin_top", 8)
	body_margin.add_theme_constant_override("margin_bottom", 8)
	_root.add_child(body_margin)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = false
	_body.fit_content = false
	_body.scroll_active = true
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.custom_minimum_size = Vector2(0, 240)
	body_margin.add_child(_body)

	_toast = Label.new()
	_toast.visible = false
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_toast)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.text = "WASD move · E interact · Tab pack · M map · J quests · C log · H home"
	vbox.add_child(_hint)

	_apply_device_chrome(top)


func _add_nav_button(parent: HBoxContainer, text: String, panel: Panel) -> void:
	var btn := Button.new()
	btn.text = text
	btn.pressed.connect(func() -> void: _toggle(panel))
	parent.add_child(btn)


func _apply_device_chrome(top: PanelContainer) -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.1, 0.14, 0.88)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 8
	panel_style.content_margin_right = 8
	panel_style.content_margin_top = 6
	panel_style.content_margin_bottom = 6
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.35, 0.7, 0.65, 0.55)
	top.add_theme_stylebox_override("panel", panel_style)
	_root.add_theme_stylebox_override("panel", panel_style.duplicate())

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.14, 0.2, 0.28, 0.95)
	btn_style.set_corner_radius_all(5)
	btn_style.content_margin_left = 8
	btn_style.content_margin_right = 8
	btn_style.content_margin_top = 4
	btn_style.content_margin_bottom = 4
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.4, 0.75, 0.7, 0.5)
	for child in get_children():
		_style_buttons(child, btn_style)


func _style_buttons(node: Node, style: StyleBoxFlat) -> void:
	if node is Button:
		var b := node as Button
		b.add_theme_stylebox_override("normal", style.duplicate())
		var hover := style.duplicate()
		hover.bg_color = Color(0.2, 0.32, 0.4, 0.98)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_color_override("font_color", Color(0.85, 0.95, 0.92))
	for child in node.get_children():
		_style_buttons(child, style)


func _toggle(panel: Panel) -> void:
	if _panel == panel:
		_close_panel()
		return
	var was_open := _panel != Panel.NONE
	_panel = panel
	_root.visible = true
	if not was_open:
		UIManager.push_modal(&"adventure_device")
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
	_refresh()


func _close_panel() -> void:
	if _panel == Panel.NONE:
		return
	_panel = Panel.NONE
	_root.visible = false
	if UIManager.has_open_modal():
		UIManager.pop_modal()


func _refresh(_a = null) -> void:
	_refresh_chrome()
	match _panel:
		Panel.PACK:
			_body.text = InventoryManager.get_pack_text()
		Panel.MAP:
			_body.text = WorldManager.get_map_blurb()
		Panel.QUESTS:
			_body.text = QuestManager.get_quest_status_line()
		Panel.LOG:
			_body.text = CollectionManager.get_journal_text()
		Panel.BITS:
			_body.text = InventoryManager.get_ledger_summary_text()
		_:
			pass


func _refresh_chrome() -> void:
	_bits.text = "%d Bits" % InventoryManager.get_bits()
	_quest_line.text = QuestManager.get_quest_status_line()


func _on_notification(message: String, duration: float) -> void:
	_toast.text = message
	_toast.visible = true
	_toast_timer = duration


func _on_quest_pulse(_a = null, _b = null) -> void:
	_refresh()


func _on_bits(_t = null, _d = null) -> void:
	_refresh_chrome()
	if _panel == Panel.BITS or _panel == Panel.PACK:
		_refresh()


func _on_world_pulse(_a = null) -> void:
	if _panel == Panel.MAP or _panel == Panel.LOG:
		_refresh()
