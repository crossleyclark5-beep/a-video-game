class_name ProfileSelect
extends CanvasLayer
## Field Unit profile gate — choose / create / delete local users.
## Pad-only: ↑↓ browse · ←→ avatar/name · A confirm · B cancel/back · X delete.


signal profile_ready(profile_id: String)

enum Mode { BROWSE, CREATE, CONFIRM_DELETE }

var _mode: int = Mode.BROWSE
var _index: int = 0
var _profiles: Array[Dictionary] = []
var _done: bool = false

## Create wizard
var _create_name: String = "Alex"
var _create_avatar: int = 0
var _create_focus: int = 0  ## 0=name preset, 1=avatar, 2=confirm
var _name_preset_i: int = 0

## Delete confirm
var _delete_target: String = ""

var _title: Label
var _body: RichTextLabel
var _hint: Label
var _avatar_swatch: ColorRect
var _avatar_glyph: Label


static func present(parent: Node) -> ProfileSelect:
	var existing := parent.get_node_or_null("ProfileSelect") as ProfileSelect
	if existing:
		return existing
	var s := ProfileSelect.new()
	s.name = "ProfileSelect"
	parent.add_child(s)
	return s


func _ready() -> void:
	layer = 58
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_reload_list()
	_refresh()
	EventBus.sfx_play_requested.emit(&"menu_beep", Vector3.ZERO)
	DeviceService.set_led(WorldPalette.UI_CYAN, &"pulse")


func _input(_event: InputEvent) -> void:
	if _done:
		return
	match _mode:
		Mode.BROWSE:
			_input_browse()
		Mode.CREATE:
			_input_create()
		Mode.CONFIRM_DELETE:
			_input_delete()


func _input_browse() -> void:
	var rows := _browse_row_count()
	var ui := InputManager.get_ui_vector_just()
	if ui.y != 0 and rows > 0:
		_index = (_index + int(ui.y)) % rows
		if _index < 0:
			_index += rows
		_refresh()
		EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
		get_viewport().set_input_as_handled()
		return
	if InputManager.is_action_just_pressed(&"ui_confirm") or InputManager.is_action_just_pressed(&"interact"):
		_activate_browse()
		get_viewport().set_input_as_handled()
		return
	if InputManager.is_action_just_pressed(&"device_menu"):
		## Start — delete selected profile (with confirmation).
		if _index < _profiles.size():
			_delete_target = str(_profiles[_index].get("id", ""))
			_mode = Mode.CONFIRM_DELETE
			_refresh()
			EventBus.sfx_play_requested.emit(&"ui_cancel", Vector3.ZERO)
			DeviceService.play_haptic(&"warning", 0.35)
		get_viewport().set_input_as_handled()


func _input_create() -> void:
	var ui := InputManager.get_ui_vector_just()
	if ui.y != 0:
		_create_focus = (_create_focus + int(ui.y)) % 3
		if _create_focus < 0:
			_create_focus += 3
		_refresh()
		EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
		get_viewport().set_input_as_handled()
		return
	if ui.x != 0:
		match _create_focus:
			0:
				_name_preset_i = (_name_preset_i + int(ui.x)) % ProfileCatalog.NAME_PRESETS.size()
				if _name_preset_i < 0:
					_name_preset_i += ProfileCatalog.NAME_PRESETS.size()
				_create_name = ProfileCatalog.NAME_PRESETS[_name_preset_i]
			1:
				_create_avatar = (_create_avatar + int(ui.x)) % ProfileCatalog.AVATARS.size()
				if _create_avatar < 0:
					_create_avatar += ProfileCatalog.AVATARS.size()
		_refresh()
		EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
		get_viewport().set_input_as_handled()
		return
	if InputManager.is_action_just_pressed(&"ui_confirm") or InputManager.is_action_just_pressed(&"interact"):
		if _create_focus == 2:
			_commit_create()
		else:
			_create_focus = 2
			_refresh()
		get_viewport().set_input_as_handled()
		return
	if InputManager.is_action_just_pressed(&"ui_cancel"):
		_mode = Mode.BROWSE
		_reload_list()
		_refresh()
		EventBus.sfx_play_requested.emit(&"ui_cancel", Vector3.ZERO)
		get_viewport().set_input_as_handled()


func _input_delete() -> void:
	if InputManager.is_action_just_pressed(&"ui_confirm") or InputManager.is_action_just_pressed(&"interact"):
		if _delete_target != "":
			SaveManager.delete_profile(_delete_target)
			EventBus.ui_notification_requested.emit("Profile erased", 1.8)
			DeviceService.play_haptic(&"warning", 0.5)
		_delete_target = ""
		_mode = Mode.BROWSE
		_reload_list()
		_index = 0
		_refresh()
		get_viewport().set_input_as_handled()
		return
	if InputManager.is_action_just_pressed(&"ui_cancel"):
		_delete_target = ""
		_mode = Mode.BROWSE
		_refresh()
		EventBus.sfx_play_requested.emit(&"ui_cancel", Vector3.ZERO)
		get_viewport().set_input_as_handled()


func _browse_row_count() -> int:
	var n := _profiles.size()
	if SaveManager.can_create_profile():
		n += 1
	return maxi(n, 1)


func _activate_browse() -> void:
	if _profiles.is_empty() and not SaveManager.can_create_profile():
		return
	if _index < _profiles.size():
		_select_existing(str(_profiles[_index].get("id", "")))
	elif SaveManager.can_create_profile():
		_mode = Mode.CREATE
		_create_focus = 0
		_name_preset_i = 0
		_create_name = ProfileCatalog.NAME_PRESETS[0]
		_create_avatar = mini(_profiles.size(), ProfileCatalog.AVATARS.size() - 1)
		_refresh()
		EventBus.sfx_play_requested.emit(&"menu_beep", Vector3.ZERO)


func _select_existing(profile_id: String) -> void:
	if profile_id.is_empty():
		return
	if not SaveManager.select_profile(profile_id):
		EventBus.ui_notification_requested.emit("Could not load profile", 2.0)
		return
	_finish(profile_id)


func _commit_create() -> void:
	if not SaveManager.can_create_profile():
		EventBus.ui_notification_requested.emit("Profile slots full (max %d)" % ProfileCatalog.MAX_PROFILES, 2.2)
		return
	var avatar_id: StringName = ProfileCatalog.AVATARS[_create_avatar]["id"]
	var pid := SaveManager.create_profile(_create_name, avatar_id)
	if pid.is_empty():
		EventBus.ui_notification_requested.emit("Create failed", 1.8)
		return
	if not SaveManager.select_profile(pid):
		EventBus.ui_notification_requested.emit("Could not open new profile", 2.0)
		return
	EventBus.ui_notification_requested.emit("Welcome, %s" % _create_name, 2.0)
	_finish(pid)


func _finish(profile_id: String) -> void:
	if _done:
		return
	_done = true
	EventBus.sfx_play_requested.emit(&"ui_confirm", Vector3.ZERO)
	profile_ready.emit(profile_id)
	queue_free()


func _reload_list() -> void:
	_profiles = SaveManager.list_profiles()
	if _index >= _browse_row_count():
		_index = maxi(_browse_row_count() - 1, 0)


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = WorldPalette.UI_NAVY.darkened(0.3)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 48
	panel.offset_right = -48
	panel.offset_top = 40
	panel.offset_bottom = -40
	DFStyle.apply_sheet(panel)
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DFStyle.apply_label_cyan(_title, DFStyle.FONT_TITLE)
	v.add_child(_title)

	var tag := Label.new()
	tag.text = "FIELD UNIT  ·  LOCAL PROFILES  ·  OFFLINE"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DFStyle.apply_label_paper(tag, DFStyle.FONT_HINT)
	tag.add_theme_color_override("font_color", WorldPalette.UI_MUTED)
	v.add_child(tag)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(row)

	_avatar_swatch = ColorRect.new()
	_avatar_swatch.custom_minimum_size = Vector2(88, 88)
	_avatar_swatch.color = WorldPalette.UI_INK
	row.add_child(_avatar_swatch)
	_avatar_glyph = Label.new()
	_avatar_glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	_avatar_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_avatar_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_avatar_glyph.add_theme_font_size_override("font_size", 40)
	_avatar_glyph.add_theme_color_override("font_color", WorldPalette.UI_PAPER)
	_avatar_swatch.add_child(_avatar_glyph)

	_body = RichTextLabel.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.bbcode_enabled = true
	_body.fit_content = false
	_body.scroll_active = true
	DFStyle.apply_rich_sheet(_body)
	row.add_child(_body)

	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	DFStyle.apply_label_paper(_hint, DFStyle.FONT_HINT)
	_hint.add_theme_color_override("font_color", WorldPalette.UI_MUTED)
	v.add_child(_hint)


func _refresh() -> void:
	match _mode:
		Mode.BROWSE:
			_refresh_browse()
		Mode.CREATE:
			_refresh_create()
		Mode.CONFIRM_DELETE:
			_refresh_delete()


func _refresh_browse() -> void:
	_title.text = "◆ WHO'S PLAYING?"
	var lines: PackedStringArray = PackedStringArray()
	if _profiles.is_empty():
		lines.append(DFStyle.color_tag(WorldPalette.UI_GOLD, "No profiles yet — create your first adventurer."))
		lines.append("")
	for i in _profiles.size():
		var p: Dictionary = _profiles[i]
		var selected := i == _index
		var name_s := str(p.get("display_name", "Traveler"))
		var sum: Dictionary = p.get("summary", {})
		var partner := str(sum.get(&"partner_nickname", sum.get("partner_nickname", "")))
		var species := str(sum.get(&"partner_species", sum.get("partner_species", "")))
		var lvl := int(sum.get(&"partner_level", sum.get("partner_level", 0)))
		var pct := int(sum.get(&"completion_pct", sum.get("completion_pct", 0)))
		var play := ProfileCatalog.format_playtime(float(sum.get(&"playtime_seconds", sum.get("playtime_seconds", 0.0))))
		var partner_line := "No partner yet"
		if partner != "":
			partner_line = "%s  ·  Lv%d" % [partner, maxi(lvl, 1)]
			if species != "":
				partner_line += "  (%s)" % species.capitalize()
		var blurb := "%s\nPlaytime %s  ·  %d%% complete" % [partner_line, play, pct]
		lines.append(DFStyle.card_bb(name_s, blurb, selected, "▶" if selected else ""))
	if SaveManager.can_create_profile():
		var create_i := _profiles.size()
		lines.append(DFStyle.card_bb(
			"+ New Profile",
			"Start a fresh adventure  ·  %d/%d slots" % [SaveManager.get_profile_count(), ProfileCatalog.MAX_PROFILES],
			_index == create_i,
			"▶" if _index == create_i else "",
		))
	elif _profiles.is_empty():
		lines.append(DFStyle.color_tag(WorldPalette.UI_ACCENT, "Profile slots full."))
	_body.text = "\n".join(lines)

	## Avatar preview for focused profile.
	if _index < _profiles.size():
		var av := StringName(str(_profiles[_index].get("avatar_id", "ember")))
		_avatar_swatch.color = ProfileCatalog.avatar_color(av)
		_avatar_glyph.text = ProfileCatalog.avatar_glyph(av)
	else:
		_avatar_swatch.color = WorldPalette.UI_INK
		_avatar_glyph.text = "+"

	_hint.text = "↑↓ select  ·  %s continue  ·  %s erase" % [
		InputManager.get_action_glyph(&"ui_confirm"),
		InputManager.get_action_glyph(&"device_menu"),
	]


func _refresh_create() -> void:
	_title.text = "◆ NEW PROFILE"
	var av: Dictionary = ProfileCatalog.AVATARS[_create_avatar]
	_avatar_swatch.color = av["color"]
	_avatar_glyph.text = str(av["glyph"])
	var lines: PackedStringArray = PackedStringArray()
	lines.append(DFStyle.card_bb(
		"Name  %s" % _create_name,
		"← → cycle presets",
		_create_focus == 0,
		"▶" if _create_focus == 0 else "",
	))
	lines.append(DFStyle.card_bb(
		"Avatar  %s" % str(av["label"]),
		"← → choose icon",
		_create_focus == 1,
		"▶" if _create_focus == 1 else "",
	))
	lines.append(DFStyle.card_bb(
		"Create & Play",
		"Opens a blank adventure for %s" % _create_name,
		_create_focus == 2,
		"▶" if _create_focus == 2 else "",
	))
	_body.text = "\n".join(lines)
	_hint.text = "↑↓ field  ·  ←→ change  ·  %s confirm  ·  %s back" % [
		InputManager.get_action_glyph(&"ui_confirm"),
		InputManager.get_action_glyph(&"ui_cancel"),
	]


func _refresh_delete() -> void:
	_title.text = "◆ ERASE PROFILE?"
	var rec := SaveManager.get_profile(_delete_target)
	var name_s := str(rec.get("display_name", "Traveler"))
	var av := StringName(str(rec.get("avatar_id", "ember")))
	_avatar_swatch.color = ProfileCatalog.avatar_color(av)
	_avatar_glyph.text = ProfileCatalog.avatar_glyph(av)
	var lines: PackedStringArray = PackedStringArray()
	lines.append(DFStyle.color_tag(WorldPalette.UI_ACCENT, "This cannot be undone."))
	lines.append("")
	lines.append("Delete [b]%s[/b] and all adventure data?" % name_s)
	lines.append("")
	lines.append(DFStyle.color_tag(WorldPalette.UI_GOLD, "A — Erase forever"))
	lines.append(DFStyle.color_tag(WorldPalette.UI_MUTED, "B — Keep profile"))
	_body.text = "\n".join(lines)
	_hint.text = "%s confirm erase  ·  %s cancel" % [
		InputManager.get_action_glyph(&"ui_confirm"),
		InputManager.get_action_glyph(&"ui_cancel"),
	]
