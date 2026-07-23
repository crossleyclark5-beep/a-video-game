class_name CombatHud
extends CanvasLayer
## Handheld battle chrome — D-pad choose · A confirm · B escape · Y ability · X item.


var _sheet: PanelContainer
var _title: Label
var _log: Label
var _ally_name: Label
var _enemy_name: Label
var _ally_bar: ProgressBar
var _enemy_bar: ProgressBar
var _ally_hp: Label
var _enemy_hp: Label
var _commands: HBoxContainer
var _hint: Label
var _command_buttons: Array[Label] = []


func _ready() -> void:
	layer = 48
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func open_battle(ally: CombatantState, enemy: CombatantState) -> void:
	visible = true
	_title.text = "◆ BATTLE"
	refresh(ally, enemy)
	DFStyle.slide_in(_sheet, 18.0, 0.2)


func close_battle() -> void:
	visible = false


func refresh(ally: CombatantState, enemy: CombatantState) -> void:
	if ally:
		_ally_name.text = "%s · %s" % [ally.display_name, CombatTypes.element_label(ally.element)]
		_ally_bar.max_value = ally.max_hp
		_tween_bar(_ally_bar, ally.hp)
		_ally_hp.text = "%d / %d" % [int(ally.hp), int(ally.max_hp)]
	if enemy:
		_enemy_name.text = "%s · %s" % [enemy.display_name, CombatTypes.element_label(enemy.element)]
		_enemy_bar.max_value = enemy.max_hp
		_tween_bar(_enemy_bar, enemy.hp)
		_enemy_hp.text = "%d / %d" % [int(enemy.hp), int(enemy.max_hp)]


func _tween_bar(bar: ProgressBar, target: float) -> void:
	if bar == null:
		return
	var tw := create_tween()
	tw.tween_property(bar, "value", target, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func set_phase_choose(index: int) -> void:
	_hint.text = "%s choose  ·  %s escape  ·  Y ability  ·  X item" % [
		InputManager.get_action_glyph(&"ui_confirm"),
		InputManager.get_action_glyph(&"ui_cancel"),
	]
	for i in _command_buttons.size():
		var lab := _command_buttons[i]
		if i == index:
			lab.add_theme_color_override("font_color", WorldPalette.UI_CYAN)
			lab.text = "▸ %s" % BattleDirector.COMMAND_LABELS[i]
		else:
			lab.add_theme_color_override("font_color", WorldPalette.UI_SHEET_TEXT)
			lab.text = "  %s" % BattleDirector.COMMAND_LABELS[i]


func flash_action(text: String) -> void:
	_log.text = text


func set_prompt(text: String) -> void:
	_log.text = text


func set_result(won: bool, summary: String) -> void:
	_title.text = "◆ VICTORY" if won else "◆ RESULT"
	_log.text = summary
	_hint.text = "%s continue" % InputManager.get_action_glyph(&"ui_confirm")


func _build() -> void:
	var anchor := MarginContainer.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor.add_theme_constant_override("margin_left", 20)
	anchor.add_theme_constant_override("margin_right", 20)
	anchor.add_theme_constant_override("margin_top", 0)
	anchor.add_theme_constant_override("margin_bottom", 14)
	add_child(anchor)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor.add_child(layout)
	layout.add_child(spacer)

	_sheet = PanelContainer.new()
	DFStyle.apply_sheet(_sheet)
	_sheet.size_flags_vertical = Control.SIZE_SHRINK_END
	layout.add_child(_sheet)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_sheet.add_child(vbox)

	_title = Label.new()
	DFStyle.apply_label_cyan(_title, DFStyle.FONT_TITLE)
	vbox.add_child(_title)

	var bars := HBoxContainer.new()
	bars.add_theme_constant_override("separation", 18)
	vbox.add_child(bars)

	var left := _make_fighter_column(true)
	bars.add_child(left)
	var right := _make_fighter_column(false)
	bars.add_child(right)

	_log = Label.new()
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log.custom_minimum_size = Vector2(0, 28)
	DFStyle.apply_label_ink(_log, DFStyle.FONT_BODY)
	vbox.add_child(_log)

	_commands = HBoxContainer.new()
	_commands.add_theme_constant_override("separation", 8)
	vbox.add_child(_commands)
	_command_buttons.clear()
	for label_text in BattleDirector.COMMAND_LABELS:
		var lab := Label.new()
		lab.text = "  %s" % label_text
		DFStyle.apply_label_paper(lab, DFStyle.FONT_HINT)
		_commands.add_child(lab)
		_command_buttons.append(lab)

	_hint = Label.new()
	DFStyle.apply_label_paper(_hint, DFStyle.FONT_HINT)
	_hint.add_theme_color_override("font_color", WorldPalette.UI_MUTED)
	vbox.add_child(_hint)


func _make_fighter_column(is_ally: bool) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_l := Label.new()
	if is_ally:
		DFStyle.apply_label_ink(name_l, DFStyle.FONT_BODY)
		_ally_name = name_l
	else:
		DFStyle.apply_label_accent(name_l, DFStyle.FONT_BODY)
		_enemy_name = name_l
	col.add_child(name_l)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 14)
	if is_ally:
		DFStyle.apply_progress(bar, WorldPalette.UI_LIME)
		_ally_bar = bar
	else:
		DFStyle.apply_progress(bar, WorldPalette.UI_DANGER)
		_enemy_bar = bar
	col.add_child(bar)
	var hp_l := Label.new()
	DFStyle.apply_label_paper(hp_l, DFStyle.FONT_HINT)
	if is_ally:
		_ally_hp = hp_l
	else:
		_enemy_hp = hp_l
	col.add_child(hp_l)
	return col
