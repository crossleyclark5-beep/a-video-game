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


func _build_visual(def: Dictionary) -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var col: Color = def.get("color", NpcCatalog.role_color(role))
	StylizedMesh.add_box(_visual, Vector3(0.45, 0.7, 0.35), col, Vector3(0, 0.55, 0), "Torso")
	StylizedMesh.add_sphere(_visual, 0.2, Color(0.95, 0.78, 0.62), Vector3(0, 1.15, 0), "Head")
	StylizedMesh.add_box(_visual, Vector3(0.42, 0.08, 0.42), col.darkened(0.25), Vector3(0, 1.32, 0), "Hat")
	## Role accent — small shoulder badge.
	StylizedMesh.add_box(_visual, Vector3(0.12, 0.12, 0.08), NpcCatalog.role_color(role).lightened(0.2), Vector3(0.28, 0.75, 0.1), "Badge")


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
		return
	_state_timer -= delta
	if _state_timer <= 0.0:
		_pick_target()
	var flat := Vector3(_target.x - global_position.x, 0.0, _target.z - global_position.z)
	if flat.length() > 0.25:
		var dir := flat.normalized()
		global_position += dir * move_speed * delta
		if _visual:
			_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(dir.x, dir.z), clampf(8.0 * delta, 0.0, 1.0))
	## Soft leash — schedules can wander farther than random leash.
	var max_leash := 28.0 if schedule_id != &"story_anchor" else 6.0
	var home_d := Vector3(_home.x - global_position.x, 0.0, _home.z - global_position.z)
	if home_d.length() > max_leash:
		_target = _home


func _pick_target() -> void:
	_state_timer = _rng.randf_range(3.5, 8.0)
	## Idle sometimes — feels natural.
	if _rng.randf() < 0.28:
		_target = global_position
		return
	var slot := NpcSchedule.slot_from_phase(NPCManager.get_day_phase())
	var points := NpcSchedule.waypoints(schedule_id, slot)
	if points.is_empty():
		_target = _home
		return
	_waypoint_index = (_waypoint_index + 1) % points.size()
	_target = _home + points[_waypoint_index]
