extends Node
## Character Item Shop roster smoke.


func _ready() -> void:
	await get_tree().process_frame
	var ok := true

	CharacterRosterManager.reset_state()
	if CharacterRosterManager.get_equipped() != CharacterOutfitCatalog.STARTER_ID:
		push_error("starter not equipped")
		ok = false
	if not CharacterRosterManager.is_unlocked(&"char_jonesy"):
		push_error("jonesy not unlocked")
		ok = false

	var roster := CharacterOutfitCatalog.all_ids()
	if roster.size() != 14:
		push_error("expected 14 outfits, got %d" % roster.size())
		ok = false
	for id in roster:
		if not ResourceRegistry.get_item(id):
			push_error("missing item %s" % String(id))
			ok = false
		if not CharacterCatalog.has_character(CharacterOutfitCatalog.mesh_for(id)):
			push_error("missing mesh for %s" % String(id))
			ok = false

	var player_cat := ShopManager.get_catalog_by_category(ItemData.ShopCategory.PLAYER, ShopManager.SHOP_ID_HOME)
	var char_count := 0
	for it in player_cat:
		if it.equip_slot == CharacterOutfitCatalog.EQUIP_SLOT:
			char_count += 1
	if char_count < 14:
		push_error("shop player chars %d < 14" % char_count)
		ok = false

	## Buy a shop character
	InventoryManager.add_bits(2000, false, "smoke", "test")
	var msg := ShopManager.buy(&"char_ice_king")
	print("Buy ice king: ", msg)
	if not CharacterRosterManager.is_unlocked(&"char_ice_king"):
		push_error("ice king unlock failed")
		ok = false
	if CharacterRosterManager.get_equipped() != &"char_ice_king":
		push_error("ice king not auto-equipped")
		ok = false

	## Earn via quest hook
	CharacterRosterManager.unlock(&"char_dark_voyager", false)
	if not CharacterRosterManager.is_unlocked(&"char_dark_voyager"):
		push_error("earn unlock failed")
		ok = false
	print(CharacterRosterManager.equip(&"char_dark_voyager"))
	if CharacterRosterManager.get_equipped() != &"char_dark_voyager":
		push_error("dark voyager equip failed")
		ok = false

	## Visual build
	var vis := CharacterLibraryVisual.new()
	add_child(vis)
	vis.build_outfit(&"char_jonesy", 1.0)
	if vis.get_child_count() < 1:
		push_error("jonesy visual empty")
		ok = false
	vis.build_outfit(&"char_peely", 1.0)

	var cv := CharacterVisual.new()
	add_child(cv)
	await get_tree().process_frame
	cv.apply_character_outfit(&"char_master_chief")

	## Save round-trip
	var state := CharacterRosterManager.export_state()
	CharacterRosterManager.reset_state()
	CharacterRosterManager.import_state(state)
	if not CharacterRosterManager.is_unlocked(&"char_ice_king"):
		push_error("import lost ice king")
		ok = false

	## Switch back to Jonesy
	print(CharacterRosterManager.equip(&"char_jonesy"))
	if CharacterRosterManager.get_equipped() != &"char_jonesy":
		push_error("re-equip jonesy failed")
		ok = false

	if ok:
		print("CHARACTER_SHOP_ROSTER_SMOKE_OK")
	else:
		print("CHARACTER_SHOP_ROSTER_SMOKE_FAIL")
	await get_tree().process_frame
	get_tree().quit(0 if ok else 1)
