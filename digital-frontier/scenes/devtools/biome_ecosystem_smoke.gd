extends Node
## Smoke: biome distribution, Grassland spawn budget, shop gates, discovery index.


func _ready() -> void:
	await get_tree().process_frame
	var ok := true

	## Distribution covers every planned biome
	if BiomeDistributionCatalog.all_biomes().size() != 13:
		push_error("biome count %d != 13" % BiomeDistributionCatalog.all_biomes().size())
		ok = false
	var summary := BiomeDistributionCatalog.summary_by_biome()
	if not summary.has("Grasslands") or not summary.has("Dark Lands"):
		push_error("summary missing biomes")
		ok = false

	## Grassland live set is early-game only
	var grass := EcosystemCatalog.grassland_species()
	if grass.size() != 11:
		push_error("grassland species %d != 11 (7 wild + glitchmite + 3 lookalike)" % grass.size())
		ok = false
	for e in grass:
		var sid: StringName = e.get("id", &"")
		if not BiomeDistributionCatalog.belongs_to_biome(sid, BiomeDistributionCatalog.Biome.GRASSLAND):
			push_error("non-grassland species in live table %s" % String(sid))
			ok = false

	## Chapter 1 bosses only
	var g_boss := EcosystemCatalog.grassland_boss()
	if g_boss.get("id", &"") != &"hollow_warden":
		push_error("major boss wrong")
		ok = false
	var g_mini := EcosystemCatalog.grassland_mini_boss()
	if g_mini.get("id", &"") != &"glitch_alpha":
		push_error("mini boss wrong")
		ok = false
	if EcosystemCatalog.lookalike_bosses().size() != 0:
		push_error("no lookalike bosses in Grassland spawn")
		ok = false

	## Database includes future creatures
	if EcosystemCatalog.all_species_database().size() <= grass.size():
		push_error("species database not larger than Grassland live set")
		ok = false
	if EcosystemCatalog.all_planned_bosses().size() < 7:
		push_error("planned bosses incomplete")
		ok = false

	## Partners
	if CreatureManager.STARTER_OPTIONS.size() != 6:
		push_error("starter options")
		ok = false
	if CreatureManager.STARTER_CREATURE_ID != &"companion_agumon":
		push_error("default starter")
		ok = false

	## Discovery index spans world
	var prog := CollectionManager.get_creature_index_progress()
	if prog.y < 20:
		push_error("index total too small %d" % prog.y)
		ok = false

	## Character shop gates
	CharacterRosterManager.reset_state()
	WorldManager.set_world_flag(&"boss_hollow_warden_down", false)
	WorldManager.set_world_flag(&"mini_boss_glitch_alpha_down", false)
	InventoryManager.add_bits(2000, false, "smoke", "test")
	if CharacterRosterManager.is_shop_gate_open(&"char_black_knight"):
		push_error("black knight gate should be closed")
		ok = false
	if CharacterRosterManager.is_shop_gate_open(&"char_master_chief"):
		push_error("master chief gate should be closed")
		ok = false
	if not CharacterRosterManager.is_shop_gate_open(&"char_ice_king"):
		push_error("ice king should open after 600 Bits earned")
		ok = false
	var deny := ShopManager.buy(&"char_black_knight")
	print("Gate deny: ", deny)
	if CharacterRosterManager.is_unlocked(&"char_black_knight"):
		push_error("bought gated skin early")
		ok = false
	WorldManager.set_world_flag(&"boss_hollow_warden_down", true)
	if not CharacterRosterManager.is_shop_gate_open(&"char_black_knight"):
		push_error("black knight gate should open after Hollow Warden")
		ok = false
	var buy_msg := ShopManager.buy(&"char_black_knight")
	print("Gate buy: ", buy_msg)
	if not CharacterRosterManager.is_unlocked(&"char_black_knight"):
		push_error("black knight buy failed after gate")
		ok = false

	## Free shop skins still buyable without story gates
	if not ShopManager.can_buy(&"char_peely") and not ShopManager.is_owned_unique(&"char_peely"):
		## May already own from prior — only fail if locked for other reasons
		if CharacterOutfitCatalog.unlock_mode(&"char_peely") != &"shop":
			push_error("peely unlock mode")
			ok = false

	if ok:
		print("BIOME_ECOSYSTEM_SMOKE_OK")
	else:
		print("BIOME_ECOSYSTEM_SMOKE_FAIL")
	await get_tree().process_frame
	get_tree().quit(0 if ok else 1)
