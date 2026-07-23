extends Node
## Probe Adventure Mode stability: launch, spawn, move, HUD, save, reload.


var _frames: int = 0
var _phase: int = 0
var _world: Node = null
var _ok: bool = true
var _errors: PackedStringArray = PackedStringArray()
var _baseline_nodes: int = 0


func _ready() -> void:
	print("ADVENTURE_STABILITY_PROBE_START")
	## Profile required for save slots (select before partner — select resets managers).
	if SaveManager.get_active_profile_id() == "":
		var pid := SaveManager.create_profile("StabilityProbe", &"ember")
		if pid == "":
			_fail("create_profile failed")
			_finish_now()
			return
		if not SaveManager.select_profile(pid):
			_fail("select_profile failed")
			_finish_now()
			return
	if not CreatureManager.has_chosen_partner():
		var opts := CreatureManager.get_starter_options()
		print("starter_options=", opts.size())
		if opts.is_empty():
			_fail("no starter options")
			_finish_now()
			return
		var sid: StringName = opts[0].id
		print("selecting partner ", sid)
		if not CreatureManager.select_partner(sid, "Probe"):
			_fail("select_partner failed")
			_finish_now()
			return
	call_deferred("_enter_world")


func _enter_world() -> void:
	var packed: PackedScene = load("res://scenes/world/game_world.tscn") as PackedScene
	if packed == null:
		_fail("missing game_world")
		_finish_now()
		return
	_world = packed.instantiate()
	add_child(_world)
	_phase = 1
	print("world instantiated")


func _process(_delta: float) -> void:
	if _phase == 0:
		return
	_frames += 1
	if _frames == 5:
		_check_spawn()
	elif _frames == 30:
		_simulate_move()
	elif _frames == 90:
		_open_menus()
	elif _frames == 150:
		_try_save_reload()
	elif _frames == 280:
		_finish()


func _check_spawn() -> void:
	var player := _world.find_child("Player", true, false)
	if player == null:
		_fail("player missing")
		return
	print("player at ", player.global_position)
	if _world.find_child("CameraRig", true, false) == null:
		_fail("camera missing")
	if _world.find_child("LivingWorld", true, false) == null:
		_fail("LivingWorld missing")
	var companion := _world.find_child("AdventureCompanion", true, false)
	if companion == null:
		_fail("companion missing")
	else:
		print("companion ok children=", companion.get_child_count())
	_baseline_nodes = _count_nodes(_world)
	print("world_node_count=", _baseline_nodes)
	if _baseline_nodes > 10000:
		_fail("node budget too high (%d)" % _baseline_nodes)


func _simulate_move() -> void:
	var player := _world.find_child("Player", true, false) as CharacterBody3D
	if player == null:
		_fail("player gone")
		return
	player.velocity = Vector3(4, 0, 2)
	player.move_and_slide()
	print("moved to ", player.global_position)
	## Interact prompt path
	if player.has_method("try_interact"):
		player.call("try_interact")


func _open_menus() -> void:
	var hud := _world.find_child("AdventureDeviceHud", true, false)
	if hud == null:
		_fail("HUD missing")
		return
	print("HUD present")
	var sheet := DFFormat.creature_index_sheet()
	if sheet.is_empty():
		_fail("empty index sheet")
	print("index sheet len=", sheet.length())


func _try_save_reload() -> void:
	print("saving...")
	var saved: bool = SaveManager.save_to_slot(GameConstants.AUTOSAVE_SLOT)
	print("save_to_slot=", saved)
	if not saved:
		_fail("save failed")
	WorldManager.set_player_checkpoint(Vector3(5, 0.15, 8))
	var packed: PackedScene = load("res://scenes/world/game_world.tscn") as PackedScene
	var world2: Node = packed.instantiate()
	_world.queue_free()
	_world = world2
	add_child(_world)
	print("reloaded world")


func _finish() -> void:
	var player := _world.find_child("Player", true, false)
	if player == null:
		_fail("player missing after reload")
	else:
		print("reload spawn ", player.global_position)
	print("ADVENTURE_STABILITY_PROBE_" + ("OK" if _ok else "FAIL"))
	for e in _errors:
		print("ERR:", e)
	get_tree().quit(0 if _ok else 1)


func _finish_now() -> void:
	print("ADVENTURE_STABILITY_PROBE_" + ("OK" if _ok else "FAIL"))
	for e in _errors:
		print("ERR:", e)
	get_tree().quit(0 if _ok else 1)


func _fail(msg: String) -> void:
	_ok = false
	_errors.append(msg)
	push_error(msg)


func _count_nodes(n: Node) -> int:
	var c: int = 1
	for ch in n.get_children():
		c += _count_nodes(ch)
	return c
