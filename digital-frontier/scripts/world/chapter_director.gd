class_name ChapterDirector
extends Node
## First Adventure Chapter director — opening, guidance, sanctum, clear, evolution.


signal chapter_cleared

var _player: Node3D = null
var _hud: CanvasLayer = null
var _living: LivingWorldController = null
var _title_timer: float = -1.0
var _title_label: Label = null
var _subtitle_label: Label = null
var _boss_bar: ProgressBar = null
var _boss_label: Label = null
var _cleared: bool = false
var _guidance: ChapterGuidance = null
var _sanctum: PineHollowSanctum = null
var _opening_done: bool = false
var _evo_pending: bool = false


func setup(player: Node3D, living: LivingWorldController, hud: CanvasLayer) -> void:
	_player = player
	_living = living
	_hud = hud
	_cleared = bool(WorldManager.get_world_flag(&"chapter_grassland_cleared", false))
	_spawn_cast()
	_spawn_town_life()
	_spawn_mini_boss()
	_spawn_curiosity()
	_spawn_sanctum()
	_spawn_guidance()
	_build_overlay()
	_maybe_opening()
	if not EventBus.quest_completed.is_connected(_on_quest_completed):
		EventBus.quest_completed.connect(_on_quest_completed)
	if not EventBus.hostile_defeated.is_connected(_on_hostile_defeated):
		EventBus.hostile_defeated.connect(_on_hostile_defeated)
	if not EventBus.quest_started.is_connected(_on_quest_started):
		EventBus.quest_started.connect(_on_quest_started)
	## Safe hub checkpoint for deaths.
	WorldManager.set_player_checkpoint(GrasslandLayout.PLEASANT_PARK + Vector3(0.0, 0.15, 18.0))
	WorldManager.set_world_flag(&"safe_hub_spawn", true)
	if _cleared:
		_apply_post_clear_world()


func _process(delta: float) -> void:
	if _title_timer >= 0.0:
		_title_timer -= delta
		if _title_timer <= 0.0:
			if _title_label:
				_title_label.visible = false
			if _subtitle_label:
				_subtitle_label.visible = false
	_update_boss_bar()
	if _evo_pending and not UIManager.has_open_modal():
		_evo_pending = false
		_play_evolution_ceremony()


func _maybe_opening() -> void:
	if bool(WorldManager.get_world_flag(&"title_chapter_intro_shown", false)):
		_opening_done = true
		return
	WorldManager.set_world_flag(&"title_chapter_intro_shown", true)
	_opening_done = true
	_show_title("CHAPTER ONE", "Grassland · The First Expedition")
	## Deferred mystery briefing — short, handheld.
	call_deferred("_present_opening_dialogue")


func _present_opening_dialogue() -> void:
	var nick := CreatureManager.get_companion_nickname() if CreatureManager.has_chosen_partner() else "your partner"
	var host: Node = _hud if _hud else get_tree().current_scene
	if host == null:
		host = self
	DeviceDialogue.present(
		host,
		&"story",
		"Field Unit",
		PackedStringArray([
			"Pleasant Park is quiet — but the Grassland isn’t sleeping.",
			"%s feels a pulse under the meadow. Something’s calling north." % nick,
			"Talk to the Park Guide. Learn the trail. Write the first chapter.",
		]),
	)
	EventBus.sfx_play_requested.emit(&"quest", Vector3.ZERO)


func _spawn_cast() -> void:
	if _living == null or _player == null:
		return
	var npcs_root := _living.get_node_or_null("WorldNpcs") as Node3D
	if npcs_root == null:
		return
	_spawn_fixed_npc(npcs_root, LivingWorldCatalog.grassland_npcs()[0], GrasslandLayout.PLEASANT_PARK + Vector3(-8, 0.15, 28))
	_spawn_fixed_npc(npcs_root, LivingWorldCatalog.grassland_npcs()[1], GrasslandLayout.PLEASANT_PARK + Vector3(14, 0.15, -12))
	_refresh_lost_scout(npcs_root)


func _refresh_lost_scout(npcs_root: Node3D = null) -> void:
	if _living == null or _player == null:
		return
	if npcs_root == null:
		npcs_root = _living.get_node_or_null("WorldNpcs") as Node3D
	if npcs_root == null:
		return
	var ready := (
		QuestManager.is_quest_completed(&"first_steps")
		or QuestManager.is_quest_active(&"grassland_call")
		or QuestManager.is_quest_completed(&"grassland_call")
	)
	if not ready:
		return
	var scout_def := LivingWorldCatalog.grassland_npcs()[4]
	var mid := GrasslandLayout.PLEASANT_PARK.lerp(GrasslandLayout.LANDMARK_PINE_HOLLOW, 0.35) + Vector3(-10, 0.15, 6)
	_spawn_fixed_npc(npcs_root, scout_def, mid)


func _spawn_town_life() -> void:
	## Extra living faces for Pleasant Park — schedules, not quest pins.
	if _living == null or _player == null:
		return
	var npcs_root := _living.get_node_or_null("WorldNpcs") as Node3D
	if npcs_root == null:
		return
	var kid := {
		"id": &"park_kid",
		"label": "Park Kid",
		"color": Color(0.95, 0.7, 0.4),
		"role": "villager",
		"schedule": "town_loop",
		"lines": PackedStringArray([
			"Race you to the gazebo!",
			"Mom says don’t pet Glitchmites. Duh.",
		]),
		"quest_offer": &"",
	}
	var elder := {
		"id": &"park_elder",
		"label": "Park Elder",
		"color": Color(0.6, 0.55, 0.7),
		"role": "villager",
		"schedule": "town_loop",
		"lines": PackedStringArray([
			"I’ve watched these pines for sixty seasons.",
			"When the Hollow goes quiet, listen harder.",
		]),
		"quest_offer": &"",
	}
	_spawn_roaming_npc(npcs_root, kid, GrasslandLayout.PLEASANT_PARK + Vector3(4, 0.15, -4))
	_spawn_roaming_npc(npcs_root, elder, GrasslandLayout.PLEASANT_PARK + Vector3(-12, 0.15, 6))
	## Celebration props after chapter clear.
	if _cleared:
		_spawn_celebration_banners(npcs_root)


func _spawn_roaming_npc(parent: Node3D, def: Dictionary, pos: Vector3) -> void:
	for child in parent.get_children():
		if child is WorldNpcActor and (child as WorldNpcActor).npc_id == def.get("id", &""):
			return
	var actor := WorldNpcActor.new()
	actor.name = "TownNpc_%s" % String(def.get("id", "x"))
	parent.add_child(actor)
	actor.setup(def, _player, pos)


func _spawn_celebration_banners(parent: Node3D) -> void:
	if parent.get_node_or_null("CelebrationBanners") != null:
		return
	var root := Node3D.new()
	root.name = "CelebrationBanners"
	parent.add_child(root)
	root.global_position = GrasslandLayout.PLEASANT_PARK
	StylizedMesh.add_box(root, Vector3(0.15, 3.0, 0.15), WorldPalette.WOOD, Vector3(-3, 1.5, 16), "PoleL")
	StylizedMesh.add_box(root, Vector3(0.15, 3.0, 0.15), WorldPalette.WOOD, Vector3(3, 1.5, 16), "PoleR")
	StylizedMesh.add_box(root, Vector3(6.0, 0.8, 0.1), WorldPalette.UI_GOLD, Vector3(0, 2.8, 16), "Banner")


func _spawn_fixed_npc(parent: Node3D, def: Dictionary, pos: Vector3) -> void:
	for child in parent.get_children():
		if child is WorldNpcActor and (child as WorldNpcActor).npc_id == def.get("id", &""):
			var existing := child as WorldNpcActor
			existing.global_position = pos
			existing.move_speed = 0.0
			existing.pinned = true
			return
	var actor := WorldNpcActor.new()
	actor.name = "ChapterNpc_%s" % String(def.get("id", "x"))
	parent.add_child(actor)
	actor.setup(def, _player, pos)
	actor.move_speed = 0.0
	actor.pinned = true


func _spawn_curiosity() -> void:
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
	## Prep sign near Fuel Stop — shop ritual guidance.
	_add_lore_marker(
		root,
		&"fuel_prep_sign",
		"Prep Notice",
		GrasslandLayout.PLEASANT_PARK + Vector3(38, 0.2, 2),
		8,
		"Fuel Stop notice: ‘Stock Field Salve before the north trail.’",
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
	shape.position = Vector3(0, 0.8, 0)
	d.add_child(shape)
	StylizedMesh.add_box(d, Vector3(0.7, 0.9, 0.15), Color(0.45, 0.38, 0.28), Vector3(0, 0.5, 0), "Stone", false, 0.75)
	StylizedMesh.add_sphere(d, 0.12, WorldPalette.UI_CYAN, Vector3(0, 1.05, 0.12), "Glow", 8, 6, 0.5)
	parent.add_child(d)
	d.global_position = pos


func _spawn_sanctum() -> void:
	if _living == null:
		return
	if _living.get_node_or_null("PineHollowSanctum") != null:
		return
	_sanctum = PineHollowSanctum.new()
	_living.add_child(_sanctum)
	_sanctum.build()


func _spawn_guidance() -> void:
	if _player == null:
		return
	_guidance = ChapterGuidance.new()
	_guidance.name = "ChapterGuidance"
	add_child(_guidance)
	_guidance.setup(_player)


func _spawn_mini_boss() -> void:
	if bool(WorldManager.get_world_flag(&"mini_boss_glitch_alpha_down", false)):
		return
	if _living == null or _player == null:
		return
	var hostiles := _living.get_node_or_null("Hostiles") as Node3D
	if hostiles == null:
		return
	if hostiles.get_node_or_null("GlitchAlpha") != null:
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
	_title_label.anchor_left = 0.08
	_title_label.anchor_right = 0.92
	_title_label.anchor_top = 0.14
	_title_label.anchor_bottom = 0.22
	_title_label.visible = false
	DFStyle.apply_label_cyan(_title_label, 30)
	_hud.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.name = "ChapterSubtitle"
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.anchor_left = 0.1
	_subtitle_label.anchor_right = 0.9
	_subtitle_label.anchor_top = 0.22
	_subtitle_label.anchor_bottom = 0.28
	_subtitle_label.visible = false
	DFStyle.apply_label_paper(_subtitle_label, DFStyle.FONT_BODY)
	_hud.add_child(_subtitle_label)

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
	_title_label.text = main
	_title_label.visible = true
	if _subtitle_label:
		_subtitle_label.text = sub
		_subtitle_label.visible = true
	_title_timer = 3.6
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


func _on_quest_started(quest_id: StringName) -> void:
	if quest_id == &"grassland_call" or quest_id == &"lost_trail":
		_refresh_lost_scout()
	if _guidance:
		_guidance.refresh_target()


func _on_quest_completed(quest_id: StringName) -> void:
	_refresh_lost_scout()
	if _guidance:
		_guidance.refresh_target()
	match quest_id:
		&"first_steps":
			_show_title("FIRST STEPS CLEAR", "Meet the Field Ranger north of town")
			NPCManager.adjust_disposition(&"park_guide", 10.0)
		&"grassland_call":
			_show_title("CALL ANSWERED", "Check the trail cache · Stock salve · Hunt Alpha")
		&"pine_threat":
			_show_title("ALPHA FALLEN", "The Root Gate will open at Pine Hollow")
			if _sanctum:
				_sanctum.try_open_gate(false)
		&"hollow_challenge":
			_clear_chapter()


func _on_hostile_defeated(species_id: StringName, _pos: Vector3) -> void:
	if species_id == &"glitch_alpha":
		_show_title("TRAIL SECURED", "Pine Hollow’s gate stirs")
		if _sanctum:
			_sanctum.try_open_gate(false)
	elif species_id == &"hollow_warden" and not _cleared:
		if QuestManager.is_quest_completed(&"hollow_challenge"):
			_clear_chapter()


func _clear_chapter() -> void:
	if _cleared:
		return
	_cleared = true
	WorldManager.set_world_flag(&"chapter_grassland_cleared", true)
	WorldManager.set_world_flag(&"town_celebration", true)
	_show_title("CHAPTER ONE CLEAR", "The Grassland breathes · Your partner stirs")
	EventBus.ui_notification_requested.emit("Chapter One complete — a growth moment approaches!", 4.0)
	EventBus.sfx_play_requested.emit(&"achievement", Vector3.ZERO)
	InventoryManager.add_bits(100, true, "Chapter clear bonus")
	CreatureManager.grant_adventure_experience(40)
	CreatureManager.grant_adventure_bond(12.0, "Shared the first chapter victory")
	## Ensure friendship/level for chapter evolution path.
	var inst := CreatureManager.get_active_instance()
	if inst:
		inst.friendship = maxf(inst.friendship, 40.0)
		if inst.level < 5:
			CreatureManager.grant_adventure_experience(80)
	NPCManager.broadcast_memory(&"chapter_clear", NpcMemory.Kind.STORY, "Player cleared Chapter One", PackedStringArray(["chapter"]))
	NPCManager.adjust_disposition(&"park_guide", 15.0)
	NPCManager.adjust_disposition(&"field_ranger", 15.0)
	NPCManager.adjust_disposition(&"park_villager", 12.0)
	_apply_post_clear_world()
	_evo_pending = true
	chapter_cleared.emit()
	SaveManager.request_autosave()


func _apply_post_clear_world() -> void:
	## Town celebration + reputation flag for living world.
	WorldManager.set_world_flag(&"reputation_park_hero", true)
	if _living:
		var npcs := _living.get_node_or_null("WorldNpcs") as Node3D
		if npcs:
			_spawn_celebration_banners(npcs)


func _play_evolution_ceremony() -> void:
	if not CreatureManager.has_chosen_partner():
		return
	if CreatureManager.get_evolution_stage() >= 1:
		## Already evolved — still celebrate.
		_show_title("PARTNER BOND", "%s stands taller beside you" % CreatureManager.get_companion_nickname())
		return
	var host: Node = _hud if _hud else get_tree().current_scene
	if host == null:
		host = self
	var nick := CreatureManager.get_companion_nickname()
	var dlg := DeviceDialogue.present(
		host,
		&"story",
		"Growth Moment",
		PackedStringArray([
			"%s’s signal flares — the first chapter changed you both." % nick,
			"Hold still. This is what the Field Unit was built to witness.",
		]),
	)
	if dlg:
		dlg.finished.connect(func(_id: StringName) -> void: _finish_evolution(), CONNECT_ONE_SHOT)
	else:
		_finish_evolution()


func _finish_evolution() -> void:
	var result := CreatureManager.try_evolve(&"")
	## Prefer chapter path if available.
	if not bool(result.get("evolved", false)):
		## Force-check chapter-flagged paths by bumping availability.
		result = CreatureManager.try_evolve()
	if bool(result.get("evolved", false)):
		_show_title("EVOLUTION", "%s → %s" % [CreatureManager.get_companion_nickname(), str(result.get("name", "Partner"))])
		EventBus.sfx_play_requested.emit(&"evolve", Vector3.ZERO)
		CreatureManager.record_memory(
			&"chapter_one_evolution",
			CompanionMemory.Kind.EVOLUTION,
			"First chapter growth",
			PackedStringArray(["chapter", "evolution"]),
		)
	else:
		_show_title("READY TO GROW", "Return Home when %s is ready" % CreatureManager.get_companion_nickname())
		EventBus.ui_notification_requested.emit("Care at Home to finish the growth!", 3.0)
