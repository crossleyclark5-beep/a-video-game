class_name DeviceBootSequence
extends CanvasLayer
## First-power-on sequence: Digital Frontier logo → LCD pixel splash.
## Buttons only; A / Start advances.

signal finished

var _phase: int = 0
var _timer: float = 0.0
var _logo: Label
var _sub: Label
var _scan: ColorRect
var _done: bool = false


static func present(parent: Node) -> DeviceBootSequence:
	var boot := DeviceBootSequence.new()
	boot.name = "DeviceBootSequence"
	parent.add_child(boot)
	return boot


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	EventBus.sfx_play_requested.emit(&"boot_chime", Vector3.ZERO)
	DeviceService.set_led(Color(0.2, 0.85, 0.55), &"pulse")


func _process(delta: float) -> void:
	if _done:
		return
	_timer += delta
	match _phase:
		0:
			## Logo fade-in.
			_logo.modulate.a = clampf(_timer / 0.8, 0.0, 1.0)
			if _timer >= 1.6:
				_phase = 1
				_timer = 0.0
				_sub.visible = true
				EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
		1:
			## Pixel scanline wipe.
			_scan.visible = true
			_scan.anchor_top = clampf(_timer / 1.1, 0.0, 1.0)
			_sub.modulate.a = clampf(_timer / 0.5, 0.0, 1.0)
			if _timer >= 1.4:
				_phase = 2
				_timer = 0.0
				_sub.text = "A / Start — continue"
				EventBus.sfx_play_requested.emit(&"menu_beep", Vector3.ZERO)
		2:
			## Wait for confirm (also auto-advance after pause).
			if _timer >= 4.0:
				_finish()


func _input(_event: InputEvent) -> void:
	if _done:
		return
	if _phase >= 1 and (
		InputManager.is_action_just_pressed(&"ui_confirm")
		or InputManager.is_action_just_pressed(&"interact")
		or InputManager.is_action_just_pressed(&"go_adventure")
		or InputManager.is_action_just_pressed(&"device_menu")
	):
		if _phase < 2:
			_phase = 2
			_timer = 0.0
			_sub.visible = true
			_sub.text = "A / Start — continue"
			_sub.modulate.a = 1.0
		else:
			_finish()
		get_viewport().set_input_as_handled()


func _finish() -> void:
	if _done:
		return
	_done = true
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
	finished.emit()
	queue_free()


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.06)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_logo = Label.new()
	_logo.text = "DIGITAL FRONTIER"
	_logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_logo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_logo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_logo.offset_top = -40
	_logo.add_theme_font_size_override("font_size", 42)
	_logo.add_theme_color_override("font_color", Color(0.55, 0.95, 0.7))
	_logo.modulate.a = 0.0
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_logo)

	_sub = Label.new()
	_sub.text = "FIELD UNIT  ·  COMPANION OS"
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.set_anchors_preset(Control.PRESET_CENTER)
	_sub.offset_top = 36
	_sub.offset_bottom = 60
	_sub.offset_left = -200
	_sub.offset_right = 200
	_sub.add_theme_font_size_override("font_size", 16)
	_sub.add_theme_color_override("font_color", Color(0.7, 0.78, 0.72))
	_sub.visible = false
	_sub.modulate.a = 0.0
	_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sub)

	_scan = ColorRect.new()
	_scan.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scan.color = Color(0.2, 0.9, 0.55, 0.12)
	_scan.visible = false
	_scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scan)
