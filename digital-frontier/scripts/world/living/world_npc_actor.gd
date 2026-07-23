class_name WorldNpcActor
extends Node3D
## Roaming world NPC — schedules, talk interactable, optional quest offer.

const GROUP := &"world_npcs"

var npc_id: StringName = &"villager"
var display_name: String = "Traveler"
var move_speed: float = 1.6
var quest_offer: StringName = &""
var role: int = NpcCatalog.Role.VILLAGER
var schedule_id: StringName = &"town_loop"
var pinned: bool = false  ## Chapter cast / story anchors

var _player: Node3D = null
var _home: Vector3 = Vector3.ZERO
var _target: Vector3 = Vector3.ZERO
var _visual: Node3D = null
var _talk: NpcTalkInteractable = null
var _state_timer: float = 0.0
var _waypoint_index: int = 0
var _rng := RandomNumberGenerator.new()
var _fallback_lines: PackedStringArray = PackedStringArray()
var _sheltering: bool = false
var _sleeping: bool = false
var _ai_detail: int = 2
var _last_slot: int = -1


func setup(def: Dictionary, player: Node3D, origin: Vector3) -> void:
	npc_id = def.get("id", &"villager")
	display_name = String(def.get("label", "Traveler"))
	quest_offer = StringName(str(def.get("quest_offer", "")))
	role = NpcCatalog.role_from_string(str(def.get("role", "villager")))
	schedule_id = StringName(str(def.get("schedule", NpcCatalog.default_schedule(role))))
	pinned = bool(def.get("pinned", false))
	_fallback_lines = def.get("lines", PackedStringArray(["Hello!"]))
	_player = player
	_home = origin
	global_position = origin
	_rng.seed = hash(String(npc_id)) + int(origin.z * 5.0)
	## Sync runtime role/schedule into NPCManager.
	var st := NPCManager.get_npc_state(npc_id)
	st[&"role"] = role
	st[&"schedule_id"] = String(schedule_id)
	_build_visual(def)
	_build_talk()
	_pick_target()
	add_to_group(GROUP)
	add_to_group(GameConstants.GROUP_NPCS)
	if not EventBus.day_phase_changed.is_connected(_on_phase_changed):
		EventBus.day_phase_changed.connect(_on_phase_changed)
	if not EventBus.weather_changed.is_connected(_on_weather_changed):
		EventBus.weather_changed.connect(_on_weather_changed)


func set_ai_detail(level: int) -> void:
	## 2 = full schedule, 1 = slower retarget, 0 = paused by controller.
	_ai_detail = clampi(level, 0, 2)


func current_activity() -> String:
	var slot := NpcSchedule.slot_from_phase(NPCManager.get_day_phase())
	if _sheltering:
		return "seeking shelter"
	if _sleeping:
		return "sleeping"
	return NpcSchedule.activity_label(schedule_id, slot)


func _on_phase_changed(_phase: int) -> void:
	_state_timer = 0.1
	_pick_target()


func _on_weather_changed(_weather: StringName) -> void:
	_state_timer = 0.1
	_pick_target()


func _build_visual(def: Dictionary) -> void:
	var col: Color = def.get("color", NpcCatalog.role_color(role))
	var accent := NpcCatalog.role_color(role)
	## Prefer curated character library when imported — higher-detail humans vs world boxes.
	var force_proc := bool(def.get("procedural_visual", false))
	if not force_proc and CharacterKit.is_available():
		var lib := CharacterLibraryVisual.new()
		lib.name = "Visual"
		var cid: StringName = def.get("character_id", CharacterCatalog.id_for_npc_role(role))
		var scale_mul := 1.0
		if role == NpcCatalog.Role.RESEARCHER:
			scale_mul = 0.96
		elif role == NpcCatalog.Role.STORY:
			## Story cast matches adult band — no oversized hero mul.
			scale_mul = 1.0
		lib.build(cid, scale_mul)
		add_child(lib)
		_visual = lib
		return
	var hat := 0
	match role:
		NpcCatalog.Role.MERCHANT:
			hat = 0
		NpcCatalog.Role.EXPLORER:
			hat = 3
		NpcCatalog.Role.RESEARCHER:
			hat = 1
		NpcCatalog.Role.STORY:
			hat = 2
		_:
			hat = 0 if _rng.randf() < 0.55 else 1
	## Hair variation from id hash — personality without unique meshes.
	var hair_tones: Array[Color] = [
		Color(0.35, 0.22, 0.15),
		Color(0.55, 0.35, 0.2),
		Color(0.15, 0.12, 0.1),
		Color(0.75, 0.65, 0.45),
		Color(0.85, 0.55, 0.35),
	]
	var hair: Color = hair_tones[absi(hash(String(npc_id))) % hair_tones.size()]
	var human := HumanoidVisual.new()
	human.name = "Visual"
	human.build(col, accent, hat, hair)
	## Researchers a touch leaner; story cast stays adult-height.
	if role == NpcCatalog.Role.RESEARCHER:
		human.scale = Vector3(0.95, 1.0, 0.95)
	add_child(human)
	_visual = human


func _build_talk() -> void:
	_talk = NpcTalkInteractable.new()
	_talk.name = "Talk"
	_talk.npc_id = npc_id
	_talk.npc_display_name = display_name
	_talk.dialogue_lines = _fallback_lines
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.4
	shape.shape = sphere
	shape.position = Vector3(0, 0.8, 0)
	_talk.add_child(shape)
	add_child(_talk)
	if not EventBus.npc_dialogue_ended.is_connected(_on_dialogue_ended):
		EventBus.npc_dialogue_ended.connect(_on_dialogue_ended)


func _on_dialogue_ended(ended_id: StringName) -> void:
	if ended_id != npc_id:
		return
	if quest_offer != &"" and not QuestManager.is_quest_active(quest_offer) and not QuestManager.is_quest_completed(quest_offer):
		if QuestManager.start_quest(quest_offer):
			EventBus.ui_notification_requested.emit("%s offered a quest!" % display_name, 2.5)
			NPCManager.adjust_disposition(npc_id, 4.0)


func _process(delta: float) -> void:
	if pinned or move_speed <= 0.01:
		if _visual and _visual.has_method("set_move_amount"):
			_visual.call("set_move_amount", 0.0, false)
		return
	if _ai_detail <= 0:
		return
	_state_timer -= delta
	if _state_timer <= 0.0:
		_pick_target()
	var spd := move_speed
	if _sleeping:
		spd = 0.0
	elif _sheltering:
		spd *= 1.15  ## Hurry to cover.
	elif _ai_detail == 1:
		spd *= 0.7
	var flat := Vector3(_target.x - global_position.x, 0.0, _target.z - global_position.z)
	var moving := flat.length() > 0.25 and spd > 0.01
	if moving:
		var dir := flat.normalized()
		global_position += dir * spd * delta
		if _visual:
			_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(dir.x, dir.z), clampf(8.0 * delta, 0.0, 1.0))
	if _visual and _visual.has_method("set_move_amount"):
		_visual.call("set_move_amount", 1.0 if moving else 0.0, false)
	## Soft leash — road merchants travel farther; story cast stays tight.
	var max_leash := 6.0 if schedule_id == &"story_anchor" else (48.0 if schedule_id == &"merchant_road" else 28.0)
	var home_d := Vector3(_home.x - global_position.x, 0.0, _home.z - global_position.z)
	if home_d.length() > max_leash:
		_target = _home


func _pick_target() -> void:
	_state_timer = _rng.randf_range(3.5, 8.0) if _ai_detail >= 2 else _rng.randf_range(6.0, 12.0)
	_sheltering = false
	_sleeping = false
	var weather := WorldAtmosphere.current_weather_id()
	var slot := NpcSchedule.slot_from_phase(NPCManager.get_day_phase())
	_last_slot = slot
	## Rain / storm → seek porch cover (most schedules).
	if (weather == &"rain" or weather == &"storm") and NpcSchedule.seeks_shelter_in_rain(schedule_id):
		_sheltering = true
		_target = _home + NpcSchedule.shelter_offset(schedule_id)
		_state_timer = _rng.randf_range(5.0, 10.0)
		return
	## Night sleep for townsfolk / kids / merchants.
	if slot == NpcSchedule.Slot.NIGHT and NpcSchedule.sleeps_at_night(schedule_id):
		_sleeping = true
		_target = _home
		_state_timer = _rng.randf_range(8.0, 14.0)
		return
	## Idle sometimes — feels natural (less often when changing phase).
	if _rng.randf() < 0.22:
		_target = global_position
		return
	var points := NpcSchedule.waypoints(schedule_id, slot)
	if points.is_empty():
		_target = _home
		return
	_waypoint_index = (_waypoint_index + 1) % points.size()
	_target = _home + points[_waypoint_index]
