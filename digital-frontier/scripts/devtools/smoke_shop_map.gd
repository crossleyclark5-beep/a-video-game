extends SceneTree
## Headless smoke: shop economy + hub-and-spoke distances + region build.
## Resolves autoloads via /root ( -s mode may not inject autoload identifiers at compile time).


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	var ok := true
	var shop: Node = root.get_node_or_null("ShopManager")
	var inv: Node = root.get_node_or_null("InventoryManager")
	if shop == null or inv == null:
		print("FAIL missing autoloads shop=", shop, " inv=", inv)
		quit(1)
		return

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

	var cat: Array = shop.call("get_catalog", &"field_unit_shop")
	print("Shop catalog size=", cat.size())
	if cat.size() < 10:
		print("FAIL catalog too small")
		ok = false
	var mile: Array = shop.call("get_catalog", &"market_mile_shop")
	for item in mile:
		var data: ItemData = item
		if data.shop_category == ItemData.ShopCategory.HOME:
			print("FAIL mile has home item ", data.id)
			ok = false

	inv.call("add_bits", 100, false, "smoke", "test")
	var before: int = inv.call("get_bits")
	var msg: String = shop.call("buy", &"food_berry_ration")
	print("Buy: ", msg, " bits=", inv.call("get_bits"))
	if int(inv.call("get_bits")) >= before:
		print("FAIL bits not spent")
		ok = false
	if not bool(inv.call("has_item", &"food_berry_ration", 1)):
		print("FAIL item not added")
		ok = false

	var use_msg: String = shop.call("use_item", &"food_berry_ration")
	print("Use: ", use_msg)

	inv.call("add_bits", 500, false, "smoke", "test")
	print(shop.call("buy", &"accessory_compass_pin"))
	print(shop.call("buy", &"accessory_compass_pin"))
	if bool(shop.call("can_buy", &"accessory_compass_pin")):
		print("FAIL unique still buyable")
		ok = false

	var world_root := Node3D.new()
	world_root.name = "SmokeRoot"
	root.add_child(world_root)
	var result: Dictionary = GrasslandRegionBuilder.build(world_root)
	print("Build chests=", result.get(&"chests", []).size(), " spawn=", result.get(&"player_spawn", Vector3.ZERO))
	if result.get(&"chests", []).is_empty():
		print("FAIL no chests")
		ok = false

	print("SMOKE ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
