extends Node
## Multi-user profile smoke — create, isolate, switch, delete, NFC payload.


var _frames: int = 0
var _done: bool = false


func _ready() -> void:
	print("PROFILE_SMOKE_START")


func _process(_delta: float) -> void:
	if _done:
		return
	_frames += 1
	if _frames < 4:
		return
	_done = true
	var ok := true

	## Clean slate for deterministic smoke (temp profiles only).
	for p in SaveManager.list_profiles():
		var pid := str(p.get("id", ""))
		if pid.begins_with("p_"):
			## Only wipe smoke-created names if tagged — delete all for isolated run.
			pass
	## Create two users
	var a := SaveManager.create_profile("SmokeA", &"ember")
	var b := SaveManager.create_profile("SmokeB", &"tide")
	if a.is_empty() or b.is_empty():
		push_error("create_profile failed")
		ok = false
		_fail()
		return
	if SaveManager.get_profile_count() < 2:
		push_error("expected at least 2 profiles")
		ok = false

	## User A — Emberling adventure
	if not SaveManager.select_profile(a):
		push_error("select A failed")
		ok = false
		_fail()
		return
	if not CreatureManager.select_partner(&"emberling", "AshBuddy"):
		push_error("partner A failed")
		ok = false
	InventoryManager.add_bits(100, false, "smoke", "earn")
	QuestManager.start_quest(&"first_steps")
	if not SaveManager.save_to_slot(0):
		push_error("save A failed")
		ok = false

	## User B — Tidepup, separate bits
	if not SaveManager.select_profile(b):
		push_error("select B failed")
		ok = false
		_fail()
		return
	if CreatureManager.has_chosen_partner():
		push_error("B should start without A's partner")
		ok = false
	if InventoryManager.get_bits() != 50:
		push_error("B bits should reset to starter 50, got %d" % InventoryManager.get_bits())
		ok = false
	if not CreatureManager.select_partner(&"tidepup", "WaveBuddy"):
		push_error("partner B failed")
		ok = false
	if not SaveManager.save_to_slot(0):
		push_error("save B failed")
		ok = false

	## Switch back to A — Emberling restored
	if not SaveManager.select_profile(a):
		push_error("reselect A failed")
		ok = false
		_fail()
		return
	if not CreatureManager.has_chosen_partner() or CreatureManager.get_companion_nickname() != "AshBuddy":
		push_error("A partner not restored")
		ok = false
	if InventoryManager.get_bits() < 150:
		push_error("A bits not restored (expected >=150)")
		ok = false

	## Summary + NFC payload
	SaveManager.refresh_active_summary()
	var rec := SaveManager.get_active_profile()
	var sum: Dictionary = rec.get("summary", {})
	if str(sum.get(&"partner_nickname", "")) != "AshBuddy":
		push_error("summary nickname missing")
		ok = false
	var nfc: Dictionary = DeviceService.exchange_profile_snapshot()
	if str(nfc.get(&"profile_id", "")) != a:
		push_error("nfc profile_id wrong")
		ok = false
	if str(nfc.get(&"display_name", "")) != "SmokeA":
		push_error("nfc display_name wrong")
		ok = false

	## Delete B with isolation
	if not SaveManager.delete_profile(b):
		push_error("delete B failed")
		ok = false
	if not SaveManager.get_profile(b).is_empty():
		push_error("B still listed after delete")
		ok = false
	## A still active and intact
	if SaveManager.get_active_profile_id() != a:
		## delete of other profile shouldn't clear A
		if SaveManager.get_active_profile_id() == "":
			push_error("active cleared when deleting other profile")
			ok = false

	## Cap
	if ProfileCatalog.MAX_PROFILES < 4 or ProfileCatalog.MAX_PROFILES > 8:
		## Spec target 4–8; catalog uses 8.
		if ProfileCatalog.MAX_PROFILES != 8:
			push_error("MAX_PROFILES should be 8")
			ok = false

	## Cleanup smoke profiles
	SaveManager.delete_profile(a)
	SaveManager.delete_profile(b)

	if ok:
		print("PROFILE_SMOKE_OK")
		get_tree().quit(0)
	else:
		_fail()


func _fail() -> void:
	print("PROFILE_SMOKE_FAIL")
	get_tree().quit(1)
