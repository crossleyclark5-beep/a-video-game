extends Node
## Smoke scene — run with: godot --path . res://scenes/devtools/smoke_shop_map.tscn


func _ready() -> void:
	await get_tree().process_frame
	var ok := true
	var checks: Array = [
		["Mere", GrasslandLayout.MIRROR_MERE, 4.5, 5.5],
		["Mile", GrasslandLayout.MARKET_MILE, 6.5, 7.5],
		["Grove", GrasslandLayout.GREASE_GROVE, 6.0, 7.5],
		["Salty", GrasslandLayout.SALTY_SPRINGS, 6.0, 7.5],
		["Reels", GrasslandLayout.RISKY_REELS, 9.5, 10.5],
		["Fields", GrasslandLayout.FATAL_FIELDS, 12.0, 13.5],
	]
	for c in checks:
		var d := GrasslandLayout.straight_distance(GrasslandLayout.PLEASANT_PARK, c[1])
		var m := GrasslandLayout.walk_minutes(d)
		print("POI %s dist=%.0f walk=%.2f min" % [c[0], d, m])
		if m < float(c[2]) or m > float(c[3]):
			print("FAIL distance out of band for ", c[0])
			ok = false

	var cat := ShopManager.get_catalog(ShopManager.SHOP_ID_HOME)
	print("Shop catalog size=", cat.size())
	if cat.size() < 10:
		print("FAIL catalog too small")
		ok = false
	for item in ShopManager.get_catalog(ShopManager.SHOP_ID_MILE):
		if item.shop_category == ItemData.ShopCategory.HOME:
			print("FAIL mile has home item ", item.id)
			ok = false

	InventoryManager.add_bits(100, false, "smoke", "test")
	var before := InventoryManager.get_bits()
	print("Buy: ", ShopManager.buy(&"food_berry_ration"), " bits=", InventoryManager.get_bits())
	if InventoryManager.get_bits() >= before:
		print("FAIL bits not spent")
		ok = false
	if not InventoryManager.has_item(&"food_berry_ration", 1):
		print("FAIL item not added")
		ok = false
	print("Use: ", ShopManager.use_item(&"food_berry_ration"))

	InventoryManager.add_bits(500, false, "smoke", "test")
	print(ShopManager.buy(&"accessory_compass_pin"))
	print(ShopManager.buy(&"accessory_compass_pin"))
	if ShopManager.can_buy(&"accessory_compass_pin"):
		print("FAIL unique still buyable")
		ok = false

	var world_root := Node3D.new()
	add_child(world_root)
	var result: Dictionary = GrasslandRegionBuilder.build(world_root)
	print("Build chests=", result.get(&"chests", []).size())
	if result.get(&"chests", []).is_empty():
		print("FAIL no chests")
		ok = false

	print("SMOKE ", "PASS" if ok else "FAIL")
	await get_tree().process_frame
	get_tree().quit(0 if ok else 1)
