class_name DeviceBattle
extends CanvasLayer
## Simple handheld digi-pet battle — fast, button-only, NFC-ready stub.
## Not a full RPG combat system.

signal battle_finished(won: bool)

enum Phase { LINK, FIGHT, RESULT }

var _phase: Phase = Phase.LINK
var _player_hp: int = 100
var _enemy_hp: int = 100
var _enemy_name: String = "Wild Bit"
var _round: int = 0
var _busy: float = 0.0
var _result_text: String = ""
var _won: bool = false

var _title: Label
var _status: Label
var _hint: Label
var _player_bar: ProgressBar
var _enemy_bar: ProgressBar
var _player_sprite: PixelCreatureSprite
var _enemy_sprite: PixelCreatureSprite


static func present(parent: Node) -> DeviceBattle:
	var b := DeviceBattle.new()
	b.name = "DeviceBattle"
	parent.add_child(b)
	return b


func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIManager.push_modal(&"battle")
	_build()
	_begin_link()


func _exit_tree() -> void:
	if UIManager.get_top_modal() == &"battle":
		UIManager.pop_modal()


func _process(delta: float) -> void:
	if _busy > 0.0:
		_busy -= delta


func _input(_event: InputEvent) -> void:
	if _busy > 0.0:
		get_viewport().set_input_as_handled()
		return
	match _phase:
		Phase.LINK:
			if InputManager.is_action_just_pressed(&"ui_confirm") or InputManager.is_action_just_pressed(&"interact"):
				_start_fight()
				get_viewport().set_input_as_handled()
			elif InputManager.is_action_just_pressed(&"ui_cancel"):
				_close(false)
				get_viewport().set_input_as_handled()
		Phase.FIGHT:
			if InputManager.is_action_just_pressed(&"ui_confirm") or InputManager.is_action_just_pressed(&"interact"):
				_player_turn(&"attack")
				get_viewport().set_input_as_handled()
			elif InputManager.is_action_just_pressed(&"device_cycle"):
				_player_turn(&"special")
				get_viewport().set_input_as_handled()
			elif InputManager.is_action_just_pressed(&"ui_cancel"):
				_status.text = "You fled the link."
				_finish_battle(false)
				get_viewport().set_input_as_handled()
		Phase.RESULT:
			if (
				InputManager.is_action_just_pressed(&"ui_confirm")
				or InputManager.is_action_just_pressed(&"interact")
				or InputManager.is_action_just_pressed(&"ui_cancel")
			):
				_close(_won)
				get_viewport().set_input_as_handled()


func _begin_link() -> void:
	_phase = Phase.LINK
	_title.text = "DEVICE BATTLE"
	_status.text = DeviceService.begin_nfc_link()
	_hint.text = "A — connect   ·   B — cancel"
	EventBus.sfx_play_requested.emit(&"menu_beep", Vector3.ZERO)
	DeviceService.set_led(Color(0.35, 0.55, 0.95), &"pulse")


func _start_fight() -> void:
	_phase = Phase.FIGHT
	_player_hp = 100
	_enemy_hp = 90 + randi_range(0, 20)
	var foes := ["Rival Ember", "Stray Spark", "Foam Bit", "Park Scout"]
	_enemy_name = foes[randi() % foes.size()]
	_round = 0
	_refresh_bars()
	_title.text = "VS %s" % _enemy_name
	_status.text = "Linked! Fight!"
	_hint.text = "A attack  ·  X special  ·  B flee"
	_player_sprite.refresh_palette()
	_player_sprite.set_anim(PixelCreatureSprite.Anim.IDLE)
	_enemy_sprite.set_appearance(Color(0.55, 0.55, 0.65), Color(0.9, 0.4, 0.45), &"sparkbit")
	EventBus.sfx_play_requested.emit(&"battle_start", Vector3.ZERO)
	DeviceService.play_haptic(&"battle", 0.5)


func _player_turn(move: StringName) -> void:
	_busy = 0.85
	_round += 1
	var dmg := 14 + randi_range(0, 8)
	if move == &"special":
		dmg = 20 + randi_range(0, 10)
		_status.text = "%s used SPECIAL!" % CreatureManager.get_companion_nickname()
	else:
		_status.text = "%s attacked!" % CreatureManager.get_companion_nickname()
	_player_sprite.set_anim(PixelCreatureSprite.Anim.ATTACK)
	_enemy_sprite.set_anim(PixelCreatureSprite.Anim.HURT)
	_enemy_hp = maxi(0, _enemy_hp - dmg)
	_refresh_bars()
	EventBus.sfx_play_requested.emit(&"battle_hit", Vector3.ZERO)
	await get_tree().create_timer(0.55).timeout
	if _enemy_hp <= 0:
		_finish_battle(true)
		return
	## Enemy counter.
	_busy = 0.85
	var edmg := 10 + randi_range(0, 10)
	_enemy_sprite.set_anim(PixelCreatureSprite.Anim.ATTACK)
	_player_sprite.set_anim(PixelCreatureSprite.Anim.HURT)
	_player_hp = maxi(0, _player_hp - edmg)
	_status.text = "%s hit back (−%d)" % [_enemy_name, edmg]
	_refresh_bars()
	EventBus.sfx_play_requested.emit(&"battle_hit", Vector3.ZERO)
	await get_tree().create_timer(0.5).timeout
	_player_sprite.set_anim(PixelCreatureSprite.Anim.IDLE)
	_enemy_sprite.set_anim(PixelCreatureSprite.Anim.IDLE)
	_busy = 0.0
	if _player_hp <= 0:
		_finish_battle(false)


func _finish_battle(won: bool) -> void:
	_won = won
	_phase = Phase.RESULT
	_busy = 0.0
	if won:
		_player_sprite.set_anim(PixelCreatureSprite.Anim.HAPPY)
		_enemy_sprite.set_anim(PixelCreatureSprite.Anim.SAD)
		var xp := 12 + _round * 2
		var bits := 18 + _round * 3
		CreatureManager.grant_adventure_experience(xp)
		InventoryManager.add_bits(bits, true, "Device battle", "battle")
		CreatureManager.pet()
		_result_text = "WIN! +%d XP · +%d Bits" % [xp, bits]
		EventBus.sfx_play_requested.emit(&"battle_win", Vector3.ZERO)
		DeviceService.notify_event(&"quest_complete")
		CollectionManager.record_rare_find("Device battle victory", _enemy_name)
	else:
		_player_sprite.set_anim(PixelCreatureSprite.Anim.SAD)
		_result_text = "Loss… train harder, then rematch."
		EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
	_status.text = _result_text
	_hint.text = "A / B — return"
	_title.text = "RESULT"


func _close(won: bool) -> void:
	battle_finished.emit(won)
	if UIManager.get_top_modal() == &"battle":
		UIManager.pop_modal()
	queue_free()


func _refresh_bars() -> void:
	_player_bar.value = _player_hp
	_enemy_bar.value = _enemy_hp


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(WorldPalette.UI_NAVY.r, WorldPalette.UI_NAVY.g, WorldPalette.UI_NAVY.b, 0.96)
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

	var arena := HBoxContainer.new()
	arena.alignment = BoxContainer.ALIGNMENT_CENTER
	arena.add_theme_constant_override("separation", 48)
	arena.custom_minimum_size = Vector2(0, 120)
	v.add_child(arena)

	var left := VBoxContainer.new()
	arena.add_child(left)
	_player_bar = ProgressBar.new()
	_player_bar.max_value = 100
	_player_bar.value = 100
	_player_bar.custom_minimum_size = Vector2(120, 12)
	DFStyle.apply_progress(_player_bar, WorldPalette.UI_LIME)
	left.add_child(_player_bar)
	var pc := CenterContainer.new()
	pc.custom_minimum_size = Vector2(100, 90)
	left.add_child(pc)
	_player_sprite = PixelCreatureSprite.new()
	_player_sprite.scale = Vector2(3.2, 3.2)
	pc.add_child(_player_sprite)

	var right := VBoxContainer.new()
	arena.add_child(right)
	_enemy_bar = ProgressBar.new()
	_enemy_bar.max_value = 100
	_enemy_bar.value = 100
	_enemy_bar.custom_minimum_size = Vector2(120, 12)
	DFStyle.apply_progress(_enemy_bar, WorldPalette.UI_DANGER)
	right.add_child(_enemy_bar)
	var ec := CenterContainer.new()
	ec.custom_minimum_size = Vector2(100, 90)
	right.add_child(ec)
	_enemy_sprite = PixelCreatureSprite.new()
	_enemy_sprite.scale = Vector2(3.2, 3.2)
	_enemy_sprite.facing = -1
	ec.add_child(_enemy_sprite)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	DFStyle.apply_label_paper(_status, DFStyle.FONT_BODY)
	v.add_child(_status)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DFStyle.apply_label_paper(_hint, DFStyle.FONT_HINT)
	_hint.add_theme_color_override("font_color", WorldPalette.UI_GOLD)
	v.add_child(_hint)
