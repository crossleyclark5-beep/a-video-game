extends Control
## Home Field Unit — 2D pixel digital companion device (not 3D).
## Creature care on the LCD; Adventure plays a pixel-gate transition into 2.5D.

const HUD_SCENE := preload("res://scenes/home/ui/home_hud.tscn")

var _bezel: PanelContainer
var _lcd: PixelHabitatLcd
var _hud: CanvasLayer
var _transition: HomeAdventureTransition
var _phase_timer: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	InputManager.set_context(InputManager.Context.HOME)
	_build_device()
	_build_hud()
	_transition = HomeAdventureTransition.new()
	_transition.name = "AdventureTransition"
	add_child(_transition)
	QuestManager.ensure_starter_quest()
	EventBus.music_change_requested.emit(&"home_night")
	EventBus.sfx_play_requested.emit(&"home_ambient", Vector3.ZERO)


func _unhandled_input(event: InputEvent) -> void:
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
	## Dark plastic handheld bezel filling the screen.
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.1, 0.11, 0.13)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 72)
	margin.add_theme_constant_override("margin_bottom", 210)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	_bezel = PanelContainer.new()
	_bezel.name = "DeviceBezel"
	margin.add_child(_bezel)
	var bezel_style := StyleBoxFlat.new()
	bezel_style.bg_color = Color(0.16, 0.17, 0.2)
	bezel_style.set_corner_radius_all(0)
	bezel_style.border_width_left = 6
	bezel_style.border_width_right = 6
	bezel_style.border_width_top = 6
	bezel_style.border_width_bottom = 6
	bezel_style.border_color = WorldPalette.UI_BORDER
	bezel_style.content_margin_left = 10
	bezel_style.content_margin_right = 10
	bezel_style.content_margin_top = 10
	bezel_style.content_margin_bottom = 10
	_bezel.add_theme_stylebox_override("panel", bezel_style)

	var lcd_frame := PanelContainer.new()
	lcd_frame.name = "LcdFrame"
	_bezel.add_child(lcd_frame)
	var lcd_style := StyleBoxFlat.new()
	lcd_style.bg_color = Color(0.05, 0.06, 0.07)
	lcd_style.set_corner_radius_all(0)
	lcd_style.border_width_left = 3
	lcd_style.border_width_right = 3
	lcd_style.border_width_top = 3
	lcd_style.border_width_bottom = 3
	lcd_style.border_color = WorldPalette.UI_ACCENT.darkened(0.35)
	lcd_style.content_margin_left = 4
	lcd_style.content_margin_right = 4
	lcd_style.content_margin_top = 4
	lcd_style.content_margin_bottom = 4
	lcd_frame.add_theme_stylebox_override("panel", lcd_style)

	_lcd = PixelHabitatLcd.new()
	_lcd.name = "PixelHabitatLcd"
	_lcd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lcd.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lcd.custom_minimum_size = Vector2(320, 240)
	lcd_frame.add_child(_lcd)

	## Brand plate above LCD (outside margin — draw as label on bg).
	var brand := Label.new()
	brand.text = "FIELD UNIT  ·  COMPANION OS"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.set_anchors_preset(Control.PRESET_TOP_WIDE)
	brand.offset_top = 28
	brand.offset_bottom = 56
	brand.add_theme_font_size_override("font_size", 18)
	brand.add_theme_color_override("font_color", WorldPalette.UI_PAPER.darkened(0.15))
	brand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(brand)


func _build_hud() -> void:
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	_hud.adventure_pressed.connect(_on_adventure)
	_hud.care_requested.connect(_on_care_requested)
	_hud.shop_pressed.connect(_on_shop)
	_hud.collection_pressed.connect(_on_collection)


func _on_care_requested(action: StringName) -> void:
	var message := ""
	match action:
		&"feed":
			message = CreatureManager.feed()
		&"rest":
			message = CreatureManager.rest()
		&"play":
			message = CreatureManager.play()
		&"train":
			message = CreatureManager.train()
		&"pet":
			message = CreatureManager.pet()
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


func _on_adventure() -> void:
	if SceneManager.is_transitioning():
		return
	## Creature leaves the LCD, then pixel-gate into 2.5D adventure.
	if _lcd:
		_lcd.play_transition_leave()
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
	await get_tree().create_timer(0.55).timeout
	if _transition:
		await _transition.play_and_wait()
	SceneManager.change_scene(String(GameConstants.SCENE_GAME_WORLD), true)


func _on_collection() -> void:
	if _hud and _hud.has_method("show_collection_journal"):
		_hud.call("show_collection_journal")
	elif _hud:
		_hud.show_status_message(CollectionManager.get_summary_line())
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)


func _on_shop() -> void:
	FieldUnitShop.present(self, ShopManager.SHOP_ID_HOME)
	if _hud:
		_hud.show_status_message("Shop open — L/R category · A buy · X pack · B close")
