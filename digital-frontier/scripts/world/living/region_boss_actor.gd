class_name RegionBossActor
extends CharacterBody3D
## Memorable regional boss — unique silhouette, phases, not a scaled trash mob.

const GROUP := &"region_bosses"

var species_id: StringName = &"hollow_warden"
var display_name: String = "Hollow Warden"
var max_hp: float = 180.0
var hp: float = 180.0
var damage: int = 14
var reward_bits: int = 120
var move_speed: float = 2.8

var _player: Node3D = null
var _home: Vector3 = Vector3.ZERO
var _visual: Node3D = null
var _phase: int = 1
var _attack_cd: float = 0.0
var _intro_done: bool = false
var _rng := RandomNumberGenerator.new()


func setup(def: Dictionary, player: Node3D, origin: Vector3) -> void:
	species_id = def.get("id", &"hollow_warden")
	display_name = String(def.get("label", "Boss"))
	max_hp = float(def.get("hp", 180))
	hp = max_hp
	damage = int(def.get("damage", 14))
	reward_bits = int(def.get("bits", 120))
	move_speed = float(def.get("speed", 2.8))
	_player = player
	_home = origin
	global_position = origin
	collision_layer = 8
	collision_mask = 1
	_build_collision()
	_build_visual(def)
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
	_maybe_phase()
	if hp <= 0.0:
		_die()


func _maybe_phase() -> void:
	var ratio := hp / maxf(max_hp, 1.0)
	if ratio < 0.5 and _phase < 2:
		_phase = 2
		move_speed *= 1.25
		damage += 3
		EventBus.ui_notification_requested.emit("%s roots crackle — phase 2!" % display_name, 2.5)
		EventBus.sfx_play_requested.emit(&"battle_start", global_position)
	elif ratio < 0.25 and _phase < 3:
		_phase = 3
		move_speed *= 1.15
		EventBus.ui_notification_requested.emit("%s howls through the pines!" % display_name, 2.5)


func _die() -> void:
	EventBus.hostile_defeated.emit(species_id, global_position)
	CollectionManager.record_creature_battle(species_id, true)
	InventoryManager.add_bits(reward_bits)
	## Grant authored boss rewards when available.
	var boss_data: BossData = ResourceRegistry.get_boss(species_id)
	if boss_data:
		for i in boss_data.reward_item_ids.size():
			var iid := StringName(boss_data.reward_item_ids[i])
			var qty := 1
			if i < boss_data.reward_quantities.size():
				qty = int(boss_data.reward_quantities[i])
			InventoryManager.add_item(iid, qty, true)
	CreatureManager.grant_adventure_experience(40)
	CreatureManager.grant_adventure_bond(8.0, "%s shared the victory!" % CreatureManager.get_companion_nickname())
	QuestManager.notify_objective(&"defeat", species_id, 1)
	QuestManager.notify_objective(&"defeat", &"any", 1)
	QuestManager.notify_objective(&"defeat", &"boss", 1)
	CollectionManager.record_rare_find(display_name, "boss")
	EventBus.ui_notification_requested.emit("Boss cleared: %s · +%d Bits" % [display_name, reward_bits], 3.5)
	EventBus.sfx_play_requested.emit(&"battle_win", global_position)
	WorldManager.set_world_flag(&"boss_hollow_warden_down", true)
	queue_free()


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.7
	shape.height = 2.2
	col.shape = shape
	col.position = Vector3(0, 1.1, 0)
	add_child(col)


func _build_visual(def: Dictionary) -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var col: Color = def.get("color", Color(0.25, 0.45, 0.28))
	var accent: Color = def.get("accent", WorldPalette.UI_GOLD)
	var scale_v := float(def.get("scale", 2.0))
	## Unique silhouette: thick trunk body + antler canopy — not a big mite.
	StylizedMesh.add_box(_visual, Vector3(1.1 * scale_v * 0.5, 1.8 * scale_v * 0.45, 1.1 * scale_v * 0.5), col, Vector3(0, 0.9 * scale_v * 0.45, 0), "TrunkBody", false, 1.0, &"wood")
	StylizedMesh.add_box(_visual, Vector3(1.8 * scale_v * 0.45, 0.7 * scale_v * 0.45, 1.8 * scale_v * 0.45), col.lightened(0.08), Vector3(0, 1.7 * scale_v * 0.45, 0), "Canopy", false, 1.0, &"leaf")
	StylizedMesh.add_box(_visual, Vector3(0.2, 0.9 * scale_v * 0.4, 0.2), accent, Vector3(-0.45, 2.1 * scale_v * 0.45, 0), "AntlerL")
	StylizedMesh.add_box(_visual, Vector3(0.2, 0.9 * scale_v * 0.4, 0.2), accent, Vector3(0.45, 2.1 * scale_v * 0.45, 0), "AntlerR")
	StylizedMesh.add_sphere(_visual, 0.12, WorldPalette.UI_LIME, Vector3(0.2, 1.35 * scale_v * 0.45, -0.4), "Eye")


func _physics_process(delta: float) -> void:
	if hp <= 0.0 or _player == null or not is_instance_valid(_player):
		return
	_attack_cd = maxf(0.0, _attack_cd - delta)
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	if dist < 28.0 and not _intro_done:
		_intro_done = true
		EventBus.ui_notification_requested.emit("%s awakens — the pines go still." % display_name, 3.0)
		EventBus.sfx_play_requested.emit(&"battle_start", global_position)
		CollectionManager.record_creature_sighting({
			&"id": species_id,
			&"name": display_name,
			&"blurb": "Ancient pine guardian of Hollow.",
			&"rarity": EcosystemCatalog.Rarity.LEGENDARY,
			&"rarity_label": "Legendary",
			&"temperament": EcosystemCatalog.Temperament.AGGRESSIVE,
			&"temperament_label": "Boss",
			&"habitat": "Forest",
		}, global_position)
	if dist > 35.0:
		## Soft leash back to den.
		var home := _home - global_position
		home.y = 0.0
		if home.length() > 1.0:
			var hd := home.normalized()
			velocity.x = hd.x * move_speed * 0.6
			velocity.z = hd.z * move_speed * 0.6
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	elif dist > 2.2:
		var dir := to_player.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		if _visual:
			_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(dir.x, dir.z), clampf(8.0 * delta, 0.0, 1.0))
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack_cd <= 0.0:
			_attack_cd = 1.35 if _phase < 3 else 0.95
			EventBus.battle_encounter_requested.emit(self, &"ambush")
			EventBus.sfx_play_requested.emit(&"battle_start", global_position)
			EventBus.ui_notification_requested.emit("%s challenges you!" % display_name, 1.4)
	if not is_on_floor():
		velocity.y -= 28.0 * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	move_and_slide()
