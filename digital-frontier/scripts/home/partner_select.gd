class_name PartnerSelect
extends CanvasLayer
## First companion choice — classic digi-pet “this is my partner” moment.
## D-pad browse · A confirm · no touchscreen.

signal partner_chosen(species_id: StringName)

var _index: int = 0
var _options: Array[CreatureData] = []
var _title: Label
var _name_l: Label
var _blurb: Label
var _stats: Label
var _hint: Label
var _preview: PixelCreatureSprite
var _done: bool = false


static func present(parent: Node) -> PartnerSelect:
	var sel := PartnerSelect.new()
	sel.name = "PartnerSelect"
	parent.add_child(sel)
	return sel


func _ready() -> void:
	layer = 55
	process_mode = Node.PROCESS_MODE_ALWAYS
	_options = CreatureManager.get_starter_options()
	if _options.is_empty():
		## Fallback — should not happen with data present.
		CreatureManager.select_partner(CreatureManager.STARTER_CREATURE_ID)
		_finish(CreatureManager.STARTER_CREATURE_ID)
		return
	_build()
	_refresh()
	EventBus.sfx_play_requested.emit(&"menu_beep", Vector3.ZERO)


func _input(_event: InputEvent) -> void:
	if _done:
		return
	var ui := InputManager.get_ui_vector_just()
	if ui.x != 0:
		_index = (_index + ui.x) % _options.size()
		if _index < 0:
			_index += _options.size()
		_refresh()
		EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
		get_viewport().set_input_as_handled()
		return
	if InputManager.is_action_just_pressed(&"ui_confirm") or InputManager.is_action_just_pressed(&"interact"):
		_confirm()
		get_viewport().set_input_as_handled()


func _confirm() -> void:
	if _options.is_empty():
		return
	var data: CreatureData = _options[_index]
	CreatureManager.select_partner(data.id)
	DeviceService.notify_event(&"creature_care")
	EventBus.ui_notification_requested.emit("Partner bonded: %s" % data.display_name, 2.8)
	_finish(data.id)


func _finish(species_id: StringName) -> void:
	if _done:
		return
	_done = true
	partner_chosen.emit(species_id)
	queue_free()


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = WorldPalette.UI_NAVY.darkened(0.25)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 40
	panel.offset_right = -40
	panel.offset_top = 36
	panel.offset_bottom = -36
	DFStyle.apply_sheet(panel)
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	_title = Label.new()
	_title.text = "◆ CHOOSE YOUR PARTNER"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DFStyle.apply_label_cyan(_title, DFStyle.FONT_TITLE)
	v.add_child(_title)

	var tag := Label.new()
	tag.text = "This choice matters. Personality · Path · Strength"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DFStyle.apply_label_paper(tag, DFStyle.FONT_HINT)
	tag.add_theme_color_override("font_color", WorldPalette.UI_MUTED.lightened(0.2))
	v.add_child(tag)

	var mid := CenterContainer.new()
	mid.custom_minimum_size = Vector2(0, 140)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(mid)
	_preview = PixelCreatureSprite.new()
	_preview.name = "Preview"
	_preview.scale = Vector2(4.5, 4.5)
	mid.add_child(_preview)

	_name_l = Label.new()
	_name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DFStyle.apply_label_accent(_name_l, DFStyle.FONT_TITLE)
	v.add_child(_name_l)

	_blurb = Label.new()
	_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DFStyle.apply_label_paper(_blurb, DFStyle.FONT_BODY)
	v.add_child(_blurb)

	_stats = Label.new()
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DFStyle.apply_label_cyan(_stats, DFStyle.FONT_HINT)
	v.add_child(_stats)

	_hint = Label.new()
	_hint.text = "◀ ▶ browse   ·   A bond forever"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DFStyle.apply_label_paper(_hint, DFStyle.FONT_BODY)
	_hint.add_theme_color_override("font_color", WorldPalette.UI_GOLD)
	v.add_child(_hint)


func _refresh() -> void:
	if _options.is_empty():
		return
	var data: CreatureData = _options[_index]
	_name_l.text = data.display_name
	_blurb.text = data.description
	if not data.lore_blurb.is_empty():
		_blurb.text = data.lore_blurb
	var hp := int(data.base_stats.get("hp", 50))
	var atk := int(data.base_stats.get("attack", 8))
	var defense := int(data.base_stats.get("defense", 8))
	var spd := int(data.base_stats.get("speed", 10))
	var path := "—"
	if data.stage_display_names.size() >= 3:
		path = "%s → %s → %s" % [
			data.stage_display_names[0],
			data.stage_display_names[1],
			data.stage_display_names[2],
		]
	var play := int(data.default_personality.get("playful", 50))
	var brave := int(data.default_personality.get("brave", 50))
	var aff := int(data.default_personality.get("affectionate", 50))
	_stats.text = "HP %d  ATK %d  DEF %d  SPD %d\nPlayful %d · Brave %d · Affection %d\n%s" % [
		hp, atk, defense, spd, play, brave, aff, path,
	]
	if _preview:
		_preview.apply_preview(data)
		_preview.set_anim(PixelCreatureSprite.Anim.IDLE)
