class_name FieldUnitShop
extends CanvasLayer
## Handheld item shop — physical buttons only (no touch / mouse required).
## D-pad browse · L/R or shoulders cycle category · A buy/use · X owned · B close.

enum ViewMode { BROWSE, OWNED }

const CATEGORIES: Array[ItemData.ShopCategory] = [
	ItemData.ShopCategory.CREATURE,
	ItemData.ShopCategory.PLAYER,
	ItemData.ShopCategory.HOME,
	ItemData.ShopCategory.ADVENTURE,
]

var _shop_id: StringName = ShopManager.SHOP_ID_HOME
var _mode: ViewMode = ViewMode.BROWSE
var _category_index: int = 0
var _item_index: int = 0
var _items: Array[ItemData] = []
var _owned_ids: Array[StringName] = []
var _open: bool = false

var _root: PanelContainer
var _title: Label
var _bits: Label
var _cat_label: Label
var _list: RichTextLabel
var _detail: RichTextLabel
var _hint: Label
var _flash: Label
var _flash_timer: float = 0.0


static func present(parent: Node, shop_id: StringName = ShopManager.SHOP_ID_HOME) -> FieldUnitShop:
	var existing := parent.get_node_or_null("FieldUnitShop") as FieldUnitShop
	if existing == null:
		existing = FieldUnitShop.new()
		existing.name = "FieldUnitShop"
		parent.add_child(existing)
	existing.open(shop_id)
	return existing


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false
	set_process(false)
	set_process_input(false)


func open(shop_id: StringName = ShopManager.SHOP_ID_HOME) -> void:
	_shop_id = shop_id
	_mode = ViewMode.BROWSE
	_category_index = 0
	_item_index = 0
	_open = true
	visible = true
	set_process(true)
	set_process_input(true)
	UIManager.push_modal(&"shop")
	_rebuild_list()
	_refresh()
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	set_process(false)
	set_process_input(false)
	UIManager.pop_modal()
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)


func is_shop_open() -> bool:
	return _open


func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0 and _flash:
			_flash.visible = false


func _input(_event: InputEvent) -> void:
	if not _open:
		return
	## Capture while open so adventure HUD / home focus don't steal.
	if InputManager.is_action_just_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	if InputManager.is_action_just_pressed(&"device_cycle"):
		_toggle_mode()
		get_viewport().set_input_as_handled()
		return
	## L / R shoulders cycle category in browse mode.
	if _mode == ViewMode.BROWSE:
		if InputManager.is_action_just_pressed(&"run"):
			_cycle_category(-1)
			get_viewport().set_input_as_handled()
			return
		if InputManager.is_action_just_pressed(&"map_peek"):
			_cycle_category(1)
			get_viewport().set_input_as_handled()
			return
	var ui := InputManager.get_ui_vector_just()
	if ui.x != 0 and _mode == ViewMode.BROWSE:
		_cycle_category(ui.x)
		get_viewport().set_input_as_handled()
		return
	if ui.y != 0:
		_move_selection(ui.y)
		get_viewport().set_input_as_handled()
		return
	if InputManager.is_action_just_pressed(&"ui_confirm") or InputManager.is_action_just_pressed(&"interact"):
		_confirm()
		get_viewport().set_input_as_handled()
		return


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	_root = PanelContainer.new()
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.12, 0.96)
	style.border_color = Color(0.35, 0.55, 0.45, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_root.add_theme_stylebox_override("panel", style)
	margin.add_child(_root)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_root.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	_title = Label.new()
	_title.text = "FIELD UNIT SHOP"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", Color(0.92, 0.95, 0.88))
	header.add_child(_title)
	_bits = Label.new()
	_bits.add_theme_font_size_override("font_size", 20)
	_bits.add_theme_color_override("font_color", Color(0.95, 0.82, 0.28))
	header.add_child(_bits)

	_cat_label = Label.new()
	_cat_label.add_theme_font_size_override("font_size", 16)
	_cat_label.add_theme_color_override("font_color", Color(0.55, 0.85, 0.7))
	vbox.add_child(_cat_label)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	vbox.add_child(body)

	_list = RichTextLabel.new()
	_list.bbcode_enabled = true
	_list.fit_content = false
	_list.scroll_active = true
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.custom_minimum_size = Vector2(220, 200)
	body.add_child(_list)

	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.fit_content = false
	_detail.scroll_active = true
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.custom_minimum_size = Vector2(220, 200)
	body.add_child(_detail)

	_flash = Label.new()
	_flash.visible = false
	_flash.add_theme_font_size_override("font_size", 15)
	_flash.add_theme_color_override("font_color", Color(0.95, 0.9, 0.55))
	vbox.add_child(_flash)

	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color(0.7, 0.75, 0.7))
	vbox.add_child(_hint)


func _toggle_mode() -> void:
	_mode = ViewMode.OWNED if _mode == ViewMode.BROWSE else ViewMode.BROWSE
	_item_index = 0
	_rebuild_list()
	_refresh()
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)


func _cycle_category(delta: int) -> void:
	if _mode != ViewMode.BROWSE:
		return
	_category_index = (_category_index + delta) % CATEGORIES.size()
	if _category_index < 0:
		_category_index += CATEGORIES.size()
	## Skip HOME category at Market Mile.
	if _shop_id == ShopManager.SHOP_ID_MILE and CATEGORIES[_category_index] == ItemData.ShopCategory.HOME:
		_category_index = (_category_index + delta) % CATEGORIES.size()
		if _category_index < 0:
			_category_index += CATEGORIES.size()
	_item_index = 0
	_rebuild_list()
	_refresh()
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)


func _move_selection(delta: int) -> void:
	var count := _items.size() if _mode == ViewMode.BROWSE else _owned_ids.size()
	if count <= 0:
		return
	_item_index = (_item_index + delta) % count
	if _item_index < 0:
		_item_index += count
	_refresh()
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)


func _confirm() -> void:
	if _mode == ViewMode.BROWSE:
		if _items.is_empty() or _item_index < 0 or _item_index >= _items.size():
			_flash_msg("Nothing selected.")
			return
		var data: ItemData = _items[_item_index]
		var msg := ShopManager.buy(data.id)
		_flash_msg(msg)
		_rebuild_list()
		_refresh()
	else:
		if _owned_ids.is_empty() or _item_index < 0 or _item_index >= _owned_ids.size():
			_flash_msg("Pack empty.")
			return
		var iid: StringName = _owned_ids[_item_index]
		var msg2 := ShopManager.use_item(iid)
		_flash_msg(msg2)
		_rebuild_list()
		_refresh()


func _rebuild_list() -> void:
	if _mode == ViewMode.BROWSE:
		var cat: ItemData.ShopCategory = CATEGORIES[_category_index]
		_items = ShopManager.get_catalog_by_category(cat, _shop_id)
		if _item_index >= _items.size():
			_item_index = maxi(_items.size() - 1, 0)
	else:
		_owned_ids = ShopManager.get_owned_item_ids()
		if _item_index >= _owned_ids.size():
			_item_index = maxi(_owned_ids.size() - 1, 0)


func _refresh() -> void:
	_bits.text = "%d Bits" % InventoryManager.get_bits()
	var shop_name := "Home Catalog" if _shop_id == ShopManager.SHOP_ID_HOME else "Market Mile"
	if _mode == ViewMode.BROWSE:
		_title.text = "SHOP · %s" % shop_name
		var cat: ItemData.ShopCategory = CATEGORIES[_category_index]
		_cat_label.text = "◀ %s ▶   (L/R or shoulders)" % ShopManager.category_label(cat)
		_hint.text = "↑↓ browse  ·  A buy  ·  X owned pack  ·  B close"
		_fill_browse()
	else:
		_title.text = "OWNED · Pack"
		_cat_label.text = "Your items — A to use / equip"
		_hint.text = "↑↓ browse  ·  A use/equip  ·  X back to shop  ·  B close"
		_fill_owned()


func _fill_browse() -> void:
	var lines: PackedStringArray = PackedStringArray()
	if _items.is_empty():
		lines.append("[i]No stock in this category.[/i]")
	else:
		for i in _items.size():
			var d: ItemData = _items[i]
			var owned := ""
			if d.is_unique and ShopManager.is_owned_unique(d.id):
				owned = " [OWNED]"
			var can := ShopManager.can_buy(d.id)
			var price_col := "#c8e6a0" if can else "#e08070"
			var sel := "▸ " if i == _item_index else "  "
			lines.append("%s%s — [color=%s]%d Bits[/color]%s" % [sel, d.display_name, price_col, d.buy_value, owned])
	_list.text = "\n".join(lines)

	if _items.is_empty() or _item_index >= _items.size():
		_detail.text = "Pick a category with stock."
		return
	var cur: ItemData = _items[_item_index]
	var blurb := cur.shop_blurb if not cur.shop_blurb.is_empty() else ShopManager.category_label(cur.shop_category)
	_detail.text = "[b]%s[/b]\n%s\n\n%s\n\nPrice: [color=#f0d050]%d Bits[/color]\nYou have: %d" % [
		cur.display_name,
		blurb,
		cur.description,
		cur.buy_value,
		InventoryManager.get_quantity(cur.id),
	]


func _fill_owned() -> void:
	var lines: PackedStringArray = PackedStringArray()
	if _owned_ids.is_empty():
		lines.append("[i]Nothing in the pack yet.[/i]")
	else:
		for i in _owned_ids.size():
			var iid: StringName = _owned_ids[i]
			var d: ItemData = ResourceRegistry.get_item(iid)
			var label := d.display_name if d else String(iid)
			var qty := InventoryManager.get_quantity(iid)
			var eq := ""
			if d and d.equip_slot != &"" and ShopManager.get_equipped(d.equip_slot) == iid:
				eq = " [E]"
			var sel := "▸ " if i == _item_index else "  "
			lines.append("%s%s ×%d%s" % [sel, label, qty, eq])
	_list.text = "\n".join(lines)

	if _owned_ids.is_empty() or _item_index >= _owned_ids.size():
		_detail.text = "Buy something at the shop first."
		return
	var cur_id: StringName = _owned_ids[_item_index]
	var cur2: ItemData = ResourceRegistry.get_item(cur_id)
	if cur2 == null:
		_detail.text = String(cur_id)
		return
	var action := "Equip" if cur2.equip_slot != &"" else ("Use" if cur2.use_effect_id != &"" else "Hold")
	_detail.text = "[b]%s[/b]\n%s\n\nA: %s" % [cur2.display_name, cur2.description, action]


func _flash_msg(msg: String) -> void:
	if _flash == null:
		return
	_flash.text = msg
	_flash.visible = true
	_flash_timer = 2.2
	EventBus.ui_notification_requested.emit(msg, 2.0)
