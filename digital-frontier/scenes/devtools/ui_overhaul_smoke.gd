extends Node
## Scene-based UI smoke — runs after autoloads (safe for DFFormat / shop / settings).

var _frames: int = 0
var _done: bool = false


func _ready() -> void:
	print("UI_OVERHAUL_SMOKE_START")


func _process(_delta: float) -> void:
	if _done:
		return
	_frames += 1
	if _frames < 4:
		return
	_done = true
	var ok := true
	var pack_txt := DFFormat.pack_sheet()
	if not pack_txt.contains("PACK"):
		push_error("pack sheet broken")
		ok = false
	var quest_txt := DFFormat.quest_sheet()
	if not quest_txt.contains("QUEST"):
		push_error("quest sheet broken")
		ok = false
	var col := DFFormat.collection_sheet()
	if not col.contains("COLLECTION"):
		push_error("collection sheet broken")
		ok = false
	var shop := FieldUnitShop.present(self)
	ok = ok and shop != null and shop.is_shop_open()
	if shop:
		shop.close()
	var settings := DeviceSettings.present(self)
	ok = ok and settings != null and settings.visible
	if settings:
		settings.close()
	print("UI_OVERHAUL_SMOKE_OK" if ok else "UI_OVERHAUL_SMOKE_FAIL")
	get_tree().quit(0 if ok else 1)
