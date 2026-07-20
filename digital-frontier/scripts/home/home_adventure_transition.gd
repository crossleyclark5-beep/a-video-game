class_name HomeAdventureTransition
extends CanvasLayer
## Pixel dissolve transition: 2D pet device → 2.5D adventure world.
## Feeling: the tiny companion leaves the LCD and enters a real world.

signal finished

var _lcd: ColorRect
var _scan: ColorRect
var _label: Label
var _noise_rects: Array[ColorRect] = []


func _ready() -> void:
	layer = 100
	visible = false


func play_and_wait() -> void:
	visible = true
	_build_fx()
	## Phase 1 — LCD wipe / scanlines
	_lcd.modulate.a = 0.0
	_label.text = "DEPARTING HABITAT..."
	var t1 := create_tween()
	t1.tween_property(_lcd, "modulate:a", 1.0, 0.35)
	t1.parallel().tween_property(_scan, "position:y", size_y() * 0.85, 0.45)
	await t1.finished
	## Phase 2 — pixel scramble
	_label.text = "PIXEL GATE OPEN"
	for i in 12:
		_spawn_noise_block()
	var t2 := create_tween()
	t2.tween_interval(0.55)
	await t2.finished
	## Phase 3 — solid to adventure
	_label.text = "ENTERING ADVENTURE"
	var t3 := create_tween()
	t3.tween_property(_lcd, "color", WorldPalette.UI_INK, 0.3)
	await t3.finished
	finished.emit()


func size_y() -> float:
	return get_viewport().get_visible_rect().size.y


func _build_fx() -> void:
	for c in get_children():
		c.queue_free()
	_noise_rects.clear()
	_lcd = ColorRect.new()
	_lcd.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lcd.color = Color(0.92, 0.90, 0.82, 1.0)
	_lcd.modulate.a = 0.0
	add_child(_lcd)
	_scan = ColorRect.new()
	_scan.color = WorldPalette.UI_ACCENT
	_scan.size = Vector2(get_viewport().get_visible_rect().size.x, 6)
	_scan.position = Vector2(0, 0)
	add_child(_scan)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", WorldPalette.UI_INK)
	_label.position = get_viewport().get_visible_rect().size * 0.5 - Vector2(160, 20)
	_label.size = Vector2(320, 40)
	add_child(_label)


func _spawn_noise_block() -> void:
	var r := ColorRect.new()
	var vp := get_viewport().get_visible_rect().size
	r.size = Vector2(randf_range(8, 48), randf_range(8, 48))
	r.position = Vector2(randf() * vp.x, randf() * vp.y)
	r.color = [
		WorldPalette.UI_INK,
		WorldPalette.UI_ACCENT,
		WorldPalette.UI_PAPER,
		Color(0.98, 0.55, 0.18),
	][randi() % 4]
	_lcd.add_child(r)
	_noise_rects.append(r)
