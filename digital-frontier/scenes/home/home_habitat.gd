extends Control
## Digi-Pet Home — Field Unit LCD companion device (not Adventure, not a habitat room).
## Creature is the focus. Adventure is the gateway into the full world.

const HUD_SCENE := preload("res://scenes/home/ui/home_hud.tscn")

var _bezel: PanelContainer
var _lcd: PixelHabitatLcd
var _hud: CanvasLayer
var _transition: HomeAdventureTransition
var _phase_timer: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	InputManager.set_context(InputManager.Context.HOME)
	if not CreatureManager.has_chosen_partner():
		## Safety if Main skipped select (e.g. direct scene run).
		var sel := PartnerSelect.present(self)
		await sel.partner_chosen
	_build_device()
	_build_hud()
	_transition = HomeAdventureTransition.new()
	_transition.name = "AdventureTransition"
	add_child(_transition)
	QuestManager.ensure_starter_quest()
	EventBus.music_change_requested.emit(&"home_night")
	EventBus.sfx_play_requested.emit(&"menu_beep", Vector3.ZERO)
	DeviceService.pulse_led_for_mood(CreatureManager.get_mood_label())


func _unhandled_input(event: InputEvent) -> void:
	if UIManager.has_open_modal():
		return
	if event.is_action_pressed(&"go_adventure"):
		_on_adventure()


func _process(delta: float) -> void:
	_phase_timer += delta
	if _phase_timer >= 90.0 and _lcd:
		_phase_timer = 0.0
		_lcd.cycle_phase()
	if _hud and _lcd:
		_hud.set_time_label(_lcd.get_phase_label())


func _build_device() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.09, 0.1, 0.11)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 68)
	margin.add_theme_constant_override("margin_bottom", 200)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	_bezel = PanelContainer.new()
	_bezel.name = "DeviceBezel"
	margin.add_child(_bezel)
	var bezel_style := StyleBoxFlat.new()
	bezel_style.bg_color = Color(0.14, 0.15, 0.17)
	bezel_style.set_corner_radius_all(0)
	bezel_style.border_width_left = 8
	bezel_style.border_width_right = 8
	bezel_style.border_width_top = 8
	bezel_style.border_width_bottom = 8
	bezel_style.border_color = Color(0.22, 0.24, 0.26)
	bezel_style.content_margin_left = 10
	bezel_style.content_margin_right = 10
	bezel_style.content_margin_top = 10
	bezel_style.content_margin_bottom = 10
	_bezel.add_theme_stylebox_override("panel", bezel_style)

	var lcd_frame := PanelContainer.new()
	lcd_frame.name = "LcdFrame"
	_bezel.add_child(lcd_frame)
	var lcd_style := StyleBoxFlat.new()
	lcd_style.bg_color = Color(0.08, 0.12, 0.08)
	lcd_style.set_corner_radius_all(0)
	lcd_style.border_width_left = 4
	lcd_style.border_width_right = 4
	lcd_style.border_width_top = 4
	lcd_style.border_width_bottom = 4
	lcd_style.border_color = Color(0.25, 0.45, 0.3)
	lcd_style.content_margin_left = 4
	lcd_style.content_margin_right = 4
	lcd_style.content_margin_top = 4
	lcd_style.content_margin_bottom = 4
	lcd_frame.add_theme_stylebox_override("panel", lcd_style)

	_lcd = PixelHabitatLcd.new()
	_lcd.name = "PixelCompanionLcd"
	_lcd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lcd.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lcd.custom_minimum_size = Vector2(320, 240)
	lcd_frame.add_child(_lcd)

	var brand := Label.new()
	brand.text = "DIGITAL FRONTIER  ·  FIELD UNIT"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.set_anchors_preset(Control.PRESET_TOP_WIDE)
	brand.offset_top = 22
	brand.offset_bottom = 50
	brand.add_theme_font_size_override("font_size", 18)
	brand.add_theme_color_override("font_color", Color(0.55, 0.85, 0.65))
	brand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(brand)


func _build_hud() -> void:
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	_hud.adventure_pressed.connect(_on_adventure)
	_hud.care_requested.connect(_on_care_requested)
	_hud.shop_pressed.connect(_on_shop)
	_hud.collection_pressed.connect(_on_collection)
	if _hud.has_signal("battle_pressed"):
		_hud.battle_pressed.connect(_on_battle)


func _on_care_requested(action: StringName) -> void:
	var message := ""
	match action:
		&"feed":
			message = CreatureManager.feed()
		&"heal":
			message = CreatureManager.heal()
		&"rest":
			message = CreatureManager.rest()
		&"play":
			message = CreatureManager.play()
		&"train":
			message = CreatureManager.train()
		&"interact", &"pet":
			message = CreatureManager.interact()
		&"status":
			message = CreatureManager.get_detailed_status()
			if _hud:
				_hud.show_status_message(message)
			if _lcd:
				_lcd.play_care(&"status")
			EventBus.sfx_play_requested.emit(&"creature_status", Vector3.ZERO)
			return
	if _hud:
		_hud.show_status_message(message)
	if _lcd:
		_lcd.play_care(action)
	EventBus.sfx_play_requested.emit(StringName("creature_%s" % String(action)), Vector3.ZERO)
	DeviceService.pulse_led_for_mood(CreatureManager.get_mood_label())


func _on_adventure() -> void:
	if SceneManager.is_transitioning():
		return
	if UIManager.has_open_modal():
		return
	if _hud:
		_hud.show_status_message("Deploying Field Unit…")
	if _lcd:
		_lcd.play_transition_leave()
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
	SaveManager.request_autosave()
	await get_tree().create_timer(0.55).timeout
	if _transition:
		await _transition.play_and_wait()
	SceneManager.change_scene(String(GameConstants.SCENE_GAME_WORLD), true)


func _on_collection() -> void:
	if _hud and _hud.has_method("show_collection_journal"):
		_hud.call("show_collection_journal")
	elif _hud:
		_hud.show_status_message(CollectionManager.get_summary_line())
	EventBus.sfx_play_requested.emit(&"menu_beep", Vector3.ZERO)


func _on_shop() -> void:
	FieldUnitShop.present(self, ShopManager.SHOP_ID_HOME)
	if _hud:
		_hud.show_status_message("Shop — spend Bits from Adventure")


func _on_battle() -> void:
	DeviceBattle.present(self)
	if _hud:
		_hud.show_status_message("Device Battle — NFC link")
