extends CanvasLayer
## Handheld Field Unit — Pack / Map / Quests / Log / Bits.
## Buttons only: Start opens, X cycles, R map peek, B/Cancel closes, D-pad unused in sheet body (scroll later).

enum DeviceSheet {
	NONE,
	PACK,
	MAP,
	QUESTS,
	LOG,
	INDEX,
	BITS,
}

const PANEL_ORDER: Array[DeviceSheet] = [DeviceSheet.PACK, DeviceSheet.MAP, DeviceSheet.QUESTS, DeviceSheet.LOG, DeviceSheet.INDEX, DeviceSheet.BITS]

var _panel: DeviceSheet = DeviceSheet.NONE
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
var _mini_map: RegionMiniMap = null
var _sheet_map: RegionMiniMap = null
var _map_host: VBoxContainer = null
var _player: Node3D = null
var _health: PlayerHealth = null
var _hp_bar: ProgressBar = null
var _hp_label: Label = null


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
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_respawned.connect(_on_player_respawned)
	EventBus.creature_discovered.connect(_on_creature_discovered)
	EventBus.day_phase_changed.connect(_on_phase_chrome)
	EventBus.weather_changed.connect(_on_weather_chrome)
	_refresh()


func bind_companion(companion: AdventureCompanionActor) -> void:
	_companion = companion
	_refresh_chrome()


func bind_player(player: Node3D) -> void:
	_player = player
	if _mini_map:
		_mini_map.bind_player(player)
	if _sheet_map:
		_sheet_map.bind_player(player)


func bind_player_health(health: PlayerHealth) -> void:
	_health = health
	if _health and not _health.health_changed.is_connected(_on_health_changed):
		_health.health_changed.connect(_on_health_changed)
	_on_health_changed(_health.hp if _health else 100.0, _health.max_hp if _health else 100.0)


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
		if _panel == DeviceSheet.NONE:
			_open(DeviceSheet.PACK)
		else:
			_close_panel()
		get_viewport().set_input_as_handled()
		return
	if InputManager.is_action_just_pressed(&"map_peek"):
		_open(DeviceSheet.MAP)
		get_viewport().set_input_as_handled()
		return
	if InputManager.is_action_just_pressed(&"device_cycle"):
		if _panel == DeviceSheet.NONE:
			_open(DeviceSheet.PACK)
		else:
			_cycle(1)
		get_viewport().set_input_as_handled()
		return
	if InputManager.is_action_just_pressed(&"ui_cancel"):
		if _panel != DeviceSheet.NONE:
			_close_panel()
			get_viewport().set_input_as_handled()
		return
	if InputManager.is_action_just_pressed(&"pause_menu"):
		DeviceSettings.present(self)
		get_viewport().set_input_as_handled()
		return
	if _panel != DeviceSheet.NONE and InputManager.is_action_just_pressed(&"ui_confirm"):
		## A while sheet open = acknowledge / soft refresh (no mouse click needed).
		_refresh()
		EventBus.sfx_play_requested.emit(&"ui_confirm", Vector3.ZERO)
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

	## Field Unit HP strip — always visible on adventure.
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 8)
	vbox.add_child(hp_row)
	_hp_label = Label.new()
	_hp_label.text = "HP"
	hp_row.add_child(_hp_label)
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(160, 14)
	_hp_bar.max_value = 100.0
	_hp_bar.value = 100.0
	_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(_hp_bar)

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
	_root.custom_minimum_size = Vector2(0, 280)
	vbox.add_child(_root)
	var body_margin := MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 12)
	body_margin.add_theme_constant_override("margin_right", 12)
	body_margin.add_theme_constant_override("margin_top", 10)
	body_margin.add_theme_constant_override("margin_bottom", 10)
	_root.add_child(body_margin)
	_map_host = VBoxContainer.new()
	_map_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_margin.add_child(_map_host)
	_sheet_map = RegionMiniMap.new()
	_sheet_map.name = "SheetMap"
	_sheet_map.custom_minimum_size = Vector2(0, 210)
	_sheet_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sheet_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sheet_map.show_labels = true
	_sheet_map.visible = false
	_map_host.add_child(_sheet_map)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = false
	_body.scroll_active = true
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.custom_minimum_size = Vector2(0, 80)
	_body.add_theme_font_size_override("normal_font_size", 16)
	_map_host.add_child(_body)

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

	## Always-on corner mini map (handheld glanceable).
	_mini_map = RegionMiniMap.new()
	_mini_map.name = "CornerMiniMap"
	_mini_map.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_mini_map.anchor_left = 1.0
	_mini_map.anchor_right = 1.0
	_mini_map.anchor_top = 0.0
	_mini_map.anchor_bottom = 0.0
	_mini_map.offset_left = -158.0
	_mini_map.offset_right = -14.0
	_mini_map.offset_top = 86.0
	_mini_map.offset_bottom = 230.0
	_mini_map.show_labels = false
	_mini_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mini_map)

	_apply_device_chrome(top)
	## Brand accent strip under top bar.
	var accent := ColorRect.new()
	accent.custom_minimum_size = Vector2(0, 4)
	accent.color = WorldPalette.UI_CYAN
	vbox.add_child(accent)
	vbox.move_child(accent, 1)


func _apply_device_chrome(top: PanelContainer) -> void:
	DFStyle.apply_panel(top, false)
	DFStyle.apply_sheet(_root)
	DFStyle.apply_label_ink(_title, DFStyle.FONT_TITLE)
	_title.text = "◆ FIELD UNIT"
	DFStyle.apply_label_accent(_bits, DFStyle.FONT_SHEET)
	DFStyle.apply_label_ink(_quest_line, DFStyle.FONT_BODY)
	DFStyle.apply_label_cyan(_companion_line, DFStyle.FONT_BODY)
	DFStyle.apply_label_accent(_notice_line, DFStyle.FONT_BODY)
	DFStyle.apply_label_ink(_hint, DFStyle.FONT_HINT)
	DFStyle.apply_label_cyan(_tab_label, DFStyle.FONT_SHEET)
	DFStyle.apply_rich_sheet(_body)
	DFStyle.apply_label_accent(_toast, DFStyle.FONT_SHEET)
	if _hp_label:
		DFStyle.apply_label_ink(_hp_label, DFStyle.FONT_HINT)
	if _hp_bar:
		DFStyle.apply_progress(_hp_bar, WorldPalette.UI_LIME)


func _open(panel: DeviceSheet) -> void:
	var was_open := _panel != DeviceSheet.NONE
	_panel = panel
	_root.visible = true
	_tab_label.visible = true
	if not was_open:
		UIManager.push_modal(&"adventure_device")
		DFStyle.slide_in(_root, 20.0, 0.2)
	EventBus.sfx_play_requested.emit(&"menu_beep", Vector3.ZERO)
	DeviceService.play_haptic(&"ui", 0.2)
	_refresh()


func _cycle(dir: int) -> void:
	var idx := PANEL_ORDER.find(_panel)
	if idx < 0:
		idx = 0
	idx = (idx + dir) % PANEL_ORDER.size()
	_open(PANEL_ORDER[idx])
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)


func _close_panel() -> void:
	if _panel == DeviceSheet.NONE:
		return
	_panel = DeviceSheet.NONE
	_root.visible = false
	_tab_label.visible = false
	if _sheet_map:
		_sheet_map.visible = false
	if _mini_map:
		_mini_map.visible = true
	if UIManager.has_open_modal():
		UIManager.pop_modal()
	EventBus.sfx_play_requested.emit(&"ui_cancel", Vector3.ZERO)


func _panel_title(p: DeviceSheet) -> String:
	match p:
		DeviceSheet.PACK:
			return "◆ PACK"
		DeviceSheet.MAP:
			return "◆ MAP"
		DeviceSheet.QUESTS:
			return "◆ QUESTS"
		DeviceSheet.LOG:
			return "◆ COLLECTION"
		DeviceSheet.INDEX:
			return "◆ INDEX"
		DeviceSheet.BITS:
			return "◆ BITS"
		_:
			return ""


func _refresh(_a = null) -> void:
	_refresh_chrome()
	_tab_label.text = "%s   (%s cycle · %s close)" % [
		_panel_title(_panel),
		InputManager.get_action_glyph(&"device_cycle"),
		InputManager.get_action_glyph(&"ui_cancel"),
	]
	var show_map := _panel == DeviceSheet.MAP
	if _sheet_map:
		_sheet_map.visible = show_map
		if show_map:
			_sheet_map.queue_redraw()
	if _mini_map:
		_mini_map.visible = not show_map
	match _panel:
		DeviceSheet.PACK:
			_body.text = DFFormat.pack_sheet()
		DeviceSheet.MAP:
			_body.text = DFFormat.map_blurb_sheet()
		DeviceSheet.QUESTS:
			_body.text = DFFormat.quest_sheet()
		DeviceSheet.LOG:
			_body.text = DFFormat.collection_sheet()
		DeviceSheet.INDEX:
			_body.text = DFFormat.creature_index_sheet()
		DeviceSheet.BITS:
			_body.text = DFFormat.bits_sheet()
		_:
			pass


func _refresh_chrome() -> void:
	_bits.text = "◆ %d Bits" % InventoryManager.get_bits()
	_quest_line.text = "Quest · " + QuestManager.get_quest_status_line().split("\n")[0]
	## Guidance hint — cyan beacon points to MAIN objective.
	if QuestManager.get_active_quest_ids().size() > 0 and _notice_line:
		var main_active := false
		for qid in QuestManager.get_active_quest_ids():
			var qd: QuestData = ResourceRegistry.get_quest(StringName(str(qid)))
			if qd and qd.quest_type == QuestData.QuestType.MAIN:
				main_active = true
				break
		if main_active and _notice_line.text.is_empty():
			_notice_line.text = "Follow the cyan ◆ marker"
	_companion_line.text = CreatureManager.get_adventure_status_line()
	var disc := CollectionManager.get_discovery_progress()
	var idx := CollectionManager.get_creature_index_progress()
	_companion_line.text += "  ·  Map %d/%d  ·  Index %d/%d" % [disc.x, disc.y, idx.x, idx.y]
	_companion_line.text += "  ·  %s / %s" % [
		WorldAtmosphere.phase_label(WorldAtmosphere.current_phase_index()),
		String(WorldAtmosphere.current_weather_id()).capitalize(),
	]
	if _companion and _companion.has_active_notice():
		_notice_line.visible = true
		_notice_line.text = _companion.get_notice_prompt()
	else:
		_notice_line.visible = false
	_hint.text = InputManager.get_control_legend() + "  ·  %s strike/companion · %s map · Select settings" % [
		InputManager.get_action_glyph(&"creature_action"),
		InputManager.get_action_glyph(&"map_peek"),
	]


func _on_health_changed(current: float, maximum: float) -> void:
	if _hp_bar:
		_hp_bar.max_value = maximum
		_hp_bar.value = current
	if _hp_label:
		_hp_label.text = "HP %d" % int(current)


func _on_player_damaged(_amount: float, _source: Node = null) -> void:
	if _hp_bar:
		DFStyle.pulse_modulate(_hp_bar, WorldPalette.UI_DANGER)


func _on_player_respawned(_pos: Vector3 = Vector3.ZERO) -> void:
	if _health:
		_on_health_changed(_health.hp, _health.max_hp)


func _on_creature_discovered(_id: StringName = &"", _rarity: int = 0) -> void:
	_refresh_chrome()
	if _panel == DeviceSheet.INDEX or _panel == DeviceSheet.LOG:
		_refresh()


func _on_phase_chrome(_phase: int = 0) -> void:
	_refresh_chrome()


func _on_weather_chrome(_weather: StringName = &"") -> void:
	_refresh_chrome()


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
	if _panel == DeviceSheet.BITS or _panel == DeviceSheet.PACK:
		_refresh()


func _on_world_pulse(_a = null) -> void:
	if _mini_map:
		_mini_map.queue_redraw()
	if _sheet_map:
		_sheet_map.queue_redraw()
	if _panel == DeviceSheet.MAP or _panel == DeviceSheet.LOG:
		_refresh()
