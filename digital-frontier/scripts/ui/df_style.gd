class_name DFStyle
extends RefCounted
## Digital Frontier Field Unit visual language — early-2000s digi-device chrome.
## Bright, playful, square-edged. One brand for Home, Adventure, Shop, Settings.


const FONT_TITLE := 24
const FONT_SHEET := 20
const FONT_BODY := 16
const FONT_HINT := 13
const FONT_CARD := 15


static func panel_paper(margin: float = 10.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = WorldPalette.UI_PAPER
	s.set_corner_radius_all(0)
	s.set_border_width_all(3)
	s.border_color = WorldPalette.UI_BORDER
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.8
	s.content_margin_bottom = margin * 0.8
	return s


static func panel_navy(margin: float = 12.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = WorldPalette.UI_NAVY
	s.set_corner_radius_all(0)
	s.set_border_width_all(4)
	s.border_color = WorldPalette.UI_CYAN
	s.border_width_bottom = 6
	s.border_color = WorldPalette.UI_CYAN
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.85
	s.content_margin_bottom = margin * 0.85
	## Accent underline via thicker bottom border in cyan.
	s.border_width_left = 4
	s.border_width_right = 4
	s.border_width_top = 4
	s.border_width_bottom = 6
	return s


static func panel_sheet() -> StyleBoxFlat:
	var s := panel_navy(12.0)
	s.bg_color = WorldPalette.UI_SHEET
	s.border_color = WorldPalette.UI_ACCENT
	return s


static func button_normal() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = WorldPalette.UI_INK
	s.set_corner_radius_all(0)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 9
	s.content_margin_bottom = 9
	s.border_width_bottom = 4
	s.border_color = WorldPalette.UI_ACCENT
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	return s


static func button_focus() -> StyleBoxFlat:
	var s := button_normal()
	s.bg_color = WorldPalette.UI_ACCENT
	s.border_color = WorldPalette.UI_CYAN
	s.set_border_width_all(3)
	s.border_width_bottom = 5
	return s


static func button_hover() -> StyleBoxFlat:
	var s := button_normal()
	s.bg_color = WorldPalette.UI_INK.lightened(0.18)
	s.border_color = WorldPalette.UI_CYAN
	return s


static func button_cta() -> StyleBoxFlat:
	var s := button_focus()
	s.bg_color = WorldPalette.UI_ACCENT
	s.border_color = WorldPalette.UI_INK
	return s


static func progress_fill(color: Color = WorldPalette.UI_CYAN) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(0)
	return s


static func progress_bg() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = WorldPalette.UI_INK.darkened(0.2)
	s.set_corner_radius_all(0)
	s.set_border_width_all(2)
	s.border_color = WorldPalette.UI_BORDER
	return s


static func apply_panel(panel: PanelContainer, navy: bool = false) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", panel_navy() if navy else panel_paper())


static func apply_sheet(panel: PanelContainer) -> void:
	if panel:
		panel.add_theme_stylebox_override("panel", panel_sheet())


static func apply_button(btn: Button, cta: bool = false) -> void:
	if btn == null:
		return
	btn.focus_mode = Control.FOCUS_ALL
	var normal := button_cta() if cta else button_normal()
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", button_hover())
	btn.add_theme_stylebox_override("pressed", button_hover())
	btn.add_theme_stylebox_override("focus", button_focus())
	btn.add_theme_color_override("font_color", WorldPalette.UI_INK if cta else WorldPalette.UI_PAPER)
	btn.add_theme_color_override("font_focus_color", WorldPalette.UI_INK)
	btn.add_theme_color_override("font_hover_color", WorldPalette.UI_PAPER)
	btn.add_theme_font_size_override("font_size", FONT_BODY)


static func apply_label_ink(label: Label, size: int = FONT_BODY) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", WorldPalette.UI_INK)
	label.add_theme_font_size_override("font_size", size)


static func apply_label_paper(label: Label, size: int = FONT_BODY) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", WorldPalette.UI_SHEET_TEXT)
	label.add_theme_font_size_override("font_size", size)


static func apply_label_accent(label: Label, size: int = FONT_BODY) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", WorldPalette.UI_ACCENT)
	label.add_theme_font_size_override("font_size", size)


static func apply_label_cyan(label: Label, size: int = FONT_BODY) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", WorldPalette.UI_CYAN)
	label.add_theme_font_size_override("font_size", size)


static func apply_rich_sheet(rtl: RichTextLabel) -> void:
	if rtl == null:
		return
	rtl.bbcode_enabled = true
	rtl.add_theme_color_override("default_color", WorldPalette.UI_SHEET_TEXT)
	rtl.add_theme_font_size_override("normal_font_size", FONT_CARD)
	rtl.scroll_active = true


static func apply_progress(bar: ProgressBar, fill: Color = WorldPalette.UI_CYAN) -> void:
	if bar == null:
		return
	bar.add_theme_stylebox_override("fill", progress_fill(fill))
	bar.add_theme_stylebox_override("background", progress_bg())
	bar.show_percentage = false


static func hex(c: Color) -> String:
	return "#%02x%02x%02x" % [int(c.r * 255.0), int(c.g * 255.0), int(c.b * 255.0)]


static func color_tag(c: Color, text: String) -> String:
	return "[color=%s]%s[/color]" % [hex(c), text]


static func header_bb(title: String, accent: Color = WorldPalette.UI_CYAN) -> String:
	return "[b]%s[/b]\n%s\n" % [color_tag(accent, title), color_tag(WorldPalette.UI_MUTED, "────────────────────")]


static func card_bb(title: String, body: String, selected: bool = false, meta: String = "") -> String:
	var mark := color_tag(WorldPalette.UI_ACCENT, "▶ ") if selected else "  "
	var t := color_tag(WorldPalette.UI_GOLD if selected else WorldPalette.UI_SHEET_TEXT, title)
	var line := "%s[b]%s[/b]" % [mark, t]
	if not meta.is_empty():
		line += "  " + color_tag(WorldPalette.UI_CYAN, meta)
	if not body.is_empty():
		line += "\n    " + color_tag(WorldPalette.UI_MUTED.lightened(0.35), body)
	return line


static func slide_in(node: Control, from_y: float = 24.0, duration: float = 0.22) -> void:
	if node == null or not is_instance_valid(node):
		return
	node.modulate.a = 0.0
	node.position.y += from_y
	var tween := node.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate:a", 1.0, duration)
	tween.tween_property(node, "position:y", node.position.y - from_y, duration)


static func pulse_modulate(node: CanvasItem, color: Color = WorldPalette.UI_CYAN) -> void:
	if node == null or not is_instance_valid(node):
		return
	var base := node.modulate
	var tween := node.create_tween()
	tween.tween_property(node, "modulate", color, 0.08)
	tween.tween_property(node, "modulate", base, 0.18)


static func make_scanline_overlay(parent: Control, alpha: float = 0.06) -> ColorRect:
	var scan := ColorRect.new()
	scan.name = "DFScanlines"
	scan.set_anchors_preset(Control.PRESET_FULL_RECT)
	scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scan.color = Color(0, 0, 0, 0)
	## Lightweight: solid wash; true scanlines would need a shader — keep mobile-cheap.
	scan.color = Color(WorldPalette.UI_CYAN.r, WorldPalette.UI_CYAN.g, WorldPalette.UI_CYAN.b, alpha * 0.35)
	parent.add_child(scan)
	return scan


static func make_brand_bar(parent: Control, title: String) -> PanelContainer:
	var bar := PanelContainer.new()
	bar.name = "DFBrandBar"
	apply_panel(bar, false)
	var row := HBoxContainer.new()
	bar.add_child(row)
	var mark := Label.new()
	mark.text = "◆"
	apply_label_accent(mark, FONT_TITLE)
	row.add_child(mark)
	var lab := Label.new()
	lab.text = title
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_label_ink(lab, FONT_TITLE)
	row.add_child(lab)
	parent.add_child(bar)
	return bar
