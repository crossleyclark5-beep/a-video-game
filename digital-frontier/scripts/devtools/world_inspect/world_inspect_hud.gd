class_name WorldInspectHud
extends CanvasLayer
## Lightweight developer HUD for World Inspection Mode.


var _panel: PanelContainer = null
var _label: Label = null
var _status: String = ""


func _ready() -> void:
	layer = UIManager.Layer.DEBUG
	_build()


func set_status(text: String) -> void:
	_status = text


func refresh(controller: WorldInspectController) -> void:
	if _label == null or controller == null:
		return
	_label.text = _compose(controller, null)


func update_readout(controller: WorldInspectController, camera: Camera3D) -> void:
	if _label == null or not visible:
		return
	_label.text = _compose(controller, camera)


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.name = "InspectPanel"
	_panel.anchor_left = 0.0
	_panel.anchor_top = 0.0
	_panel.anchor_right = 0.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = 12.0
	_panel.offset_top = 12.0
	_panel.offset_right = 420.0
	_panel.offset_bottom = 280.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.12, 0.78)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_panel.add_theme_stylebox_override(&"panel", sb)
	add_child(_panel)
	_label = Label.new()
	_label.name = "InspectLabel"
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override(&"font_size", 14)
	_label.add_theme_color_override(&"font_color", Color(0.85, 0.95, 1.0))
	_panel.add_child(_label)


func _compose(controller: WorldInspectController, camera: Camera3D) -> String:
	var lines: PackedStringArray = [
		"WORLD INSPECT (dev)",
		"F3 exit · RMB look · WASD move · Q/E up/down",
		"Shift fast · Alt slow · Wheel FOV · C above player",
		"1 Grid  2 Height  3 Info  4 Collision  5 Scale  6/F4 Placement",
		"Overlays: %s" % controller.overlay_summary(),
	]
	if camera:
		var p := camera.global_position
		var ground := GrasslandHeightField.height_at(p.x, p.z)
		lines.append("Cam (%.1f, %.1f, %.1f)  FOV %.0f" % [p.x, p.y, p.z, camera.fov])
		lines.append("Ground Y %.2f  altitude %.1f" % [ground, p.y - ground])
	if not _status.is_empty():
		lines.append(_status)
	return "\n".join(lines)
