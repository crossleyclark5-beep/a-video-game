class_name DeviceDialogue
extends CanvasLayer
## Handheld dialogue card — A continue/confirm · B close · D-pad choices.
## Role portrait badge shows NPC category without needing textures yet.

signal finished(npc_id: StringName)
signal choice_selected(npc_id: StringName, choice_index: int)

var _open: bool = false
var _npc_id: StringName = &""
var _lines: PackedStringArray = PackedStringArray()
var _index: int = 0
var _choices: PackedStringArray = PackedStringArray()
var _choice_index: int = 0
var _choice_mode: bool = false
var _root: PanelContainer
var _title: Label
var _role_badge: Label
var _portrait: ColorRect
var _portrait_glyph: Label
var _body: RichTextLabel
var _choice_box: VBoxContainer
var _choice_labels: Array[Label] = []
var _hint: Label


static func present(parent: Node, npc_id: StringName, display_name: String, lines: PackedStringArray) -> DeviceDialogue:
	if lines.is_empty():
		lines = PackedStringArray(["…"])
	var existing := parent.get_node_or_null("DeviceDialogue") as DeviceDialogue
	if existing:
		existing.open(npc_id, display_name, lines)
		return existing
	var d := DeviceDialogue.new()
	d.name = "DeviceDialogue"
	parent.add_child(d)
	d.open(npc_id, display_name, lines)
	return d


static func present_choice(
	parent: Node,
	npc_id: StringName,
	display_name: String,
	prompt: String,
	choices: PackedStringArray,
) -> DeviceDialogue:
	var lines := PackedStringArray([prompt])
	var d := present(parent, npc_id, display_name, lines)
	d.set_choices(choices)
	return d


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	set_process_input(false)


func open(npc_id: StringName, display_name: String, lines: PackedStringArray) -> void:
	_npc_id = npc_id
	_lines = lines
	_index = 0
	_choice_mode = false
	_choices = PackedStringArray()
	_choice_index = 0
	_open = true
	visible = true
	set_process_input(true)
	UIManager.push_modal(&"dialogue")
	_apply_identity(npc_id, display_name)
	_choice_box.visible = false
	_refresh_body()
	DFStyle.slide_in(_root, 14.0, 0.18)
	EventBus.sfx_play_requested.emit(&"menu_beep", Vector3.ZERO)
	EventBus.npc_dialogue_started.emit(_npc_id)


func set_choices(choices: PackedStringArray) -> void:
	_choices = choices
	_choice_mode = not choices.is_empty()
	_choice_index = 0
	_rebuild_choices()
	_refresh_choice_highlight()
	_choice_box.visible = _choice_mode
	_hint.text = "%s confirm  ·  D-pad select  ·  %s close" % [
		InputManager.get_action_glyph(&"ui_confirm"),
		InputManager.get_action_glyph(&"ui_cancel"),
	]


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	set_process_input(false)
	if UIManager.get_top_modal() == &"dialogue":
		UIManager.pop_modal()
	EventBus.npc_dialogue_ended.emit(_npc_id)
	finished.emit(_npc_id)
	EventBus.sfx_play_requested.emit(&"ui_cancel", Vector3.ZERO)


func _input(_event: InputEvent) -> void:
	if not _open:
		return
	if InputManager.is_action_just_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	if _choice_mode:
		var ui := InputManager.get_ui_vector_just()
		if ui.y != 0:
			_choice_index = posmod(_choice_index + int(sign(ui.y)), maxi(_choices.size(), 1))
			_refresh_choice_highlight()
			EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
			get_viewport().set_input_as_handled()
			return
		if InputManager.is_action_just_pressed(&"ui_confirm") or InputManager.is_action_just_pressed(&"interact"):
			choice_selected.emit(_npc_id, _choice_index)
			EventBus.sfx_play_requested.emit(&"ui_confirm", Vector3.ZERO)
			close()
			get_viewport().set_input_as_handled()
			return
	if InputManager.is_action_just_pressed(&"ui_confirm") or InputManager.is_action_just_pressed(&"interact"):
		_advance()
		get_viewport().set_input_as_handled()


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		close()
		return
	_refresh_body()
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)


func _apply_identity(npc_id: StringName, display_name: String) -> void:
	var role := NpcCatalog.Role.STORY if npc_id == &"story" else NPCManager.get_role(npc_id)
	var col := NpcCatalog.role_color(role)
	_portrait.color = col
	_portrait_glyph.text = NpcCatalog.role_glyph(role)
	_role_badge.text = NpcCatalog.role_label(role)
	_role_badge.add_theme_color_override("font_color", col)
	_title.text = "◆ %s" % display_name.to_upper()


func _refresh_body() -> void:
	var line := _lines[_index] if _index < _lines.size() else "…"
	_body.text = DFStyle.color_tag(WorldPalette.UI_SHEET_TEXT, line)
	if not _choice_mode:
		_hint.text = "%s continue  ·  %s close  ·  %d/%d" % [
			InputManager.get_action_glyph(&"ui_confirm"),
			InputManager.get_action_glyph(&"ui_cancel"),
			_index + 1,
			_lines.size(),
		]


func _rebuild_choices() -> void:
	for c in _choice_labels:
		c.queue_free()
	_choice_labels.clear()
	for i in _choices.size():
		var lab := Label.new()
		lab.text = "  %s" % _choices[i]
		DFStyle.apply_label_paper(lab, DFStyle.FONT_BODY)
		_choice_box.add_child(lab)
		_choice_labels.append(lab)


func _refresh_choice_highlight() -> void:
	for i in _choice_labels.size():
		var lab := _choice_labels[i]
		if i == _choice_index:
			lab.add_theme_color_override("font_color", WorldPalette.UI_CYAN)
			lab.text = "▸ %s" % _choices[i]
		else:
			lab.add_theme_color_override("font_color", WorldPalette.UI_SHEET_TEXT)
			lab.text = "  %s" % _choices[i]


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_child(layout)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)

	_root = PanelContainer.new()
	DFStyle.apply_sheet(_root)
	_root.size_flags_vertical = Control.SIZE_SHRINK_END
	layout.add_child(_root)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_root.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)

	var portrait_wrap := Control.new()
	portrait_wrap.custom_minimum_size = Vector2(44, 44)
	header.add_child(portrait_wrap)
	_portrait = ColorRect.new()
	_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait.color = WorldPalette.UI_CYAN
	portrait_wrap.add_child(_portrait)
	_portrait_glyph = Label.new()
	_portrait_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	DFStyle.apply_label_ink(_portrait_glyph, DFStyle.FONT_TITLE)
	_portrait_glyph.add_theme_color_override("font_color", Color(0.08, 0.1, 0.14))
	portrait_wrap.add_child(_portrait_glyph)

	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	_title = Label.new()
	DFStyle.apply_label_cyan(_title, DFStyle.FONT_TITLE)
	titles.add_child(_title)
	_role_badge = Label.new()
	DFStyle.apply_label_paper(_role_badge, DFStyle.FONT_HINT)
	titles.add_child(_role_badge)

	var accent := ColorRect.new()
	accent.custom_minimum_size = Vector2(0, 3)
	accent.color = WorldPalette.UI_ACCENT
	vbox.add_child(accent)

	_body = RichTextLabel.new()
	_body.fit_content = true
	_body.scroll_active = false
	_body.custom_minimum_size = Vector2(0, 56)
	DFStyle.apply_rich_sheet(_body)
	vbox.add_child(_body)

	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 4)
	_choice_box.visible = false
	vbox.add_child(_choice_box)

	_hint = Label.new()
	DFStyle.apply_label_paper(_hint, DFStyle.FONT_HINT)
	_hint.add_theme_color_override("font_color", WorldPalette.UI_MUTED)
	vbox.add_child(_hint)
