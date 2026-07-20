extends CanvasLayer
## Handheld Field Unit — Pack / Map / Quests / Log / Bits.
## Buttons only: Start opens, X cycles, R map peek, B/Cancel closes, D-pad unused in sheet body (scroll later).

enum Panel {
	NONE,
	PACK,
	MAP,
	QUESTS,
	LOG,
	BITS,
}

const PANEL_ORDER: Array[Panel] = [Panel.PACK, Panel.MAP, Panel.QUESTS, Panel.LOG, Panel.BITS]

var _panel: Panel = Panel.NONE
var _root: PanelContainer
var _title: Label
var _bits: Label
var _quest_line: Label
var _companion_line: Label
var _notice_line: Label
var _body: RichTextLabel
var _toast: Label
var _hint: Label
var _tab_label: Label
var _toast_timer: float = 0.0
var _refresh_timer: float = 0.0
var _companion: AdventureCompanionActor = null


func _ready() -> void:
	layer = 12
	_build_ui()
	EventBus.ui_notification_requested.connect(_on_notification)
	EventBus.inventory_changed.connect(_refresh)
	EventBus.quest_updated.connect(_on_quest_pulse)
	EventBus.quest_completed.connect(_on_quest_pulse)
	EventBus.bits_changed.connect(_on_bits)
	EventBus.location_discovered.connect(_on_world_pulse)
	EventBus.companion_state_changed.connect(_refresh_chrome)
	EventBus.companion_noticed.connect(_on_companion_notice)
	_refresh()


func bind_companion(companion: AdventureCompanionActor) -> void:
	_companion = companion
	_refresh_chrome()


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_toast.visible = false
	_refresh_timer += delta
	if _refresh_timer >= 0.5:
		_refresh_timer = 0.0
		_refresh_chrome()


func _unhandled_input(_event: InputEvent) -> void:
	## All via InputMap actions — no mouse / raw keycodes required.
	if InputManager.is_action_just_pressed(&"device_menu"):
		if _panel == Panel.NONE:
			_open(Panel.PACK)
		else:
			_close_panel()
		get_viewport().set_input_as_handled()
		return
	if InputManager.is_action_just_pressed(&"map_peek"):
		_open(Panel.MAP)
		get_viewport().set_input_as_handled()
		return
	if InputManager.is_action_just_pressed(&"device_cycle"):
		if _panel == Panel.NONE:
			_open(Panel.PACK)
		else:
			_cycle(1)
		get_viewport().set_input_as_handled()
		return
	if InputManager.is_action_just_pressed(&"ui_cancel"):
		if _panel != Panel.NONE:
			_close_panel()
			get_viewport().set_input_as_handled()
		return
	if _panel != Panel.NONE and InputManager.is_action_just_pressed(&"ui_confirm"):
		## A while sheet open = acknowledge / soft refresh (no mouse click needed).
		_refresh()
		EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	var top := PanelContainer.new()
	top.name = "TopBar"
	vbox.add_child(top)
	var top_row := HBoxContainer.new()
	top.add_child(top_row)
	_title = Label.new()
	_title.text = "FIELD UNIT"
	_title.add_theme_font_size_override("font_size", 22)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(_title)
	_bits = Label.new()
	_bits.add_theme_font_size_override("font_size", 22)
	_bits.text = "0 Bits"
	top_row.add_child(_bits)

	_quest_line = Label.new()
	_quest_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_line.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_quest_line)

	_companion_line = Label.new()
	_companion_line.add_theme_font_size_override("font_size", 16)
	_companion_line.add_theme_color_override("font_color", Color(0.7, 0.92, 0.95))
	vbox.add_child(_companion_line)

	_notice_line = Label.new()
	_notice_line.visible = false
	_notice_line.add_theme_font_size_override("font_size", 17)
	_notice_line.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	vbox.add_child(_notice_line)

	_tab_label = Label.new()
	_tab_label.add_theme_font_size_override("font_size", 18)
	_tab_label.visible = false
	vbox.add_child(_tab_label)

	_root = PanelContainer.new()
	_root.visible = false
	_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.custom_minimum_size = Vector2(0, 260)
	vbox.add_child(_root)
	var body_margin := MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 12)
	body_margin.add_theme_constant_override("margin_right", 12)
	body_margin.add_theme_constant_override("margin_top", 10)
	body_margin.add_theme_constant_override("margin_bottom", 10)
	_root.add_child(body_margin)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = false
	_body.scroll_active = true
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.custom_minimum_size = Vector2(0, 220)
	_body.add_theme_font_size_override("normal_font_size", 18)
	body_margin.add_child(_body)

	_toast = Label.new()
	_toast.visible = false
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_toast)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 15)
	vbox.add_child(_hint)

	_apply_device_chrome(top)


func _apply_device_chrome(top: PanelContainer) -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.09, 0.12, 0.92)
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.35, 0.75, 0.65, 0.7)
	top.add_theme_stylebox_override("panel", panel_style)
	_root.add_theme_stylebox_override("panel", panel_style.duplicate())


func _open(panel: Panel) -> void:
	var was_open := _panel != Panel.NONE
	_panel = panel
	_root.visible = true
	_tab_label.visible = true
	if not was_open:
		UIManager.push_modal(&"adventure_device")
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
	DeviceService.play_haptic(&"ui", 0.2)
	_refresh()


func _cycle(dir: int) -> void:
	var idx := PANEL_ORDER.find(_panel)
	if idx < 0:
		idx = 0
	idx = (idx + dir) % PANEL_ORDER.size()
	_open(PANEL_ORDER[idx])


func _close_panel() -> void:
	if _panel == Panel.NONE:
		return
	_panel = Panel.NONE
	_root.visible = false
	_tab_label.visible = false
	if UIManager.has_open_modal():
		UIManager.pop_modal()
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)


func _panel_title(p: Panel) -> String:
	match p:
		Panel.PACK:
			return "PACK"
		Panel.MAP:
			return "MAP"
		Panel.QUESTS:
			return "QUESTS"
		Panel.LOG:
			return "COLLECTION"
		Panel.BITS:
			return "BITS"
		_:
			return ""


func _refresh(_a = null) -> void:
	_refresh_chrome()
	_tab_label.text = "%s   (%s cycle · %s close)" % [
		_panel_title(_panel),
		InputManager.get_action_glyph(&"device_cycle"),
		InputManager.get_action_glyph(&"ui_cancel"),
	]
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
	_companion_line.text = CreatureManager.get_adventure_status_line()
	var disc := CollectionManager.get_discovery_progress()
	_companion_line.text += "  ·  Map %d/%d" % [disc.x, disc.y]
	if _companion and _companion.has_active_notice():
		_notice_line.visible = true
		_notice_line.text = _companion.get_notice_prompt()
	else:
		_notice_line.visible = false
	_hint.text = InputManager.get_control_legend() + "  ·  %s companion" % InputManager.get_action_glyph(&"creature_action")


func _on_companion_notice(_id: StringName = &"", _kind: StringName = &"") -> void:
	_refresh_chrome()


func _on_notification(message: String, duration: float) -> void:
	_toast.text = message
	_toast.visible = true
	_toast_timer = duration


func _on_quest_pulse(_a = null, _b = null) -> void:
	if _a is StringName:
		DeviceService.notify_event(&"quest_complete")
	_refresh()


func _on_bits(_t = null, _d = null) -> void:
	_refresh_chrome()
	if _panel == Panel.BITS or _panel == Panel.PACK:
		_refresh()


func _on_world_pulse(_a = null) -> void:
	if _panel == Panel.MAP or _panel == Panel.LOG:
		_refresh()
