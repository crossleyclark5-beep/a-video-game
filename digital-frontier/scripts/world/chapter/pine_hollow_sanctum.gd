class_name PineHollowSanctum
extends Node3D
## First major adventure location — short outdoor sanctum at Pine Hollow.
## Root gate → seal pylons → Warden arena. No new biome; deepens existing landmark.


const GROUP := &"pine_hollow_sanctum"

var _gate_barrier: Node3D = null
var _gate_open: bool = false
var _seals_lit: int = 0


func build() -> void:
	name = "PineHollowSanctum"
	position = GrasslandLayout.LANDMARK_PINE_HOLLOW
	add_to_group(GROUP)
	_build_approach()
	_build_gate()
	_build_seals()
	_build_arena()
	_build_lore()
	if bool(WorldManager.get_world_flag(&"hollow_root_gate_open", false)):
		_open_gate(false)


func _build_approach() -> void:
	## Southern approach corridor — root walls funnel the player.
	var approach := Node3D.new()
	approach.name = "Approach"
	add_child(approach)
	StylizedMesh.add_box(approach, Vector3(10, 0.08, 18), WorldPalette.DIRT.darkened(0.1), Vector3(0, 0.04, -22), "Path", false, 1.0, &"dirt")
	for i in 5:
		var z := -30.0 + float(i) * 3.5
		StylizedMesh.add_box(approach, Vector3(1.2, 2.2, 1.2), WorldPalette.WOOD.darkened(0.15), Vector3(-5.5, 1.1, z), "RootWallL_%d" % i, false, 1.0, &"wood")
		StylizedMesh.add_box(approach, Vector3(1.2, 2.2, 1.2), WorldPalette.WOOD.darkened(0.15), Vector3(5.5, 1.1, z), "RootWallR_%d" % i, false, 1.0, &"wood")
	RegionPropKit.add_discoverable(
		approach,
		&"hollow_approach",
		"Hollow Approach",
		Vector3(0, 0.5, -28),
		10,
		"Root walls tighten. Something old listens beyond the gate.",
	)


func _build_gate() -> void:
	var gate := Node3D.new()
	gate.name = "RootGate"
	add_child(gate)
	StylizedMesh.add_box(gate, Vector3(3.5, 3.5, 1.2), WorldPalette.WOOD.darkened(0.25), Vector3(0, 1.7, -12), "Arch", false, 1.0, &"wood")
	StylizedMesh.add_box(gate, Vector3(1.0, 4.0, 1.0), WorldPalette.LEAF_DARK, Vector3(-2.2, 2.0, -12), "PillarL", false, 1.0, &"leaf")
	StylizedMesh.add_box(gate, Vector3(1.0, 4.0, 1.0), WorldPalette.LEAF_DARK, Vector3(2.2, 2.0, -12), "PillarR", false, 1.0, &"leaf")
	_gate_barrier = Node3D.new()
	_gate_barrier.name = "Barrier"
	gate.add_child(_gate_barrier)
	StylizedMesh.add_box(_gate_barrier, Vector3(4.2, 3.2, 0.6), Color(0.35, 0.55, 0.4, 1.0), Vector3(0, 1.6, -12), "Vines", false, 0.85, &"leaf")
	StylizedMesh.add_sphere(_gate_barrier, 0.35, WorldPalette.UI_PURPLE, Vector3(0, 2.4, -11.5), "SealOrb", 10, 8, 0.7)

	var interact := HollowGateInteractable.new()
	interact.name = "GateInteract"
	interact.sanctum = self
	gate.add_child(interact)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.5, 3.0, 2.5)
	shape.shape = box
	shape.position = Vector3(0, 1.5, -12)
	interact.add_child(shape)


func _build_seals() -> void:
	var seals := Node3D.new()
	seals.name = "Seals"
	add_child(seals)
	_add_seal(seals, &"hollow_seal_west", "West Root Seal", Vector3(-8, 0, -2), 0)
	_add_seal(seals, &"hollow_seal_east", "East Root Seal", Vector3(8, 0, 3), 1)


func _add_seal(parent: Node3D, loc_id: StringName, loc_name: String, pos: Vector3, idx: int) -> void:
	var node := Node3D.new()
	node.name = "Seal_%d" % idx
	node.position = pos
	parent.add_child(node)
	StylizedMesh.add_box(node, Vector3(1.4, 0.4, 1.4), WorldPalette.CURB, Vector3(0, 0.2, 0), "Base", false, 1.0, &"stone")
	StylizedMesh.add_box(node, Vector3(0.5, 2.0, 0.5), WorldPalette.WOOD, Vector3(0, 1.2, 0), "Spire", false, 1.0, &"wood")
	var glow_col := WorldPalette.UI_CYAN if bool(WorldManager.get_world_flag(StringName("seal_%s" % String(loc_id)), false)) else WorldPalette.UI_MUTED
	StylizedMesh.add_sphere(node, 0.28, glow_col, Vector3(0, 2.3, 0), "Glow", 8, 6, 0.6)
	var d := HollowSealInteractable.new()
	d.name = "SealInteract"
	d.seal_id = loc_id
	d.seal_name = loc_name
	d.sanctum = self
	d.prompt_verb = "Activate"
	node.add_child(d)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.6
	shape.shape = sphere
	shape.position = Vector3(0, 1.0, 0)
	d.add_child(shape)
	if bool(WorldManager.get_world_flag(StringName("seal_%s" % String(loc_id)), false)):
		_seals_lit += 1


func _build_arena() -> void:
	var arena := Node3D.new()
	arena.name = "Arena"
	add_child(arena)
	StylizedMesh.add_box(arena, Vector3(22, 0.06, 22), WorldPalette.GRASS_DARK, Vector3(0, 0.03, 8), "ArenaFloor", false, 1.0, &"grass")
	for i in 8:
		var ang := float(i) * TAU / 8.0
		var p := Vector3(cos(ang) * 11.0, 0, 8.0 + sin(ang) * 11.0)
		StylizedMesh.add_box(arena, Vector3(1.0, 1.6, 1.0), WorldPalette.WOOD.darkened(0.2), p + Vector3(0, 0.8, 0), "Ring_%d" % i, false, 1.0, &"wood")
	RegionPropKit.build_chest(arena, "SanctumChest", Vector3(-3, 0, 14), ChestInteractable.Rarity.RARE, 40.0, "Sanctum cache")


func _build_lore() -> void:
	var plaque := DiscoverableInteractable.new()
	plaque.name = "HollowLorePlaque"
	plaque.location_id = &"hollow_lore_plaque"
	plaque.location_name = "Rootbound Plaque"
	plaque.discover_message = "‘The Warden is not a monster. It is a lock. Who holds the key?’"
	plaque.bits_reward = 20
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 2.0, 2.0)
	shape.shape = box
	shape.position = Vector3(0, 0.8, 0)
	plaque.add_child(shape)
	StylizedMesh.add_box(plaque, Vector3(1.2, 1.1, 0.2), Color(0.4, 0.35, 0.28), Vector3(0, 0.55, 0), "Plaque", false, 0.8)
	StylizedMesh.add_sphere(plaque, 0.1, WorldPalette.UI_GOLD, Vector3(0, 1.15, 0.15), "Glow", 6, 6, 0.5)
	add_child(plaque)
	plaque.position = Vector3(0, 0, 0)


func try_open_gate(from_player: bool = true) -> bool:
	if _gate_open:
		return true
	if not bool(WorldManager.get_world_flag(&"mini_boss_glitch_alpha_down", false)):
		if from_player:
			var host := get_tree().current_scene if get_tree() else self
			DeviceDialogue.present(
				host,
				&"story",
				"Root Gate",
				PackedStringArray([
					"Living vines seal the Hollow.",
					"They won’t yield until Glitch Alpha falls on the trail.",
				]),
			)
		return false
	_open_gate(from_player)
	return true


func _open_gate(notify: bool) -> void:
	_gate_open = true
	WorldManager.set_world_flag(&"hollow_root_gate_open", true)
	if _gate_barrier and is_instance_valid(_gate_barrier):
		_gate_barrier.visible = false
	if notify:
		EventBus.ui_notification_requested.emit("Root Gate opens — the sanctum awaits.", 2.8)
		EventBus.sfx_play_requested.emit(&"quest", global_position)
	QuestManager.notify_objective(&"discover", &"hollow_root_gate", 1)
	EventBus.location_discovered.emit(&"hollow_root_gate")


func on_seal_activated(seal_id: StringName) -> void:
	var flag := StringName("seal_%s" % String(seal_id))
	if bool(WorldManager.get_world_flag(flag, false)):
		return
	WorldManager.set_world_flag(flag, true)
	_seals_lit += 1
	EventBus.sfx_play_requested.emit(&"ui_confirm", global_position)
	EventBus.ui_notification_requested.emit("Root seal lit (%d/2)" % mini(_seals_lit, 2), 2.0)
	QuestManager.notify_objective(&"discover", seal_id, 1)
	EventBus.location_discovered.emit(seal_id)
	if _seals_lit >= 2:
		WorldManager.set_world_flag(&"hollow_seals_complete", true)
		EventBus.ui_notification_requested.emit("Both seals burn — the Warden stirs.", 3.0)
		EventBus.sfx_play_requested.emit(&"battle_start", global_position)
		QuestManager.notify_objective(&"discover", &"hollow_seals_complete", 1)
