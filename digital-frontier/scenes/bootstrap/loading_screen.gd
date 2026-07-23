extends Control
## Lightweight loading overlay — Field Unit chrome while Adventure instantiates.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = WorldPalette.UI_NAVY
	add_child(bg)
	var label := Label.new()
	label.text = "◆ LOADING FIELD UNIT…"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	DFStyle.apply_label_cyan(label, DFStyle.FONT_TITLE)
	add_child(label)
	var sub := Label.new()
	sub.text = "Mapping the Frontier"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.anchor_top = 0.55
	sub.anchor_bottom = 0.62
	sub.anchor_left = 0.0
	sub.anchor_right = 1.0
	DFStyle.apply_label_ink(sub, DFStyle.FONT_HINT)
	add_child(sub)
