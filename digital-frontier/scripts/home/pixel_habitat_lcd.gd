class_name PixelHabitatLcd
extends Control
## 2D pixel LCD habitat — late-90s digital companion screen aesthetic.
## Logical 160×120 nearest-scaled to the control size.

signal station_activated(station_id: StringName, care_action: StringName)

const LCD_W := 160
const LCD_H := 120
const PIXEL_SCALE_TARGET := 4  ## visual density hint

enum Phase { DAY, DUSK, NIGHT }

var phase: Phase = Phase.NIGHT
var _creature: PixelCreatureSprite
var _time: float = 0.0
var _wander_timer: float = 1.5
var _target := Vector2(80, 78)
var _care_lock: float = 0.0
var _bubble_text: String = ""
var _bubble_timer: float = 0.0
var _floor_y := 92.0
var _stations := {
	&"food": {"pos": Vector2(28, 88), "action": &"feed", "label": "BOWL"},
	&"bed": {"pos": Vector2(130, 88), "action": &"rest", "label": "BED"},
	&"toy": {"pos": Vector2(80, 88), "action": &"play", "label": "TOY"},
	&"train": {"pos": Vector2(50, 70), "action": &"train", "label": "PAD"},
}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_creature = PixelCreatureSprite.new()
	_creature.name = "PixelCreature"
	_creature.position = Vector2(80, _floor_y - 8)
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
		]:
			## Sleep can persist if energy was low.
			if _creature.anim == PixelCreatureSprite.Anim.SLEEP and CreatureManager.get_energy() < 45.0:
				pass
			else:
				_creature.set_anim(PixelCreatureSprite.Anim.IDLE)
	else:
		_tick_ai(delta)
	## Map creature from LCD space into control space.
	var scale_v := _lcd_scale()
	var origin := _lcd_origin()
	_creature.scale = Vector2(scale_v / float(PixelCreatureSprite.SPRITE_SIZE) * 18.0, scale_v / float(PixelCreatureSprite.SPRITE_SIZE) * 18.0)
	_creature.position = origin + _creature_lcd_pos() * scale_v
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
	## Walk toward station then play reaction.
	var station_id := &""
	match action:
		&"feed":
			station_id = &"food"
		&"rest":
			station_id = &"bed"
		&"play":
			station_id = &"toy"
		&"train":
			station_id = &"train"
		_:
			station_id = &""
	if station_id != &"" and _stations.has(station_id):
		_target = _stations[station_id]["pos"]
	_creature.play_care(action)
	_care_lock = 2.2 if action != &"rest" else 3.5
	_show_bubble(_care_bubble(action))
	station_activated.emit(station_id if station_id != &"" else &"pet", action)


func play_transition_leave() -> void:
	## Creature walks to the right “door” for adventure transition.
	_target = Vector2(LCD_W + 10, _floor_y - 8)
	_creature.set_anim(PixelCreatureSprite.Anim.WALK)
	_creature.facing = 1
	_care_lock = 99.0
	_show_bubble("BYE!")


func get_creature_screen_pos() -> Vector2:
	return _creature.global_position if _creature else global_position


func _creature_lcd_pos() -> Vector2:
	## Stored as meta on node for AI; use _ai_pos.
	return _ai_pos


var _ai_pos := Vector2(80, 84)


func _tick_ai(delta: float) -> void:
	var mood := CreatureManager.get_mood_label().to_lower()
	if CreatureManager.get_energy() < 25.0:
		_target = _stations[&"bed"]["pos"]
		_creature.set_anim(PixelCreatureSprite.Anim.WALK if _ai_pos.distance_to(_target) > 4.0 else PixelCreatureSprite.Anim.SLEEP)
	elif CreatureManager.get_hunger() < 30.0:
		_target = _stations[&"food"]["pos"]
		_creature.set_anim(PixelCreatureSprite.Anim.WALK if _ai_pos.distance_to(_target) > 4.0 else PixelCreatureSprite.Anim.SAD)
	elif "sad" in mood or "lonely" in mood:
		_creature.set_anim(PixelCreatureSprite.Anim.SAD)
	else:
		_wander_timer -= delta
		if _wander_timer <= 0.0:
			_wander_timer = randf_range(1.2, 3.0)
			_target = Vector2(randf_range(24, LCD_W - 24), _floor_y - 8)
		if _ai_pos.distance_to(_target) > 3.0:
			_creature.set_anim(PixelCreatureSprite.Anim.WALK)
		else:
			_creature.set_anim(PixelCreatureSprite.Anim.IDLE)

	var to := _target - _ai_pos
	if to.length() > 1.0:
		var step := to.normalized() * 28.0 * delta
		_ai_pos += step
		_creature.facing = 1 if to.x >= 0.0 else -1
	_ai_pos.x = clampf(_ai_pos.x, 16.0, LCD_W - 16.0)
	_ai_pos.y = clampf(_ai_pos.y, 60.0, _floor_y - 4.0)


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
		&"play":
			return "YAY!"
		&"train":
			return "HUP!"
		&"pet":
			return "<3"
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
	## Bezel inset already provided by parent; draw LCD glass.
	var lcd_rect := Rect2(origin, Vector2(LCD_W, LCD_H) * s)
	draw_rect(lcd_rect, _sky_color())
	## Pixel grid room.
	_draw_room(origin, s)
	_draw_stations(origin, s)
	## Status strip at top of LCD.
	_draw_status_strip(origin, s)
	if _bubble_timer > 0.0 and not _bubble_text.is_empty():
		_draw_bubble(origin, s)


func _sky_color() -> Color:
	match phase:
		Phase.DAY:
			return Color(0.55, 0.78, 0.95)
		Phase.DUSK:
			return Color(0.85, 0.55, 0.45)
		_:
			return Color(0.12, 0.14, 0.22)


func _draw_room(origin: Vector2, s: float) -> void:
	## Wallpaper
	var wall := Color(0.55, 0.72, 0.58) if phase != Phase.NIGHT else Color(0.28, 0.36, 0.42)
	draw_rect(Rect2(origin + Vector2(0, 0) * s, Vector2(LCD_W, 70) * s), wall)
	## Floor
	var floor_c := Color(0.62, 0.48, 0.32) if phase != Phase.NIGHT else Color(0.32, 0.26, 0.2)
	draw_rect(Rect2(origin + Vector2(0, 70) * s, Vector2(LCD_W, 50) * s), floor_c)
	## Floor pixel tiles
	for x in range(0, LCD_W, 8):
		draw_line(origin + Vector2(x, 70) * s, origin + Vector2(x, LCD_H) * s, floor_c.darkened(0.12), maxf(1.0, s * 0.5))
	## Window
	var win := Rect2(origin + Vector2(110, 18) * s, Vector2(36, 28) * s)
	draw_rect(win, Color(0.2, 0.22, 0.28))
	draw_rect(win.grow(-2.0 * s / 4.0), _sky_color().lightened(0.05))
	draw_line(win.position + Vector2(win.size.x * 0.5, 0), win.position + Vector2(win.size.x * 0.5, win.size.y), WorldPalette.UI_INK, s * 0.4)
	draw_line(win.position + Vector2(0, win.size.y * 0.5), win.position + Vector2(win.size.x, win.size.y * 0.5), WorldPalette.UI_INK, s * 0.4)
	## Shelf
	draw_rect(Rect2(origin + Vector2(8, 40) * s, Vector2(40, 4) * s), WorldPalette.WOOD)
	## Pixel plant
	draw_rect(Rect2(origin + Vector2(14, 28) * s, Vector2(4, 12) * s), WorldPalette.LEAF_DARK)
	draw_rect(Rect2(origin + Vector2(10, 24) * s, Vector2(12, 6) * s), WorldPalette.LEAF)


func _draw_stations(origin: Vector2, s: float) -> void:
	## Bowl
	var bowl: Vector2 = _stations[&"food"]["pos"]
	draw_rect(Rect2(origin + (bowl + Vector2(-6, -2)) * s, Vector2(12, 5) * s), WorldPalette.UI_INK)
	draw_rect(Rect2(origin + (bowl + Vector2(-4, -1)) * s, Vector2(8, 3) * s), WorldPalette.UI_ACCENT)
	## Bed
	var bed: Vector2 = _stations[&"bed"]["pos"]
	draw_rect(Rect2(origin + (bed + Vector2(-12, -4)) * s, Vector2(24, 8) * s), Color(0.45, 0.35, 0.55))
	draw_rect(Rect2(origin + (bed + Vector2(-10, -6)) * s, Vector2(8, 5) * s), Color(0.85, 0.85, 0.9))
	## Toy ball
	var toy: Vector2 = _stations[&"toy"]["pos"]
	draw_circle(origin + toy * s, 4.0 * s, WorldPalette.UI_ACCENT)
	draw_circle(origin + toy * s, 1.5 * s, WorldPalette.UI_PAPER)
	## Train pad
	var pad: Vector2 = _stations[&"train"]["pos"]
	draw_rect(Rect2(origin + (pad + Vector2(-8, -2)) * s, Vector2(16, 4) * s), WorldPalette.METAL)


func _draw_status_strip(origin: Vector2, s: float) -> void:
	draw_rect(Rect2(origin, Vector2(LCD_W, 12) * s), Color(0.08, 0.1, 0.12, 0.85))
	var font := ThemeDB.fallback_font
	var nick := CreatureManager.get_companion_nickname()
	var line := "%s  Lv%d  %s" % [nick, CreatureManager.get_level(), get_phase_label()]
	draw_string(font, origin + Vector2(4, 9) * s, line, HORIZONTAL_ALIGNMENT_LEFT, -1, int(8 * s / 2.5), WorldPalette.UI_PAPER)


func _draw_bubble(origin: Vector2, s: float) -> void:
	var p := origin + (_ai_pos + Vector2(-10, -28)) * s
	var font := ThemeDB.fallback_font
	var tw := font.get_string_size(_bubble_text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(8 * s / 2.5)).x
	draw_rect(Rect2(p, Vector2(tw + 8 * s / 2.5, 12 * s / 2.5)), WorldPalette.UI_PAPER)
	draw_rect(Rect2(p, Vector2(tw + 8 * s / 2.5, 12 * s / 2.5)), WorldPalette.UI_INK, false, s * 0.4)
	draw_string(font, p + Vector2(4 * s / 2.5, 9 * s / 2.5), _bubble_text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(8 * s / 2.5), WorldPalette.UI_INK)
