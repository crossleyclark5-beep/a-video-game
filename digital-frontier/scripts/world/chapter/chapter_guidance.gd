class_name ChapterGuidance
extends Node3D
## Handheld objective beacon — floating marker toward the active MAIN quest target.


var _player: Node3D = null
var _marker: MeshInstance3D = null
var _label: Label3D = null
var _target: Vector3 = Vector3.ZERO
var _has_target: bool = false
var _pulse: float = 0.0


func setup(player: Node3D) -> void:
	_player = player
	_build_marker()
	EventBus.quest_updated.connect(_on_quest_pulse)
	EventBus.quest_started.connect(_on_quest_pulse)
	EventBus.quest_completed.connect(_on_quest_pulse)
	call_deferred("refresh_target")


func _build_marker() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.35
	mesh.height = 0.7
	_marker = MeshInstance3D.new()
	_marker.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = WorldPalette.UI_CYAN
	mat.emission_enabled = true
	mat.emission = WorldPalette.UI_CYAN
	mat.emission_energy_multiplier = 1.4
	_marker.material_override = mat
	add_child(_marker)
	_label = Label3D.new()
	_label.text = "◆"
	_label.font_size = 48
	_label.modulate = WorldPalette.UI_CYAN
	_label.position = Vector3(0, 0.9, 0)
	add_child(_label)
	visible = false


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_pulse += delta
	refresh_target()
	if not _has_target:
		visible = false
		return
	var to := _target - _player.global_position
	to.y = 0.0
	var dist := to.length()
	if dist < 6.0:
		## Near objective — hide beacon to avoid clutter.
		visible = false
		return
	visible = true
	var dir := to.normalized() if dist > 0.1 else Vector3(0, 0, 1)
	global_position = _player.global_position + dir * 4.5 + Vector3(0, 2.2 + sin(_pulse * 3.0) * 0.15, 0)
	_marker.scale = Vector3.ONE * (0.85 + sin(_pulse * 4.0) * 0.08)


func _on_quest_pulse(_a = null, _b = null) -> void:
	refresh_target()


func refresh_target() -> void:
	_has_target = false
	_target = Vector3.ZERO
	## Prefer MAIN quest objective anchors.
	if QuestManager.is_quest_active(&"first_steps"):
		var stage := QuestManager.get_quest_stage(&"first_steps")
		if stage <= 0:
			_set_target(GrasslandLayout.PLEASANT_PARK + Vector3(0, 0, 18.5))
		elif stage == 1:
			_set_target(GrasslandLayout.PLEASANT_PARK + Vector3(-6, 0, 8))
		else:
			_set_target(GrasslandLayout.PLEASANT_PARK + Vector3(0, 0, 16))
		return
	if QuestManager.is_quest_active(&"grassland_call"):
		_set_target(GrasslandLayout.PLEASANT_PARK + Vector3(-8, 0, 28))
		return
	if QuestManager.is_quest_active(&"pine_threat"):
		var st := QuestManager.get_quest_stage(&"pine_threat")
		if st == 0:
			var mid := GrasslandLayout.PLEASANT_PARK.lerp(GrasslandLayout.LANDMARK_PINE_HOLLOW, 0.28)
			_set_target(mid + Vector3(-6, 0, 4))
		elif st == 1:
			_set_target(GrasslandLayout.PLEASANT_PARK + Vector3(40, 0, 0))  ## Fuel Stop east
		else:
			_set_target(GrasslandLayout.PLEASANT_PARK.lerp(GrasslandLayout.LANDMARK_PINE_HOLLOW, 0.42) + Vector3(12, 0, 8))
		return
	if QuestManager.is_quest_active(&"hollow_challenge"):
		var hs := QuestManager.get_quest_stage(&"hollow_challenge")
		if hs == 0:
			_set_target(GrasslandLayout.LANDMARK_PINE_HOLLOW + Vector3(0, 0, -22))
		elif hs == 1:
			_set_target(GrasslandLayout.LANDMARK_PINE_HOLLOW + Vector3(0, 0, -12))
		else:
			_set_target(GrasslandLayout.LANDMARK_PINE_HOLLOW + Vector3(0, 0, 8))
		return


func _set_target(pos: Vector3) -> void:
	_target = pos
	_has_target = true
