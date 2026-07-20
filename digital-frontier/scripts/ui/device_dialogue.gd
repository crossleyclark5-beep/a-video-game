class_name DeviceDialogue
extends CanvasLayer
## Handheld dialogue card — A continue · B close. Replaces toast-only NPC talk.

signal finished(npc_id: StringName)

var _open: bool = false
var _npc_id: StringName = &""
var _lines: PackedStringArray = PackedStringArray()
var _index: int = 0
var _root: PanelContainer
var _title: Label
var _body: RichTextLabel
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
	_open = true
	visible = true
	set_process_input(true)
	UIManager.push_modal(&"dialogue")
	_title.text = "◆ %s" % display_name.to_upper()
	_refresh_body()
	DFStyle.slide_in(_root, 14.0, 0.18)
	EventBus.sfx_play_requested.emit(&"menu_beep", Vector3.ZERO)
	EventBus.npc_dialogue_started.emit(_npc_id)


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	set_process_input(false)
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


func _refresh_body() -> void:
	var line := _lines[_index] if _index < _lines.size() else "…"
	_body.text = DFStyle.color_tag(WorldPalette.UI_SHEET_TEXT, line)
	_hint.text = "%s continue  ·  %s close  ·  %d/%d" % [
		InputManager.get_action_glyph(&"ui_confirm"),
		InputManager.get_action_glyph(&"ui_cancel"),
		_index + 1,
		_lines.size(),
	]


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 220)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)
	_root = PanelContainer.new()
	DFStyle.apply_sheet(_root)
	margin.add_child(_root)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_root.add_child(vbox)
	_title = Label.new()
	DFStyle.apply_label_cyan(_title, DFStyle.FONT_TITLE)
	vbox.add_child(_title)
	var accent := ColorRect.new()
	accent.custom_minimum_size = Vector2(0, 3)
	accent.color = WorldPalette.UI_ACCENT
	vbox.add_child(accent)
	_body = RichTextLabel.new()
	_body.fit_content = true
	_body.scroll_active = false
	_body.custom_minimum_size = Vector2(0, 72)
	DFStyle.apply_rich_sheet(_body)
	vbox.add_child(_body)
	_hint = Label.new()
	DFStyle.apply_label_paper(_hint, DFStyle.FONT_HINT)
	_hint.add_theme_color_override("font_color", WorldPalette.UI_MUTED)
	vbox.add_child(_hint)
