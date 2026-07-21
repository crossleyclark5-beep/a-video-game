extends BaseManager
## Item Shop character roster — unlock, equip, and apply licensed outfit visuals.
## Starter: Jonesy. Others: buy in Field Unit Shop or earn via quests.

var _unlocked: Dictionary = {}  ## outfit_id -> true
var _equipped_id: StringName = &""
var _apply_queued: bool = false


func _initialize_manager() -> void:
	if not EventBus.quest_completed.is_connected(_on_quest_completed):
		EventBus.quest_completed.connect(_on_quest_completed)
	if not EventBus.inventory_changed.is_connected(_on_inventory_changed):
		EventBus.inventory_changed.connect(_on_inventory_changed)
	if not EventBus.scene_transition_finished.is_connected(_on_scene_ready):
		EventBus.scene_transition_finished.connect(_on_scene_ready)
	if not EventBus.profile_changed.is_connected(_on_profile_changed):
		EventBus.profile_changed.connect(_on_profile_changed)
	_log("CharacterRosterManager initialized")


func is_unlocked(outfit_id: StringName) -> bool:
	if _unlocked.has(outfit_id):
		return true
	return InventoryManager.has_item(outfit_id, 1)


func get_equipped() -> StringName:
	var from_shop := ShopManager.get_equipped(CharacterOutfitCatalog.EQUIP_SLOT)
	if from_shop != &"" and is_unlocked(from_shop):
		return from_shop
	if _equipped_id != &"" and is_unlocked(_equipped_id):
		return _equipped_id
	return CharacterOutfitCatalog.STARTER_ID


func unlock(outfit_id: StringName, announce: bool = true) -> void:
	if not CharacterOutfitCatalog.has_outfit(outfit_id):
		return
	if is_unlocked(outfit_id):
		_unlocked[outfit_id] = true
		return
	_unlocked[outfit_id] = true
	if not InventoryManager.has_item(outfit_id, 1):
		InventoryManager.add_item(outfit_id, 1, false)
	var data: ItemData = ResourceRegistry.get_item(outfit_id)
	var label := data.display_name if data else String(outfit_id)
	if announce:
		EventBus.ui_notification_requested.emit("Unlocked character: %s" % label, 2.8)
		EventBus.sfx_play_requested.emit(&"ui_purchase", Vector3.ZERO)
	_log("Unlocked outfit %s" % String(outfit_id))


func equip(outfit_id: StringName) -> String:
	if not CharacterOutfitCatalog.has_outfit(outfit_id):
		return "Unknown character."
	if not is_unlocked(outfit_id):
		return earn_hint(outfit_id)
	_unlocked[outfit_id] = true
	if not InventoryManager.has_item(outfit_id, 1):
		InventoryManager.add_item(outfit_id, 1, false)
	note_equipped(outfit_id)
	ShopManager.set_equipped_slot(CharacterOutfitCatalog.EQUIP_SLOT, outfit_id)
	var data: ItemData = ResourceRegistry.get_item(outfit_id)
	var label := data.display_name if data else String(outfit_id)
	return "Equipped %s." % label


func note_equipped(outfit_id: StringName) -> void:
	## Called after ShopManager writes the character equip slot.
	if not CharacterOutfitCatalog.has_outfit(outfit_id):
		return
	_equipped_id = outfit_id
	_unlocked[outfit_id] = true
	_apply_equipped()


func ensure_starter() -> void:
	var starter := CharacterOutfitCatalog.STARTER_ID
	unlock(starter, false)
	if ShopManager.get_equipped(CharacterOutfitCatalog.EQUIP_SLOT) == &"":
		_equipped_id = starter
		## Direct equip without recursive announce.
		ShopManager.set_equipped_slot(CharacterOutfitCatalog.EQUIP_SLOT, starter)
	_apply_equipped()


func earn_hint(outfit_id: StringName) -> String:
	var mode := CharacterOutfitCatalog.unlock_mode(outfit_id)
	if mode == &"shop":
		return "Buy this character in the Item Shop."
	if mode == &"starter":
		return "Starter character — already yours."
	var q := CharacterOutfitCatalog.earn_quest(outfit_id)
	if q != &"":
		var qd: QuestData = ResourceRegistry.get_quest(q)
		var title := qd.display_name if qd else String(q)
		return "Earn through gameplay: complete %s." % title
	return "Earn this character through gameplay."


func roster_summary() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in CharacterOutfitCatalog.all_ids():
		var data: ItemData = ResourceRegistry.get_item(id)
		var def := CharacterOutfitCatalog.outfit_def(id)
		out.append({
			&"id": id,
			&"name": data.display_name if data else String(id),
			&"unlocked": is_unlocked(id),
			&"equipped": get_equipped() == id,
			&"unlock": def.get("unlock", &"shop"),
			&"blurb": def.get("blurb", ""),
		})
	return out


func apply_to_visual(visual: Node) -> void:
	if visual == null:
		return
	var outfit_id := get_equipped()
	if visual.has_method("apply_character_outfit"):
		visual.call("apply_character_outfit", outfit_id)
	elif visual.has_method("set_library_character"):
		visual.call("set_library_character", CharacterOutfitCatalog.mesh_for(outfit_id))


func _apply_equipped() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for n in tree.get_nodes_in_group(GameConstants.GROUP_PLAYER):
		var cv := n.get_node_or_null("VisualRoot/CharacterVisual")
		if cv:
			apply_to_visual(cv)
		elif n.has_node("CharacterVisual"):
			apply_to_visual(n.get_node("CharacterVisual"))


func _queue_apply() -> void:
	if _apply_queued:
		return
	_apply_queued = true
	call_deferred("_flush_apply")


func _flush_apply() -> void:
	_apply_queued = false
	_apply_equipped()


func _on_quest_completed(quest_id: StringName) -> void:
	for outfit_id in CharacterOutfitCatalog.ids_for_quest(quest_id):
		unlock(outfit_id, true)


func _on_inventory_changed() -> void:
	## Buying a character unique should mark roster unlock.
	for id in CharacterOutfitCatalog.all_ids():
		if InventoryManager.has_item(id, 1):
			_unlocked[id] = true
	_queue_apply()


func _on_scene_ready(_scene: StringName) -> void:
	ensure_starter()
	_queue_apply()


func _on_profile_changed(_profile_id: String) -> void:
	## After profile load/reset, starter must exist.
	call_deferred("ensure_starter")


func export_state() -> Dictionary:
	return {
		&"unlocked": _unlocked.duplicate(),
		&"equipped": _equipped_id,
	}


func import_state(data: Dictionary) -> void:
	if data.is_empty():
		return
	_unlocked = data.get(&"unlocked", data.get("unlocked", {})).duplicate()
	_equipped_id = StringName(str(data.get(&"equipped", data.get("equipped", CharacterOutfitCatalog.STARTER_ID))))
	ensure_starter()


func reset_state() -> void:
	_unlocked.clear()
	_equipped_id = &""
	ensure_starter()
