extends Node
## Smoke: Digimon-inspired DF creature look-alikes (companions / enemies / bosses).
## Grassland only hosts beginner lookalike foes — full roster stays in the database.


func _ready() -> void:
	await get_tree().process_frame
	var ok := true
	var root := Node3D.new()
	add_child(root)

	var all_ids := CreatureLookalikeCatalog.all_ids()
	if all_ids.size() != 27:
		push_error("expected 27 creatures, got %d" % all_ids.size())
		ok = false

	if CreatureLookalikeCatalog.companion_ids().size() != 6:
		push_error("companion count")
		ok = false
	if CreatureLookalikeCatalog.enemy_ids().size() != 15:
		push_error("enemy count")
		ok = false
	if CreatureLookalikeCatalog.boss_ids().size() != 6:
		push_error("boss count")
		ok = false

	for id in all_ids:
		var kit := CreatureLookalikeKit.build(root, id, 1.0)
		if kit == null:
			push_error("null kit %s" % String(id))
			ok = false
			continue
		var meshes := _count_meshes(kit)
		print("%s meshes=%d" % [String(id), meshes])
		if meshes < 6:
			push_error("%s sparse (%d)" % [String(id), meshes])
			ok = false

	## Companion data + visual profile
	for cid in CreatureLookalikeCatalog.companion_ids():
		var data: CreatureData = ResourceRegistry.get_creature(cid)
		if data == null:
			push_error("missing CreatureData %s" % String(cid))
			ok = false
			continue
		var cv := CompanionVisual.new()
		add_child(cv)
		cv.apply_from_creature(data, 0)
		await get_tree().process_frame
		if cv.get_child_count() < 1:
			push_error("companion visual empty %s" % String(cid))
			ok = false

	## Grassland starters = six lookalike partners only
	var starters := CreatureManager.get_starter_options()
	if starters.size() != 6:
		push_error("starter options %d != 6" % starters.size())
		ok = false

	## Only three beginner lookalike hostiles spawn live in Grassland
	var lookalike_hostile := 0
	for e in EcosystemCatalog.grassland_species():
		if bool(e.get("lookalike", false)):
			lookalike_hostile += 1
	if lookalike_hostile != 3:
		push_error("grassland lookalike hostiles %d != 3" % lookalike_hostile)
		ok = false

	## Full enemy roster remains in the species database (spawn_live false for later biomes)
	var db_lookalike := 0
	for e in EcosystemCatalog.all_species_database():
		if bool(e.get("lookalike", false)):
			db_lookalike += 1
	if db_lookalike < 15:
		push_error("database lookalike enemies %d < 15" % db_lookalike)
		ok = false

	## Lookalike bosses are biome-assigned — not flooded into Grassland spawn
	if EcosystemCatalog.lookalike_bosses().size() != 0:
		push_error("lookalike bosses must not spawn in Grassland")
		ok = false
	var planned := EcosystemCatalog.all_planned_bosses()
	if planned.size() < 7:
		push_error("planned bosses %d < 7 (hollow + 6 lookalike)" % planned.size())
		ok = false
	for bid in CreatureLookalikeCatalog.boss_ids():
		if ResourceRegistry.get_boss(bid) == null:
			push_error("missing BossData %s" % String(bid))
			ok = false
		if not BiomeDistributionCatalog.has_entry(bid):
			push_error("boss missing distribution %s" % String(bid))
			ok = false
		if BiomeDistributionCatalog.belongs_to_biome(bid, BiomeDistributionCatalog.Biome.GRASSLAND):
			push_error("lookalike boss wrongly in Grassland %s" % String(bid))
			ok = false

	## RegionBossActor lookalike path via future biome def
	var forest_bosses := EcosystemCatalog.bosses_for_biome(BiomeDistributionCatalog.Biome.FOREST)
	if forest_bosses.is_empty():
		push_error("forest boss missing")
		ok = false
	else:
		var boss := RegionBossActor.new()
		add_child(boss)
		boss.setup(forest_bosses[0], null, Vector3.ZERO)
		await get_tree().process_frame

	if ok:
		print("CREATURE_LOOKALIKE_SMOKE_OK")
	else:
		print("CREATURE_LOOKALIKE_SMOKE_FAIL")
	await get_tree().process_frame
	get_tree().quit(0 if ok else 1)


func _count_meshes(n: Node) -> int:
	var c := 0
	if n is MeshInstance3D:
		c += 1
	for ch in n.get_children():
		c += _count_meshes(ch)
	return c
