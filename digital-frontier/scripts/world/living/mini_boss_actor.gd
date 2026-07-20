class_name MiniBossActor
extends CharacterBody3D
## Named mini-boss — Glitch Alpha. Gate before Hollow Warden.

const GROUP := &"mini_bosses"

var species_id: StringName = &"glitch_alpha"
var display_name: String = "Glitch Alpha"
var max_hp: float = 90.0
var hp: float = 90.0
var damage: int = 10
var reward_bits: int = 55
var move_speed: float = 4.2

var _player: Node3D = null
var _home: Vector3 = Vector3.ZERO
var _visual: Node3D = null
var _attack_cd: float = 0.0
var _intro: bool = false


func setup(player: Node3D, origin: Vector3) -> void:
	_player = player
	_home = origin
	global_position = origin
	hp = max_hp
	collision_layer = 8
	collision_mask = 1
	_build()
	add_to_group(GROUP)
	add_to_group(HostileCreatureActor.GROUP)
	add_to_group(GameConstants.GROUP_CREATURES)


func apply_damage(amount: float, source: Node = null) -> void:
	if hp <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	EventBus.sfx_play_requested.emit(&"battle_hit", global_position)
	if source:
		EventBus.combat_hit.emit(source, self, amount)
	if hp <= 0.0:
		_die()


func _die() -> void:
	EventBus.hostile_defeated.emit(species_id, global_position)
	CollectionManager.record_creature_battle(species_id, true)
	InventoryManager.add_bits(reward_bits)
	CreatureManager.grant_adventure_experience(20)
	CreatureManager.grant_adventure_bond(4.0, "")
	QuestManager.notify_objective(&"defeat", species_id, 1)
	QuestManager.notify_objective(&"defeat", &"any", 1)
	CollectionManager.record_rare_find(display_name, "mini_boss")
	WorldManager.set_world_flag(&"mini_boss_glitch_alpha_down", true)
	EventBus.ui_notification_requested.emit("Mini-boss down: %s · +%d Bits" % [display_name, reward_bits], 3.0)
	EventBus.sfx_play_requested.emit(&"battle_win", global_position)
	queue_free()


func _build() -> void:
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 1.4
	col.shape = shape
	col.position = Vector3(0, 0.75, 0)
	add_child(col)
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	## Distinct from normal Glitchmite — taller, dual horns, gold core.
	StylizedMesh.add_box(_visual, Vector3(0.85, 0.7, 0.95), Color(0.75, 0.15, 0.5), Vector3(0, 0.5, 0), "Body")
	StylizedMesh.add_sphere(_visual, 0.32, Color(0.9, 0.25, 0.6), Vector3(0, 1.05, -0.15), "Head")
	StylizedMesh.add_box(_visual, Vector3(0.12, 0.45, 0.12), WorldPalette.UI_GOLD, Vector3(-0.25, 1.35, -0.1), "HornL")
	StylizedMesh.add_box(_visual, Vector3(0.12, 0.45, 0.12), WorldPalette.UI_GOLD, Vector3(0.25, 1.35, -0.1), "HornR")
	StylizedMesh.add_sphere(_visual, 0.1, WorldPalette.UI_CYAN, Vector3(0, 0.55, 0.35), "Core")


func _physics_process(delta: float) -> void:
	if hp <= 0.0 or _player == null or not is_instance_valid(_player):
		return
	_attack_cd = maxf(0.0, _attack_cd - delta)
	var to := _player.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist < 22.0 and not _intro:
		_intro = true
		EventBus.ui_notification_requested.emit("Glitch Alpha screeches — mini-boss fight!", 2.8)
		EventBus.sfx_play_requested.emit(&"battle_start", global_position)
		CollectionManager.record_creature_sighting({
			&"id": species_id,
			&"name": display_name,
			&"blurb": "Alpha glitch strain — packs lesser mites under its horns.",
			&"rarity": EcosystemCatalog.Rarity.RARE,
			&"rarity_label": "Rare",
			&"habitat": "Grassland",
			&"temperament_label": "Mini-Boss",
		}, global_position)
	if dist > 28.0:
		var home := _home - global_position
		home.y = 0.0
		if home.length() > 1.0:
			var hd := home.normalized()
			velocity.x = hd.x * move_speed * 0.7
			velocity.z = hd.z * move_speed * 0.7
		else:
			velocity = Vector3.ZERO
	elif dist > 1.8:
		var dir := to.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		if _visual:
			_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(dir.x, dir.z), clampf(10.0 * delta, 0.0, 1.0))
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack_cd <= 0.0:
			_attack_cd = 1.05
			var health := _player.get_node_or_null("PlayerHealth")
			if health and health.has_method("apply_damage"):
				health.call("apply_damage", damage, self)
	if not is_on_floor():
		velocity.y -= 28.0 * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	move_and_slide()
