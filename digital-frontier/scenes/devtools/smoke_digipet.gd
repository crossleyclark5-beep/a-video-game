extends Node
## Digi-pet smoke: partner select, care, battle helpers, LCD build.


func _ready() -> void:
	await get_tree().process_frame
	var ok := true
	if CreatureManager.has_chosen_partner():
		print("Partner already chosen: ", CreatureManager.get_companion_nickname())
	else:
		var opts := CreatureManager.get_starter_options()
		print("Starters=", opts.size())
		if opts.size() < 3:
			print("FAIL expected 3 starters")
			ok = false
		if not CreatureManager.select_partner(&"emberling"):
			print("FAIL select_partner")
			ok = false
	print("Partner=", CreatureManager.get_companion_nickname(), " id=", CreatureManager.get_companion_id())
	print("Feed: ", CreatureManager.feed())
	print("Heal: ", CreatureManager.heal())
	print("Interact: ", CreatureManager.interact())
	print("Train: ", CreatureManager.train())
	var link := DeviceService.begin_nfc_link()
	print("NFC: ", link)
	var snap: Dictionary = DeviceService.exchange_creature_snapshot()
	print("Snapshot species=", snap.get(&"species_id", ""))
	var lcd := PixelHabitatLcd.new()
	add_child(lcd)
	lcd.play_care(&"feed")
	await get_tree().create_timer(0.2).timeout
	print("Journal lines=", CollectionManager.get_journal_text().split("\n").size())
	print("SMOKE ", "PASS" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)
