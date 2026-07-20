class_name ChapterDirector
extends Node
## Grassland vertical slice director — title cards, cast, mini-boss, chapter clear.

signal chapter_cleared

var _player: Node3D = null
var _hud: CanvasLayer = null
var _living: LivingWorldController = null
var _title_timer: float = -1.0
var _title_label: Label = null
var _boss_bar: ProgressBar = null
var _boss_label: Label = null
var _cleared: bool = false


func setup(player: Node3D, living: LivingWorldController, hud: CanvasLayer) -> void:
	_player = player
	_living = living
	_hud = hud
	_spawn_cast()
	_spawn_mini_boss()
	_spawn_curiosity()
	_build_overlay()
	if not bool(WorldManager.get_world_flag(&"title_chapter_intro_shown", false)):
		WorldManager.set_world_flag(&"title_chapter_intro_shown", true)
		_show_title("GRASSLAND CHAPTER", "Pleasant Park · First Expedition")
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.hostile_defeated.connect(_on_hostile_defeated)
	## Safe hub checkpoint for deaths.
	WorldManager.set_player_checkpoint(GrasslandLayout.PLEASANT_PARK + Vector3(0.0, 0.15, 18.0))
	WorldManager.set_world_flag(&"safe_hub_spawn", true)


func _process(delta: float) -> void:
	if _title_timer >= 0.0:
		_title_timer -= delta
		if _title_timer <= 0.0 and _title_label:
			_title_label.visible = false
	_update_boss_bar()


func _spawn_cast() -> void:
	if _living == null or _player == null:
		return
	var npcs_root := _living.get_node_or_null("WorldNpcs") as Node3D
	if npcs_root == null:
		return
	## Field Ranger north of park (main spine). Researcher east lawn (Index / wildlife tips).
	_spawn_fixed_npc(npcs_root, LivingWorldCatalog.grassland_npcs()[0], GrasslandLayout.PLEASANT_PARK + Vector3(-8, 0.15, 28))
	_spawn_fixed_npc(npcs_root, LivingWorldCatalog.grassland_npcs()[1], GrasslandLayout.PLEASANT_PARK + Vector3(14, 0.15, -12))


func _spawn_fixed_npc(parent: Node3D, def: Dictionary, pos: Vector3) -> void:
	for child in parent.get_children():
		if child is WorldNpcActor and (child as WorldNpcActor).npc_id == def.get("id", &""):
			var existing := child as WorldNpcActor
			existing.global_position = pos
			existing.move_speed = 0.0  ## Pin chapter cast so quest targets stay findable.
			return
	var actor := WorldNpcActor.new()
	actor.name = "ChapterNpc_%s" % String(def.get("id", "x"))
	parent.add_child(actor)
	actor.setup(def, _player, pos)
	actor.move_speed = 0.0


func _spawn_curiosity() -> void:
	## Trail crumbs reward players who leave the hub toward Pine Hollow.
	if _living == null:
		return
	var root := _living.get_node_or_null("Hostiles") as Node3D
	if root == null:
		root = _living
	var mid := GrasslandLayout.PLEASANT_PARK.lerp(GrasslandLayout.LANDMARK_PINE_HOLLOW, 0.28)
	_add_lore_marker(
		root,
		&"ranger_trail_cache",
		"Ranger Trail Cache",
		mid + Vector3(-6, 0.2, 4),
		14,
		"A ranger left supplies: ‘Alpha nests ahead — Y when close. Salve recommended.’",
	)
	var near_hollow := GrasslandLayout.PLEASANT_PARK.lerp(GrasslandLayout.LANDMARK_PINE_HOLLOW, 0.72)
	_add_lore_marker(
		root,
		&"hollow_warning_stone",
		"Hollow Warning Stone",
		near_hollow + Vector3(5, 0.2, -3),
		18,
		"Carved warning: ‘The Warden dreams in roots. Wake it only when ready.’",
	)


func _add_lore_marker(parent: Node3D, loc_id: StringName, loc_name: String, pos: Vector3, bits: int, message: String) -> void:
	if parent.get_node_or_null("Lore_%s" % String(loc_id)) != null:
		return
	var d := DiscoverableInteractable.new()
	d.name = "Lore_%s" % String(loc_id)
	d.location_id = loc_id
	d.location_name = loc_name
	d.discover_message = message
	d.bits_reward = bits
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 2.0, 2.0)
	shape.shape = box
	d.add_child(shape)
	StylizedMesh.add_box(d, Vector3(0.7, 0.9, 0.15), Color(0.45, 0.38, 0.28), Vector3(0, 0.5, 0), "Stone", false, 0.75)
	StylizedMesh.add_sphere(d, 0.12, WorldPalette.UI_CYAN, Vector3(0, 1.05, 0.12), "Glow", 8, 6, 0.5)
	parent.add_child(d)
	d.global_position = pos


func _spawn_mini_boss() -> void:
	if bool(WorldManager.get_world_flag(&"mini_boss_glitch_alpha_down", false)):
		return
	if _living == null or _player == null:
		return
	var hostiles := _living.get_node_or_null("Hostiles") as Node3D
	if hostiles == null:
		return
	var boss := MiniBossActor.new()
	boss.name = "GlitchAlpha"
	hostiles.add_child(boss)
	var pos := GrasslandLayout.PLEASANT_PARK.lerp(GrasslandLayout.LANDMARK_PINE_HOLLOW, 0.42) + Vector3(12, 0.15, 8)
	boss.setup(_player, pos)


func _build_overlay() -> void:
	if _hud == null:
		return
	_title_label = Label.new()
	_title_label.name = "ChapterTitle"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.anchor_left = 0.1
	_title_label.anchor_right = 0.9
	_title_label.anchor_top = 0.18
	_title_label.anchor_bottom = 0.28
	_title_label.visible = false
	DFStyle.apply_label_cyan(_title_label, 28)
	_hud.add_child(_title_label)

	_boss_label = Label.new()
	_boss_label.name = "BossLabel"
	_boss_label.visible = false
	_boss_label.anchor_left = 0.2
	_boss_label.anchor_right = 0.8
	_boss_label.anchor_top = 0.06
	_boss_label.anchor_bottom = 0.1
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DFStyle.apply_label_accent(_boss_label, DFStyle.FONT_BODY)
	_hud.add_child(_boss_label)

	_boss_bar = ProgressBar.new()
	_boss_bar.name = "BossHP"
	_boss_bar.visible = false
	_boss_bar.anchor_left = 0.2
	_boss_bar.anchor_right = 0.8
	_boss_bar.anchor_top = 0.1
	_boss_bar.anchor_bottom = 0.125
	_boss_bar.show_percentage = false
	DFStyle.apply_progress(_boss_bar, WorldPalette.UI_DANGER)
	_hud.add_child(_boss_bar)


func _show_title(main: String, sub: String) -> void:
	if _title_label == null:
		return
	_title_label.text = "%s\n%s" % [main, sub]
	_title_label.visible = true
	_title_timer = 3.2
	EventBus.sfx_play_requested.emit(&"quest", Vector3.ZERO)


func _update_boss_bar() -> void:
	if _boss_bar == null or _player == null:
		return
	var target: Node3D = null
	var label := ""
	var ratio := 0.0
	for node in get_tree().get_nodes_in_group(RegionBossActor.GROUP):
		if node is RegionBossActor and is_instance_valid(node):
			var b := node as RegionBossActor
			if _player.global_position.distance_to(b.global_position) < 32.0 and b.hp > 0.0:
				target = b
				label = b.display_name
				ratio = b.hp / maxf(b.max_hp, 1.0)
				break
	if target == null:
		for node2 in get_tree().get_nodes_in_group(MiniBossActor.GROUP):
			if node2 is MiniBossActor and is_instance_valid(node2):
				var m := node2 as MiniBossActor
				if _player.global_position.distance_to(m.global_position) < 26.0 and m.hp > 0.0:
					target = m
					label = m.display_name
					ratio = m.hp / maxf(m.max_hp, 1.0)
					break
	if target == null:
		_boss_bar.visible = false
		_boss_label.visible = false
		return
	_boss_bar.visible = true
	_boss_label.visible = true
	_boss_label.text = "◆ %s" % label
	_boss_bar.max_value = 1.0
	_boss_bar.value = ratio


func _on_quest_completed(quest_id: StringName) -> void:
	if quest_id == &"first_steps":
		_show_title("QUEST COMPLETE", "Talk to the Field Ranger")
	elif quest_id == &"grassland_call":
		_show_title("THREAT MARKED", "Defeat Glitch Alpha")
	elif quest_id == &"pine_threat":
		_show_title("PATH OPEN", "Challenge Pine Hollow")
	elif quest_id == &"hollow_challenge":
		_clear_chapter()


func _on_hostile_defeated(species_id: StringName, _pos: Vector3) -> void:
	if species_id == &"hollow_warden" and not _cleared:
		if QuestManager.is_quest_completed(&"hollow_challenge"):
			_clear_chapter()


func _clear_chapter() -> void:
	if _cleared:
		return
	_cleared = true
	WorldManager.set_world_flag(&"chapter_grassland_cleared", true)
	_show_title("CHAPTER ONE CLEAR", "Grassland secured · Rest at Home")
	EventBus.ui_notification_requested.emit("Vertical slice complete — save & celebrate at Home!", 4.0)
	EventBus.sfx_play_requested.emit(&"achievement", Vector3.ZERO)
	InventoryManager.add_bits(100, true, "Chapter clear bonus")
	CreatureManager.grant_adventure_experience(30)
	chapter_cleared.emit()
	SaveManager.request_autosave()
