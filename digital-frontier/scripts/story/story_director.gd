class_name StoryDirector
extends Node
## Story progression foundation — mystery beats, world reactions, cutscene-lite events.
##
## Works with ChapterDirector: chapter handles spine title cards; StoryDirector
## plays cryptic Frontier mystery beats and stamps NPC/world memory.

signal beat_played(beat_id: StringName)

var _player: Node3D = null
var _hud: CanvasLayer = null
var _pending: Array[StringName] = []
var _busy: bool = false


func setup(player: Node3D, hud: CanvasLayer) -> void:
	_player = player
	_hud = hud
	if not EventBus.quest_completed.is_connected(_on_quest_completed):
		EventBus.quest_completed.connect(_on_quest_completed)
	if not EventBus.hostile_defeated.is_connected(_on_hostile_defeated):
		EventBus.hostile_defeated.connect(_on_hostile_defeated)
	if not EventBus.location_discovered.is_connected(_on_location_discovered):
		EventBus.location_discovered.connect(_on_location_discovered)
	if not EventBus.battle_ended.is_connected(_on_battle_ended):
		EventBus.battle_ended.connect(_on_battle_ended)
	## Opening mystery — once per save, after chapter intro settles.
	call_deferred("_maybe_open_whisper")


func _process(_delta: float) -> void:
	if _busy or _pending.is_empty():
		return
	if UIManager.has_open_modal():
		return
	var beat: StringName = _pending.pop_front()
	_play_beat(beat)


func queue_beat(beat_id: StringName) -> void:
	if bool(WorldManager.get_world_flag(StoryCatalog.flag_for_beat(beat_id), false)):
		return
	if _pending.has(beat_id):
		return
	_pending.append(beat_id)


func _maybe_open_whisper() -> void:
	if not bool(WorldManager.get_world_flag(&"title_chapter_intro_shown", false)):
		return
	queue_beat(&"frontier_whisper")


func _play_beat(beat_id: StringName) -> void:
	var lines := StoryCatalog.beat_lines(beat_id)
	if lines.is_empty():
		return
	_busy = true
	WorldManager.set_world_flag(StoryCatalog.flag_for_beat(beat_id), true)
	WorldManager.set_world_flag(&"story_mystery_depth", int(WorldManager.get_world_flag(&"story_mystery_depth", 0)) + 1)
	EventBus.story_beat_started.emit(beat_id)
	EventBus.ui_notification_requested.emit(StoryCatalog.beat_title(beat_id), 2.2)
	EventBus.sfx_play_requested.emit(&"quest", Vector3.ZERO)
	## Companion remembers the mystery.
	CreatureManager.record_memory(
		StringName("story_%s" % String(beat_id)),
		CompanionMemory.Kind.STORY,
		StoryCatalog.beat_title(beat_id),
		PackedStringArray(["story", String(beat_id)]),
	)
	NPCManager.broadcast_story_memory(beat_id)
	var host: Node = _hud if _hud else get_tree().current_scene
	if host == null:
		host = self
	var dlg := DeviceDialogue.present(host, &"story", StoryCatalog.beat_title(beat_id), lines)
	if dlg:
		dlg.finished.connect(func(_id: StringName) -> void: _finish_beat(beat_id), CONNECT_ONE_SHOT)
	else:
		_finish_beat(beat_id)


func _finish_beat(beat_id: StringName) -> void:
	_busy = false
	EventBus.story_beat_finished.emit(beat_id)
	beat_played.emit(beat_id)
	SaveManager.request_autosave()


func _on_quest_completed(quest_id: StringName) -> void:
	match quest_id:
		&"injured_signal":
			queue_beat(&"signal_injury")
			NPCManager.remember(&"meadow_researcher", &"helped_once", NpcMemory.Kind.HELPED, "Helped with an injured signal", PackedStringArray(["help"]))
			NPCManager.remember(&"meadow_researcher", &"index_help", NpcMemory.Kind.QUEST, "Shared creature notes", PackedStringArray(["quest"]))
		&"lost_trail":
			queue_beat(&"lost_scout_found")
			NPCManager.remember(&"lost_scout", &"rescued", NpcMemory.Kind.HELPED, "Found the lost scout", PackedStringArray(["rescue"]))
			NPCManager.remember(&"field_ranger", &"helped_once", NpcMemory.Kind.HELPED, "Brought a scout home", PackedStringArray(["help"]))
		&"village_shield":
			NPCManager.remember(&"park_villager", &"village_safe", NpcMemory.Kind.HELPED, "Protected the village", PackedStringArray(["protect"]))
			NPCManager.adjust_disposition(&"park_villager", 12.0)
		&"hollow_challenge":
			queue_beat(&"warden_dream")
			queue_beat(&"chapter_echo")
		&"pine_threat":
			queue_beat(&"alpha_shadow")
	NPCManager.note_quest_completed_for_cast(quest_id)


func _on_hostile_defeated(species_id: StringName, _pos: Vector3) -> void:
	if species_id == &"glitch_alpha":
		NPCManager.broadcast_memory(&"boss_alpha", NpcMemory.Kind.BOSS, "Player defeated Glitch Alpha", PackedStringArray(["boss", "alpha"]))
	elif species_id == &"hollow_warden":
		NPCManager.broadcast_memory(&"boss_warden", NpcMemory.Kind.BOSS, "Player defeated the Hollow Warden", PackedStringArray(["boss", "warden"]))


func _on_location_discovered(location_id: StringName) -> void:
	if location_id == &"pine_hollow":
		NPCManager.broadcast_memory(&"discovered_hollow", NpcMemory.Kind.DISCOVERY, "Player reached Pine Hollow", PackedStringArray(["discover"]))
	elif location_id == &"ranger_trail_cache":
		NPCManager.remember(&"field_ranger", &"trail_found", NpcMemory.Kind.DISCOVERY, "Found the ranger trail cache", PackedStringArray(["trail"]))


func _on_battle_ended(won: bool, enemy_id: StringName, _record: Dictionary) -> void:
	if won and enemy_id == &"hollow_warden":
		queue_beat(&"warden_dream")
