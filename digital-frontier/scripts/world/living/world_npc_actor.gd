class_name WorldNpcActor
extends Node3D
## Roaming world NPC — walks near hubs/roads, talk interactable, optional quest offer.

const GROUP := &"world_npcs"

var npc_id: StringName = &"villager"
var display_name: String = "Traveler"
var move_speed: float = 1.6
var quest_offer: StringName = &""

var _player: Node3D = null
var _home: Vector3 = Vector3.ZERO
var _target: Vector3 = Vector3.ZERO
var _visual: Node3D = null
var _talk: NpcTalkInteractable = null
var _state_timer: float = 0.0
var _rng := RandomNumberGenerator.new()


func setup(def: Dictionary, player: Node3D, origin: Vector3) -> void:
	npc_id = def.get("id", &"villager")
	display_name = String(def.get("label", "Traveler"))
	quest_offer = StringName(str(def.get("quest_offer", "")))
	_player = player
	_home = origin
	global_position = origin
	_rng.seed = hash(String(npc_id)) + int(origin.z * 5.0)
	_build_visual(def)
	_build_talk(def)
	_pick_target()
	add_to_group(GROUP)
	add_to_group(GameConstants.GROUP_NPCS)


func _build_visual(def: Dictionary) -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var col: Color = def.get("color", Color(0.5, 0.5, 0.7))
	StylizedMesh.add_box(_visual, Vector3(0.45, 0.7, 0.35), col, Vector3(0, 0.55, 0), "Torso")
	StylizedMesh.add_sphere(_visual, 0.2, Color(0.95, 0.78, 0.62), Vector3(0, 1.15, 0), "Head")
	StylizedMesh.add_box(_visual, Vector3(0.42, 0.08, 0.42), col.darkened(0.25), Vector3(0, 1.32, 0), "Hat")


func _build_talk(def: Dictionary) -> void:
	_talk = NpcTalkInteractable.new()
	_talk.name = "Talk"
	_talk.npc_id = npc_id
	_talk.npc_display_name = display_name
	var lines: PackedStringArray = def.get("lines", PackedStringArray(["Hello!"]))
	_talk.dialogue_lines = lines
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.4
	shape.shape = sphere
	shape.position = Vector3(0, 0.8, 0)
	_talk.add_child(shape)
	add_child(_talk)
	_talk.interacted.connect(_on_talked)


func _on_talked(_actor: Node) -> void:
	if quest_offer != &"" and not QuestManager.is_quest_active(quest_offer) and not QuestManager.is_quest_completed(quest_offer):
		if QuestManager.start_quest(quest_offer):
			EventBus.ui_notification_requested.emit("%s offered a quest!" % display_name, 2.5)


func _process(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		_pick_target()
	var flat := Vector3(_target.x - global_position.x, 0.0, _target.z - global_position.z)
	if flat.length() > 0.2:
		var dir := flat.normalized()
		global_position += dir * move_speed * delta
		if _visual:
			_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(dir.x, dir.z), clampf(8.0 * delta, 0.0, 1.0))
	## Stay near home leash.
	var home_d := Vector3(_home.x - global_position.x, 0.0, _home.z - global_position.z)
	if home_d.length() > 18.0:
		_target = _home


func _pick_target() -> void:
	_state_timer = _rng.randf_range(3.0, 7.0)
	## Occasionally idle in place.
	if _rng.randf() < 0.35:
		_target = global_position
		return
	var ang := _rng.randf() * TAU
	var r := _rng.randf_range(1.5, 7.0)
	_target = _home + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
