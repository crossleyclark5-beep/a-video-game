class_name PixelHabitatLcd
extends Control
## Digi-pet LCD — creature-first screen. No room, house, or habitat furniture.
## Logical 160×120 nearest-scaled. Late-90s handheld companion aesthetic.

signal station_activated(station_id: StringName, care_action: StringName)

const LCD_W := 160
const LCD_H := 120

enum Phase { DAY, DUSK, NIGHT }

var phase: Phase = Phase.NIGHT
var _creature: PixelCreatureSprite
var _time: float = 0.0
var _care_lock: float = 0.0
var _bubble_text: String = ""
var _bubble_timer: float = 0.0
var _leave_x: float = 80.0
var _leaving: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_creature = PixelCreatureSprite.new()
	_creature.name = "PixelCreature"
	add_child(_creature)
	if not EventBus.companion_state_changed.is_connected(_on_companion_changed):
		EventBus.companion_state_changed.connect(_on_companion_changed)
	_on_companion_changed()
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _bubble_timer > 0.0:
		_bubble_timer -= delta
	if _care_lock > 0.0:
		_care_lock -= delta
		if _care_lock <= 0.0 and _creature.anim in [
			PixelCreatureSprite.Anim.EAT,
			PixelCreatureSprite.Anim.HAPPY,
			PixelCreatureSprite.Anim.SLEEP,
			PixelCreatureSprite.Anim.HURT,
			PixelCreatureSprite.Anim.ATTACK,
		]:
			if _creature.anim == PixelCreatureSprite.Anim.SLEEP and CreatureManager.get_energy() < 45.0:
				pass
			else:
				_creature.set_anim(PixelCreatureSprite.Anim.IDLE)
	elif not _leaving:
		_tick_idle(delta)

	var scale_v := _lcd_scale()
	var origin := _lcd_origin()
	var sprite_scale := scale_v / float(PixelCreatureSprite.SPRITE_SIZE) * 42.0
	_creature.scale = Vector2(sprite_scale, sprite_scale)
	var cx := origin.x + (float(LCD_W) * 0.5) * scale_v
	var cy := origin.y + (float(LCD_H) * 0.58) * scale_v
	if _leaving:
		_leave_x += 55.0 * delta
		cx = origin.x + _leave_x * scale_v
	_creature.position = Vector2(cx, cy + sin(_time * 2.2) * (1.5 if _creature.anim == PixelCreatureSprite.Anim.IDLE else 0.0))
	queue_redraw()


func get_phase_label() -> String:
	match phase:
		Phase.DAY:
			return "DAY"
		Phase.DUSK:
			return "DUSK"
		_:
			return "NIGHT"


func cycle_phase() -> void:
	phase = ((int(phase) + 1) % 3) as Phase
	queue_redraw()


func play_care(action: StringName) -> void:
	_leaving = false
	_creature.play_care(action)
	_care_lock = 2.4 if action != &"rest" and action != &"heal" else 3.2
	_show_bubble(_care_bubble(action))
	station_activated.emit(&"lcd", action)


func play_battle_anim(kind: StringName) -> void:
	match kind:
		&"attack":
			_creature.set_anim(PixelCreatureSprite.Anim.ATTACK)
		&"hurt":
			_creature.set_anim(PixelCreatureSprite.Anim.HURT)
		&"win":
			_creature.set_anim(PixelCreatureSprite.Anim.HAPPY)
		_:
			_creature.set_anim(PixelCreatureSprite.Anim.IDLE)
	_care_lock = 1.2


func play_transition_leave() -> void:
	_leaving = true
	_leave_x = float(LCD_W) * 0.5
	_creature.set_anim(PixelCreatureSprite.Anim.WALK)
	_creature.facing = 1
	_care_lock = 99.0
	_show_bubble("GO!")


func get_creature_screen_pos() -> Vector2:
	return _creature.global_position if _creature else global_position


func _tick_idle(_delta: float) -> void:
	var mood := CreatureManager.get_mood_label().to_lower()
	if CreatureManager.get_energy() < 25.0:
		_creature.set_anim(PixelCreatureSprite.Anim.SLEEP)
	elif CreatureManager.get_hunger() < 30.0 or "sad" in mood or "lonely" in mood:
		_creature.set_anim(PixelCreatureSprite.Anim.SAD)
	elif _creature.anim != PixelCreatureSprite.Anim.WALK:
		_creature.set_anim(PixelCreatureSprite.Anim.IDLE)


func _on_companion_changed(_a = null) -> void:
	if _creature:
		_creature.refresh_palette()
	queue_redraw()


func _care_bubble(action: StringName) -> String:
	match action:
		&"feed":
			return "YUM!"
		&"rest":
			return "ZZZ"
		&"play", &"interact", &"pet":
			return "<3"
		&"train":
			return "HUP!"
		&"heal":
			return "OK!"
		_:
			return "..."


func _show_bubble(text: String) -> void:
	_bubble_text = text
	_bubble_timer = 1.6


func _lcd_scale() -> float:
	return minf(size.x / float(LCD_W), size.y / float(LCD_H))


func _lcd_origin() -> Vector2:
	var s := _lcd_scale()
	var w := float(LCD_W) * s
	var h := float(LCD_H) * s
	return Vector2((size.x - w) * 0.5, (size.y - h) * 0.5)


func _draw() -> void:
	var s := _lcd_scale()
	var origin := _lcd_origin()
	var lcd_rect := Rect2(origin, Vector2(LCD_W, LCD_H) * s)
	## Classic green-glass LCD plate — limited palette.
	draw_rect(lcd_rect, _lcd_bg())
	## Soft scanlines for device feel.
	for y in range(0, LCD_H, 3):
		draw_rect(Rect2(origin + Vector2(0, y) * s, Vector2(LCD_W, 1) * s), Color(0, 0, 0, 0.08))
	## Ground line only — no furniture / room.
	var gy := origin.y + 88.0 * s
	draw_line(Vector2(origin.x + 16 * s, gy), Vector2(origin.x + (LCD_W - 16) * s, gy), _ink().darkened(0.2), maxf(1.0, s * 0.6))
	_draw_status_pips(origin, s)
	if _bubble_timer > 0.0 and not _bubble_text.is_empty():
		_draw_bubble(origin, s)


func _lcd_bg() -> Color:
	match phase:
		Phase.DAY:
			return Color(0.62, 0.78, 0.55)
		Phase.DUSK:
			return Color(0.55, 0.62, 0.42)
		_:
			return Color(0.28, 0.38, 0.28)


func _ink() -> Color:
	return Color(0.12, 0.18, 0.12)


func _draw_status_pips(origin: Vector2, s: float) -> void:
	draw_rect(Rect2(origin, Vector2(LCD_W, 14) * s), Color(0.1, 0.14, 0.1, 0.75))
	if s < 0.5:
		return
	var font := ThemeDB.fallback_font
	var nick := CreatureManager.get_companion_nickname()
	if nick.is_empty() or not CreatureManager.has_chosen_partner():
		nick = "???"
	var line := "%s  Lv%d" % [nick, CreatureManager.get_level()]
	var fs := maxi(1, int(7 * s / 2.2))
	draw_string(font, origin + Vector2(4, 10) * s, line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.85, 0.95, 0.75))
	## Tiny need pips (not a full RPG panel).
	var needs := [
		CreatureManager.get_hunger(),
		CreatureManager.get_happiness(),
		CreatureManager.get_energy(),
		CreatureManager.get_health(),
	]
	for i in needs.size():
		var fill := clampf(float(needs[i]) / 100.0, 0.0, 1.0)
		var px := origin + Vector2(118 + float(i) * 10, 4) * s
		draw_rect(Rect2(px, Vector2(8, 6) * s), _ink().lightened(0.15))
		draw_rect(Rect2(px, Vector2(8 * fill, 6) * s), Color(0.45, 0.85, 0.4))


func _draw_bubble(origin: Vector2, s: float) -> void:
	if s < 0.5:
		return
	var p := origin + Vector2(58, 28) * s
	var font := ThemeDB.fallback_font
	var fs := maxi(1, int(8 * s / 2.5))
	var tw := font.get_string_size(_bubble_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_rect(Rect2(p, Vector2(tw + 8 * s / 2.5, 12 * s / 2.5)), Color(0.85, 0.95, 0.7))
	draw_rect(Rect2(p, Vector2(tw + 8 * s / 2.5, 12 * s / 2.5)), _ink(), false, s * 0.4)
	draw_string(font, p + Vector2(4 * s / 2.5, 9 * s / 2.5), _bubble_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _ink())
